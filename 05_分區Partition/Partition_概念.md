# 資料表分割 (Table Partitioning) 與監控維護
----


### 📝 觀念 (Concepts)

- **什麼是資料表分割？**
當資料表（如交易紀錄 `ticket_all`）大到擁有數億筆資料時，查詢與維護會極度緩慢。資料表分割就是把這張「大表」按特定規則（通常是「日期」）水平切成多塊「小表」（分割區），但對外部應用程式來說，它看起來依然是一張完整的表。
- **分割三大核心元件：**
    1. **Partition Function (分割函數)**：定義**「怎麼切」**（例如：以每個月為邊界切分）。
    2. **Partition Scheme (分割配置)**：定義**「放哪裡」**（將切好的每一塊，指派到特定的 Filegroup 檔案群組中）。
    3. **Partition Column (分割欄位)**：作為切分依據的欄位（例如：`TradeDate`）。
- **核心優勢 (Sliding Window 滑動視窗)**：
    - **查詢極速**：SQL 只會去掃描符合條件的那一個分割區（Partition Elimination），忽略其他無關區塊。
    - **維護無感**：可以針對單一舊分割區瞬間清空（`TRUNCATE`）或搬離（`SWITCH`），完全不會鎖死整張表或產生大量 Transaction Log。

---

### ⌨️ 基本語法 (Basic Syntax：系統視圖與動態管理)

要監控分割表的健康狀態，必須聯合查詢多張系統表 (DMV)。你提供的腳本正是這方面的神兵利器。

**1. 關鍵系統表解析：**

- `sys.dm_db_partition_stats`：查詢每個分割區目前有幾筆資料 (`row_count`)。
- `sys.partition_functions` & `sys.partition_schemes`：查詢分割的規則與配置方式。
- `sys.filegroups`：查詢該分割區實際存放的硬碟位置（檔案群組）。
- `sys.partition_range_values`：查詢該分割區的上下限值 (`LowerBoundary`, `UpperBoundary`)。

**2. DBA 日常維護的動態語法 (腳本中被註解的部分)：**

- **`SWITCH PARTITION`**：將該區塊的資料「秒轉移」到另一張歷史表。
- **`MERGE RANGE`**：將兩個相鄰的分割區合併成一個。
- **`SPLIT RANGE`**：在邊界外切出一個新的空分割區，準備接收未來的新資料。
- **`TRUNCATE TABLE ... WITH (PARTITIONS (n))`**：秒殺清空第 n 號分割區的所有資料。

---

### 📝 範例 (Examples)

**主題：量化交易資料庫的日常監控與舊資料淘汰**

**【案例場景】**
資料庫內有一張 `ticket_all` 存放逐筆交易紀錄。為了節省空間，系統規定只保留最近一段時間的資料，過舊的資料必須每個月定期清理，並為下個月預先開好儲存空間。

**【實戰操作 (搭配監控腳本)】**

1. **日常健康檢查 (執行你的腳本主體)**
    - 執行腳本後，會印出一張總表，顯示 TableName、分割區編號 (PartitionNumber)、邊界日期、所在的 FileGroupName，以及最重要的**資料筆數 (`row_count`)**。
    - 藉此檢查每個月的資料量是否異常，以及最新的分割區是否快滿了。
2. **擴建未來空間 (使用 `SPLIT`)**
到了月底，需要準備下個月的空間。將腳本中 `split_str` 的註解拿掉，利用印出來的動態語法建立新空間：
```sql
ALTER PARTITION SCHEME [Psh_tck] NEXT USED [FG_LOG_NextMonth]; 
ALTER PARTITION FUNCTION [Pf_tck]() SPLIT RANGE ('2026-04-01');
```
3. **瞬間秒殺舊資料 (使用 TRUNCATE)**
透過腳本查出最舊資料位在 PartitionNumber 2，將 truncate_str 註解拿掉並執行產出的語法：
```sql
TRUNCATE TABLE ticket_all WITH (PARTITIONS (2));
```
- QA 心得：傳統使用 `DELETE FROM ticket_all WHERE date < '...'` 會跑非常久且塞爆硬碟日誌。使用 Partition Truncate 是直接釋放資料頁，千萬筆資料也是一秒內清空，是 DBA 處理巨量資料的必備絕招。
## 從零打造資料表分割 (Table Partitioning 實戰建置)
---

### 📝 觀念 (Concepts：系統櫃木工裝潢指南)

當我們面對一張全新的大表，要把它打造成「分割表（系統櫃）」時，必須嚴格遵守以下四個施工步驟：

1. **定規矩 (Partition Function)**：做抽屜的標籤。規定資料要按照什麼條件切開。*(例如：每個月切一格)*。
2. **配房間 (Partition Scheme)**：分配這些抽屜要放在哪個實體硬碟（檔案群組 Filegroup）裡。
3. **把表塞進櫃子 (Clustered Index)**：資料表預設是個大紙箱。我們必須透過建立「叢集索引（實體排序）」，強制這張表按照剛才的「配置圖（Scheme）」住進系統櫃裡。
    - ⚠️ **鐵規則**：你要當作分割依據的欄位（例如：`ticket_data`），**必須**包在主鍵（Primary Key）裡面！
4. **建立隨身小冊子 (Aligned Index)**：為這張表建立非叢集索引時，也要記得加上 `ON [配置圖]`，讓小冊子也跟著主表一起分割。這樣以後你一秒丟棄舊抽屜（TRUNCATE）時，才不會被小冊子卡住。
### ⌨️ 基本語法 (Basic Syntax：建置腳本與白話註解)

以下是你提供的腳本，我加上了白話文與生活比喻的註解：
```sql
-- ==========================================
-- 步驟 1：定規矩 (Partition Function) - 製作抽屜標籤
-- ==========================================
-- [白話文] 建立一個叫 Pfn_datetime 的規則，看 DATETIME 來分類。
-- RANGE RIGHT 的意思是：遇到剛好是 1月1號 00:00:00 的資料，要向「右」放（放進新月份的抽屜）。
-- 這裡設了 3 個邊界（刀口），所以總共會切出 4 個抽屜。
CREATE PARTITION FUNCTION [Pfn_datetime](DATETIME) AS 
RANGE RIGHT FOR VALUES (
    N'2026-01-01T00:00:00.000', 
    N'2026-02-01T00:00:00.000', 
    N'2026-03-01T00:00:00.000'
)
GO

-- ==========================================
-- 步驟 2：配房間 (Partition Scheme) - 搬家工人配置圖
-- ==========================================
-- [白話文] 建立一個叫 Psh_datetime 的配置圖，照著上面的規則切。
-- 寫法 1.1：全部 4 個抽屜都放在 [PRIMARY] 大本營群組裡。
-- (實務上如果硬碟夠多，這裡會寫 TO ([FG_202512], [FG_202601], [FG_202602], [FG_202603]))
CREATE PARTITION SCHEME [Psh_datetime] AS PARTITION [Pfn_datetime] 
ALL TO ([PRIMARY])
GO

-- ==========================================
-- 步驟 3：建立資料表並搬入系統櫃
-- ==========================================
-- [白話文] 先建一個普通的大紙箱 (放在 PRIMARY)
CREATE TABLE ticket
(
	ticket_id INT NOT NULL,
	acct_name VARCHAR(10) NOT NULL,
	ticket_data DATETIME NOT NULL
) ON [PRIMARY] 
GO

-- [白話文] 🌟大魔術：建立叢集主鍵，並強制它「照著 Psh_datetime 配置圖」住進系統櫃！
-- 注意：主鍵必須包含切割欄位 (ticket_data)，否則 SQL 會報錯不給建。
ALTER TABLE [dbo].[ticket] ADD CONSTRAINT [PK_ticket] PRIMARY KEY CLUSTERED 
(
	ticket_id ASC,
	ticket_data
) ON [Psh_datetime](ticket_data)
GO

-- ==========================================
-- 步驟 4：建立「對齊的」非叢集索引 (Aligned Index)
-- ==========================================
-- [白話文] 建一本加速查詢的小冊子。
-- 尾巴的 ON [Psh_datetime]([ticket_data]) 非常重要！
-- 這樣小冊子也會跟著主表一起被切成 4 個抽屜，以後維護才能順利。
CREATE NONCLUSTERED INDEX [IDX_ticket_date] ON [dbo].[ticket]
(
	[ticket_data] ASC
)
INCLUDE([ticket_id],[acct_name]) 
WITH (SORT_IN_TEMPDB = ON) ON [Psh_datetime]([ticket_data])
GO
```
### 📝 範例 (Examples)

**【案例場景：測試資料會掉進哪個抽屜？】**

你剛才在腳本裡寫了 `INSERT` 語句，我們來模擬一下這些資料被 SQL Server 派發到哪裡去了：

- **抽屜 1號 (比 2026-01-01 還舊的)**
    - `INSERT INTO ticket VALUES (1,'Tony','2025-12-01')` ➔ 📦 掉進 **1號** 抽屜。
- **抽屜 2號 (2026-01-01 到 2026-01-31)**
    - `INSERT INTO ticket VALUES (2,'Kent','2026-01-15')` ➔ 📦 掉進 **2號** 抽屜。
    - `INSERT INTO ticket VALUES (3,'Gino','2026-01-16')` ➔ 📦 掉進 **2號** 抽屜。
- **抽屜 3號 (2026-02-01 到 2026-02-28)**
    - `INSERT INTO ticket VALUES (4,'Ryan','2026-02-05')` ➔ 📦 掉進 **3號** 抽屜。
- **抽屜 4號 (大於等於 2026-03-01 的)**
    - `INSERT INTO ticket VALUES (1,'Tony','2026-03-01')` ➔ 📦 掉進 **4號** 抽屜。*(因為我們設了 RANGE RIGHT)*
    - `INSERT INTO ticket VALUES (5,'Kevin','2026-03-03')` ➔ 📦 掉進 **4號** 抽屜。

**【QA 驗收測試】**
你建完這張表並塞入資料後，如果去執行你上一篇給我的那段「監控腳本」，你就會清楚看到 `ticket` 這張表出現了 4 列（4 個 Partition），而且 `row_count` 會完美對應我們上面推算的：1筆、2筆、1筆、2筆！
## 分割表秒轉移術 (SWITCH PARTITION)
---
### 📝 觀念 (Concepts：抽屜整格搬家法)

- **什麼是 SWITCH PARTITION？**
這是一個「修改產權（Metadata）」的動作。SQL Server 不會真的去搬動硬碟上的幾百萬筆資料，它只是改一下系統紀錄，宣告：「原本屬於 `ticket` 表第 1 號抽屜的資料，現在改歸 `ticket_history` 表管了」。
- **極速效能**：無論是 10 筆還是 1 億筆資料，SWITCH 都會在 **1 秒內** 完成，且幾乎不產生 Transaction Log（不會卡死系統）。
- **⚠️ 轉移的「鐵規則」(必須 100% 吻合)**：
    1. **實體位置相同**：接收資料的「歷史表」，必須跟你抽屜所在的「檔案群組 (Filegroup)」一模一樣。（例如我們的抽屜在 `PRIMARY`，歷史表也必須蓋在 `PRIMARY`）。
    2. **結構一模一樣**：欄位名稱、型別、順序、Null 屬性必須完全相同。
    3. **索引一模一樣**：主表有什麼叢集/非叢集索引，歷史表就必須有長得一模一樣的索引。
    4. **接收端必須是空的**：歷史表（或者歷史表的那個接收抽屜）裡面不能有任何資料。

---

### ⌨️ 基本語法 (Basic Syntax)

**把某個抽屜的資料，切換到一張「沒有分割的普通空表」裡：**
```sql
-- 語法：ALTER TABLE [來源大表] SWITCH PARTITION [抽屜編號] TO [接收用的歷史空表];
ALTER TABLE [dbo].[ticket] SWITCH PARTITION 1 TO [dbo].[ticket_history];
```
### 📝 範例 (Examples)

**【案例場景：把 2025 年的舊資料封箱備份】**
我們剛才建好的 `ticket` 表裡，第 1 號抽屜裝著 2026 年以前的資料（裡面有 1 筆 Tony 的 2025-12-01 發票）。現在我們要把它秒移到 `ticket_history` 表。

**【實戰操作 3 步驟】**

**步驟一：請木工打造一個「長得一模一樣」的歷史空紙箱**
（這段語法我已經幫你把結構對齊了，請直接在 `TestDB` 執行）
```sql
USE [TestDB];
GO

-- 1. 建立結構完全相同的空表 (建在 PRIMARY 群組)
CREATE TABLE [dbo].[ticket_history](
	[ticket_id] INT NOT NULL,
	[acct_name] VARCHAR(10) NOT NULL,
	[ticket_data] DATETIME NOT NULL
) ON [PRIMARY]; 
GO

-- 2. 建立一模一樣的叢集主鍵
ALTER TABLE [dbo].[ticket_history] ADD CONSTRAINT [PK_ticket_history] PRIMARY KEY CLUSTERED 
(
	[ticket_id] ASC,
	[ticket_data]
) ON [PRIMARY];
GO

-- 3. 建立一模一樣的非叢集索引 (小冊子)
CREATE NONCLUSTERED INDEX [IDX_ticket_history_date] ON [dbo].[ticket_history]
(
	[ticket_data] ASC
)
INCLUDE([ticket_id],[acct_name]) ON [PRIMARY];
GO
```
步驟二：見證奇蹟！執行 SWITCH 瞬間轉移
```sql
-- 把 ticket 表的第 1 號抽屜，整格塞進 ticket_history 裡
ALTER TABLE [dbo].[ticket] SWITCH PARTITION 1 TO [dbo].[ticket_history];
GO
```
步驟三：QA 驗收成果
執行下面這兩行，看看資料是不是瞬間跑到另一張表了！
```sql
-- 1. 檢查歷史表 (應該會出現 Tony 2025-12-01 的那一筆)
SELECT * FROM [dbo].[ticket_history];

-- 2. 檢查主表 (Tony 那筆已經不見了，只剩下 2026 年的 5 筆)
SELECT * FROM [dbo].[ticket];
```
## 資料秒殺術 (TRUNCATE TABLE)
### 📝 觀念 (Concepts：碎紙機 vs 垃圾車)

- **DELETE (碎紙機)**：
    - **運作方式**：一筆一筆刪除。SQL Server 會把每一筆刪除的動作都詳細記錄在「交易日誌 (Transaction Log)」裡，以防你想反悔 (Rollback)。
    - **缺點**：如果有一千萬筆資料，它就要寫一千萬筆日誌。速度極慢，且會把硬碟空間瞬間塞爆。
    - **比喻**：把抽屜裡的過期發票拿出來，**一張一張放進碎紙機**。
- **TRUNCATE (垃圾車直接載走)**：
    - **運作方式**：直接「釋放資料頁 (Data Pages)」。它不管裡面有幾筆資料，直接把底層的儲存空間標記為「空」。它只在日誌裡記錄「我釋放了這些空間」，而不記錄每一筆資料。
    - **優點**：速度極快（通常不到 1 秒），幾乎不佔用日誌空間。
    - **比喻**：把整個抽屜拉出來，**整箱直接倒進垃圾車**，然後把空抽屜放回去。
- **⚠️ TRUNCATE 的鐵規則與限制**：
    1. **無法反悔**：一旦執行，資料瞬間灰飛煙滅（除非你有完整備份），請小心使用！
    2. **不能加 WHERE**：`TRUNCATE` 只能清空「整張表」或是「整格分割抽屜」，不能像 `DELETE` 那樣指定「只刪除 Tony 的資料」。
    3. **重置跳號 (Identity)**：如果你的表有自動遞增的流水號，`TRUNCATE` 會把它歸零重新開始算；`DELETE` 則會繼續往下跳號。

---

### ⌨️ 基本語法 (Basic Syntax)

**1. 清空整張大表 (傳統用法)**
```sql
-- 瞬間清空整張紙箱裡的所有東西
TRUNCATE TABLE [dbo].[資料表名稱];
```
**2. 清空特定的分割抽屜**

搭配我們剛學的分割表，你可以只清空某一個特定的抽屜，而不影響其他抽屜的熱資料！
```sql
-- 只清空第 1 號抽屜 (把過期的歷史資料秒殺)
TRUNCATE TABLE [dbo].[資料表名稱] WITH (PARTITIONS (1));

-- 一次清空多個抽屜 (例如第 1 到第 3 號)
TRUNCATE TABLE [dbo].[資料表名稱] WITH (PARTITIONS (1 TO 3));
```
### 📝 範例 (Examples)

**【案例場景：徹底銷毀 2025 年的歷史備份】**

延續我們上一個進度：你剛才已經用 `SWITCH` 把 2025 年的那筆舊資料，成功轉移到了 `ticket_history` 這張歷史表裡面。現在，老闆說這筆資料已經完全不需要了，請把它從硬碟上徹底抹除。

**【實戰操作】**

請在你的 `TestDB` 執行以下語法：
```sql
USE [TestDB];
GO

-- 1. 執行秒殺大絕招！清空這張歷史表
TRUNCATE TABLE [dbo].[ticket_history];
GO

-- 2. QA 驗收：看看裡面還有沒有東西？
SELECT * FROM [dbo].[ticket_history];
GO
```
如果當初我們沒有用`*SWITCH*`轉移到歷史表，而是直接針對主表`*ticket*`的第 1 號抽屜動手，語法就會長這樣：

*(註：你現在的 `ticket` 第 1 號抽屜已經是空的了，所以這段只是觀念展示)*
```sql
TRUNCATE TABLE [dbo].[ticket] WITH (PARTITIONS (1));
```
## 合併分割區 (MERGE RANGE)
### 📝 觀念 (Concepts：拆除抽屜隔板)

- **什麼是 MERGE RANGE？**
    - 在分割表的世界裡，你不是去合併「資料表」，而是去修改「木工的裁切規則 (Partition Function)」。
    - 它的本質是：**「拆除掉某一個邊界值（刀口）」**。
- **運作原理（打通抽屜）**：
    - 假設你原本有 [1月]、[2月] 兩個抽屜，中間有一個隔板叫「2月1日」。當你宣告要把「2月1日」這個隔板拆掉 (`MERGE`) 時，1月和2月的抽屜就會瞬間打通，變成一個超大的 [1月-2月] 抽屜。
- **最佳實務 (DBA 鐵規則)**：
    - ⚠️ **盡量只合併「空的」抽屜**：如果隔板兩邊的抽屜裡裝滿了幾千萬筆資料，當你拆除隔板時，SQL Server 會需要在底層重新搬動這些龐大的資料來合併，這會產生超巨大的 Transaction Log 並嚴重拖慢效能。
    - 因此，標準動作永遠是：**先 TRUNCATE (清空舊抽屜) ➔ 再 MERGE (拆除空抽屜的隔板)**。

---

### ⌨️ 基本語法 (Basic Syntax)
```sql
-- 語法：修改「分割函數」，並指定要拆除哪一個「邊界值」
ALTER PARTITION FUNCTION [你的分割函數名稱]() 
MERGE RANGE ('你要拆除的那個時間點/邊界值');
```
注意：函數名稱後面的括號 () 是一定要加的喔！
### 📝 範例 (Examples)

**【案例場景：拆除 2026 年 2 月的隔板】** 

回顧我們當初建置 `Pfn_datetime` 這個規則時，我們下了三刀（三個邊界）：

1. `2026-01-01`
2. `2026-02-01`
3. `2026-03-01`
這切出了 4 個抽屜。現在，我們要把中間那個 `2026-02-01` 的隔板拆掉，讓抽屜數量從 4 個變成 3 個。

**【實戰操作】**

請在你的 `TestDB` 執行以下這行大絕招：
```sql
USE [TestDB];
GO

-- 拆除 '2026-02-01' 這個邊界值 (隔板)(一次只能拆一個隔板)
ALTER PARTITION FUNCTION [Pfn_datetime]() 
MERGE RANGE (N'2026-02-01T00:00:00.000');
GO
```
**【QA 驗收挑戰】**
執行完上面這行之後，請你去跑一次我們之前寫的那段**「抽屜檢查儀表板」**！

1. 你的抽屜總數從 4 個變成了 **3 個**！
2. 原本的 `2026-02-01` 這個邊界值從報表上消失了。
3. 原本住在這兩格抽屜裡的資料（如果有殘留的話），現在會全部被擠進同一個新的大抽屜裡，`RowCount` 會自動加總！
## 擴建分割區 (SPLIT RANGE)

### 📝 觀念 (Concepts：釘上新的隔板)

- **什麼是 SPLIT RANGE？**
    - 它的動作跟 MERGE 剛好相反：**「在現有的系統櫃裡，釘上一個新的邊界值（刀口）」**。
    - 當你切下一刀，原本的某一個抽屜就會被「一分為二」，變成兩個抽屜。
- **⚠️ SPLIT 的「雙重核准」鐵規則 (極度重要！)**：
    - SQL Server 有一個很嚴格的防呆機制：在你要切出新抽屜之前，你必須先告訴「搬家工人 (Partition Scheme)」，**這個新抽屜要放在哪一顆實體硬碟 (Filegroup) 上？**
    - 所以，SPLIT 永遠是 **「兩階段動作」**：
        1. 先宣告下一個使用的群組：`NEXT USED`
        2. 再執行切割動作：`SPLIT RANGE`
- **最佳實務 (DBA 效能守則)**：
    - ⚠️ **絕對不要去切「裝滿資料」的抽屜！** 如果你在一堆舊資料中間硬切一刀，SQL Server 會被迫把幾千萬筆資料拿出來重新分類搬家，整個資料庫會瞬間卡死。
    - **正確姿勢**：永遠只在最右邊（或最左邊）那個**「用來裝未來資料的空抽屜」**進行 SPLIT。先切好空房間，等未來的資料自己乖乖掉進去。

---

### ⌨️ 基本語法 (Basic Syntax)
```sql
-- 步驟一：先跟配置圖 (Scheme) 預告，新切出來的空間要放在哪個硬碟群組
ALTER PARTITION SCHEME [你的配置圖名稱] 
NEXT USED [你的檔案群組名稱]; -- (例如 [PRIMARY] 或是 [FG_202604])

-- 步驟二：修改規則 (Function)，正式釘上新隔板
ALTER PARTITION FUNCTION [你的分割函數名稱]() 
SPLIT RANGE ('未來的新時間點/邊界值');
```
### 📝 範例 (Examples)

**【案例場景：迎接 2026 年 4 月的新報價資料】**

回顧一下，我們目前的 `Pfn_datetime` 函數裡，最後一個刀口是 `2026-03-01`。
也就是說，3月份、4月份、5月份的資料，目前都會全部擠在最後一個抽屜裡。
現在到了月底，DBA 要預先幫 4 月份切出一個獨立的空間。

**【實戰操作】**

請在你的 `TestDB` 執行這兩行終極指令：
```sql
USE [TestDB];
GO

-- 1. 先宣告：等一下切出來的新抽屜，請繼續放在 [PRIMARY] 大本營裡
ALTER PARTITION SCHEME [Psh_datetime] 
NEXT USED [PRIMARY];
GO

-- 2. 正式切刀：在 2026-04-01 釘上新隔板！
ALTER PARTITION FUNCTION [Pfn_datetime]() 
SPLIT RANGE (N'2026-04-01T00:00:00.000');
GO
```
**【QA 驗收挑戰】**
執行完上面這兩段語法後，**請你再跑一次那段「抽屜檢查儀表板」腳本！**

你會發現令人驚豔的變化：

1. 你的系統櫃抽屜總數，又多了一個！
2. 報表上會出現一個全新的邊界值 `2026-04-01`。
3. 如果你現在 INSERT 一筆 4 月中旬的資料，它就會精準地掉進這個你剛開好的新抽屜裡！

## 【SQL 進階架構】中繼表 (Staging Table) 封存實戰

### 📝 觀念 (Concepts：無痛搬家三部曲)

- **情境**：主表在極速硬碟（或特定月份的 Filegroup），歷史庫在便宜慢速硬碟（或另一台伺服器）。
- **核心挑戰**：不能直接 `SWITCH`（硬碟不同），直接 `INSERT` 幾千萬筆又會鎖死（Lock）主表，導致當下寫入的報價或交易資料進不來。
- **解法：暫存紙箱 (Staging Table)**
    1. **借用場地**：在「主表要清空的那個抽屜」的**同一個實體硬碟**上，放一個一模一樣的空紙箱（中繼表）。
    2. **秒切 (SWITCH)**：一秒鐘把舊抽屜的資料倒進空紙箱。此時主表瞬間解脫，繼續去接新的報價資料。
    3. **慢搬 (INSERT)**：我們在背景慢慢把紙箱裡的資料，跨硬碟倒進歷史資料庫。就算搬了半小時也無所謂，因為沒有人會去查這個紙箱。
    4. **銷毀 (TRUNCATE)**：搬完後，一秒銷毀紙箱裡的內容，把極速硬碟的空間退還給系統。

### ⌨️ 基本語法與實戰腳本 (Basic Syntax)

為了讓你在 `TestDB` 裡面可以直接演練，我們假設：

- **主表**：`QuantMarketData` (剛才建好的分割表，放在 `PRIMARY`)
- **中繼表**：`QuantMarketData_Staging` (必須建在跟主表同一個群組，也就是 `PRIMARY`)
- **遠端歷史表**：`HistoryDB_QuantData` (模擬遠端的歷史庫，這裡我們建一張普通表來假裝)

**【前置作業：請木工準備中繼表與歷史表】**

*(請在 TestDB 執行以下腳本，建立一模一樣的結構)*
```sql
USE [TestDB];
GO

-- ==========================================
-- 1. 建立中繼表 (Staging Table) - 必須在 PRIMARY
-- ==========================================
CREATE TABLE [dbo].[QuantMarketData_Staging] (
	[StrategyID] INT NOT NULL,
	[Symbol] VARCHAR(20) NOT NULL,
	[TradeDate] DATETIME NOT NULL,     
	[ClosePrice] DECIMAL(18,4) NOT NULL
) ON [PRIMARY]; -- 🌟 關鍵：必須跟你要搬出的抽屜在同一個群組
GO

-- 補上一模一樣的 PK
ALTER TABLE [dbo].[QuantMarketData_Staging] ADD CONSTRAINT [PK_QuantMarketData_Staging] PRIMARY KEY CLUSTERED 
(
	[StrategyID] ASC,
	[Symbol] ASC,
	[TradeDate] ASC
) ON [PRIMARY];
GO

-- ==========================================
-- 2. 建立模擬的遠端歷史表 (History Table)
-- ==========================================
CREATE TABLE [dbo].[HistoryDB_QuantData] (
	[StrategyID] INT NOT NULL,
	[Symbol] VARCHAR(20) NOT NULL,
	[TradeDate] DATETIME NOT NULL,     
	[ClosePrice] DECIMAL(18,4) NOT NULL
) ON [PRIMARY]; 
GO
```
### 📝 範例 (Examples：每月 1 號的排程任務)

**【實戰演練：把第 1 號抽屜的資料封存到遠端】**

假設你的主表 `QuantMarketData` 的第 1 號抽屜裡已經裝滿了過期的舊資料。現在，請按照這三個 DBA 標準步驟執行：
```sql
USE [TestDB];
GO

-- 🔪 步驟一：秒切 (脫離主表)
-- 把主表第 1 號抽屜，瞬間倒進中繼表。
-- (執行完這行，主表就乾淨了，線上交易完全不受影響)
ALTER TABLE [dbo].[QuantMarketData] 
SWITCH PARTITION 1 TO [dbo].[QuantMarketData_Staging];
GO

-- 🚚 步驟二：跨庫實體搬家 (物理轉移)
-- 把中繼表的資料，塞進遠端的歷史庫。
-- (因為中繼表沒有其他人會用，所以這裡慢慢 INSERT 也不會卡死別人)
INSERT INTO [dbo].[HistoryDB_QuantData] 
    ([StrategyID], [Symbol], [TradeDate], [ClosePrice])
SELECT 
    [StrategyID], [Symbol], [TradeDate], [ClosePrice] 
FROM [dbo].[QuantMarketData_Staging];
GO

-- 🗑️ 步驟三：銷毀中繼表，釋放空間
-- 確定歷史庫都收到了，一秒清空暫存紙箱！
TRUNCATE TABLE [dbo].[QuantMarketData_Staging];
GO
```