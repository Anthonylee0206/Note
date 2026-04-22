/* =========================================================================
   【用途】       動態 SQL 的兩個排錯練習片段：
                    --1 段：參數化 COUNT 查詢（少寫 schema / 用錯 ..） — 練 sp_executesql 用法
                    --9 段：WITH CTE 動態拼接 JOIN（有多個錯誤：型別宣告、別名、欄位名）
                  預期會報錯，屬於「從錯誤中學」的練習題，不是可直接執行的範本。
   【使用時機】   SQL 教學 / 自學 / 面試題模擬；練習看到錯誤訊息能不能秒修。
   【輸入參數】   @user_id — 要查的使用者代號。
   【輸出】       正確修正後：COUNT(*) 筆數；或 CTE JOIN 結果。
                  未修正執行：SQL Server 會報語法 / 物件錯誤。
   【風險/注意】 - 需要先跑 04_索引與資料表/Create_Table_範例.sql 建立 user_currency 表。
                  - --9 段有數個刻意 / 非刻意的 bug（例如 `VARCHAR(10)s`、欄位名 merchent_id
                    vs merchant_id、別名 a 未在 SELECT 列中定義等）— 找 bug 是重點。
   ========================================================================= */

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