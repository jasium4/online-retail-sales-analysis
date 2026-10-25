"""Run the final SQL files and regenerate the three result CSVs."""
from contextlib import closing
from pathlib import Path
import csv
import sqlite3

folder = Path(__file__).resolve().parent
database = folder / "retail.db"
if not database.is_file():
    raise SystemExit("Run import_data.py first.")
(folder / "results").mkdir(exist_ok=True)
with closing(sqlite3.connect(f"{database.as_uri()}?mode=ro", uri=True)) as connection:
    for name in ["top_10_products", "monthly_sales", "top_10_countries"]:
        sql = (folder / "sql" / f"{name}.sql").read_text(encoding="utf-8")
        cursor = connection.execute(sql)
        rows = cursor.fetchall()
        with (folder / "results" / f"{name}.csv").open("w", newline="", encoding="utf-8") as file:
            writer = csv.writer(file)
            writer.writerow([column[0] for column in cursor.description])
            writer.writerows(rows)
        print(f"Exported {name}.csv ({len(rows)} rows)")
