-- Monthly Trends Analysis
-- This script analyzes sales and profitability trends over time

-- Monthly Sales Trend
SELECT
    YEAR(dd.date_value) AS year,
    MONTH(dd.date_value) AS month,
    DATEFROMPARTS(YEAR(dd.date_value), MONTH(dd.date_value), 1) AS month_start,
    COUNT(DISTINCT fs.transaction_id) AS transactions,
    SUM(fs.quantity) AS units_sold,
    SUM(fs.sales_amount) AS monthly_sales,
    SUM(fs.cost_amount) AS monthly_cost,
    SUM(fs.profit_amount) AS monthly_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY YEAR(dd.date_value), MONTH(dd.date_value)
ORDER BY YEAR(dd.date_value), MONTH(dd.date_value);

-- Month-over-Month Growth
WITH monthly_sales AS (
    SELECT
        YEAR(dd.date_value) AS year,
        MONTH(dd.date_value) AS month,
        SUM(fs.sales_amount) AS monthly_sales,
        SUM(fs.profit_amount) AS monthly_profit
    FROM fact_sales fs
    LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
    GROUP BY YEAR(dd.date_value), MONTH(dd.date_value)
)
SELECT
    year,
    month,
    monthly_sales,
    LAG(monthly_sales) OVER (ORDER BY year, month) AS prev_month_sales,
    ROUND((monthly_sales - LAG(monthly_sales) OVER (ORDER BY year, month)) / 
           LAG(monthly_sales) OVER (ORDER BY year, month) * 100, 2) AS mom_growth_percent,
    monthly_profit,
    LAG(monthly_profit) OVER (ORDER BY year, month) AS prev_month_profit
FROM monthly_sales
ORDER BY year, month;

-- Seasonality Analysis
SELECT
    MONTH(dd.date_value) AS month,
    DATENAME(MONTH, dd.date_value) AS month_name,
    COUNT(DISTINCT fs.transaction_id) AS avg_transactions,
    ROUND(AVG(fs.sales_amount), 2) AS avg_sale_value,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.profit_amount) AS total_profit,
    COUNT(DISTINCT YEAR(dd.date_value)) AS years_of_data
FROM fact_sales fs
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY MONTH(dd.date_value)
ORDER BY MONTH(dd.date_value);

-- Top Performing Months
SELECT TOP 12
    YEAR(dd.date_value) AS year,
    MONTH(dd.date_value) AS month,
    DATENAME(MONTH, dd.date_value) AS month_name,
    SUM(fs.sales_amount) AS monthly_sales,
    SUM(fs.profit_amount) AS monthly_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
LEFT JOIN dim_date dd ON fs.date_id = dd.date_id
GROUP BY YEAR(dd.date_value), MONTH(dd.date_value)
ORDER BY monthly_sales DESC;
