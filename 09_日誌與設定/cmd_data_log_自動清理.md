# 🚀 【DBA 終極神器】cmd_data_log 零手動全自動維護筆記

**💡 核心觀念：**
這兩支腳本使用了 `動態 SQL (Dynamic SQL) + 暫存表 (Temp Table) + WHILE 迴圈` 的技術。
系統會先在背景把所有需要執行的指令「組裝成字串」存起來，然後用迴圈一行一行自動觸發，完全免去人工複製貼上的風險。

---

## 🛡️【一鍵清理舊年份】全自動斬草除根腳本

**功能**：自動掃描並清空指定邊界（例如 1~25 區）的資料 ➡️ 自動打通空房間 ➡️ 產出拔除實體檔案的語法供最後確認。
**使用時機**：硬碟亮紅燈，或例行性大掃除時。

```sql
USE [cmd_data_log];
GO

-- 關閉影響行數的回傳訊息，讓底下的執行過程畫面更乾淨
SET NOCOUNT ON; 

-- =====================================================================
-- ⚙️ [參數設定區] (執行前請先確認這裡)
-- =====================================================================
-- 🎯 填入你要清空並拆除的「最大邊界編號」
-- (例如填入 25，代表第 1 區到第 25 區的資料都會被清空，牆壁也會被拆掉)
DECLARE @MaxBoundaryToPurge INT = 25; 

PRINT '開始執行【一鍵全自動清理腳本】... 鎖定邊界: 1 到 ' + CAST(@MaxBoundaryToPurge AS VARCHAR(10));
PRINT '--------------------------------------------------';

-- =====================================================================
-- 🛠️ 準備階段: 建立「待辦事項」暫存表
-- =====================================================================
-- 如果暫存表已經存在就先刪掉，避免重複執行時報錯
IF OBJECT_ID('tempdb..#CleanupQueue') IS NOT NULL DROP TABLE #CleanupQueue;

-- 建立一個存在記憶體裡的表，用來排隊等著執行 SQL 指令
CREATE TABLE #CleanupQueue (
    ID INT IDENTITY(1,1),     -- 自動遞增的排隊號碼牌 (迴圈靠這個跑)
    SqlCmd NVARCHAR(MAX),     -- 組裝好的完整 SQL 語法字串
    ActionType VARCHAR(50)    -- 幫這個動作取個名字 (方便印出進度)
);

-- =====================================================================
-- 🛠️ 階段 1: 收集 TRUNCATE 指令 (清空資料)
-- =====================================================================
INSERT INTO #CleanupQueue (SqlCmd, ActionType)
SELECT DISTINCT
    -- 動態組裝: TRUNCATE TABLE [結構].[表名] WITH (PARTITIONS (1 TO N))
    'TRUNCATE TABLE [' + SCHEMA_NAME(t.schema_id) + '].[' + t.name + '] WITH (PARTITIONS (1 TO ' + CAST(@MaxBoundaryToPurge AS VARCHAR(10)) + '));',
    '1_TRUNCATE'
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partition_schemes ps ON i.data_space_id = ps.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
-- 鎖定只找 Pfn_date 和 Pfn_datetime 這兩把主刀切出來的表
WHERE i.index_id <= 1 AND pf.name IN ('Pfn_date', 'Pfn_datetime');

-- =====================================================================
-- 🛠️ 階段 2: 收集 MERGE 指令 (拆除邏輯邊界)
-- =====================================================================
INSERT INTO #CleanupQueue (SqlCmd, ActionType)
SELECT 
    -- 動態組裝: ALTER PARTITION FUNCTION [刀名] () MERGE RANGE ('邊界日期')
    'ALTER PARTITION FUNCTION [' + pf.name + '] () MERGE RANGE (''' + CONVERT(NVARCHAR(50), prv.value, 121) + ''');',
    '2_MERGE'
FROM sys.partition_functions pf
INNER JOIN sys.partition_range_values prv ON pf.function_id = prv.function_id
-- 鎖定目標：小於等於我們設定的 @MaxBoundaryToPurge 的邊界
WHERE pf.name IN ('Pfn_date', 'Pfn_datetime') AND prv.boundary_id <= @MaxBoundaryToPurge;

-- =====================================================================
-- 🛠️ 階段 3: 印出 REMOVE FILE/FILEGROUP 指令 (拔除實體檔案)
-- =====================================================================
-- ⚠️ [安全防禦機制] 
-- 刪除實體檔案是不可逆的，萬一前面的 TRUNCATE 卡住，這裡直接自動刪除會釀成大禍。
-- 所以這裡「不寫入」自動執行的暫存表，而是單純 SELECT 出來，讓 DBA 最後手動貼上執行。
PRINT '⚠️ [安全提示] 實體檔案拔除 (REMOVE) 具有不可逆風險。';
PRINT '請在 TRUNCATE 與 MERGE 成功跑完後，手動執行以下拔除指令：';
SELECT 
    'ALTER DATABASE [' + DB_NAME() + '] REMOVE FILE [' + df.name + ']; ' +
    'ALTER DATABASE [' + DB_NAME() + '] REMOVE FILEGROUP [' + fg.name + '];' AS SafeRemoveCommand
FROM sys.filegroups fg
INNER JOIN sys.database_files df ON fg.data_space_id = df.data_space_id
WHERE fg.name <> 'PRIMARY' 
-- 檢查機制：確保這個 Filegroup 上面已經「沒有任何資料綁定」才列出來
  AND NOT EXISTS (
    SELECT 1 FROM sys.allocation_units au WHERE au.data_space_id = fg.data_space_id
);

-- =====================================================================
-- 🚀 執行迴圈：開始背景全自動打怪
-- =====================================================================
DECLARE @CurrentID INT = 1;         -- 設定迴圈起點
DECLARE @MaxID INT;                 -- 設定迴圈終點 (總共有幾行指令)
DECLARE @CurrentCmd NVARCHAR(MAX);  -- 存放目前迴圈抓出來的 SQL 語法
DECLARE @CurrentAction VARCHAR(50); -- 存放目前迴圈的動作名稱

-- 取得總指令數
SELECT @MaxID = ISNULL(MAX(ID), 0) FROM #CleanupQueue;

-- 當目前號碼牌小於等於總號碼牌時，繼續跑
WHILE @CurrentID <= @MaxID
BEGIN
    -- 根據號碼牌 (@CurrentID) 把語法從暫存表抓出來
    SELECT @CurrentCmd = SqlCmd, @CurrentAction = ActionType FROM #CleanupQueue WHERE ID = @CurrentID;
    
    -- 在訊息視窗印出進度條，讓你看了心安
    PRINT '執行中 [' + @CurrentAction + '] (' + CAST(@CurrentID AS VARCHAR) + '/' + CAST(@MaxID AS VARCHAR) + '): ' + LEFT(@CurrentCmd, 100) + '...';
    
    -- 🎯 扣下板機：呼叫系統預存程序，將字串當作真正的 SQL 指令執行！
    EXEC sp_executesql @CurrentCmd;
    
    -- 號碼牌 +1，準備處理下一行
    SET @CurrentID = @CurrentID + 1;
END

PRINT '--------------------------------------------------';
PRINT '🎉 歷史資料清理與邊界拆除已全數完成！';
-- 任務結束，刪除暫存表釋放記憶體
DROP TABLE #CleanupQueue;
GO
```

---

## 🏗️【一鍵無腦擴充】全自動蓋房腳本

**功能**：自動根據你設定的「起訖月份」，產生對應的 Filegroup ➡️ 建立 `8MB` 的 `.ndf` 檔案 ➡️ 綁定 `NEXT USED` ➡️ 切割出新房間 (`SPLIT`)。
**使用時機**：預先建立未來一整年的分區時。

```sql
USE [cmd_data_log];
GO

SET NOCOUNT ON;

-- =====================================================================
-- ⚙️ [參數設定區] (執行前請先確認這裡)
-- =====================================================================
DECLARE @StartDate DATE = '2028-01-01';             -- 🎯 新建房間的「起始月份」(請設定為該月1號)
DECLARE @EndDate DATE = '2028-12-01';               -- 🎯 新建房間的「結束月份」(請設定為該月1號)
DECLARE @BasePath NVARCHAR(255) = 'E:\DB\cmd_data_log\'; -- 🎯 E 槽實體檔案存放路徑 (結尾必須有 \)

PRINT '開始執行【一鍵全自動擴建腳本】... 擴建範圍: ' + CAST(@StartDate AS VARCHAR) + ' 到 ' + CAST(@EndDate AS VARCHAR);
PRINT '--------------------------------------------------';

-- =====================================================================
-- 🛠️ 準備階段: 建立「待辦事項」暫存表
-- =====================================================================
IF OBJECT_ID('tempdb..#ExpandQueue') IS NOT NULL DROP TABLE #ExpandQueue;
CREATE TABLE #ExpandQueue (ID INT IDENTITY(1,1), SqlCmd NVARCHAR(MAX), ActionType VARCHAR(50));

-- =====================================================================
-- 🛠️ 階段 1: 收集 ADD FILEGROUP & ADD FILE 指令 (建立實體抽屜櫃與抽屜)
-- =====================================================================
-- 使用 CTE (公用資料表運算式) 產生兩個日期之間的「連續月份清單」
;WITH DateCTE AS (
    SELECT @StartDate AS BoundaryDate
    UNION ALL
    SELECT DATEADD(MONTH, 1, BoundaryDate) FROM DateCTE WHERE BoundaryDate < @EndDate
)
-- 把產生出來的每個月份，組裝成建檔語法塞進暫存表
INSERT INTO #ExpandQueue (SqlCmd, ActionType)
SELECT 
    -- 動作 A: 建立以年月命名的 Filegroup (例如 FG_202801)
    'ALTER DATABASE [' + DB_NAME() + '] ADD FILEGROUP [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' +
    -- 動作 B: 建立實體 .ndf 檔案，綁定路徑，初始大小 8MB，每次成長 64MB
    'ALTER DATABASE [' + DB_NAME() + '] ADD FILE (NAME = N''' + DB_NAME() + '_' + FORMAT(BoundaryDate, 'yyyyMM') + ''', FILENAME = N''' + @BasePath + DB_NAME() + '_' + FORMAT(BoundaryDate, 'yyyyMM') + '.ndf'', SIZE = 8MB, FILEGROWTH = 64MB) TO FILEGROUP [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + '];',
    '1_ADD_FILE'
FROM DateCTE;

-- =====================================================================
-- 🛠️ 階段 2: 收集 SPLIT RANGE 指令 (切割邏輯房間)
-- =====================================================================
-- 再次使用 CTE 產生連續月份清單
;WITH DateCTE AS (
    SELECT @StartDate AS BoundaryDate
    UNION ALL
    SELECT DATEADD(MONTH, 1, BoundaryDate) FROM DateCTE WHERE BoundaryDate < @EndDate
)
INSERT INTO #ExpandQueue (SqlCmd, ActionType)
-- 上半部：處理純日期的 Pfn_date (宣告 NEXT USED 後直接下刀 SPLIT)
SELECT 
    'ALTER PARTITION SCHEME [Psch_date] NEXT USED [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' + 
    'ALTER PARTITION FUNCTION [Pfn_date] () SPLIT RANGE (''' + CONVERT(VARCHAR(10), BoundaryDate, 120) + ''');', 
    '2_SPLIT_DATE' 
FROM DateCTE
UNION ALL
-- 下半部：處理含時間的 Pfn_datetime (宣告 NEXT USED 後，時間強制補上 00:00:00.000)
SELECT 
    'ALTER PARTITION SCHEME [Psch_datetime] NEXT USED [FG_' + FORMAT(BoundaryDate, 'yyyyMM') + ']; ' + 
    'ALTER PARTITION FUNCTION [Pfn_datetime] () SPLIT RANGE (''' + CONVERT(VARCHAR(10), BoundaryDate, 120) + ' 00:00:00.000'');', 
    '3_SPLIT_DATETIME' 
FROM DateCTE;

-- =====================================================================
-- 🚀 執行迴圈：開始背景全自動打怪
-- =====================================================================
DECLARE @CurrentID INT = 1, @MaxID INT, @CurrentCmd NVARCHAR(MAX), @CurrentAction VARCHAR(50);
SELECT @MaxID = ISNULL(MAX(ID), 0) FROM #ExpandQueue;

WHILE @CurrentID <= @MaxID
BEGIN
    -- 抓出指令
    SELECT @CurrentCmd = SqlCmd, @CurrentAction = ActionType FROM #ExpandQueue WHERE ID = @CurrentID;
    
    -- 印出進度條
    PRINT '執行中 [' + @CurrentAction + '] (' + CAST(@CurrentID AS VARCHAR) + '/' + CAST(@MaxID AS VARCHAR) + ')';
    
    -- 🎯 扣下板機：執行 SQL
    EXEC sp_executesql @CurrentCmd;
    
    SET @CurrentID = @CurrentID + 1;
END

PRINT '--------------------------------------------------';
PRINT '🎉 新實體檔案與分區邊界擴建已全數完成！';
-- 任務結束，釋放暫存表
DROP TABLE #ExpandQueue;
GO
```

---
