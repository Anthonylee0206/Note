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


