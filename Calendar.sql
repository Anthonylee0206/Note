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

