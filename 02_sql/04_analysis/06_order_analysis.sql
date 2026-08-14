-- Order Analysis
-- This script analyzes order patterns and transaction metrics

-- Order Value Distribution
SELECT
    CASE
        WHEN fs.sales_amount < 100 THEN 'Under $100'
        WHEN fs.sales_amount < 500 THEN '$100-$500'
        WHEN fs.sales_amount < 1000 THEN '$500-$1000'
        WHEN fs.sales_amount < 5000 THEN '$1000-$5000'
        ELSE 'Over $5000'
    END AS order_value_range,
    COUNT(*) AS order_count,
    ROUND(AVG(fs.sales_amount), 2) AS avg_order_value,
    ROUND(AVG(fs.profit_amount), 2) AS avg_profit,
    SUM(fs.sales_amount) AS total_sales,
    SUM(fs.profit_amount) AS total_profit
FROM fact_sales fs
GROUP BY
    CASE
        WHEN fs.sales_amount < 100 THEN 'Under $100'
        WHEN fs.sales_amount < 500 THEN '$100-$500'
        WHEN fs.sales_amount < 1000 THEN '$500-$1000'
        WHEN fs.sales_amount < 5000 THEN '$1000-$5000'
        ELSE 'Over $5000'
    END
ORDER BY
    CASE
        WHEN fs.sales_amount < 100 THEN 1
        WHEN fs.sales_amount < 500 THEN 2
        WHEN fs.sales_amount < 1000 THEN 3
        WHEN fs.sales_amount < 5000 THEN 4
        ELSE 5
    END;

-- Order Quantity Analysis
SELECT
    CASE
        WHEN fs.quantity <= 5 THEN '1-5 Units'
        WHEN fs.quantity <= 10 THEN '6-10 Units'
        WHEN fs.quantity <= 20 THEN '11-20 Units'
        WHEN fs.quantity <= 50 THEN '21-50 Units'
        ELSE '50+ Units'
    END AS quantity_range,
    COUNT(*) AS order_count,
    ROUND(AVG(fs.quantity), 2) AS avg_quantity,
    ROUND(AVG(fs.sales_amount), 2) AS avg_order_value,
    SUM(fs.sales_amount) AS total_sales
FROM fact_sales fs
GROUP BY
    CASE
        WHEN fs.quantity <= 5 THEN '1-5 Units'
        WHEN fs.quantity <= 10 THEN '6-10 Units'
        WHEN fs.quantity <= 20 THEN '11-20 Units'
        WHEN fs.quantity <= 50 THEN '21-50 Units'
        ELSE '50+ Units'
    END
ORDER BY COUNT(*) DESC;

-- Profitability by Order Value
SELECT
    CASE
        WHEN fs.profit_amount < 0 THEN 'Loss Making'
        WHEN fs.profit_amount = 0 THEN 'Break Even'
        WHEN fs.profit_amount > 0 AND fs.profit_amount <= 50 THEN 'Low Profit (<$50)'
        WHEN fs.profit_amount > 50 AND fs.profit_amount <= 200 THEN 'Medium Profit ($50-$200)'
        ELSE 'High Profit (>$200)'
    END AS profit_category,
    COUNT(*) AS order_count,
    ROUND(AVG(fs.profit_amount), 2) AS avg_profit,
    ROUND(AVG(fs.sales_amount), 2) AS avg_sales,
    SUM(fs.profit_amount) AS total_profit,
    ROUND(SUM(fs.profit_amount) / SUM(fs.sales_amount) * 100, 2) AS profit_margin_percent
FROM fact_sales fs
GROUP BY
    CASE
        WHEN fs.profit_amount < 0 THEN 'Loss Making'
        WHEN fs.profit_amount = 0 THEN 'Break Even'
        WHEN fs.profit_amount > 0 AND fs.profit_amount <= 50 THEN 'Low Profit (<$50)'
        WHEN fs.profit_amount > 50 AND fs.profit_amount <= 200 THEN 'Medium Profit ($50-$200)'
        ELSE 'High Profit (>$200)'
    END
ORDER BY COUNT(*) DESC;

-- AOV and Profit per Customer by Product Category
SELECT
    dp.category,
    COUNT(DISTINCT fs.customer_id) AS unique_customers,
    COUNT(DISTINCT fs.transaction_id) AS total_orders,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.customer_id), 2) AS avg_customer_value,
    ROUND(SUM(fs.sales_amount) / COUNT(DISTINCT fs.transaction_id), 2) AS avg_order_value,
    ROUND(SUM(fs.profit_amount) / COUNT(DISTINCT fs.customer_id), 2) AS profit_per_customer
FROM fact_sales fs
LEFT JOIN dim_product dp ON fs.product_id = dp.product_id
GROUP BY dp.category
ORDER BY avg_order_value DESC;
