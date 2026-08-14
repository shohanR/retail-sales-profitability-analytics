-- Business Rule Checks
-- This script validates business rules and KPIs

-- Check: Profit should equal Sales - Cost
SELECT 'fact_sales - incorrect profit calculation' AS check_name,
       COUNT(*) AS issue_count
FROM fact_sales
WHERE ABS(profit_amount - (sales_amount - cost_amount)) > 0.01;

-- Check: Profit margin should be between -100% and 100%
SELECT 'fact_sales - invalid profit margin' AS check_name,
       COUNT(*) AS issue_count
FROM fact_sales
WHERE sales_amount > 0
  AND ((profit_amount / sales_amount) < -1 OR (profit_amount / sales_amount) > 1);

-- Check: Cost should not exceed sales (optional business rule)
-- Commented out as losses are valid - uncomment if needed
-- SELECT 'fact_sales - cost exceeds sales' AS check_name,
--        COUNT(*) AS issue_count
-- FROM fact_sales
-- WHERE cost_amount > sales_amount;

-- Check: Quantity * Unit Price should approximately equal sales amount
SELECT 'fact_sales - quantity x price mismatch' AS check_name,
       COUNT(*) AS issue_count
FROM fact_sales
WHERE ABS((quantity * unit_price) - sales_amount) > 0.01;

-- Check: Each customer exists in dim_customer
SELECT 'dim_customer - no product in catalog' AS check_name,
       COUNT(*) AS issue_count
FROM fact_sales
WHERE customer_id IS NULL;

-- Check: Each product exists in dim_product
SELECT 'dim_product - no customer in database' AS check_name,
       COUNT(*) AS issue_count
FROM fact_sales
WHERE product_id IS NULL;
