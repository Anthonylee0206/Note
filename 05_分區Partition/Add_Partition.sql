/* =========================================================================
   【用途】       對分區函數 [Pfn_ticket_date] 新增「下週一 12:00」的邊界，
                  新分區落在 [FG_provider_ticket] 檔案群組。典型的滑動視窗擴建。
   【使用時機】   每週例行跑一次（建議週三～週五執行）；確保下週一來之前有新空房。
   【輸入參數】   無。@MONDAY 由 DATEADD(DAY,7,GETDATE()) 自動算「當下日期 + 7 天」
                  再格式化為 yyyy-MM-dd，再拼上 T12:00:00.000 當邊界。
   【輸出】       ALTER PARTITION SCHEME NEXT USED；ALTER PARTITION FUNCTION SPLIT RANGE。
                  成功無訊息，失敗會 RAISERROR（Primary 檢查 / 邊界已存在等）。
   【風險/注意】 - 會先做 Primary Replica 檢查，Secondary 執行會直接 RAISERROR 中止。
                  - 同一邊界重複 SPLIT 會報錯，確認當週還沒跑過。
                  - SPLIT RANGE 是函數層級操作，會影響所有使用 Pfn_ticket_date 的表。
                  - NEXT USED 若已經指向其他 FG，這次 ALTER 會覆蓋；需確認 FG_provider_ticket
                    有足夠磁碟空間。
   ========================================================================= */

--Check Replica - Primary

IF master.dbo.fn_hadr_is_primary_replica('cmd_data') = 0
BEGIN
		
RAISERROR(N'Must be executed on the Primary',16,1) WITH NOWAIT
		
END

-- =============================================================

-- cmd_data_provider_ticket

USE [cmd_data]
GO

SET NOCOUNT, ARITHABORT ON;
SET QUOTED_IDENTIFIER ON;

ALTER PARTITION SCHEME [Psh_ticket_date] NEXT USED [FG_provider_ticket]
GO

DECLARE
	@MONDAY NVARCHAR(10) = FORMAT(DATEADD(DAY,7,GETDATE()),'yyyy-MM-dd')

ALTER PARTITION FUNCTION [Pfn_ticket_date]() SPLIT RANGE(N''+@MONDAY+'T12:00:00.000')
GO

SET NOCOUNT, ARITHABORT OFF;
SET QUOTED_IDENTIFIER OFF;

-- =============================================================