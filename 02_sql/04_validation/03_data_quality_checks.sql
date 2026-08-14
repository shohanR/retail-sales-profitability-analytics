-- Data Quality Checks
-- This script performs comprehensive data quality validations

-- Check quantity is not negative
SELECT 'fact_sales - negative quantity' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE quantity < 0;

-- Check sales amount is not negative
SELECT 'fact_sales - negative sales amount' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE sales_amount < 0;

-- Check cost amount is not negative
SELECT 'fact_sales - negative cost amount' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE cost_amount < 0;

-- Check price consistency
SELECT 'dim_product - invalid price' AS check_name, COUNT(*) AS issue_count
FROM dim_product
WHERE price < 0;

-- Check date range validity
SELECT 'fact_sales - invalid date' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE date_id NOT IN (SELECT date_id FROM dim_date);

-- Check referential integrity - customers
SELECT 'fact_sales - invalid customer reference' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE customer_id NOT IN (SELECT customer_id FROM dim_customer);

-- Check referential integrity - products
SELECT 'fact_sales - invalid product reference' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE product_id NOT IN (SELECT product_id FROM dim_product);

-- Check referential integrity - countries
SELECT 'fact_sales - invalid country reference' AS check_name, COUNT(*) AS issue_count
FROM fact_sales
WHERE country_id NOT IN (SELECT country_id FROM dim_country);
