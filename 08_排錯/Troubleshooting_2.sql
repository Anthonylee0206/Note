DROP TABLE IF EXISTS [user_currency_log]

CREATE TABLE [dbo].[user_currency_log]
(
	log_date DATETIME,
	[user_id] [varchar](50) NOT NULL,
	[curr_id] [varchar](10) NOT NULL,
	[merchant_id] [varchar](10) NOT NULL
);

DECLARE @a INT = 3,@SQL NVARCHAR(100)

SET @SQL = '
INSERT INTO [user_currency_log]
SELECT TOP @A
 GETDATE()
 [user_id]
,[curr_id]
,[merchant_id]
FROM [dbo].[user_currency] WITH (NOLOCK)
WHERE [user_id] = ''ek@''

SELECT * FROM user_currency_log'

EXEC (@SQL)
GO

DROP TABLE IF EXISTS mem_info

CREATE TABLE mem_info
(
	mem_id INT IDENTITY(1,1) PRIMARY KEY NOT NULL,
	mem_name VARCHAR(50)
)

INSERT INTO mem_info VALUES ('testcmd123idr')

DECLARE @mem_id VARCHAR(50) = 'ปณิธาน สิทธินวล'
EXEC sp_executesql N'UPDATE mem_info SET mem_name = @mem_id',N'@mem_id VARCHAR(50)',@mem_id

SELECT * FROM mem_info