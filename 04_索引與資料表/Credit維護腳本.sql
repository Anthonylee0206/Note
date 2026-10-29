/* =========================================================================
   【用途】       列出 SOCTRANS / SOCTRANSPAR / WINLOSE 三張表的 PK 索引重組語法（同 Table_Index.sql）。
   【使用時機】   Credit 維護日，不管碎片率有沒有高於 20% 都要重組（2026-10-30 起，ryan 指定）。
   【輸入參數】   無，在 CMDK_STOCKS 執行。
   【輸出】       同 Table_Index.sql，複製 reorganizestr 欄位執行。
   【風險/注意】  只做 REORGANIZE；其他日不要重組這三張表（容易造成 BLOCKING）。
   ========================================================================= */

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
		,'ALTER INDEX [' + I.name + '] ON ' + SCHEMA_NAME(t.schema_id) + '.' + OBJECT_NAME(T.object_id) + ' REBUILD PARTITION = ' +
		CASE WHEN S.name IS NULL THEN 'ALL' ELSE CAST(P.partition_number AS VARCHAR) END + ' WITH (SORT_IN_TEMPDB = ON,ONLINE=ON);' AS rebuildstr
		,'ALTER INDEX [' + I.name + '] ON ' + SCHEMA_NAME(t.schema_id) + '.' + OBJECT_NAME(T.object_id) + ' REORGANIZE PARTITION = ' +
		CASE WHEN S.name IS NULL THEN 'ALL' ELSE CAST(P.partition_number AS VARCHAR) END + ' WITH (' +
		CASE WHEN I.type_desc LIKE '%COLUMNSTORE' THEN 'COMPRESS_ALL_ROW_GROUPS = OFF' ELSE 'LOB_COMPACTION = ON' END + ');' reorganizestr
		,'UPDATE STATISTICS ' + OBJECT_NAME(T.object_id) AS updatestatstr
		,STATS_DATE(T.object_id,I.index_id) stats_time
		,O.create_date
		,p.object_id
		,p.index_id
	FROM sys.objects T JOIN sys.indexes I ON T.object_id = I.object_id AND T.[type] IN ('U','V')
	JOIN sys.partitions P ON I.object_id = P.object_id AND I.index_id = P.index_id
	JOIN sys.objects O ON I.object_id = O.object_id
	LEFT JOIN sys.filegroups F ON i.data_space_id = F.data_space_id
	LEFT JOIN sys.partition_schemes S ON i.data_space_id = S.data_space_id
	WHERE 1 = 1
	--AND T.name = 'mem_info'
	--AND T.name LIKE '%daily_tran%'
	AND T.name IN ('SOCTRANS','SOCTRANSPAR','WINLOSE')
	AND I.is_primary_key = 1
	AND p.rows > 1000
	AND i.name IS NOT NULL
)
SELECT --DISTINCT
	 table_name
	,index_name
	,index_type
	,file_group
	,rows
	,D.avg_fragmentation_in_percent
	,stats_time
	,create_date
	,is_unique
	,is_primary_key
	,A.partition_number
	,rebuildstr
	,reorganizestr
	,updatestatstr
FROM A
CROSS APPLY sys.dm_db_index_physical_stats(DB_ID(), A.object_id , A.index_id , A.partition_number , DEFAULT) D
WHERE 1 = 1
--AND avg_fragmentation_in_percent > 20.0
--AND stats_time < GETDATE() - 1
ORDER BY 1
