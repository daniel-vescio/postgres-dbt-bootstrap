"""Load every CSV in data/ into the bronze schema.

Each file becomes a table named after the file (Customer Extract.csv -> bronze.customer_extract).
Tables are dropped and reloaded each run. Every column lands as text, and typing happens in silver.
Connection settings come from .env, with the same defaults as profiles.yml.
"""

import csv
import os
import re
from pathlib import Path

import psycopg2
from dotenv import load_dotenv

ROOT = Path(__file__).resolve().parent.parent


def snake_case(name):
    name = re.sub(r"([a-z0-9])([A-Z])", r"\1_\2", name.strip())
    name = re.sub(r"[^0-9a-zA-Z]+", "_", name).strip("_").lower()
    return f"_{name}" if name[:1].isdigit() else name


def column_names(header):
    """snake_case each header, filling blanks and numbering repeats."""
    names = []
    for i, raw in enumerate(header, start=1):
        name = snake_case(raw) or f"column_{i}"
        while name in names:
            name += f"_{i}"
        names.append(name)
    return names


def load(cur, path):
    name = snake_case(path.stem)
    table = f'bronze."{name}"'
    # utf-8-sig strips the byte-order mark Excel adds to CSV exports
    with path.open(newline="", encoding="utf-8-sig") as f:
        columns = [f'"{c}"' for c in column_names(next(csv.reader(f)))]
        f.seek(0)
        cur.execute(f"drop table if exists {table}")
        cur.execute(
            f"create table {table} ({', '.join(c + ' text' for c in columns)}, "
            "_loaded_at timestamptz not null default now())"
        )
        cur.copy_expert(
            f"copy {table} ({', '.join(columns)}) from stdin with (format csv, header true)", f
        )
    cur.execute(f"select count(*) from {table}")
    return f"bronze.{name}", cur.fetchone()[0]


def main():
    files = sorted((ROOT / "data").glob("*.csv"))
    if not files:
        print("No CSVs in data/ yet.")
        return

    load_dotenv(ROOT / ".env")
    conn = psycopg2.connect(
        host=os.getenv("POSTGRES_HOST", "localhost"),
        port=os.getenv("POSTGRES_PORT", "5432"),
        user=os.getenv("POSTGRES_USER", "dbt"),
        password=os.getenv("POSTGRES_PASSWORD", "dbt"),
        dbname=os.getenv("POSTGRES_DB", "poc"),
    )
    with conn, conn.cursor() as cur:
        cur.execute("create schema if not exists bronze")
        for path in files:
            table, rows = load(cur, path)
            print(f"{table:<45} {rows:>10,} rows  <- {path.name}")
    conn.close()
    print("\nAdd new tables to models/bronze/_sources.yml to use them in models.")


if __name__ == "__main__":
    main()
