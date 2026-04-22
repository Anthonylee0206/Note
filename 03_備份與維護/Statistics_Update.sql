/* =========================================================================
   【用途】       對所有「使用者資料庫」逐一執行 EXEC sp_updatestats，更新統計資訊。
   【使用時機】   定期維護（週末 / 月初）；查詢計畫變差、執行時間忽然變長時；
                  大量資料匯入 / 搬移後；索引 REBUILD 之後補上。
   【輸入參數】   無。排除清單寫死為 master / model / msdb / tempdb，且僅處理 ONLINE。
   【輸出】       每個 DB 印出 ---DBName Statistics Update BEGIN--- / END---；
                  失敗時 RAISERROR 錯誤訊息並繼續跑下一個 DB。
   【風險/注意】 - sp_updatestats 只處理「修改過筆數達門檻」的統計，不是全量更新；
                    需要全量請改 UPDATE STATISTICS ... WITH FULLSCAN。
                  - 大 DB 跑起來可能數分鐘～數十分鐘，會吃 CPU/IO。
                  - 整體不在交易內，任一 DB 失敗不會回滾前面的。
   ========================================================================= */

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

