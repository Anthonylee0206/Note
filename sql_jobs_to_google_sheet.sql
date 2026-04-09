-- =====================================================================
-- SQL Server Agent Jobs 資訊匯出腳本
-- 用途：擷取 Job 完整資訊，匯出至 Google Sheet 整理
-- 使用方式：在 SSMS 執行後，將結果複製貼上到 Google Sheet
-- =====================================================================

-- =====================================================================
-- 查詢 1：Job 總覽 (貼到 Sheet 1 - Job 總覽)
-- =====================================================================
SELECT
    j.job_id,
    j.name                          AS [Job 名稱],
    CASE j.enabled
        WHEN 1 THEN '啟用'
        WHEN 0 THEN '停用'
    END                             AS [狀態],
    c.name                          AS [分類],
    j.description                   AS [描述],
    SUSER_SNAME(j.owner_sid)        AS [擁有者],
    j.date_created                  AS [建立日期],
    j.date_modified                 AS [最後修改日期],
    -- 最後執行結果
    CASE ja.last_executed_step_id
        WHEN 0 THEN '尚未執行'
        ELSE CAST(ja.last_executed_step_id AS VARCHAR)
    END                             AS [最後執行步驟],
    CASE h.run_status
        WHEN 0 THEN '失敗'
        WHEN 1 THEN '成功'
        WHEN 2 THEN '重試'
        WHEN 3 THEN '已取消'
        WHEN 4 THEN '進行中'
        ELSE '尚未執行'
    END                             AS [最後執行結果],
    -- 最後執行時間
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS [最後執行時間],
    -- 執行時長 (秒)
    h.run_duration / 10000 * 3600
    + (h.run_duration % 10000) / 100 * 60
    + h.run_duration % 100              AS [執行時長(秒)],
    -- 排程資訊
    CASE s.freq_type
        WHEN 1  THEN '單次'
        WHEN 4  THEN '每天'
        WHEN 8  THEN '每週'
        WHEN 16 THEN '每月'
        WHEN 32 THEN '每月相對'
        WHEN 64 THEN 'SQL Agent 啟動時'
        WHEN 128 THEN '伺服器閒置時'
        ELSE '無排程'
    END                             AS [排程頻率],
    CASE
        WHEN s.freq_type = 4 THEN '每 ' + CAST(s.freq_interval AS VARCHAR) + ' 天'
        WHEN s.freq_type = 8 THEN
            CASE WHEN s.freq_interval & 1  = 1  THEN '日 ' ELSE '' END +
            CASE WHEN s.freq_interval & 2  = 2  THEN '一 ' ELSE '' END +
            CASE WHEN s.freq_interval & 4  = 4  THEN '二 ' ELSE '' END +
            CASE WHEN s.freq_interval & 8  = 8  THEN '三 ' ELSE '' END +
            CASE WHEN s.freq_interval & 16 = 16 THEN '四 ' ELSE '' END +
            CASE WHEN s.freq_interval & 32 = 32 THEN '五 ' ELSE '' END +
            CASE WHEN s.freq_interval & 64 = 64 THEN '六 ' ELSE '' END
        ELSE ''
    END                             AS [排程間隔明細],
    -- 排程執行時間
    STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':')
                                    AS [排程開始時間],
    CASE s.freq_subday_type
        WHEN 1 THEN '於指定時間'
        WHEN 2 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 秒'
        WHEN 4 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 分鐘'
        WHEN 8 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 小時'
        ELSE ''
    END                             AS [子排程頻率],
    @@SERVERNAME                    AS [伺服器名稱]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.syscategories c
    ON j.category_id = c.category_id
LEFT JOIN msdb.dbo.sysjobschedules js
    ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s
    ON js.schedule_id = s.schedule_id
LEFT JOIN msdb.dbo.sysjobactivity ja
    ON j.job_id = ja.job_id
    AND ja.session_id = (SELECT MAX(session_id) FROM msdb.dbo.sysjobactivity)
OUTER APPLY (
    SELECT TOP 1 run_status, run_date, run_time, run_duration
    FROM msdb.dbo.sysjobhistory
    WHERE job_id = j.job_id AND step_id = 0
    ORDER BY run_date DESC, run_time DESC
) h
ORDER BY j.name;


-- =====================================================================
-- 查詢 2：Job Steps 明細 (貼到 Sheet 2 - 步驟明細)
-- =====================================================================
SELECT
    j.name                          AS [Job 名稱],
    js.step_id                      AS [步驟編號],
    js.step_name                    AS [步驟名稱],
    CASE js.subsystem
        WHEN 'TSQL'       THEN 'T-SQL'
        WHEN 'CmdExec'    THEN '作業系統命令'
        WHEN 'PowerShell' THEN 'PowerShell'
        WHEN 'SSIS'       THEN 'SSIS 封裝'
        ELSE js.subsystem
    END                             AS [步驟類型],
    js.database_name                AS [執行資料庫],
    js.command                      AS [執行命令],
    CASE js.on_success_action
        WHEN 1 THEN '成功後結束'
        WHEN 2 THEN '成功後到下一步'
        WHEN 3 THEN '成功後跳到步驟 ' + CAST(js.on_success_step_id AS VARCHAR)
        WHEN 4 THEN '成功後報告失敗'
    END                             AS [成功後動作],
    CASE js.on_fail_action
        WHEN 1 THEN '失敗後結束'
        WHEN 2 THEN '失敗後到下一步'
        WHEN 3 THEN '失敗後跳到步驟 ' + CAST(js.on_fail_step_id AS VARCHAR)
        WHEN 4 THEN '失敗後報告失敗'
    END                             AS [失敗後動作],
    js.retry_attempts               AS [重試次數],
    js.retry_interval               AS [重試間隔(分鐘)],
    @@SERVERNAME                    AS [伺服器名稱]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobsteps js
    ON j.job_id = js.job_id
ORDER BY j.name, js.step_id;


-- =====================================================================
-- 查詢 3：Job 執行歷史紀錄 (貼到 Sheet 3 - 執行歷史)
-- =====================================================================
SELECT
    j.name                          AS [Job 名稱],
    h.step_id                       AS [步驟編號],
    h.step_name                     AS [步驟名稱],
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS [執行時間],
    CASE h.run_status
        WHEN 0 THEN '失敗'
        WHEN 1 THEN '成功'
        WHEN 2 THEN '重試'
        WHEN 3 THEN '已取消'
        WHEN 4 THEN '進行中'
    END                             AS [執行結果],
    h.run_duration / 10000 * 3600
    + (h.run_duration % 10000) / 100 * 60
    + h.run_duration % 100          AS [執行時長(秒)],
    h.message                       AS [訊息],
    @@SERVERNAME                    AS [伺服器名稱]
FROM msdb.dbo.sysjobhistory h
INNER JOIN msdb.dbo.sysjobs j
    ON h.job_id = j.job_id
WHERE h.run_date >= CONVERT(VARCHAR(8), DATEADD(DAY, -30, GETDATE()), 112)  -- 最近 30 天
ORDER BY j.name, h.run_date DESC, h.run_time DESC;


-- =====================================================================
-- 查詢 4：Job 排程明細 (貼到 Sheet 4 - 排程明細)
-- =====================================================================
SELECT
    j.name                          AS [Job 名稱],
    s.name                          AS [排程名稱],
    CASE s.enabled
        WHEN 1 THEN '啟用'
        WHEN 0 THEN '停用'
    END                             AS [排程狀態],
    CASE s.freq_type
        WHEN 1  THEN '單次'
        WHEN 4  THEN '每天'
        WHEN 8  THEN '每週'
        WHEN 16 THEN '每月'
        WHEN 32 THEN '每月相對'
        WHEN 64 THEN 'SQL Agent 啟動時'
        WHEN 128 THEN '伺服器閒置時'
    END                             AS [頻率類型],
    CASE s.freq_type
        WHEN 4 THEN '每 ' + CAST(s.freq_interval AS VARCHAR) + ' 天'
        WHEN 8 THEN
            CASE WHEN s.freq_interval & 1  = 1  THEN '週日 ' ELSE '' END +
            CASE WHEN s.freq_interval & 2  = 2  THEN '週一 ' ELSE '' END +
            CASE WHEN s.freq_interval & 4  = 4  THEN '週二 ' ELSE '' END +
            CASE WHEN s.freq_interval & 8  = 8  THEN '週三 ' ELSE '' END +
            CASE WHEN s.freq_interval & 16 = 16 THEN '週四 ' ELSE '' END +
            CASE WHEN s.freq_interval & 32 = 32 THEN '週五 ' ELSE '' END +
            CASE WHEN s.freq_interval & 64 = 64 THEN '週六 ' ELSE '' END
        WHEN 16 THEN '每月第 ' + CAST(s.freq_interval AS VARCHAR) + ' 天'
        ELSE ''
    END                             AS [執行日],
    STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':')
                                    AS [開始時間],
    CASE s.freq_subday_type
        WHEN 1 THEN '於指定時間執行一次'
        WHEN 2 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 秒'
        WHEN 4 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 分鐘'
        WHEN 8 THEN '每 ' + CAST(s.freq_subday_interval AS VARCHAR) + ' 小時'
    END                             AS [子頻率],
    STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':')
                                    AS [結束時間],
    @@SERVERNAME                    AS [伺服器名稱]
FROM msdb.dbo.sysjobs j
INNER JOIN msdb.dbo.sysjobschedules js
    ON j.job_id = js.job_id
INNER JOIN msdb.dbo.sysschedules s
    ON js.schedule_id = s.schedule_id
ORDER BY j.name, s.name;


-- =====================================================================
-- 查詢 5：Job 通知設定 (貼到 Sheet 5 - 通知設定)
-- =====================================================================
SELECT
    j.name                          AS [Job 名稱],
    CASE j.notify_level_email
        WHEN 0 THEN '不通知'
        WHEN 1 THEN '成功時'
        WHEN 2 THEN '失敗時'
        WHEN 3 THEN '完成時'
    END                             AS [Email 通知條件],
    ISNULL(o_email.name, '無')      AS [Email 操作員],
    CASE j.notify_level_page
        WHEN 0 THEN '不通知'
        WHEN 1 THEN '成功時'
        WHEN 2 THEN '失敗時'
        WHEN 3 THEN '完成時'
    END                             AS [呼叫器通知條件],
    CASE j.delete_level
        WHEN 0 THEN '不刪除'
        WHEN 1 THEN '成功後刪除'
        WHEN 2 THEN '失敗後刪除'
        WHEN 3 THEN '完成後刪除'
    END                             AS [自動刪除條件],
    @@SERVERNAME                    AS [伺服器名稱]
FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysoperators o_email
    ON j.notify_email_operator_id = o_email.id
ORDER BY j.name;
