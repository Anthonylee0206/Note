USE [cmd_data]
GO

/****** Object:  StoredProcedure [dbo].[Backup_log]    Script Date: 2026/3/26 下午 04:28:49 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO






CREATE PROC [dbo].[Backup_log]
AS
BEGIN

SET NOCOUNT ON;

--LOG
DECLARE @pathname NVARCHAR(MAX) = N'E:\BAK\log\' + DB_NAME() + FORMAT(GETDATE(),'yyyyMMddHHmm') + 'log.bak'
DECLARE @SQL NVARCHAR(MAX)

SET @SQL = N'
BACKUP LOG [' + DB_NAME() + '] TO  DISK = N''' + @pathname + '''
WITH NOFORMAT, INIT,
NAME = N''' + DB_NAME() + N'_log'',  SKIP, NOREWIND, NOUNLOAD, COMPRESSION,  STATS = 10;
'

PRINT @SQL

EXECUTE (@SQL)

END

GO


