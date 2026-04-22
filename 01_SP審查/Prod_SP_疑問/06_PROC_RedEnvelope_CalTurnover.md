# SP 6：PROC_RedEnvelope_CalTurnover 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.PROC_RedEnvelope_CalTurnover` 是紅包流水計算 SP，
核心邏輯使用 WHILE 迴圈逐筆處理每個會員的紅包（偽 Cursor），
是導致平均 728ms、最大 5,651ms 的主因。
另外執行計畫顯示**同一支 SP 有兩個快取計畫，效能差 200 倍**，
是典型的 parameter sniffing 問題。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.PROC_RedEnvelope_CalTurnover` |
| 資料庫 | cmd_data |
| 用途 | 計算紅包流水並更新 TB_RedEnvelope_Mem |
| 每日執行次數 | 約 856 次 |
| 平均耗時 | 728ms（快的計畫）/ 834ms（慢的計畫） |
| 最大耗時 | 5,651ms |
| 平均 Logical Reads | 1,036,759（慢的計畫）/ 192（快的計畫）|
| 特殊說明 | 兩個快取計畫效能差 200 倍，疑似 parameter sniffing |

---

## 三、問題清單

### 問題 1：WHILE 迴圈逐筆處理（最大問題）【必改】

```sql
DECLARE @first AS INT, @last AS INT
SET @first = 1
SET @last = (SELECT COUNT(*) FROM #redEnvelope_mem)
WHILE @first <= @last
BEGIN
    SELECT @mem_id = ..., @red_id = ...
    FROM (... ROW_NUMBER() ...) WHERE rn = @first

    UPDATE #redEnvelope_valid_ticket
    SET red_id = S.red_id
    FROM ... WHERE rm.mem_id = @mem_id AND rm.red_id = @red_id

    SET @first = @first + 1
END
```

**這是偽裝的 Cursor**：

- 每圈都要做一次 ROW_NUMBER 子查詢找第 N 筆（每圈都重新排序整張表）
- 每圈都要做一次 UPDATE + JOIN
- 如果有 1000 個紅包 → 1000 圈 → 1000 次子查詢 + 1000 次 UPDATE

**這是 728ms 平均和 5651ms 最大耗時的主因。**

改寫方向：把 WHILE 迴圈改成用 Cursor（至少不用每圈重新 ROW_NUMBER），
或嘗試用視窗函數一次性計算（需要分析業務邏輯是否允許）。

### 問題 2：ISNULL 放在 WHERE 欄位側（多處）【必改】

```sql
-- ❌ 四處 ISNULL 包欄位
AND ISNULL(pt.success_bet_amt,0) > 0
AND ISNULL(pt.red_id,'') = ''
AND ISNULL(S.red_id,'') != ''
AND ISNULL(T.promote_id,'') = ''

-- ✅ 改寫
AND pt.success_bet_amt > 0
AND (pt.red_id IS NULL OR pt.red_id = '')
AND S.red_id IS NOT NULL AND S.red_id <> ''
AND (T.promote_id IS NULL OR T.promote_id = '')
```

### 問題 3：provider_ticket 被操作三次【建議】

```
第一次：INSERT SELECT 選票
第二次：MERGE 更新 red_id 和 promote_id
第三次：UPDATE 標記 NoRed（WHERE ISNULL(red_id,'') = ''）
```

第三次 UPDATE 的 WHERE 條件 `ISNULL(red_id,'') = ''` 會掃描 `provider_ticket` 大量資料，
而且日期條件只回推 1 天，但表裡可能有幾百萬筆 `red_id` 為空的舊資料。

### 問題 4：MERGE 沒有 HOLDLOCK（三處）【建議】

```sql
-- ❌
MERGE dbo.provider_ticket WITH(UPDLOCK) AS T
MERGE TB_RedEnvelope_Mem WITH(UPDLOCK) AS T  -- 兩次

-- ✅ 全部加 HOLDLOCK
MERGE dbo.provider_ticket WITH(UPDLOCK, HOLDLOCK) AS T
MERGE TB_RedEnvelope_Mem WITH(UPDLOCK, HOLDLOCK) AS T
```

### 問題 5：兩個 MERGE on TB_RedEnvelope_Mem 可以合併【建議】

```sql
-- 目前：第一個 MERGE 更新流水，第二個 MERGE 更新狀態
-- 可以合併成一個 MERGE，在 UPDATE SET 裡同時處理
MERGE TB_RedEnvelope_Mem WITH(UPDLOCK, HOLDLOCK) AS T
USING #redEnvelope_turnover AS S
ON T.mem_id = S.member_id AND T.red_id = S.red_id AND T.[status] = 1
WHEN MATCHED THEN
    UPDATE SET
        T.current_amt = T.current_amt + S.turnover_amt,
        T.current_wl = T.current_wl + S.wl,
        -- 達標就順便更新狀態
        T.[status] = CASE
            WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN 2
            ELSE T.[status] END,
        T.updated_by = CASE
            WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN 'System'
            ELSE T.updated_by END,
        T.updated_date = CASE
            WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN GETDATE()
            ELSE T.updated_date END;
```

注意：合併後要另外處理 `OUTPUT INTO TB_RedEnvelope_Mem_log` 的邏輯，
只 OUTPUT 狀態有變更的那些行。

### 問題 6：CATCH 沒有 @@TRANCOUNT 和 THROW【建議】

### 問題 7：舊式 DROP TABLE + SET OFF【提醒】

---

## 四、改動風險等級

| 改動 | 風險 |
|---|---|
| ISNULL 改寫 | **低** |
| MERGE 加 HOLDLOCK | **中** |
| 合併兩個 MERGE | **中**（需處理 OUTPUT 邏輯）|
| CATCH 加 @@TRANCOUNT + THROW | **中** |
| WHILE 迴圈改寫 | **高**（核心邏輯，需充分驗證）|
| DROP TABLE IF EXISTS | **無** |
| 拿掉 SET OFF | **無** |

---

## 五、建議推進順序

```
第一步（低風險）：ISNULL 改寫 + DROP TABLE IF EXISTS + 拿掉 SET OFF
  不影響邏輯，純寫法改善

第二步（中風險）：MERGE 加 HOLDLOCK + CATCH 修正
  併發安全性改善

第三步（中風險）：合併兩個 MERGE
  減少 TB_RedEnvelope_Mem 掃描次數
  需要處理 OUTPUT 邏輯

第四步（高風險）：WHILE 迴圈改寫
  核心邏輯重構，效果最大但風險也最大
  需要完整的測試案例驗證結果一致
  建議先在測試環境用真實資料量模擬
```

---

## 六、修正後完整版本

注意：WHILE 迴圈部分因為涉及紅包依序計算的業務邏輯（前一個紅包達標才算下一個），
短期內改用 Cursor 提升效率，長期建議重構為集合式操作。

```sql
ALTER PROCEDURE [dbo].[PROC_RedEnvelope_CalTurnover]
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    -- 清理暫存表
    DROP TABLE IF EXISTS #redEnvelope_valid_ticket;

    CREATE TABLE #redEnvelope_valid_ticket
    (
        [ticket_id]       BIGINT        NOT NULL,
        [ticket_date]     DATETIME      NOT NULL,
        [member_id]       VARCHAR(30)   NOT NULL,
        [provider_id]     VARCHAR(10)   NULL,
        [game_type]       VARCHAR(10)   NULL,
        [balance_date]    DATE          NULL,
        [success_bet_amt] NUMERIC(18,6) NULL,
        [wl_amt]          NUMERIC(18,6) NULL,
        [login_id]        VARCHAR(30)   NULL,
        [promote_id]      VARCHAR(10)   NULL,
        [red_id]          VARCHAR(10)   NULL
    );

    -- 選出生效中的會員紅包
    DROP TABLE IF EXISTS #redEnvelope_mem;

    SELECT rm.mem_id, rm.red_id, rm.create_date,
           rm.target_amt, rm.current_amt, re.game_id
    INTO #redEnvelope_mem
    FROM TB_RedEnvelope_Mem AS rm WITH (NOLOCK)
    LEFT JOIN TB_RedEnvelope AS re WITH (NOLOCK)
        ON re.red_id = rm.red_id
    WHERE rm.[status] = 1
      AND rm.target_amt > rm.current_amt;

    -- 選出需要計算的票
    INSERT INTO #redEnvelope_valid_ticket
    SELECT DISTINCT
        pt.ticket_id,
        pt.ticket_date,
        pt.member_id,
        pt.provider_id,
        ISNULL(pt.game_type, '') AS game_id,
        pt.balance_date,
        pt.success_bet_amt,
        pt.wl_amt,
        pt.login_id,
        pt.promote_id,
        NULL AS red_id
    FROM dbo.provider_ticket AS pt WITH (NOLOCK)
    INNER JOIN #redEnvelope_mem AS rm
        ON rm.mem_id = pt.member_id
    WHERE pt.is_cancel = 0
      AND pt.success_bet_amt > 0                                    -- 拿掉 ISNULL
      AND (pt.red_id IS NULL OR pt.red_id = '')                     -- 拿掉 ISNULL
      AND pt.balance_date >= DATEADD(DAY, -1, CAST(rm.create_date AS DATE));

    -- 依領取時間順序計算紅包流水
    -- 改用 Cursor 取代每圈都重新 ROW_NUMBER 的 WHILE 迴圈
    DECLARE @mem_id VARCHAR(30), @red_id VARCHAR(10);

    DECLARE red_cursor CURSOR LOCAL FAST_FORWARD FOR
        SELECT mem_id, red_id
        FROM #redEnvelope_mem
        ORDER BY mem_id, create_date;

    OPEN red_cursor;
    FETCH NEXT FROM red_cursor INTO @mem_id, @red_id;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- 計算紅包流水，達標後不計流水
        UPDATE #redEnvelope_valid_ticket
        SET red_id = S.red_id
        FROM #redEnvelope_valid_ticket AS T
        INNER JOIN
        (
            SELECT vt.ticket_id,
                   CASE WHEN SUM(vt.success_bet_amt)
                            OVER (PARTITION BY vt.member_id, vt.red_id
                                  ORDER BY vt.ticket_date, vt.ticket_id)
                        - vt.success_bet_amt + rm.current_amt < rm.target_amt
                        THEN rm.red_id
                        ELSE NULL
                   END AS red_id
            FROM #redEnvelope_mem AS rm
            INNER JOIN #redEnvelope_valid_ticket AS vt
                ON vt.member_id = rm.mem_id
               AND (vt.red_id IS NULL OR vt.red_id = '')            -- 拿掉 ISNULL
            WHERE rm.mem_id = @mem_id
              AND rm.red_id = @red_id
              AND (rm.game_id IS NULL
                   OR vt.game_type IN (SELECT VALUE FROM STRING_SPLIT(rm.game_id, ',')))
        ) AS S
            ON T.ticket_id = S.ticket_id;

        FETCH NEXT FROM red_cursor INTO @mem_id, @red_id;
    END

    CLOSE red_cursor;
    DEALLOCATE red_cursor;

    -- 計算累計紅包流水
    DROP TABLE IF EXISTS #redEnvelope_turnover;

    SELECT member_id, red_id,
           SUM(success_bet_amt) AS turnover_amt,
           SUM(wl_amt)          AS wl
    INTO #redEnvelope_turnover
    FROM #redEnvelope_valid_ticket
    WHERE red_id IS NOT NULL
    GROUP BY member_id, red_id;

    BEGIN TRY
        BEGIN TRAN t1;

            -- update provider_ticket red_id
            -- 領紅包但未領優惠的票，註記 NoRebate
            MERGE dbo.provider_ticket WITH (UPDLOCK, HOLDLOCK) AS T     -- 加 HOLDLOCK
            USING #redEnvelope_valid_ticket AS S
            ON T.ticket_id = S.ticket_id
            WHEN MATCHED THEN
                UPDATE SET
                    T.red_id = ISNULL(S.red_id, ''),
                    T.promote_id = CASE
                        WHEN S.red_id IS NOT NULL AND S.red_id <> ''    -- 拿掉 ISNULL
                             AND (T.promote_id IS NULL OR T.promote_id = '')
                        THEN 'NoRebate'
                        ELSE T.promote_id
                    END;

            -- 未領紅包的票，註記 NoRed
            UPDATE dbo.provider_ticket WITH (UPDLOCK)
            SET red_id = 'NoRed'
            WHERE is_cancel = 0
              AND success_bet_amt > 0                                    -- 拿掉 ISNULL
              AND (red_id IS NULL OR red_id = '')                        -- 拿掉 ISNULL
              AND balance_date >= DATEADD(DAY, -1, CAST(GETDATE() AS DATE));

            -- 更新紅包流水 + 達標自動 release（合併兩個 MERGE 為一個）
            MERGE TB_RedEnvelope_Mem WITH (UPDLOCK, HOLDLOCK) AS T      -- 加 HOLDLOCK
            USING #redEnvelope_turnover AS S
            ON T.mem_id  = S.member_id
               AND T.red_id  = S.red_id
               AND T.[status] = 1
            WHEN MATCHED THEN
                UPDATE SET
                    T.current_amt  = T.current_amt + S.turnover_amt,
                    T.current_wl   = T.current_wl + S.wl,
                    T.[status]     = CASE
                        WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN 2
                        ELSE T.[status] END,
                    T.updated_by   = CASE
                        WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN 'System'
                        ELSE T.updated_by END,
                    T.updated_date = CASE
                        WHEN T.current_amt + S.turnover_amt >= T.target_amt THEN GETDATE()
                        ELSE T.updated_date END
            OUTPUT
                CASE WHEN INSERTED.[status] = 2 THEN 'RELEASE' ELSE NULL END,
                INSERTED.*
            INTO TB_RedEnvelope_Mem_log;
            -- 注意：OUTPUT 會包含所有 MATCHED 的行，
            -- 需要確認 TB_RedEnvelope_Mem_log 是否能接受非 RELEASE 的行
            -- 如果不行，改成先 MERGE 再用 SELECT INSERT 記 log

        COMMIT TRAN t1;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRAN t1;
        EXEC dbo.sys_error_log;
        THROW;
    END CATCH
END;
GO
```

### 改動對照表

| # | 改前 | 改後 | 原因 |
|---|---|---|---|
| 1 | WHILE + ROW_NUMBER 每圈重新排序 | Cursor FAST_FORWARD | 不用每圈重新排序整張表 |
| 2 | `ISNULL(success_bet_amt,0) > 0` | `success_bet_amt > 0` | sargability |
| 3 | `ISNULL(red_id,'') = ''` | `(red_id IS NULL OR red_id = '')` | sargability |
| 4 | `ISNULL(S.red_id,'') != ''` | `S.red_id IS NOT NULL AND S.red_id <> ''` | sargability |
| 5 | `ISNULL(T.promote_id,'') = ''` | `(T.promote_id IS NULL OR T.promote_id = '')` | sargability |
| 6 | `CONVERT(DATE, rm.create_date)` | `CAST(rm.create_date AS DATE)` | 更簡潔 |
| 7 | MERGE 沒有 HOLDLOCK（三處） | 全部加 HOLDLOCK | 防止併發重複 |
| 8 | 兩個 MERGE on TB_RedEnvelope_Mem | 合併為一個 | 減少掃描次數 |
| 9 | `ROLLBACK` | `IF @@TRANCOUNT > 0 ROLLBACK TRAN t1` + `THROW` | 安全性 |
| 10 | `IF OBJECT_ID ... DROP` | `DROP TABLE IF EXISTS` | 簡化 |
| 11 | `SET NOCOUNT, ARITHABORT OFF` | 拿掉 | SP 結束自動恢復 |

### Cursor vs WHILE 的差異

```
改前 WHILE:
  每圈: ROW_NUMBER() OVER (ORDER BY ...) → 排序整張表
        找 rn = @first → 掃描結果集
        UPDATE → 執行
  1000 個紅包 = 排序 1000 次

改後 Cursor FAST_FORWARD:
  開始時: 排序一次，建立指標
  每圈: FETCH NEXT → O(1) 直接取下一筆
        UPDATE → 執行
  1000 個紅包 = 排序 1 次
```

### OUTPUT 合併的注意事項

合併兩個 MERGE 後，OUTPUT 會輸出所有 MATCHED 的行，
包含未達標（status 沒改變）的行。
如果 `TB_RedEnvelope_Mem_log` 只應記錄 RELEASE 的行，
需要改成以下方式：

```sql
-- 先 MERGE 不 OUTPUT
MERGE TB_RedEnvelope_Mem WITH (UPDLOCK, HOLDLOCK) AS T
USING #redEnvelope_turnover AS S
ON ...
WHEN MATCHED THEN UPDATE SET ...;

-- 再用 SELECT INSERT 只記錄達標的
INSERT INTO TB_RedEnvelope_Mem_log
SELECT 'RELEASE', *
FROM TB_RedEnvelope_Mem
WHERE [status] = 2
  AND updated_by = 'System'
  AND updated_date >= CAST(GETDATE() AS DATE);
```

---
---

