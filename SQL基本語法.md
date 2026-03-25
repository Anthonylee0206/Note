# 資料庫建置 (DDL)

---

## 刪除和建立資料表 
```SQL
DROP TABLE IF EXISTS Products;
GO
CREATE TABLE Products (
ProductID INT PRIMARY KEY,             -- 主鍵，確保編號絕對不重複 (天生自帶 NOT NULL)
ItemName VARCHAR(50),                  -- 字串型態 (最多 50 字)
Price DECIMAL(10, 2),                  -- 金錢專屬格式 (總長 10 位數，小數點佔 2 位)
InstallDate DATE                       -- 日期型態 (年月日)
);
GO
```
## SELECT (資料查詢與篩選)
- **全表查詢**：`SELECT * FROM Products;`
- **條件過濾**：`WHERE Price > 1000 AND Stock > 30` (數字直接寫，字串要加單引號 `' '`)
- **模糊搜尋**：`WHERE ItemName LIKE '%無線%'` (`%` 代表任意字元)
- **資料排序**：`ORDER BY Price DESC` (`DESC` 為降冪由大到小，放在語法最尾端)
- **分群與加總**：搭配 `AS` 幫計算出來的欄位取別名
```SQL
SELECT Category, SUM(Stock) AS '總庫存'
FROM Products
GROUP BY Category;
```
## INSERT (新增資料的兩種方式)
```SQL
INSERT INTO Products (ProductID, ItemName, Price, InstallDate)
VALUES
(1, '機械鍵盤', 2500.00, '2026-01-15'),
(2, '無線滑鼠', 850.50, '2026-02-01');
GO
-- 把暫存表裡的資料，全部挑出來灌進 Products 裡
INSERT INTO Products (ProductID, ItemName, Price, InstallDate)
SELECT 
     ProductID
    ,ItemName
    ,Price
    ,InstallDate
FROM Products_Staging;
GO
```
## UPDATE(更新資料)
**保命鐵則**：絕對要加 WHERE 條件，否則全表都會被改掉！
```SQL
UPDATE Products
SET Stock = 100
WHERE ProductID = 1;
```
## DELETE(刪除資料)
**保命鐵則**：絕對要加 WHERE 條件，否則整張表會被清空！
```SQL
DELETE FROM Products
WHERE ProductID = 4;
```
# 自動化與邏輯層

----

## VIEW(檢視表)
將複雜的查詢與即時運算 (如算價差) 存成一個「專屬監視器」，本身不佔實體硬碟空間。
```SQL
-- 建立 VIEW (櫥窗)
CREATE VIEW vw_HighEndProducts
AS
SELECT 
    ProductID, 
    ItemName, 
    Price, 
    InstallDate
FROM Products
WHERE Price > 1000.00; -- 只挑出超過 1000 元的商品
GO

-- 🎯 實戰應用：以後查詢就像查一般資料表一樣簡單！
SELECT * FROM vw_HighEndProducts;
```
## FUNCTION(自訂函數)
像隨身計算機，專門處理數學邏輯 (如取最大值、算手續費)，丟入參數即吐出結果。
```SQL
-- 建立 FUNCTION (計算機)：丟入原價，回傳打 8 折後的價格
CREATE FUNCTION fn_CalculateVIPPrice (@OriginalPrice DECIMAL(10,2))
RETURNS DECIMAL(10,2) -- 宣告會吐出什麼型態的結果
AS
BEGIN
    DECLARE @DiscountPrice DECIMAL(10,2);
    
    -- 計算 8 折
    SET @DiscountPrice = @OriginalPrice * 0.8; 

    RETURN @DiscountPrice; -- 把算好的結果吐出來
END;
GO

-- 🎯 實戰應用：套用在 SELECT 查詢裡面，自動幫所有商品算出 VIP 價！
SELECT 
    ProductID,
    ItemName,
    Price AS [原價],
    dbo.fn_CalculateVIPPrice(Price) AS [VIP專屬八折價] -- 呼叫我們自訂的計算機
FROM Products;
```
## STORED PROCEDURE(預存程序)
自動化決策機器人，可包辦 `IF...ELSE` 邏輯，並能主動執行 `INSERT/UPDATE` 等寫入動作。(最常用來接收 Python 爬蟲抓回來的實盤報價並自動存檔)
```SQL
-- 建立 SP (自動化產線)：需要告訴它「商品編號」跟「新價格」
CREATE PROCEDURE sp_UpdateProductPrice
    @TargetID INT,
    @NewPrice DECIMAL(10,2)
AS
BEGIN
    -- 防呆機制：先檢查這項商品存不存在
    IF EXISTS (SELECT 1 FROM Products WHERE ProductID = @TargetID)
    BEGIN
        -- 如果存在，就執行更新
        UPDATE Products
        SET Price = @NewPrice
        WHERE ProductID = @TargetID;
        
        PRINT '✅ 更新成功！價格已修改。';
    END
    ELSE
    BEGIN
        -- 如果找不到商品，印出警告
        PRINT '❌ 更新失敗！找不到這個商品編號。';
    END
END;
GO

-- 🎯 實戰應用：呼叫 SP 來執行任務 (必須用 EXEC，不能放在 SELECT 裡)

-- 測試一：把 2 號商品 (無線滑鼠) 的價格改成 900
EXEC sp_UpdateProductPrice @TargetID = 2, @NewPrice = 900.00;

-- 測試二：故意更新一個不存在的 99 號商品 (會觸發防呆警告)
EXEC sp_UpdateProductPrice @TargetID = 99, @NewPrice = 100.00;

-- 驗收成果
SELECT * FROM Products;
```
# 進階查詢與多表關聯

----

## GROUP BY(分組)
```SQL
-- 1. 幫原本的表加一個「分類」欄位
ALTER TABLE Products ADD Category VARCHAR(20);
GO

-- 2. 幫原本的鍵盤跟滑鼠貼上分類標籤
UPDATE Products SET Category = '電腦周邊' WHERE ProductID IN (1, 2);
GO

-- 3. 多進幾筆不同分類的貨
INSERT INTO Products (ProductID, ItemName, Price, InstallDate, Category)
VALUES
(3, '電競耳機', 3200.00, '2026-03-05', '電腦周邊'),
(4, '辦公桌', 5500.00, '2026-02-10', '辦公家具'),
(5, '人體工學椅', 8900.00, '2026-02-15', '辦公家具'),
(6, '隨身碟 128G', 450.00, '2026-03-01', '電腦周邊');
GO
--1
SELECT 
    Category AS [商品分類],
    COUNT(ProductID) AS [商品數量],   -- 算籃子裡有幾個
    SUM(Price) AS [庫存總價值],       -- 把籃子裡的價格全部加總
    AVG(Price) AS [平均單價]          -- 算籃子裡的平均價格
FROM Products
GROUP BY Category; -- 🌟 關鍵：宣告「我要依照 Category 來分類打包」
GO
--2
SELECT 
    Category AS [商品分類],
    COUNT(ProductID) AS [高價商品數量]
FROM Products
WHERE Price >= 1000.00     -- 🔪 第一關 (WHERE)：在打包前，先把低於 1000 元的便宜貨剔除
GROUP BY Category          -- 📦 第二關 (GROUP BY)：把剩下的高價品按分類打包
HAVING COUNT(ProductID) >= 2; -- 🗑️ 第三關 (HAVING)：打包數完後，把數量不到 2 件的籃子整個丟掉
GO
```
## ALIAS(取別名)
當欄位名稱太長，或是經過數學計算產生新數據時，使用 `AS` 可以讓報表更專業；幫資料表取單一字母的綽號，則可以讓程式碼版面極度簡潔。
- 為計算欄位取別名：
```SQL
SELECT Category, SUM(Stock) AS '總庫存'
FROM Products
GROUP BY Category;
```
- 為資料表取綽號 (業界標準寫法)：
```SQL
-- 將 Orders 簡稱 O，Products 簡稱 P (AS 可以省略)
SELECT O.OrderID, P.ItemName
FROM Orders O ...
```
## INNER JOIN
關聯式資料庫 (RDBMS) 最強大的靈魂！透過兩張表共有的「橋樑欄位」(例如 ProductID)，將分散儲存的資料（訂單與商品明細）無縫拼接成一張人類易讀的總表。
- 語法結構：
```SQL
SELECT
O.OrderID,       -- 來自訂單表
P.ItemName,      -- 來自商品表
O.Qty            -- 來自訂單表
FROM Orders AS O
INNER JOIN Products AS P
ON O.ProductID = P.ProductID;  -- 👈 兩張表相認的關鍵橋樑
```
## 表內運算
SQL 不只能撈取資料，還內建強大的運算引擎。可以在 `SELECT` 階段直接將不同欄位進行數學運算（加減乘除），瞬間產出財務或會計報表。
```SQL
SELECT
O.OrderID,
P.ItemName,
O.Qty,
(O.Qty * P.Price) AS '訂單總金額'  -- 👈 直接將「數量」乘上「單價」，並掛上新招牌
FROM Orders O
INNER JOIN Products P
ON O.ProductID = P.ProductID;
```
# 條件判斷式

----
在撈取資料時，資料庫底層為了效能，通常只存代碼或數字（例如存 `1` 或 `0`），但匯出報表時必須讓 PM 或老闆看懂。我們可以在 `SELECT` 階段，直接讓 SQL 幫我們把數字「翻譯」成人類易讀的文字。

### QA 守門員必備的防護細節

1. **Unicode 防亂碼 (`N'...'`)**：在輸入中文字串前加上 `N`，確保字元編碼正確。可防止中文字在跨國、跨語系的資料庫環境中變成 `???` 亂碼。
2. **保留字防護罩 (`[...]`)**：如果欄位名稱剛好是 SQL 的系統保留字（例如 `Action`、`Date`、`User`），請務必加上中括號 `[]` 包起來，避免引發語法錯誤。

### 三種實戰寫法大比拼

在實務上，我們可以根據情境的複雜度，選擇最適合的條件判斷語法：
```SQL
SELECT 
    U.UserName AS [使用者名稱],    -- 從 Users 表抓取名字
    L.LogDate AS [登入時間],      -- 從 LoginLogs 表抓取時間
    
    -- ====================================================================
    -- 武器 A：簡單 CASE (Simple CASE)
    -- [白話文]：把 [Action] 拿在手上，然後一個一個對答案。
    -- [適用場景]：只看單一欄位，且只有「等於 (=)」的情況（例如 1=成功, 2=失敗）。
    -- ====================================================================
    CASE [Action] 
        WHEN 1 THEN N'成功'  -- 如果 [Action] 是 1，就印出 '成功'
        ELSE N'失敗'         -- 其他所有情況，都印出 '失敗'
    END AS '登入狀態_A',
    
    -- ====================================================================
    -- 武器 B：搜尋 CASE (Searched CASE) 🌟 DBA 最愛用、最萬能！
    -- [白話文]：不先把欄位拿在手上，而是每一行 WHEN 都完整寫出一個判斷式。
    -- [適用場景]：需要複雜邏輯的時候！例如大於小於 (Action > 10)、或是跨欄位判斷 (Action = 1 AND Price > 1000)。
    -- ====================================================================
    CASE 
        WHEN [Action] = 1 THEN N'成功' 
        ELSE N'失敗' 
    END AS '登入狀態_B',
    
    -- ====================================================================
    -- 武器 C：IIF 函數 (Inline IF)
    -- [白話文]：長得跟 Excel 的 IF 函數一模一樣！語法最精簡。
    -- [語法規則]：IIF(判斷條件, 條件成立給這個, 條件不成立給這個)
    -- [適用場景]：簡單的「二選一」(True/False) 邏輯。版面看起來最乾淨。
    -- (注意：這是 SQL Server 2012 以後才支援的函數喔)
    -- ====================================================================
    IIF([Action] = 1, N'成功', N'失敗') AS '登入狀態_C'

-- ====================================================================
-- 🔗 資料表關聯 (JOIN)
-- [白話文]：把 Users(大表) 和 LoginLogs(明細表)，透過 UserID 這個共同欄位綁在一起！
-- ====================================================================
FROM Users AS U
INNER JOIN LoginLogs AS L
    ON U.UserID = L.UserID;
GO
```
# 宣告變數(DECLARE VARIABLES)

----

- 認明正字標記 (@)：在 SQL Server 裡面，只要是你自己創造的區域變數，名字前面一定都要加上一個小老鼠 `@`（例如：`@MyPrice`）。

- 生命週期超短：變數是暫存在記憶體裡的。只要你的這段腳本執行完畢（或者遇到 GO 這個批次結束指令），變數就會瞬間消失，不會留在資料庫裡。

- 標準三部曲：宣告 (`DECLARE`) ➔ 賦值 (`SET / SELECT`) ➔ 使用 (做運算或查詢)。

----
### EX.1
這是最標準的用法，直接把一個寫死的值塞進便利貼裡。
```SQL
-- 1. 宣告 (DECLARE)：跟系統要一個名為 @TargetDate 的暫存空間，並規定只能放日期 (DATE)
DECLARE @TargetDate DATE;

-- 2. 賦值 (SET)：把 '2026-02-01' 這個值寫到便利貼上
SET @TargetDate = '2026-02-01';

-- 3. 使用：拿這張便利貼去當作查詢條件
SELECT * FROM Products 
WHERE InstallDate >= @TargetDate;
-- 偷懶寫法: DECLARE @TargetDate DATE = '2026-02-01';
```
### EX.2
這招超級常用！當你的變數值不是固定的，而是要「去資料庫裡算出來」的時候。
```SQL
-- 情境：我想找出店裡「最貴的商品價格」，然後把它存起來，看看有哪些商品超過這個價格的一半。

DECLARE @MaxPrice DECIMAL(10,2); -- 準備一個裝價格的口袋

-- 🌟 關鍵寫法：用 SELECT 把算出來的最大值，塞進 @MaxPrice 裡面
SELECT @MaxPrice = MAX(Price) 
FROM Products;

-- 印出變數裡面的值來看看 (在 SSMS 的「訊息」視窗會看到)
PRINT '目前的最高價是：' + CAST(@MaxPrice AS VARCHAR);

-- 拿這個變數來做進階查詢 (找出價格超過最高價一半的商品)
SELECT * FROM Products
WHERE Price > (@MaxPrice / 2);
```
### EX.3
還記得我們在搬運海量資料時用的 WHILE 迴圈嗎？迴圈一定要搭配一個「變數計數器」，不然它會變成無限迴圈跑不出來！
```SQL
-- 1. 宣告一個整數變數，初始值設為 1
DECLARE @Counter INT = 1;

-- 2. 設定迴圈條件：只要 @Counter 小於等於 5，就一直跑
WHILE @Counter <= 5
BEGIN
    -- 這裡面可以放你想重複執行的動作 (例如 INSERT 資料)
    PRINT '現在跑到第 ' + CAST(@Counter AS VARCHAR) + ' 圈了！';
    
    -- 🌟 終極關鍵：每跑完一圈，就把計數器自己加 1 (不然會無限迴圈卡死！)
    SET @Counter = @Counter + 1;
END

PRINT '迴圈順利結束！';
```
## DBA 避坑指南：變數的「結界 (GO)」
在 SSMS 裡面寫腳本時，GO 是一個「批次結束」的指令。
變數的生命週期絕對跨不過 GO！這是初學者最常踩到的雷：
```SQL
-- ❌ 錯誤示範：跨越結界
DECLARE @TestName VARCHAR(20) = 'Tony';
GO -- 系統看到 GO，就把前面的記憶體全部清空了

PRINT @TestName; 
-- 💥 這裡會報錯：「必須宣告純量變數 "@TestName"」，因為它過不了 GO！
```

# 資料表變數 (@Table)和暫存表 (#Table)

----
在進行資料庫操作、壓力測試或撰寫自動化腳本時，我們常需要一個「臨時的空間」來存放過程中的資料。除了前面提到的 `#暫存表`，還有一種更輕量級的武器叫做 `@資料表變數`。
## 什麼是資料表變數 (Table Variable)？
它本質上是一個「長得像表格的變數」。既然是變數，它的生命週期就極短，而且主要存活在伺服器的記憶體 (RAM) 之中。
- 宣告語法:
```SQL
DECLARE @TestUsers TABLE (
UserID INT PRIMARY KEY,
UserName VARCHAR(20)
);
-- 宣告完後，就可以像一般表格一樣對它 INSERT 或 SELECT
```
這兩者雖然都是免洗餐具，但在底層運作與效能上有著決定性的差異：

| **比較項目** | **@資料表變數 (DECLARE @Table)** | **#暫存表 (CREATE TABLE #Table)** |
| --- | --- | --- |
| **存在位置** | 主要存在於 **記憶體 (RAM)** | 存在於資料庫實體硬碟的 **tempdb** 中 |
| **存活壽命** | **極短！** 所在的腳本批次一跑完（遇到 `GO`）就立刻消滅。 | **較長！** 只要當前的查詢視窗沒關閉，它就會一直活著。 |
| **適合資料量** | **極少量** (通常建議 1,000 筆以內)。 | **海量大數據** (十萬、百萬筆級別)。 |
| **效能與擴充** | 無法建立額外的統計資訊，塞入過多資料會導致查詢慢到當機。 | 支援建立「索引 (Index)」，處理龐大資料依然飛快。 |
| **QA 實戰場景** | RD 寫爬蟲抓回幾個特定的錯誤 ID，需要傳入腳本中快速比對時。 | 執行千萬筆壓力測試造假資料，或在修改正式資料前做的「安全沙盒備份」。 |

### 🚨 守門員避坑指南：結合 SELECT INTO 的限制
如果你想用 `SELECT INTO` 這個「無中生有」的複製絕招，只能使用 `#暫存表`，系統不允許你直接 `SELECT INTO` 到一個 `@資料表變數` 中。
```SQL
-- ✅ 正確寫法：把 JOIN 好的查詢結果，瞬間複製成一張暫存表
SELECT
U.UserID,
U.UserName,
L.Action
INTO #JoinedResult
FROM @Users AS U
INNER JOIN @LoginLogs AS L ON U.UserID = L.UserID;
```
# 迴圈控制與變數賦值 (WHILE & Variable Assignment)

----
在撰寫自動化腳本、壓測程式或預存程序 (Stored Procedure) 時，我們經常需要用語法讓資料庫「重複執行」某些動作，或者「逐筆」將資料撈出來檢查。這時候就需要結合迴圈與變數。

## 迴圈的現代化寫法 (`WHILE` 與 `+=`)
SQL Server 沒有 `FOR` 迴圈，全部都靠 `WHILE` 來控制。控制迴圈時，務必要讓計數器前進，否則會造成伺服器資源耗盡的「無窮迴圈 (Infinite Loop)」。

- **現代化步進寫法**：使用 `+=` (複合指派運算子)。
    - `SET @ID += 1;` 邏輯等同於傳統的 `SET @ID = @ID + 1;`。
    - **優點**：語法極度簡潔，與 Python 等現代主流程式語言邏輯接軌，更能大幅降低手誤打錯變數名稱的風險。
## 將查詢結果存入變數 (`SELECT @Var = Column`)

除了單純查詢，我們可以直接把撈出來的真實資料，精準地「塞進」事前宣告好的變數中，方便後續做運算或判斷。

- **語法結構**：
```SQL
SELECT
@變數1 = 欄位A,
@變數2 = 欄位B
FROM 表格名稱
WHERE 條件;
```
## 守門員必懂的「空值陷阱」 (The NULL Trap)

當你執行 `SELECT @Var = Column FROM ... WHERE ...`，但資料庫裡**根本找不到**符合條件的資料時，會發生什麼事？

- **殘酷真相**：資料庫**不會報錯**！變數會直接「保留它上一次的值」。
- **影響**：如果你一開始宣告變數時沒有給予預設值（預設為 `NULL`），且查詢沒撈到東西，最後印出來的報表就會是一大堆空值 (`NULL`)。這是在 Review 迴圈腳本時，最容易抓到的邏輯漏洞。

### 實戰範例：逐筆撈取資料的標準管線

這是一段非常嚴謹的迴圈腳本，從 ID 1 跑到 ID 3，每次都把資料抓進變數裡，然後印出獨立的小報表：
```SQL
-- 1. 宣告所有需要的變數
DECLARE
@PRODUCTID INT = 1, -- 迴圈起點：從 ID 1 開始
@ItemName VARCHAR(50),
@Category VARCHAR(20),
@Price DECIMAL(10,2),
@Stock INT;
-- 2. 設定迴圈：只要 ID <= 3 就繼續跑
WHILE (@PRODUCTID <= 3)
BEGIN
-- [動作一]：去實體表撈資料，並將靈魂(資料)注入變數中
SELECT
@ItemName = ItemName,
@Category = Category,
@Price = Price,
@Stock = Stock
FROM Products
WHERE ProductID = @PRODUCTID;
-- [動作二]：將裝滿資料的變數，當成報表印出來
-- (💡若動作一沒撈到資料，這裡就會印出 NULL)
SELECT
    @PRODUCTID AS '目前查詢ID',
    @ItemName AS '商品名稱',
    @Category AS '分類',
    @Price AS '價格',
    @Stock AS '庫存';

-- [動作三]：🚨 迴圈步進防線 (千萬不能漏掉這行！)
SET @PRODUCTID += 1;
END
```
# 動態迴圈與無窮迴圈 (Dynamic & Infinite Loops)

----
在真實的商業環境中，資料表的筆數每天都在變動，我們不可能每次都手動去改迴圈的終點數字（例如 `WHILE @ID <= 3`）。主管級的寫法會讓程式「自己去判斷」該跑幾次。實務上有兩大主流寫法：
## 流派一：先探路法 (算 COUNT 動態迴圈)
程式執行前，先去查出整張表「目前總共有幾筆」，並把這個數字當成迴圈的終點。

- **優點**：非常穩健，不管資料有幾筆都能精準跑完。
- **實戰寫法**：
```SQL
DECLARE @sn INT = 1;
DECLARE @count INT;
-- 1. 先探路：取得目前總筆數，存入變數
SELECT @count = COUNT(*) FROM [dbo].[acct_info];
-- 2. 動態終點：用總筆數來限制迴圈
WHILE (@sn <= @count)
BEGIN
-- (執行撈資料或寫入動作...)
SET @sn += 1;
END
```
## 流派二：蒙眼狂奔法 (無窮迴圈 ＋ 緊急煞車)

這是一種極度進階的寫法。故意寫一個永遠成立的條件讓迴圈無限跑，直到「撞到牆壁（撈不到資料）」才強制啟動煞車跳出。

- **核心魔法變數 (`@@ROWCOUNT`)**：SQL Server 內建的系統變數，會記錄「上一句 SQL 到底撈出/影響了幾筆資料」。如果撈不到東西，它就會是 `0`。
- **煞車指令 (`BREAK`)**：立刻中斷並跳出目前的 WHILE 迴圈。
- **實戰寫法**：
```SQL
DECLARE @sn INT = 1;
--1. 蓄意製造無窮迴圈 (1 永遠等於 1)
WHILE (1 = 1)
BEGIN
SELECT * FROM [dbo].[acct_info] WHERE sn = @sn;
--2. 緊急煞車：如果剛剛那句 SELECT 什麼都沒撈到 (0 筆)
IF @@ROWCOUNT = 0
    BREAK; -- 立刻跳出迴圈！

SET @sn += 1;
END
```
## 流派三：邊界定位法 (MIN & MAX 動態迴圈) 🏆 業界最穩健寫法

為了解決「斷號」導致漏抓的問題，我們不依賴總筆數 (`COUNT`)，也不盲目瞎跑。我們直接找出整張表的「最小值 (起點)」與「最大值 (終點)」，明確劃定迴圈的執行範圍。

- **核心語法 (`MIN` / `MAX`)**：動態抓取真實的首尾邊界。
- **避坑神指令 (`CONTINUE`)**：當迴圈跑到斷層（例如找不到流水號 3）時，不要用 `BREAK`（這會終止整個迴圈），而是用 `CONTINUE`。它的意思是：**「這回合直接放棄，跳過後面的動作，直接進入下一圈！」**

💻 實戰寫法 (完美避開所有陷阱)
```SQL
DECLARE @current_sn INT;
DECLARE @max_sn INT;
DECLARE @acct_name NVARCHAR(50);
-- 1. 偵查邊界：找出起點與終點
SELECT
    @current_sn = MIN(sn), -- 假設最小是 1
    @max_sn = MAX(sn) -- 假設最大是 5 (即使中間沒有 3)
FROM [dbo].[acct_info];
-- 2. 動態範圍：從 1 跑到 5
WHILE (@current_sn <= @max_sn)
BEGIN
-- 🛡️ QA 防線：檢查這個流水號存不存在？
-- (如果現在跑到 3，但 3 已經被刪除了)
   IF NOT EXISTS (SELECT 1 FROM [dbo].[acct_info] WHERE sn = @current_sn)
   BEGIN
       SET @current_sn += 1; -- 計數器先 +1 (千萬別忘記，不然會死迴圈)
       CONTINUE; -- ⚡ 啟動跳躍：略過這回合，直接回去跑 ID 4！
   END
-- === 下面是正常有抓到資料的處理邏輯 ===
   SELECT @acct_name = [acct_name]
   FROM [dbo].[acct_info]
   WHERE sn = @current_sn;

-- (處理你的資料...)

-- 正常情況的步進
   SET @current_sn += 1;
END
```
## QA 守門員必考題：斷號陷阱 (The Sequence Gap Trap)

在 Review 這兩種迴圈時，QA 必須具備敏銳的「邊界測試 (Edge Case)」直覺。
**情境**：如果資料庫的流水號有斷層（例如：1, 2, 4, 5，**缺少了 3**），這兩種寫法會發生什麼事？

- **流派一 (COUNT)**：總共 4 筆，迴圈會跑 4 次。當 `@sn = 3` 撈不到東西時，迴圈會繼續前進，成功抓到第 4 筆。但因為只跑 4 次，最後的流水號 `5` 就會被漏掉！
- **流派二 (BREAK)**：當迴圈跑到 `@sn = 3`，發現 `@@ROWCOUNT = 0`，**煞車系統會直接啟動並中斷迴圈**！後面的 `4` 和 `5` 會全部陣亡，直接漏抓！
- **💡 結論**：在資料有可能「被刪除而產生斷號」的表格上，這兩種傳統的 `WHILE` 寫法都會有 Bug。必須確保流水號是連續的，或者改用更進階的 Cursor (指標) 寫法。