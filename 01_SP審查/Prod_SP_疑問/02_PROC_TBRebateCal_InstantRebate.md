# SP 2：PROC_TBRebateCal_InstantRebate 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.PROC_TBRebateCal_InstantRebate` 是即時反水計算 SP，
執行計畫中 `provider_ticket` 全表掃描占 96% Cost，
SQL Server 自動建議的 Missing Index Impact 達 77.49%。
同時 SP 內部有多處寫法問題影響效能和安全性。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.PROC_TBRebateCal_InstantRebate` |
| 資料庫 | cmd_data |
| 用途 | 計算 provider_ticket 的反水並存入 TB_Rebate_Cal 和 mem_credit |
| 每日執行次數 | 約 9,116 次 |
| 平均耗時 | 711ms |
| 最大耗時 | 2,570ms |
| 平均 Logical Reads | 1,016,423（每次讀超過 100 萬 Page）|
| 平均 CPU | 7,346ms（有平行處理）|

---

## 三、執行計畫分析

### Missing Index 建議（SQL Server 自動提示）

#### Missing Index 1（Impact 77.49%，最優先）

```sql
CREATE NONCLUSTERED INDEX [IX_provider_ticket_cancel_balance]
ON [dbo].[provider_ticket] ([is_cancel], [balance_date])
INCLUDE ([ticket_id], [member_id], [provider_id], [game_type],
         [success_bet_amt], [promote_id]);
```

| 項目 | 說明 |
|---|---|
| 問題 | provider_ticket 全表掃描，占 96% Cost |
| Impact | 77.49%（建了這個索引效能改善約 77%）|
| 風險等級 | **低**（加 ONLINE = ON 不影響線上業務）|
| 建議 | **最優先處理** |

#### Missing Index 2（Impact 15.65%）

```sql
CREATE NONCLUSTERED INDEX [IX_cashback_setting_comm]
ON [dbo].[cashback_setting] ([comm])
INCLUDE ([min_comm_amt], [max_comm_amt]);
```

| 項目 | 說明 |
|---|---|
| 問題 | cashback_setting 全表掃描，占 18% Cost |
| Impact | 15.65% |
| 風險等級 | **低** |

### 執行計畫 Cost 分佈

#### 上半段（選出需要計算的票）

| 節點 | 操作 | Cost |
|---|---|---|
| **Index Scan (NonClustered)** | `provider_ticket` | **96%** |
| Clustered Index Scan | `mem_info` | 3% |
| Index Scan | `cashback_setting` | - |
| Table Insert | `#rebate_valid_ticket` | 1% |

#### 下半段（計算反水金額）

| 節點 | 操作 | Cost |
|---|---|---|
| Clustered Index Seek | `mem_info` | 35% |
| **Clustered Index Scan** | `cashback_setting` | **18%** |
| Hash Match (Inner Join) | - | 16% |
| Table Insert | `#rebate_calc_result` | 24% |

---

## 四、SP 程式碼問題清單

### 問題 1：FORMAT() 函數（效能殺手）【必改】

`FORMAT()` 底層使用 .NET CLR，比 `CONVERT()` 慢 10-50 倍。

```sql
-- ❌ 現在的寫法（3 處）
T.updated_date = FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')

ON T.tran_date = FORMAT(S.cal_date,'yyyy-MM-dd 12:00:00')

-- ✅ 改用 CONVERT
T.updated_date = CONVERT(VARCHAR(19), GETDATE(), 120)

ON T.tran_date = CONVERT(VARCHAR(10), S.cal_date, 120) + ' 12:00:00'
```

特別是放在 MERGE 的 ON 條件裡，每筆比對都會呼叫一次 CLR，
資料量大時效能影響非常顯著。

### 問題 2：ISNULL 放在 WHERE 欄位側（sargability）【必改】

```sql
-- ❌ 欄位被 ISNULL 包住，索引無法 Seek
WHERE ISNULL(pt.promote_id,'') = ''
  AND ISNULL(pt.success_bet_amt,0) > 0

-- ✅ 改寫
WHERE (pt.promote_id IS NULL OR pt.promote_id = '')
  AND pt.success_bet_amt > 0
```

### 問題 3：舊式 JOIN 寫法（逗號 JOIN）【必改】

```sql
-- ❌ 舊式 JOIN
FROM #rebate_valid_ticket AS t1,
     #rebate_calc_result AS t2
WHERE t2.cal_date = t1.balance_date
  AND t2.mem_id = t1.mem_id
  AND t2.provider_id = t1.provider_id
  AND t2.game_id = t1.game_id

-- ✅ 改成 ANSI JOIN
FROM #rebate_valid_ticket AS t1
INNER JOIN #rebate_calc_result AS t2
    ON t2.cal_date    = t1.balance_date
   AND t2.mem_id      = t1.mem_id
   AND t2.provider_id = t1.provider_id
   AND t2.game_id     = t1.game_id
```

### 問題 4：MERGE 缺 HOLDLOCK【建議】

```sql
-- ❌ 只有 UPDLOCK
MERGE dbo.provider_ticket WITH(UPDLOCK) AS T

-- ✅ 加上 HOLDLOCK 防止併發時重複 INSERT
MERGE dbo.provider_ticket WITH(UPDLOCK, HOLDLOCK) AS T
```

四個 MERGE 都建議加上 HOLDLOCK。

### 問題 5：CATCH 區塊問題【建議】

```sql
-- ❌ 現在的寫法
BEGIN CATCH 
    ROLLBACK;               -- 沒有檢查 @@TRANCOUNT
    EXEC dbo.sys_error_log  -- 記錄錯誤但沒有 THROW
END CATCH

-- ✅ 建議
BEGIN CATCH 
    IF @@TRANCOUNT > 0
        ROLLBACK TRAN t1;
    EXEC dbo.sys_error_log;
    THROW;                   -- 把錯誤丟回呼叫端
END CATCH
```

### 問題 6：cashback_setting 被 JOIN 了兩次【建議】

第一次在 INSERT `#rebate_valid_ticket` 時 JOIN `cashback_setting`，
第二次在 CTE `CalcRebate` 裡又 JOIN 一次。
同一張表被掃描兩次，可以考慮在第一次 JOIN 時就把需要的欄位帶出來存進暫存表，
避免重複掃描。

### 問題 7：暫存表可以用簡化語法【提醒】

```sql
-- ❌ 現在的寫法
IF OBJECT_ID('tempdb..#rebate_valid_ticket') IS NOT NULL
BEGIN DROP TABLE #rebate_valid_ticket END

-- ✅ 簡化版（SQL Server 2016+）
DROP TABLE IF EXISTS #rebate_valid_ticket;
```

### 問題 8：SET OFF 不需要【提醒】

```sql
-- ❌ SP 結束會自動恢復，不需要手動 OFF
SET NOCOUNT,ARITHABORT OFF;
```

---

## 五、改動風險等級總覽

| 改動 | 風險 | 類型 |
|---|---|---|
| 加索引 Missing Index 1（provider_ticket）| **低** | 索引 |
| 加索引 Missing Index 2（cashback_setting）| **低** | 索引 |
| FORMAT() 改 CONVERT() | **低** | SP 改寫 |
| ISNULL 改寫 | **低** | SP 改寫 |
| 舊式 JOIN 改 ANSI JOIN | **低** | SP 改寫 |
| MERGE 加 HOLDLOCK | **中** | SP 改寫 |
| CATCH 加 @@TRANCOUNT + THROW | **中** | SP 改寫 |
| cashback_setting 減少重複 JOIN | **中** | SP 改寫 |
| DROP TABLE IF EXISTS 簡化 | **無** | 清理 |
| 拿掉 SET OFF | **無** | 清理 |

---

## 六、建議推進順序

```
第一步（低風險）：加兩個 Missing Index
  排離峰時段，加 ONLINE = ON
  預期 provider_ticket 掃描從 96% 大幅下降
  cashback_setting 全表掃描消除

第二步（低風險）：改 FORMAT → CONVERT 和 ISNULL 寫法
  這幾個改動邏輯不變，只是寫法更高效
  在測試環境驗證後提交

第三步（中風險）：MERGE 加 HOLDLOCK、CATCH 修正、減少重複 JOIN
  涉及併發安全和錯誤處理邏輯
  需要在測試環境充分驗證
```

---

## 七、修正後完整版本

```sql
ALTER PROCEDURE [dbo].[PROC_TBRebateCal_InstantRebate]
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    DECLARE @BeginDate DATETIME = DATEADD(DAY, -2, GETDATE());

    -- 清理暫存表
    DROP TABLE IF EXISTS #rebate_valid_ticket;
    DROP TABLE IF EXISTS #rebate_calc_result;

    CREATE TABLE #rebate_valid_ticket
    (
        [ticket_id]       BIGINT         NOT NULL,
        [mem_id]          VARCHAR(30)    NULL,
        [provider_id]     VARCHAR(10)    NULL,
        [game_id]         VARCHAR(10)    NULL,
        [balance_date]    DATE           NULL,
        [success_bet_amt] NUMERIC(18,6)  NULL,
        -- 第一次 JOIN cashback_setting 時就把需要的欄位帶出來
        -- 避免後面 CTE 再 JOIN 一次（減少重複掃描）
        [curr_id]         VARCHAR(10)    NULL,
        [login_id]        VARCHAR(30)    NULL,
        [comm_type]       VARCHAR(16)    NULL,
        [comm]            NUMERIC(18,6)  NULL,
        [min_comm_amt]    NUMERIC(18,6)  NULL,
        [max_comm_amt]    NUMERIC(18,6)  NULL
    );

    -- 選出需要計算的票，同時帶出 cashback_setting 的欄位
    INSERT INTO #rebate_valid_ticket
    SELECT
        pt.ticket_id,
        pt.member_id,
        pt.provider_id,
        ISNULL(pt.game_type, '')    AS game_id,
        pt.balance_date,
        pt.success_bet_amt,
        mi.curr_id,
        mi.login_id,
        ISNULL(mi.comm_type, 'REBATE') AS comm_type,
        cs.comm,
        cs.min_comm_amt,
        cs.max_comm_amt
    FROM dbo.provider_ticket AS pt WITH (NOLOCK)
    INNER JOIN dbo.mem_info AS mi WITH (NOLOCK)
        ON mi.mem_id    = pt.member_id
       AND mi.[status]  = 1                         -- 篩選活躍用戶
    INNER JOIN dbo.cashback_setting AS cs WITH (NOLOCK)
        ON cs.provider_id = pt.provider_id          -- 篩選有設定參數的資料
       AND cs.game_id     = ISNULL(pt.game_type, '')
       AND cs.curr_id     = mi.curr_id
       AND cs.group_id    = mi.group_id
       AND cs.comm_type   = mi.comm_type
       AND cs.comm        > 0
    WHERE pt.balance_date >= @BeginDate
      AND pt.is_cancel     = 0
      AND (pt.promote_id IS NULL OR pt.promote_id = '')   -- 拿掉 ISNULL 包欄位
      AND pt.success_bet_amt > 0;                          -- 拿掉 ISNULL 包欄位

    CREATE TABLE #rebate_calc_result
    (
        [cal_date]        DATE           NOT NULL,
        [mem_id]          VARCHAR(30)    NOT NULL,
        [provider_id]     VARCHAR(10)    NOT NULL,
        [game_id]         VARCHAR(10)    NOT NULL,
        [curr_id]         VARCHAR(10)    NOT NULL,
        [login_id]        VARCHAR(30)    NULL,
        [ticket_count]    INT,
        [success_bet_amt] NUMERIC(18,6),
        [comm]            NUMERIC(18,6),
        [rebate_amt]      NUMERIC(18,2)
    );

    -- 處理反水計算
    -- 不再需要第二次 JOIN cashback_setting 和 mem_info
    -- 因為第一步已經把需要的欄位帶進暫存表
    ;WITH SummaryTicket AS
    (
        -- 彙總注單
        SELECT
            balance_date,
            mem_id,
            provider_id,
            game_id,
            curr_id,
            login_id,
            comm_type,
            comm,
            min_comm_amt,
            max_comm_amt,
            COUNT(ticket_id)                    AS ticket_count,
            SUM(ISNULL(success_bet_amt, 0))     AS success_bet_amt,
            ROUND(comm * SUM(ISNULL(success_bet_amt, 0)), 2, 2) AS rebate_amt
        FROM #rebate_valid_ticket
        GROUP BY balance_date, mem_id, provider_id, game_id,
                 curr_id, login_id, comm_type, comm,
                 min_comm_amt, max_comm_amt
    )
    INSERT INTO #rebate_calc_result
    SELECT
        balance_date,
        mem_id,
        provider_id,
        game_id,
        curr_id,
        login_id,
        ticket_count,
        success_bet_amt,
        comm,
        CASE
            WHEN rebate_amt > max_comm_amt THEN max_comm_amt
            ELSE rebate_amt
        END AS rebate_amt
    FROM SummaryTicket
    WHERE rebate_amt > min_comm_amt;

    BEGIN TRY
        BEGIN TRAN;

            -- update provider_ticket promote_id
            -- 篩選有成功發反水的票，標記為 'Rebate'
            MERGE dbo.provider_ticket WITH (UPDLOCK, HOLDLOCK) AS T
            USING
            (
                SELECT t1.ticket_id
                FROM #rebate_valid_ticket AS t1
                INNER JOIN #rebate_calc_result AS t2
                    ON t2.cal_date    = t1.balance_date
                   AND t2.mem_id      = t1.mem_id
                   AND t2.provider_id = t1.provider_id
                   AND t2.game_id     = t1.game_id
            ) AS S
            ON T.ticket_id = S.ticket_id
            WHEN MATCHED THEN
                UPDATE SET promote_id = 'Rebate';

            -- 存入 TB_Rebate_Cal
            MERGE dbo.TB_Rebate_Cal WITH (UPDLOCK, HOLDLOCK) AS T
            USING #rebate_calc_result AS S
            ON T.cal_date     = S.cal_date
               AND T.mem_id      = S.mem_id
               AND T.provider_id = S.provider_id
               AND T.game_id     = S.game_id
            WHEN MATCHED THEN
                UPDATE SET
                    T.ticket_count    = T.ticket_count + S.ticket_count,
                    T.success_bet_amt = T.success_bet_amt + S.success_bet_amt,
                    T.comm            = S.comm,
                    T.rebate_amt      = ISNULL(T.rebate_amt, 0) + S.rebate_amt,
                    T.updated_date    = CONVERT(VARCHAR(19), GETDATE(), 120)
            WHEN NOT MATCHED THEN
                INSERT
                    (cal_date, mem_id, provider_id, game_id, curr_id,
                     ticket_count, success_bet_amt, comm, rebate_amt,
                     updated_by, updated_date)
                VALUES
                    (S.cal_date, S.mem_id, S.provider_id, S.game_id, S.curr_id,
                     S.ticket_count, S.success_bet_amt, S.comm, S.rebate_amt,
                     'System', CONVERT(VARCHAR(19), GETDATE(), 120));

            -- 依照日期打到 mem_daily_tran
            MERGE dbo.mem_daily_tran WITH (UPDLOCK, HOLDLOCK) AS T
            USING
            (
                SELECT
                    cal_date,
                    mem_id,
                    provider_id,
                    SUM(rebate_amt) AS total_rebate_amt
                FROM #rebate_calc_result
                GROUP BY cal_date, mem_id, provider_id
            ) AS S
            ON T.tran_date    = DATEADD(HOUR, 12, CAST(S.cal_date AS DATETIME))
               AND T.mem_id      = S.mem_id
               AND T.provider_id = S.provider_id
               AND T.tran_type   = 'WL'
            WHEN MATCHED THEN
                UPDATE SET
                    T.comm_amt = ISNULL(T.comm_amt, 0) + S.total_rebate_amt,
                    T.net_amt  = ISNULL(T.net_amt, 0) + S.total_rebate_amt;

            -- update member rebate amount
            MERGE dbo.mem_credit WITH (UPDLOCK, HOLDLOCK) AS T
            USING
            (
                SELECT
                    mem_id,
                    SUM(rebate_amt) AS total_rebate_amt
                FROM #rebate_calc_result
                GROUP BY mem_id
            ) AS S
            ON S.mem_id = T.mem_id
            WHEN MATCHED THEN
                UPDATE SET
                    T.rebate_amt = ISNULL(T.rebate_amt, 0) + S.total_rebate_amt;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN;
        EXEC dbo.sys_error_log;
        THROW;
    END CATCH
END;
GO
```

### 改動對照表

| # | 改動 | 改前 | 改後 | 原因 |
|---|---|---|---|---|
| 1 | DROP TABLE | `IF OBJECT_ID ... DROP` | `DROP TABLE IF EXISTS` | 簡化（2016+ 支援，prod 是 2017 可用）|
| 2 | cashback_setting | JOIN 兩次 | 第一次就帶出所有欄位 | 減少重複掃描，省下 18% Cost |
| 3 | ISNULL WHERE | `ISNULL(promote_id,'') = ''` | `(promote_id IS NULL OR promote_id = '')` | sargability，索引可用 |
| 4 | ISNULL WHERE | `ISNULL(success_bet_amt,0) > 0` | `success_bet_amt > 0` | sargability，索引可用 |
| 5 | CTE | 重新 JOIN mem_info + cashback_setting | 直接用暫存表的欄位 | 省掉兩次 JOIN |
| 6 | 舊式 JOIN | `FROM t1, t2 WHERE ...` | `FROM t1 INNER JOIN t2 ON ...` | ANSI 標準 |
| 7 | MERGE | `WITH (UPDLOCK)` | `WITH (UPDLOCK, HOLDLOCK)` | 防止併發重複 INSERT |
| 8 | FORMAT | `FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss')` | `CONVERT(VARCHAR(19), GETDATE(), 120)` | 效能快 10-50 倍 |
| 9 | FORMAT | `FORMAT(S.cal_date,'yyyy-MM-dd 12:00:00')` | `DATEADD(HOUR, 12, CAST(S.cal_date AS DATETIME))` | 避免隱含轉換，索引可用 |
| 10 | CATCH | `ROLLBACK` | `IF @@TRANCOUNT > 0 ROLLBACK` + `THROW` | 安全性 |
| 11 | SET OFF | `SET NOCOUNT,ARITHABORT OFF` | 拿掉 | SP 結束自動恢復 |

---
---

