"""Import the UCI workbook into SQLite. Run before export_results.py."""
from contextlib import closing
from pathlib import Path
import sqlite3
import pandas as pd

folder = Path(__file__).resolve().parent
source = folder / "Online Retail.xlsx"
database = folder / "retail.db"
if not source.is_file():
    raise SystemExit("Download Online Retail.xlsx from UCI and place it beside this script. See README.md.")

print("Reading Excel file...")
sales = pd.read_excel(source, dtype={
    "InvoiceNo": "string", "StockCode": "string", "CustomerID": "string"
})
expected = ["InvoiceNo", "StockCode", "Description", "Quantity",
            "InvoiceDate", "UnitPrice", "CustomerID", "Country"]
if list(sales.columns) != expected:
    raise ValueError(f"Unexpected workbook columns: {list(sales.columns)}")

# Re-running replaces sales_raw; it does not append duplicate imports.
with closing(sqlite3.connect(database)) as connection:
    sales.to_sql("sales_raw", connection, if_exists="replace", index=False)
    connection.commit()
    count = connection.execute("SELECT COUNT(*) FROM sales_raw").fetchone()[0]
print(f"Imported {count:,} rows into {database.name}")
