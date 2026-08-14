-- Monthly Performance View
-- Provides monthly aggregated metrics for trend analysis

CREATE OR ALTER VIEW vw_monthly_performance AS
SELECT
    YEAR(dd.date_value) AS year,
    MONTH(dd.date_value) AS month,
    DATEFROMPARTS(YEAR(dd.date_value), MONTH(dd.date_value), 1) AS month_start,
    EOMONTH(dd.date_value) AS month_end,
    COUNT(DISTINCT fs.transaction_id) AS monthly_transactions,
    COUNT(DISTINCT fs.customer_id) AS unique_customers,
    COUNT(DISTINCT fs.product_id) AS unique_products,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS monthly_sales,
    SUM(fs.cost_amount) AS monthly_cost,
    SUM(fs.profit_amount) AS monthly_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    ROUND(AVG(fs.sales_amount), 2) AS avg_transaction_value,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.customer_id), 2) AS sales_per_customer
FROM fact_sales fs
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY YEAR(dd.date_value), MONTH(dd.date_value);

GO

-- Test the view
-- SELECT * FROM vw_monthly_performance ORDER BY year DESC, month DESC;
