/*
===============================================================================
02_create_dimensions.sql

Purpose
-------
Create the dimensional tables used by the retail analytical model.

Tables
------
analytics.dim_customer
analytics.dim_product
analytics.dim_country
analytics.dim_date
===============================================================================
*/

BEGIN;

-- ============================================================================
-- Customer dimension
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics.dim_customer (
    customer_id INTEGER PRIMARY KEY,
    country TEXT
);


-- ============================================================================
-- Product dimension
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics.dim_product (
    stock_code TEXT PRIMARY KEY,
    description TEXT
);


-- ============================================================================
-- Country dimension
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics.dim_country (
    country_key INTEGER PRIMARY KEY,
    country TEXT NOT NULL UNIQUE
);


-- ============================================================================
-- Date dimension
-- ============================================================================

CREATE TABLE IF NOT EXISTS analytics.dim_date (
    date_key INTEGER PRIMARY KEY,
    date DATE NOT NULL UNIQUE,
    year SMALLINT NOT NULL,
    quarter SMALLINT NOT NULL,
    month SMALLINT NOT NULL,
    month_name TEXT NOT NULL,
    week SMALLINT NOT NULL,
    day SMALLINT NOT NULL,
    day_name TEXT NOT NULL
);

COMMIT;