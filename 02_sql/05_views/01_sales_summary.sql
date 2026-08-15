/*
===============================================================================
01_sales_summary.sql

Purpose
-------
Create a reusable monthly sales-summary view for Power BI, Excel, and
downstream analytics.

Grain
-----
One row per calendar month.

Business definitions
--------------------
Gross Sales
    Sales amount from Sale transactions.

Net Sales
    Sum of sales_amount across Sale, Return, and Cancellation transactions.

Sales Orders
    Distinct invoices associated with Sale transactions.

Units Sold
    Total quantity associated with Sale transactions.

Purchasing Customers
    Distinct known customers associated with Sale transactions.

Returns
    Reported separately and excluded from Gross Sales.

Cancellations
    Reported separately and excluded from Gross Sales.

Derived KPIs
------------
Average Order Value
    Gross Sales / Sales Orders.

Average Units per Order
    Units Sold / Sales Orders.

Average Unit Price
    Average positive unit price across Sale transactions.

Return Rate
    Return transaction lines / Sale transaction lines.

Cancellation Rate
    Cancellation transaction lines / Sale transaction lines.

===============================================================================
*/


CREATE OR REPLACE VIEW analytics.vw_sales_summary AS

SELECT
    /* -----------------------------------------------------------------------
       Calendar attributes
       ----------------------------------------------------------------------- */

    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    EXTRACT(
        YEAR FROM f.invoice_date
    )::INTEGER AS year,

    EXTRACT(
        MONTH FROM f.invoice_date
    )::INTEGER AS month_number,

    TO_CHAR(
        f.invoice_date,
        'YYYY-MM'
    ) AS year_month,

    /* -----------------------------------------------------------------------
       Sales activity
       ----------------------------------------------------------------------- */

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_orders,

    COUNT(DISTINCT f.customer_id) FILTER (
        WHERE f.transaction_type = 'Sale'
          AND f.customer_id IS NOT NULL
    ) AS purchasing_customers,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales,

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
       Net sales
       ----------------------------------------------------------------------- */

    SUM(f.sales_amount) AS net_sales,

    /* -----------------------------------------------------------------------
       Core order KPIs
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

    /* -----------------------------------------------------------------------
       Transaction rates
       ----------------------------------------------------------------------- */

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
    ) AS cancellation_rate_pct

FROM analytics.fact_sales AS f

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE,

    EXTRACT(
        YEAR FROM f.invoice_date
    ),

    EXTRACT(
        MONTH FROM f.invoice_date
    ),

    TO_CHAR(
        f.invoice_date,
        'YYYY-MM'
    );


/*
===============================================================================
VALIDATION
===============================================================================

1. Inspect monthly rows
-------------------------------------------------------------------------------

SELECT *
FROM analytics.vw_sales_summary
ORDER BY month_start;


2. Validate overall totals
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS view_rows,
    MIN(month_start) AS first_month,
    MAX(month_start) AS last_month,
    SUM(gross_sales) AS total_gross_sales,
    SUM(net_sales) AS total_net_sales,
    SUM(sales_orders) AS total_sales_orders,
    SUM(units_sold) AS total_units_sold,
    SUM(return_lines) AS total_return_lines,
    SUM(cancellation_lines) AS total_cancellation_lines
FROM analytics.vw_sales_summary;


3. Validate against fact_sales
-------------------------------------------------------------------------------

SELECT
    COUNT(DISTINCT DATE_TRUNC(
        'month',
        invoice_date
    )) AS fact_months,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_gross_sales,

    SUM(sales_amount) AS fact_net_sales,

    COUNT(DISTINCT invoice_no) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_sales_orders,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_units_sold

FROM analytics.fact_sales;


4. Check for duplicate months
-------------------------------------------------------------------------------

SELECT
    month_start,
    COUNT(*) AS row_count
FROM analytics.vw_sales_summary
GROUP BY month_start
HAVING COUNT(*) > 1;

Expected result:
    0 rows.

===============================================================================
*/
