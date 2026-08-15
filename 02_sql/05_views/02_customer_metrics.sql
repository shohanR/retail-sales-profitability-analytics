/*
===============================================================================
02_customer_metrics.sql

Purpose
-------
Create a reusable customer-level metrics view for Power BI, Excel, and
downstream SQL reporting.

View
----
analytics.vw_customer_metrics

Grain
-----
One row per known customer_id.

Sources
-------
analytics.fact_sales
analytics.dim_customer

Business definitions
--------------------
Sales Orders
    Distinct invoices associated with Sale transactions.

Units Sold
    Total quantity associated with Sale transactions.

Gross Sales
    Sales amount from Sale transactions.

Net Sales
    Sum of sales_amount across all transaction types attributed to the
    customer.

Average Order Value
    Gross Sales / Sales Orders.

Average Units per Order
    Units Sold / Sales Orders.

Return Lines
    Number of Return transaction lines.

Returned Units
    Total quantity from Return transactions.

Cancellation Lines
    Number of Cancellation transaction lines.

Cancelled Units
    Total quantity from Cancellation transactions.

Customer Attribution
--------------------
Only customers with a non-null customer_id are represented in this view.

Transactions with missing customer_id remain in fact_sales and are handled
separately in the broader sales analysis layer.

Important
---------
- Transaction classifications come from the validated fact_sales model.
- Returns and cancellations are retained and reported separately.
- No customer records are fabricated or imputed.
===============================================================================
*/


CREATE OR REPLACE VIEW analytics.vw_customer_metrics AS

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    /* -----------------------------------------------------------------------
       Sales activity
       ----------------------------------------------------------------------- */

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

    /* -----------------------------------------------------------------------
       Overall attributed financial activity
       ----------------------------------------------------------------------- */

    SUM(f.sales_amount) AS net_sales,

    /* -----------------------------------------------------------------------
       Return activity
       ----------------------------------------------------------------------- */

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

    /* -----------------------------------------------------------------------
       Cancellation activity
       ----------------------------------------------------------------------- */

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

    /* -----------------------------------------------------------------------
       Customer KPIs
       ----------------------------------------------------------------------- */

    ROUND(
        SUM(f.sales_amount) FILTER (
            WHERE f.transaction_type = 'Sale'
        )
        / NULLIF(
            COUNT(DISTINCT f.invoice_no) FILTER (
                WHERE f.transaction_type = 'Sale'
            ),
            0
        ),
        2
    ) AS average_order_value,

    ROUND(
        SUM(f.quantity) FILTER (
            WHERE f.transaction_type = 'Sale'
        )::NUMERIC
        / NULLIF(
            COUNT(DISTINCT f.invoice_no) FILTER (
                WHERE f.transaction_type = 'Sale'
            ),
            0
        ),
        2
    ) AS average_units_per_order,

    ROUND(
        AVG(f.unit_price) FILTER (
            WHERE f.transaction_type = 'Sale'
              AND f.unit_price > 0
        ),
        4
    ) AS average_unit_price,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE f.transaction_type = 'Return'
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE f.transaction_type = 'Sale'
            ),
            0
        ),
        2
    ) AS return_rate_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        )
        / NULLIF(
            COUNT(*) FILTER (
                WHERE f.transaction_type = 'Sale'
            ),
            0
        ),
        2
    ) AS cancellation_rate_pct,

    /* -----------------------------------------------------------------------
       Customer activity period
       ----------------------------------------------------------------------- */

    MIN(f.invoice_date) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS first_purchase_date,

    MAX(f.invoice_date) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS last_purchase_date,

    COUNT(DISTINCT f.stock_code) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS distinct_products_purchased

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL

GROUP BY
    f.customer_id;


/*
===============================================================================
VALIDATION
===============================================================================

1. Inspect the view
-------------------------------------------------------------------------------

SELECT *
FROM analytics.vw_customer_metrics
ORDER BY gross_sales DESC;


2. Validate customer count
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS view_customer_count,
    COUNT(DISTINCT customer_id) AS fact_customer_count
FROM analytics.vw_customer_metrics
CROSS JOIN (
    SELECT
        COUNT(DISTINCT customer_id) AS customer_count
    FROM analytics.fact_sales
    WHERE customer_id IS NOT NULL
) AS fact_counts;


3. Validate gross sales
-------------------------------------------------------------------------------

SELECT
    SUM(gross_sales) AS view_gross_sales,

    (
        SELECT
            SUM(sales_amount)
        FROM analytics.fact_sales
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS fact_gross_sales

FROM analytics.vw_customer_metrics;


4. Validate sales orders
-------------------------------------------------------------------------------

SELECT
    SUM(sales_orders) AS view_sales_orders,

    (
        SELECT
            COUNT(DISTINCT invoice_no)
        FROM analytics.fact_sales
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS fact_sales_orders

FROM analytics.vw_customer_metrics;


5. Check for duplicate customers
-------------------------------------------------------------------------------

SELECT
    customer_id,
    COUNT(*) AS row_count
FROM analytics.vw_customer_metrics
GROUP BY customer_id
HAVING COUNT(*) > 1;

Expected result:
    0 rows.

===============================================================================
*/
