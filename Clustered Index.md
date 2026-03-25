# 索引 (IDX) 與叢集 / 非叢集架構

---

## 觀念 (Concepts)

**1. 索引 (IDX) 的核心功用**

- **加速查詢 (Read)**：就像書本最後面的「索引頁」或「目錄」，當你要找特定資料時，不用從第一頁翻到最後一頁（這在 SQL 叫全表掃描 Table Scan），而是直接看索引頁找到對應的頁碼，瞬間跳過去。
- **拖慢寫入 (Write)**：天下沒有白吃的午餐！雖然查詢變快了，但每次你執行 `INSERT`、`UPDATE`、`DELETE` 時，系統不僅要改資料，還要**同步更新索引**。所以索引建太多，寫入效能就會崩潰。

**2. 叢集索引 (Clustered Index) ➔ 「實體本尊」**

- **定義**：資料表中的資料列會**依照這個索引的順序，在硬碟上進行實體的物理排序與儲存**。
- **比喻**：就像一本**「英文字典」**。整本字典就是照著 A 到 Z 的順序印出來的，字彙本身就包含了排序。
- **數量限制**：因為資料只能有一種物理排序方式，所以**一張表只能有 1 個叢集索引**。（通常系統會預設把「主鍵 Primary Key」當作叢集索引）。

**3. 非叢集索引 (Non-Clustered Index) ➔ 「路標與分身」**

- **定義**：它是一個與實體資料**獨立分開儲存的結構**。裡面只存了「你建立索引的那個欄位」加上一個「指標（指向實體資料的記憶體位置）」。
- **比喻**：就像一本**「教科書背後的關鍵字索引頁」**。書本的內文是按章節排的（叢集），但你想找「演算法」這個詞，可以去翻背後的索引，它會告訴你在第 45 頁、第 112 頁，你再翻過去找。
- **數量限制**：一張表可以有**多個**非叢集索引（在 SQL Server 裡最多可以建 999 個，但實務上通常只建幾個最常用的）。

---

## 基本語法 (Basic Syntax)

**1. 建立叢集索引 (Clustered Index)**
```sql
-- 語法：CREATE CLUSTERED INDEX [索引名稱] ON [表名]([欄位名]);
-- 備註：如果表上已經有主鍵(PK)，通常就已經佔用掉叢集索引的名額了。
CREATE CLUSTERED INDEX IDX_Clustered_OrderID 
ON [dbo].[Orders]([OrderID]);
```
**2. 建立非叢集索引 (Non-Clustered Index)**
```sql
-- 語法：CREATE NONCLUSTERED INDEX [索引名稱] ON [表名]([欄位名]);
-- 常用於經常被放在 WHERE 條件後面，或是用來 JOIN 的欄位
CREATE NONCLUSTERED INDEX IDX_NonClustered_Symbol 
ON [dbo].[Orders]([CryptoSymbol]);
```
**3. 建立包含多個欄位的複合索引**
```sql
-- 把最常一起查詢的條件包在同一個索引裡
CREATE NONCLUSTERED INDEX IDX_Symbol_Date 
ON [dbo].[Orders]([CryptoSymbol] ASC, [TradeDate] DESC);
```
**4. 刪除索引**
```sql
DROP INDEX [IDX_NonClustered_Symbol] ON [dbo].[Orders];
```
## 範例 (Examples)

**【案例場景：量化交易訂單表的效能調校】**
假設我們有一張有 5,000 萬筆紀錄的交易表 `CryptoTrades`。

- **欄位**：`TradeID` (交易序號), `Symbol` (幣種, 例如 BTC, ETH), `Price` (價格), `TradeDate` (交易時間)。

**【實戰策略與 QA 心得】**

1. **決定叢集索引 (唯一的老大)**
    - **選擇**：我們將 `TradeID` 設為主鍵 (Primary Key)，系統自動將它變為**叢集索引**。
    - **結果**：整張表的 5,000 萬筆資料，在硬碟上會嚴格按照 `TradeID` 由小到大連續存放。當我們查詢 `WHERE TradeID = 10005` 時，速度會是閃電般的毫秒級。
2. **遇到效能瓶頸 (需要非叢集索引救援)**
    - **問題**：系統經常需要跑報表，查詢「特定幣種」的紀錄：`SELECT * FROM CryptoTrades WHERE Symbol = 'BTC'`。
    - **現象**：因為資料是按 `TradeID` 排列的，SQL Server 找不到 `Symbol` 的規律，只好把 5,000 萬筆資料全部掃描一次（Table Scan），導致查詢超級慢。
    - **解法**：針對 `Symbol` 建立**非叢集索引**。
```sql
CREATE NONCLUSTERED INDEX IDX_Symbol ON CryptoTrades(Symbol);
```
- **原理**：SQL Server 會在旁邊另外建一本「小冊子」，裡面按字母順序排滿了 BTC、ETH，並附上每一筆對應的 `TradeID`。以後查詢 BTC，SQL 就會先翻小冊子（極快），再根據上面的指標去拿完整資料（這動作叫做 Key Lookup）。
3. **防呆避坑指南 (QA 必查項目)**
    - **不要對每個欄位都建索引**：如果對 `Price`、`TradeDate` 等每個欄位都建非叢集索引，每次新增一筆訂單，SQL 就要同時去更新好幾本「小冊子」，寫入效能會嚴重卡死（Deadlock 風險大增）。
    - **低辨識度的欄位別建**：例如「訂單狀態（成功 / 失敗）」，只有兩種值。建索引的意義不大，系統通常會覺得直接全表掃描還比較快。