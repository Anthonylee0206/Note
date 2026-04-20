# SQL Server SP 審查 Checklist

適用於 SQL Server 2022，用來審查 RD 提交的 Stored Procedure 腳本。

---

## 一、SET 選項

- SP 開頭（`BEGIN` 之後第一行）加上 `SET NOCOUNT, ARITHABORT ON`
- 結尾不需要 `SET OFF`，SP 結束自動恢復
- SP 外面不該有多餘的 `SET ANSI_PADDING OFF` 之類的殘留

```sql
CREATE OR ALTER PROCEDURE [dbo].[sample_sp]
    @Param1 VARCHAR(10)
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;  -- 放這裡

    -- 主體邏輯
END;
```

---

## 二、參數檢查

- 每個參數的型態要跟**資料表欄位型態完全一致**，避免隱含轉換
  - VARCHAR 對 VARCHAR，不要混 NVARCHAR
  - 金額類一律 `DECIMAL(18,2)`，不要用 FLOAT
  - 日期類用 DATETIME，不要用 VARCHAR 字串傳日期
- 宣告了但沒用到的參數要跟 RD 確認
- 預設值是否合理（例如 `''` 會不會導致查不到資料）

---

## 三、WHERE 條件

### 運算放在值的那一邊，欄位保持乾淨

```sql
-- ❌ 錯誤：欄位被運算包住，索引失效
WHERE YEAR(date) = 2025
WHERE Price * 1.05 > 100
WHERE LEFT(CustomerCode, 2) = 'AB'

-- ✅ 正確：欄位保持乾淨
WHERE date >= '2025-01-01' AND date < '2026-01-01'
WHERE Price > 100 / 1.05
WHERE CustomerCode LIKE 'AB%'
```

### 不要在欄位上做 CAST / CONVERT / SUBSTRING

```sql
-- ❌ 會讓索引失效
WHERE SUBSTRING(CONVERT(VARCHAR, d.deposit_date, 120), 1, 10) >= @StartDate
WHERE CAST(d.member_id AS NVARCHAR) = CAST(m.member_id AS NVARCHAR)

-- ✅ 正確
WHERE d.deposit_date >= @StartDate
WHERE d.member_id = m.member_id
```

### ISNULL 陷阱

```sql
-- ❌ 當欄位本身為 NULL 時會漏資料
AND b.status = ISNULL(@Status, b.status)

-- ✅ 正確
AND (@Status IS NULL OR b.status = @Status)
```

### LIKE 模糊查詢

```sql
-- ❌ 前後 % 無法用索引，空字串時會拖累效能
AND m.member_name LIKE '%' + @MemberName + '%'

-- ✅ 空字串時短路掉
AND (@MemberName = '' OR m.member_name LIKE '%' + @MemberName + '%')
```

---

## 四、SELECT 與 JOIN

- 不要用 `SELECT *`，明確列出欄位
- 多表 JOIN 每個欄位要加**表別名**（例：`b.bet_date`）
- 避免同名欄位衝突
- JOIN 了但 SELECT 沒用到該表欄位的話，JOIN 是多餘的
- LEFT JOIN 的篩選條件位置要注意：
  - 放 WHERE 會變成 INNER JOIN 效果
  - 真要保留 LEFT JOIN 語意就放 ON 子句

---

## 五、INSERT

- **一定要明確列出欄位名稱**，不要只寫 VALUES
- 表結構變動時才不會壞掉

```sql
-- ❌ 危險
INSERT INTO wallet_transaction_log
VALUES (@MemberId, @MerchantId, ...);

-- ✅ 安全
INSERT INTO wallet_transaction_log
    (member_id, merchant_id, trans_type, amount, create_date)
VALUES
    (@MemberId, @MerchantId, @TransType, @Amount, GETDATE());
```

---

## 六、寫入類 SP 的標準架構

任何包含 UPDATE / INSERT / DELETE 的 SP 都套這個模板：

```sql
CREATE OR ALTER PROCEDURE [dbo].[sample_write_sp]
    @Param1 VARCHAR(20)
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    BEGIN TRY
        BEGIN TRAN;

            -- 讀取要修改的資料用 WITH (UPDLOCK) 而不是 NOLOCK
            SELECT @Value = col
            FROM some_table WITH (UPDLOCK)
            WHERE id = @Param1;

            -- 做 UPDATE / INSERT
            UPDATE some_table
            SET col = @NewValue
            WHERE id = @Param1;

        COMMIT TRAN;

        -- 回傳結果
        SELECT @NewValue AS result;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END;
```

### 重點觀念

- **金額、點數、庫存**這類併發敏感的操作，讀取時用 `WITH (UPDLOCK)`
- 交易要有明確的 COMMIT / ROLLBACK，IF / ELSE 每個分支都要處理
- CATCH 裡的 ROLLBACK 是備援，處理非預期錯誤（如死鎖）
- 轉帳、扣款類要檢查對方是否存在，避免資料憑空消失

```sql
IF NOT EXISTS (SELECT 1 FROM member_points WHERE member_id = @ToMemberId)
BEGIN
    ROLLBACK TRAN;
    SELECT 'Target member not found' AS result;
    RETURN;
END
```

---

## 七、查詢類 SP 的最佳化

- 讀取性查詢可以用 `WITH (NOLOCK)`（業務允許髒讀的前提下）
- 分頁查詢搭配多個可選參數，考慮 `OPTION (RECOMPILE)` 避免 parameter sniffing

---

## 八、審查順序（口訣）

> **SET → 參數 → 欄位 → JOIN → WHERE → 交易安全 → 執行計畫**

照這個順序跑，大部分問題都能抓到。

---

## 九、常用輔助查詢

### 快速查欄位型態（對照參數用）

```sql
SELECT c.name, t.name AS type_name, c.max_length
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE object_id = OBJECT_ID('dbo.YourTableName')
ORDER BY c.column_id;
```

### SSMS 常用快捷鍵

| 快捷鍵 | 功能 |
|---|---|
| `Alt + F1` | 對選取的表名快速查看結構 |
| `Ctrl + L` | 顯示估計執行計畫 |
| `Ctrl + M` | 開啟實際執行計畫 |
| `Ctrl + D` | 結果以格線顯示 |
| `Ctrl + K, Ctrl + X` | 插入程式碼片段 |

---

## 十、常見錯誤速查表

| 問題 | 症狀 | 修正 |
|---|---|---|
| NVARCHAR 對 VARCHAR 欄位 | 隱含轉換，索引失效 | 參數型態跟欄位一致 |
| FLOAT 存金額 | 浮點精度誤差 | 改用 DECIMAL(18,2) |
| 欄位上做函數運算 | Index Scan 而非 Seek | 運算移到值的那邊 |
| `ISNULL(@p, col) = col` | 欄位為 NULL 時漏資料 | `(@p IS NULL OR col = @p)` |
| `SELECT *` | 前端接收異常、效能差 | 明確列出欄位 |
| INSERT 沒列欄位 | 表結構變動就壞 | 明確列出欄位 |
| 寫入無交易包裝 | 併發覆蓋、資料不一致 | `BEGIN TRAN` + `TRY/CATCH` |
| 金額讀取用 NOLOCK | 雙重扣款、錢消失 | 改用 `WITH (UPDLOCK)` |

---

## 十一、常見多餘寫法對照表

掃描程式碼時，眼睛只要捕捉這些 pattern，看到就標記：

| 看到這個 | 就知道是多餘 | 修正 |
|---|---|---|
| `CAST(x AS VARCHAR) = CAST(y AS VARCHAR)` | 同型態轉換 | 直接比較 |
| `* 1.0`、`+ 0` | 假運算 | 拿掉 |
| `WHERE 1=1 AND ...` | 動態 SQL 殘留 | 拿掉 `1=1` |
| `WITH q AS (SELECT * FROM t) SELECT * FROM q` | 包了一層卻沒加工 | 直接寫 |
| `ISNULL(主鍵欄位, ...)` | 主鍵不可能 NULL | 直接取 |
| `DISTINCT` + `GROUP BY` | 重複去重 | 擇一 |
| `((條件))` | 過度括號 | 拿掉外層 |
| `SELECT col + 0 AS col` | 假加工 | 直接取 |

---

## 十二、排版與風格原則

### 基本原則

- 關鍵字大寫（SELECT、FROM、WHERE）
- 物件名稱小寫或保持原貌
- 子句獨立成行（SELECT、FROM、WHERE、GROUP BY、ORDER BY）
- 縮排統一用 4 個空格，不要混 Tab
- 表別名一律加 `AS`，整支 SP 風格一致

### JOIN 條件對齊範例

```sql
-- ❌ 一行寫太長
LEFT JOIN cashback_setting r WITH (NOLOCK) ON g.group_id=r.group_id AND g.merchant_id=r.merchant_id

-- ✅ 條件分行對齊
LEFT JOIN cashback_setting AS r WITH (NOLOCK)
       ON g.group_id    = r.group_id
      AND g.merchant_id = r.merchant_id
```

### WHERE 多條件對齊

```sql
WHERE  d.merchant_id = @MerchantId
  AND  d.status      = 1
  AND  d.amount     >= @MinAmount
```

`AND` 對齊、等號對齊，掃一眼就知道有哪些條件。

---

## 十三、快速審查流程（三步驟）

### Step 1：格式化（30 秒）

收到腳本第一件事，**先丟進格式化工具**，再開始看。

推薦工具：
- **Poor Man's T-SQL Formatter**（免費 SSMS 套件）
- **Redgate SQL Prompt**（付費，功能完整）
- **ApexSQL Refactor**（免費版可用）
- **線上工具**：[poorsql.com](https://poorsql.com)

### Step 2：邏輯審查（3-15 分鐘）

照前面的審查順序跑：**SET → 參數 → 欄位 → JOIN → WHERE → 交易安全**。
**這步是重點**，必改的問題都在這裡。

### Step 3：寫法掃描（1-2 分鐘）

從頭往下快速掃，眼睛找「常見多餘寫法對照表」的 pattern，看到一個標記一個。
同時注意「視覺跳動感」（縮排忽深忽淺、AS 有時加有時不加），都標記為排版問題。

---

## 十四、分級回饋

審查發現的問題，回給 RD 時分類標示：

```
【必改】@MemberId 應改為 VARCHAR,目前 NVARCHAR 會造成隱含轉換
【必改】扣款邏輯缺少交易包裝
【建議】CAST(member_id AS VARCHAR) 為多餘轉換,可拿掉
【建議】WHERE 條件可對齊以提高可讀性
【提醒】團隊 style guide 規範表別名應加 AS
```

分級標準:

- **必改**:影響效能、安全性、正確性(隱含轉換、缺交易、SELECT *)
- **建議**:可讀性、維護性問題(多餘 CAST、排版亂、命名不一致)
- **提醒**:純風格偏好(逗號前後、AS 加不加),只要不影響後續維護可不強制

---

## 十五、心法

> **排版、多餘寫法、命名不一致 → 交給工具**
> **邏輯、效能、安全 → 交給人腦**

人的注意力是有限資源,全部花在排版上就沒有力氣抓真正重要的問題。
速度的關鍵是分工:工具處理表面,你處理本質。
