"""
02_clean_data.py

Purpose
-------
Transform the raw UCI Online Retail II workbook into a reproducible,
analytics-ready transaction layer and dimensional exports.

Pipeline
--------
Raw workbook
    -> Load
    -> Canonicalize columns
    -> Normalize values
    -> Detect exact duplicates
    -> Classify transactions
    -> Resolve product descriptions
    -> Apply data-quality flags
    -> Calculate sales amount
    -> Export fact and dimension tables
    -> Generate cleaning audit report

Design principles
-----------------
- Raw data is never modified.
- No customer IDs are fabricated.
- Returns/cancellations are preserved.
- Questionable records are flagged rather than silently deleted.
- Exact duplicate source rows are removed from the analytical layer
  only after being explicitly identified.
- Every important transformation is documented in the audit report.
"""

from pathlib import Path

import pandas as pd


# =============================================================================
# Configuration
# =============================================================================

PROJECT_ROOT = Path(__file__).resolve().parents[2]

RAW_FILE = (
    PROJECT_ROOT
    / "01_data"
    / "01_raw"
    / "online_retail_II.xlsx"
)

PROCESSED_DIR = (
    PROJECT_ROOT
    / "01_data"
    / "02_processed"
)

REPORT_FILE = (
    PROJECT_ROOT
    / "06_docs"
    / "02_data"
    / "DATA_CLEANING_REPORT.md"
)


# =============================================================================
# Source -> canonical column mapping
# =============================================================================

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


# =============================================================================
# Helpers
# =============================================================================

def standardize_columns(df: pd.DataFrame) -> pd.DataFrame:
    """Standardize source column names."""
    df = df.copy()

    df.columns = (
        df.columns
        .astype(str)
        .str.strip()
        .str.lower()
        .str.replace(" ", "_", regex=False)
    )

    return df


def normalize_text(series: pd.Series) -> pd.Series:
    """Normalize text while preserving missing values."""
    return (
        series
        .astype("string")
        .str.strip()
        .replace("", pd.NA)
    )


def safe_int(value) -> int:
    """Return an integer for report generation."""
    return int(value)


def pct(value: int, denominator: int) -> str:
    """Return a formatted percentage."""
    if denominator == 0:
        return "0.00%"

    return f"{value / denominator:.2%}"


# =============================================================================
# Validate source
# =============================================================================

if not RAW_FILE.exists():
    raise FileNotFoundError(
        f"Raw dataset not found:\n{RAW_FILE}\n\n"
        "Place online_retail_II.xlsx inside 01_data/01_raw/."
    )

PROCESSED_DIR.mkdir(
    parents=True,
    exist_ok=True,
)

REPORT_FILE.parent.mkdir(
    parents=True,
    exist_ok=True,
)


# =============================================================================
# Load workbook
# =============================================================================

print("=" * 80)
print("UCI ONLINE RETAIL II — DATA CLEANING PIPELINE")
print("=" * 80)

print(f"\nLoading: {RAW_FILE}")

excel_file = pd.ExcelFile(
    RAW_FILE,
    engine="openpyxl",
)

print("\nWorksheets:")

for sheet in excel_file.sheet_names:
    print(f"  - {sheet}")


frames = []

for sheet in excel_file.sheet_names:

    print(f"\nReading: {sheet}")

    df = pd.read_excel(
        RAW_FILE,
        sheet_name=sheet,
        engine="openpyxl",
    )

    df = standardize_columns(df)

    missing_columns = (
        set(SOURCE_TO_CANONICAL)
        - set(df.columns)
    )

    if missing_columns:
        raise ValueError(
            f"Worksheet '{sheet}' is missing columns: "
            + ", ".join(sorted(missing_columns))
        )

    df = df.rename(
        columns=SOURCE_TO_CANONICAL
    )

    df["source_sheet"] = sheet

    frames.append(df)


raw_df = pd.concat(
    frames,
    ignore_index=True,
)


raw_row_count = len(raw_df)

print(
    f"\nRaw rows loaded: {raw_row_count:,}"
)


# =============================================================================
# Normalize data types and text
# =============================================================================

print("\nNormalizing data types and text...")

raw_df["invoice_no"] = normalize_text(
    raw_df["invoice_no"]
)

raw_df["stock_code"] = normalize_text(
    raw_df["stock_code"]
)

raw_df["description"] = normalize_text(
    raw_df["description"]
)

raw_df["country"] = normalize_text(
    raw_df["country"]
)

raw_df["customer_id"] = pd.to_numeric(
    raw_df["customer_id"],
    errors="coerce",
)

raw_df["quantity"] = pd.to_numeric(
    raw_df["quantity"],
    errors="coerce",
)

raw_df["unit_price"] = pd.to_numeric(
    raw_df["unit_price"],
    errors="coerce",
)

raw_df["invoice_date"] = pd.to_datetime(
    raw_df["invoice_date"],
    errors="coerce",
)


# =============================================================================
# Exact duplicate detection
# =============================================================================

print("\nDetecting exact duplicate source rows...")

dedupe_columns = [
    "invoice_no",
    "stock_code",
    "description",
    "quantity",
    "invoice_date",
    "unit_price",
    "customer_id",
    "country",
]

duplicate_mask = raw_df.duplicated(
    subset=dedupe_columns,
    keep="first",
)

duplicate_count = int(
    duplicate_mask.sum()
)

raw_df["is_duplicate"] = duplicate_mask


# =============================================================================
# Remove exact duplicates from analytical layer
# =============================================================================

clean_df = raw_df.loc[
    ~raw_df["is_duplicate"]
].copy()

rows_after_deduplication = len(clean_df)


# =============================================================================
# Transaction classification
# =============================================================================

print("\nClassifying transactions...")

invoice_text = (
    clean_df["invoice_no"]
    .fillna("")
    .str.upper()
)

clean_df["is_cancelled"] = (
    invoice_text.str.startswith("C")
)

clean_df["is_return"] = (
    clean_df["quantity"] < 0
)

clean_df["is_negative_price"] = (
    clean_df["unit_price"] < 0
)

clean_df["is_zero_price"] = (
    clean_df["unit_price"] == 0
)

clean_df["transaction_type"] = "Sale"

clean_df.loc[
    clean_df["is_return"],
    "transaction_type",
] = "Return"

clean_df.loc[
    clean_df["is_cancelled"],
    "transaction_type",
] = "Cancellation"

clean_df.loc[
    clean_df["invoice_no"].isna(),
    "transaction_type",
] = "Invalid"


# =============================================================================
# Customer quality classification
# =============================================================================

print("\nClassifying customer records...")

clean_df["customer_status"] = "Identified"

clean_df.loc[
    clean_df["customer_id"].isna(),
    "customer_status",
] = "Unknown"


# =============================================================================
# Product description resolution
# =============================================================================

print("\nResolving missing product descriptions...")

product_description_map = (
    clean_df.loc[
        clean_df["stock_code"].notna()
        & clean_df["description"].notna(),
        [
            "stock_code",
            "description",
        ],
    ]
    .drop_duplicates(
        subset=["stock_code"]
    )
    .set_index("stock_code")["description"]
)

missing_description_before = int(
    clean_df["description"].isna().sum()
)

clean_df["description"] = (
    clean_df["description"]
    .fillna(
        clean_df["stock_code"].map(
            product_description_map
        )
    )
)

missing_description_after = int(
    clean_df["description"].isna().sum()
)

clean_df["description_status"] = "Valid"

clean_df.loc[
    clean_df["description"].isna(),
    "description_status",
] = "Unknown"


# =============================================================================
# Price quality classification
# =============================================================================

clean_df["price_quality_status"] = "Valid"

clean_df.loc[
    clean_df["unit_price"] == 0,
    "price_quality_status",
] = "Zero Price"

clean_df.loc[
    clean_df["unit_price"] < 0,
    "price_quality_status",
] = "Negative Price"

clean_df.loc[
    clean_df["unit_price"].isna(),
    "price_quality_status",
] = "Missing Price"


# =============================================================================
# Date quality
# =============================================================================

clean_df["date_quality_status"] = "Valid"

clean_df.loc[
    clean_df["invoice_date"].isna(),
    "date_quality_status",
] = "Invalid Date"


# =============================================================================
# Sales calculation
# =============================================================================

print("\nCalculating transaction value...")

clean_df["sales_amount"] = (
    clean_df["quantity"]
    * clean_df["unit_price"]
)


# =============================================================================
# Analytical flags
# =============================================================================

clean_df["is_valid_invoice"] = (
    clean_df["invoice_no"].notna()
)

clean_df["is_valid_product"] = (
    clean_df["stock_code"].notna()
)

clean_df["is_valid_date"] = (
    clean_df["invoice_date"].notna()
)

clean_df["is_analytically_usable"] = (
    clean_df["is_valid_invoice"]
    & clean_df["is_valid_product"]
    & clean_df["is_valid_date"]
)


# =============================================================================
# Final fact table
# =============================================================================

fact_columns = [
    "invoice_no",
    "stock_code",
    "description",
    "quantity",
    "invoice_date",
    "unit_price",
    "customer_id",
    "country",
    "sales_amount",
    "transaction_type",
    "is_cancelled",
    "is_return",
    "customer_status",
    "description_status",
    "price_quality_status",
    "date_quality_status",
    "is_analytically_usable",
    "source_sheet",
]

fact_sales = clean_df[
    fact_columns
].copy()


# =============================================================================
# Customer dimension
# =============================================================================

print("\nBuilding customer dimension...")

customer_source = clean_df.loc[
    clean_df["customer_id"].notna(),
    [
        "customer_id",
        "country",
    ],
].copy()

dim_customer = (
    customer_source
    .sort_values(
        [
            "customer_id",
            "country",
        ]
    )
    .drop_duplicates(
        subset=["customer_id"],
        keep="first",
    )
)

dim_customer["customer_id"] = (
    dim_customer["customer_id"]
    .astype("Int64")
)

dim_customer = dim_customer[
    [
        "customer_id",
        "country",
    ]
]


# =============================================================================
# Product dimension
# =============================================================================

print("Building product dimension...")

dim_product = (
    clean_df.loc[
        clean_df["stock_code"].notna(),
        [
            "stock_code",
            "description",
        ],
    ]
    .sort_values(
        [
            "stock_code",
            "description",
        ]
    )
    .drop_duplicates(
        subset=["stock_code"],
        keep="first",
    )
)


# =============================================================================
# Country dimension
# =============================================================================

print("Building country dimension...")

dim_country = (
    clean_df.loc[
        clean_df["country"].notna(),
        [
            "country",
        ],
    ]
    .drop_duplicates()
    .sort_values("country")
    .reset_index(drop=True)
)

dim_country.insert(
    0,
    "country_key",
    range(
        1,
        len(dim_country) + 1,
    ),
)


# =============================================================================
# Date dimension
# =============================================================================

print("Building date dimension...")

date_values = (
    clean_df.loc[
        clean_df["invoice_date"].notna(),
        "invoice_date",
    ]
    .dt.normalize()
    .drop_duplicates()
    .sort_values()
)

dim_date = pd.DataFrame(
    {
        "date": date_values,
    }
)

dim_date["date_key"] = (
    dim_date["date"]
    .dt.strftime("%Y%m%d")
    .astype(int)
)

dim_date["year"] = (
    dim_date["date"].dt.year
)

dim_date["quarter"] = (
    dim_date["date"].dt.quarter
)

dim_date["month"] = (
    dim_date["date"].dt.month
)

dim_date["month_name"] = (
    dim_date["date"].dt.month_name()
)

dim_date["week"] = (
    dim_date["date"].dt.isocalendar().week
    .astype(int)
)

dim_date["day"] = (
    dim_date["date"].dt.day
)

dim_date["day_name"] = (
    dim_date["date"].dt.day_name()
)

dim_date = dim_date[
    [
        "date_key",
        "date",
        "year",
        "quarter",
        "month",
        "month_name",
        "week",
        "day",
        "day_name",
    ]
]


# =============================================================================
# Export
# =============================================================================

print("\nExporting processed datasets...")

fact_sales.to_csv(
    PROCESSED_DIR / "fact_sales.csv",
    index=False,
)

dim_customer.to_csv(
    PROCESSED_DIR / "dim_customer.csv",
    index=False,
)

dim_product.to_csv(
    PROCESSED_DIR / "dim_product.csv",
    index=False,
)

dim_country.to_csv(
    PROCESSED_DIR / "dim_country.csv",
    index=False,
)

dim_date.to_csv(
    PROCESSED_DIR / "dim_date.csv",
    index=False,
)


# =============================================================================
# Audit metrics
# =============================================================================

cancelled_rows = int(
    clean_df["is_cancelled"].sum()
)

return_rows = int(
    clean_df["is_return"].sum()
)

missing_customer_rows = int(
    clean_df["customer_id"].isna().sum()
)

zero_price_rows = int(
    clean_df["is_zero_price"].sum()
)

negative_price_rows = int(
    clean_df["is_negative_price"].sum()
)

invalid_date_rows = int(
    clean_df["invoice_date"].isna().sum()
)

unknown_description_rows = int(
    clean_df["description"].isna().sum()
)

analytically_usable_rows = int(
    clean_df["is_analytically_usable"].sum()
)

net_sales = clean_df[
    "sales_amount"
].sum()

positive_sales = clean_df.loc[
    clean_df["sales_amount"] > 0,
    "sales_amount",
].sum()

negative_sales = clean_df.loc[
    clean_df["sales_amount"] < 0,
    "sales_amount",
].sum()


# =============================================================================
# Cleaning report
# =============================================================================

report = []

report.append("# Data Cleaning Report")
report.append("")
report.append(
    "> Automated cleaning and transformation audit for the "
    "UCI Online Retail II dataset."
)
report.append("")

report.append("## 1. Processing Summary")
report.append("")
report.append("| Metric | Value |")
report.append("|---|---:|")
report.append(
    f"| Raw rows | {raw_row_count:,} |"
)
report.append(
    f"| Duplicate transaction rows removed | {duplicate_count:,} |"
)
report.append(
    f"| Rows after deduplication | "
    f"{rows_after_deduplication:,} |"
)
report.append(
    f"| Analytically usable rows | "
    f"{analytically_usable_rows:,} |"
)
report.append("")

report.append("## 2. Transaction Classification")
report.append("")
report.append("| Classification | Rows |")
report.append("|---|---:|")
report.append(
    f"| Sales | "
    f"{int((clean_df['transaction_type'] == 'Sale').sum()):,} |"
)
report.append(
    f"| Returns | {return_rows:,} |"
)
report.append(
    f"| Cancellations | {cancelled_rows:,} |"
)
report.append(
    f"| Invalid | "
    f"{int((clean_df['transaction_type'] == 'Invalid').sum()):,} |"
)
report.append("")

report.append("## 3. Data Quality Flags")
report.append("")
report.append("| Quality Check | Rows |")
report.append("|---|---:|")
report.append(
    f"| Missing CustomerID | "
    f"{missing_customer_rows:,} |"
)
report.append(
    f"| Zero unit price | "
    f"{zero_price_rows:,} |"
)
report.append(
    f"| Negative unit price | "
    f"{negative_price_rows:,} |"
)
report.append(
    f"| Invalid invoice date | "
    f"{invalid_date_rows:,} |"
)
report.append(
    f"| Unknown product description | "
    f"{unknown_description_rows:,} |"
)
report.append("")

report.append("## 4. Description Resolution")
report.append("")
report.append(
    f"- Missing descriptions before mapping: "
    f"{missing_description_before:,}"
)
report.append(
    f"- Missing descriptions after mapping: "
    f"{missing_description_after:,}"
)
report.append(
    f"- Descriptions resolved through product mapping: "
    f"{missing_description_before - missing_description_after:,}"
)
report.append("")

report.append("## 5. Financial Baseline")
report.append("")
report.append("| Metric | Value |")
report.append("|---|---:|")
report.append(
    f"| Net transaction value | "
    f"{net_sales:,.2f} |"
)
report.append(
    f"| Positive transaction value | "
    f"{positive_sales:,.2f} |"
)
report.append(
    f"| Negative transaction value | "
    f"{negative_sales:,.2f} |"
)
report.append("")

report.append("## 6. Output Tables")
report.append("")
report.append("| Table | Rows |")
report.append("|---|---:|")
report.append(
    f"| fact_sales | {len(fact_sales):,} |"
)
report.append(
    f"| dim_customer | {len(dim_customer):,} |"
)
report.append(
    f"| dim_product | {len(dim_product):,} |"
)
report.append(
    f"| dim_country | {len(dim_country):,} |"
)
report.append(
    f"| dim_date | {len(dim_date):,} |"
)
report.append("")

report.append("## 7. Transformation Principles")
report.append("")
report.append(
    "1. The raw source workbook remains unchanged."
)
report.append(
    "2. Duplicate transaction records matching the defined business-key "
    "attributes are removed from the analytical layer after identification."
)
report.append(
    "3. Returns and cancellations are retained and explicitly classified."
)
report.append(
    "4. Missing CustomerID values are retained as unknown customers."
)
report.append(
    "5. Zero and negative prices are flagged rather than silently deleted."
)
report.append(
    "6. Product descriptions are resolved from valid product-level "
    "mappings where possible."
)
report.append(
    "7. No synthetic customer or product information is fabricated."
)
report.append(
    "8. All calculated sales values are derived from quantity multiplied "
    "by unit price."
)
report.append("")

report.append("## 8. Next Step")
report.append("")
report.append(
    "The processed data will next undergo independent SQL-based "
    "validation before analytical queries and reporting models are built."
)

REPORT_FILE.write_text(
    "\n".join(report),
    encoding="utf-8",
)


# =============================================================================
# Console summary
# =============================================================================

print("\n" + "=" * 80)
print("CLEANING COMPLETE")
print("=" * 80)

print("\nRows:")
print(f"  Raw:                    {raw_row_count:,}")
print(f"  Duplicate transactions: {duplicate_count:,}")
print(f"  After deduplication:   {rows_after_deduplication:,}")

print("\nTransaction classification:")
print(f"  Returns:                {return_rows:,}")
print(f"  Cancellations:          {cancelled_rows:,}")

print("\nData quality:")
print(f"  Missing customers:      {missing_customer_rows:,}")
print(f"  Zero prices:            {zero_price_rows:,}")
print(f"  Negative prices:        {negative_price_rows:,}")
print(f"  Unknown descriptions:   {unknown_description_rows:,}")
print(f"  Invalid dates:          {invalid_date_rows:,}")

print("\nOutput tables:")
print(f"  fact_sales:             {len(fact_sales):,}")
print(f"  dim_customer:           {len(dim_customer):,}")
print(f"  dim_product:            {len(dim_product):,}")
print(f"  dim_country:            {len(dim_country):,}")
print(f"  dim_date:               {len(dim_date):,}")

print("\nReport:")
print(f"  {REPORT_FILE}")

print("\nProcessing completed successfully.")