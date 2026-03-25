SELECT
	 OBJECT_NAME(p.object_id) as TableName
	,p.partition_number as PartitionNumber
	,prv_left.value as LowerBoundary
	,prv_right.value as UpperBoundary
	,ps.name as PartitionScheme
	,pf.name as PartitionFunction
	,fg.name as FileGroupName
	,p.row_count
	,c.name as partition_column
	--,'ALTER TABLE ' + OBJECT_NAME(p.object_id) + ' SWITCH PARTITION ' + CAST(p.partition_number AS VARCHAR(3)) + ' TO ' + OBJECT_NAME(p.object_id) + '_switch PARTITION ' + CAST(p.partition_number AS VARCHAR(3)) AS swith_str
	--,'ALTER PARTITION FUNCTION ' + QUOTENAME(pf.name,'') + '() MERGE RANGE (''' + FORMAT(CAST(prv_left.value AS DATETIME),'yyyy-MM-dd 00:00:00.000') + ''')' AS merge_str
	--,'ALTER PARTITION SCHEME [' + ps.name + '] NEXT USED [' + fg.name + ']; ALTER PARTITION FUNCTION ' + QUOTENAME(pf.name,'') + '() SPLIT RANGE (''' + FORMAT(CAST(prv_left.value AS DATETIME),'yyyy-MM-dd 00:00:00.000') + ''')' AS split_str
	--,'TRUNCATE TABLE ' + OBJECT_NAME(p.object_id) + ' WITH (PARTITIONS (' + CAST(p.partition_number AS VARCHAR(3)) + '))' AS truncate_str
	--INTO ##TEMP
FROM sys.dm_db_partition_stats p
INNER JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id
INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0) AND (ic.index_id=i.index_id AND ic.object_id=i.object_id)
INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id
INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND  dds.destination_id = p.partition_number
INNER JOIN sys.filegroups fg ON fg.data_space_id = dds.data_space_id
LEFT JOIN sys.partition_range_values prv_right ON prv_right.function_id = ps.function_id AND prv_right.boundary_id = p.partition_number
LEFT JOIN sys.partition_range_values prv_left ON prv_left.function_id = ps.function_id AND prv_left.boundary_id = p.partition_number - 1
WHERE 1 = 1
AND p.index_id < 2
--AND ps.name IN ('Psh_owt','Psh_tck')
--AND row_count > 0
--AND partition_number < 22
--AND fg.name = 'FG_LOG_202107'
--AND OBJECT_NAME(p.object_id) = 'ticket_all'
--AND OBJECT_NAME(p.object_id) = 'one_wallet_transfer_all'
ORDER BY 1,2
GO

/*

SELECT f.name,MAX(v.value) max_value
FROM sys.partition_functions f JOIN sys.partition_range_values v
ON f.function_id = v.function_id
GROUP BY f.name

*/