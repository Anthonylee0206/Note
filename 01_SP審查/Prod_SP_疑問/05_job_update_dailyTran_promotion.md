# SP 5：job_update_dailyTran_promotion 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.job_update_dailyTran_promotion` 是排程 JOB，負責更新 `mem_daily_tran` 和 `mem_promotion`。
執行計畫中 MERGE `mem_daily_tran` 占 97% Cost，
UPDATE `mem_promotion` 有 Key Lookup 82%（跟 SP 1 `get_freebet_count` 同一個索引問題）。
另外再次出現 FORMAT() 函數。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.job_update_dailyTran_promotion` |
| 資料庫 | cmd_data |
| 用途 | 排程 JOB：玩遊戲滾流水，更新 mem_daily_tran 和 mem_promotion |
| 每日執行次數 | 約 856 次 |
| 平均耗時 | 1,450ms |
| 平均 Logical Reads | 898,443 |

---

## 三、問題清單

### 問題 1：FORMAT() 又出現了【必改】

```sql
-- ❌ FORMAT 回傳 NVARCHAR，跟 DATETIME 比對有隱含轉換
WHERE tran_date >= FORMAT(DATEADD(DAY,-45,GETDATE()),'yyyy-MM-dd 12:00:00')

-- ✅ 改用 DATEADD
WHERE tran_date >= DATEADD(HOUR, 12, CAST(DATEADD(DAY, -45, GETDATE()) AS DATE))
```

### 問題 2：Key Lookup 82%（跟 SP 1 同一個索引）【必改】

```
Missing Index (Impact 58.27):
ON [dbo].[mem_promotion] ([is_active])
INCLUDE ([mem_id], [promote_id], [curr_accum], ...)
```

**跟 `get_freebet_count` 完全同一個索引問題**，加一次索引兩支 SP 都受益。
但這支需要 INCLUDE 的欄位比 SP 1 多，建索引時要合併兩邊需求。

### 問題 3：MERGE 沒有 HOLDLOCK【建議】

```sql
-- ❌
MERGE mem_daily_tran AS T USING ...

-- ✅
MERGE mem_daily_tran WITH (HOLDLOCK) AS T USING ...
```

### 問題 4：UPDATE 用舊式 FROM 語法【建議】

```sql
-- ❌ 舊式寫法，WHERE 用子查詢別名比對表名.欄位
UPDATE mem_promotion WITH(UPDLOCK)
SET curr_accum = curr_accum + turnover_amt
FROM (...) AS t
WHERE memID = mem_promotion.mem_id
AND mem_promotion.is_active = 1
AND mem_promotion.promote_id = t.proID

-- ✅ 改用 MERGE 或標準 UPDATE ... JOIN
UPDATE mp
SET mp.curr_accum = mp.curr_accum + t.turnover_amt,
    mp.accum_wl = mp.accum_wl + t.wl
FROM mem_promotion AS mp WITH (UPDLOCK)
INNER JOIN (
    SELECT mem_id AS memID, promote_id AS proID,
           SUM(turnover_amt) AS turnover_amt,
           SUM(wl_amt) AS wl
    FROM #tmp_mem_promotion_turnover
    GROUP BY mem_id, promote_id
) AS t
    ON t.memID = mp.mem_id
   AND t.proID = mp.promote_id
WHERE mp.is_active = 1;
```

### 問題 5：CATCH 沒有 @@TRANCOUNT 和 THROW【建議】

```sql
-- ❌
BEGIN CATCH
    ROLLBACK
    EXEC dbo.sys_error_log
END CATCH

-- ✅
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRAN T1;
    EXEC dbo.sys_error_log;
    THROW;
END CATCH
```

### 問題 6：舊式 DROP TABLE + SET OFF【提醒】

```sql
-- ❌
IF OBJECT_ID('tempdb..#tmp_mem_promotion_turnover') IS NOT NULL
BEGIN DROP TABLE #tmp_mem_promotion_turnover END

-- ✅
DROP TABLE IF EXISTS #tmp_mem_promotion_turnover;
```

---

## 四、改動風險等級

| 改動 | 風險 |
|---|---|
| FORMAT 改 DATEADD | **低** |
| 索引加 INCLUDE（合併 SP 1 需求） | **低** |
| MERGE 加 HOLDLOCK | **中** |
| UPDATE 舊式改標準 JOIN | **中** |
| CATCH 加 @@TRANCOUNT + THROW | **中** |
| DROP TABLE IF EXISTS | **無** |
| 拿掉 SET OFF | **無** |

---

## 五、跨 SP 索引合併建議

SP 1（`get_freebet_count`）和 SP 5（`job_update_dailyTran_promotion`）
都需要 `mem_promotion.idx_is_active` 加 INCLUDE，
但各自需要不同的欄位。建議合併成一個涵蓋兩支 SP 的索引：

```sql
-- 合併兩支 SP 的 INCLUDE 需求
CREATE INDEX idx_is_active
    ON dbo.mem_promotion (is_active)
    INCLUDE (mem_id, promote_id, is_overdue, curr_accum, accum_wl)
WITH (DROP_EXISTING = ON, ONLINE = ON);
```

**一次加索引，同時修 SP 1 和 SP 5 的 Key Lookup 問題。**

具體要 INCLUDE 哪些欄位需要把兩邊的 Missing Index 建議合併，
可以用以下查詢確認 SQL Server 的完整建議：

```sql
SELECT
    mid.statement,
    mid.equality_columns,
    mid.inequality_columns,
    mid.included_columns,
    migs.avg_user_impact
FROM sys.dm_db_missing_index_details mid
JOIN sys.dm_db_missing_index_groups mig
    ON mid.index_handle = mig.index_handle
JOIN sys.dm_db_missing_index_group_stats migs
    ON mig.index_group_handle = migs.group_handle
WHERE mid.statement LIKE '%mem_promotion%'
ORDER BY migs.avg_user_impact DESC;
```

---

## 六、修正後完整版本

```sql
ALTER PROCEDURE [dbo].[job_update_dailyTran_promotion]
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    -- 清理暫存表
    DROP TABLE IF EXISTS #tmp_mem_promotion_turnover;

    CREATE TABLE #tmp_mem_promotion_turnover
    (
        [id]           BIGINT        NOT NULL,
        [mem_id]       VARCHAR(30)   NOT NULL,
        [provider_id]  VARCHAR(10)   NOT NULL,
        [tran_date]    DATETIME      NOT NULL,
        [promote_id]   VARCHAR(10)   NULL,
        [wl_amt]       DECIMAL(18,6) DEFAULT(0) NULL,
        [turnover_amt] DECIMAL(18,6) DEFAULT(0) NULL
    );

    -- 選出需要更新的優惠流水
    INSERT INTO #tmp_mem_promotion_turnover
    SELECT r.id, p.mem_id, r.provider_id, r.tran_date,
           r.promote_id, r.promote_wl, r.turnover_amt
    FROM total_tmp_cal_record AS r WITH (NOLOCK)
    INNER JOIN mem_promotion AS p WITH (NOLOCK)
        ON r.promote_id = p.promote_id
       AND r.mem_id     = p.mem_id
    WHERE p.is_active = 1;

    BEGIN TRY
        BEGIN TRAN T1;

            -- 彙總 total_tmp_cal_record
            DROP TABLE IF EXISTS #total_tmp_cal_record;

            SELECT
                mem_id, provider_id, tran_date, login_id,
                SUM(success_bet)  AS success_bet,
                SUM(wl_amt)       AS wl_amt,
                SUM(ttl_bet)      AS ttl_bet,
                SUM(jp_amt)       AS jp_amt,
                SUM(bet_count)    AS bet_count,
                SUM(turnover_amt) AS turnover_amt
            INTO #total_tmp_cal_record
            FROM total_tmp_cal_record WITH (NOLOCK)
            WHERE tran_date >= DATEADD(HOUR, 12, CAST(DATEADD(DAY, -45, GETDATE()) AS DATE))  -- FORMAT 改 DATEADD
            GROUP BY mem_id, provider_id, tran_date, login_id;

            -- 更新 daily 流水
            MERGE mem_daily_tran WITH (HOLDLOCK) AS T       -- 加 HOLDLOCK
            USING #total_tmp_cal_record AS S
            ON T.mem_id      = S.mem_id
               AND T.tran_date   = S.tran_date
               AND T.tran_type   = 'WL'
               AND T.provider_id = S.provider_id
            WHEN MATCHED THEN
                UPDATE SET
                    T.success_bet     = S.success_bet,
                    T.wl_amt          = S.wl_amt,
                    T.ttl_bet         = S.ttl_bet,
                    T.jp_amt          = S.jp_amt,
                    T.bet_count       = S.bet_count,
                    T.success_bonusbet = T.success_bonusbet + S.turnover_amt
            WHEN NOT MATCHED THEN
                INSERT (mem_id, provider_id, tran_type, tran_date,
                        bet_count, ttl_bet, success_bet, jp_amt, wl_amt,
                        comm_amt, login_id, in_count, in_amt, bonus_amt,
                        out_count, out_amt, success_bonusbet)
                VALUES (S.mem_id, S.provider_id, 'WL', S.tran_date,
                        ISNULL(S.bet_count, 0), ISNULL(S.ttl_bet, 0),
                        ISNULL(S.success_bet, 0), ISNULL(S.jp_amt, 0),
                        ISNULL(S.wl_amt, 0), 0, S.login_id,
                        0, 0, 0, 0, 0, ISNULL(S.turnover_amt, 0));

            -- 更新優惠流水（舊式 FROM 改標準 JOIN）
            UPDATE mp
            SET mp.curr_accum = mp.curr_accum + t.turnover_amt,
                mp.accum_wl   = mp.accum_wl + t.wl
            FROM mem_promotion AS mp WITH (UPDLOCK)
            INNER JOIN
            (
                SELECT mem_id, promote_id,
                       SUM(turnover_amt) AS turnover_amt,
                       SUM(wl_amt)       AS wl
                FROM #tmp_mem_promotion_turnover
                GROUP BY mem_id, promote_id
            ) AS t
                ON t.mem_id     = mp.mem_id
               AND t.promote_id = mp.promote_id
            WHERE mp.is_active = 1;

            -- 清除優惠流水
            UPDATE tcr
            SET tcr.turnover_amt = 0,
                tcr.promote_wl   = 0
            FROM total_tmp_cal_record AS tcr WITH (UPDLOCK)
            INNER JOIN #tmp_mem_promotion_turnover AS i
                ON tcr.id = i.id;

        COMMIT TRAN T1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN T1;
        EXEC dbo.sys_error_log;
        THROW;
    END CATCH
END;
GO
```

### 改動對照表

| # | 改前 | 改後 | 原因 |
|---|---|---|---|
| 1 | `FORMAT(DATEADD(...),'yyyy-MM-dd 12:00:00')` | `DATEADD(HOUR, 12, CAST(... AS DATE))` | FORMAT 慢且有隱含轉換 |
| 2 | `IF OBJECT_ID ... DROP` | `DROP TABLE IF EXISTS` | 簡化 |
| 3 | `MERGE mem_daily_tran AS T` | `MERGE mem_daily_tran WITH (HOLDLOCK) AS T` | 防止併發重複 INSERT |
| 4 | 舊式 `UPDATE ... FROM ... WHERE memID = mem_promotion.mem_id` | `UPDATE mp FROM mem_promotion AS mp INNER JOIN ...` | 標準 JOIN 寫法 |
| 5 | `UPDATE total_tmp_cal_record ... FROM #tmp ...` | `UPDATE tcr FROM total_tmp_cal_record AS tcr INNER JOIN ...` | 標準 JOIN + 明確別名 |
| 6 | `ROLLBACK` | `IF @@TRANCOUNT > 0 ROLLBACK TRAN T1` + `THROW` | 安全性 |
| 7 | `SET NOCOUNT, ARITHABORT OFF` | 拿掉 | SP 結束自動恢復 |

---
---

