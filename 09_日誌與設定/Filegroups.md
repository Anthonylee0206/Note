# 檔案群組 (Filegroups)

## 1. 什麼是檔案群組？為什麼需要它？
定義：檔案群組是 SQL Server 中的邏輯容器。它像是一個標籤，用來管理底下的實體檔案（.mdf, .ndf）。

在 SQL Server 裡，資料庫不是只有一個單一檔案。當資料量變超大時，把所有雞蛋放在同一個籃子（同一個實體硬碟）會讓讀寫效能（I/O）變得很差。

**檔案群組 (Filegroup)** 就像是「邏輯資料夾」的概念。我們可以把不同的資料表或索引，分門別類放在不同的實體硬碟上，藉此分散硬碟的讀寫壓力，提升整體速度。

* **Primary (主要檔案群組)：** 每個資料庫預設一定會有，包含系統物件和主要資料檔 (`.mdf`)。
* **Secondary (次要檔案群組)：** 我們自己手動建立的，用來存放使用者資料或特定大表 (`.ndf`)。
* ⚠️ **超級大陷阱：** 交易記錄檔 (`.ldf`) 是獨立運作的，**它不屬於任何檔案群組**！

**為什麼要用？**
*   **冷熱分離**：頻繁存取的「熱資料」放 SSD 群組；少用的「歷史冷資料」放 HDD 群組。
*   **管理彈性**：硬碟快滿時，可以加掛新檔案到新硬碟，再把表搬過去。

**刪除規則**：若要刪除群組，該群組內必須是「空屋」狀態，不能有任何資料表或索引。

---

## 2. 工位觀察重點

下次看前輩建置資料庫或設定檔案群組時，不要只看語法，記得重點觀察（或偷偷記下）他們的**硬碟分配策略**：

* [ ] **實體硬碟怎麼分？** 前輩是不是把 `.mdf` 放 C 槽，把 `.ndf` 放 D 槽或高速 SSD，然後把 `.ldf` (Log) 獨立放在 E 槽？*(這是標準的效能優化起手式，因為 Log 檔的寫入方式跟資料檔不同)*
* [ ] **預設群組設定：** 前輩建好新的 Secondary 群組後，有沒有下指令把它設為 `DEFAULT`？*(如果有，代表以後新建的資料表，都會自動跑到這個新硬碟去，而不會塞爆 Primary)*
* [ ] **冷熱資料分離：** 觀察前輩是不是把「歷史紀錄 (幾百萬筆的舊資料)」跟「當下交易 (每天在變動的新資料)」分開放在不同的檔案群組？
* [ ] **資料與索引分離：** 有些極致的作法，會把「資料表」放一個群組，「索引 (Index)」放另一個群組，藉此加快查詢速度。

---

## 3. 核心語法範例

### A. 建立資料庫時，直接分好檔案群組
這通常是用在全新專案，一開始就規劃好架構。

```sql
-- 建立資料庫，並同時定義好檔案與群組
CREATE DATABASE [MyTestDB]
ON PRIMARY 
(
    NAME = N'MyTestDB_Primary', 
    FILENAME = N'C:\SQLData\MyTestDB.mdf',  -- 系統主檔放 C 槽
    SIZE = 100MB, 
    FILEGROWTH = 10%
),
-- 建立我們專屬的次要檔案群組 (例如專門放歷史資料)
FILEGROUP [History_FG] 
(
    NAME = N'MyTestDB_History1', 
    FILENAME = N'D:\SQLData\MyTestDB_History1.ndf', -- 歷史資料放 D 槽
    SIZE = 500MB, 
    FILEGROWTH = 50MB
)
-- Log 檔獨立設定，注意它沒有包在 FILEGROUP 裡面！
LOG ON 
(
    NAME = N'MyTestDB_Log', 
    FILENAME = N'E:\SQLLog\MyTestDB_log.ldf', -- Log 檔放 E 槽
    SIZE = 100MB, 
    FILEGROWTH = 10%
);
```
### B. 事後幫現有資料庫擴充檔案群組
如果資料庫在運作，但發現 D 槽快滿了，需要加裝硬碟 (F 槽) 並擴充群組：
```sql
-- 1. 先生出一個新的「籃子」(邏輯檔案群組)
ALTER DATABASE [MyTestDB] ADD FILEGROUP [NewData_FG];

-- 2. 把實體檔案放在新硬碟，並歸入剛剛建好的籃子裡
ALTER DATABASE [MyTestDB] ADD FILE 
(
    NAME = N'MyTestDB_NewData1',
    FILENAME = N'F:\SQLData\MyTestDB_NewData1.ndf', -- 指向新的實體路徑
    SIZE = 1GB,
    FILEGROWTH = 100MB
) TO FILEGROUP [NewData_FG];

-- 3. (選擇性) 把這個新籃子設為預設值
ALTER DATABASE [MyTestDB] MODIFY FILEGROUP [NewData_FG] DEFAULT;
```
### c.重建叢集索引 (Move Table)
這是改變資料表實體位置最標準的做法：
```sql
USE [master]; -- 站在資料庫外面執行
-- 1. 移除實體檔案
ALTER DATABASE [資料庫名] REMOVE FILE [邏輯檔名];
-- 2. 移除邏輯群組
ALTER DATABASE [資料庫名] REMOVE FILEGROUP [群組名];
```
## 4.範例 (Examples)

**主題：歷史訂單表撤離與二館拆除實戰**

**【場景】**
將資料表 `HistoryCryptoOrders` 從二館 `HistoryData` 撤回大本營 `PRIMARY`，並夷平二館。

**【踩坑排除紀錄】**

1. **SSMS UI 鎖定**：若「儲存體」選單反灰不讓改，代表主鍵被鎖定。
    - **解法**：至「工具 > 選項 > 設計師 (設計師)」取消勾選「防止儲存需要資料表重建的變更」。
2. **索引改名術**：系統自動生成的長名稱主鍵（如 `PK__HistoryC__...`）很難在語法中使用。
    - **解法**：在 UI 對索引按右鍵「重新命名」為短名字（如 `PK_History`）後，再跑搬家語法。
3. **清空驗證**：在下達 `REMOVE` 指令前，必須確認群組已空。

```sql
-- 檢查群組內是否還有房客
SELECT t.name FROM sys.indexes i 
JOIN sys.tables t ON i.object_id = t.object_id
JOIN sys.filegroups f ON i.data_space_id = f.data_space_id
WHERE f.name = 'HistoryData';
```

4. **物理清理**：若執行 `REMOVE` 後硬碟上的 `.ndf` 還在，可於確認資料庫已解除連結後，手動於 Windows 資料夾中刪除。