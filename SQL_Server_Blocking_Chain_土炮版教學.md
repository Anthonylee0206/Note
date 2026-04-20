# SQL Server Blocking Chain 土炮版分析腳本

適用於 SQL Server 2016+,以 WHILE 迴圈搭配暫存表的方式建構阻塞鏈樹狀分析,
取代遞迴 CTE 寫法,讓中間過程可觀察、可除錯、可擴充。

---

## 一、整體思路

1. 刻一張暫存表存放阻塞鏈資料
2. 先找出「源頭 Blocker」(沒人擋他,但他擋別人) 放第 0 層
3. 用 WHILE 迴圈一層一層往下找受害者 (BFS 廣度優先)
4. 用 sort_path 排序,讓樹狀結構正確呈現

---

## 二、完整腳本

```sql
-- ============================================================
-- 土炮版 Blocking Chain 樹狀分析
-- ============================================================


-- ============================================================
-- Step 1: 建立暫存表
-- ============================================================
-- 為什麼用暫存表?
--   遞迴 CTE 雖然簡潔,但中間結果看不到、難以除錯。
--   暫存表可以隨時 SELECT 觀察,也方便中途插入額外邏輯。
-- 為什麼要 IF EXISTS DROP?
--   如果上次執行中斷沒清掉,這次 CREATE 會報錯,先確保乾淨。
DROP TABLE IF EXISTS #BlockingChain;

CREATE TABLE #BlockingChain
(
    spid            INT,            -- 自己的 session_id (SQL Server 給每個連線的編號)
    blocking_spid   INT,            -- 擋住自己的 session_id (0 代表自己就是源頭)
    tree_level      INT,            -- 在樹的第幾層 (0=源頭, 1=被源頭擋, 2=被第1層的人擋, 以此類推)
    sort_path       VARCHAR(500),   -- 排序用的路徑字串,例如 '00052.00078'
                                    -- 這是樹狀呈現的關鍵,沒有它分支會錯亂
    login_name      NVARCHAR(128),  -- 登入帳號
    host_name       NVARCHAR(128),  -- 從哪台機器連進來
    program_name    NVARCHAR(128),  -- 用什麼程式連進來 (SSMS, .NET, Java...)
    db_name         NVARCHAR(128),  -- 在哪個資料庫
    session_status  NVARCHAR(60),   -- 連線狀態 (running, sleeping, suspended)
                                    -- sleeping 又持有鎖通常代表孤兒交易,前端忘了 COMMIT
    wait_sec        INT,            -- 已經等待幾秒
    wait_type       NVARCHAR(60),   -- 等待類型 (LCK_M_X 排他鎖, LCK_M_S 共享鎖, ...)
    sql_text        NVARCHAR(MAX)   -- 目前正在執行的 SQL 文字
);


-- ============================================================
-- Step 2: 找出源頭 Blocker 塞入第 0 層
-- ============================================================
-- 「源頭」的定義:
--   條件 A: 我有擋到別人 (我的 session_id 出現在別人的 blocking_session_id)
--   條件 B: 我自己沒被擋 (我自己的 blocking_session_id 是 0 或不存在)
--   兩個條件同時成立才是真正的源頭。
--
-- 為什麼要這樣定義?
--   假設阻塞鏈是 A → B → C (A 擋 B, B 擋 C)
--   只看「有擋人」會把 A 和 B 都當源頭,但 B 其實也是受害者。
--   加上「沒被擋」才能精準鎖定最頂層的兇手 A。
INSERT INTO #BlockingChain
    (spid, blocking_spid, tree_level, sort_path,
     login_name, host_name, program_name, db_name,
     session_status, wait_sec, wait_type, sql_text)
SELECT
    s.session_id,
    0,                                                          -- 源頭沒有 blocker,填 0
    0,                                                          -- 第 0 層
    RIGHT('00000' + CAST(s.session_id AS VARCHAR(10)), 5),      -- sort_path 起始值
                                                                -- 例如 session 52 → '00052'
                                                                -- 補 0 是為了字串排序正確 (避免 '9' > '52')
    s.login_name,
    s.host_name,
    s.program_name,
    DB_NAME(COALESCE(r.database_id, 0)),                        -- sleeping session 沒有 active request,
                                                                -- r.database_id 會是 NULL,COALESCE 防呆
    s.status,
    0,                                                          -- 源頭自己沒在等,填 0
    NULL,                                                       -- 源頭沒有 wait_type
    t.text                                                      -- 取得 SQL 文字
FROM sys.dm_exec_sessions s
    -- dm_exec_sessions 包含「所有」連線,不管有沒有正在跑東西
LEFT JOIN sys.dm_exec_requests r
    ON s.session_id = r.session_id
    -- dm_exec_requests 只包含「正在執行」的請求,sleeping 的就沒資料
    -- 用 LEFT JOIN 才能把 sleeping 的源頭也撈出來
LEFT JOIN sys.dm_exec_connections c
    ON s.session_id = c.session_id
    -- dm_exec_connections 用來取得最近一次執行的 SQL handle
    -- 因為 sleeping session 的 r.sql_handle 是 NULL,要從 connections 拿備援
OUTER APPLY sys.dm_exec_sql_text(
    COALESCE(r.sql_handle, c.most_recent_sql_handle)
) t
    -- OUTER APPLY 類似 LEFT JOIN,但可以呼叫表值函式
    -- COALESCE 優先用 active request 的 sql_handle,沒有就用最近執行的
WHERE s.session_id IN (
        -- 條件 A: 我擋了別人
        SELECT DISTINCT blocking_session_id
        FROM sys.dm_exec_requests
        WHERE blocking_session_id > 0)
  AND s.session_id NOT IN (
        -- 條件 B: 我沒被別人擋
        SELECT session_id
        FROM sys.dm_exec_requests
        WHERE blocking_session_id > 0);

-- 想觀察源頭找到了哪些就跑這句
-- SELECT * FROM #BlockingChain;


-- ============================================================
-- Step 3: WHILE 迴圈往下挖受害者 (BFS 廣度優先搜尋)
-- ============================================================
-- 運作原理:
--   假設阻塞關係是 A(源頭) → B → C
--   第 1 圈:找誰被「第 0 層的 A」擋住 → 找到 B,塞入第 1 層
--   第 2 圈:找誰被「第 1 層的 B」擋住 → 找到 C,塞入第 2 層
--   第 3 圈:找誰被「第 2 層的 C」擋住 → 沒有 → BREAK
--
-- 為什麼要用「上一層」當條件?
--   如果不限制 bc.tree_level,每一圈會把已經處理過的人重複比對,
--   不只浪費效能,還可能造成同一筆資料插入多次。
DECLARE @current_level INT = 0;

WHILE 1 = 1                                 -- 永遠成立,靠裡面的 BREAK 跳出
BEGIN
    INSERT INTO #BlockingChain
        (spid, blocking_spid, tree_level, sort_path,
         login_name, host_name, program_name, db_name,
         session_status, wait_sec, wait_type, sql_text)
    SELECT
        r.session_id,
        r.blocking_session_id,                                      -- 我被誰擋
        @current_level + 1,                                         -- 我屬於下一層
        bc.sort_path + '.'
            + RIGHT('00000' + CAST(r.session_id AS VARCHAR(10)), 5),
            -- sort_path 拼接邏輯:
            -- 父層 '00052' + '.' + 我的 '00078' → '00052.00078'
            -- 字串排序時,'00052.00078' 會緊跟在 '00052' 後面,
            -- 確保樹狀結構視覺上正確
        s.login_name,
        s.host_name,
        s.program_name,
        DB_NAME(r.database_id),
        s.status,
        r.wait_time / 1000,                                         -- wait_time 單位是毫秒,/1000 換成秒
        r.wait_type,
        t.text
    FROM sys.dm_exec_requests r
    JOIN sys.dm_exec_sessions s
        ON r.session_id = s.session_id
    JOIN #BlockingChain bc
        ON r.blocking_session_id = bc.spid     -- 我的 blocker 必須在 #BlockingChain 裡
       AND bc.tree_level = @current_level      -- 而且必須是「上一層」的人
                                               -- 這個條件是迴圈正確運作的關鍵
    OUTER APPLY sys.dm_exec_sql_text(r.sql_handle) t
    WHERE r.blocking_session_id > 0            -- 只看被擋住的
      AND r.session_id NOT IN
          (SELECT spid FROM #BlockingChain);   -- 防呆:如果 A 擋 B、B 擋 A 形成循環,
                                               -- 沒這條件會無限迴圈

    -- @@ROWCOUNT 是上一句 INSERT 影響的筆數
    -- 如果這一圈沒找到新受害者,代表樹挖完了,跳出
    IF @@ROWCOUNT = 0 BREAK;

    SET @current_level = @current_level + 1;   -- 往下一層

    -- 安全保險:正常阻塞鏈不會超過 50 層
    -- 萬一遇到怪異情況也不會跑爆
    IF @current_level > 50 BREAK;
END


-- ============================================================
-- Step 4: 組樹狀圖呈現
-- ============================================================
-- 視覺呈現的兩個重點:
--   1. blocking_tree 欄位:用 REPLICATE 縮排 + ASCII 符號畫樹枝
--   2. ORDER BY sort_path:讓同一個源頭的分支聚在一起
--
-- 範例輸出:
--   >>> [52] ROOT BLOCKER
--       |-- [78] WAITING
--           |-- [91] WAITING
--       |-- [83] WAITING
--   >>> [101] ROOT BLOCKER
--       |-- [115] WAITING
SELECT
    blocking_tree =
        CASE
            WHEN tree_level = 0
                THEN '>>> [' + CAST(spid AS VARCHAR(10)) + '] ROOT BLOCKER'
                     -- 源頭用 >>> 標示,一眼就能看到
            ELSE REPLICATE('    ', tree_level)              -- 每深一層多 4 個空格
                 + '|-- [' + CAST(spid AS VARCHAR(10)) + '] WAITING'
                 -- |-- 是模擬樹枝的 ASCII 符號
        END,
    spid,
    blocking_spid,
    role           = CASE
                        WHEN tree_level = 0 THEN 'ROOT'         -- 源頭
                        ELSE 'VICTIM'                           -- 受害者
                     END,
    session_status,
    is_sleeping    = CASE
                        WHEN session_status = 'sleeping' THEN 'YES'
                        ELSE 'NO'
                     END,
                     -- sleeping 的源頭特別重要,通常是孤兒交易
                     -- (前端發出查詢後沒 COMMIT 也沒斷線)
    wait_sec,
    wait_type,
    login_name,
    host_name,
    program_name,
    db_name,
    sql_text
FROM #BlockingChain
ORDER BY sort_path;
    -- 為什麼用 sort_path 不用 tree_level?
    -- 假設有兩個源頭 52 和 101:
    --   用 tree_level 排序會變成:
    --     52 (level 0)
    --     101 (level 0)
    --     78 (level 1, 屬於 52)
    --     115 (level 1, 屬於 101)
    --   分支被打散
    --   用 sort_path 排序則是:
    --     52       sort_path = '00052'
    --     78       sort_path = '00052.00078'
    --     101      sort_path = '00101'
    --     115      sort_path = '00101.00115'
    --   分支聚在一起,樹狀結構才正確


-- 清理暫存表 (其實 SP 結束會自動清,寫出來是好習慣)
DROP TABLE #BlockingChain;
```

---

## 三、關鍵概念補充說明

### 1. 為什麼用三個 DMV?

| DMV | 用途 |
|---|---|
| `sys.dm_exec_sessions` | 所有連線(包含 sleeping),有登入資訊 |
| `sys.dm_exec_requests` | 只有正在執行的請求,有 blocking 關係 |
| `sys.dm_exec_connections` | 連線層級資訊,提供備援的 SQL handle |

要拼出完整資訊三個都需要。

### 2. OUTER APPLY vs LEFT JOIN

`sys.dm_exec_sql_text()` 是表值函式(接受參數的「函式型表」),不能用 JOIN 串接,
必須用 `CROSS APPLY` 或 `OUTER APPLY`。
`OUTER APPLY` 行為類似 `LEFT JOIN`,找不到資料時保留左邊的列。

### 3. sort_path 的字串補零

```sql
RIGHT('00000' + CAST(spid AS VARCHAR(10)), 5)
```

把 session_id 補成 5 位數,例如 52 變成 `'00052'`。
原因是字串排序時 `'9' > '52'`(因為比較第一個字元),補零後才能正確排序。

### 4. BFS vs DFS

- **BFS(廣度優先)**:一層一層往下挖,先把所有第 1 層挖完才挖第 2 層
- **DFS(深度優先)**:挖一個分支挖到底再挖下一個分支

BFS 用 WHILE 迴圈很直觀,DFS 比較適合用遞迴。本腳本採用 BFS。

### 5. @@ROWCOUNT 是迴圈終止的關鍵

`@@ROWCOUNT` 會記錄上一句 DML 影響的筆數。
當這一圈 INSERT 沒插入任何資料,代表樹已經挖完,再挖下去也是空的,BREAK 跳出。

---

## 四、土炮版 vs 遞迴 CTE 對照

| 比較點 | 遞迴 CTE | WHILE 暫存表 (土炮版) |
|---|---|---|
| 程式碼長度 | 短 | 長 |
| 可讀性 | 抽象,要熟才看得懂 | 步驟清楚,新手友善 |
| 除錯難度 | 難,中間結果看不到 | 易,每步可觀察 |
| 中途插入邏輯 | 困難 | 簡單 |
| 效能 | 通常較佳 | 略差但差距不大 |
| 適用場景 | 一次性查詢、報表 | 學習、客製化、長期維護 |

阻塞鏈通常層數不深、資料量不大,效能差異可以忽略。
土炮版反而比較容易維護和擴充。

---

## 五、執行範例輸出

```
blocking_tree                          spid  blocking_spid  role     is_sleeping  wait_sec  wait_type
>>> [52] ROOT BLOCKER                  52    0              ROOT     YES          0         NULL
    |-- [78] WAITING                   78    52             VICTIM   NO           45        LCK_M_X
        |-- [91] WAITING               91    78             VICTIM   NO           42        LCK_M_S
    |-- [83] WAITING                   83    52             VICTIM   NO           30        LCK_M_X
>>> [101] ROOT BLOCKER                 101   0              ROOT     NO           0         NULL
    |-- [115] WAITING                  115   101            VICTIM   NO           12        LCK_M_X
```

掃一眼就能判斷:
- **52** 是源頭、而且還在 sleeping,最可疑(八成是孤兒交易)
- **78、91** 形成二層阻塞,91 被 78 擋、78 被 52 擋
- **101** 是另一條獨立的阻塞鏈

---

## 六、可擴充的方向

### 加上自動 KILL 建議

```sql
kill_cmd = CASE
              WHEN tree_level = 0 AND session_status = 'sleeping'
              THEN 'KILL ' + CAST(spid AS VARCHAR(10))
              ELSE NULL
           END
```

源頭如果是孤兒 sleeping session,直接給一句可複製貼上的 KILL 指令。

### 改成歷史紀錄表

把 `#BlockingChain` 改成實體表 `dbo.BlockingHistory`,
加個 `snapshot_time` 欄位,搭配 SQL Agent 每分鐘跑一次,
就變成阻塞歷史紀錄表,事後可以查任何時間點的阻塞狀態。

### 中途過濾

例如想「找完源頭就先排除 sleeping 不到 1 分鐘的」,
土炮版直接在 Step 2 之後加 DELETE 就好:

```sql
DELETE FROM #BlockingChain
WHERE tree_level = 0
  AND session_status = 'sleeping'
  AND ... ;
```

遞迴 CTE 想做這件事就麻煩很多。
