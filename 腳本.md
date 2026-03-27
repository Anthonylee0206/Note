## TRANSACTION LOG CHECK(LDF)
```sql
-- 檢查伺服器上所有資料庫的 Log 使用率
DBCC SQLPERF(LOGSPACE);
GO

-- =============================================================

-- PARTITION ROW COUNT

-- 宣告要檢查的資料表名稱 (請替換成你想檢查的表)
DECLARE @TableName NVARCHAR(200) = 'cmd_data_log.dbo.provider_ticket_cmd_cashout_log';

-- 查詢該資料表每個分區 (Partition) 裡面實際存放的資料筆數
SELECT 
    OBJECT_NAME(p.object_id) AS [TableName],
    p.partition_number AS [PartitionNumber],
    p.rows AS [RowCount],
    a.type_desc AS [StorageType]
FROM sys.partitions p
INNER JOIN sys.allocation_units a ON p.hobt_id = a.container_id
WHERE p.object_id = OBJECT_ID(@TableName)
  AND p.index_id IN (0, 1) -- 只統計實體資料表 (Heap or Clustered Index)，排除非叢集索引
ORDER BY p.partition_number;

```
## FAILED JOBS HISTORY
```sql
-- 查詢 msdb 系統庫，抓出過去 24 小時內執行失敗 (run_status = 0) 的 Job
SELECT 
    j.name AS [JobName],
    h.run_date AS [RunDate],
    h.run_time AS [RunTime],
    h.message AS [ErrorMessage]
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j ON h.job_id = j.job_id
WHERE h.run_status = 0 -- 0: Failed, 1: Succeeded
  AND h.step_id = 0    -- 0 代表整個 Job 的最終執行結果 (而非單一步驟)
  -- 將 run_date 轉換為 DATE 格式，並過濾出大於等於昨天的紀錄
  AND CAST(CAST(h.run_date AS VARCHAR(8)) AS DATE) >= DATEADD(DAY, -1, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC;

```
## SAFE BATCH DELETE WITH TRY...CATCH
```sql
SET NOCOUNT ON;

-- 設定迴圈初始條件與每次刪除的批次大小 (Batch Size)
DECLARE @DeletedRows INT = 1; 
DECLARE @BatchSize INT = 5000; 

-- 當還有資料被刪除時，繼續執行迴圈
WHILE (@DeletedRows > 0)
BEGIN
    BEGIN TRY
        -- 開啟交易保護 (Transaction)
        BEGIN TRAN; 

        -- 執行刪除與搬家 (請依實際需求替換資料表與條件)
        DELETE TOP (@BatchSize) c
        OUTPUT deleted.TransID, deleted.ItemName, GETDATE()
        INTO Test_Detail_Archive
        FROM Test_Detail c
        WHERE c.TransID < 1000;

        -- 紀錄本次迴圈實際刪除的筆數
        SET @DeletedRows = @@ROWCOUNT; 

        -- 成功執行無錯誤，提交交易
        COMMIT TRAN; 

        -- 強制休息 0.5 秒，釋放硬碟 I/O 與鎖定 (Lock)
        WAITFOR DELAY '00:00:00.500'; 
    END TRY
    BEGIN CATCH
        -- 若發生錯誤 (如 Deadlock)，且交易仍在進行中，則進行還原 (Rollback)
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN; 

        -- 印出錯誤訊息供 DBA 除錯
        PRINT 'Error Occurred: ' + ERROR_MESSAGE();
        
        -- 強制終止迴圈，避免無限錯誤迴圈
        BREAK; 
    END CATCH
END

PRINT 'Batch Delete / Archive Process Completed.'
SET NOCOUNT OFF;

```
## TOP 10 LARGEST TABLES
```sql
-- 找出目前資料庫中佔用空間最大的前 10 名資料表 (Top 10 Largest Tables)
SELECT TOP 10
    t.name AS [TableName],
    p.rows AS [RowCount],
    SUM(a.total_pages) * 8 / 1024 AS [TotalSpaceMB],
    SUM(a.used_pages) * 8 / 1024 AS [UsedSpaceMB]
FROM sys.tables t
INNER JOIN sys.indexes i ON t.object_id = i.object_id
INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a ON p.partition_id = a.container_id
WHERE t.is_ms_shipped = 0 -- 排除系統自建表
    AND i.index_id IN (0, 1) 
GROUP BY t.name, p.rows
ORDER BY [TotalSpaceMB] DESC;

```
## CHECK FILES SPACE
```sql
-- 查詢目前資料庫的實體檔案 (MDF/NDF/LDF) 大小與使用狀況
SELECT 
    name AS [LogicalFileName],
    physical_name AS [PhysicalPath],
    type_desc AS [FileType],
    size * 8 / 1024 AS [TotalSizeMB],
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024 AS [UsedSpaceMB],
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS [FreeSpaceMB]
FROM sys.database_files;

```
## ACTIVE BLOCKING
```sql
-- 查詢目前資料庫中正在執行，且造成阻塞 (Blocking) 的連線
SELECT 
    session_id AS [BlockedSessionID],
    blocking_session_id AS [BlockingSessionID], -- 👈 這個就是罪魁禍首！
    wait_type AS [WaitType],
    wait_time AS [WaitTimeMS],
    wait_resource AS [WaitResource],
    command AS [CommandType],
    status AS [Status]
FROM sys.dm_exec_requests
WHERE blocking_session_id <> 0;

```
## 查看JOB下次預計執行時間
```sql
-- 查詢 SQL Server Agent 中，已啟用作業的「下次預計執行時間」
SELECT 
    j.name AS [JobName],
    j.enabled AS [IsEnabled],
    -- 將數字格式的日期與時間轉換成比較好讀的格式
    s.next_run_date AS [NextRunDate_Raw],
    s.next_run_time AS [NextRunTime_Raw]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.enabled = 1 -- 只看目前有啟用的 Job
ORDER BY s.next_run_date, s.next_run_time;

```
## INDEX FRAGMENTATION
```sql
-- 查詢目前資料庫中，破碎程度 (Fragmentation) 超過 10% 的索引
-- 數值如果在 10%~30% 建議重組 (Reorganize)，大於 30% 建議重建 (Rebuild)
SELECT 
    OBJECT_NAME(ips.object_id) AS [TableName],
    i.name AS [IndexName],
    ips.index_type_desc AS [IndexType],
    ips.avg_fragmentation_in_percent AS [FragmentationPercent],
    ips.page_count AS [PageCount]
FROM sys.dm_db_index_physical_stats(DB_ID(), NULL, NULL, NULL, 'LIMITED') ips
INNER JOIN sys.indexes i ON ips.object_id = i.object_id AND ips.index_id = i.index_id
WHERE ips.avg_fragmentation_in_percent > 10.0 -- 門檻設定為大於 10%
  AND ips.index_id > 0 -- 排除 Heap (沒有建叢集索引的資料表)
ORDER BY [FragmentationPercent] DESC;

```
## MISSING INDEXES
```sql
-- 找出 SQL Server 引擎強烈建議你建立的「遺失索引 (Missing Indexes)」
-- ImpactScore 越高，代表建立這個索引後，對系統整體效能的提升越顯著
SELECT TOP 20
    ROUND(migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans), 0) AS [ImpactScore],
    mid.statement AS [TargetTable],
    mid.equality_columns AS [EqualityColumns],
    mid.inequality_columns AS [InequalityColumns],
    mid.included_columns AS [IncludedColumns],
    migs.user_seeks AS [UserSeeks],
    migs.user_scans AS [UserScans]
FROM sys.dm_db_missing_index_group_stats migs
INNER JOIN sys.dm_db_missing_index_groups mig ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
ORDER BY [ImpactScore] DESC;

```
## ACTIVE QUERIES
```sql
-- 監控目前系統中「正在執行」的 SQL 語法，抓出耗時最久或消耗最多資源的怪獸查詢
SELECT 
    r.session_id AS [SessionID],
    s.login_name AS [LoginName],
    DB_NAME(r.database_id) AS [DatabaseName],
    r.start_time AS [StartTime],
    r.status AS [Status],
    r.command AS [CommandType],
    t.text AS [SQLText], -- 這裡會顯示對方正在跑的完整 SQL 語句
    r.cpu_time AS [CPUTimeMS],
    r.logical_reads AS [LogicalReads]
FROM sys.dm_exec_requests r
INNER JOIN sys.dm_exec_sessions s ON r.session_id = s.session_id
CROSS APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID -- 排除掉你自己正在跑的這支監控語法
ORDER BY r.cpu_time DESC;

```
## MEMORY USAGE BY DATABASE
```sql
-- 檢查 SQL Server 的記憶體 (Buffer Pool) 佔用分佈，看哪個資料庫吃最多
SELECT 
    CASE database_id 
        WHEN 32767 THEN 'ResourceDb' 
        ELSE DB_NAME(database_id) 
    END AS [DatabaseName],
    COUNT(*) * 8 / 1024 AS [MemoryUsedMB]
FROM sys.dm_os_buffer_descriptors
GROUP BY database_id
ORDER BY [MemoryUsedMB] DESC;

```
## ACTIVE CONNECTIONS BY DATABASE
```sql
-- 統計目前各個資料庫的連線數量與來源 (Active Connections and Source)
SELECT 
    DB_NAME(dbid) AS [DatabaseName],
    COUNT(dbid) AS [ConnectionCount],
    loginame AS [LoginName],
    hostname AS [HostName],
    program_name AS [ProgramName]
FROM sys.sysprocesses
WHERE dbid > 0 -- 排除系統背景排程
GROUP BY dbid, loginame, hostname, program_name
ORDER BY [ConnectionCount] DESC;

```
## HISTORICAL EXPENSIVE QUERIES
```sql
-- 撈出系統快取中，歷史累積消耗最多 CPU 時間的前 20 名 SQL 語法 (Top CPU Consuming Queries)
SELECT TOP 20
    t.text AS [QueryText],
    qs.execution_count AS [ExecutionCount],
    qs.total_worker_time / 1000 AS [TotalCPUTimeMS],
    (qs.total_worker_time / qs.execution_count) / 1000 AS [AvgCPUTimeMS],
    qs.total_logical_reads AS [TotalLogicalReads],
    qs.last_execution_time AS [LastExecutionTime]
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) t
ORDER BY qs.total_worker_time DESC;

```
## LAST BACKUP STATUS
```sql
-- 檢查所有資料庫的最後一次成功備份時間 (Last Successful Backup Time)
-- Type: D = Full (完整), I = Differential (差異), L = Log (交易紀錄)
SELECT 
    d.name AS [DatabaseName],
    MAX(CASE WHEN b.type = 'D' THEN b.backup_finish_date ELSE NULL END) AS [LastFullBackup],
    MAX(CASE WHEN b.type = 'I' THEN b.backup_finish_date ELSE NULL END) AS [LastDiffBackup],
    MAX(CASE WHEN b.type = 'L' THEN b.backup_finish_date ELSE NULL END) AS [LastLogBackup]
FROM sys.databases d
LEFT JOIN msdb.dbo.backupset b ON d.name = b.database_name
WHERE d.name NOT IN ('tempdb') -- tempdb 是暫存庫，不需要備份
GROUP BY d.name
ORDER BY d.name;

```
## TABLE USAGE STATISTICS
```sql
-- 查詢資料表的存取頻率，抓出「最常被查詢」與「從未被查詢」的表 (Table Usage & Access Frequency)
SELECT 
    OBJECT_NAME(i.object_id) AS [TableName],
    SUM(ius.user_seeks + ius.user_scans + ius.user_lookups) AS [TotalReads],
    SUM(ius.user_updates) AS [TotalUpdates],
    MAX(ius.last_user_seek) AS [LastReadTime],
    MAX(ius.last_user_update) AS [LastUpdateTime]
FROM sys.indexes i
LEFT JOIN sys.dm_db_index_usage_stats ius 
    ON i.object_id = ius.object_id AND i.index_id = ius.index_id AND ius.database_id = DB_ID()
WHERE OBJECTPROPERTY(i.object_id, 'IsUserTable') = 1 -- 只看使用者建立的表，不看系統表
GROUP BY i.object_id
ORDER BY [TotalReads] DESC, [TotalUpdates] DESC;

```
## TEMPDB SPACE USAGE
```sql
-- 監控 TempDB 的空間使用狀況，確保暫存庫不會被大型查詢給撐爆 (TempDB Space Allocation)
SELECT
    SUM(user_object_reserved_page_count) * 8 / 1024 AS [UserObjectsMB],     -- 使用者自建的暫存表大小
    SUM(internal_object_reserved_page_count) * 8 / 1024 AS [InternalObjectsMB], -- 系統執行複雜 JOIN 或排序時消耗的空間
    SUM(version_store_reserved_page_count) * 8 / 1024 AS [VersionStoreMB],  -- 版本快照使用的空間
    SUM(unallocated_extent_page_count) * 8 / 1024 AS [FreeSpaceMB]          -- 剩下的可用空間
FROM tempdb.sys.dm_db_file_space_usage;

```
## VLF COUNT CHECK
```sql
-- 檢查交易紀錄檔 (LDF) 內部的碎片化程度 (Virtual Log File Count)
-- ⚠️ DBA 警告：如果 VLFCount 查出來超過 500，甚至破千，代表你的 LDF 已經嚴重碎片化！
-- (註：此語法適用於 SQL Server 2016 SP2 以上版本)
SELECT 
    DB_NAME(database_id) AS [DatabaseName],
    COUNT(*) AS [VLFCount]
FROM sys.dm_db_log_info(DB_ID()) 
GROUP BY database_id;

```
## SERVER WAIT STATISTICS
```sql
-- 查詢伺服器層級的「等待事件統計」，抓出讓系統變慢的真正瓶頸 (Top Server Wait Types)
SELECT TOP 10
    wait_type AS [WaitType],
    wait_time_ms / 1000.0 AS [WaitTimeSeconds],
    100.0 * wait_time_ms / SUM(wait_time_ms) OVER() AS [WaitPercentage],
    waiting_tasks_count AS [WaitingTasksCount]
FROM sys.dm_os_wait_stats
-- 排除掉系統正常的背景待命事件，只看真正影響效能的瓶頸
WHERE wait_type NOT IN (
    'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
    'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
    'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
    'DIRTY_PAGE_POLL', 'HADR_FILESTREAM_IOMGR_IOCOMPLETION'
)
ORDER BY [WaitTimeSeconds] DESC;

```
## DATABASE GROWTH TREND
```sql
-- 利用歷史完整備份紀錄，推算資料庫每個月的成長趨勢，作為未來硬碟採購的依據 (Database Growth Trend via Backups)
SELECT 
    YEAR(backup_start_date) AS [BackupYear],
    MONTH(backup_start_date) AS [BackupMonth],
    AVG(backup_size / 1024 / 1024) AS [AvgSizeMB], -- 換算成 MB
    MAX(backup_size / 1024 / 1024) - MIN(backup_size / 1024 / 1024) AS [GrowthInMonthMB] -- 該月內的成長量
FROM msdb.dbo.backupset
WHERE type = 'D' -- D 代表 Database Full Backup (完整備份)
  AND database_name = DB_NAME() -- 只看目前的資料庫
GROUP BY YEAR(backup_start_date), MONTH(backup_start_date)
ORDER BY [BackupYear] DESC, [BackupMonth] DESC;

```