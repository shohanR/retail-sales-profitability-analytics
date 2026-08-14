-- Product Analysis
-- This script analyzes product performance and profitability

-- Top Products by Sales
SELECT TOP 20
    dp.product_name,
    dp.category,
    dp.sub_category,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.cost_amount) AS cost,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name, dp.category, dp.sub_category
ORDER BY sales DESC;

-- Products by Category Performance
SELECT
    dp.category,
    COUNT(DISTINCT dp.product_id) AS product_count,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_transaction_value
FROM fact_sales fs
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.category
ORDER BY sales DESC;

-- Low Profit Products (Below 10%)
SELECT
    dp.product_name,
    dp.category,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.product_id, dp.product_name, dp.category
HAVING ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) < 10
ORDER BY profit_margin_percent ASC;
