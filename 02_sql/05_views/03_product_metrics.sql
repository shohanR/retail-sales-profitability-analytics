-- Product Metrics View
-- Provides product-level metrics for analysis and reporting

CREATE OR ALTER VIEW vw_product_metrics AS
SELECT
    fs.product_id,
    dp.product_name,
    dp.category,
    dp.sub_category,
    dp.price,
    COUNT(DISTINCT fs.customer_id) AS unique_customers,
    COUNT(DISTINCT fs.transaction_id) AS total_sales_transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.cost_amount) AS total_cost,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_transaction_value,
    ROUND(AVG(fs.profit_amount), 2) AS avg_profit_per_sale,
    MIN(dd.date_value) AS first_sale_date,
    MAX(dd.date_value) AS last_sale_date
FROM fact_sales fs
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY fs.product_id, dp.product_name, dp.category, dp.sub_category, dp.price;

GO

-- Test the view
-- SELECT TOP 20 * FROM vw_product_metrics ORDER BY total_sales DESC;
