# SQL Server SP 審查 - 進階議題

適用於 SQL Server 2022,延伸自基礎 SP 審查 Checklist。
當基礎項目(SET、參數、JOIN、交易)都熟練後,可進一步檢視以下進階議題。

---

## 一、NOLOCK 的真相與替代方案

### NOLOCK 的副作用

`WITH (NOLOCK)` 等同於 `READ UNCOMMITTED` 隔離層級,實務上很多人誤以為它只是
「不鎖表、效能好」,但它其實有嚴重副作用:

| 副作用 | 說明 |
|---|---|
| **髒讀(Dirty Read)** | 讀到其他交易還沒 COMMIT 的資料,對方 ROLLBACK 後資料就不存在了 |
| **重複列(Duplicate Reads)** | page 分裂時同一筆資料可能被讀到兩次 |
| **漏列(Missing Rows)** | page 移動時某些資料可能完全讀不到 |
| **Schema 變動時報錯** | 讀取時遇到 DDL 變更可能拋出奇怪錯誤 |

### NOLOCK 適用場景判斷

| 業務類型 | 是否適合 NOLOCK |
|---|---|
| 金流、庫存、點數、餘額 | ❌ 絕對不行 |
| 訂單成立、交易紀錄 | ❌ 不行 |
| 報表、統計、分析 | ⚠ 視需求 |
| 客戶篩選、行銷名單 | ✅ 可接受 |
| 首頁顯示、列表 | ✅ 可接受 |

### 替代方案比較

| 方式 | 優點 | 缺點 |
|---|---|---|
| `WITH (NOLOCK)` | 寫在每個查詢,彈性 | 髒讀、漏讀、語法髒 |
| `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` | SP 層級控制 | 仍有髒讀問題 |
| **`READ COMMITTED SNAPSHOT`** (DB 層級) | 不鎖、不髒讀、版本控制 | tempdb 負擔變大 |
| `SNAPSHOT ISOLATION` | 同上,且可查交易開始時的版本 | tempdb 負擔更大 |

### 推薦做法

**DBA 應該評估整個資料庫啟用 RCSI**:

```sql
ALTER DATABASE YourDB SET READ_COMMITTED_SNAPSHOT ON;
```

啟用後就能拿掉 SP 裡所有 `WITH (NOLOCK)`,一勞永逸。
但啟用前要評估 tempdb 容量是否足夠,因為會多出版本儲存空間。

### 審查回饋範例

```
【建議】整支 SP 使用大量 NOLOCK,可能讀到髒資料。
如業務允許建議:
1. 移除所有 WITH (NOLOCK)
2. 評估資料庫啟用 READ COMMITTED SNAPSHOT 隔離層級
3. 若暫時保留 NOLOCK,需在文件說明業務為何可以接受髒讀
```

---

## 二、UNION ALL 多段查詢的合併考量

### 問題徵兆

SP 中有多個 UNION ALL 段落,每段都 JOIN 同樣的幾張表,
只有 WHERE 條件不同。等於同樣的關聯做了好幾次。

### 合併思路

把共用的 JOIN 只做一次,用 OR 條件把多個篩選合併在 WHERE 子句:

```sql
-- ❌ 三段式 UNION ALL
SELECT ... FROM A JOIN B JOIN C WHERE 條件1
UNION ALL
SELECT ... FROM A JOIN B JOIN C WHERE 條件2
UNION ALL
SELECT ... FROM A JOIN B JOIN C WHERE 條件3

-- ✅ 合併版
SELECT ... FROM A JOIN B JOIN C
WHERE 條件1 OR 條件2 OR 條件3
```

### 取捨分析

| 比較點 | UNION ALL 多段 | OR 合併 |
|---|---|---|
| 可讀性 | 邏輯分段清楚 | 條件集中但邊界模糊 |
| 重複 JOIN | 會 | 不會 |
| 最佳化器友善度 | 通常較佳 | **OR 條件常難以最佳化** |
| 維護難度 | 改一段不影響其他 | 改動容易互相干擾 |

### 實務建議

**不要為了「看起來聰明」而過早最佳化**。

- 先保留 UNION ALL 版本(邏輯清楚)
- 實際跑起來發現效能瓶頸,才考慮合併
- 合併後一定要比對執行計畫,確認真的變好

---

## 三、參數命名與驗證

### 常見命名問題

```sql
-- ❌ 命名冗餘、匈牙利命名
@paramIntCategoryId INT
@strCustomerName NVARCHAR(50)
@p1 INT
@x VARCHAR(10)

-- ✅ 簡潔、跟欄位名對應
@CategoryId INT
@CustomerName NVARCHAR(50)
@StartDate DATETIME
@MaxResults INT
```

### 預設值原則

- 可選參數應有預設值,呼叫時才不用每次都傳
- 預設 `NULL` 通常比預設空字串 `''` 更安全,能明確區分「沒傳」和「傳了空值」

```sql
CREATE PROC dbo.proc_get_orders
    @CustomerId INT,                 -- 必要參數,無預設值
    @StartDate  DATETIME = NULL,     -- 可選,預設 NULL
    @Status     INT      = NULL      -- 可選,預設 NULL
AS
BEGIN
    ...
END
```

### 參數驗證

複雜 SP 應該在開頭驗證參數合法性:

```sql
CREATE PROC dbo.proc_find_customers
    @CategoryId INT = NULL
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    -- 必要參數驗證
    IF @CategoryId IS NULL
    BEGIN
        RAISERROR('CategoryId is required.', 16, 1);
        RETURN;
    END

    -- 業務合法性驗證
    IF NOT EXISTS (
        SELECT 1 FROM production.productcategory
        WHERE productcategoryid = @CategoryId
    )
    BEGIN
        RAISERROR('CategoryId %d does not exist.', 16, 1, @CategoryId);
        RETURN;
    END

    -- 主查詢
    ...
END
```

---

## 四、TRY/CATCH 的判斷原則

### 讀取類 vs 寫入類

| SP 類型 | 是否需要 TRY/CATCH |
|---|---|
| 純查詢 SELECT | ⚠ 不一定需要 |
| 單純 INSERT/UPDATE/DELETE | ✅ 建議加 |
| 多步驟 DML 操作 | ✅ **必須加** |
| 金融、庫存、點數 | ✅ **必須加 + TRAN** |

### 讀取類何時加 TRY/CATCH?

基本讀取不需要,但以下情境需要:

- 查詢中有複雜的商業邏輯(多步驟計算)
- 需要記錄錯誤到自訂 error log 表
- 需要回傳自訂錯誤碼
- 需要記錄查詢使用 log

### 讀取類加 TRY/CATCH 範例

```sql
BEGIN TRY
    -- 主查詢
    SELECT ...

    -- 記錄查詢 log
    INSERT INTO dbo.query_log (proc_name, param_json, query_time)
    VALUES ('proc_find_customers',
            JSON_OBJECT('CategoryId': @CategoryId),
            SYSUTCDATETIME());
END TRY
BEGIN CATCH
    INSERT INTO dbo.error_log (error_number, error_message, error_time)
    VALUES (ERROR_NUMBER(), ERROR_MESSAGE(), SYSUTCDATETIME());

    THROW;
END CATCH
```

### 寫入類標準模板(重要)

```sql
CREATE PROC dbo.proc_write_something
    @Param1 VARCHAR(20)
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    BEGIN TRY
        BEGIN TRAN;

            -- 讀取敏感資料用 UPDLOCK
            SELECT @Value = col
            FROM some_table WITH (UPDLOCK)
            WHERE id = @Param1;

            -- 執行 DML
            UPDATE some_table
            SET col = @NewValue
            WHERE id = @Param1;

            INSERT INTO log_table (...) VALUES (...);

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        THROW;
    END CATCH
END
```

---

## 五、索引與執行計畫

### 看執行計畫的基本動作

在 SSMS 執行 SP 前按 `Ctrl + M`(包含實際執行計畫),
然後執行 SP,會多一個分頁「執行計畫」。

### 執行計畫檢查重點

| 徵兆 | 意義 | 處理方向 |
|---|---|---|
| **Table Scan / Clustered Index Scan** | 全表掃描 | 確認 WHERE 欄位有無索引 |
| **Index Scan** | 掃描整個索引 | 看能否變成 Seek |
| **Index Seek** | 理想情況 | 保持 |
| **Key Lookup** (超過 50%) | 找到索引後回主表查其他欄位 | 考慮 INCLUDE 欄位或擴大索引 |
| **黃色驚嘆號** | 警告(隱含轉換、統計資訊過期) | 點開看細節 |
| **Hash Match** | 雜湊 JOIN | 通常 OK,但大表要確認統計 |
| **估計列數 vs 實際列數差異大** | 統計資訊過期 | 更新統計 |

### 常見修正手段

**隱含轉換警告**

```sql
-- ❌ 欄位型態 VARCHAR,參數傳 NVARCHAR
DECLARE @id NVARCHAR(20) = N'A001';
SELECT * FROM customer WHERE customer_code = @id;

-- ✅ 參數型態對齊欄位
DECLARE @id VARCHAR(20) = 'A001';
SELECT * FROM customer WHERE customer_code = @id;
```

**Key Lookup 過多**

```sql
-- 原索引
CREATE INDEX IX_orders_customerid ON orders(customer_id);

-- 改成涵蓋索引,減少 Key Lookup
CREATE INDEX IX_orders_customerid_covering
    ON orders(customer_id)
    INCLUDE (order_date, amount, status);
```

**統計資訊過期**

```sql
-- 手動更新統計
UPDATE STATISTICS dbo.orders WITH FULLSCAN;

-- 或更新整個資料庫
EXEC sp_updatestats;
```

### 建索引的謹慎原則

- 索引越多,INSERT/UPDATE/DELETE 越慢
- 索引要根據實際查詢模式設計,不要憑感覺亂加
- 建索引前先用 `sys.dm_db_missing_index_details` 查看 SQL Server 的建議
- 建完後實測執行計畫是否真的有用

---

## 六、統計 IO 與執行時間(證明改寫有效的方法)

### 開啟統計

```sql
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

EXEC dbo.proc_find_customers @CategoryId = 1;
```

### 要看的數字

**邏輯讀取(logical reads)**:SQL Server 從 buffer pool 讀取的 page 數。
這是**判斷查詢效率最客觀的指標**,跟硬體無關。

**實體讀取(physical reads)**:從磁碟讀的 page 數。第一次執行會有,
之後資料在記憶體就是 0,所以不太可靠。

**CPU time**:花多少 CPU 時間。重度運算型查詢看這個。

**Elapsed time**:總耗時。受伺服器負載影響,不穩定。

### 改寫前後比較範例

```
原始版本:
Table 'salesorderheader'. Scan count 3, logical reads 15234
Table 'customer'.         Scan count 3, logical reads 892
Table 'person'.           Scan count 3, logical reads 445
CPU time = 890 ms,  elapsed time = 1250 ms

改寫版本:
Table 'salesorderheader'. Scan count 1, logical reads 5078
Table 'customer'.         Scan count 1, logical reads 297
Table 'person'.           Scan count 1, logical reads 148
CPU time = 215 ms,  elapsed time = 310 ms
```

從 Scan count 和 logical reads 可看出「三次 JOIN 合併成一次」的效果。

---

## 七、進階審查 Checklist

把這些補充到日常審查流程:

### NOLOCK 檢查
- [ ] NOLOCK 使用是否合理?業務是否能接受髒讀?
- [ ] 是否該評估改用 READ COMMITTED SNAPSHOT?
- [ ] 金流/庫存類操作是否誤用 NOLOCK?

### UNION/JOIN 檢查
- [ ] UNION ALL 多段是否有共用邏輯可合併?
- [ ] 合併是否會讓 OR 條件難以最佳化?
- [ ] 是否該保留分段版本以維持可讀性?

### 參數檢查
- [ ] 參數命名是否簡潔(無匈牙利命名)?
- [ ] 是否有合理預設值?
- [ ] 是否有必要的驗證邏輯?
- [ ] 錯誤時是否給出清楚的錯誤訊息?

### TRY/CATCH 檢查
- [ ] 讀取類 SP:TRY/CATCH 是必要還是贅述?
- [ ] 寫入類 SP:是否有 TRY/CATCH + TRAN?
- [ ] CATCH 內是否有 `IF @@TRANCOUNT > 0 ROLLBACK`?
- [ ] 是否有 `THROW` 讓呼叫端知道錯誤?

### 執行計畫檢查
- [ ] 有沒有 Table Scan / Clustered Index Scan on 大表?
- [ ] 有沒有黃色驚嘆號警告?
- [ ] Key Lookup 占比是否過高?
- [ ] 估計列數 vs 實際列數是否差異過大?

### 效能驗證
- [ ] 有沒有跑 SET STATISTICS IO/TIME 量化改寫效果?
- [ ] 改寫前後的 logical reads 差異如何?
- [ ] 是否有適合的索引支援 WHERE 條件?

---

## 八、推薦閱讀

- **Aaron Bertrand - 40 Common SP Problems**
  [red-gate.com simple-talk](https://www.red-gate.com/simple-talk/databases/sql-server/t-sql-programming-sql-server/40-problems-sql-server-stored-procedure/)
  本指南多數觀念來自這篇經典文章,強烈建議整篇讀完。

- **Brent Ozar 部落格**
  [brentozar.com](https://www.brentozar.com/)
  SQL Server 效能調校權威,特別擅長索引、執行計畫、parameter sniffing。

- **Microsoft Learn - SQL Server Documentation**
  [learn.microsoft.com/sql](https://learn.microsoft.com/sql)
  官方文件,T-SQL 語法、DMV、執行計畫、Extended Events 都有完整說明。

---

## 九、心態建議

### 進階審查的兩難

- 追求完美 → 效率低、拖累開發進度
- 只看表面 → 問題埋到正式環境才爆

### 平衡原則

- **必改**:影響正確性、安全性、效能重大的 → 上線前必須修
- **建議**:可讀性、維護性、效能微幅改善 → 記錄下來,下次 refactor 一起處理
- **提醒**:純風格、團隊規範差異 → 不強制,只提醒

### 審查者的本分

> 不要當「擋路的警察」,要當「幫忙把關的隊友」。

好的審查是**教育 RD、不是批鬥**。每次回饋都說明「為什麼要改」,
讓對方下次能自己避開。長期下來整個團隊的 SQL 品質就會提升。
