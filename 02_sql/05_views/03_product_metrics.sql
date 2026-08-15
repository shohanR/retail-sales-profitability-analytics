/*
===============================================================================
03_product_metrics.sql

Purpose
-------
Create a reusable product-level metrics view for Power BI, Excel, and
downstream SQL reporting.

View
----
analytics.vw_product_metrics

Grain
-----
One row per stock_code.

Sources
-------
analytics.fact_sales
analytics.dim_product

Business definitions
--------------------
Gross Sales
    Sales amount from Sale transactions.

Net Sales
    Sum of sales_amount across all transaction types associated with the
    product.

Units Sold
    Total quantity from Sale transactions.

Sales Orders
    Distinct invoices containing Sale transactions.

Average Selling Price
    Average positive unit price across Sale transactions.

Return Lines
    Number of Return transaction lines.

Returned Units
    Quantity associated with Return transactions.

Cancellation Lines
    Number of Cancellation transaction lines.

Cancelled Units
    Quantity associated with Cancellation transactions.

Sales Contribution
    Product gross sales as a percentage of total gross sales.

Important
---------
- Product descriptions come from dim_product.
- One stock_code maps to one canonical product description.
- Source-level description variation is handled in the product dimension.
- Returns and cancellations are preserved and reported separately.
- No product records are fabricated or imputed.
===============================================================================
*/


CREATE OR REPLACE VIEW analytics.vw_product_metrics AS

WITH product_metrics AS (

    SELECT
        f.stock_code,

        /* -------------------------------------------------------------------
           Sales activity
           ------------------------------------------------------------------- */

        COUNT(*) FILTER (
            WHERE f.transaction_type = 'Sale'
        ) AS sale_lines,

        COUNT(DISTINCT f.invoice_no) FILTER (
            WHERE f.transaction_type = 'Sale'
        ) AS sales_orders,

        SUM(f.quantity) FILTER (
            WHERE f.transaction_type = 'Sale'
        ) AS units_sold,

        SUM(f.sales_amount) FILTER (
            WHERE f.transaction_type = 'Sale'
        ) AS gross_sales,

        /* -------------------------------------------------------------------
           Overall financial activity
           ------------------------------------------------------------------- */

        SUM(f.sales_amount) AS net_sales,

        /* -------------------------------------------------------------------
           Return activity
           ------------------------------------------------------------------- */

        COUNT(*) FILTER (
            WHERE f.transaction_type = 'Return'
        ) AS return_lines,

        COUNT(DISTINCT f.invoice_no) FILTER (
            WHERE f.transaction_type = 'Return'
        ) AS return_orders,

        SUM(f.quantity) FILTER (
            WHERE f.transaction_type = 'Return'
        ) AS returned_units,

        SUM(f.sales_amount) FILTER (
            WHERE f.transaction_type = 'Return'
        ) AS return_sales_amount,

        /* -------------------------------------------------------------------
           Cancellation activity
           ------------------------------------------------------------------- */

        COUNT(*) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        ) AS cancellation_lines,

        COUNT(DISTINCT f.invoice_no) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        ) AS cancellation_orders,

        SUM(f.quantity) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        ) AS cancelled_units,

        SUM(f.sales_amount) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        ) AS cancellation_sales_amount,

        /* -------------------------------------------------------------------
           Pricing
           ------------------------------------------------------------------- */

        AVG(f.unit_price) FILTER (
            WHERE f.transaction_type = 'Sale'
              AND f.unit_price > 0
        ) AS average_selling_price,

        MIN(f.unit_price) FILTER (
            WHERE f.transaction_type = 'Sale'
              AND f.unit_price > 0
        ) AS minimum_selling_price,

        MAX(f.unit_price) FILTER (
            WHERE f.transaction_type = 'Sale'
              AND f.unit_price > 0
        ) AS maximum_selling_price,

        /* -------------------------------------------------------------------
           Product reach
           ------------------------------------------------------------------- */

        COUNT(DISTINCT f.customer_id) FILTER (
            WHERE f.transaction_type = 'Sale'
              AND f.customer_id IS NOT NULL
        ) AS purchasing_customers

    FROM analytics.fact_sales AS f

    GROUP BY
        f.stock_code
)

SELECT
    pm.stock_code,

    p.description,

    /* -----------------------------------------------------------------------
       Sales activity
       ----------------------------------------------------------------------- */

    pm.sale_lines,

    pm.sales_orders,

    pm.purchasing_customers,

    pm.units_sold,

    pm.gross_sales,

    /* -----------------------------------------------------------------------
       Overall financial activity
       ----------------------------------------------------------------------- */

    pm.net_sales,

    /* -----------------------------------------------------------------------
       Return activity
       ----------------------------------------------------------------------- */

    pm.return_lines,

    pm.return_orders,

    pm.returned_units,

    pm.return_sales_amount,

    /* -----------------------------------------------------------------------
       Cancellation activity
       ----------------------------------------------------------------------- */

    pm.cancellation_lines,

    pm.cancellation_orders,

    pm.cancelled_units,

    pm.cancellation_sales_amount,

    /* -----------------------------------------------------------------------
       Pricing
       ----------------------------------------------------------------------- */

    ROUND(
        pm.average_selling_price,
        4
    ) AS average_selling_price,

    ROUND(
        pm.minimum_selling_price,
        4
    ) AS minimum_selling_price,

    ROUND(
        pm.maximum_selling_price,
        4
    ) AS maximum_selling_price,

    /* -----------------------------------------------------------------------
       Product KPIs
       ----------------------------------------------------------------------- */

    ROUND(
        pm.gross_sales
        / NULLIF(pm.sales_orders, 0),
        2
    ) AS average_order_value,

    ROUND(
        pm.units_sold::NUMERIC
        / NULLIF(pm.sales_orders, 0),
        2
    ) AS average_units_per_order,

    ROUND(
        100.0
        * pm.return_lines
        / NULLIF(pm.sale_lines, 0),
        2
    ) AS return_rate_pct,

    ROUND(
        100.0
        * pm.cancellation_lines
        / NULLIF(pm.sale_lines, 0),
        2
    ) AS cancellation_rate_pct,

    ROUND(
        100.0
        * pm.gross_sales
        / NULLIF(
            SUM(pm.gross_sales) OVER (),
            0
        ),
        2
    ) AS gross_sales_contribution_pct,

    CASE
        WHEN pm.gross_sales IS NULL
            THEN 'No Sales'

        WHEN pm.gross_sales <= 0
            THEN 'Non-Positive Sales'

        ELSE 'Active'
    END AS sales_status,

    CASE
        WHEN p.description IS NULL
          OR TRIM(p.description) = ''
            THEN 'Missing Description'

        ELSE 'Described'
    END AS description_status

FROM product_metrics AS pm

LEFT JOIN analytics.dim_product AS p
    ON pm.stock_code = p.stock_code;


/*
===============================================================================
VALIDATION
===============================================================================

1. Inspect the view
-------------------------------------------------------------------------------

SELECT *
FROM analytics.vw_product_metrics
ORDER BY gross_sales DESC NULLS LAST;


2. Validate product count
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS view_product_count,
    (
        SELECT COUNT(*)
        FROM analytics.dim_product
    ) AS dimension_product_count;


3. Validate gross sales
-------------------------------------------------------------------------------

SELECT
    SUM(gross_sales) AS view_gross_sales,

    (
        SELECT
            SUM(sales_amount)
        FROM analytics.fact_sales
        WHERE transaction_type = 'Sale'
    ) AS fact_gross_sales

FROM analytics.vw_product_metrics;


4. Validate units sold
-------------------------------------------------------------------------------

SELECT
    SUM(units_sold) AS view_units_sold,

    (
        SELECT
            SUM(quantity)
        FROM analytics.fact_sales
        WHERE transaction_type = 'Sale'
    ) AS fact_units_sold

FROM analytics.vw_product_metrics;


5. Validate purchasing customers
-------------------------------------------------------------------------------

SELECT
    SUM(
        CASE
            WHEN purchasing_customers > 0
                THEN 1
            ELSE 0
        END
    ) AS products_with_known_customer_activity
FROM analytics.vw_product_metrics;


6. Check duplicate stock codes
-------------------------------------------------------------------------------

SELECT
    stock_code,
    COUNT(*) AS row_count
FROM analytics.vw_product_metrics
GROUP BY stock_code
HAVING COUNT(*) > 1;

Expected result:
    0 rows.


7. Check invalid product references
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS invalid_product_rows
FROM analytics.vw_product_metrics AS v
LEFT JOIN analytics.dim_product AS p
    ON v.stock_code = p.stock_code
WHERE p.stock_code IS NULL;

Expected result:
    0


8. Product description quality
-------------------------------------------------------------------------------

SELECT
    description_status,
    COUNT(*) AS product_count
FROM analytics.vw_product_metrics
GROUP BY description_status
ORDER BY description_status;

Expected baseline:
    355 products with 'Missing Description'
    Remaining products with 'Described'

===============================================================================
*/