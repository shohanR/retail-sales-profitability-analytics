-- Customer Analysis
-- This script analyzes customer performance and value metrics

-- Top Customers by Sales
SELECT TOP 20
    dc.customer_name,
    dc.segment,
    COUNT(DISTINCT fs.transaction_id) AS transaction_count,
    SUM(fs.quantity) AS total_units,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.transaction_id), 2) AS avg_order_value,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
GROUP BY fs.customer_id, dc.customer_name, dc.segment
ORDER BY total_sales DESC;

-- Customer Segmentation Analysis
SELECT
    dc.segment,
    COUNT(DISTINCT fs.customer_id) AS customer_count,
    COUNT(DISTINCT fs.transaction_id) AS transaction_count,
    ROUND(AVG(fs.sales_amount), 2) AS avg_order_value,
    SUM(fs.sales_amount) AS segment_sales,
    SUM(fs.profit_amount) AS segment_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
GROUP BY dc.segment
ORDER BY segment_sales DESC;

-- Customer Lifetime Value (CLV)
SELECT TOP 20
    dc.customer_name,
    dc.segment,
    COUNT(DISTINCT fs.transaction_id) AS purchase_frequency,
    MIN(dd.date_value) AS first_purchase,
    MAX(dd.date_value) AS last_purchase,
    DATEDIFF(DAY, MIN(dd.date_value), MAX(dd.date_value)) AS customer_lifespan_days,
    SUM(fs.sales_amount) AS lifetime_sales,
    SUM(fs.profit_amount) AS lifetime_profit
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY fs.customer_id, dc.customer_name, dc.segment
ORDER BY lifetime_sales DESC;

-- Inactive Customers (No purchases in last 90 days)
SELECT
    dc.customer_name,
    dc.segment,
    MAX(dd.date_value) AS last_purchase_date,
    DATEDIFF(DAY, MAX(dd.date_value), CAST(GETDATE() AS DATE)) AS days_since_purchase
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY fs.customer_id, dc.customer_name, dc.segment
HAVING DATEDIFF(DAY, MAX(dd.date_value), CAST(GETDATE() AS DATE)) > 90
ORDER BY days_since_purchase DESC;
