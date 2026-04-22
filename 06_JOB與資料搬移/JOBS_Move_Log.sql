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