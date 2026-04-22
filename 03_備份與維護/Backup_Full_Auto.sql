/* =========================================================================
   【用途】       對所有「使用者資料庫」做 FULL 備份，檔案帶日期存到 @DBPath。
   【使用時機】   每日 FULL 備份（可掛 SQL Agent Job 排程）；或手動一次性備份所有庫。
   【輸入參數】   @DBPath：備份輸出目錄（預設 D:\BAK，目錄必須已存在）。
                  排除清單寫死為 master / model / msdb / tempdb，且僅備份 ONLINE 狀態。
   【輸出】       每個 DB 印出 ---DBName BEGIN--- / ---DBName END---；失敗時 RAISERROR 錯誤。
                  實體檔：{@DBPath}\{DBName}_full_yyyyMMdd.bak
   【風險/注意】 - 使用 COPY_ONLY，不影響 log backup chain（不會切斷 log 備份序列）。
                  - 啟用 COMPRESSION，CPU 用量會升高。
                  - 同一天重跑：INIT 會直接覆蓋當日檔。
                  - 目錄不存在 / 權限不足會進 CATCH，只印錯誤不中斷整體迴圈。
   ========================================================================= */

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
