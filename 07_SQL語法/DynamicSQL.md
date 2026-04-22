# 動態 SQL 架構設計

> 從「雙變數組裝法」到「模組化四變數拆分法」的完整進階路徑。

---

## 🎯 核心痛點：為什麼需要動態 SQL？

當系統前台有多個「選填」的搜尋條件（例如：可以只搜姓名、可以只搜日期、也可以全都不填）時，如果把條件寫死在一般查詢的 `WHERE` 裡面，會導致 SQL Server 放棄使用索引（全表掃描），造成嚴重的效能災難。

**正解：使用動態 SQL (Dynamic SQL)。也就是「使用者有輸入什麼條件，程式才把那一段 SQL 文字拼湊上去」。**

---

# 第一階段：雙變數組裝法（業界入門標準）

為了讓程式碼好維護、防禦駭客攻擊，且具備未來的擴充性，資深工程師會採用**「雙變數分工」**的架構。

## 🏆 完美實戰範例碼

```sql
-- 1. 宣告外部傳入的真實資料變數
DECLARE 
     @acct_name VARCHAR(10) = 'Ryan'
    ,@ticket_date DATETIME = '2026-03-20'

-- 2. 宣告動態組裝用的「雙變數」(必須是 NVARCHAR)
DECLARE 
     @SQL NVARCHAR(MAX) = ''             -- 負責裝「最終完整語法」的發射艙
    ,@SQL_condiction NVARCHAR(MAX) = ''  -- 負責裝「條件積木」的購物車

-- 3. 收集條件積木 (IF 判斷式)
IF @acct_name <> ''
    SET @SQL_condiction += ' AND acct_name = @acct_name'

IF @ticket_date <> ''
    SET @SQL_condiction += ' AND ticket_date = @ticket_date'

-- 4. 主語法與條件大合體
SET @SQL = '
SELECT [ticket_id]
      ,[acct_name]
      ,[ticket_date]
FROM [dbo].[ticket] WITH (NOLOCK)
WHERE 1 = 1' + @SQL_condiction

-- 5. 執行前的防呆檢查
PRINT @SQL

-- 6. 安全發射！(參數化查詢)
EXEC sp_executesql 
    @stmt = @SQL, 
    @params = N'@acct_name VARCHAR(10),@ticket_date DATETIME', 
    @acct_name = @acct_name, 
    @ticket_date = @ticket_date
```

## 🧠 核心邏輯與語法深度解析

### 1. 為什麼要拆成「兩個變數」？
- `@SQL_condiction` (條件購物車)：負責巡迴所有的 `IF` 判斷式。只要條件成立，就把對應的 `AND ...` 文字字串丟進車裡。它不包含 `SELECT` 等主語法。
- `@SQL` (最終發射艙)：負責把寫死的「主底盤 (`SELECT ...`)」跟剛才收集好的「購物車 (`@SQL_condiction`)」黏在一起。
- 優勢：如果未來系統需要增加 `ORDER BY` (排序)，你只需要加在最後面：`SET @SQL = 'SELECT...' + @SQL_condiction + ' ORDER BY ticket_date'`。雙變數設計完美避開了「語法順序卡死」的地雷。

### 2. 神來一筆的墊底句：WHERE 1 = 1
- 痛點：如果不寫 `1 = 1`，當使用者只輸入第二個條件時，語法會變成 `WHERE AND ticket_date...`，直接引發語法錯誤。
- 解法：`1 = 1` 是一個永遠成立的「火車頭」。有了它，後面的 @SQL_condiction 裡面的每一個條件都可以無腦用 `AND` 開頭（例如 `+ ' AND acct_name...'`），就像火車車廂一樣一節一節掛上去，絕對不會報錯。
- 效能：SQL Server 底層的最佳化引擎會自動忽略 `1 = 1`，絕對不會拖慢查詢速度。

### 3. 字串拼接符號：`+=` 與 `+`
- `SET @SQL_condiction += ' AND...'` 意思是把新的條件文字「附加」到原有的字串屁股後面。
- 這是動態 SQL 中把積木一塊一塊接起來的關鍵動作。

### 4. 終極防禦兵器：sp_executesql
動態 SQL 最怕的就是駭客在欄位輸入惡意指令 (SQL Injection)。這行指令是微軟官方唯一推薦的安全解法：
- `@stmt = @SQL`：先把「帶有 @ 代號的語法設計圖」交給 SQL Server。
- `@params = N'...'`：遞上名牌清單，宣告設計圖裡面的代號是什麼資料型態。
- 最後的參數 (`@acct_name = @acct_name...`)：把真正的資料交出去。因為語法跟資料是「分開傳遞」的，駭客輸入的惡意字串只會被當成純文字處理，無法被執行。

---

# 第二階段：模組化四變數拆分法（遇到 JOIN / 多段語法時的升級版）

## 🚨 雙變數法的極限：SQL 的「絕對語法順序」

在 SQL 的世界裡，執行語法有著不可跨越的嚴格順序：
👉 `SELECT` ➔ `FROM` ➔ `JOIN` ➔ `WHERE` ➔ `GROUP BY` ➔ `ORDER BY`

當我們在後端程式或預存程序 (SP) 中「動態拼接」字串時，使用者的輸入條件是隨機的（可能填了 A 條件，也可能填了 B 條件）。如果我們只用單一變數順著程式邏輯往下拼，極容易觸發「語法順序錯亂」的地獄。

### 💥 災難示範：只用單一變數 (`@SQL`) 拼到底

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

**🔥 最終產出的死亡語法：**
`SELECT * FROM ticket WHERE 1=1 AND acct_name = @acct_name INNER JOIN users...`
(SQL Server 報錯：無效的語法。因為 JOIN 絕對不能出現在 WHERE 之後！)

## 🛡️ 解法：模組化變數拆分（三 / 四變數流派）

為了解決這個順序危機，資深工程師會採用**「分類購物車（模組化）」**的概念。
我們不急著把字串組裝起來，而是依照 SQL 的語法結構，準備不同的變數（購物車）來分別收集對應的積木。直到最後一刻，才按照 SQL 規定的順序進行「大合體」。

### 🧱 變數分工定義

1. `@SQL_Base` (主底盤)：存放永遠不會變的基礎查詢 (`SELECT ... FROM ...`)。
2. `@SQL_Join` (關聯車廂)：專門收集所有的 `INNER JOIN` 或 `LEFT JOIN` 條件。一開始為空字串 ''。
3. `@SQL_Where` (過濾車廂)：專門收集查詢條件。起手式永遠是 `' WHERE 1=1 '`。
4. `@SQL_OrderBy` (排序車廂)：專門收集排序規則。起手式為空字串 `''`。

## ⌨️ 完美實戰範例碼（支援 JOIN 與多條件）

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

---

# 🎯 總結：兩種流派的選擇時機

| 流派 | 適用情境 | 優勢 |
|---|---|---|
| **雙變數法** | 只有 WHERE 條件會動態變動 | 結構最簡潔、學習成本低 |
| **四變數模組法** | 會動態加 JOIN / GROUP BY / ORDER BY | 免疫語法順序 Bug、擴充性高 |

**共同達成的三大要求：**
1. **效能最高**：避開了靜態 `OR` 判斷導致的全表掃描，能精準命中 Index。
2. **擴充性強**：主結構不用改，要加新條件只要再掛一個 `IF`。
3. **極度安全**：透過 `sp_executesql` 參數化查詢，完美阻擋 SQL Injection 攻擊。
