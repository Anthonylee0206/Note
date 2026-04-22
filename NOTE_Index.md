# NOTE 筆記索引

最後更新：2026-04-22

---

## 📂 目錄結構

```text
Note/
├── 01_SP審查/          ← 程式碼審查與 Prod 效能分析
├── 02_診斷與監控/      ← 健檢、阻塞、診斷工具包
├── 03_備份與維護/      ← 備份與統計資訊
├── 04_索引與資料表/    ← Index、Table 相關查詢
├── 05_分區Partition/   ← 分區概念、SOP、維運腳本
├── 06_JOB與資料搬移/   ← Agent JOB 與搬資料
├── 07_SQL語法/         ← 基礎語法、動態 SQL、萬年曆
├── 08_排錯/            ← 排錯腳本
├── 09_日誌與設定/      ← cmd_data_log、Filegroups
└── 10_DBA工具箱/       ← DBA 常用腳本集
```

---

## 一、[01_SP審查](01_SP審查/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [SP審查_Checklist.md](01_SP審查/SP審查_Checklist.md) | SP 審查基礎清單（SET、參數、JOIN、WHERE、交易安全） | 每次審查必看 |
| [SP審查_進階議題.md](01_SP審查/SP審查_進階議題.md) | 進階議題（NOLOCK/RCSI、索引、執行計畫、TRY/CATCH） | 複雜 SP 時參考 |
| [TSQL_Review_Note.md](01_SP審查/TSQL_Review_Note.md) | T-SQL 審查筆記 | |
| [Prod_SP_疑問/](01_SP審查/Prod_SP_疑問/) | Prod 環境 6 支 SP 完整效能分析（已拆分） | 持續更新 |

### Prod SP 效能分析（子目錄）

| 檔案 | SP 名稱 |
|---|---|
| [00_總覽與共同問題.md](01_SP審查/Prod_SP_疑問/00_總覽與共同問題.md) | 分析環境、六支 SP 共同問題彙總 |
| [01_get_freebet_count.md](01_SP審查/Prod_SP_疑問/01_get_freebet_count.md) | SP 1：get_freebet_count |
| [02_PROC_TBRebateCal_InstantRebate.md](01_SP審查/Prod_SP_疑問/02_PROC_TBRebateCal_InstantRebate.md) | SP 2：PROC_TBRebateCal_InstantRebate |
| [03_tran_list.md](01_SP審查/Prod_SP_疑問/03_tran_list.md) | SP 3：tran_list |
| [04_mempromotion_by_list_new.md](01_SP審查/Prod_SP_疑問/04_mempromotion_by_list_new.md) | SP 4：mempromotion_by_list_new |
| [05_job_update_dailyTran_promotion.md](01_SP審查/Prod_SP_疑問/05_job_update_dailyTran_promotion.md) | SP 5：job_update_dailyTran_promotion |
| [06_PROC_RedEnvelope_CalTurnover.md](01_SP審查/Prod_SP_疑問/06_PROC_RedEnvelope_CalTurnover.md) | SP 6：PROC_RedEnvelope_CalTurnover |

---

## 二、[02_診斷與監控](02_診斷與監控/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [SP_Diagnostic_Toolkit.sql](02_診斷與監控/SP_Diagnostic_Toolkit.sql) | SP 診斷工具包（10 章，環境概覽到阻塞鏈分析） | Prod 可安全執行 |
| [Blocking_Chain_教學.md](02_診斷與監控/Blocking_Chain_教學.md) | 阻塞鏈分析教學（WHILE 暫存表版） | 含原理說明 |
| [Daily_Health_Check.sql](02_診斷與監控/Daily_Health_Check.sql) | 每日健檢腳本 | |
| [Daily_Job_Check.sql](02_診斷與監控/Daily_Job_Check.sql) | JOB 日常檢查 | |

---

## 三、[03_備份與維護](03_備份與維護/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [Backup_Full_Auto.sql](03_備份與維護/Backup_Full_Auto.sql) | 全備份腳本 | |
| [Backup_Log.sql](03_備份與維護/Backup_Log.sql) | 日誌備份腳本 | |
| [Statistics_Update.sql](03_備份與維護/Statistics_Update.sql) | 統計資訊更新 | |

---

## 四、[04_索引與資料表](04_索引與資料表/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [Clustered_Index.md](04_索引與資料表/Clustered_Index.md) | 叢集索引筆記 | |
| [Table_Index.sql](04_索引與資料表/Table_Index.sql) | 資料表索引查詢 | |
| [Table_Space.sql](04_索引與資料表/Table_Space.sql) | 資料表空間查詢 | |
| [Create_Table_範例.sql](04_索引與資料表/Create_Table_範例.sql) | 建立資料表範例 | |

---

## 五、[05_分區Partition](05_分區Partition/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [Partition_概念.md](05_分區Partition/Partition_概念.md) | 分區觀念與系統視圖監控 | |
| [Partition_滑動視窗SOP.md](05_分區Partition/Partition_滑動視窗SOP.md) | 滑動視窗保養手冊（拆除 / 擴建 SOP） | |
| [Check_Partition.md](05_分區Partition/Check_Partition.md) | 分區檢查筆記 | |
| [Check_Partition.sql](05_分區Partition/Check_Partition.sql) | 分區檢查腳本 | |
| [Add_Partition.sql](05_分區Partition/Add_Partition.sql) | 新增分區腳本 | |

---

## 六、[06_JOB與資料搬移](06_JOB與資料搬移/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [JOBS_筆記.md](06_JOB與資料搬移/JOBS_筆記.md) | JOB 筆記 | |
| [JOBS_Move_Log.sql](06_JOB與資料搬移/JOBS_Move_Log.sql) | 搬移 log 資料 | |
| [JOBS_Move_Ticket_Data.sql](06_JOB與資料搬移/JOBS_Move_Ticket_Data.sql) | 搬移 ticket 資料 | |
| [SP_Move_Data.sql](06_JOB與資料搬移/SP_Move_Data.sql) | 資料搬移 SP | |

---

## 七、[07_SQL語法](07_SQL語法/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [SQL_基本語法.md](07_SQL語法/SQL_基本語法.md) | SQL 基礎語法筆記 | |
| [DynamicSQL.md](07_SQL語法/DynamicSQL.md) | 動態 SQL（雙變數組裝 + 模組化四變數） | 已合併兩份原筆記 |
| [萬年曆_教學.md](07_SQL語法/萬年曆_教學.md) | 用 WHILE + PIVOT 製作萬年曆 | 教學 |
| [Calendar.sql](07_SQL語法/Calendar.sql) | 萬年曆最終腳本 | |

---

## 八、[08_排錯](08_排錯/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [Troubleshooting_1.sql](08_排錯/Troubleshooting_1.sql) | 排錯腳本 1 | |
| [Troubleshooting_2.sql](08_排錯/Troubleshooting_2.sql) | 排錯腳本 2 | |

---

## 九、[09_日誌與設定](09_日誌與設定/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [cmd_data_log_自動清理.md](09_日誌與設定/cmd_data_log_自動清理.md) | 一鍵全自動清理舊分區資料 | |
| [cmd_data_log_維護SOP.md](09_日誌與設定/cmd_data_log_維護SOP.md) | 逐步盤點 / 拆除 / 擴建 SOP | |
| [Filegroups.md](09_日誌與設定/Filegroups.md) | 檔案群組筆記 | |

---

## 十、[10_DBA工具箱](10_DBA工具箱/)

| 檔案 | 用途 | 備註 |
|---|---|---|
| [DBA_常用腳本.md](10_DBA工具箱/DBA_常用腳本.md) | Log 使用率、分區筆數、失敗 JOB 等 | |
| [DBA_Survival_Toolkit.sql](10_DBA工具箱/DBA_Survival_Toolkit.sql) | 20 支 DBA 生存腳本 | |

---

## 🎯 常用速查

**審查 RD 腳本時** → [SP審查_Checklist.md](01_SP審查/SP審查_Checklist.md)

**進 Prod 查問題時** → [SP_Diagnostic_Toolkit.sql](02_診斷與監控/SP_Diagnostic_Toolkit.sql)

**發現效能問題時** → 記錄到 [01_SP審查/Prod_SP_疑問/](01_SP審查/Prod_SP_疑問/)

**遇到阻塞時** → [SP_Diagnostic_Toolkit.sql](02_診斷與監控/SP_Diagnostic_Toolkit.sql) 第八章

**學習新概念時** → [SP審查_進階議題.md](01_SP審查/SP審查_進階議題.md)

**寫動態查詢時** → [DynamicSQL.md](07_SQL語法/DynamicSQL.md)

**cmd_data_log 要維護時** → 先看 [cmd_data_log_維護SOP.md](09_日誌與設定/cmd_data_log_維護SOP.md)，大掃除用 [cmd_data_log_自動清理.md](09_日誌與設定/cmd_data_log_自動清理.md)
