# 動態 SQL 架構設計：模組化變數拆分法
---
## 🚨 核心痛點：SQL 的「絕對語法順序」
在 SQL 的世界裡，執行語法有著不可跨越的嚴格順序：
👉 `SELECT` ➔ `FROM` ➔ `JOIN` ➔ `WHERE` ➔ `GROUP BY` ➔ `ORDER BY`

當我們在後端程式或預存程序 (SP) 中「動態拼接」字串時，使用者的輸入條件是隨機的（可能填了 A 條件，也可能填了 B 條件）。如果我們只用單一變數順著程式邏輯往下拼，極容易觸發「語法順序錯亂」的地獄。

## 💥 災難示範：只用單一變數 (`@SQL`) 拼到底
情境：工程師用一個 `@SQL` 變數，隨著程式由上往下，遇到什麼條件就往字串後面加（使用 `+=`）。
```sql
DECLARE @SQL NVARCHAR(MAX) = 'SELECT * FROM ticket WHERE 1=1 ';

-- 狀況 1：使用者輸入了姓名，直接黏在後面 (沒問題)
IF @acct_name <> ''
    SET @SQL += ' AND acct_name = @acct_name';

-- 狀況 2：使用者輸入了部門，這需要 JOIN 員工表才能過濾！
IF @dept_name <> ''
    -- ❌ 致命錯誤：此時字串已經寫到 WHERE 了，你卻把 JOIN 黏在 WHERE 的屁股後面！
    SET @SQL += ' INNER JOIN users U ON ticket.acct_name = U.acct_name AND U.dept = @dept_name';
```
### 🔥 最終產出的死亡語法：
`SELECT * FROM ticket WHERE 1=1 AND acct_name = @acct_name INNER JOIN users...`
(SQL Server 報錯：無效的語法。因為 JOIN 絕對不能出現在 WHERE 之後！)

## 🛡️ 業界標準解法：模組化變數拆分 (三/四變數流派)
為了解決這個順序危機，資深工程師會採用**「分類購物車（模組化）」**的概念。
我們不急著把字串組裝起來，而是依照 SQL 的語法結構，準備不同的變數（購物車）來分別收集對應的積木。直到最後一刻，才按照 SQL 規定的順序進行「大合體」。

### 🧱 變數分工定義：
1.`@SQL_Base` (主底盤)：存放永遠不會變的基礎查詢 (`SELECT ... FROM ...`)。

2.`@SQL_Join` (關聯車廂)：專門收集所有的 `INNER JOIN` 或 `LEFT JOIN` 條件。一開始為空字串 ''。

3.`@SQL_Where` (過濾車廂)：專門收集查詢條件。起手式永遠是 `' WHERE 1=1 '`。

4.`@SQL_OrderBy` (排序車廂)：專門收集排序規則。起手式為空字串 `''`。

## ⌨️ 完美實戰範例碼 (支援 JOIN 與多條件)
這個寫法無論未來的過濾條件怎麼增加、順序怎麼跳躍，都絕對不會出錯：
```sql
-- ==========================================
-- 1. 準備專屬購物車 (宣告模組化變數)
-- ==========================================
DECLARE @SQL_Base    NVARCHAR(MAX) = 'SELECT T.ticket_id, T.acct_name FROM [dbo].[ticket] T '; 
DECLARE @SQL_Join    NVARCHAR(MAX) = '';             
DECLARE @SQL_Where   NVARCHAR(MAX) = ' WHERE 1=1 ';  
DECLARE @SQL_OrderBy NVARCHAR(MAX) = '';             

-- 模擬前端傳來的參數
DECLARE @acct_name VARCHAR(10) = 'Ryan';
DECLARE @dept_name VARCHAR(20) = 'IT';
DECLARE @sort_type INT = 1;

-- ==========================================
-- 2. 收集積木時間 (順序隨便寫，不會互相干擾！)
-- ==========================================

-- 條件 A：如果有姓名，丟進 WHERE 車廂
IF @acct_name <> ''
    SET @SQL_Where += ' AND T.acct_name = @acct_name';

-- 條件 B：如果有部門，同時需要 JOIN 表 與 WHERE 條件
IF @dept_name <> ''
BEGIN
    -- 1. 把 JOIN 積木精準丟進 JOIN 車廂
    SET @SQL_Join += ' INNER JOIN [dbo].[users] U ON T.acct_name = U.acct_name';
    -- 2. 把部門條件精準丟進 WHERE 車廂
    SET @SQL_Where += ' AND U.dept = @dept_name';
END

-- 條件 C：判斷排序方式，丟進 OrderBy 車廂
IF @sort_type = 1
    SET @SQL_OrderBy = ' ORDER BY T.ticket_date DESC';

-- ==========================================
-- 3. 🚀 最終大合體 (嚴格遵守 SQL 語法順序！)
-- ==========================================
DECLARE @FinalSQL NVARCHAR(MAX);

-- 按照絕對順序：Base -> Join -> Where -> OrderBy
SET @FinalSQL = @SQL_Base + @SQL_Join + @SQL_Where + @SQL_OrderBy;

-- 除錯檢查點：印出最終完美的語法
PRINT @FinalSQL;

-- 安全發射執行 (參數化防禦 SQL Injection)
EXEC sp_executesql 
    @stmt = @FinalSQL, 
    @params = N'@acct_name VARCHAR(10), @dept_name VARCHAR(20)', 
    @acct_name = @acct_name, 
    @dept_name = @dept_name;
```
## 🎯 總結：為什麼你必須採用這種寫法？
免疫順序 Bug：你寫 IF 判斷式的先後順序，再也不會影響最終 SQL 的語法正確性。

極高擴充性：如果未來系統要新增一個「依據訂單表過濾」的功能，你只需要在程式碼中間隨便找個空位加一段 `IF`，把 `JOIN` 和 `WHERE` 分別丟進對應的變數即可，完全不用擔心破壞原本的程式結構。

程式碼易讀：接手你程式碼的工程師，可以一眼看出哪裡在處理主語法、哪裡在處理關聯、哪裡在處理條件。