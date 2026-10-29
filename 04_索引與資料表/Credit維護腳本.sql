/* =========================================================================
   【用途】       Credit 維護日索引重組。沿用 Table_Index.sql 的產生語法方式：
                  一般索引照舊「碎片率 > 20%」才列出；
                  SOCTRANS / SOCTRANSPAR / WINLOSE 的叢集索引（PK）不管碎片率多少一律列出。
                  一次查詢產出一份清單，不會重複，複製 reorganizestr 欄位貼上執行即可。
   【使用時機】   Credit 維護日（2026-10-30 起）。在 CMDK_STOCKS 執行。
   【規則來源】   ryan wu，2026-10-29（CMD DBA BASE）：
                  - 維護日：PK_SOCTRANS / PK_SOCTRANSPAR / PK_WINLOSE 一律 REORGANIZE
                  - 其他日：不重組這 3 個（SELECT / UPDATE 多，重組常造成 BLOCKING）
   【輸入參數】   第 31 行 @frag_limit：一般索引的碎片率門檻（預設 20）
                  第 32 行 @force_db：指定索引只在這個 DB 強制列出（預設 CMDK_STOCKS），
                  避免在 DB2 的 CMDK_REPORTS（訂閱端，可能有同名 PK）誤列
   【輸出】       table_name / index_name / 碎片率 / reason（指定 or 超過門檻）/ 分區號 /
                  reorganizestr / rebuildstr / updatestatstr（可直接複製執行的語法）
   【風險/注意】  1. 指定的 3 個 PK 只能用 reorganizestr，不要用 rebuildstr（ryan 指定重組）。
                  2. REORGANIZE 不保證碎片率歸零（只重排 leaf level、單執行緒），做完剩幾 % 屬正常。
                  3. CMDK_STOCKS 是 Replication Publisher，重組寫大量 log，Log Reader 讀完才能截斷；
                     做完用檔尾第三段看 log_reuse_wait_desc 跟 log 使用率。
                  4. REORGANIZE 不更新統計值，3 張表做完記得跑 updatestatstr。
                  5. REORGANIZE 隨時可中斷，已完成的部分不會 rollback。
                  6. 分割表會依分區各一列（REORGANIZE PARTITION = n），筆數 <= 1000 的分區不列。
   ========================================================================= */

USE CMDK_STOCKS
GO

-- =========================================================================
-- 一、維護日：產生重組語法（一般 > 20% + 指定 3 個 PK）
-- =========================================================================

DECLARE @frag_limit FLOAT   = 20.0;            -- 一般索引的碎片率門檻
DECLARE @force_db   SYSNAME = N'CMDK_STOCKS';  -- 指定索引只在這個 DB 強制列出

;WITH A
AS
(
	SELECT
		 LOWER(T.name) AS table_name
		,I.name AS index_name
		,I.type_desc AS index_type
		,ISNULL(F.name,S.name) AS file_group
		,P.rows
		,I.is_unique
		,I.is_primary_key
		,P.partition_number
		,CASE WHEN DB_NAME() = @force_db
		       AND I.name IN ('PK_SOCTRANS','PK_SOCTRANSPAR','PK_WINLOSE')
		      THEN 1 ELSE 0 END AS is_forced
		,'ALTER INDEX [' + I.name + '] ON ' + SCHEMA_NAME(T.schema_id) + '.' + OBJECT_NAME(T.object_id) + ' REORGANIZE PARTITION = ' +
		CASE WHEN S.name IS NULL THEN 'ALL' ELSE CAST(P.partition_number AS VARCHAR) END + ' WITH (' +
		CASE WHEN I.type_desc LIKE '%COLUMNSTORE' THEN 'COMPRESS_ALL_ROW_GROUPS = OFF' ELSE 'LOB_COMPACTION = ON' END + ');' AS reorganizestr
		,'ALTER INDEX [' + I.name + '] ON ' + SCHEMA_NAME(T.schema_id) + '.' + OBJECT_NAME(T.object_id) + ' REBUILD PARTITION = ' +
		CASE WHEN S.name IS NULL THEN 'ALL' ELSE CAST(P.partition_number AS VARCHAR) END + ' WITH (SORT_IN_TEMPDB = ON,ONLINE=ON);' AS rebuildstr
		,'UPDATE STATISTICS ' + SCHEMA_NAME(T.schema_id) + '.' + OBJECT_NAME(T.object_id) AS updatestatstr
		,STATS_DATE(T.object_id,I.index_id) AS stats_time
		,P.object_id
		,P.index_id
	FROM sys.objects T
	JOIN sys.indexes I ON T.object_id = I.object_id AND T.[type] IN ('U','V')
	JOIN sys.partitions P ON I.object_id = P.object_id AND I.index_id = P.index_id
	LEFT JOIN sys.filegroups F ON I.data_space_id = F.data_space_id
	LEFT JOIN sys.partition_schemes S ON I.data_space_id = S.data_space_id
	WHERE 1 = 1
	AND P.rows > 1000
	AND I.name IS NOT NULL
)
SELECT
	 A.table_name
	,A.index_name
	,A.index_type
	,A.file_group
	,A.rows
	,CAST(D.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS frag_pct
	,CASE WHEN A.is_forced = 1 THEN N'指定(不看碎片率)'
	      ELSE N'> ' + CAST(@frag_limit AS NVARCHAR(10)) + N'%' END AS reason
	,A.stats_time
	,A.is_primary_key
	,A.partition_number
	,A.reorganizestr
	,A.rebuildstr
	,A.updatestatstr
FROM A
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), A.object_id, A.index_id, A.partition_number, 'LIMITED') D
WHERE A.is_forced = 1
   OR D.avg_fragmentation_in_percent > @frag_limit
ORDER BY A.is_forced DESC, A.table_name, A.index_name, A.partition_number;
GO


-- =========================================================================
-- 二、做完驗證：只看指定 3 個 PK 的碎片率（重組完再跑一次）
-- =========================================================================

SELECT
	 LOWER(OBJECT_NAME(I.object_id)) AS table_name
	,I.name AS index_name
	,D.partition_number
	,D.page_count
	,CAST(D.avg_fragmentation_in_percent AS DECIMAL(5,2)) AS frag_pct
	,STATS_DATE(I.object_id, I.index_id) AS stats_time
FROM sys.indexes I
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), I.object_id, I.index_id, NULL, 'LIMITED') D
WHERE I.name IN ('PK_SOCTRANS','PK_SOCTRANSPAR','PK_WINLOSE')
ORDER BY 1, 3;
GO


-- =========================================================================
-- 三、做完檢查 log（CMDK_STOCKS 是 Publisher）
-- =========================================================================

SELECT name, recovery_model_desc, log_reuse_wait_desc
FROM sys.databases
WHERE name = N'CMDK_STOCKS';    -- 長時間停在 REPLICATION = Log Reader 還在追

DBCC SQLPERF(LOGSPACE);         -- 看 CMDK_STOCKS 的 Log Space Used (%)，需 VIEW SERVER STATE
GO


/*
-- =========================================================================
-- 四、其他日（非維護日）排除這 3 個
-- =========================================================================
-- 1) 平常手動跑 Table_Index.sql 時：在 CTE 的 WHERE 加這段
--	AND NOT (DB_NAME() = 'CMDK_STOCKS'
--	         AND I.name IN ('PK_SOCTRANS','PK_SOCTRANSPAR','PK_WINLOSE'))
--
-- 2) 自動 JOB（LOKI-DB1 上是 MT_JobReorganizeIndex / MT_RebuildIndex）：
--    先看 JOB step 怎麼挑索引，再加同樣的排除條件
SELECT j.name AS job_name, j.enabled, st.step_id, st.step_name, st.database_name, st.command
FROM msdb.dbo.sysjobs j
JOIN msdb.dbo.sysjobsteps st ON st.job_id = j.job_id
WHERE j.name LIKE '%Index%' OR j.name LIKE '%Reorg%'
   OR st.command LIKE '%REORGANIZE%' OR st.command LIKE '%IndexOptimize%'
ORDER BY j.name, st.step_id;
*/
