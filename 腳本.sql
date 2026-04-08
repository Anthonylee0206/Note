-------------------------------------------------------------------
-- DBA Ultimate Survival Toolkit (20 Golden Scripts)
-- Author: DBA Team
-- Description: Essential scripts for Job management, Performance, 
--              Storage, Health, and Utility.
-------------------------------------------------------------------

-------------------------------------------------------------------
-- [PART 1] JOB INSPECTION (排程起底兩步法 - 置頂工具)
-------------------------------------------------------------------

-- 1. Job Steps Scanner (查詢排程的執行步驟與實際指令)
-- 請將 'JOBS_cal_turnover' 替換成你想查的目標排程名稱
USE [msdb];
GO

SELECT 
    j.[name] AS [JobName],
    s.[step_id] AS [StepID],
    s.[step_name] AS [StepName],
    s.[subsystem] AS [SubSystem],
    s.[command] AS [CommandText]
FROM [dbo].[sysjobs] AS j
INNER JOIN [dbo].[sysjobsteps] AS s 
    ON j.[job_id] = s.[job_id]
WHERE j.[name] = N'JOBS_cal_turnover' 
ORDER BY s.[step_id] ASC;
GO

-- 2. Stored Procedure Extractor (抓出預存程序的底層原始碼)
-- 記得切換到該預存程序所在的業務資料庫 (例如 cmd_data)
USE [cmd_data]; 
GO

-- 將第一步查到的預存程序名稱放進來，即可印出完整 CREATE PROCEDURE 語法
EXEC [sys].[sp_helptext] @objname = N'job_ticket_cal_cmd';
GO


-------------------------------------------------------------------
-- [PART 2] JOB MANAGEMENT (排程管理與監控)
-------------------------------------------------------------------

-- 3. List All Jobs and Status (查詢系統內所有的排程清單與目前啟用狀態)
USE [msdb];
GO

SELECT 
    [name] AS [JobName],
    CASE [enabled] 
        WHEN 1 THEN 'Enabled' 
        ELSE 'Disabled' 
    END AS [JobStatus],
    [description] AS [JobDescription],
    [date_created] AS [DateCreated],
    [date_modified] AS [DateModified]
FROM [dbo].[sysjobs]
ORDER BY [JobName] ASC;
GO

-- 4. Job Execution History (查詢排程最近的執行歷史與失敗原因)
USE [msdb];
GO

SELECT TOP 50
    j.[name] AS [JobName],
    CASE h.[run_status]
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Canceled'
        ELSE 'Unknown'
    END AS [RunStatus],
    h.[run_date] AS [RunDate],
    h.[run_time] AS [RunTime],
    h.[message] AS [ResultMessage]
FROM [dbo].[sysjobhistory] AS h
INNER JOIN [dbo].[sysjobs] AS j 
    ON h.[job_id] = j.[job_id]
WHERE h.[step_id] = 0 
ORDER BY h.[run_date] DESC, h.[run_time] DESC;
GO

-- 5. Disable Specific Job (單點緊急煞車：停用單一指定的排程)
USE [msdb];
GO

-- 0 代表停用, 1 代表啟用
EXEC [dbo].[sp_update_job] 
    @job_name = N'JOBS_cal_turnover', 
    @enabled = 0;  
GO

-- 6. Generate Disable Jobs Script (大範圍緊急煞車：自動產生停用語法)
-- 複製下方查詢產生的結果去執行，可一次停用特定開頭的排程
USE [msdb];
GO

SELECT 
    'EXEC msdb.dbo.sp_update_job @job_name = N''' + [name] + ''', @enabled = 0;' AS [GeneratedScript]
FROM [dbo].[sysjobs]
WHERE [name] LIKE 'JOBS_%' OR [name] LIKE 'Mt_%'; 
GO


-------------------------------------------------------------------
-- [PART 3] PERFORMANCE & BLOCKING (效能與阻塞監控)
-------------------------------------------------------------------

-- 7. Find Active Queries (查看目前正在消耗 CPU 的活躍查詢語法)
SELECT 
    r.[session_id] AS [SessionID],
    s.[login_name] AS [LoginName],
    DB_NAME(r.[database_id]) AS [DatabaseName],
    r.[status] AS [Status],
    r.[command] AS [Command],
    r.[cpu_time] AS [CPUTime],
    t.[text] AS [SQLCommand]
FROM [sys].[dm_exec_requests] AS r
INNER JOIN [sys].[dm_exec_sessions] AS s 
    ON r.[session_id] = s.[session_id]
CROSS APPLY [sys].[dm_exec_sql_text](r.[sql_handle]) AS t
WHERE r.[session_id] > 50 AND r.[session_id] <> @@SPID;
GO

-- 8. Find Blocking Sessions (找出是誰卡住了別人的執行緒)
SELECT 
    [session_id] AS [BlockedSessionID],
    [blocking_session_id] AS [BlockingSessionID],
    [wait_type] AS [WaitType],
    [wait_time] AS [WaitTimeMS],
    [command] AS [Command]
FROM [sys].[dm_exec_requests]
WHERE [blocking_session_id] > 0;
GO

-- 9. Check Index Fragmentation (找出資料庫中碎片化超過 30% 且需要重建的索引)
SELECT 
    OBJECT_NAME(ips.[object_id]) AS [TableName],
    i.[name] AS [IndexName],
    ips.[avg_fragmentation_in_percent] AS [FragmentationPercent],
    ips.[page_count] AS [PageCount]
FROM [sys].[dm_db_index_physical_stats](DB_ID(), NULL, NULL, NULL, 'LIMITED') AS ips
INNER JOIN [sys].[indexes] AS i 
    ON ips.[object_id] = i.[object_id] AND ips.[index_id] = i.[index_id]
WHERE ips.[avg_fragmentation_in_percent] > 30.0 AND ips.[page_count] > 1000
ORDER BY ips.[avg_fragmentation_in_percent] DESC;
GO

-- 10. Find Missing Indexes (系統建議應該建立以提升效能的缺失索引)
SELECT TOP 20
    ROUND(s.[avg_total_user_cost] * s.[avg_user_impact] * (s.[user_seeks] + s.[user_scans]), 0) AS [TotalCost],
    d.[statement] AS [TableName],
    d.[equality_columns] AS [EqualityColumns],
    d.[inequality_columns] AS [InequalityColumns],
    d.[included_columns] AS [IncludedColumns]
FROM [sys].[dm_db_missing_index_groups] AS g
INNER JOIN [sys].[dm_db_missing_index_group_stats] AS s 
    ON s.[group_handle] = g.[index_group_handle]
INNER JOIN [sys].[dm_db_missing_index_details] AS d 
    ON d.[index_handle] = g.[index_handle]
ORDER BY [TotalCost] DESC;
GO


-------------------------------------------------------------------
-- [PART 4] STORAGE & MAINTENANCE (空間與儲存管理)
-------------------------------------------------------------------

-- 11. Database Sizes (列出伺服器上所有資料庫的檔案大小 MB)
SELECT 
    DB_NAME([database_id]) AS [DatabaseName],
    [type_desc] AS [FileType],
    [name] AS [LogicalName],
    [physical_name] AS [PhysicalPath],
    ([size] * 8 / 1024) AS [SizeInMB]
FROM [sys].[master_files]
ORDER BY [database_id] ASC, [type] ASC;
GO

-- 12. Top 10 Largest Tables (列出當前資料庫最佔空間的前十大資料表)
SELECT TOP 10
    t.[name] AS [TableName],
    p.[rows] AS [RowCount],
    (SUM(a.[total_pages]) * 8 / 1024) AS [TotalSpaceMB],
    (SUM(a.[used_pages]) * 8 / 1024) AS [UsedSpaceMB]
FROM [sys].[tables] AS t
INNER JOIN [sys].[indexes] AS i ON t.[object_id] = i.[object_id]
INNER JOIN [sys].[partitions] AS p ON i.[object_id] = p.[object_id] AND i.[index_id] = p.[index_id]
INNER JOIN [sys].[allocation_units] AS a ON p.[partition_id] = a.[container_id]
WHERE t.[is_ms_shipped] = 0 AND i.[object_id] > 255
GROUP BY t.[name], p.[rows]
ORDER BY [TotalSpaceMB] DESC;
GO

-- 13. Find Unused Indexes (找出建了卻沒人在用，白白浪費空間的索引)
SELECT 
    OBJECT_NAME(i.[object_id]) AS [TableName],
    i.[name] AS [IndexName],
    s.[user_updates] AS [TotalUpdates],
    s.[user_seeks] AS [TotalSeeks],
    s.[user_scans] AS [TotalScans]
FROM [sys].[indexes] AS i
LEFT JOIN [sys].[dm_db_index_usage_stats] AS s 
    ON i.[object_id] = s.[object_id] AND i.[index_id] = s.[index_id] AND s.[database_id] = DB_ID()
WHERE OBJECTPROPERTY(i.[object_id], 'IsUserTable') = 1
  AND i.[type_desc] = 'NONCLUSTERED'
  AND s.[user_seeks] = 0 AND s.[user_scans] = 0 AND s.[user_lookups] = 0
ORDER BY s.[user_updates] DESC;
GO

-- 14. Shrink Transaction Log (緊急情況下釋放 Log 檔案空間)
-- 請將 cmd_data 與 cmd_data_log 替換為實際的資料庫與邏輯檔案名稱
USE [cmd_data]; 
GO

-- 先將復原模式切換為簡單模式
ALTER DATABASE [cmd_data] SET RECOVERY SIMPLE;
GO
-- 壓縮 Log 檔案至 10MB
DBCC SHRINKFILE (N'cmd_data_log', 10);
GO
-- 切換回完整模式 (生產環境必備)
ALTER DATABASE [cmd_data] SET RECOVERY FULL;
GO


-------------------------------------------------------------------
-- [PART 5] SYSTEM HEALTH & LOGS (系統健康與日誌)
-------------------------------------------------------------------

-- 15. SQL Server Uptime (檢查伺服器上次重啟的時間與存活天數)
SELECT 
    [sqlserver_start_time] AS [ServerStartTime],
    DATEDIFF(DAY, [sqlserver_start_time], GETDATE()) AS [UptimeDays]
FROM [sys].[dm_os_sys_info];
GO

-- 16. Recent Backup Status (確認資料庫最近一次的備份時間與類型)
SELECT 
    [database_name] AS [DatabaseName],
    MAX([backup_finish_date]) AS [LastBackupFinishDate],
    CASE [type] 
        WHEN 'D' THEN 'Full' 
        WHEN 'I' THEN 'Differential' 
        WHEN 'L' THEN 'Log' 
    END AS [BackupType]
FROM [msdb].[dbo].[backupset]
GROUP BY [database_name], [type]
ORDER BY [DatabaseName] ASC;
GO

-- 17. Connection Count by IP (抓出目前連線數最高的客戶端 IP，防範異常連線)
SELECT 
    c.[client_net_address] AS [ClientIPAddress],
    COUNT(*) AS [ConnectionCount]
FROM [sys].[dm_exec_connections] AS c
INNER JOIN [sys].[dm_exec_sessions] AS s 
    ON c.[session_id] = s.[session_id]
WHERE s.[is_user_process] = 1
GROUP BY c.[client_net_address]
ORDER BY [ConnectionCount] DESC;
GO


-------------------------------------------------------------------
-- [PART 6] UTILITY & SEARCH (開發與工具)
-------------------------------------------------------------------

-- 18. Search Column in Database (找尋資料庫中哪張表有特定的欄位名稱)
-- 以下範例為尋找包含 'soc_trans_id' 的表
SELECT 
    t.[name] AS [TableName],
    c.[name] AS [ColumnName],
    ty.[name] AS [DataType]
FROM [sys].[tables] AS t
INNER JOIN [sys].[columns] AS c 
    ON t.[object_id] = c.[object_id]
INNER JOIN [sys].[types] AS ty 
    ON c.[user_type_id] = ty.[user_type_id]
WHERE c.[name] LIKE '%soc_trans_id%'
ORDER BY t.[name] ASC;
GO

-- 19. Search Text in SPs (找尋哪支預存程序裡面寫到了特定的字串)
-- 以下範例為尋找包含 'cmd_data_archive' 的 SP
SELECT 
    [name] AS [StoredProcedureName],
    [modify_date] AS [LastModified]
FROM [sys].[objects]
WHERE [type] = 'P' 
  AND OBJECT_DEFINITION([object_id]) LIKE '%cmd_data_archive%'
ORDER BY [name] ASC;
GO

-- 20. Custom String Split Loop (純手工字串切割迴圈)
DECLARE @InputString NVARCHAR(MAX) = N'ANDY,ALLEN,ANTHONY,ROGER,TOMMY,TOM,KOBE,';
DECLARE @Delimiter CHAR(1) = ',';
DECLARE @Position INT;

DECLARE @ResultTable TABLE (
    [SplitValue] NVARCHAR(100)
);

WHILE CHARINDEX(@Delimiter, @InputString) > 0
BEGIN
    SET @Position = CHARINDEX(@Delimiter, @InputString);
    
    INSERT INTO @ResultTable ([SplitValue]) 
    VALUES (LEFT(@InputString, @Position - 1));
    
    SET @InputString = STUFF(@InputString, 1, @Position, '');
END

-- 掃尾：把最後剩下的字串丟進結果表
IF LEN(@InputString) > 0 
BEGIN
    INSERT INTO @ResultTable ([SplitValue]) VALUES (@InputString);
END

SELECT [SplitValue] FROM @ResultTable;
GO

-------------------------------------------------------------------
-- TOOL: STORED PROCEDURE LOCATOR (跨資料庫搜尋工具)
-- Description: Find where an SP is located across the entire server.
-------------------------------------------------------------------

-- 21. Precise Search (全伺服器精準名稱搜索)
-- 當你百分之百確定預存程序的全名時，用這段最快。
DECLARE @TargetSPName NVARCHAR(128) = N'job_ticket_cal_cmd'; -- 👈 填入完整名稱

DECLARE @SearchCommand NVARCHAR(MAX) = N'
    USE [?]; 
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name = ''' + @TargetSPName + ''')
    BEGIN
        SELECT 
            DB_NAME() AS [DatabaseName], 
            SCHEMA_NAME([schema_id]) AS [SchemaName],
            [name] AS [ProcedureName], 
            [create_date] AS [CreateDate], 
            [modify_date] AS [ModifyDate]
        FROM sys.procedures 
        WHERE name = ''' + @TargetSPName + ''';
    END';

-- Execute the search across all online databases (執行全庫掃描)
EXEC sp_MSforeachdb @SearchCommand;
GO


-- 22. Fuzzy Search (全伺服器模糊關鍵字搜索)
-- 當你只記得部分名字（例如包含 'cal'）的時候，用這段。
DECLARE @Keyword NVARCHAR(128) = N'%cal%'; -- 👈 填入部分關鍵字

DECLARE @FuzzySearchCommand NVARCHAR(MAX) = N'
    USE [?]; 
    IF EXISTS (SELECT 1 FROM sys.procedures WHERE name LIKE ''' + @Keyword + ''')
    BEGIN
        SELECT 
            DB_NAME() AS [DatabaseName], 
            [name] AS [ProcedureName], 
            [type_desc] AS [ObjectType],
            [modify_date] AS [LastModified]
        FROM sys.procedures 
        WHERE name LIKE ''' + @Keyword + ''';
    END';

EXEC sp_MSforeachdb @FuzzySearchCommand;
GO


-- 23. Content Search (全伺服器預存程序「內容」關鍵字搜索)
-- 這是最強大的：搜尋所有預存程序的「程式碼」裡是否提到某個字（例如某張資料表名稱）。
DECLARE @ContentKeyword NVARCHAR(128) = N'%cmd_data_archive%'; -- 👈 填入想在代碼裡找的字

DECLARE @ContentSearchCommand NVARCHAR(MAX) = N'
    USE [?]; 
    IF EXISTS (
        SELECT 1 FROM sys.procedures p 
        INNER JOIN sys.sql_modules m ON p.object_id = m.object_id 
        WHERE m.definition LIKE ''' + @ContentKeyword + '''
    )
    BEGIN
        SELECT 
            DB_NAME() AS [DatabaseName], 
            p.[name] AS [ProcedureName], 
            p.[modify_date] AS [LastModified]
        FROM sys.procedures p
        INNER JOIN sys.sql_modules m ON p.object_id = m.object_id
        WHERE m.definition LIKE ''' + @ContentKeyword + ''';
    END';

EXEC sp_MSforeachdb @ContentSearchCommand;
GO