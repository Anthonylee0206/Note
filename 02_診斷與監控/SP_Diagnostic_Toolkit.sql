-- ============================================================
-- SQL Server SP 診斷與效能分析工具包
-- ============================================================
-- 用途：DBA 日常維護用的查詢腳本集合
-- 環境：SQL Server 2016+ (已驗證 2017 / 2022)
-- 使用方式：
--   1. 連線到目標 SQL Server
--   2. 依需求框選對應區塊執行
--   3. 全部都是 SELECT / DMV 查詢，不會修改任何資料
--   4. 可安全在 prod 環境執行（read only 帳號即可）
-- 注意：
--   標示 ★ 的地方需要替換成實際的資料庫名稱或 SP 名稱
-- ============================================================


-- ============================================================
-- 第一章：環境概覽
-- 用途：第一次進 prod 時，快速了解整個環境的全貌
-- ============================================================

-- 1-1. 所有資料庫的基本資訊和狀態
-- 看有哪些庫、有沒有開 RCSI、復原模式是什麼
SELECT
    name,
    state_desc,
    recovery_model_desc,
    log_reuse_wait_desc,
    is_read_committed_snapshot_on,
    compatibility_level,
    create_date
FROM sys.databases
ORDER BY name;


-- 1-2. 每個資料庫的大小（資料檔 + 日誌檔）
SELECT
    db.name,
    SUM(mf.size * 8 / 1024)                        AS total_mb,
    SUM(CASE WHEN mf.type = 0
        THEN mf.size * 8 / 1024 END)               AS data_mb,
    SUM(CASE WHEN mf.type = 1
        THEN mf.size * 8 / 1024 END)               AS log_mb
FROM sys.databases db
JOIN sys.master_files mf
    ON db.database_id = mf.database_id
GROUP BY db.name
ORDER BY total_mb DESC;


-- 1-3. 各資料表的大小和資料列數
-- ★ 先 USE 切換到目標資料庫
-- USE cmd_data;
SELECT
    s.name                              AS schema_name,
    t.name                              AS table_name,
    p.rows                              AS row_count,
    SUM(a.total_pages) * 8 / 1024       AS total_mb,
    SUM(a.used_pages) * 8 / 1024        AS used_mb
FROM sys.tables t
JOIN sys.schemas s
    ON t.schema_id = s.schema_id
JOIN sys.indexes i
    ON t.object_id = i.object_id
JOIN sys.partitions p
    ON i.object_id = p.object_id
    AND i.index_id = p.index_id
JOIN sys.allocation_units a
    ON p.partition_id = a.container_id
WHERE i.index_id IN (0, 1)
GROUP BY t.name, s.name, p.rows
ORDER BY total_mb DESC;


-- ============================================================
-- 第二章：目前連線與活動監控
-- 用途：看目前有誰在連線、在做什麼、有沒有阻塞
-- ============================================================

-- 2-1. 目前所有使用者連線
SELECT
    s.session_id,
    s.login_name,
    s.host_name,
    s.program_name,
    s.status,
    s.cpu_time,
    s.memory_usage,
    s.last_request_start_time,
    DB_NAME(s.database_id) AS db_name
FROM sys.dm_exec_sessions s
WHERE s.is_user_process = 1
ORDER BY s.last_request_start_time DESC;


-- 2-2. 目前正在執行的查詢
-- 建議在業務時段執行，才能看到正在跑的東西
SELECT
    r.session_id,
    r.status,
    r.wait_type,
    r.wait_time / 1000              AS wait_sec,
    r.cpu_time,
    r.total_elapsed_time / 1000     AS elapsed_sec,
    DB_NAME(r.database_id)          AS db_name,
    t.text                          AS sql_text
FROM sys.dm_exec_requests r
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.session_id <> @@SPID
ORDER BY r.total_elapsed_time DESC;


-- 2-3. 快速看有沒有阻塞
SELECT
    r.session_id,
    r.blocking_session_id,
    r.wait_type,
    r.wait_time / 1000  AS wait_sec,
    t.text              AS sql_text
FROM sys.dm_exec_requests r
OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
WHERE r.blocking_session_id > 0;


-- ============================================================
-- 第三章：SP 效能分析
-- 用途：找出最吃資源的 SP，定位效能瓶頸
-- ============================================================

-- 3-1. 最吃資源的 SP（綜合排序）
-- ★ 修改 DB_ID('cmd_data') 為目標資料庫
-- 跑完後換 ORDER BY 欄位看不同維度：
--   execution_count DESC        → 跑最頻繁的
--   total_elapsed_ms DESC       → 整體占用最多時間的
--   avg_elapsed_ms DESC         → 單次平均最慢的
--   max_elapsed_ms DESC         → 曾經最慢一次（偶發性問題）
--   avg_logical_reads DESC      → IO 最重的
--   avg_cpu_ms DESC             → CPU 最重的
SELECT TOP 20
    OBJECT_NAME(qs.object_id, qs.database_id)           AS sp_name,
    DB_NAME(qs.database_id)                              AS db_name,
    qs.execution_count,
    qs.total_elapsed_time / qs.execution_count
        / 1000                                           AS avg_elapsed_ms,
    qs.max_elapsed_time / 1000                           AS max_elapsed_ms,
    qs.total_worker_time / qs.execution_count
        / 1000                                           AS avg_cpu_ms,
    qs.total_logical_reads / qs.execution_count          AS avg_logical_reads,
    qs.total_elapsed_time / 1000                         AS total_elapsed_ms,
    qs.last_execution_time,
    qs.cached_time                                       AS plan_cached_since
FROM sys.dm_exec_procedure_stats qs
WHERE qs.database_id = DB_ID('cmd_data')                 -- ★ 換成目標資料庫
  AND OBJECT_NAME(qs.object_id, qs.database_id) IS NOT NULL
ORDER BY qs.total_elapsed_time DESC;


-- 3-2. 看某支 SP 的執行計畫
-- ★ 把 'your_sp_name' 換成要查的 SP 名稱
-- 跑完後點 query_plan 欄位的藍色超連結，會打開圖形化執行計畫
SELECT TOP 5
    qs.last_execution_time,
    qs.execution_count,
    qs.total_elapsed_time / qs.execution_count / 1000   AS avg_ms,
    qs.max_elapsed_time / 1000                          AS max_ms,
    qs.total_logical_reads / qs.execution_count         AS avg_logical_reads,
    qp.query_plan
FROM sys.dm_exec_procedure_stats qs
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE OBJECT_NAME(qs.object_id, qs.database_id) = 'your_sp_name'  -- ★ 換成 SP 名稱
ORDER BY qs.last_execution_time DESC;


-- 3-3. 找動態 SQL（sp_executesql）裡面的實際執行計畫
-- 用途：當 SP 用了動態 SQL，3-2 看不到真正的執行計畫時用這個
-- ★ 把 '%table_name%' 換成動態 SQL 裡面的表名
SELECT TOP 10
    qs.execution_count,
    qs.total_elapsed_time / qs.execution_count / 1000   AS avg_elapsed_ms,
    qs.total_logical_reads / qs.execution_count         AS avg_logical_reads,
    SUBSTRING(st.text, 1, 500)                          AS sql_text,
    qp.query_plan
FROM sys.dm_exec_query_stats qs
CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) st
CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) qp
WHERE st.text LIKE '%table_name%'                       -- ★ 換成表名
  AND st.text NOT LIKE '%sys.dm_exec%'
ORDER BY qs.total_elapsed_time DESC;


-- ============================================================
-- 第四章：SP 原始碼查看
-- 用途：拉出 SP 的完整程式碼進行審查
-- ============================================================

-- 4-1. 查單支 SP 的完整內容
-- ★ 換成要查的 SP 名稱
-- 建議先按 Ctrl+T 切文字模式再跑，保留換行格式
SELECT definition
FROM sys.sql_modules
WHERE object_id = OBJECT_ID('dbo.your_sp_name');         -- ★ 換成 SP 名稱


-- 4-2. 批次查多支 SP 的內容（取最常跑的前 10 支）
-- ★ 修改 DB_ID('cmd_data') 為目標資料庫
SELECT
    OBJECT_NAME(sm.object_id)       AS sp_name,
    sm.definition                   AS sp_content
FROM sys.sql_modules sm
JOIN sys.objects o
    ON sm.object_id = o.object_id
WHERE o.type = 'P'
  AND OBJECT_NAME(sm.object_id) IN
(
    SELECT TOP 10
        OBJECT_NAME(qs.object_id, qs.database_id)
    FROM sys.dm_exec_procedure_stats qs
    WHERE qs.database_id = DB_ID('cmd_data')             -- ★ 換成目標資料庫
      AND OBJECT_NAME(qs.object_id, qs.database_id) IS NOT NULL
    ORDER BY qs.execution_count DESC
)
ORDER BY OBJECT_NAME(sm.object_id);


-- 4-3. 用關鍵字搜尋 SP（找包含特定表名或函數的 SP）
-- ★ 把 '%keyword%' 換成要搜尋的關鍵字
SELECT
    OBJECT_NAME(sm.object_id)       AS sp_name,
    o.create_date,
    o.modify_date
FROM sys.sql_modules sm
JOIN sys.objects o
    ON sm.object_id = o.object_id
WHERE o.type = 'P'
  AND sm.definition LIKE '%keyword%'                     -- ★ 換成關鍵字
ORDER BY o.modify_date DESC;


-- 4-4. 最近 30 天內修改過的 SP
SELECT
    name                            AS sp_name,
    create_date,
    modify_date
FROM sys.objects
WHERE type = 'P'
  AND modify_date >= DATEADD(DAY, -30, GETDATE())
ORDER BY modify_date DESC;


-- ============================================================
-- 第五章：索引分析
-- 用途：查看資料表的索引結構、找出缺少的索引
-- ============================================================

-- 5-1. 查某張表的所有索引和欄位
-- ★ 把 'dbo.your_table_name' 換成要查的表名
SELECT
    i.name                          AS index_name,
    i.type_desc                     AS index_type,
    i.is_unique,
    ic.key_ordinal,
    ic.is_included_column,
    c.name                          AS column_name
FROM sys.indexes i
JOIN sys.index_columns ic
    ON i.object_id = ic.object_id
    AND i.index_id = ic.index_id
JOIN sys.columns c
    ON ic.object_id = c.object_id
    AND ic.column_id = c.column_id
WHERE i.object_id = OBJECT_ID('dbo.your_table_name')    -- ★ 換成表名
ORDER BY i.name, ic.is_included_column, ic.key_ordinal;


-- 5-2. 查某張表的欄位型態（對照 SP 參數用）
-- ★ 把 'dbo.your_table_name' 換成要查的表名
SELECT
    c.name                          AS column_name,
    t.name                          AS type_name,
    c.max_length,
    c.is_nullable,
    c.column_id
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE c.object_id = OBJECT_ID('dbo.your_table_name')    -- ★ 換成表名
ORDER BY c.column_id;


-- 5-3. SQL Server 建議的 Missing Index（全資料庫）
-- 用途：找出 SQL Server 認為應該建立的索引
-- avg_user_impact 越高越值得建
SELECT
    mid.statement                   AS table_name,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_user_impact,
    migs.user_seeks,
    migs.last_user_seek
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig
    ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats migs
    ON mig.index_group_handle = migs.group_handle
WHERE mid.database_id = DB_ID()
ORDER BY migs.avg_user_impact DESC;


-- 5-4. 比對兩張表的同名欄位型態（找隱含轉換用）
-- ★ 換成要比對的兩張表和欄位名
SELECT
    OBJECT_NAME(c.object_id)        AS table_name,
    c.name                          AS column_name,
    t.name                          AS type_name,
    c.max_length
FROM sys.columns c
JOIN sys.types t ON c.user_type_id = t.user_type_id
WHERE (c.object_id = OBJECT_ID('dbo.table_a') AND c.name = 'column_x')  -- ★
   OR (c.object_id = OBJECT_ID('dbo.table_b') AND c.name = 'column_x'); -- ★


-- ============================================================
-- 第六章：SQL Agent JOB 監控
-- 用途：查看排程工作的清單和執行狀態
-- ============================================================

-- 6-1. 所有排程工作
SELECT
    j.name                          AS job_name,
    j.enabled,
    j.description,
    CASE jh.run_status
        WHEN 0 THEN 'Failed'
        WHEN 1 THEN 'Succeeded'
        WHEN 2 THEN 'Retry'
        WHEN 3 THEN 'Cancelled'
        WHEN 4 THEN 'In Progress'
        ELSE 'Unknown'
    END                             AS last_run_status,
    msdb.dbo.agent_datetime(jh.run_date, jh.run_time)
                                    AS last_run_datetime,
    s.name                          AS schedule_name
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js
    ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s
    ON js.schedule_id = s.schedule_id
OUTER APPLY (
    SELECT TOP 1 run_status, run_date, run_time
    FROM msdb.dbo.sysjobhistory
    WHERE job_id = j.job_id AND step_id = 0
    ORDER BY run_date DESC, run_time DESC
) jh
ORDER BY j.name;


-- 6-2. 最近失敗的 JOB（快速排查用）
SELECT
    j.name                          AS job_name,
    jh.step_name,
    msdb.dbo.agent_datetime(jh.run_date, jh.run_time)
                                    AS fail_datetime,
    jh.message                      AS error_message
FROM msdb.dbo.sysjobhistory jh
JOIN msdb.dbo.sysjobs j
    ON jh.job_id = j.job_id
WHERE jh.run_status = 0
  AND jh.run_date >= CONVERT(INT, CONVERT(VARCHAR(8), DATEADD(DAY, -7, GETDATE()), 112))
ORDER BY jh.run_date DESC, jh.run_time DESC;


-- ============================================================
-- 第七章：Extended Events 監控
-- 用途：查看目前有哪些 XEvents Session 在跑
-- ============================================================

-- 7-1. 目前有哪些 XEvents Session
SELECT
    es.name,
    es.create_time,
    CASE WHEN ds.name IS NOT NULL THEN 'Running' ELSE 'Stopped' END AS status
FROM sys.server_event_sessions es
LEFT JOIN sys.dm_xe_sessions ds
    ON es.name = ds.name
ORDER BY es.name;


-- ============================================================
-- 第八章：阻塞鏈分析（土炮版）
-- 用途：發現阻塞時，快速呈現樹狀阻塞鏈
-- 使用時機：2-3 查到有阻塞時，跑這段看完整的樹狀結構
-- ============================================================

DROP TABLE IF EXISTS #BlockingChain;

CREATE TABLE #BlockingChain
(
    spid            INT,
    blocking_spid   INT,
    tree_level      INT,
    sort_path       VARCHAR(500),
    login_name      NVARCHAR(128),
    host_name       NVARCHAR(128),
    program_name    NVARCHAR(128),
    db_name         NVARCHAR(128),
    session_status  NVARCHAR(60),
    wait_sec        INT,
    wait_type       NVARCHAR(60),
    sql_text        NVARCHAR(MAX)
);

-- 找源頭 Blocker
INSERT INTO #BlockingChain
    (spid, blocking_spid, tree_level, sort_path,
     login_name, host_name, program_name, db_name,
     session_status, wait_sec, wait_type, sql_text)
SELECT
    s.session_id, 0, 0,
    RIGHT('00000' + CAST(s.session_id AS VARCHAR(10)), 5),
    s.login_name, s.host_name, s.program_name,
    DB_NAME(COALESCE(r.database_id, 0)),
    s.status, 0, NULL, t.text
FROM sys.dm_exec_sessions s
LEFT JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
LEFT JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
OUTER APPLY sys.dm_exec_sql_text(
    COALESCE(r.sql_handle, c.most_recent_sql_handle)
) t
WHERE s.session_id IN (
        SELECT DISTINCT blocking_session_id
        FROM sys.dm_exec_requests
        WHERE blocking_session_id > 0)
  AND s.session_id NOT IN (
        SELECT session_id
        FROM sys.dm_exec_requests
        WHERE blocking_session_id > 0);

-- WHILE 迴圈往下找受害者
DECLARE @current_level INT = 0;

WHILE 1 = 1
BEGIN
    INSERT INTO #BlockingChain
        (spid, blocking_spid, tree_level, sort_path,
         login_name, host_name, program_name, db_name,
         session_status, wait_sec, wait_type, sql_text)
    SELECT
        r.session_id, r.blocking_session_id,
        @current_level + 1,
        bc.sort_path + '.' + RIGHT('00000' + CAST(r.session_id AS VARCHAR(10)), 5),
        s.login_name, s.host_name, s.program_name,
        DB_NAME(r.database_id), s.status,
        r.wait_time / 1000, r.wait_type, t.text
    FROM sys.dm_exec_requests r
    JOIN sys.dm_exec_sessions s
        ON r.session_id = s.session_id
    JOIN #BlockingChain bc
        ON r.blocking_session_id = bc.spid
       AND bc.tree_level = @current_level
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.blocking_session_id > 0
      AND r.session_id NOT IN (SELECT spid FROM #BlockingChain);

    IF @@ROWCOUNT = 0 BREAK;
    SET @current_level = @current_level + 1;
    IF @current_level > 50 BREAK;
END

-- 呈現樹狀結果
SELECT
    blocking_tree =
        CASE
            WHEN tree_level = 0
                THEN '>>> [' + CAST(spid AS VARCHAR(10)) + '] ROOT BLOCKER'
            ELSE REPLICATE('    ', tree_level)
                 + '|-- [' + CAST(spid AS VARCHAR(10)) + '] WAITING'
        END,
    spid,
    blocking_spid,
    role           = CASE WHEN tree_level = 0 THEN 'ROOT' ELSE 'VICTIM' END,
    session_status,
    is_sleeping    = CASE WHEN session_status = 'sleeping' THEN 'YES' ELSE 'NO' END,
    wait_sec,
    wait_type,
    login_name,
    host_name,
    program_name,
    db_name,
    sql_text
FROM #BlockingChain
ORDER BY sort_path;

DROP TABLE #BlockingChain;


-- ============================================================
-- 第九章：tempdb 監控
-- 用途：評估 RCSI 或版本儲存區的空間使用
-- ============================================================

-- 9-1. tempdb 檔案空間使用
SELECT
    name,
    size * 8 / 1024                                 AS total_mb,
    FILEPROPERTY(name, 'SpaceUsed') * 8 / 1024      AS used_mb,
    (size - FILEPROPERTY(name, 'SpaceUsed')) * 8 / 1024 AS free_mb
FROM tempdb.sys.database_files;


-- 9-2. tempdb version store 大小
SELECT
    SUM(version_store_reserved_page_count) * 8 / 1024 AS version_store_mb,
    SUM(user_object_reserved_page_count) * 8 / 1024   AS user_object_mb,
    SUM(internal_object_reserved_page_count) * 8 / 1024 AS internal_object_mb
FROM sys.dm_db_file_space_usage
WHERE database_id = 2;


-- ============================================================
-- 第十章：效能比對用
-- 用途：改寫 SP 前後，用這個量化改善效果
-- ============================================================

-- 10-1. 開啟 IO 和時間統計
-- 改寫前跑一次、改寫後跑一次，比較 logical reads 和 elapsed time
SET STATISTICS IO ON;
SET STATISTICS TIME ON;

-- ★ 在這裡執行要測試的查詢或 SP
-- EXEC dbo.your_sp_name @param1 = 'value1';

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;


-- ============================================================
-- 使用提示
-- ============================================================
-- 1. 所有查詢都是 SELECT，不會修改任何資料
-- 2. 標示 ★ 的地方需要替換成實際值
-- 3. 第八章（阻塞鏈）需要整段一起跑，不能分段
-- 4. 建議在離峰時段跑大範圍查詢（第一章、第三章）
-- 5. 第二章適合在業務時段跑，才能看到即時狀態
-- ============================================================
