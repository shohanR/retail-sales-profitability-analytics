/*
===============================================================================
01_load_dimensions.sql

Purpose
-------
Load the processed Python dimension datasets into PostgreSQL.

Source
------
01_data/02_processed/

Target
------
analytics.dim_customer
analytics.dim_product
analytics.dim_country
analytics.dim_date

Note
----
The processed CSV files are generated locally by the Python ETL pipeline and
are intentionally excluded from Git version control.
===============================================================================
*/

BEGIN;

-- ============================================================================
-- Customer dimension
-- ============================================================================

-- TRUNCATE TABLE analytics.dim_customer;

COPY analytics.dim_customer (
    customer_id,
    country
)
FROM 'D:/Projects/retail-sales-profitability-analytics/01_data/02_processed/dim_customer.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    ENCODING 'UTF8'
);


-- ============================================================================
-- Product dimension
-- ============================================================================

-- TRUNCATE TABLE analytics.dim_product;

COPY analytics.dim_product (
    stock_code,
    description
)
FROM 'D:/Projects/retail-sales-profitability-analytics/01_data/02_processed/dim_product.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    ENCODING 'UTF8'
);


-- ============================================================================
-- Country dimension
-- ============================================================================

-- TRUNCATE TABLE analytics.dim_country;

COPY analytics.dim_country (
    country_key,
    country
)
FROM 'D:/Projects/retail-sales-profitability-analytics/01_data/02_processed/dim_country.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    ENCODING 'UTF8'
);


-- ============================================================================
-- Date dimension
-- ============================================================================

-- TRUNCATE TABLE analytics.dim_date;

COPY analytics.dim_date (
    date_key,
    date,
    year,
    quarter,
    month,
    month_name,
    week,
    day,
    day_name
)
FROM 'D:/Projects/retail-sales-profitability-analytics/01_data/02_processed/dim_date.csv'
WITH (
    FORMAT CSV,
    HEADER TRUE,
    ENCODING 'UTF8'
);

COMMIT;