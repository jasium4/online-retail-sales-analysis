-- Complete months only: December 2010 through November 2011.
-- Positive sales before returns, GBP. December 2011 is excluded.
WITH unique_records AS (
    SELECT DISTINCT * FROM sales_raw
), eligible_sales AS (
    SELECT * FROM unique_records
    WHERE Quantity > 0
        AND UnitPrice > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND StockCode NOT IN ('DOT', 'POST', 'M')
)
SELECT strftime('%Y-%m', InvoiceDate) AS sales_month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM eligible_sales
WHERE InvoiceDate >= '2010-12-01' AND InvoiceDate < '2011-12-01'
GROUP BY strftime('%Y-%m', InvoiceDate)
ORDER BY sales_month;
