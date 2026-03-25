# 動態 SQL 架構設計：雙變數組裝法 (業界標準正解)
## 🎯 一、 核心痛點：為什麼需要動態 SQL？
當系統前台有多個「選填」的搜尋條件（例如：可以只搜姓名、可以只搜日期、也可以全都不填）時，如果把條件寫死在一般查詢的 `WHERE` 裡面，會導致 SQL Server 放棄使用索引（全表掃描），造成嚴重的效能災難。

**正解：使用動態 SQL (Dynamic SQL)。也就是「使用者有輸入什麼條件，程式才把那一段 SQL 文字拼湊上去」。**

## 🏆 二、 業界標準正解：雙變數組裝法
為了讓程式碼好維護、防禦駭客攻擊，且具備未來的擴充性，資深工程師會採用**「雙變數分工」**的架構。

【完美實戰範例碼】
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
## 🧠 三、 核心邏輯與語法深度解析
### 1. 為什麼要拆成「兩個變數」？ (架構設計的精髓)
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

## 🎯 四、 總結：為什麼這是正解？
這套**「雙變數 + 1=1 + sp_executesql」**的組合拳，達成了企業級資料庫開發的三大要求：

1.**效能最高**：避開了靜態 `OR` 判斷導致的全表掃描，能精準命中 Index。

2.**擴充性強**：要加 10 個新搜尋條件，只要無腦往下加 10 個 `IF` 即可，主結構完全不用改。

3.**極度安全**：完美阻擋 SQL Injection 攻擊。