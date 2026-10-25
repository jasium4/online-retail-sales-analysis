-- ONLINE RETAIL: SALES ANALYSIS
--
-- Questions:
-- Which product codes generated the most sales value?
-- How did sales value change by month?
--
-- Line value = Quantity * UnitPrice, in GBP.
-- Sales value = sum of line values.
-- We analyse positive sales before returns, not profit.
-- These queries do not modify the original data.


-- 1. INITIAL PRODUCT RANKING
-- Exclude cancellations and nonpositive quantities/prices.
-- Group by StockCode because descriptions can vary.

SELECT
    StockCode,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM sales_raw
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
GROUP BY StockCode
ORDER BY
    SUM(Quantity * UnitPrice) DESC,
    StockCode
LIMIT 10;


-- 2. INVESTIGATE UNFAMILIAR CODES
-- Inspect codes encountered while exploring the rankings.

SELECT DISTINCT
    StockCode,
    Description
FROM sales_raw
WHERE StockCode IN ('DOT', 'POST', 'M')
ORDER BY StockCode, Description;

-- Findings:
-- DOT = DOTCOM POSTAGE.
-- POST = POSTAGE.
-- M = Manual.
-- DOT and POST also have records with missing descriptions.
--
-- Decision:
-- Exclude postage from the product ranking.
-- Exclude M because "Manual" does not identify a specific product.


-- 3. PRODUCT RANKING WITH CODE EXCLUSIONS
-- This intermediate ranking still includes repeated records.

SELECT
    StockCode,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM sales_raw
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M')
GROUP BY StockCode
ORDER BY
    SUM(Quantity * UnitPrice) DESC,
    StockCode
LIMIT 10;

-- Finding:
-- Code 22423 ranks first, with GBP 174,484.74.
-- Next: inspect descriptions associated with this code.


-- 4. IDENTIFY THE LEADING PRODUCT

SELECT DISTINCT
    StockCode,
    Description
FROM sales_raw
WHERE StockCode = '22423'
ORDER BY Description;

-- Finding:
-- The code has a product description and entries labelled
-- "faulty" or "damages".
-- Next: check whether those unusual entries affect the ranking.


-- 5. INSPECT FAULTY/DAMAGED ENTRIES

SELECT
    Description,
    Quantity,
    UnitPrice
FROM sales_raw
WHERE StockCode = '22423'
    AND Description IN ('faulty', 'damages')
ORDER BY Description, Quantity;

-- Findings:
-- "faulty": Quantity = -13, UnitPrice = 0.
-- "damages": Quantity = -21 and -19, UnitPrice = 0.
--
-- Interpretation:
-- These appear consistent with stock adjustments, although their
-- exact business purpose is unconfirmed.
--
-- Effect on the analysis:
-- Our positive-quantity and positive-price filters exclude them.


-- 6. CHECK FOR FULLY IDENTICAL RECORDS
-- Compare the total row count with unique combinations
-- of all eight original columns.

SELECT
    (SELECT COUNT(*) FROM sales_raw) AS total_rows,
    (
        SELECT COUNT(*)
        FROM (
            SELECT DISTINCT *
            FROM sales_raw
        ) AS unique_records
    ) AS unique_rows;

-- Findings:
-- Total rows: 541,909.
-- Unique rows: 536,641.
-- Extra copies beyond the first occurrence: 5,268.


-- 7. INSPECT EXAMPLES OF REPEATED RECORDS
-- Match on all eight original columns.
-- Ordering makes the selection of examples reproducible.

SELECT
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country,
    COUNT(*) AS copies
FROM sales_raw
GROUP BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
HAVING COUNT(*) > 1
ORDER BY
    InvoiceNo,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    UnitPrice,
    CustomerID,
    Country
LIMIT 5;

-- Repetition is confirmed, but its cause is unknown.
-- Identical records could be accidental copies or legitimate lines.


-- 8. MEASURE THE EFFECT OF REPEATED RECORDS
-- Apply the same sales filters to both versions.

WITH unique_records AS (
    SELECT DISTINCT *
    FROM sales_raw
)
SELECT
    'All records' AS version,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM sales_raw
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M')

UNION ALL

SELECT
    'Unique records only' AS version,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM unique_records
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M');

-- Findings:
-- All records:         GBP 10,304,223.62.
-- Unique records only: GBP 10,280,009.88.
-- Difference:          GBP     24,213.74.
-- Reduction: approximately 0.235% of the all-records total.
--
-- Decision:
-- Retain one copy of each identical record for the main analysis.
-- This is an assumption and may remove legitimate repeated lines.
-- Preserve sales_raw and this comparison for transparency.


-- 9. FINAL PRODUCT RANKING
-- Apply the documented sales filters and code exclusions
-- to one copy of each fully identical record.
-- Round totals for display; rank by the unrounded sum.

WITH unique_records AS (
    SELECT DISTINCT *
    FROM sales_raw
)
SELECT
    StockCode,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM unique_records
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M')
GROUP BY StockCode
ORDER BY
    SUM(Quantity * UnitPrice) DESC,
    StockCode
LIMIT 10;

-- Finding:
-- Code 22423 remains the highest-ranked product code.
-- Sales value before returns: GBP 174,156.54.
-- Keeping unique records reduced its total from GBP 174,484.74
-- by GBP 328.20, without changing its first-place position.
--
-- Exported result: results/top_10_products.csv.


-- 10. PREVIEW MONTH EXTRACTION
-- Convert invoice timestamps into year-month labels.
-- Example: 2010-12-01 08:26:00 becomes 2010-12.
-- This preview does not calculate monthly totals.

SELECT
    InvoiceDate,
    strftime('%Y-%m', InvoiceDate) AS sales_month
FROM sales_raw
LIMIT 5;


-- 11. MONTHLY SALES VALUE
-- Use unique records and the established sales filters.
-- Exclude December 2011 because data ends on 9 December.

WITH unique_records AS (
    SELECT DISTINCT *
    FROM sales_raw
)
SELECT
    strftime('%Y-%m', InvoiceDate) AS sales_month,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM unique_records
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M')
    AND InvoiceDate < '2011-12-01'
GROUP BY strftime('%Y-%m', InvoiceDate)
ORDER BY sales_month;

-- Findings:
-- November 2011 had the highest sales value: GBP 1,453,295.98.
-- February 2011 had the lowest: GBP 508,081.54.
-- Sales increased each month from August through November 2011.
-- These results show a pattern, not its cause.


-- 12. TOP 10 INTERNATIONAL MARKETS BY SALES VALUE
-- Use unique records and the same sales filters as the product ranking.
-- Exclude the UK to focus on international markets.
-- Country represents the customer's country, not necessarily delivery location.
-- Use the full available period: 1 December 2010 to 9 December 2011.
-- Unlike query 11, this comparison is not between monthly totals.

WITH unique_records AS (
    SELECT DISTINCT *
    FROM sales_raw
)
SELECT
    Country,
    ROUND(SUM(Quantity * UnitPrice), 2) AS sales_value
FROM unique_records
WHERE Quantity > 0
    AND UnitPrice > 0
    AND InvoiceNo NOT LIKE 'C%'
    AND StockCode NOT IN ('DOT', 'POST', 'M')
    AND Country <> 'United Kingdom'
GROUP BY Country
ORDER BY
    SUM(Quantity * UnitPrice) DESC,
    Country
LIMIT 10;

-- Findings:
-- Netherlands ranked first: GBP 283,889.34.
-- Ireland (labelled EIRE) ranked second: GBP 276,090.86.
-- Germany ranked third: GBP 205,381.15.
-- Values represent positive sales before returns,
-- using unique records across the full available period.

-- LIMITATIONS
-- Returns are excluded rather than deducted.
-- Product costs are unavailable, so profit cannot be calculated.
-- Only selected unusual codes have been investigated.
-- Identical records are treated as duplicates for the main analysis;
-- their business meaning cannot be confirmed from this dataset alone.
-- The available period includes an incomplete December 2011.