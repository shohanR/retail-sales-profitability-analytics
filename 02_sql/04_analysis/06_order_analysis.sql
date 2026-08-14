/*
===============================================================================
06_order_analysis.sql

Purpose
-------
Analyze order-level behavior including order value, order size, purchasing
frequency, transaction composition, and high-value orders.

Sources
-------
analytics.fact_sales

Grain
-----
One row per invoice/order in order-level summaries.

Business definitions
--------------------
Sales Order
    Distinct invoice_no associated with Sale transactions.

Gross Order Value
    Sum of sales_amount for Sale transaction lines belonging to an order.

Units per Order
    Sum of quantity from Sale transaction lines belonging to an order.

Average Order Value
    Gross order value divided by the number of sales orders.

Important
---------
Returns and cancellations are analyzed separately from normal sales activity.

The source data contains invoice numbers beginning with "A" and "C".
These are preserved as transaction identifiers and are not automatically
discarded.

Customer-level metrics exclude NULL customer_id values where customer
attribution is required.

===============================================================================
*/


/*
===============================================================================
1. ORDER-LEVEL SALES DETAIL
===============================================================================

Creates the analytical order-level view directly from fact_sales.

===============================================================================
*/

SELECT
    f.invoice_no,

    MIN(f.invoice_date) AS order_date,

    MAX(f.customer_id) AS customer_id,

    MAX(f.country_key) AS country_key,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_order_value,

    COUNT(DISTINCT f.stock_code) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS distinct_products

FROM analytics.fact_sales AS f

GROUP BY
    f.invoice_no

ORDER BY
    order_date,
    invoice_no;


/*
===============================================================================
2. TOP 20 ORDERS BY GROSS ORDER VALUE
===============================================================================
*/

SELECT
    f.invoice_no,

    MIN(f.invoice_date) AS order_date,

    MAX(f.customer_id) AS customer_id,

    MAX(c.country) AS country,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.stock_code) AS distinct_products,

    SUM(f.sales_amount) AS gross_order_value

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'

GROUP BY
    f.invoice_no

ORDER BY
    gross_order_value DESC

LIMIT 20;


/*
===============================================================================
3. ORDER VALUE DISTRIBUTION
===============================================================================

Groups sales orders into useful commercial value bands.

===============================================================================
*/

WITH order_values AS (
    SELECT
        invoice_no,

        SUM(sales_amount) AS gross_order_value

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        invoice_no
)

SELECT
    CASE
        WHEN gross_order_value < 10
            THEN '< $10'

        WHEN gross_order_value < 50
            THEN '$10 - $49.99'

        WHEN gross_order_value < 100
            THEN '$50 - $99.99'

        WHEN gross_order_value < 250
            THEN '$100 - $249.99'

        WHEN gross_order_value < 500
            THEN '$250 - $499.99'

        WHEN gross_order_value < 1000
            THEN '$500 - $999.99'

        ELSE '$1,000+'
    END AS order_value_band,

    COUNT(*) AS order_count,

    SUM(gross_order_value) AS total_sales,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS average_order_value

FROM order_values

GROUP BY
    CASE
        WHEN gross_order_value < 10
            THEN '< $10'

        WHEN gross_order_value < 50
            THEN '$10 - $49.99'

        WHEN gross_order_value < 100
            THEN '$50 - $99.99'

        WHEN gross_order_value < 250
            THEN '$100 - $249.99'

        WHEN gross_order_value < 500
            THEN '$250 - $499.99'

        WHEN gross_order_value < 1000
            THEN '$500 - $999.99'

        ELSE '$1,000+'
    END

ORDER BY
    MIN(gross_order_value);


/*
===============================================================================
4. ORDER SIZE DISTRIBUTION
===============================================================================

Groups orders according to the number of units sold.

===============================================================================
*/

WITH order_units AS (
    SELECT
        invoice_no,

        SUM(quantity) AS units_sold

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        invoice_no
)

SELECT
    CASE
        WHEN units_sold = 1
            THEN '1 unit'

        WHEN units_sold BETWEEN 2 AND 5
            THEN '2-5 units'

        WHEN units_sold BETWEEN 6 AND 10
            THEN '6-10 units'

        WHEN units_sold BETWEEN 11 AND 25
            THEN '11-25 units'

        WHEN units_sold BETWEEN 26 AND 50
            THEN '26-50 units'

        ELSE '51+ units'
    END AS order_size_band,

    COUNT(*) AS order_count,

    SUM(units_sold) AS total_units,

    ROUND(
        AVG(units_sold),
        2
    ) AS average_units_per_order

FROM order_units

GROUP BY
    CASE
        WHEN units_sold = 1
            THEN '1 unit'

        WHEN units_sold BETWEEN 2 AND 5
            THEN '2-5 units'

        WHEN units_sold BETWEEN 6 AND 10
            THEN '6-10 units'

        WHEN units_sold BETWEEN 11 AND 25
            THEN '11-25 units'

        WHEN units_sold BETWEEN 26 AND 50
            THEN '26-50 units'

        ELSE '51+ units'
    END

ORDER BY
    MIN(units_sold);


/*
===============================================================================
5. ORDER PRODUCT BREADTH
===============================================================================

Measures how many distinct products are included in each order.

===============================================================================
*/

WITH order_products AS (
    SELECT
        invoice_no,

        COUNT(DISTINCT stock_code) AS distinct_products,

        SUM(quantity) AS units_sold,

        SUM(sales_amount) AS gross_order_value

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        invoice_no
)

SELECT
    CASE
        WHEN distinct_products = 1
            THEN '1 product'

        WHEN distinct_products BETWEEN 2 AND 5
            THEN '2-5 products'

        WHEN distinct_products BETWEEN 6 AND 10
            THEN '6-10 products'

        WHEN distinct_products BETWEEN 11 AND 20
            THEN '11-20 products'

        ELSE '21+ products'
    END AS product_breadth_band,

    COUNT(*) AS order_count,

    SUM(units_sold) AS units_sold,

    SUM(gross_order_value) AS gross_sales,

    ROUND(
        AVG(gross_order_value),
        2
    ) AS average_order_value

FROM order_products

GROUP BY
    CASE
        WHEN distinct_products = 1
            THEN '1 product'

        WHEN distinct_products BETWEEN 2 AND 5
            THEN '2-5 products'

        WHEN distinct_products BETWEEN 6 AND 10
            THEN '6-10 products'

        WHEN distinct_products BETWEEN 11 AND 20
            THEN '11-20 products'

        ELSE '21+ products'
    END

ORDER BY
    MIN(distinct_products);


/*
===============================================================================
6. MONTHLY ORDER PERFORMANCE
===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    SUM(f.sales_amount) AS gross_sales,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.stock_code) AS distinct_products_sold,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.invoice_no), 0),
        2
    ) AS average_order_value,

    ROUND(
        SUM(f.quantity)::NUMERIC
        / NULLIF(COUNT(DISTINCT f.invoice_no), 0),
        2
    ) AS average_units_per_order

FROM analytics.fact_sales AS f

WHERE f.transaction_type = 'Sale'

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    month_start;


/*
===============================================================================
7. CUSTOMER ORDER FREQUENCY
===============================================================================

Measures how many sales orders each known customer placed.

===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.invoice_no), 0),
        2
    ) AS average_order_value

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.transaction_type = 'Sale'
  AND f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

ORDER BY
    sales_orders DESC,
    gross_sales DESC;


/*
===============================================================================
8. TOP 20 CUSTOMERS BY ORDER FREQUENCY
===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.transaction_type = 'Sale'
  AND f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

ORDER BY
    sales_orders DESC,
    gross_sales DESC

LIMIT 20;


/*
===============================================================================
9. ORDERS WITH RETURNS
===============================================================================

Identifies invoices containing both normal sales and return activity.

===============================================================================
*/

SELECT
    f.invoice_no,

    MIN(f.invoice_date) AS order_date,

    MAX(f.customer_id) AS customer_id,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS return_lines,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS returned_quantity,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS return_sales_amount

FROM analytics.fact_sales AS f

GROUP BY
    f.invoice_no

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Return'
    ) > 0

ORDER BY
    return_lines DESC;


/*
===============================================================================
10. ORDERS WITH CANCELLATIONS
===============================================================================

Identifies invoices containing cancellation activity.

===============================================================================
*/

SELECT
    f.invoice_no,

    MIN(f.invoice_date) AS order_date,

    MAX(f.customer_id) AS customer_id,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancellation_lines,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancelled_quantity,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancellation_sales_amount

FROM analytics.fact_sales AS f

GROUP BY
    f.invoice_no

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) > 0

ORDER BY
    cancellation_lines DESC;


/*
===============================================================================
11. ORDER TRANSACTION COMPOSITION
===============================================================================

Classifies each invoice according to its transaction composition.

===============================================================================
*/

WITH order_flags AS (
    SELECT
        invoice_no,

        BOOL_OR(
            transaction_type = 'Sale'
        ) AS has_sale,

        BOOL_OR(
            transaction_type = 'Return'
        ) AS has_return,

        BOOL_OR(
            transaction_type = 'Cancellation'
        ) AS has_cancellation

    FROM analytics.fact_sales

    GROUP BY
        invoice_no
)

SELECT
    CASE
        WHEN has_sale
         AND NOT has_return
         AND NOT has_cancellation
            THEN 'Sale Only'

        WHEN has_sale
         AND has_return
         AND NOT has_cancellation
            THEN 'Sale + Return'

        WHEN has_sale
         AND NOT has_return
         AND has_cancellation
            THEN 'Sale + Cancellation'

        WHEN has_sale
         AND has_return
         AND has_cancellation
            THEN 'Sale + Return + Cancellation'

        WHEN NOT has_sale
         AND has_return
         AND NOT has_cancellation
            THEN 'Return Only'

        WHEN NOT has_sale
         AND NOT has_return
         AND has_cancellation
            THEN 'Cancellation Only'

        ELSE 'Other'
    END AS order_composition,

    COUNT(*) AS order_count

FROM order_flags

GROUP BY
    CASE
        WHEN has_sale
         AND NOT has_return
         AND NOT has_cancellation
            THEN 'Sale Only'

        WHEN has_sale
         AND has_return
         AND NOT has_cancellation
            THEN 'Sale + Return'

        WHEN has_sale
         AND NOT has_return
         AND has_cancellation
            THEN 'Sale + Cancellation'

        WHEN has_sale
         AND has_return
         AND has_cancellation
            THEN 'Sale + Return + Cancellation'

        WHEN NOT has_sale
         AND has_return
         AND NOT has_cancellation
            THEN 'Return Only'

        WHEN NOT has_sale
         AND NOT has_return
         AND has_cancellation
            THEN 'Cancellation Only'

        ELSE 'Other'
    END

ORDER BY
    order_count DESC;


/*
===============================================================================
12. ORDER DATE/TIME SPREAD
===============================================================================

Measures the number of transaction lines and orders by hour.

Useful for operational and purchasing-pattern analysis.

===============================================================================
*/

SELECT
    EXTRACT(
        HOUR FROM f.invoice_date
    )::INTEGER AS invoice_hour,

    COUNT(*) AS transaction_lines,

    COUNT(DISTINCT f.invoice_no) AS distinct_invoices,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS customers,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales

FROM analytics.fact_sales AS f

GROUP BY
    EXTRACT(
        HOUR FROM f.invoice_date
    )

ORDER BY
    invoice_hour;


/*
===============================================================================
13. ORDER DAY-OF-WEEK PATTERN
===============================================================================
*/

SELECT
    EXTRACT(
        ISODOW FROM f.invoice_date
    )::INTEGER AS weekday_number,

    TO_CHAR(
        f.invoice_date,
        'Day'
    ) AS weekday_name,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_orders,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales

FROM analytics.fact_sales AS f

GROUP BY
    EXTRACT(
        ISODOW FROM f.invoice_date
    ),
    TO_CHAR(
        f.invoice_date,
        'Day'
    )

ORDER BY
    weekday_number;


/*
===============================================================================
14. HIGH-VALUE ORDER CONCENTRATION
===============================================================================

Measures the contribution of the top 1%, 5%, and 10% of orders to gross sales.

This provides a useful concentration/risk indicator.

===============================================================================
*/

WITH order_values AS (
    SELECT
        invoice_no,

        SUM(sales_amount) AS gross_order_value

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        invoice_no
),

ranked_orders AS (
    SELECT
        invoice_no,

        gross_order_value,

        ROW_NUMBER() OVER (
            ORDER BY gross_order_value DESC
        ) AS order_rank,

        COUNT(*) OVER () AS total_orders

    FROM order_values
),

classified_orders AS (
    SELECT
        *,

        CASE
            WHEN order_rank <= CEIL(total_orders * 0.01)
                THEN 'Top 1%'

            WHEN order_rank <= CEIL(total_orders * 0.05)
                THEN 'Top 5%'

            WHEN order_rank <= CEIL(total_orders * 0.10)
                THEN 'Top 10%'

            ELSE 'Remaining Orders'
        END AS order_segment

    FROM ranked_orders
)

SELECT
    order_segment,

    COUNT(*) AS order_count,

    SUM(gross_order_value) AS gross_sales,

    ROUND(
        100.0
        * SUM(gross_order_value)
        / NULLIF(
            SUM(SUM(gross_order_value)) OVER (),
            0
        ),
        2
    ) AS sales_contribution_pct

FROM classified_orders

GROUP BY
    order_segment

ORDER BY
    CASE order_segment
        WHEN 'Top 1%' THEN 1
        WHEN 'Top 5%' THEN 2
        WHEN 'Top 10%' THEN 3
        ELSE 4
    END;


/*
===============================================================================
15. ORDER-LEVEL DATA QUALITY CHECK
===============================================================================

Checks whether a sales order contains inconsistent customer attribution.

A single invoice should normally map to one customer where customer data
is available.

===============================================================================
*/

SELECT
    invoice_no,

    COUNT(DISTINCT customer_id)
        FILTER (
            WHERE customer_id IS NOT NULL
        ) AS distinct_customer_ids

FROM analytics.fact_sales

GROUP BY
    invoice_no

HAVING
    COUNT(DISTINCT customer_id)
        FILTER (
            WHERE customer_id IS NOT NULL
        ) > 1

ORDER BY
    distinct_customer_ids DESC;


/*
===============================================================================
16. ORDER-LEVEL DATA QUALITY CHECK
===============================================================================

Checks whether an invoice contains multiple countries.

===============================================================================
*/

SELECT
    invoice_no,

    COUNT(DISTINCT country_key)
        FILTER (
            WHERE country_key IS NOT NULL
        ) AS distinct_countries

FROM analytics.fact_sales

GROUP BY
    invoice_no

HAVING
    COUNT(DISTINCT country_key)
        FILTER (
            WHERE country_key IS NOT NULL
        ) > 1

ORDER BY
    distinct_countries DESC;


/*
===============================================================================
17. ORDER ANALYSIS SUMMARY
===============================================================================

Compact KPI baseline for downstream reporting.

===============================================================================
*/

WITH order_metrics AS (
    SELECT
        invoice_no,

        SUM(sales_amount) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS gross_order_value,

        SUM(quantity) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS units_sold,

        COUNT(DISTINCT stock_code) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS distinct_products

    FROM analytics.fact_sales

    GROUP BY
        invoice_no
)

SELECT
    COUNT(*) FILTER (
        WHERE gross_order_value IS NOT NULL
          AND gross_order_value > 0
    ) AS sales_orders,

    SUM(gross_order_value) FILTER (
        WHERE gross_order_value IS NOT NULL
    ) AS total_gross_sales,

    SUM(units_sold) FILTER (
        WHERE gross_order_value IS NOT NULL
    ) AS total_units_sold,

    ROUND(
        AVG(gross_order_value) FILTER (
            WHERE gross_order_value IS NOT NULL
        ),
        2
    ) AS average_order_value,

    ROUND(
        AVG(units_sold) FILTER (
            WHERE gross_order_value IS NOT NULL
        ),
        2
    ) AS average_units_per_order,

    ROUND(
        AVG(distinct_products) FILTER (
            WHERE gross_order_value IS NOT NULL
        ),
        2
    ) AS average_products_per_order

FROM order_metrics;