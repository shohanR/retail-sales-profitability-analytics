-- Null Checks
-- This script validates that critical fields have no null values

SELECT 'dim_customer - customer_id NULL' AS check_name, COUNT(*) AS null_count
FROM dim_customer WHERE customer_id IS NULL
UNION ALL
SELECT 'dim_customer - customer_name NULL', COUNT(*)
FROM dim_customer WHERE customer_name IS NULL
UNION ALL
SELECT 'dim_product - product_id NULL', COUNT(*)
FROM dim_product WHERE product_id IS NULL
UNION ALL
SELECT 'dim_product - product_name NULL', COUNT(*)
FROM dim_product WHERE product_name IS NULL
UNION ALL
SELECT 'dim_country - country_name NULL', COUNT(*)
FROM dim_country WHERE country_name IS NULL
UNION ALL
SELECT 'fact_sales - transaction_id NULL', COUNT(*)
FROM fact_sales WHERE transaction_id IS NULL
UNION ALL
SELECT 'fact_sales - customer_id NULL', COUNT(*)
FROM fact_sales WHERE customer_id IS NULL
UNION ALL
SELECT 'fact_sales - product_id NULL', COUNT(*)
FROM fact_sales WHERE product_id IS NULL
WHERE null_count > 0;
