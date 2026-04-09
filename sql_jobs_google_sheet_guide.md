# SQL Server Jobs - Google Sheet 整理指南

## Google Sheet 欄位結構

| 欄位 | 說明 | 範例 |
|------|------|------|
| Job Name | SQL Agent Job 名稱 | `JOBS_move_log` |
| Enabled | 啟用狀態 (1=啟用, 0=停用) | `1` |
| Freq | 頻率 | `Daily`, `Weekly`, `Monthly` |
| Day | 執行日 | `Daily`, `Mon Fri`, `Day 2` |
| Time | 執行時間 | `6:30:00 AM`, `12:00:00 AM - 11:59:59 PM` |
| Schedule Summary | 完整排程描述 | `Occurs every day at 6:30:00 AM` |
| Description | Job 用途說明 | 搬移 6 個月前 log 資料 |

---

## 使用方式

1. 在 SSMS 開啟 `sql_jobs_to_google_sheet.sql`
2. 連接目標 SQL Server 執行（F5）
3. 結果 **Ctrl+A → Ctrl+C** 複製到 Google Sheet

## 多台伺服器整合

每台 SQL Server 各執行一次，貼到同一份 Google Sheet 的不同工作表（以環境命名，如 `CASH DEV`、`CASH PROD`）。

## 建議格式化

- **Enabled = 0** 的列 → 灰色底色（停用的 Job）
- **Schedule Summary** 欄 → 自動換行，方便閱讀長文字
- 第一列凍結為標題列
