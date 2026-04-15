-- =====================================================================
-- SQL Server Agent Job 每日維護檢查腳本
-- 執行方式：F5 一次執行，會出現多個結果集
-- =====================================================================
SET NOCOUNT ON;

-- ===== 可調整參數 =====
DECLARE @HoursBack    INT = 24;    -- 往回看幾小時的失敗紀錄
DECLARE @DaysBack     INT = 30;    -- 往回看幾天的成功率趨勢
DECLARE @LongRunMin   INT = 30;    -- 超過幾分鐘視為長時間跑
-- =====================


-- =====================================================================
-- 結果 1：最近 N 小時失敗的 Job 一覽 ★
-- =====================================================================
PRINT '============================================================';
PRINT ' [1] 最近 ' + CAST(@HoursBack AS VARCHAR) + ' 小時失敗的 Job';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    h.step_id                             AS [Step #],
    h.step_name                           AS [Step Name],
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS [Run Time],
    h.run_duration / 10000 * 3600 
        + (h.run_duration % 10000) / 100 * 60 
        + h.run_duration % 100            AS [Duration (sec)],
    LEFT(h.message, 500)                  AS [Error Message]
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id
WHERE h.run_status = 0
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(HOUR, -@HoursBack, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC;


-- =====================================================================
-- 結果 2：目前正在執行的 Job
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [2] 目前正在執行的 Job';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    ja.start_execution_date               AS [Started At],
    DATEDIFF(SECOND, ja.start_execution_date, GETDATE()) AS [Running (sec)],
    js.step_id                            AS [Current Step #],
    js.step_name                          AS [Current Step Name]
FROM msdb.dbo.sysjobactivity ja
INNER JOIN msdb.dbo.sysjobs j ON j.job_id = ja.job_id
LEFT JOIN msdb.dbo.sysjobsteps js 
    ON js.job_id = ja.job_id AND js.step_id = ja.last_executed_step_id + 1
WHERE ja.start_execution_date IS NOT NULL 
  AND ja.stop_execution_date IS NULL
  AND ja.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
ORDER BY ja.start_execution_date;


-- =====================================================================
-- 結果 3：Job 狀態儀表板（失敗排最上面）
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [3] 所有 Job 最新狀態儀表板';
PRINT '============================================================';

WITH LastRun AS (
    SELECT 
        h.job_id,
        h.run_status,
        msdb.dbo.agent_datetime(h.run_date, h.run_time) AS run_time,
        ROW_NUMBER() OVER (PARTITION BY h.job_id ORDER BY h.run_date DESC, h.run_time DESC) AS rn
    FROM msdb.dbo.sysjobhistory h
    WHERE h.step_id = 0
)
SELECT 
    j.name                                AS [Job Name],
    CASE j.enabled WHEN 1 THEN 'Yes' ELSE 'No' END AS [Enabled],
    CASE lr.run_status
        WHEN 0 THEN '❌ Failed'
        WHEN 1 THEN '✅ Succeeded'
        WHEN 2 THEN '⚠ Retry'
        WHEN 3 THEN '⊘ Cancelled'
        ELSE '- Never Run'
    END                                   AS [Last Status],
    lr.run_time                           AS [Last Run],
    msdb.dbo.agent_datetime(
        NULLIF(js.next_run_date, 0), 
        js.next_run_time)                 AS [Next Run]
FROM msdb.dbo.sysjobs j
LEFT JOIN LastRun lr ON lr.job_id = j.job_id AND lr.rn = 1
LEFT JOIN msdb.dbo.sysjobschedules js ON js.job_id = j.job_id
ORDER BY 
    CASE lr.run_status WHEN 0 THEN 1 WHEN 2 THEN 2 ELSE 3 END,
    j.name;


-- =====================================================================
-- 結果 4：失敗 Job 的完整錯誤訊息（Failed Jobs 的細節）
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [4] 最近失敗 Job 的完整錯誤訊息';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    h.step_id                             AS [Step #],
    h.step_name                           AS [Step Name],
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS [Run Time],
    h.message                             AS [Full Error Message]
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j ON j.job_id = h.job_id
WHERE h.run_status = 0
  AND h.step_id > 0
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(HOUR, -@HoursBack, GETDATE())
ORDER BY h.run_date DESC, h.run_time DESC, h.step_id;


-- =====================================================================
-- 結果 5：最近 N 天每日成功率趨勢（看 Job 是最近才壞還是長期不穩）
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [5] 最近 ' + CAST(@DaysBack AS VARCHAR) + ' 天 Job 成功率統計';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    COUNT(*)                              AS [Runs],
    SUM(CASE WHEN h.run_status = 1 THEN 1 ELSE 0 END) AS [Success],
    SUM(CASE WHEN h.run_status = 0 THEN 1 ELSE 0 END) AS [Failed],
    CAST(
        CASE WHEN COUNT(*) > 0
             THEN SUM(CASE WHEN h.run_status = 1 THEN 1.0 ELSE 0 END) / COUNT(*) * 100
             ELSE 0 
        END AS DECIMAL(5,1))              AS [Success Rate %],
    AVG(h.run_duration / 10000 * 3600 
        + (h.run_duration % 10000) / 100 * 60 
        + h.run_duration % 100)           AS [Avg Duration (sec)],
    MAX(h.run_duration / 10000 * 3600 
        + (h.run_duration % 10000) / 100 * 60 
        + h.run_duration % 100)           AS [Max Duration (sec)]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h 
    ON j.job_id = h.job_id AND h.step_id = 0
WHERE msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(DAY, -@DaysBack, GETDATE())
GROUP BY j.name
ORDER BY [Success Rate %], [Failed] DESC;


-- =====================================================================
-- 結果 6：長時間執行的 Job（超過 N 分鐘）
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [6] 長時間執行的 Job（平均超過 ' + CAST(@LongRunMin AS VARCHAR) + ' 分鐘）';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    COUNT(*)                              AS [Runs (30d)],
    AVG(h.run_duration / 10000 * 3600 
        + (h.run_duration % 10000) / 100 * 60 
        + h.run_duration % 100) / 60      AS [Avg Duration (min)],
    MAX(h.run_duration / 10000 * 3600 
        + (h.run_duration % 10000) / 100 * 60 
        + h.run_duration % 100) / 60      AS [Max Duration (min)]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobhistory h 
    ON j.job_id = h.job_id AND h.step_id = 0
WHERE h.run_status = 1
  AND msdb.dbo.agent_datetime(h.run_date, h.run_time) >= DATEADD(DAY, -@DaysBack, GETDATE())
GROUP BY j.name
HAVING AVG(h.run_duration / 10000 * 3600 
         + (h.run_duration % 10000) / 100 * 60 
         + h.run_duration % 100) / 60 >= @LongRunMin
ORDER BY [Avg Duration (min)] DESC;


-- =====================================================================
-- 結果 7：停用但有排程的 Job（可能被忘記）
-- =====================================================================
PRINT '';
PRINT '============================================================';
PRINT ' [7] 被停用但仍有排程的 Job（檢查是否該清掉）';
PRINT '============================================================';

SELECT 
    j.name                                AS [Job Name],
    j.enabled                             AS [Enabled],
    s.name                                AS [Schedule Name],
    j.date_modified                       AS [Last Modified]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s ON js.schedule_id = s.schedule_id
WHERE j.enabled = 0
ORDER BY j.name;


PRINT '';
PRINT '============================================================';
PRINT ' 檢查完成';
PRINT '============================================================';
