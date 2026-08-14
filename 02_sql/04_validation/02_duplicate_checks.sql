-- Duplicate Checks
-- This script identifies duplicate records in fact and dimension tables

-- Check for duplicate transactions
SELECT 'fact_sales - duplicate transactions' AS check_name,
       transaction_id,
       COUNT(*) AS duplicate_count
FROM fact_sales
GROUP BY transaction_id
HAVING COUNT(*) > 1;

-- Check for duplicate customers
SELECT 'dim_customer - duplicate customers' AS check_name,
       customer_id,
       COUNT(*) AS duplicate_count
FROM dim_customer
GROUP BY customer_id
HAVING COUNT(*) > 1;

-- Check for duplicate products
SELECT 'dim_product - duplicate products' AS check_name,
       product_id,
       COUNT(*) AS duplicate_count
FROM dim_product
GROUP BY product_id
HAVING COUNT(*) > 1;

-- Check for duplicate countries
SELECT 'dim_country - duplicate countries' AS check_name,
       country_name,
       COUNT(*) AS duplicate_count
FROM dim_country
GROUP BY country_name
HAVING COUNT(*) > 1;
