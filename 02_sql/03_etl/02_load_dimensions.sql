-- Load Dimensions
-- This script populates dimension tables from staging data

-- Load dim_customer
INSERT INTO dim_customer (customer_id, customer_name, segment, country_id)
SELECT DISTINCT
    stg.customer_id,
    stg.customer_name,
    stg.segment,
    dc.country_id
FROM stg_sales stg
LEFT JOIN dim_country dc ON stg.country = dc.country_name
WHERE NOT EXISTS (
    SELECT 1 FROM dim_customer dc2 WHERE dc2.customer_id = stg.customer_id
);

-- Load dim_product
INSERT INTO dim_product (product_id, product_name, category, sub_category, price)
SELECT DISTINCT
    stg.product_id,
    stg.product_name,
    stg.category,
    stg.sub_category,
    stg.unit_price
FROM stg_sales stg
WHERE NOT EXISTS (
    SELECT 1 FROM dim_product dp WHERE dp.product_id = stg.product_id
);

-- Load dim_country
INSERT INTO dim_country (country_code, country_name)
SELECT DISTINCT stg.country_code, stg.country
FROM stg_sales stg
WHERE NOT EXISTS (
    SELECT 1 FROM dim_country dc WHERE dc.country_name = stg.country
);
