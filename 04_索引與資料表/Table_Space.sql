SELECT
  t.NAME AS TableName,
  CASE WHEN i.name IS NULL THEN 'Heap Table' ELSE i.name END as IndexName,
  P.data_compression_desc,
  SUM(p.[Rows]) AS [Rows],
  CONVERT(DECIMAL(18,3),(SUM(a.total_pages) * 8.0) / 1024 / 1024) AS TotalSpaceGB,
  CONVERT(DECIMAL(18,3),(SUM(a.used_pages) * 8.0) / 1024 / 1024) AS UsedSpaceGB,
  CONVERT(DECIMAL(18,3),(SUM(a.data_pages) * 8.0) / 1024 / 1024) AS DataSpaceGB
	--,'RAISERROR(' + QUOTENAME(T.name,'''') + ',0,1) WITH NOWAIT;' + CHAR(10) + 'ALTER TABLE ' + QUOTENAME(T.name,'') + ' REBUILD PARTITION = ALL WITH (DATA_COMPRESSION = PAGE)' + CHAR(10) + 'GO'
FROM sys.tables t WITH (NOLOCK)
INNER JOIN sys.indexes i WITH (NOLOCK) ON t.OBJECT_ID = i.object_id AND i.index_id <= 1
INNER JOIN sys.partitions p WITH (NOLOCK) ON i.object_id = p.OBJECT_ID AND i.index_id = p.index_id
INNER JOIN sys.allocation_units a WITH (NOLOCK) ON a.container_id = p.partition_id AND a.type = CASE i.type WHEN 5 THEN 2 WHEN 1 THEN 1 WHEN 0 THEN 1 END
WHERE 1 = 1
  --AND t.NAME = 'one_wallet_transfer_all'
  AND i.OBJECT_ID > 255
  --AND p.data_compression_desc = 'NONE'
GROUP BY
	 t.NAME
	,i.name
	,p.data_compression_desc
ORDER BY 4 DESC