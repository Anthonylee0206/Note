# SP 4：mempromotion_by_list_new 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.mempromotion_by_list_new` 是所有 SP 中**執行次數最高**的（每天 561 萬次），
平均只要 4ms 但 max 到 14 秒，典型的 parameter sniffing 問題。
最嚴重的是 JOIN 條件上有 `CAST(promote_id AS NVARCHAR)` 隱含轉換，
以及同樣的四張表 JOIN + WHERE 完全重複執行兩次（一次取資料、一次取 COUNT）。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.mempromotion_by_list_new` |
| 資料庫 | cmd_data |
| 用途 | 3.2 Player Promotion 活動列表查詢（分頁）|
| 每日執行次數 | 約 5,612,970 次（**所有 SP 中最高**）|
| 平均耗時 | 4ms |
| 最大耗時 | 14,214ms（14 秒）|
| 平均 Logical Reads | 4,157 |
| 特殊說明 | 使用動態 SQL（sp_executesql）|

---

## 三、問題清單

### 問題 1：JOIN 上的 CAST 隱含轉換（最嚴重）【必改】

```sql
-- ❌ 每次 JOIN 都對欄位做 CAST，索引完全失效
LEFT JOIN promotion AS p WITH(NOLOCK)
ON CAST(a.promote_id AS NVARCHAR) = p.promote_id

-- ✅ 確認兩邊型態一致，直接比對
LEFT JOIN promotion AS p WITH(NOLOCK)
ON a.promote_id = p.promote_id
```

如果 `a.promote_id` 是 VARCHAR 而 `p.promote_id` 是 NVARCHAR，
應該從根本統一欄位型態，或至少轉換資料量小的那一邊：

```sql
-- ✅ 如果不能改欄位型態，轉換資料量小的那邊
LEFT JOIN promotion AS p WITH(NOLOCK)
ON a.promote_id = CAST(p.promote_id AS VARCHAR(30))
```

每天 561 萬次 × CAST 導致的全表掃描，這個改掉效果最大。

### 問題 2：同樣的查詢跑兩次【必改】

```sql
-- 第一次：取分頁資料
SELECT ... FROM mem_promotion JOIN promotion JOIN mem_info JOIN promotion_type
WHERE ... ORDER BY ... OFFSET FETCH

-- 第二次：取總筆數（完全一樣的 JOIN 和 WHERE）
SELECT @RecordsCount = COUNT(1)
FROM mem_promotion JOIN promotion JOIN mem_info JOIN promotion_type
WHERE ...
```

四張表 JOIN 兩次、相同的 WHERE 掃兩次。

**建議**：改成暫存表方式，先篩選一次存起來，再分頁和 COUNT：

```sql
-- 只 JOIN 一次，存進暫存表
SELECT a.id, ... INTO #_promo_result
FROM mem_promotion AS a ...
WHERE ...;

-- 總筆數直接從暫存表取
SET @RecordsCount = @@ROWCOUNT;

-- 分頁也從暫存表取
SELECT * FROM #_promo_result
ORDER BY create_time DESC
OFFSET ... ROWS FETCH NEXT ... ROWS ONLY;
```

### 問題 3：OR 條件讓 create_time 索引失效【必改】

```sql
-- ❌ OR @IsSelectAll = '1' 讓日期索引失效
WHERE (a.create_time BETWEEN @BeginDate AND @EndDate
       OR @IsSelectAll = '1')

-- ✅ 動態 SQL 裡根據 @IsSelectAll 決定要不要加日期條件
-- 在拼接 filter 的時候處理：
IF @IsSelectAll = 0
    SET @filter += N' AND a.create_time >= @BeginDate
                     AND a.create_time < DATEADD(DAY, 1, CAST(@EndDate AS DATE))';
```

### 問題 4：@IsComplete 邏輯可能有 bug【建議確認】

```sql
-- 完成：curr_accum >= target_amt AND curr_accum <> 0     ← OK
-- 未完成：curr_accum < target_amt AND curr_accum = 0     ← ❓

-- 未完成條件只抓 curr_accum 剛好等於 0 的資料
-- 例如 curr_accum = 50, target_amt = 100 不會被抓到
-- 需要跟 RD 確認：是「完全沒開始」還是「還沒達標」？

-- 如果意圖是「還沒達標」，應該改成：
AND a.curr_accum < a.target_amt AND @IsComplete = '0'

-- 如果意圖是「完全沒開始」，目前邏輯正確但建議加註解說明
```

### 問題 5：SQL Injection 風險【必改】

```sql
-- ❌ 跟 tran_list 一樣的問題
SET @filter += N' AND m.curr_id in ( ' + dbo.GetCurrArray(@UserId) + ' ) '

-- ✅ 改用 STRING_SPLIT
SET @filter += N' AND m.curr_id IN (SELECT value FROM STRING_SPLIT(dbo.GetCurrArray(@UserId), '',''))'
```

### 問題 6：BETWEEN 日期邊界【建議】

```sql
-- ❌ DATETIME 的 BETWEEN 有邊界問題
WHERE a.create_time BETWEEN @BeginDate AND @EndDate

-- ✅ 半開區間
WHERE a.create_time >= @BeginDate
  AND a.create_time < DATEADD(DAY, 1, CAST(@EndDate AS DATE))
```

### 問題 7：沒有 OPTION (RECOMPILE)【必改】

平均 4ms 但 max 到 14 秒，典型的 parameter sniffing。
動態 SQL 搭配多個可選參數，應該加 RECOMPILE：

```sql
-- 在 OFFSET FETCH 後面加
OFFSET (@PageIndex - 1) * @PageSize ROWS
FETCH NEXT @PageSize ROWS ONLY
OPTION (RECOMPILE);
```

### 問題 8：SET OFF 不需要【提醒】

```sql
SET NOCOUNT ,ARITHABORT OFF;    -- SP 結束自動恢復
```

---

## 四、改動風險等級

| 改動 | 風險 | 說明 |
|---|---|---|
| CAST 移除 / 修正 | **中** | 需確認兩邊欄位型態 |
| 查詢合併（暫存表） | **中** | 需驗證分頁結果一致 |
| OR @IsSelectAll 改動態拼接 | **低** | 邏輯不變 |
| @IsComplete 邏輯確認 | **中** | 需跟 RD 確認業務意圖 |
| SQL Injection 修正 | **中** | 需了解 GetCurrArray 回傳格式 |
| BETWEEN 改半開區間 | **低** | 邏輯修正 |
| 加 OPTION (RECOMPILE) | **低** | 解決 14 秒偶發問題 |
| 拿掉 SET OFF | **無** | 清理 |

---

## 五、建議推進順序

```
第一步（效果最大）：修正 CAST(promote_id AS NVARCHAR)
  確認 mem_promotion.promote_id 和 promotion.promote_id 的型態
  統一型態後拿掉 CAST，索引恢復正常

第二步（低風險）：加 OPTION (RECOMPILE)
  直接解決 14 秒偶發問題
  不影響邏輯，只是每次重新編譯

第三步（低風險）：BETWEEN 改半開區間 + OR 改動態拼接
  邏輯不變，日期篩選更精確
  create_time 索引可用

第四步（中風險）：合併兩次查詢為暫存表方式
  四張表只 JOIN 一次
  需驗證分頁和 COUNT 結果一致

第五步：跟 RD 確認 @IsComplete 邏輯
```

---

## 六、修正後完整版本

```sql
ALTER PROCEDURE [dbo].[mempromotion_by_list_new]
    @BeginDate   DATETIME     = '',
    @EndDate     DATETIME     = '',
    @MerchantId  VARCHAR(10)  = '',
    @LoginId     VARCHAR(30)  = '',
    @ProviderId  VARCHAR(30)  = '',
    @PlayerId    VARCHAR(30)  = '',
    @UserId      VARCHAR(30)  = '',
    @CurrId      VARCHAR(10)  = '',
    @IsActive    VARCHAR(20)  = '',
    @PromoteId   VARCHAR(30)  = '',
    @IsSelectAll INT          = 0,
    @PromoteType VARCHAR(20)  = '',
    @IsComplete  VARCHAR(10)  = '-',
    @IsOverdue   INT          = -1,
    @PageIndex   INT          = 1,
    @PageSize    INT          = 10,
    @RecordsCount INT         = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    DECLARE @sqlStr NVARCHAR(MAX) = '',
            @filter NVARCHAR(MAX) = '';

    -- ============================================================
    -- 動態拼接 WHERE 條件
    -- ============================================================

    -- 日期條件：改成動態拼接，避免 OR @IsSelectAll 讓索引失效
    IF @IsSelectAll = 0
        SET @filter += N' AND a.create_time >= @BeginDate
                         AND a.create_time < DATEADD(DAY, 1, CAST(@EndDate AS DATE))';

    -- @IsComplete 條件：拆成獨立的動態拼接
    IF @IsComplete = '1'
        SET @filter += N' AND a.curr_accum >= a.target_amt AND a.curr_accum <> 0'
    ELSE IF @IsComplete = '0'
        SET @filter += N' AND a.curr_accum < a.target_amt AND a.curr_accum = 0';
    -- @IsComplete = '-' 時不加任何條件（查全部）

    IF @ProviderId <> ''
        SET @filter += N' AND a.provider_id = @ProviderId';

    IF @PlayerId <> ''
        SET @filter += N' AND a.mem_id = @PlayerId';

    IF @CurrId <> ''
        SET @filter += N' AND m.curr_id = @CurrId';

    IF @PromoteType <> ''
        SET @filter += N' AND p.promote_type = @PromoteType';

    IF @IsActive <> ''
        SET @filter += N' AND a.is_active = CAST(@IsActive AS INT)';

    IF @MerchantId <> ''
        SET @filter += N' AND a.merchant_id = @MerchantId';

    IF @PromoteId <> ''
        SET @filter += N' AND a.promote_id LIKE(@PromoteId + ''%'')';

    IF @LoginId <> ''
        SET @filter += N' AND a.login_id LIKE(@LoginId + ''%'')';

    -- SQL Injection 修正：改用 STRING_SPLIT 參數化
    IF @UserId <> ''
        SET @filter += N' AND m.curr_id IN (SELECT value FROM STRING_SPLIT(dbo.GetCurrArray(@UserId), '',''))';

    IF @IsOverdue <> -1
        SET @filter += N' AND a.is_overdue = @IsOverdue';

    -- ============================================================
    -- 主查詢：只 JOIN 一次，用暫存表同時處理分頁和 COUNT
    -- ============================================================

    SET @sqlStr = N'

    -- Step 1: 篩選符合條件的資料，一次 JOIN 全部完成
    DROP TABLE IF EXISTS #_promo_result;

    SELECT
        a.id,
        a.mem_id,
        a.provider_id,
        a.promote_id,
        a.transfer_amt,
        a.target_amt,
        a.bonus_amt,
        a.curr_accum,
        a.create_time,
        a.is_active,
        a.lastupdate_by,
        a.lastupdate_date,
        a.promo_date,
        a.accum_wl,
        p.promote_title,
        n.is_first,
        m.curr_id,
        a.merchant_id,
        a.login_id,
        a.tran_no,
        a.unlock_amt,
        a.remark,
        a.is_overdue,
        p.game_id
    INTO #_promo_result
    FROM mem_promotion AS a WITH (NOLOCK)
    LEFT JOIN promotion AS p WITH (NOLOCK)
        ON a.promote_id = p.promote_id             -- 拿掉 CAST，確認型態一致
    INNER JOIN mem_info AS m WITH (NOLOCK)
        ON m.mem_id = a.mem_id
    INNER JOIN promotion_type AS n WITH (NOLOCK)
        ON n.promotion_type_code = a.promote_type
    WHERE 1 = 1' + @filter + N';

    -- Step 2: 總筆數直接從 @@ROWCOUNT 取，不用再 COUNT 一次
    SET @RecordsCount = @@ROWCOUNT;

    -- Step 3: 分頁從暫存表取
    SELECT *
    FROM #_promo_result
    ORDER BY create_time DESC
    OFFSET (@PageIndex - 1) * @PageSize ROWS
    FETCH NEXT @PageSize ROWS ONLY
    OPTION (RECOMPILE);                             -- 解決 parameter sniffing

    DROP TABLE IF EXISTS #_promo_result;
    ';

    -- ============================================================
    -- 執行動態 SQL
    -- ============================================================
    EXEC sp_executesql @sqlStr, N'
        @BeginDate   DATETIME,
        @EndDate     DATETIME,
        @MerchantId  VARCHAR(10),
        @LoginId     VARCHAR(30),
        @ProviderId  VARCHAR(30),
        @PlayerId    VARCHAR(30),
        @UserId      VARCHAR(30),
        @CurrId      VARCHAR(10),
        @IsActive    VARCHAR(20),
        @PromoteId   VARCHAR(30),
        @IsSelectAll INT,
        @PromoteType VARCHAR(20),
        @IsComplete  VARCHAR(10),
        @PageIndex   INT,
        @PageSize    INT,
        @RecordsCount INT OUTPUT,
        @IsOverdue   INT',
        @BeginDate,
        @EndDate,
        @MerchantId,
        @LoginId,
        @ProviderId,
        @PlayerId,
        @UserId,
        @CurrId,
        @IsActive,
        @PromoteId,
        @IsSelectAll,
        @PromoteType,
        @IsComplete,
        @PageIndex,
        @PageSize,
        @RecordsCount OUTPUT,
        @IsOverdue;
END;
GO
```

### 改動對照表

| # | 改前 | 改後 | 原因 |
|---|---|---|---|
| 1 | `CAST(a.promote_id AS NVARCHAR) = p.promote_id` | `a.promote_id = p.promote_id` | 隱含轉換，索引失效 |
| 2 | 同樣的 JOIN + WHERE 跑兩次（取資料 + COUNT） | 暫存表 + `@@ROWCOUNT` | 四張表只 JOIN 一次 |
| 3 | `WHERE (... BETWEEN ... OR @IsSelectAll = '1')` | 日期條件動態拼接 | OR 讓 create_time 索引失效 |
| 4 | `@IsComplete` 的 OR 嵌套條件放在 WHERE 裡 | 拆成動態拼接 IF/ELSE | 簡化 WHERE，讓最佳化器更好判斷 |
| 5 | `dbo.GetCurrArray` 直接拼字串 | `STRING_SPLIT` 參數化 | SQL Injection 防護 |
| 6 | `BETWEEN @BeginDate AND @EndDate` | `>= @BeginDate AND < DATEADD(DAY,1,@EndDate)` | 日期邊界問題 |
| 7 | 沒有 RECOMPILE | `OPTION (RECOMPILE)` | 解決 4ms → 14 秒偶發問題 |
| 8 | `SET NOCOUNT, ARITHABORT OFF` | 拿掉 | SP 結束自動恢復 |

### 關鍵改善說明

**四張表 JOIN 從兩次變一次**

```
改前:
  第一次: mem_promotion + promotion + mem_info + promotion_type
          → SELECT 分頁資料
  第二次: mem_promotion + promotion + mem_info + promotion_type
          → SELECT COUNT(1)
  = 每張表掃描兩次

改後:
  一次: mem_promotion + promotion + mem_info + promotion_type
        → SELECT INTO 暫存表
        → @@ROWCOUNT 取總筆數（不用再 COUNT）
        → 分頁從暫存表取
  = 每張表只掃描一次
```

**OR 條件拆成動態拼接**

```
改前:
  WHERE (a.create_time BETWEEN ... OR @IsSelectAll = '1')
  AND ((...AND @IsComplete = '1') OR (...AND @IsComplete = '0') OR @IsComplete = '-')
  → 最佳化器看到 OR 就放棄用索引

改後:
  動態拼接時就決定好要不要加日期條件和完成條件
  → WHERE 裡面只有 AND，索引可以正常使用
```

**CAST 移除的影響**

```
改前:
  ON CAST(a.promote_id AS NVARCHAR) = p.promote_id
  → 每次 JOIN 都對 mem_promotion 的 promote_id 做轉換
  → 561 萬次/天 × 全表掃描

改後:
  ON a.promote_id = p.promote_id
  → 直接比對，索引可用
  → 如果型態不一致需要先統一欄位型態
```

### 注意事項

1. **CAST 移除前必須確認型態**：跑以下查詢確認兩邊欄位型態

```sql
SELECT
    OBJECT_NAME(c.object_id) AS table_name,
    c.name                   AS column_name,
    t.name                   AS type_name,
    c.max_length
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE (c.object_id = OBJECT_ID('dbo.mem_promotion') AND c.name = 'promote_id')
   OR (c.object_id = OBJECT_ID('dbo.promotion') AND c.name = 'promote_id');
```

如果兩邊型態不同（例如 VARCHAR vs NVARCHAR），需要決定統一成哪一種，
或在資料量較小的 `promotion` 表那邊做轉換。

2. **@IsComplete 邏輯**：目前保留原本的邏輯（`curr_accum = 0` 才算未完成），
但建議跟 RD 確認是否正確。

---
---

