-- Country Analysis
-- This script analyzes geographic performance and market insights

-- Country Performance Summary
SELECT
    dc.country_name,
    COUNT(DISTINCT fs.customer_id) AS unique_customers,
    COUNT(DISTINCT fs.product_id) AS unique_products,
    COUNT(DISTINCT fs.transaction_id) AS total_transactions,
    SUM(fs.quantity) AS total_units_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.cost_amount) AS total_cost,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_order_value
FROM fact_sales fs
LEFT JOIN dim_country dc ON fs.country_id = dc.country_id
GROUP BY fs.country_id, dc.country_name
ORDER BY total_sales DESC;

-- Country Market Share
SELECT
    dc.country_name,
    SUM(fs.sales_amount) AS country_sales,
    ROUND(SUM(fs.sales_amount) * 100.0 / (SELECT SUM(sales_amount) FROM fact_sales), 2) AS market_share_percent,
    COUNT(DISTINCT fs.customer_id) AS customers,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.customer_id), 2) AS sales_per_customer
FROM fact_sales fs
LEFT JOIN dim_country dc ON fs.country_id = dc.country_id
GROUP BY fs.country_id, dc.country_name
ORDER BY country_sales DESC;

-- Top Products by Country
SELECT TOP 30
    dc.country_name,
    dp.product_name,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.profit_amount) AS profit
FROM fact_sales fs
LEFT JOIN dim_country dc ON fs.country_id = dc.country_id
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY fs.country_id, dc.country_name, fs.product_id, dp.product_name
ORDER BY sales DESC;

-- Geographic Profitability Comparison
SELECT
    dc.country_name,
    CASE
        WHEN SUM(fs.profit_amount) / SUM(fs.sales_amount) >= 0.3 THEN 'High Profit (30%+)'
        WHEN SUM(fs.profit_amount) / SUM(fs.sales_amount) >= 0.15 THEN 'Medium Profit (15-30%)'
        ELSE 'Low Profit (<15%)'
    END AS profitability_tier,
    SUM(fs.sales_amount) AS sales,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_country dc ON fs.country_id = dc.country_id
GROUP BY fs.country_id, dc.country_name
ORDER BY profit_margin_percent DESC;
