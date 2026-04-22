SET NOCOUNT ON;

DECLARE @DBPath     NVARCHAR(100) = N'D:\BAK';
DECLARE @DBName     NVARCHAR(100);
DECLARE @BackupPath NVARCHAR(MAX);
DECLARE @SQL        NVARCHAR(MAX);
DECLARE @Mes        NVARCHAR(200);

DECLARE @DBList TABLE (DBName NVARCHAR(100));

INSERT INTO @DBList (DBName)
SELECT [name]
FROM sys.databases
WHERE [name] NOT IN ('master', 'model', 'msdb', 'tempdb')
    AND state_desc = 'ONLINE';

WHILE EXISTS (SELECT 1 FROM @DBList)
BEGIN
    SELECT TOP 1 @DBName = DBName FROM @DBList;
    SELECT @Mes = N'---' + @DBName + N' BEGIN---';
    RAISERROR(@Mes, 10, 1) WITH NOWAIT;
    
    SET @BackupPath = @DBPath + N'\' + @DBName + N'_full_' + FORMAT(GETDATE(), 'yyyyMMdd') + N'.bak';
    SET @SQL = N'BACKUP DATABASE ' + QUOTENAME(@DBName) + 
               N' TO DISK = N''' + @BackupPath + N''' ' + 
               N' WITH COPY_ONLY, NOFORMAT, INIT, NAME = N''' + @DBName + N''', ' + 
               N' SKIP, NOREWIND, NOUNLOAD, COMPRESSION, ' + 
               N' STATS = 20, MAXTRANSFERSIZE = 4194304, BUFFERCOUNT = 8;';
   
    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        SET @Mes = N'Error backing up ' + @DBName + N': ' + ERROR_MESSAGE();
        RAISERROR(@Mes, 10, 1) WITH NOWAIT;
    END CATCH

    SET @Mes = N'---' + @DBName + N' END---';
    RAISERROR(@Mes, 10, 1) WITH NOWAIT;
    RAISERROR('', 10, 1) WITH NOWAIT;
    DELETE FROM @DBList WHERE DBName = @DBName;
END
