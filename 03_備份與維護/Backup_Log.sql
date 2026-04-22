/* =========================================================================
   【用途】       建立預存程序 dbo.Backup_log，執行時對「目前 USE 的 DB」做交易
                  記錄備份到 E:\BAK\log\，檔名帶 yyyyMMddHHmm。
   【使用時機】   日常 log 備份；搭配 SQL Agent Job 每小時排程；災難復原點。
   【輸入參數】   無。備份路徑寫死在 @pathname（E:\BAK\log\）。
                  要備份哪個 DB 由呼叫端決定（USE 哪個就備哪個，透過 DB_NAME() 取得）。
   【輸出】       實體檔：E:\BAK\log\{DBName}{yyyyMMddHHmm}log.bak
                  PRINT @SQL 會印出實際執行的 BACKUP LOG 指令。
   【風險/注意】 - 使用 INIT（覆蓋同名檔），同分鐘內重跑會覆蓋。
                  - 啟用 COMPRESSION，吃 CPU。
                  - DB 需為 FULL/BULK_LOGGED 還原模式才能備 log；SIMPLE 模式會報錯。
                  - E:\BAK\log 目錄必須存在。
   ========================================================================= */

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


