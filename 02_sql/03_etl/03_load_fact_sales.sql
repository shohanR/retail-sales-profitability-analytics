-- Load Fact Sales
-- This script populates the fact_sales table with transformed data

INSERT INTO fact_sales (
    transaction_id,
    date_id,
    customer_id,
    product_id,
    country_id,
    quantity,
    unit_price,
    sales_amount,
    cost_amount,
    profit_amount
)
SELECT
    stg.transaction_id,
    dd.date_id,
    dc.customer_id,
    dp.product_id,
    dcountry.country_id,
    stg.quantity,
    stg.unit_price,
    stg.sales_amount,
    stg.cost_amount,
    (stg.sales_amount - stg.cost_amount) AS profit_amount
FROM stg_sales stg
LEFT JOIN dim_date dd ON CAST(stg.transaction_date AS DATE) = dd.date_value
LEFT JOIN dim_customer dc ON stg.customer_id = dc.customer_id
LEFT JOIN dim_product dp ON stg.product_id = dp.product_id
LEFT JOIN dim_country dcountry ON stg.country = dcountry.country_name
WHERE NOT EXISTS (
    SELECT 1 FROM fact_sales fs WHERE fs.transaction_id = stg.transaction_id
);
