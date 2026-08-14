-- Sales Summary View
-- Provides a consolidated view of sales performance metrics

CREATE OR ALTER VIEW vw_sales_summary AS
SELECT
    COUNT(DISTINCT fs.transaction_id) AS total_transactions,
    COUNT(DISTINCT fs.customer_id) AS total_customers,
    COUNT(DISTINCT fs.product_id) AS total_products,
    COUNT(DISTINCT fs.country_id) AS total_countries,
    COUNT(DISTINCT YEAR(dd.date_value)) AS years_of_data,
    SUM(fs.quantity) AS total_units_sold,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.cost_amount) AS total_cost,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS overall_profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_transaction_value,
    ROUND(AVG(fs.quantity), 2) AS avg_units_per_transaction,
    MIN(dd.date_value) AS earliest_transaction_date,
    MAX(dd.date_value) AS latest_transaction_date
FROM fact_sales fs
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id;

GO

-- Test the view
-- SELECT * FROM vw_sales_summary;
