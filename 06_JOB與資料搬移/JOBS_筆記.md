## 🟢 第一份：幕後核心預存程序 `sp_move_data` 

這支是所有 Job 都在呼叫的共用搬家引擎。

```sql
USE [cmd_data]
GO
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 建立預存程序，名稱為 sp_move_data，接收兩個參數
CREATE PROC [dbo].[sp_move_data]
    @Tbname VARCHAR(50),    -- 傳入參數 1：要搬移的資料表名稱 (但看邏輯，這其實是設定表裡的 Table_Name 條件)
    @TableType VARCHAR(6)   -- 傳入參數 2：資料表類型 (例如 'log', 'ticket')
AS
BEGIN

-- 關閉影響資料列數的訊息回傳，可以提升一點點效能
SET NOCOUNT ON;

-- 宣告變數，用來承接從設定表撈出來的設定值
DECLARE @Table_Name VARCHAR(50),      -- 實際的資料表名稱
        @FilterColName VARCHAR(20),   -- 用來當作過濾條件的「日期欄位名稱」
        @WhereString VARCHAR(200),    -- 過濾的門檻值 (例如 6 個月前)
        @FromDbName VARCHAR(20),      -- 來源資料庫 (通常是 cmd_data)
        @TargetDbName VARCHAR(20)     -- 目標資料庫 (通常是 cmd_data_log 或 archive)

-- 宣告一個變數，用來組裝動態執行的 SQL 語法
DECLARE @SQL NVARCHAR(500)

-- 去系統設定表 (sys_movelog_setting) 裡面，找出符合條件的搬家規則，並把值塞進剛才宣告的變數裡
SELECT @Table_Name = Table_Name,
       @FilterColName = FilterColName,
       @WhereString = WhereString,
       @FromDbName = FromDbName,
       @TargetDbName = TargetDbName
FROM cmd_data.dbo.sys_movelog_setting
WHERE Table_Name = @Tbname AND TableType = @TableType

-- 開始把變數組裝成一段真正的 DELETE 語法字串
SET @SQL = '
DELETE ' + @Table_Name + ' 
OUTPUT deleted.* -- 把剛才刪除的資料，瞬間輸出
INTO ' + @TargetDbName + '.dbo.' + @Table_Name + '  -- 並塞進目標資料庫的同名歷史表裡
FROM ' + @FromDbName + '.dbo.' + @Table_Name + '    -- 來源是原本的資料庫
WHERE ' + @FilterColName + ' < ' + @WhereString     -- 條件是：日期欄位 < 設定的門檻值
-- ⚠️ DBA 嚴重警告：這裡的 DELETE 後面漏寫了 TOP(50000)，會導致下面迴圈失效，一口氣刪除所有資料！

-- 如果組裝出來的語法不是空的，就開始執行
IF @SQL IS NOT NULL
BEGIN
    -- 開啟一個無窮迴圈 (1永遠等於1)
    WHILE (1=1)
    BEGIN
        -- 執行剛才組裝好的那段 DELETE 語法
        EXEC sp_executesql @SQL

        -- 檢查剛才那一擊殺了幾筆資料。如果小於 5 萬筆，代表搬完了
        IF (@@ROWCOUNT < 50000)
            BREAK; -- 打破並結束迴圈
    END
END

-- 恢復影響資料列數的訊息回傳
SET NOCOUNT OFF;

END
GO
```

---

## 🔵 第二份：日常搬家排程 `JOBS_move_log`

這支是每天早上 06:30 負責把資料搬去 `cmd_data_log` 的排程。

```sql
-- =============================================================
-- 檢查目前節點是不是主機 (Primary Replica)
-- 如果 fn_hadr_is_primary_replica 回傳 0 (代表是備援機)
IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
    -- 拋出紅色錯誤訊息並立刻中斷程式，保護備援機不被寫入
    RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
END
-- =============================================================

-- 呼叫剛才那支預存程序，去設定表找出名為 STEPNAME，類型為 log 的規則來搬資料
EXEC sp_move_data 'STEPNAME','log'

-- =============================================================
-- 針對 provider_ticket_cmd_cashout_log 的客製化搬家邏輯

-- 宣告變數 @date，並算出「今天的 6 個月前」是哪一天
declare @date date = DATEADD(MONTH,-6,GETDATE()) 

-- 建立第一個 CTE (暫存檢視表) 命名為 cashout
;with cashout as 
(
    -- 去主表抓出 6 個月前的訂單 ID 和交易日期 (使用 nolock 避免卡死線上玩家)
    select soc_trans_id, working_date
    from cmd_data.dbo.provider_ticket_cmd with (nolock)
    where working_date < @date
)
-- 把資料塞進歷史庫的 cashout_log 明細表
insert into cmd_data_log.dbo.provider_ticket_cmd_cashout_log
-- 抓取線上明細表的所有欄位，並補上主表的交易日期
select c.*, cashoutlog.working_date
from cmd_data.dbo.provider_ticket_cmd_cashout_log as c
-- 利用 Join 對照剛才抓出的「6 個月前舊訂單名單」
inner join cashout as cashoutlog 
on cashoutlog.soc_trans_id = c.soc_trans_id

-- 建立第二個 CTE (跟上面一模一樣，抓出 6 個月前的舊名單)
;with cashout as 
(
    select soc_trans_id 
    from cmd_data.dbo.provider_ticket_cmd with (nolock)
    where working_date < @date
)
-- 從線上庫的 cashout_log 明細表刪除資料
delete c
from cmd_data.dbo.provider_ticket_cmd_cashout_log as c
-- 一樣用 Join 對照舊名單，對得上的就砍掉，釋放空間
inner join cashout as cashoutlog 
on cashoutlog.soc_trans_id = c.soc_trans_id

-- =============================================================
-- 針對 provider_ticket_pp_log 的完美分批搬家邏輯 (DBA 滿分示範)

SET NOCOUNT ON;

-- 開啟無窮迴圈
WHILE (1=1)
BEGIN

-- 🌟 讓系統強制休息 1 秒鐘，讓硬碟 I/O 有時間喘息、消化 Transaction Log
WAITFOR DELAY '00:00:01.000'

-- 🌟 每次只精準刪除 1 萬筆資料，保護系統不卡死
DELETE TOP (10000) p 
OUTPUT deleted.* -- 刪除的同時瞬間輸出
INTO cmd_data_log..provider_ticket_pp_log -- 塞進歷史庫
FROM provider_ticket_pp_log p WITH (NOLOCK)
-- 條件：結束日期小於「今天的 3 個月前」
WHERE p.end_date < CAST(DATEADD(MONTH,-3,GETDATE()) AS DATE)
AND p.end_date IS NOT NULL

-- 檢查剛才砍了幾筆，如果砍不到 1 萬筆，代表舊資料都搬完了
IF (@@ROWCOUNT < 10000)
BEGIN
    BREAK; -- 結束迴圈
END

END
SET NOCOUNT OFF;
-- =============================================================
```

---

## 🟡 第三份：深冷搬家排程 `jobs_move_ticket_data`

這支負責把滿 1 年的資料搬去 `cmd_data_archive`。

```sql
-- 叢集主機檢查 (同上，防護備援機)
IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
    RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
END
-- =============================================================

-- 呼叫預存程序，這次找設定表裡類型為 'ticket' 的來搬
EXEC sp_move_data 'STEPNAME','ticket'

-- =============================================================
-- 針對 provider_ticket_cmd_cashout 的跨資料庫追溯搬家邏輯

-- 直接對線上庫的明細表下達刪除指令
DELETE cc 
OUTPUT deleted.*, cmd.working_date -- 刪除同時輸出明細，並補上主表日期
INTO cmd_data_archive.dbo.provider_ticket_cmd_cashout -- 塞進終極冷庫 archive
FROM dbo.provider_ticket_cmd_cashout cc
-- 🌟 神級 Join：直接去冷庫裡找「已經被搬過去的」主表紀錄
JOIN cmd_data_archive.dbo.[provider_ticket_cmd] cmd
ON cc.[soc_trans_id] = cmd.[soc_trans_id] 
-- 條件是：主表的交易日期，必須超過 365 天前 (1 年前)
AND cmd.[working_date] < CONVERT(VARCHAR(10),GETDATE()-365,111)
-- ⚠️ DBA 警告：這裡一樣少了 WHILE 迴圈跟 TOP 分批，資料量大時會有卡死風險
-- =============================================================
```

---

## 🔴 第四份：自動蓋新房間 `Partition Auto-Builder`

確保 2027 年長治久安的終極防護腳本。

```sql
-- =============================================================
-- 叢集主機檢查 (同上)
IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
    RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
END
-- =============================================================

-- 切換到線上庫 (如果是歷史庫，這裡會是 USE [cmd_data_log])
USE [cmd_data]
GO

-- 設定運算環境參數 (標準寫法)
SET NOCOUNT, ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;

-- 📍 準備地基：修改 Partition Scheme (分區配置機制)
-- 告訴系統：下一次切新房間時，請幫我蓋在 [FG_provider_ticket] 這個檔案群組裡
ALTER PARTITION SCHEME [Psh_ticket_date] NEXT USED [FG_provider_ticket]
GO

-- 📅 算日子：宣告一個字串變數 @MONDAY
-- 利用 DATEADD(DAY, 7, GETDATE()) 算出「今天的 7 天後」，並格式化成 YYYY-MM-DD
DECLARE
    @MONDAY NVARCHAR(10) = FORMAT(DATEADD(DAY,7,GETDATE()),'yyyy-MM-dd')

-- 🧱 蓋牆壁：修改 Partition Function (分區函數)
-- 發動 SPLIT RANGE，在剛才算出來的「7天後的中午 12:00:00」那個時間點，切出一道新的資料隔閡
ALTER PARTITION FUNCTION [Pfn_ticket_date]() SPLIT RANGE(N''+@MONDAY+'T12:00:00.000')
GO

-- 恢復環境參數
SET NOCOUNT, ARITHABORT OFF;
SET QUOTED_IDENTIFIER OFF;
-- =============================================================
```
