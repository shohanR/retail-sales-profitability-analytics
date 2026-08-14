/*
===============================================================================
04_create_fact_staging.sql

Purpose
-------
Create a staging table for the Python-generated transaction dataset.

The staging table mirrors the processed CSV structure. It intentionally uses
business attributes such as country rather than dimensional surrogate keys.

The transformation into analytics.fact_sales will resolve the dimensional
keys through joins.
===============================================================================
*/

BEGIN;

CREATE TABLE IF NOT EXISTS staging.fact_sales_load (
    invoice_no TEXT,
    stock_code TEXT,
    description TEXT,
    quantity INTEGER,
    invoice_date TIMESTAMP,
    unit_price NUMERIC(18, 4),
    customer_id INTEGER,
    country TEXT,
    sales_amount NUMERIC(18, 4),
    transaction_type TEXT,
    is_cancelled BOOLEAN,
    is_return BOOLEAN,
    customer_status TEXT,
    description_status TEXT,
    price_quality_status TEXT,
    date_quality_status TEXT,
    is_analytically_usable BOOLEAN,
    source_sheet TEXT
);

COMMIT;