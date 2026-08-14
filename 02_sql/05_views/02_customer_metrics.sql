-- Customer Metrics View
-- Provides customer-level metrics for analysis and reporting

CREATE OR ALTER VIEW vw_customer_metrics AS
SELECT
    fs.customer_id,
    dc.customer_name,
    dc.segment,
    dcountry.country_name,
    COUNT(DISTINCT fs.transaction_id) AS purchase_frequency,
    SUM(fs.quantity) AS total_units_purchased,
    SUM(fs.sales_amount) AS lifetime_sales,
    SUM(fs.cost_amount) AS lifetime_cost,
    SUM(fs.profit_amount) AS lifetime_profit,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.transaction_id), 2) AS avg_order_value,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent,
    MIN(dd.date_value) AS first_purchase_date,
    MAX(dd.date_value) AS last_purchase_date,
    DATEDIFF(DAY, MIN(dd.date_value), MAX(dd.date_value)) AS customer_lifespan_days
FROM fact_sales fs
LEFT JOIN dim_customer dc ON fs.customer_id = dc.customer_id
LEFT JOIN dim_country dcountry ON fs.country_id = dcountry.country_id
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY fs.customer_id, dc.customer_name, dc.segment, dcountry.country_name;

GO

-- Test the view
-- SELECT TOP 20 * FROM vw_customer_metrics ORDER BY lifetime_sales DESC;
