/* =========================================================================
   【用途】       建立預存程序 dbo.sp_move_data。這支是「設定表驅動」的泛用搬移工具：
                  從 sys_movelog_setting 讀取 (FromDB / TargetDB / Table / FilterCol / Where)
                  組出動態 SQL，用 DELETE OUTPUT INTO 分批搬資料（每 5 萬筆一批迴圈）。
                  JOBS_Move_Log.sql / JOBS_Move_Ticket_Data.sql 都透過呼叫這支完成工作。
   【使用時機】   新增 / 調整任何一張表的搬移規則時；排在每日 JOB 週期內呼叫。
   【輸入參數】   @Tbname    — 要搬移的 Table_Name（對 sys_movelog_setting.Table_Name）。
                  @TableType — 'log' 或 'ticket'（對 sys_movelog_setting.TableType）。
                  其餘來源 DB / 目標 DB / 過濾欄位 / 邊界值全在 sys_movelog_setting 裡。
   【輸出】       從 @FromDbName.dbo.@Table_Name 搬資料到 @TargetDbName.dbo.@Table_Name；
                  單批 50000 筆，直到 @@ROWCOUNT < 50000 才 BREAK。
   【風險/注意】 - WhereString 是字串拼接，若 sys_movelog_setting 可被外部寫入會有
                    SQL Injection 風險；設定表務必只讓 DBA 寫入。
                  - 無 TRY/CATCH，任一批失敗會中斷，前面已搬的不會回滾。
                  - 無條件檢查：若 sys_movelog_setting 找不到設定，@SQL 會是 NULL，
                    IF @SQL IS NOT NULL 會直接略過，不會報錯也不會搬。
   ========================================================================= */

USE [cmd_data]
GO

/****** Object:  StoredProcedure [dbo].[sp_move_data]    Script Date: 2026/3/26 下午 04:27:58 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROC [dbo].[sp_move_data]
	@Tbname VARCHAR(50),
	@TableType VARCHAR(6)
AS
BEGIN

SET NOCOUNT ON;

DECLARE @Table_Name VARCHAR(50),
		@FilterColName VARCHAR(20),
		@WhereString VARCHAR(200),
		@FromDbName VARCHAR(20),
		@TargetDbName VARCHAR(20)

DECLARE @SQL NVARCHAR(500)


SELECT @Table_Name = Table_Name,
	   @FilterColName = FilterColName,
	   @WhereString = WhereString,
	   @FromDbName = FromDbName,
	   @TargetDbName = TargetDbName
FROM cmd_data.dbo.sys_movelog_setting
WHERE Table_Name = @Tbname AND TableType = @TableType

SET @SQL = '
DELETE ' + @Table_Name + '
OUTPUT deleted.* 
INTO ' + @TargetDbName + '.dbo.' + @Table_Name + ' 
FROM ' + @FromDbName + '.dbo.' + @Table_Name + '
WHERE ' + @FilterColName + ' < ' + @WhereString

IF @SQL IS NOT NULL
BEGIN
	WHILE (1=1)
	BEGIN

		EXEC sp_executesql @SQL

		IF (@@ROWCOUNT < 50000)
			BREAK;
	END
END

SET NOCOUNT OFF;

END
GO


