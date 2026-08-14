/*
===============================================================================
03_load_fact_sales.sql

Purpose
-------
Transform the processed staging transaction data into the analytical
fact_sales table.

Source
------
staging.fact_sales_load

Targets
-------
analytics.fact_sales

Transformation
--------------
- Resolve country -> country_key
- Validate customer/product/date dimension relationships
- Calculate the analytical fact grain
- Preserve transaction and data-quality classifications

Grain
-----
One row per cleaned transaction line.
===============================================================================
*/

BEGIN;

INSERT INTO analytics.fact_sales (
    invoice_no,
    stock_code,
    invoice_date,
    invoice_timestamp,
    customer_id,
    country_key,
    quantity,
    unit_price,
    sales_amount,
    transaction_type,
    is_cancelled,
    is_return,
    customer_status,
    description_status,
    price_quality_status,
    date_quality_status,
    is_analytically_usable,
    source_sheet
)
SELECT
    s.invoice_no,
    s.stock_code,
    s.invoice_date::DATE,
    s.invoice_date,
    s.customer_id,
    c.country_key,
    s.quantity,
    s.unit_price,
    s.sales_amount,
    s.transaction_type,
    s.is_cancelled,
    s.is_return,
    s.customer_status,
    s.description_status,
    s.price_quality_status,
    s.date_quality_status,
    s.is_analytically_usable,
    s.source_sheet
FROM staging.fact_sales_load AS s
INNER JOIN analytics.dim_country AS c
    ON LOWER(TRIM(s.country)) = LOWER(TRIM(c.country));

COMMIT;