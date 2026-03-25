# 📖 【DBA 實戰】SQL Server 分區表滑動視窗保養手冊

**核心觀念：**
* **資料表層級 (Table Level)**：只影響單一資料表（例如：清空房間裡的垃圾 `TRUNCATE`）。
* **函數層級 (Function Level)**：影響全資料庫綁定該把刀的所有表（例如：拆牆 `MERGE`、建新牆 `SPLIT`）。
* **執行大原則**：
  * **拆除順序**：清空資料 (`TRUNCATE`) ➡️ 拆除邏輯邊界 (`MERGE`) ➡️ 刪除實體檔案 (`REMOVE FILE`) ➡️ 刪除群組 (`REMOVE FILEGROUP`)。
  * **擴建順序**：建檔案群組 (`ADD FILEGROUP`) ➡️ 掛載實體檔案 (`ADD FILE`) ➡️ 盤子對準房間 (`NEXT USED`) ➡️ 揮刀切邊界 (`SPLIT`)。

---

## 🗑️ 第一階段：清理歷史包袱（拆除舊分區）

### 步驟 1：找出「特定刀子 (PFN)」綁定了哪些資料表
**目的**：在清資料前，必須先查清楚這把刀（例如 `Pfn_date`）到底被多少張表共用，確保不會漏清或錯殺。

```sql
-- 🔍 查詢綁定特定 Partition Function 的所有資料表
SELECT 
    pf.name AS [分割函數(刀子)],
    OBJECT_SCHEMA_NAME(i.object_id) AS [結構描述],
    OBJECT_NAME(i.object_id) AS [資料表名稱],
    i.name AS [索引名稱],
    p.partition_number AS [分區編號],
    prv.value AS [邊界值(日期)],
    p.rows AS [目前資料筆數]
FROM sys.indexes i
JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
LEFT JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id AND p.partition_number = prv.boundary_id
WHERE pf.name = 'Pfn_date' -- ⚠️ 替換成你要查的刀子名稱
  AND i.index_id <= 1      -- 只看主要資料 (Heap 或 Clustered Index)
  AND prv.value = '2020-01-01' -- ⚠️ 鎖定你要清空的那個舊月份
ORDER BY p.rows DESC;
```

### 步驟 2：清空舊房間的資料 (TRUNCATE PARTITION)
**目的**：將舊房間內的資料瞬間清空，釋放 Data Pages。
**注意**：這屬於「資料表層級」，步驟 1 查出有幾張表，這裡就要下幾次指令。

```sql
-- 🧹 清空單一資料表的特定分區 (例如清空第 1 號分區)
TRUNCATE TABLE [dbo].[provider_ticket_allbet_log] WITH (PARTITIONS (1));

-- (實務偷懶招式：用語法產生器自動寫出所有 TRUNCATE 指令)
SELECT 'TRUNCATE TABLE [' + OBJECT_SCHEMA_NAME(p.object_id) + '].[' + OBJECT_NAME(p.object_id) + '] WITH (PARTITIONS (' + CAST(p.partition_number AS VARCHAR) + '));'
FROM sys.partitions p
JOIN sys.indexes i ON p.object_id = i.object_id AND p.index_id = i.index_id
JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
WHERE ps.name = 'Psh_date' AND i.index_id <= 1 AND p.partition_number = 1; -- ⚠️ 1 為要清空的分區號碼
```

### 步驟 3：拆除邏輯隔間牆 (MERGE)
**目的**：把兩個月份的分區打通。執行後，該邊界會從資料庫系統表中徹底消失。
**注意**：這屬於「全域動作」。如果一個房間同時被 `Pfn_date` 和 `Pfn_int` 使用，**必須把所有刀的邊界都 MERGE 掉**，房間才會真正空出來。

```sql
-- 💣 拆除 2020-01-01 的邊界牆 (將它與前一個分區合併)
ALTER PARTITION FUNCTION [Pfn_date]() MERGE RANGE ('2020-01-01');

-- 若有其他刀子共用這個房間，也要一併拆除：
-- ALTER PARTITION FUNCTION [Pfn_int]() MERGE RANGE (20200101);
```

### 步驟 4：退租還地，徹底刪除實體檔案與群組 (REMOVE)
**目的**：將硬碟空間真正還給 Windows 系統。
**鐵規則**：必須先丟家具 (`.ndf`)，才能拆房間 (`Filegroup`)。房間內只要還有任何邊界或資料，系統會報錯拒絕刪除。

```sql
-- 📦 4-1: 先移除實體檔案 (這會真實刪除 E 槽的 .ndf 檔)
ALTER DATABASE [你的資料庫名稱] REMOVE FILE [實體檔案邏輯名稱_例如: tt128_data_log_202001];

-- 🏗️ 4-2: 再移除檔案群組 (Filegroup)
ALTER DATABASE [你的資料庫名稱] REMOVE FILEGROUP [群組名稱_例如: FG_202001];
```

---

## 🏗️ 第二階段：擴建未來版圖（建立新分區）



### 步驟 5：建立新的實體空間 (CREATE FILEGROUP & ADD FILE)
**目的**：向作業系統要一塊新的硬碟空間來蓋新房間。

```sql
-- 🧱 5-1: 建立新的檔案群組 (Filegroup)
ALTER DATABASE [你的資料庫名稱] ADD FILEGROUP [FG_202302];

-- 🗄️ 5-2: 在群組內掛載實體檔案 (.ndf)
-- 必須精準設定存放路徑、初始大小 (SIZE) 與自動成長量 (FILEGROWTH)
ALTER DATABASE [你的資料庫名稱] 
ADD FILE (
    NAME = N'tt128_data_log_202302', 
    FILENAME = N'E:\DB\tt128_data_log\FG_202302.ndf', 
    SIZE = 8MB, 
    FILEGROWTH = 64MB
) TO FILEGROUP [FG_202302];
```

### 步驟 6：盤子對準新房間 (NEXT USED)
**目的**：告訴「盤子 (Partition Scheme)」，等一下切下來的新蛋糕要放在剛剛蓋好的哪一個實體房間裡。
**注意**：**如果沒有做這一步，下一步的 SPLIT 絕對會報錯！**

```sql
-- 🎯 指定盤子的下一個落點
ALTER PARTITION SCHEME [Psh_date] NEXT USED [FG_202302];
```

### 步驟 7：揮刀切出新邊界 (SPLIT)
**目的**：在資料表裡正式切出一個全新的月份隔間。
**注意**：執行完這行，全資料庫有綁定這把刀的幾十張表，會**瞬間同時**多出一個新分區。

```sql
-- 🔪 切出 2023-02-01 的新邊界
ALTER PARTITION FUNCTION [Pfn_date]() SPLIT RANGE ('2023-02-01');
```

---

## 💡 專屬 DBA 避坑心法

1. **「家具與房間」的命名陷阱**：
   * `REMOVE FILE` 和 `ADD FILE` 裡面用的名字，是 **「邏輯檔案名稱 (Logical File Name)」** (通常很長，帶有資料庫名)。
   * `REMOVE FILEGROUP` 和 `NEXT USED` 裡面用的名字，是 **「檔案群組名稱 (Filegroup Name)」** (通常較短，如 `FG_YYYYMM`)。
   * 搞錯名字是報錯的第一大元兇！
2. **「隱藏房客」導致房間無法刪除**：
   * 當你確認已經 `TRUNCATE` 也 `MERGE` 了，但 `REMOVE FILEGROUP` 還是報錯說「房間不為空」時。100% 是因為有「另一把刀 (如 `Pfn_int`)」的邊界還指著這個房間。必須把所有刀的舊邊界都 MERGE 乾淨。
3. **不能只切一張表的邊界**：
   * 共用同一把刀的表，同生共死。如果某張表要搞特權（例如：別人留五年，它只留兩個月），唯一的解法是幫它建專屬的 PF/PS，然後用 `CREATE INDEX ... WITH (DROP_EXISTING = ON)` 幫它重建索引搬家。
   * 實務上更常做的妥協是：對它下 `TRUNCATE` 清空資料就好，**空房間的邊界留著不 MERGE 也不會影響效能與空間**。