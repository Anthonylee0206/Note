/* =========================================================================
   【用途】       把舊 ticket 資料從主庫 (cmd_data) 搬到 archive 庫 (cmd_data_archive)。
                  示範兩種搬移技法：
                    (A) EXEC sp_move_data 'STEPNAME','ticket'（設定表驅動的泛用做法）
                    (B) DELETE OUTPUT INTO + JOIN 判定（cashout 跟著 cmd 的 working_date 歸檔）
   【使用時機】   排在 SQL Agent Job 每日 / 每週跑；手動補跑落後日期。
   【輸入參數】   第 14 行 STEPNAME — 對應 sys_movelog_setting 內的 Table_Name。
                  第 26 行 CONVERT(..., GETDATE()-365, 111) — 保留最近幾天（預設 365 天）。
   【輸出】       符合條件的 ticket / cashout 從 cmd_data 移到 cmd_data_archive。
   【風險/注意】 - 會先做 Primary Replica 檢查，Secondary 執行會 RAISERROR 中止。
                  - (B) 段一次性 DELETE 不分批，巨量資料下會長時間鎖表 + 長交易；
                    視情況改用分批 TOP (N) + WHILE 迴圈。
                  - 需確認 archive 庫的目標表結構與主庫一致，否則 OUTPUT INTO 欄位對不上。
   ========================================================================= */

-- Check Replica - Primary

IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
		
RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
		
END

-- =============================================================

-- STEPNAME

EXEC sp_move_data 'STEPNAME','ticket'

-- =============================================================

-- provider_ticket_cmd_cashout

DELETE cc OUTPUT
deleted.*,cmd.working_date
INTO cmd_data_archive.dbo.provider_ticket_cmd_cashout
FROM dbo.provider_ticket_cmd_cashout cc
JOIN cmd_data_archive.dbo.[provider_ticket_cmd] cmd
ON cc.[soc_trans_id] = cmd.[soc_trans_id] 
AND cmd.[working_date] < CONVERT(VARCHAR(10),GETDATE()-365,111)

-- =============================================================






