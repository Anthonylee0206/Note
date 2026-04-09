-- =====================================================================
-- SQL Server Agent Jobs 匯出至 Google Sheet
-- 用途：一次查詢產出所有 Job 排程資訊，直接貼到 Google Sheet
-- 欄位：Job Name | Enabled | Freq | Day | Time | Schedule Summary | Description
-- =====================================================================

SELECT
    j.name                              AS [Job Name],
    j.enabled                           AS [Enabled],

    -- Freq: 頻率描述
    CASE s.freq_type
        WHEN 1  THEN 'Once'
        WHEN 4  THEN
            CASE WHEN s.freq_interval = 1 THEN 'Daily'
                 ELSE 'Every ' + CAST(s.freq_interval AS VARCHAR) + ' days'
            END
        WHEN 8  THEN
            CASE WHEN s.freq_recurrence_factor = 1 THEN 'Weekly'
                 ELSE 'Every ' + CAST(s.freq_recurrence_factor AS VARCHAR) + ' weeks'
            END
        WHEN 16 THEN
            CASE WHEN s.freq_recurrence_factor = 1 THEN 'Monthly'
                 ELSE 'Every ' + CAST(s.freq_recurrence_factor AS VARCHAR) + ' months'
            END
        WHEN 32 THEN 'Monthly Relative'
        WHEN 64 THEN 'On Agent Start'
        WHEN 128 THEN 'On Idle'
        ELSE ''
    END                                 AS [Freq],

    -- Day: 執行日
    CASE s.freq_type
        WHEN 4 THEN 'Daily'
        WHEN 8 THEN
            LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Mon ' ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tue ' ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wed ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thu ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Fri ' ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Sat ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sun ' ELSE '' END
            )
        WHEN 16 THEN 'Day ' + CAST(s.freq_interval AS VARCHAR)
        WHEN 32 THEN
            CASE s.freq_relative_interval
                WHEN 1  THEN 'First '
                WHEN 2  THEN 'Second '
                WHEN 4  THEN 'Third '
                WHEN 8  THEN 'Fourth '
                WHEN 16 THEN 'Last '
            END +
            CASE s.freq_interval
                WHEN 1  THEN 'Sun'
                WHEN 2  THEN 'Mon'
                WHEN 3  THEN 'Tue'
                WHEN 4  THEN 'Wed'
                WHEN 5  THEN 'Thu'
                WHEN 6  THEN 'Fri'
                WHEN 7  THEN 'Sat'
                WHEN 8  THEN 'Day'
                WHEN 9  THEN 'Weekday'
                WHEN 10 THEN 'Weekend'
            END
        ELSE ''
    END                                 AS [Day],

    -- Time: 執行時間 (格式 HH:MM AM/PM)
    CASE
        WHEN s.freq_subday_type = 1 THEN  -- 只在指定時間執行一次
            LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME),
                100), 11))
        ELSE  -- 有子頻率 (每 N 分鐘/小時)，顯示起迄區間
            LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME),
                100), 11))
            + ' - '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22),
                CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME),
                100), 11))
    END                                 AS [Time],

    -- Schedule Summary: 完整排程描述 (模擬 SQL Server Agent 格式)
    CASE
        -- 每天 + 子頻率 (每 N 分鐘/小時)
        WHEN s.freq_type = 4 AND s.freq_subday_type IN (2, 4, 8) THEN
            'Occurs every day, every '
            + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每天 + 指定時間
        WHEN s.freq_type = 4 AND s.freq_subday_type = 1 THEN
            'Occurs every day at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每週 + 子頻率
        WHEN s.freq_type = 8 AND s.freq_subday_type IN (2, 4, 8) THEN
            'Occurs every week on '
            + LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Monday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tuesday, '  ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wednesday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Friday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sunday, '   ELSE '' END
              )
            + 'every '
            + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每週 + 指定時間
        WHEN s.freq_type = 8 AND s.freq_subday_type = 1 THEN
            'Occurs every week on '
            + LTRIM(
                CASE WHEN s.freq_interval & 2  = 2  THEN 'Monday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 4  = 4  THEN 'Tuesday, '  ELSE '' END +
                CASE WHEN s.freq_interval & 8  = 8  THEN 'Wednesday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 16 = 16 THEN 'Thursday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 32 = 32 THEN 'Friday, '   ELSE '' END +
                CASE WHEN s.freq_interval & 64 = 64 THEN 'Saturday, ' ELSE '' END +
                CASE WHEN s.freq_interval & 1  = 1  THEN 'Sunday, '   ELSE '' END
              )
            + 'at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每月 + 指定時間
        WHEN s.freq_type = 16 AND s.freq_subday_type = 1 THEN
            'Occurs every month on day '
            + CAST(s.freq_interval AS VARCHAR)
            + ' at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每月 + 子頻率
        WHEN s.freq_type = 16 AND s.freq_subday_type IN (2, 4, 8) THEN
            'Occurs every month on day '
            + CAST(s.freq_interval AS VARCHAR)
            + ', every '
            + CAST(s.freq_subday_interval AS VARCHAR) + ' '
            + CASE s.freq_subday_type WHEN 2 THEN 'second(s)' WHEN 4 THEN 'minute(s)' WHEN 8 THEN 'hour(s)' END
            + ' between '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))
            + ' and '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_end_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 每月相對 + 指定時間
        WHEN s.freq_type = 32 AND s.freq_subday_type = 1 THEN
            'Occurs every month on the '
            + CASE s.freq_relative_interval
                WHEN 1  THEN 'first '
                WHEN 2  THEN 'second '
                WHEN 4  THEN 'third '
                WHEN 8  THEN 'fourth '
                WHEN 16 THEN 'last '
              END
            + CASE s.freq_interval
                WHEN 1  THEN 'Sunday'  WHEN 2  THEN 'Monday'  WHEN 3  THEN 'Tuesday'
                WHEN 4  THEN 'Wednesday' WHEN 5 THEN 'Thursday' WHEN 6 THEN 'Friday'
                WHEN 7  THEN 'Saturday' WHEN 8 THEN 'day' WHEN 9 THEN 'weekday' WHEN 10 THEN 'weekend day'
              END
            + ' at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- 單次
        WHEN s.freq_type = 1 THEN
            'Occurs once at '
            + LTRIM(RIGHT(CONVERT(VARCHAR(22), CAST(STUFF(STUFF(RIGHT('000000' + CAST(s.active_start_time AS VARCHAR), 6), 5, 0, ':'), 3, 0, ':') AS TIME), 100), 11))

        -- Agent 啟動時
        WHEN s.freq_type = 64  THEN 'Occurs when SQL Server Agent starts'
        WHEN s.freq_type = 128 THEN 'Occurs when server is idle'

        ELSE ''
    END                                 AS [Schedule Summary],

    j.description                       AS [Description]

FROM msdb.dbo.sysjobs j
LEFT JOIN msdb.dbo.sysjobschedules js
    ON j.job_id = js.job_id
LEFT JOIN msdb.dbo.sysschedules s
    ON js.schedule_id = s.schedule_id
ORDER BY j.name;
