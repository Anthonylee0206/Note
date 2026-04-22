/* =========================================================================
   【用途】       兩段動態 SQL / 字元編碼的排錯練習：
                    前半段：動態 SQL 串 @A 到 SELECT TOP 的 bug 示範
                           （變數 @A 不會被代換到 @SQL 字面值裡面）
                    後半段：泰文字元 'ปณิธาน สิทธินวล' 塞進 VARCHAR(50) 被截掉的編碼問題
                           （示範為什麼該用 NVARCHAR + N'...' 前綴）
   【使用時機】   教學 / 自學；追不到為什麼資料變亂碼或顯示「??」時回來看。
   【輸入參數】   @a       — TOP 筆數（預設 3）
                  @mem_id  — 要 UPDATE 的 mem_name（預設一段泰文字）
   【輸出】       user_currency_log / mem_info 兩張測試表的查詢結果。
   【風險/注意】 - 會 DROP 重建 user_currency_log 與 mem_info，勿在 Prod 執行。
                  - 需要先跑 04_索引與資料表/Create_Table_範例.sql 建立 user_currency 表。
                  - 前半段的 INSERT ... SELECT 其實是語法錯誤（缺逗號 + @A 不會代換），
                    這就是這支的排錯重點。
   ========================================================================= */

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