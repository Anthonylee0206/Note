--1
DECLARE @SQL NVARCHAR(MAX), @user_id VARCHAR(10)

SET @user_id = 'idramadhanu@-'

SET @SQL = '
SELECT COUNT(*) AS cnt
FROM dbo..user_currency WITH (NOLOCK) AS a
WHERE a.user_id = @user_id'

EXEC sp_executesql @SQL,'@user_id VARCHAR(10)',@user_id
GO

--9
DECLARE @SQL VARCHAR(MAX), @user_id VARCHAR(10)s

SET @user_id = 'ictest003@'

SET @SQL = '
SET NOCOUNT ON

WITH A
AS
(
	SELECT *
	FROM dbo.user_currency a WITH (NOLOCK)
	WHERE user_id = @user_id
)
SELECT
	user_id,
	curr_id,
	merchent_id
FROM A JOIN [dbo].[user_currency_archive] h WITH (NOLOCK)
ON a.user_id = h.user_id
AND a.curr_id = a.curr_id
AND a.merchant_id = a.merchant_id'

EXEC sp_executesql @SQL,N'@user_id VARCHAR(10)',@user_id
GO