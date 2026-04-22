```sql
SELECT
	 OBJECT_NAME(p.object_id) as [資料表名稱]     -- 這是哪個大紙箱 (Table)
	,p.partition_number as [抽屜編號]             -- 這是第幾個抽屜 (Partition)
	,prv_left.value as [下限邊界值]               -- 抽屜裝的資料範圍 (例如：大於等於 5月1號)
	,prv_right.value as [上限邊界值]              -- 抽屜裝的資料範圍 (例如：小於 6月1號)
	,ps.name as [配置名稱]                        -- 負責分配房間的搬家工人 (Partition Scheme)
	,pf.name as [函數名稱]                        -- 負責寫抽屜標籤的規則 (Partition Function)
	,fg.name as [實體檔案群組]                    -- 實際上存在哪顆實體硬碟的群組 (FileGroup)
	,p.row_count as [資料筆數]                    -- 🌟重點：這個抽屜裡面現在塞了幾筆資料
	,c.name as [分割依據欄位]                     -- 我們是看哪個欄位來分類的 (例如：交易日期)

	-- 💡 以下是 DBA 的自動化魔法咒語 (預設註解起來，要用的時候解開，它會幫你把語法「印」出來)
	
	-- [一秒搬家] 把這個抽屜的資料，瞬間轉移到另一張歷史表
	--,'ALTER TABLE ' + OBJECT_NAME(p.object_id) + ' SWITCH PARTITION ' + CAST(p.partition_number AS VARCHAR(3)) + ' TO ' + OBJECT_NAME(p.object_id) + '_switch PARTITION ' + CAST(p.partition_number AS VARCHAR(3)) AS swith_str
	
	-- [合併抽屜] 把相鄰的抽屜打通合併 (通常用來整併太舊的資料，省空間)
	--,'ALTER PARTITION FUNCTION ' + QUOTENAME(pf.name,'') + '() MERGE RANGE (''' + FORMAT(CAST(prv_left.value AS DATETIME),'yyyy-MM-dd 00:00:00.000') + ''')' AS merge_str
	
	-- [擴建抽屜] 月底準備下個月的新抽屜：先指派要放在哪個實體群組，然後切出新空間
	--,'ALTER PARTITION SCHEME [' + ps.name + '] NEXT USED [' + fg.name + ']; ALTER PARTITION FUNCTION ' + QUOTENAME(pf.name,'') + '() SPLIT RANGE (''' + FORMAT(CAST(prv_left.value AS DATETIME),'yyyy-MM-dd 00:00:00.000') + ''')' AS split_str
	
	-- [一秒清空] 🌟大絕招：把這個抽屜裡的幾千萬筆資料，瞬間倒進垃圾桶 (不會卡死資料庫)
	--,'TRUNCATE TABLE ' + OBJECT_NAME(p.object_id) + ' WITH (PARTITIONS (' + CAST(p.partition_number AS VARCHAR(3)) + '))' AS truncate_str

FROM sys.dm_db_partition_stats p -- [核心系統表] 查出每個抽屜的健康狀態與資料量
INNER JOIN sys.indexes i ON i.object_id = p.object_id AND i.index_id = p.index_id -- 關聯索引資訊
INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0) AND (ic.index_id=i.index_id AND ic.object_id=i.object_id)
INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id -- 抓出是用哪個欄位當作分類標籤
INNER JOIN sys.partition_schemes ps ON ps.data_space_id = i.data_space_id -- 抓出配置圖
INNER JOIN sys.partition_functions pf ON ps.function_id = pf.function_id -- 抓出切分規則
INNER JOIN sys.destination_data_spaces dds ON dds.partition_scheme_id = ps.data_space_id AND  dds.destination_id = p.partition_number
INNER JOIN sys.filegroups fg ON fg.data_space_id = dds.data_space_id -- 抓出對應的實體硬碟(群組)
LEFT JOIN sys.partition_range_values prv_right ON prv_right.function_id = ps.function_id AND prv_right.boundary_id = p.partition_number -- 找抽屜的上限值
LEFT JOIN sys.partition_range_values prv_left ON prv_left.function_id = ps.function_id AND prv_left.boundary_id = p.partition_number - 1 -- 找抽屜的下限值

WHERE 1 = 1
AND p.index_id < 2 -- 只看「叢集索引(實體資料)」或「沒有索引(Heap)」，不看其他多餘的分身小冊子

-- 🔍 這裡是你平常查資料可以自己打開的過濾器 (依需求把註解拿掉)
--AND ps.name IN ('Psh_owt','Psh_tck') -- 只看特定的配置圖
--AND row_count > 0 -- 只顯示裡面有裝東西的抽屜 (空抽屜不看)
--AND partition_number < 22 -- 只看某個編號以前的抽屜
--AND fg.name = 'FG_LOG_202107' -- 只看放在特定硬碟群組的資料
--AND OBJECT_NAME(p.object_id) = 'ticket_all' -- 只看「特定一張大紙箱(Table)」的狀況
--AND OBJECT_NAME(p.object_id) = 'one_wallet_transfer_all'

ORDER BY 1,2 -- 按照 表格名稱、抽屜編號 乖乖排好顯示
GO

/*
-- 另外附贈的小工具：
-- 快速查看每個「切分規則」目前切到的「最大邊界值」
-- (也就是用來檢查最新的一個抽屜已經開到哪一天了，看需不需要趕快擴建)
SELECT f.name AS [函數名稱], MAX(v.value) AS [最新邊界值]
FROM sys.partition_functions f 
JOIN sys.partition_range_values v ON f.function_id = v.function_id
GROUP BY f.name
*/
```