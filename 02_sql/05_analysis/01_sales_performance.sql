-- Sales Performance Analysis
-- This script analyzes overall sales and profitability metrics

SELECT
    COUNT(DISTINCT fs.transaction_id) AS total_transactions,
    COUNT(DISTINCT fs.customer_id) AS total_customers,
    COUNT(DISTINCT fs.product_id) AS total_products,
    COUNT(DISTINCT fs.country_id) AS total_countries,
    SUM(fs.quantity) AS total_units_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.cost_amount) AS total_cost,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_transaction_value,
    ROUND(AVG(fs.profit_amount), 2) AS avg_profit_per_transaction
FROM fact_sales fs;

-- Sales by Country
SELECT
    dc.country_name,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_country dc ON fs.country_id = dc.country_id
GROUP BY dc.country_name
ORDER BY sales DESC;

-- Sales by Customer Segment
SELECT
    dc.segment,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS sales,
    SUM(fs.profit_amount) AS profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
GROUP BY dc.segment
ORDER BY sales DESC;
