-- Full available period; positive sales before returns, GBP.
-- Label each product with its most frequent nonblank description on
-- eligible unique invoice lines. Alphabetical tie-breaker; labels do not
-- affect totals. LEFT JOIN preserves products without descriptions.
WITH unique_records AS (
    SELECT DISTINCT * FROM sales_raw
), eligible_sales AS (
    SELECT * FROM unique_records
    WHERE Quantity > 0
        AND UnitPrice > 0
        AND InvoiceNo NOT LIKE 'C%'
        AND StockCode NOT IN ('DOT', 'POST', 'M')
)
, product_totals AS (
    SELECT StockCode, SUM(Quantity * UnitPrice) AS total_value
    FROM eligible_sales
    GROUP BY StockCode
), description_counts AS (
    SELECT StockCode, TRIM(Description) AS product_name, COUNT(*) AS line_count
    FROM eligible_sales
    WHERE Description IS NOT NULL AND TRIM(Description) <> ''
    GROUP BY StockCode, TRIM(Description)
), ranked_descriptions AS (
    SELECT StockCode, product_name,
        ROW_NUMBER() OVER (
            PARTITION BY StockCode
            ORDER BY line_count DESC, product_name
        ) AS description_rank
    FROM description_counts
)
SELECT t.StockCode, COALESCE(d.product_name, '[Description unavailable]') AS product_name,
    ROUND(t.total_value, 2) AS sales_value
FROM product_totals AS t
LEFT JOIN ranked_descriptions AS d
    ON t.StockCode = d.StockCode AND d.description_rank = 1
ORDER BY t.total_value DESC, t.StockCode
LIMIT 10;
