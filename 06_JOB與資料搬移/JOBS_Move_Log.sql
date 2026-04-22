/* =========================================================================
   【用途】       把舊資料從「主庫 (cmd_data)」搬到「log 庫 (cmd_data_log)」，
                  每支表寫一段。示範三種搬移技法：
                    (A) EXEC sp_move_data（泛用，設定表驅動）
                    (B) CTE + INSERT + DELETE（cashout_log：交易紀錄同步歸檔）
                    (C) DELETE TOP (N) OUTPUT INTO + WHILE 迴圈（pp_log：超大表分批）
   【使用時機】   排在 SQL Agent Job 每日 / 每週跑；手動補跑落後的日期。
   【輸入參數】   第 14 行 STEPNAME — 對應 sys_movelog_setting 內的 Table_Name。
                  第 20 行 @date — 保留最近幾個月（預設：半年前）。
                  第 56 行 DATEADD(MONTH,-3,...) — pp_log 保留最近幾個月（預設 3 個月）。
                  第 56 行 TOP (10000) — 單批大小。
   【輸出】       會把符合條件的資料從 cmd_data 的表搬到 cmd_data_log 對應表並刪除原資料。
   【風險/注意】 - 會先做 Primary Replica 檢查，Secondary 執行會 RAISERROR 中止。
                  - 含 DELETE + INSERT 雙向寫入，跑之前確認 target DB 存在且結構一致。
                  - pp_log 段是 10000 筆 × 1 秒 delay 的迴圈，跨天沒跑完會持續鎖；
                    視情況縮小 TOP 或調整 WAITFOR。
                  - 中斷可能留下「搬到一半」的狀態，重跑時可接續處理剩餘資料。
   ========================================================================= */

-- Check Replica - Primary

IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN

RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT

END

-- =============================================================

-- STEPNAME

EXEC sp_move_data 'STEPNAME','log'

-- =============================================================

-- provider_ticket_cmd_cashout_log

declare @date date = DATEADD(MONTH,-6,GETDATE()) 

;with cashout as 
(
	select soc_trans_id, working_date
	from cmd_data.dbo.provider_ticket_cmd with (nolock)
	where working_date < @date
)
insert into cmd_data_log.dbo.provider_ticket_cmd_cashout_log
select c.*, cashoutlog.working_date
from cmd_data.dbo.provider_ticket_cmd_cashout_log as c
inner join cashout as cashoutlog 
on cashoutlog.soc_trans_id = c.soc_trans_id

;with cashout as 
(
	select soc_trans_id 
	from cmd_data.dbo.provider_ticket_cmd with (nolock)
	where working_date < @date
)
delete c
from cmd_data.dbo.provider_ticket_cmd_cashout_log as c
inner join cashout as cashoutlog 
on cashoutlog.soc_trans_id = c.soc_trans_id

-- =============================================================

-- provider_ticket_pp_log

SET NOCOUNT ON;

WHILE (1=1)
BEGIN

WAITFOR DELAY '00:00:01.000'

DELETE TOP (10000) p 
OUTPUT 
deleted.* 
INTO cmd_data_log..provider_ticket_pp_log
FROM provider_ticket_pp_log p WITH (NOLOCK)
WHERE p.end_date < CAST(DATEADD(MONTH,-3,GETDATE()) AS DATE)
AND p.end_date IS NOT NULL

IF (@@ROWCOUNT < 10000)
BEGIN
	BREAK;
END


END

SET NOCOUNT OFF;

-- =============================================================