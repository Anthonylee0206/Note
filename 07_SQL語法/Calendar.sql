/* =========================================================================
   【用途】       用 WHILE 迴圈建立「2026 年全年連續日期表」，再用 PIVOT 轉成
                  月曆格式（一列 = 該月該週，欄位 = 週日~週六）。
   【使用時機】   需要日期維度表給報表 JOIN、月曆視圖、或教學示範 PIVOT。
                  配合同目錄 萬年曆_教學.md 一起看。
   【輸入參數】   第 12 行 @CurrentDate（起日）、第 13 行 @EndDate（迄日）— 改成想要的年份。
                  第 1 行 SET DATEFIRST 7 — 7 = 週日為一週第一天（美式）；
                  想改成週一為第一天請改 1（ISO / 歐式）。
   【輸出】       實體表 [Calendar]（Date / Year / Month / Day / Weekday / WeekNumber）；
                  最後 SELECT 輸出月曆格式：Year / Month / Sun~Sat。
   【風險/注意】 - 開頭 DROP TABLE IF EXISTS 會直接刪同名表；勿在 Prod 使用 Calendar 這麼泛用的名字。
                  - WHILE 一天一筆 INSERT，一年 365 次迴圈，大範圍（例如 10 年）會慢；
                    真要用請改 recursive CTE 或 number table。
   ========================================================================= */

SET DATEFIRST 7;

DROP TABLE IF EXISTS Calendar;
CREATE TABLE Calendar (
    [Date] DATE,
    [Year] INT,
    [Month] INT,
    [Day] INT,
    [Weekday] INT,
    [WeekNumber] INT 
);
DECLARE @CurrentDate DATE = '2026-01-01';
DECLARE @EndDate DATE = '2026-12-31';
WHILE (@CurrentDate <= @EndDate)
BEGIN
    INSERT INTO Calendar ([Date], [Year], [Month], [Day], [Weekday],[WeekNumber])
    VALUES (
        @CurrentDate, 
        YEAR(@CurrentDate),
        MONTH(@CurrentDate),
        DAY(@CurrentDate),
        DATEPART(WEEKDAY, @CurrentDate), 
        DATEPART(WEEK, @CurrentDate)
    );
    SET @CurrentDate = DATEADD(DAY, 1, @CurrentDate);
END
SELECT 
    [Year],
    [Month],
    MAX([1]) AS [Sun],    
    MAX([2]) AS [Mon],
    MAX([3]) AS [Tue],
    MAX([4]) AS [Wed],
    MAX([5]) AS [Thu],
    MAX([6]) AS [Fri],
    MAX([7]) AS [Sat]
FROM Calendar
PIVOT
(
    MAX([DAY])
    FOR [Weekday] IN ([1],[2],[3],[4],[5],[6],[7])
) AS pvt
GROUP BY
    [Year], 
    [Month], 
    [WeekNumber]
ORDER BY 
    [Year], 
    [Month], 
    [WeekNumber]

