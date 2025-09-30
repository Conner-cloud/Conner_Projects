CREATE VIEW vw_EVStocks AS
WITH Total_Stock AS (
    SELECT
        region,
        year,
        unit,
        SUM(Val) AS Total_Stock
    FROM EVSales.dbo.[IEA Global EV Data 2024]
    WHERE unit = 'Vehicles'
    GROUP BY region, year, unit
),
LY_Stock AS (
    SELECT
        region,
        year,
        unit,
        Total_Stock,
        LAG(Total_Stock, 1, NULL) OVER(PARTITION BY region ORDER BY year) AS LY_Stock
    FROM Total_Stock
)
SELECT
    region,
    year,
    unit,
    Total_Stock,
    LY_Stock,
    (Total_Stock - LY_Stock) AS YOY_Stock_Difference,
    (Total_Stock - LY_Stock) * 1.0 / NULLIF(LY_Stock, 0) AS Percent_Change_Stock
FROM LY_Stock
GO

CREATE VIEW vw_EVShare AS
WITH Max_Share AS (
    SELECT
        region AS region2,
        year AS year2,
        unit AS unit2,
        MAX(Val) AS Max_Share
    FROM EVSales.dbo.[IEA Global EV Data 2024]
    WHERE unit = 'percent'
    GROUP BY region, year, unit
),
LY_Share AS (
    SELECT
        region2,
        year2,
        unit2,
        Max_Share,
        LAG(Max_Share, 1, NULL) OVER(PARTITION BY region2 ORDER BY year2) AS LY_Share
    FROM Max_Share
)
SELECT
    region2,
    year2,
    unit2,
    Max_Share,
    LY_Share,
    (Max_Share - LY_Share) AS YOY_Share_Difference,
    (Max_Share - LY_Share) * 1.0 / NULLIF(Max_Share, 0) AS Percent_Change_Share
FROM LY_Share
GO

CREATE VIEW vw_EVdata AS
SELECT
	region,
	year,
	Total_Stock,
	LY_Stock,
	YOY_Stock_Difference,
	Percent_Change_Stock,
	Max_Share,
	LY_Share,
	YOY_Share_Difference,
	Percent_Change_Share
FROM vw_EVStocks
LEFT JOIN vw_EVShare
ON vw_EVStocks.region = vw_EVShare.region2 AND vw_EVStocks.year = vw_EVShare.year2
GO

SELECT * FROM vw_EVdata