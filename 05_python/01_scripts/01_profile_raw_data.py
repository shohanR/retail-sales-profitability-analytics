"""
01_profile_raw_data.py

Purpose
-------
Profile the UCI Online Retail II raw workbook before any transformation.

The script:
1. Reads all worksheets from the raw Excel workbook.
2. Standardizes column names for profiling only.
3. Combines the worksheets.
4. Calculates structural, completeness, uniqueness, and business-quality metrics.
5. Produces a Markdown data-quality baseline report.

Important
---------
The raw source file is NEVER modified.
"""

from pathlib import Path
import pandas as pd


# ---------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------

PROJECT_ROOT = Path(__file__).resolve().parents[2]

RAW_FILE = PROJECT_ROOT / "01_data" / "01_raw" / "online_retail_II.xlsx"

REPORT_FILE = (
    PROJECT_ROOT
    / "06_docs"
    / "02_data"
    / "DATA_PROFILE_REPORT.md"
)


# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------

def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Standardize column names without changing the source workbook."""
    df = df.copy()

    df.columns = (
        df.columns
        .astype(str)
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )

    return df


def format_number(value) -> str:
    """Format numeric values for human-readable reporting."""
    if pd.isna(value):
        return "N/A"

    return f"{value:,.0f}"


def format_percentage(value) -> str:
    """Format decimal ratio as percentage."""
    if pd.isna(value):
        return "N/A"

    return f"{value:.2%}"


# ---------------------------------------------------------------------
# Load workbook
# ---------------------------------------------------------------------

if not RAW_FILE.exists():
    raise FileNotFoundError(
        f"Raw dataset not found:\n{RAW_FILE}\n\n"
        "Place online_retail_II.xlsx inside 01_data/01_raw/."
    )

print("=" * 80)
print("UCI ONLINE RETAIL II — RAW DATA PROFILING")
print("=" * 80)

print(f"\nLoading: {RAW_FILE}")

excel_file = pd.ExcelFile(RAW_FILE, engine="openpyxl")

print("\nWorksheets found:")
for sheet in excel_file.sheet_names:
    print(f"  - {sheet}")


# ---------------------------------------------------------------------
# Read all sheets
# ---------------------------------------------------------------------

frames = []

for sheet in excel_file.sheet_names:
    print(f"\nReading worksheet: {sheet}")

    sheet_df = pd.read_excel(
        RAW_FILE,
        sheet_name=sheet,
        engine="openpyxl",
    )

    sheet_df["source_sheet"] = sheet

    frames.append(sheet_df)

raw_df = pd.concat(
    frames,
    ignore_index=True,
)

raw_df = standardize_columns(raw_df)


# ---------------------------------------------------------------------
# Basic structure
# ---------------------------------------------------------------------

row_count = len(raw_df)
column_count = len(raw_df.columns)

print("\n" + "-" * 80)
print("STRUCTURE")
print("-" * 80)

print(f"Rows:       {row_count:,}")
print(f"Columns:    {column_count:,}")


# ---------------------------------------------------------------------
# Canonical column mapping
# ---------------------------------------------------------------------
#
# The UCI source uses source-specific names such as:
#   Invoice
#   Price
#   Customer ID
#
# We map them to canonical project names so downstream SQL,
# Python, Excel, and Power BI layers use a consistent vocabulary.
#
# The raw workbook itself is never modified.
# ---------------------------------------------------------------------

SOURCE_TO_CANONICAL = {
    "invoice": "invoice_no",
    "stockcode": "stock_code",
    "description": "description",
    "quantity": "quantity",
    "invoicedate": "invoice_date",
    "price": "unit_price",
    "customer_id": "customer_id",
    "country": "country",
}

missing_source_columns = (
    set(SOURCE_TO_CANONICAL)
    - set(raw_df.columns)
)

if missing_source_columns:
    raise ValueError(
        "Unexpected dataset structure. Missing source columns: "
        + ", ".join(sorted(missing_source_columns))
    )

raw_df = raw_df.rename(
    columns=SOURCE_TO_CANONICAL
)

print("\nCanonical columns:")
for column in raw_df.columns:
    print(f"  - {column}")


# ---------------------------------------------------------------------
# Data types
# ---------------------------------------------------------------------

dtype_table = pd.DataFrame(
    {
        "column": raw_df.columns,
        "dtype": raw_df.dtypes.astype(str).values,
        "non_null": raw_df.notna().sum().values,
        "null_count": raw_df.isna().sum().values,
        "null_pct": (
            raw_df.isna().mean().values
        ),
        "unique_values": raw_df.nunique(dropna=True).values,
    }
)


# ---------------------------------------------------------------------
# Missing values
# ---------------------------------------------------------------------

missing_summary = (
    raw_df.isna()
    .sum()
    .to_frame("null_count")
)

missing_summary["null_pct"] = (
    missing_summary["null_count"] / row_count
)

missing_summary = missing_summary.sort_values(
    "null_count",
    ascending=False,
)


# ---------------------------------------------------------------------
# Duplicate analysis
# ---------------------------------------------------------------------

exact_duplicate_count = int(raw_df.duplicated().sum())

invoice_duplicate_rows = (
    raw_df["invoice_no"]
    .value_counts()
)

duplicate_invoice_numbers = int(
    (invoice_duplicate_rows > 1).sum()
)


# ---------------------------------------------------------------------
# Business-rule checks
# ---------------------------------------------------------------------

cancelled_mask = (
    raw_df["invoice_no"]
    .astype(str)
    .str.upper()
    .str.startswith("C")
)

cancelled_rows = int(cancelled_mask.sum())

negative_quantity_rows = int(
    (raw_df["quantity"] < 0).sum()
)

zero_quantity_rows = int(
    (raw_df["quantity"] == 0).sum()
)

negative_price_rows = int(
    (raw_df["unit_price"] < 0).sum()
)

zero_price_rows = int(
    (raw_df["unit_price"] == 0).sum()
)

missing_customer_rows = int(
    raw_df["customer_id"].isna().sum()
)

missing_description_rows = int(
    raw_df["description"].isna().sum()
)


# ---------------------------------------------------------------------
# Date analysis
# ---------------------------------------------------------------------

raw_df["invoice_date"] = pd.to_datetime(
    raw_df["invoice_date"],
    errors="coerce",
)

min_date = raw_df["invoice_date"].min()
max_date = raw_df["invoice_date"].max()

invalid_dates = int(
    raw_df["invoice_date"].isna().sum()
)


# ---------------------------------------------------------------------
# Revenue baseline
# ---------------------------------------------------------------------

raw_df["sales_amount"] = (
    raw_df["quantity"] * raw_df["unit_price"]
)

gross_transaction_value = raw_df["sales_amount"].sum()

positive_sales_value = raw_df.loc[
    raw_df["sales_amount"] > 0,
    "sales_amount",
].sum()

negative_sales_value = raw_df.loc[
    raw_df["sales_amount"] < 0,
    "sales_amount",
].sum()


# ---------------------------------------------------------------------
# Cardinality
# ---------------------------------------------------------------------

unique_invoices = raw_df["invoice_no"].nunique(
    dropna=True
)

unique_products = raw_df["stock_code"].nunique(
    dropna=True
)

unique_customers = raw_df["customer_id"].nunique(
    dropna=True
)

unique_countries = raw_df["country"].nunique(
    dropna=True
)


# ---------------------------------------------------------------------
# Generate report
# ---------------------------------------------------------------------

report_lines = []

report_lines.append("# Raw Data Profile Report")
report_lines.append("")
report_lines.append(
    "> Automated baseline profile of the UCI Online Retail II dataset "
    "before transformation."
)
report_lines.append("")

report_lines.append("## 1. Dataset Overview")
report_lines.append("")
report_lines.append("| Metric | Value |")
report_lines.append("|---|---:|")
report_lines.append(f"| Total rows | {format_number(row_count)} |")
report_lines.append(f"| Total columns | {format_number(column_count)} |")
report_lines.append(
    f"| Worksheets | {format_number(len(excel_file.sheet_names))} |"
)
report_lines.append(
    f"| Unique invoices | {format_number(unique_invoices)} |"
)
report_lines.append(
    f"| Unique products | {format_number(unique_products)} |"
)
report_lines.append(
    f"| Unique customers | {format_number(unique_customers)} |"
)
report_lines.append(
    f"| Unique countries | {format_number(unique_countries)} |"
)
report_lines.append(
    f"| Date range | {min_date} → {max_date} |"
)
report_lines.append("")

report_lines.append("## 2. Data Quality Baseline")
report_lines.append("")
report_lines.append("| Check | Count |")
report_lines.append("|---|---:|")
report_lines.append(
    f"| Exact duplicate rows | {format_number(exact_duplicate_count)} |"
)
report_lines.append(
    f"| Invoices containing multiple line items | "
    f"{format_number(duplicate_invoice_numbers)} |"
)
report_lines.append(
    f"| Cancelled transaction rows | {format_number(cancelled_rows)} |"
)
report_lines.append(
    f"| Negative quantity rows | {format_number(negative_quantity_rows)} |"
)
report_lines.append(
    f"| Zero quantity rows | {format_number(zero_quantity_rows)} |"
)
report_lines.append(
    f"| Negative unit-price rows | {format_number(negative_price_rows)} |"
)
report_lines.append(
    f"| Zero unit-price rows | {format_number(zero_price_rows)} |"
)
report_lines.append(
    f"| Missing customer IDs | {format_number(missing_customer_rows)} |"
)
report_lines.append(
    f"| Missing descriptions | {format_number(missing_description_rows)} |"
)
report_lines.append(
    f"| Invalid invoice dates | {format_number(invalid_dates)} |"
)
report_lines.append("")

report_lines.append("## 3. Missing-Value Analysis")
report_lines.append("")
report_lines.append(
    "| Column | Missing Values | Missing % |"
)
report_lines.append("|---|---:|---:|")

for column, row in missing_summary.iterrows():
    report_lines.append(
        f"| {column} | "
        f"{format_number(row['null_count'])} | "
        f"{format_percentage(row['null_pct'])} |"
    )

report_lines.append("")

report_lines.append("## 4. Column Profile")
report_lines.append("")
report_lines.append(
    "| Column | Data Type | Non-Null | Missing | "
    "Missing % | Unique |"
)
report_lines.append(
    "|---|---|---:|---:|---:|---:|"
)

for _, row in dtype_table.iterrows():
    report_lines.append(
        f"| {row['column']} | "
        f"{row['dtype']} | "
        f"{format_number(row['non_null'])} | "
        f"{format_number(row['null_count'])} | "
        f"{format_percentage(row['null_pct'])} | "
        f"{format_number(row['unique_values'])} |"
    )

report_lines.append("")

report_lines.append("## 5. Revenue Baseline")
report_lines.append("")
report_lines.append("| Metric | Value |")
report_lines.append("|---|---:|")
report_lines.append(
    f"| Gross transaction value | "
    f"{gross_transaction_value:,.2f} |"
)
report_lines.append(
    f"| Positive transaction value | "
    f"{positive_sales_value:,.2f} |"
)
report_lines.append(
    f"| Negative transaction value | "
    f"{negative_sales_value:,.2f} |"
)
report_lines.append("")

report_lines.append("## 6. Initial Observations")
report_lines.append("")
report_lines.append(
    "- The raw workbook contains multiple worksheets that are combined "
    "for profiling only."
)
report_lines.append(
    "- Duplicate invoice numbers are expected because an invoice may "
    "contain multiple line items."
)
report_lines.append(
    "- Cancellation transactions require explicit business-rule handling "
    "rather than blind deletion."
)
report_lines.append(
    "- Missing CustomerID values require documented treatment."
)
report_lines.append(
    "- Negative quantities and negative transaction values require "
    "classification before analytical modeling."
)
report_lines.append(
    "- The raw source remains unchanged; all transformations will occur "
    "downstream."
)
report_lines.append("")

report_lines.append("## 7. Next Step")
report_lines.append("")
report_lines.append(
    "The next stage is to define the formal data-cleaning and validation "
    "rules before loading the analytical model."
)

REPORT_FILE.parent.mkdir(
    parents=True,
    exist_ok=True,
)

REPORT_FILE.write_text(
    "\n".join(report_lines),
    encoding="utf-8",
)

print("\n" + "=" * 80)
print("PROFILE COMPLETE")
print("=" * 80)

print(f"\nReport written to:")
print(REPORT_FILE)

print("\nKey metrics:")
print(f"  Rows:                 {row_count:,}")
print(f"  Columns:              {column_count:,}")
print(f"  Unique invoices:      {unique_invoices:,}")
print(f"  Unique products:      {unique_products:,}")
print(f"  Unique customers:     {unique_customers:,}")
print(f"  Unique countries:     {unique_countries:,}")
print(f"  Exact duplicates:     {exact_duplicate_count:,}")
print(f"  Cancelled rows:       {cancelled_rows:,}")
print(f"  Missing CustomerID:   {missing_customer_rows:,}")
print(f"  Negative quantities:  {negative_quantity_rows:,}")
print(f"  Negative prices:      {negative_price_rows:,}")
print(f"  Zero quantities:      {zero_quantity_rows:,}")
print(f"  Zero prices:          {zero_price_rows:,}")
print(f"  Missing descriptions: {missing_description_rows:,}")
print(f"  Invalid dates:        {invalid_dates:,}")
print(f"  Gross value:          {gross_transaction_value:,.2f}")
print(f"  Positive value:       {positive_sales_value:,.2f}")
print(f"  Negative value:       {negative_sales_value:,.2f}")