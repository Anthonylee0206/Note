# SP 1：get_freebet_count 效能分析

分析日期：2026-04-22

---

## 一、問題摘要

`dbo.get_freebet_count` 執行計畫中 Key Lookup 占 50% Cost，
每次執行約 90,483 次 Key Lookup，只為了取 `is_overdue` 一個欄位。
該 SP 每天執行約 557 萬次，估計每天產生約 16 億次 Key Lookup。

---

## 二、SP 基本資訊

| 項目 | 內容 |
|---|---|
| SP 名稱 | `dbo.get_freebet_count` |
| 資料庫 | cmd_data |
| 用途 | BO Top Notice Promotion Count（計算符合條件的優惠數量）|
| 每日執行次數 | 約 557 萬次 |
| 平均耗時 | 1ms |
| 平均 Logical Reads | 548 |

---

## 三、SP 原始碼

```sql
ALTER PROCEDURE [dbo].[get_freebet_count]
    @MerchantId VARCHAR(10) = '',
    @RecordsCount INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT @RecordsCount = COUNT(mp.mem_id)
    FROM mem_promotion AS mp WITH (NOLOCK)
    INNER JOIN promotion p WITH (NOLOCK)
        ON mp.promote_id = p.promote_id
        AND mp.merchant_id = p.merchant_id
    INNER LOOP JOIN mem_info AS m WITH (NOLOCK)
        ON m.mem_id = mp.mem_id
    WHERE (mp.merchant_id = @MerchantId OR @MerchantId = '-')
        AND mp.is_active = 1
        AND (mp.curr_accum >= mp.target_amt AND mp.curr_accum <> 0)
        AND mp.is_overdue = 0

    SET NOCOUNT OFF;
END;
SET ANSI_PADDING OFF;
```

---

## 四、執行計畫分析

### 執行計畫節點與 Cost 分佈

| 節點 | 操作 | Cost | 說明 |
|---|---|---|---|
| **Key Lookup (Clustered)** | `PK_mem_promotion` | **50%** | 回主表查 `is_overdue` 欄位 |
| Clustered Index Seek | `PK_mem_info` | 45% | 查 mem_info 主鍵 |
| Index Scan (NonClustered) | `promotion.IIX_is_active` | 3% | promotion 全表掃描 |
| Hash Match (Inner Join) | - | 2% | JOIN 操作 |
| Index Seek (NonClustered) | `mem_promotion.idx_is_active` | 0% | 用索引找 is_active = 1 |

### Key Lookup 詳細資訊

| 屬性 | 值 |
|---|---|
| Predicate | `[mem_promotion].[is_overdue] = 0` |
| Estimated Number of Executions | 303.687 |
| Estimated Number of Rows for All Executions | 90,477 |
| Estimated Row Size | 9B |
| Object | `PK_mem_promotion` |

### 白話解釋

```
Step 1: idx_is_active 找 is_active = 1 → 304 筆
Step 2: 每筆回 PK_mem_promotion 查 is_overdue → 90,483 次 Key Lookup
Step 3: 篩完 is_overdue = 0 後 → 43 筆
Step 4: JOIN promotion 全表掃描 1,917 筆
Step 5: JOIN mem_info 用 PK Seek
Step 6: COUNT → result = 43
```

**核心問題**：90,483 次 Key Lookup 就為了查 `is_overdue` 一個 1 byte 的欄位。

---

## 五、影響評估

| 指標 | 數值 |
|---|---|
| 每日執行次數 | 約 557 萬次 |
| 每次 Key Lookup 次數 | 約 90,483 次 |
| **每日 Key Lookup 總次數** | **約 5 億次**（保守估計）|
| Key Lookup Cost 占比 | 50% |

雖然平均耗時只有 1ms，但乘上 557 萬次的執行量，
Key Lookup 帶來的累積 IO 壓力對整體系統有持續性的影響。

---

## 六、建議修正方案

### 方案 A：索引加 INCLUDE（風險最低，效果最大，推薦優先執行）

```sql
CREATE INDEX idx_is_active
    ON dbo.mem_promotion (is_active)
    INCLUDE (is_overdue)
WITH (DROP_EXISTING = ON, ONLINE = ON);
```

| 項目 | 說明 |
|---|---|
| 改動範圍 | 只改索引，不動 SP |
| 預期效果 | Key Lookup 消失，50% Cost 歸零 |
| 風險等級 | **低** |
| ONLINE = ON | 建立期間不鎖表，不影響線上業務 |
| 建議執行時段 | 離峰時段 |

### 方案 B：建立涵蓋索引（進一步優化）

```sql
CREATE INDEX idx_freebet_covering
    ON dbo.mem_promotion (is_active, is_overdue, merchant_id)
    INCLUDE (mem_id, promote_id, curr_accum, target_amt)
WITH (ONLINE = ON);
```

| 項目 | 說明 |
|---|---|
| 預期效果 | 整個查詢只靠索引完成，不回主表 |
| 風險等級 | **低**（但索引較大，INSERT/UPDATE 略慢）|
| 建議 | 如果方案 A 效果不夠再考慮 |

### 方案 C：SP 改寫（搭配索引修正一起做效果更好）

```sql
ALTER PROCEDURE [dbo].[get_freebet_count]
    @MerchantId  VARCHAR(10) = '',
    @RecordsCount INT = 0 OUTPUT
AS
BEGIN
    SET NOCOUNT, ARITHABORT ON;

    SELECT @RecordsCount = COUNT(mp.mem_id)
    FROM mem_promotion AS mp WITH (NOLOCK)
    INNER JOIN promotion AS p WITH (NOLOCK)
        ON mp.promote_id  = p.promote_id
       AND mp.merchant_id = p.merchant_id
    WHERE (@MerchantId = '-' OR mp.merchant_id = @MerchantId)
      AND mp.is_active   = 1
      AND mp.curr_accum >= mp.target_amt
      AND mp.curr_accum <> 0
      AND mp.is_overdue  = 0
      AND EXISTS (
          SELECT 1 FROM mem_info AS m WITH (NOLOCK)
          WHERE m.mem_id = mp.mem_id
      )
    OPTION (RECOMPILE);
END;
GO
```

#### SP 改動明細

| 項目 | 改前 | 改後 | 原因 |
|---|---|---|---|
| SET 選項 | `SET NOCOUNT ON` | `SET NOCOUNT, ARITHABORT ON` | 補上 ARITHABORT |
| LOOP JOIN | `INNER LOOP JOIN mem_info` | 拿掉強制指定 | 讓最佳化器自己選演算法 |
| mem_info | `INNER LOOP JOIN` | `EXISTS (SELECT 1 ...)` | 只需確認存在，不需取資料 |
| OR 條件 | 無處理 | 加 `OPTION (RECOMPILE)` | 讓最佳化器根據實際值決定計畫 |
| SET NOCOUNT OFF | 有 | 拿掉 | SP 結束自動恢復，不需要 |
| SET ANSI_PADDING OFF | SP 外面有 | 拿掉 | 多餘且在 SP 外面 |

#### SP 改寫風險等級

| 改動 | 風險 | 說明 |
|---|---|---|
| 加 ARITHABORT | 無 | 補上最佳實務 |
| 拿掉 SET OFF / ANSI_PADDING | 無 | 純清理 |
| 拿掉 LOOP JOIN | 中 | 執行計畫可能改變，需測試驗證 |
| 改 EXISTS | 中 | 邏輯需確認跟原本一致 |
| 加 RECOMPILE | 中 | 每次重新編譯，CPU 微增但查詢簡單 |

---

## 七、建議推進順序

```
第一步（低風險）：加索引 INCLUDE → 方案 A
  不改 SP，排離峰時段加索引
  預期 Key Lookup 消失，IO 大幅下降

第二步（中風險）：在測試環境驗證 SP 改寫 → 方案 C
  確認改寫後結果一致
  比較改寫前後 logical reads 和 elapsed time

第三步：整理修改單提交審核
  索引修改 + SP 改寫一起提交
  排定上線時間
```

---

## 八、其他觀察到的可疑 SP

同一次分析中觀察到以下 SP 也值得進一步分析：

| SP 名稱 | 每日執行次數 | avg_elapsed_ms | avg_logical_reads | 備註 |
|---|---|---|---|---|
| `PROC_TBRebateCal_InstantRebate` | 9,116 | 711ms | 1,016,423 | IO 最重，每次讀 100 萬 Page |
| `tran_list` | 1,466,446 | 26ms | 1,851 | 總耗時最高 |
| `mempromotion_by_list_new` | 5,612,970 | 4ms | 4,157 | 最高頻，max 到 14 秒 |
| `job_update_dailyTran_promotion` | 856 | 1,450ms | 898,443 | IO 很重 |
| `PROC_RedEnvelope_CalTurnover` | 856 | 847ms | 1,089,234 | IO 很重 |

建議後續逐一分析執行計畫，找出類似的索引或寫法問題。

---
---

