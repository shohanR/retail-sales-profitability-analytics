/*
===============================================================================
01_null_checks.sql

Purpose
-------
Validate mandatory and analytical fields in the PostgreSQL fact table.
===============================================================================
*/

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (WHERE invoice_no IS NULL) AS null_invoice_no,
    COUNT(*) FILTER (WHERE stock_code IS NULL) AS null_stock_code,
    COUNT(*) FILTER (WHERE invoice_date IS NULL) AS null_invoice_date,
    COUNT(*) FILTER (WHERE country_key IS NULL) AS null_country_key,
    COUNT(*) FILTER (WHERE quantity IS NULL) AS null_quantity,
    COUNT(*) FILTER (WHERE unit_price IS NULL) AS null_unit_price,
    COUNT(*) FILTER (WHERE sales_amount IS NULL) AS null_sales_amount,
    COUNT(*) FILTER (WHERE transaction_type IS NULL) AS null_transaction_type

FROM analytics.fact_sales;