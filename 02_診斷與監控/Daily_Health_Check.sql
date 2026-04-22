/* =========================================================================
   【用途】       SQL Server 實例每日健檢快篩：一次跑出 6 個重點指標。
   【使用時機】   每天早上進公司第一件事；事件發生時快速體檢；交班 handover。
   【輸入參數】   無。所有 DB / Job / Session 都看。
   【輸出】       依序 PRINT 分段標題，共 6 個結果集：
                   1. 各 DB 交易記錄使用率 (DBCC SQLPERF(LOGSPACE))
                   2. 目前 DB 的資料檔 / 記錄檔總量 / 已用 / 剩餘
                   3. 最近 24 小時失敗 Job
                   4. 目前仍在被 Block 的 Session
                   5. 目前 DB 最大 10 張表
                   6. 各 DB 連線數彙總
   【風險/注意】  純查詢 + DMV，可在 Prod 直接跑。
                  第 2、5 段只會看「當前 USE 的 DB」；要跨 DB 請手動切換或逐一執行。
   ========================================================================= */

SET NOCOUNT ON;

PRINT '=========================================';
PRINT ' 1. Transaction Log Space Usage';
PRINT '=========================================';
DBCC SQLPERF(LOGSPACE);

PRINT '=========================================';
PRINT ' 2. Database File Space & Free Capacity';
PRINT '=========================================';
SELECT 
    name AS [LogicalFileName],
    physical_name AS [PhysicalPath],
    type_desc AS [FileType],
    size * 8 / 1024 AS [TotalSizeMB],
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024 AS [UsedSpaceMB],
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS [FreeSpaceMB]
FROM sys.database_files;

PRINT '=========================================';
PRINT ' 3. Failed Jobs in Last 24 Hours';
PRINT '=========================================';
SELECT 
    j.name AS [JobName],
    h.run_date AS [RunDate],
    h.run_time AS [RunTime],
    h.message AS [ErrorMessage]
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0 
  AND h.step_id = 0    
  AND CAST(CAST(h.run_date AS VARCHAR(8)) AS DATE) >= DATEADD(DAY, -1, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC;

PRINT '=========================================';
PRINT ' 4. Active Blocking Sessions';
PRINT '=========================================';
SELECT 
    session_id AS [BlockedSessionID],
    blocking_session_id AS [BlockingSessionID],
    wait_type AS [WaitType],
    wait_time AS [WaitTimeMS],
    command AS [CommandType],
    status AS [Status]
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

PRINT '=========================================';
PRINT ' 5. Top 10 Largest Tables';
PRINT '=========================================';
SELECT TOP 10
    t.name AS [TableName],
    p.rows AS [RowCount],
    SUM(a.total_pages) * 8 / 1024 AS [TotalSpaceMB]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 AND i.index_id IN (0, 1) 
GROUP BY t.name, p.rows
ORDER BY [TotalSpaceMB] DESC;

PRINT '=========================================';
PRINT ' 6. Active Connections Summary';
PRINT '=========================================';
SELECT 
    DB_NAME(dbid) AS [DatabaseName],
    COUNT(dbid) AS [ConnectionCount],
    loginame AS [LoginName],
    hostname AS [HostName]
FROM sys.sysprocesses
WHERE dbid > 0 
GROUP BY dbid, loginame, hostname
ORDER BY [ConnectionCount] DESC;

SET NOCOUNT OFF;