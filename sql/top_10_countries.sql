-- Full available period; positive sales before returns, GBP.
-- Country means customer residence. EIRE is the source label for Ireland.
WITH unique_records AS (
    SELECT DISTINCT * FROM sales_raw
), eligible_sales AS (
    SELECT * FROM unique_records
    WHERE Quantity > 0
        AND UnitPrice > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND StockCode NOT IN ('DOT', 'POST', 'M')
)
SELECT Country, ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM eligible_sales
WHERE Country <> 'United Kingdom'
GROUP BY Country
ORDER BY SUM(Quantity * UnitPrice) DESC, Country
LIMIT 10;
