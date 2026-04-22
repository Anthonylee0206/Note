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






