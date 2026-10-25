-- Dataset overview: row count and date range
SELECT COUNT(*) AS total_rows, MIN(InvoiceDate) AS first_invoice, MAX(InvoiceDate) AS last_invoice
FROM sales_raw;
