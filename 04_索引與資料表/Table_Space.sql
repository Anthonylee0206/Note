/* =========================================================================
   【用途】       列出資料庫內所有使用者資料表的「筆數 + 空間用量 + 壓縮狀態」。
   【使用時機】   盤點肥大表、評估是否要做 PAGE 壓縮、磁碟快滿時找目標。
   【輸入參數】   第 15 行 t.NAME = '...' 可取消註解鎖定單表；
                  第 17 行 p.data_compression_desc = 'NONE' 可取消註解只看未壓縮；
                  第 9 行被註解掉的那一行可產生 ALTER TABLE REBUILD ... DATA_COMPRESSION=PAGE 語法產生器。
   【輸出】       TableName / IndexName / 壓縮描述 / Rows / TotalSpaceGB / UsedSpaceGB / DataSpaceGB
                  預設依 Rows 由大到小排序。
   【風險/注意】  純查詢，全表帶 WITH (NOLOCK)，Prod 可直接跑。
                  統計範圍僅含 Heap 或 Clustered Index（index_id ≤ 1），不含非叢集索引額外空間。
   ========================================================================= */

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