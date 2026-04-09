# SQL Server Jobs - Google Sheet 整理指南

## Google Sheet 建議結構

建立一份 Google Sheet，包含以下 5 個工作表：

---

### Sheet 1：Job 總覽

| 欄位 | 說明 |
|------|------|
| Job 名稱 | SQL Agent Job 名稱 |
| 狀態 | 啟用 / 停用 |
| 分類 | Job 類別 |
| 描述 | Job 用途說明 |
| 擁有者 | 建立者帳號 |
| 排程頻率 | 每天 / 每週 / 單次 等 |
| 排程開始時間 | 例如 06:30:00 |
| 最後執行結果 | 成功 / 失敗 |
| 最後執行時間 | 時間戳記 |
| 執行時長(秒) | 上次執行花費時間 |
| 伺服器名稱 | 來源伺服器 |

### Sheet 2：步驟明細

| 欄位 | 說明 |
|------|------|
| Job 名稱 | 所屬 Job |
| 步驟編號 | 1, 2, 3... |
| 步驟名稱 | Step 名稱 |
| 步驟類型 | T-SQL / CmdExec / PowerShell |
| 執行資料庫 | 目標 DB |
| 執行命令 | SQL 語法或指令 |
| 成功後動作 | 下一步 / 結束 |
| 失敗後動作 | 下一步 / 報告失敗 |
| 伺服器名稱 | 來源伺服器 |

### Sheet 3：執行歷史

| 欄位 | 說明 |
|------|------|
| Job 名稱 | 所屬 Job |
| 步驟編號 | 執行步驟 |
| 執行時間 | 日期時間 |
| 執行結果 | 成功 / 失敗 / 重試 |
| 執行時長(秒) | 花費時間 |
| 訊息 | 系統回傳訊息 |
| 伺服器名稱 | 來源伺服器 |

### Sheet 4：排程明細

| 欄位 | 說明 |
|------|------|
| Job 名稱 | 所屬 Job |
| 排程名稱 | Schedule 名稱 |
| 排程狀態 | 啟用 / 停用 |
| 頻率類型 | 每天 / 每週 / 每月 |
| 執行日 | 週一、週二... 或每月第 N 天 |
| 開始時間 | HH:MM:SS |
| 子頻率 | 每 N 分鐘 / 於指定時間 |
| 伺服器名稱 | 來源伺服器 |

### Sheet 5：通知設定

| 欄位 | 說明 |
|------|------|
| Job 名稱 | 所屬 Job |
| Email 通知條件 | 成功時 / 失敗時 / 完成時 |
| Email 操作員 | 接收通知的人 |
| 自動刪除條件 | 是否自動清理 |
| 伺服器名稱 | 來源伺服器 |

---

## 匯出步驟

### 方法一：SSMS 直接複製（最快）

1. 在 SSMS 開啟 `sql_jobs_to_google_sheet.sql`
2. 依序執行每段查詢（選取一段後按 F5）
3. 在結果格線上 **Ctrl+A** 全選 → **Ctrl+C** 複製
4. 到 Google Sheet 對應工作表 **Ctrl+V** 貼上

### 方法二：匯出 CSV 後匯入

1. 在 SSMS 執行查詢
2. 結果格線右鍵 → **Save Results As** → 存成 `.csv`
3. Google Sheet → **檔案** → **匯入** → 上傳 CSV
4. 選擇 **分隔符號: 逗號**，匯入到對應的工作表

### 方法三：sqlcmd 命令列匯出

```bash
# 匯出 Job 總覽為 CSV（替換 SERVER_NAME 為實際伺服器名稱）
sqlcmd -S SERVER_NAME -d msdb -i sql_jobs_to_google_sheet.sql -s "," -o jobs_export.csv -W
```

---

## 多台伺服器整合

如果有多台 SQL Server，每台都執行相同查詢，結果都包含 `伺服器名稱` 欄位。
匯入 Google Sheet 後可利用此欄位做篩選或樞紐分析。

建議加入 **條件式格式**：
- 最後執行結果 = `失敗` → 紅色底色
- 狀態 = `停用` → 灰色文字
- 執行時長 > 3600 秒 → 橘色底色（執行超過 1 小時需關注）

---

## 已知 Jobs 對照表（本環境）

| Job 名稱 | 排程時間 | 來源庫 | 目標庫 | 說明 |
|----------|---------|--------|--------|------|
| JOBS_move_log | 每天 06:30 | cmd_data | cmd_data_log | 搬移 6 個月前的 log 資料 |
| jobs_move_ticket_data | 每天排程 | cmd_data | cmd_data_archive | 搬移 1 年前的 ticket 資料 |
| Partition Auto-Builder | 每週排程 | cmd_data | - | 自動建立下週的 Partition |

### JOBS_move_log 步驟拆解

| 步驟 | 對象 | 搬移方式 | 保留期限 | 批次大小 |
|------|------|---------|---------|---------|
| 1 | STEPNAME (透過 sp_move_data) | DELETE OUTPUT INTO | 依 sys_movelog_setting 設定 | 50,000 筆/批 |
| 2 | provider_ticket_cmd_cashout_log | CTE + JOIN + INSERT/DELETE | 6 個月 | 無分批 |
| 3 | provider_ticket_pp_log | WHILE + DELETE TOP + WAITFOR | 3 個月 | 10,000 筆/批 + 每批等 1 秒 |

### jobs_move_ticket_data 步驟拆解

| 步驟 | 對象 | 搬移方式 | 保留期限 | 批次大小 |
|------|------|---------|---------|---------|
| 1 | STEPNAME (透過 sp_move_data) | DELETE OUTPUT INTO | 依 sys_movelog_setting 設定 | 50,000 筆/批 |
| 2 | provider_ticket_cmd_cashout | DELETE OUTPUT + JOIN archive | 365 天 | 無分批 |
