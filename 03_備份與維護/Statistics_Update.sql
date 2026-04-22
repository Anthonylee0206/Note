SET NOCOUNT ON;

DECLARE @DBName NVARCHAR(100);
DECLARE @SQL    NVARCHAR(MAX);
DECLARE @Mes    NVARCHAR(200);

DECLARE @DBList TABLE (DBName NVARCHAR(100));

INSERT INTO @DBList (DBName)
SELECT [name] 
FROM sys.databases 
WHERE [name] NOT IN ('master', 'model', 'msdb', 'tempdb') 
  AND state_desc = 'ONLINE';

WHILE EXISTS (SELECT 1 FROM @DBList)
BEGIN
    SELECT TOP 1 @DBName = DBName FROM @DBList;

    SET @Mes = N'---' + @DBName + N' Statistics Update BEGIN---';
    RAISERROR(@Mes, 10, 1) WITH NOWAIT;

    SET @SQL = N'USE ' + QUOTENAME(@DBName) + N'; EXEC sp_updatestats;';

    BEGIN TRY
        EXEC sp_executesql @SQL;
    END TRY
    BEGIN CATCH
        SET @Mes = N'Error updating ' + @DBName + N': ' + ERROR_MESSAGE();
        RAISERROR(@Mes, 10, 1) WITH NOWAIT;
    END CATCH

    SET @Mes = N'---' + @DBName + N' Statistics Update END---';
    RAISERROR(@Mes, 10, 1) WITH NOWAIT;
    RAISERROR('', 10, 1) WITH NOWAIT;

    DELETE FROM @DBList WHERE DBName = @DBName;
END

