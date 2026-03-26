# 🏆 【DBA 實戰筆記】cmd_data_log 分區資料維護終極 SOP

**維護標的**：`cmd_data_log` 資料庫
**實體檔案路徑**：`E:\DB\cmd_data_log\`
**核心分區函數**：`Pfn_date` (純日期)、`Pfn_datetime` (含時間)
**執行原則**：先清資料 (TRUNCATE) ➡️ 拆邏輯空房 (MERGE) ➡️ 刪實體檔案 (REMOVE) ➡️ 建新實體檔 (ADD FILE) ➡️ 切新邏輯房 (SPLIT)

---

## 🟢 第一階段：全庫盤點與分區表定位 (分區雷達)
**目的**：下刀前，先確認資料庫內各大表的分區狀況與資料量。
**⚠️ 注意**：請確保 SSMS 左上角已切換至 `cmd_data_log`。

```sql
USE [cmd_data_log];
GO

-- =============================================
-- 用途: 查詢資料庫內有掛載 Partition 機制的大表與總筆數
-- 說明: 透過關聯系統表，找出哪些表用了哪些分區函數，以及目前的資料量
-- =============================================
SELECT DISTINCT
    t.name AS TableName,                     -- 資料表名稱
    ps.name AS PartitionSchemeName,          -- 該表使用的分區配置機制 (Scheme)
    pf.name AS PartitionFunctionName,        -- 該表使用的分區切割刀 (Function)
    COUNT(p.partition_number) AS TotalPartitionCount, -- 計算這張表總共被切成了幾個分區
    SUM(p.rows) AS TotalRows                 -- 加總所有分區的資料筆數，得出總資料量
FROM sys.tables t
-- 關聯索引表 (因為分區通常是跟著 Clustered Index 建立的)
INNER JOIN sys.indexes i ON t.object_id = i.object_id
-- 關聯分區實體表，取得每個分區的細節 (如筆數)
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
-- 關聯 Scheme 表，得知資料是怎麼分配到 Filegroup 的
INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
-- 關聯 Function 表，得知是用哪一把刀切的 (例如 Pfn_date)
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
WHERE i.index_id <= 1 -- 條件：只看主要資料 (Heap 或 Clustered Index)，避免把其他索引算進去導致重複計算
GROUP BY t.name, ps.name, pf.name
ORDER BY TotalRows DESC; -- 依照資料量由大到小排序，抓出最肥的表
```

---

## 🔴 第二階段：秒殺歷史舊資料 (TRUNCATE PARTITION)
**目的**：瞬間清空指定月份範圍的資料，不產生大量 Transaction Log。
**⚠️ 注意**：此腳本會產生清單，請複製 `GeneratedCommand` 的結果去執行。

```sql
USE [cmd_data_log];
GO

-- =============================================
-- 用途: 自動產生大範圍 TRUNCATE (例如 1 到 25 區) 的批次清單
-- 說明: 找出所有被 Pfn_date 和 Pfn_datetime 切割的表，並組裝出 TRUNCATE 語法
-- =============================================
SELECT DISTINCT
    -- 【核心組裝區】把資料表名稱塞進字串，組出 TRUNCATE TABLE ... WITH (PARTITIONS (...)) 的語法
    -- 這裡的 1 TO 25 代表一次清空第 1 區到第 25 區的所有資料
    'TRUNCATE TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] WITH (PARTITIONS (1 TO 25));' AS GeneratedCommand,
    
    t.name AS TableName,              -- 顯示表名供參考確認
    pf.name AS PartitionFunctionName  -- 顯示使用的刀供參考確認
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
WHERE i.index_id <= 1  
  AND pf.name IN ('Pfn_date', 'Pfn_datetime') -- 🎯 條件：只鎖定這兩把主刀切出來的表
ORDER BY t.name;
```

---

## 🟡 第三階段：拆除邏輯空房間 (MERGE RANGE)
**目的**：資料清空後，回收舊的邊界釋放資源。
**⚠️ 絕對防坑**：**永遠只能 MERGE「沒有資料」的空分區！** 否則會觸發底層資料大搬移導致硬碟卡死。



```sql
USE [cmd_data_log];
GO

-- =============================================
-- 用途: 自動產生合併邊界 (MERGE RANGE) 的語法清單
-- 說明: 針對已清空的前 25 區，產生拆除邊界的 ALTER PARTITION FUNCTION 指令
-- =============================================
SELECT 
    -- 【核心組裝區】組裝 ALTER PARTITION FUNCTION ... MERGE RANGE ('日期')
    -- CONVERT(..., 121) 是為了確保 datetime 格式會帶上標準的 yyyy-mm-dd hh:mi:ss.mmm，避免報錯
    'ALTER PARTITION FUNCTION [' + pf.name + '] () MERGE RANGE (''' + CONVERT(NVARCHAR(50), prv.value, 121) + ''');' AS GeneratedCommand,
    
    pf.name AS PartitionFunctionName, -- 分區函數名稱
    prv.boundary_id AS BoundaryID,    -- 邊界編號 (也就是第幾個邊界)
    prv.value AS BoundaryValue        -- 實際的邊界值 (例如 2022-01-01)
FROM sys.partition_functions pf
-- 關聯邊界值表，取得每一個切點的日期時間
INNER JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id
WHERE pf.name IN ('Pfn_date', 'Pfn_datetime') 
  AND prv.boundary_id <= 25 -- 🎯 條件：鎖定前 25 個邊界 (請根據你實際清空的區塊調整此數字)
ORDER BY pf.name, prv.value;
```

---

## 🔵 第四階段：實體空間回收 (REMOVE FILE / FILEGROUP)
**目的**：徹底釋放 E 槽硬碟空間。
**順序**：必須先 `REMOVE FILE` (.ndf)，再 `REMOVE FILEGROUP`。

```sql
USE [cmd_data_log];
GO

-- =============================================
-- 用途: 自動產生移除實體檔案 (.ndf) 與檔案群組的語法
-- 說明: 將空殼檔案拔除，把硬碟空間還給 Windows
-- =============================================
SELECT 
    -- 【核心組裝區】一行指令包含兩個動作：
    -- 動作 1: 拔除實體的 .ndf 檔案 (這步做完硬碟空間就會釋放)
    'ALTER DATABASE [' + DB_NAME() + '] REMOVE FILE [' + df.name + ']; ' +
    -- 動作 2: 拔除邏輯的檔案群組 (Filegroup)
    'ALTER DATABASE [' + DB_NAME() + '] REMOVE FILEGROUP [' + fg.name + '];' AS GeneratedCommand,
    
    fg.name AS FileGroupName, -- 檔案群組名稱 (例如 FG_202201)
    
    -- 【容量計算】把檔案的 Size (以 8KB 為單位) 換算成 GB，讓你知道清出了多少空間
    CAST((df.size * 8.0) / 1024 / 1024 AS DECIMAL(10, 2)) AS FileSizeGB 
FROM sys.filegroups fg
-- 關聯資料庫檔案表，找到群組底下的實體檔案
INNER JOIN sys.database_files df ON fg.data_space_id = df.data_space_id
WHERE fg.name <> 'PRIMARY' -- 🛡️ 絕對防禦：PRIMARY 群組是系統心臟，絕對不可刪除
ORDER BY fg.name;
```

---

## 🟣 第五階段：預建未來分區 (ADD FILE / SPLIT RANGE)
**目的**：幫未來的月份打好地基並切好房間，避免資料全部擠在同一個分區。

### 步驟 5-1：預建 Filegroup 與實體檔案 (.ndf)

```sql
USE [cmd_data_log];
GO

-- 🎯 設定 E 槽儲存 .ndf 檔案的實際資料夾路徑
DECLARE @BasePath NVARCHAR(255) = 'E:\DB\cmd_data_log\'; 

-- 【CTE 遞迴區】自動產生 2027 年 1 月到 12 月的連續日期表
WITH DateCTE AS (
    SELECT CAST('2027-01-01' AS DATE) AS BoundaryDate
    UNION ALL
    SELECT DATEADD(MONTH, 1, BoundaryDate)
    FROM DateCTE
    WHERE BoundaryDate < '2027-12-01'
)
SELECT 
    -- 【核心組裝區】動作 1: 依照月份建立對應的 Filegroup (例如 FG_202701)
    'ALTER DATABASE [' + DB_NAME() + '] ADD FILEGROUP [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' +
    
    -- 【核心組裝區】動作 2: 建立 .ndf 實體檔案，放在 E 槽路徑下，並指派給剛剛建好的 Filegroup
    -- SIZE = 8MB (初始大小), FILEGROWTH = 64MB (每次長大的幅度)
    'ALTER DATABASE [' + DB_NAME() + '] ADD FILE (NAME = N''' + DB_NAME() + '_' + FORMAT(BoundaryDate, 'yyyyMM') + ''', FILENAME = N''' + @BasePath + DB_NAME() + '_' + FORMAT(BoundaryDate, 'yyyyMM') + '.ndf'', SIZE = 8MB, FILEGROWTH = 64MB) TO FILEGROUP [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + '];' AS GeneratedCommand
FROM DateCTE;
```

### 步驟 5-2：切分區並綁定至專屬 Filegroup



```sql
USE [cmd_data_log];
GO

-- 【CTE 遞迴區】一樣自動產生 2027 年的連續日期表
WITH DateCTE AS (
    SELECT CAST('2027-01-01' AS DATE) AS BoundaryDate
    UNION ALL
    SELECT DATEADD(MONTH, 1, BoundaryDate)
    FROM DateCTE
    WHERE BoundaryDate < '2027-12-01'
)
-- 【組裝純日期 Pfn_date 的切刀語法】
SELECT 
    -- 動作 1: 宣告「下一個切出來的房間，要放在哪一個 Filegroup」 (NEXT USED)
    'ALTER PARTITION SCHEME [Psch_date] NEXT USED [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' + 
    -- 動作 2: 正式下刀，切出該月份的邊界 (SPLIT RANGE)
    'ALTER PARTITION FUNCTION [Pfn_date] () SPLIT RANGE (''' + CONVERT(VARCHAR(10), BoundaryDate, 120) + ''');' 
    AS GeneratedCommand,
    CONVERT(VARCHAR(10), BoundaryDate, 120) AS TargetMonth,
    'Pfn_date' AS FunctionName
FROM DateCTE

UNION ALL

-- 【組裝含時間 Pfn_datetime 的切刀語法】
SELECT 
    -- 動作 1: 同樣宣告 NEXT USED
    'ALTER PARTITION SCHEME [Psch_datetime] NEXT USED [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' + 
    -- 動作 2: 正式下刀，注意這裡強制補上了 00:00:00.000 的時間格式
    'ALTER PARTITION FUNCTION [Pfn_datetime] () SPLIT RANGE (''' + CONVERT(VARCHAR(10), BoundaryDate, 120) + ' 00:00:00.000'');' 
    AS GeneratedCommand,
    CONVERT(VARCHAR(10), BoundaryDate, 120) AS TargetMonth,
    'Pfn_datetime' AS FunctionName
FROM DateCTE
ORDER BY TargetMonth, FunctionName; -- 依照月份排序產出
```