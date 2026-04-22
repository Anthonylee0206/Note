# SP 3：tran_list 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.tran_list` 使用動態 SQL 組合查詢條件，是後台存取款列表頁面的核心 SP。
因為每天執行約 146 萬次且平均耗時 26ms，**總耗時在所有 SP 中排第一**。
主要問題包含 `mem_tran` 被掃描兩次、CHARINDEX 函數導致索引失效、
暫存表沒建索引、以及潛在的 SQL Injection 風險。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.tran_list` |
| 資料庫 | cmd_data |
| 用途 | Backend System 2.1 Deposit 存取款列表查詢 |
| 每日執行次數 | 約 1,466,446 次 |
| 平均耗時 | 26ms |
| 總耗時 | 38,560,654ms（**所有 SP 中最高**）|
| 平均 Logical Reads | 1,851 |
| 特殊說明 | 使用動態 SQL（sp_executesql），真正的執行計畫不在 SP 層級 |

---

## 三、SP 架構解讀

### 整體流程

```
Step 1:  根據傳入參數，動態拼接 WHERE 條件字串
Step 2:  SELECT INTO #_mem_tran（從 mem_tran 篩選基本欄位）
Step 3:  @@ROWCOUNT 取得總筆數（分頁用）
Step 4:  CTE 分頁（OFFSET FETCH）
Step 5:  JOIN 回 mem_tran + mem_info + mem_group + mem_tran_pic + bank_info 取完整欄位
Step 6:  透過 sp_executesql 執行整段動態 SQL
```

### 為什麼用動態 SQL？

這支 SP 有很多可選參數（TranType、Currency、Method、Bank、PlayerId 等），
不同組合會產生不同的 WHERE 條件。動態 SQL 可以根據實際傳入的參數只拼需要的條件，
避免 `(@param = '' OR col = @param)` 這種 OR 條件造成的 parameter sniffing 問題。

---

## 四、問題清單

### 問題 1：mem_tran 被掃描兩次（最大效能問題）【必改】

```sql
-- 第一次掃描：SELECT INTO 暫存表，只拿 4 個欄位
SELECT a.tran_no, a.mem_id, a.status, a.create_date
INTO #_mem_tran
FROM mem_tran AS a WITH (NOLOCK)
WHERE a.create_date BETWEEN @BDate AND @EDate ...

-- 第二次掃描：CTE 分頁後又 JOIN 回 mem_tran 拿完整欄位
FROM mem m JOIN mem_tran a WITH (NOLOCK)
ON m.tran_no = a.tran_no
```

**問題**：第一次掃描 mem_tran 做篩選和計算總筆數，
第二次掃描 mem_tran 拿完整欄位。同一張大表掃了兩次。

**建議**：第一次就把分頁需要的欄位帶出來，或改用 `COUNT(*) OVER()` 在同一個查詢裡同時取得總筆數。

### 問題 2：CHARINDEX 排序（sargability）【必改】

```sql
-- ❌ 對欄位做函數運算排序，索引用不上
ORDER BY CHARINDEX(status+',','P,S,A,M,R,'), create_date DESC
```

這個排序的意圖是讓 status 按照 P → S → A → M → R 的順序排列。

**建議**：改用 CASE WHEN 明確指定順序：

```sql
-- ✅ 不對欄位做函數運算
ORDER BY CASE a.status
             WHEN 'P' THEN 1
             WHEN 'S' THEN 2
             WHEN 'A' THEN 3
             WHEN 'M' THEN 4
             WHEN 'R' THEN 5
             ELSE 6
         END,
         a.create_date DESC
```

### 問題 3：CHARINDEX 篩選 TranStatus（sargability）【必改】

```sql
-- ❌ 用 CHARINDEX 模擬 IN，索引無法使用
AND CHARINDEX(',' + a.[status] + ',', ',' + @TranStatus + ',') <> 0
```

**建議**：改用 `STRING_SPLIT`（SQL Server 2016+ 支援，prod 是 2017 可用）：

```sql
-- ✅ 改用 STRING_SPLIT + IN
AND a.[status] IN (SELECT value FROM STRING_SPLIT(@TranStatus, ','))
```

或直接在拼接時展開成 IN 子句：

```sql
-- ✅ 動態拼接成 IN
SET @filter += ' AND a.[status] IN (SELECT value FROM STRING_SPLIT(@TranStatus, '',''))'
```

### 問題 4：CTE 裡面用 SELECT *【建議】

```sql
-- ❌ SELECT *
;WITH mem AS
(
    SELECT * FROM #_mem_tran
    ORDER BY ...
)

-- ✅ 明確列出欄位
;WITH mem AS
(
    SELECT tran_no, mem_id, status, create_date
    FROM #_mem_tran
    ORDER BY ...
)
```

### 問題 5：SQL Injection 風險【必改】

```sql
-- ❌ 函數回傳值直接拼進 SQL 字串
SET @filter += ' AND a.[curr_id] in ( ' + dbo.GetCurrArray(@UserId) + ' )'
```

`dbo.GetCurrArray` 的回傳值沒有經過參數化就直接拼進動態 SQL。
其他條件（@TranType、@Method 等）都用參數化傳入 sp_executesql，
唯獨這個直接字串拼接。

**建議**：改成在動態 SQL 內呼叫函數，或改用 `STRING_SPLIT` 參數化處理。

### 問題 6：暫存表沒建索引【建議】

```sql
SELECT ... INTO #_mem_tran FROM mem_tran ...
-- 建完之後沒加索引，後面 JOIN 用 tran_no 比對會全表掃描
```

**建議**：建完暫存表後加索引：

```sql
SELECT ... INTO #_mem_tran FROM mem_tran ...

CREATE CLUSTERED INDEX IX_mem_tran_no ON #_mem_tran(tran_no);
```

### 問題 7：BETWEEN 日期邊界問題【建議】

```sql
-- ❌ DATETIME 的 BETWEEN 有邊界問題
WHERE a.create_date BETWEEN @BDate AND @EDate
-- 如果 @EDate = '2026-04-22'，只抓到 00:00:00.000，後面的時間全漏
```

**建議**：改用半開區間：

```sql
-- ✅ 安全的日期範圍
WHERE a.create_date >= @BDate
  AND a.create_date < DATEADD(DAY, 1, CAST(@EDate AS DATE))
```

### 問題 8：SET OFF 不需要【提醒】

```sql
-- ❌ SP 結束自動恢復
SET ARITHABORT, NOCOUNT OFF;
```

---

## 五、改動風險等級總覽

| 改動 | 風險 | 類型 |
|---|---|---|
| CHARINDEX 排序 → CASE WHEN | **低** | 寫法改善 |
| CHARINDEX 篩選 → STRING_SPLIT | **低** | 寫法改善 |
| CTE SELECT * → 明確欄位 | **無** | 清理 |
| BETWEEN → 半開區間 | **低** | 邏輯修正 |
| 暫存表加索引 | **低** | 效能改善 |
| SQL Injection 修正 | **中** | 安全性 |
| mem_tran 減少掃描次數 | **中** | 需要重構查詢邏輯 |
| 拿掉 SET OFF | **無** | 清理 |

---

## 六、建議推進順序

```
第一步（低風險）：改 CHARINDEX 和 BETWEEN
  邏輯不變，只是寫法更高效
  CHARINDEX 改 CASE WHEN 和 STRING_SPLIT
  BETWEEN 改半開區間

第二步（低風險）：暫存表加索引 + CTE 明確欄位
  建完 #_mem_tran 後加 CLUSTERED INDEX
  減少後續 JOIN 時的掃描

第三步（中風險）：SQL Injection 修正
  GetCurrArray 的拼接改成參數化
  需要了解 GetCurrArray 的回傳格式

第四步（中風險）：減少 mem_tran 掃描次數
  涉及查詢邏輯重構
  需要在測試環境充分驗證分頁結果一致
```

---

## 七、修正後完整版本

```sql
ALTER PROCEDURE [dbo].[tran_list]
    @BeginDate  DATETIME    = '',
    @EndDate    DATETIME    = '',
    @TranType   VARCHAR(20) = '',
    @Currency   VARCHAR(20) = '',
    @Method     VARCHAR(20) = '',
    @TranStatus VARCHAR(20) = '',
    @Bank       NVARCHAR(50)= '',
    @PlayerId   VARCHAR(30) = '',
    @UserId     VARCHAR(30) = '',
    @MerchantId VARCHAR(10) = '',
    @LoginId    VARCHAR(30) = '',
    @PageIndex  INT         = 1,
    @PageSize   INT         = 10,
    @RecordsCount INT       = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    DECLARE @SQLString NVARCHAR(MAX) = '',
            @filter    NVARCHAR(MAX) = '',
            @SelString NVARCHAR(MAX) = '',
            @BDate     DATETIME      = @BeginDate,
            @EDate     DATETIME      = @EndDate;

    -- ============================================================
    -- 動態拼接 WHERE 條件
    -- ============================================================

    IF @TranType <> ''
        SET @filter += N' AND a.[tran_type] = @TranType';

    IF @UserId <> ''
    BEGIN
        IF @Currency <> ''
            SET @filter += N' AND a.[curr_id] = @Currency'
        ELSE
            -- 改用 STRING_SPLIT 參數化，避免 SQL Injection
            -- 原本直接拼接 dbo.GetCurrArray(@UserId) 有注入風險
            SET @filter += N' AND a.[curr_id] IN (SELECT value FROM STRING_SPLIT(dbo.GetCurrArray(@UserId), '',''))';
    END

    IF @Method <> ''
    BEGIN
        IF @Method = 'NOTRF'
            SET @filter += N' AND a.[method_id] <> ''TRF'''
        ELSE
            SET @filter += N' AND a.[method_id] = @Method';
    END

    IF @Bank <> ''
    BEGIN
        IF @TranType <> 'Out'
            SET @filter += N' AND a.[mbank_id] = @Bank'
        ELSE
            SET @filter += N' AND a.[bank_id] = @Bank';
    END

    IF @PlayerId <> ''
        SET @filter += N' AND a.[mem_id] = @PlayerId';

    IF @MerchantId <> ''
        SET @filter += N' AND a.[merchant_id] = @MerchantId';

    IF @LoginId <> ''
        SET @filter += N' AND a.[login_id] = @LoginId';

    -- CHARINDEX 改 STRING_SPLIT + IN，索引可用
    IF @TranStatus <> ''
        SET @filter += N' AND a.[status] IN (SELECT value FROM STRING_SPLIT(@TranStatus, '',''))';

    -- 動態決定 bank 欄位（存款 vs 取款顯示不同欄位）
    IF @TranType <> 'Out'
        SET @SelString = N' a.mbank_id AS bank_id, bi.bank_name AS bank_name,'
    ELSE
        SET @SelString = N' a.[bank_id], a.[bank_name],';

    -- ============================================================
    -- 主查詢
    -- ============================================================

    SET @SQLString = N'

    -- Step 1: 篩選符合條件的交易，同時拿到排序需要的欄位
    DROP TABLE IF EXISTS #_mem_tran;

    SELECT
        a.[tran_no],
        a.[mem_id],
        a.[status],
        a.[create_date],
        -- 排序欄位直接在這裡算好，後面不用再算
        CASE a.[status]
            WHEN ''P'' THEN 1
            WHEN ''S'' THEN 2
            WHEN ''A'' THEN 3
            WHEN ''M'' THEN 4
            WHEN ''R'' THEN 5
            ELSE 6
        END AS status_sort
    INTO #_mem_tran
    FROM mem_tran AS a WITH (NOLOCK)
    WHERE a.create_date >= @BDate
      AND a.create_date < DATEADD(DAY, 1, CAST(@EDate AS DATE))'
      + @filter + N';

    -- Step 2: 取得總筆數
    SET @RecordsCount = @@ROWCOUNT;

    -- Step 3: 暫存表加索引，加速後續 JOIN 和排序
    CREATE CLUSTERED INDEX IX_tmp_sort
        ON #_mem_tran (status_sort, create_date DESC);

    CREATE NONCLUSTERED INDEX IX_tmp_tran_no
        ON #_mem_tran (tran_no);

    -- Step 4: 分頁 + JOIN 取完整欄位
    -- 只掃描 mem_tran 一次（透過 tran_no 精準 Seek，不是全表掃描）
    SELECT
        a.[tran_no],
        a.[mem_id],
        a.[curr_id],
        a.[create_date],
        a.[tran_type],
        a.[amt],
        a.[status],
        ' + @SelString + N'
        a.[bank_acct_no],
        a.[approval_id],
        a.[approval_date],
        a.[method_id],
        a.[remark],
        a.[tran_date],
        a.[post_status],
        a.[merchant_id],
        a.[login_id],
        a.[city_code],
        a.[province_code],
        mg.group_desc,
        mi.mem_name,
        a.[tran_reference],
        ''0'' AS matched,
        mi.group_id,
        pic.tran_pic AS receipt_pic,
        CASE WHEN mi.deposit_date IS NULL
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
        END AS first_deposit,
        CASE WHEN mi.withdraw_date IS NULL
             THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT)
        END AS first_withdraw
    FROM
    (
        -- 分頁在暫存表上做，已有索引，速度快
        SELECT tran_no
        FROM #_mem_tran
        ORDER BY status_sort, create_date DESC
        OFFSET ((@PageIndex - 1) * @PageSize) ROWS
        FETCH NEXT @PageSize ROWS ONLY
    ) AS paged
    INNER JOIN mem_tran AS a WITH (NOLOCK)
        ON paged.tran_no = a.tran_no
    INNER JOIN mem_info AS mi WITH (NOLOCK)
        ON a.mem_id = mi.mem_id
    INNER JOIN mem_group AS mg WITH (NOLOCK)
        ON mg.group_id = mi.group_id
    LEFT JOIN mem_tran_pic AS pic WITH (NOLOCK)
        ON pic.tran_no = a.tran_no
    LEFT JOIN bank_info AS bi WITH (NOLOCK)
        ON bi.bank_id = a.mbank_id
       AND bi.curr_id = a.curr_id
    ORDER BY paged.tran_no;

    DROP TABLE IF EXISTS #_mem_tran;
    ';

    -- ============================================================
    -- 執行動態 SQL
    -- ============================================================
    EXECUTE sp_executesql @SQLString, N''
        @BDate       DATETIME,
        @EDate       DATETIME,
        @TranType    VARCHAR(20),
        @Currency    VARCHAR(20),
        @Method      VARCHAR(20),
        @TranStatus  VARCHAR(20),
        @Bank        NVARCHAR(50),
        @PlayerId    VARCHAR(30),
        @UserId      VARCHAR(30),
        @MerchantId  VARCHAR(10),
        @LoginId     VARCHAR(30),
        @PageIndex   INT,
        @PageSize    INT,
        @RecordsCount INT OUTPUT'',
        @BDate,
        @EDate,
        @TranType,
        @Currency,
        @Method,
        @TranStatus,
        @Bank,
        @PlayerId,
        @UserId,
        @MerchantId,
        @LoginId,
        @PageIndex,
        @PageSize,
        @RecordsCount OUTPUT;
END;
GO
```

### 改動對照表

| # | 改前 | 改後 | 原因 |
|---|---|---|---|
| 1 | `BETWEEN @BDate AND @EDate` | `>= @BDate AND < DATEADD(DAY,1,@EDate)` | 日期邊界問題 |
| 2 | `CHARINDEX(status+',','P,S,A,M,R,')` 排序 | `CASE WHEN status` 算好存進暫存表 | sargability，排序直接用數字 |
| 3 | `CHARINDEX` 篩選 TranStatus | `STRING_SPLIT + IN` | sargability，索引可用 |
| 4 | `dbo.GetCurrArray` 直接拼字串 | `STRING_SPLIT` 參數化 | SQL Injection 防護 |
| 5 | 暫存表沒索引 | 建 CLUSTERED + NONCLUSTERED INDEX | 分頁排序和 JOIN 都變快 |
| 6 | CTE `SELECT *` 分頁 | 子查詢只取 `tran_no` 分頁 | 明確欄位，分頁更輕量 |
| 7 | CTE 分頁後 JOIN mem_tran 全表 | 子查詢先分頁取 tran_no，再用 PK Seek | mem_tran 第二次只 Seek 10 筆 |
| 8 | `SET ARITHABORT, NOCOUNT OFF` | 拿掉 | SP 結束自動恢復 |

### 關鍵改善說明

**mem_tran 從掃描兩次變成「掃一次 + Seek 十筆」**

```
改前:
  第一次: 全表掃描 mem_tran → 篩選後塞入暫存表
  第二次: 全表掃描 mem_tran → JOIN 暫存表取完整欄位
  = 兩次全表掃描

改後:
  第一次: 全表掃描 mem_tran → 篩選後塞入暫存表（同）
  第二次: 暫存表分頁取 10 個 tran_no → 用 PK Seek 回 mem_tran 取 10 筆
  = 一次全表掃描 + 10 次 PK Seek
```

**排序預計算**

```
改前: 每次分頁都要跑一次 CHARINDEX 函數
改後: status_sort 在 INSERT 時就算好存進暫存表
      加上 CLUSTERED INDEX (status_sort, create_date DESC)
      分頁直接用索引排序，不用再算
```

---
---

