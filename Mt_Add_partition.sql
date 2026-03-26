--Check Replica - Primary

IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
		
RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
		
END

-- =============================================================

-- cmd_data_provider_ticket

USE [cmd_data]
GO

SET NOCOUNT, ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;

ALTER PARTITION SCHEME [Psh_ticket_date] NEXT USED [FG_provider_ticket]
GO

DECLARE
	@MONDAY NVARCHAR(10) = FORMAT(DATEADD(DAY,7,GETDATE()),'yyyy-MM-dd')

ALTER PARTITION FUNCTION [Pfn_ticket_date]() SPLIT RANGE(N''+@MONDAY+'T12:00:00.000')
GO

SET NOCOUNT, ARITHABORT OFF;
SET QUOTED_IDENTIFIER OFF;

-- =============================================================