/*
===============================================================================
04_monthly_performance.sql

Purpose
-------
Create a reusable monthly performance view for Power BI, Excel, and
downstream SQL reporting.

View
----
analytics.vw_monthly_performance

Grain
-----
One row per calendar month.

Sources
-------
analytics.fact_sales

Business definitions
--------------------
Gross Sales
    Sales amount from Sale transactions.

Net Sales
    Sum of sales_amount across all transaction types.

Sales Orders
    Distinct invoices associated with Sale transactions.

Units Sold
    Total quantity associated with Sale transactions.

Purchasing Customers
    Distinct known customers associated with Sale transactions.

Average Order Value
    Gross Sales / Sales Orders.

Average Units per Order
    Units Sold / Sales Orders.

Month-over-Month Growth
    Current-month gross sales compared with the immediately preceding
    month in the available monthly series.

Year-over-Year Growth
    Current-month gross sales compared with the same calendar month in
    the prior year, when available.

Returns and cancellations
    Reported separately from Gross Sales.

Important
---------
- Monthly reporting uses invoice_date for calendar aggregation.
- invoice_timestamp remains available in fact_sales for transaction-time
  analysis but is not used as the monthly reporting grain.
- Missing customer IDs remain in fact_sales and are excluded only from
  customer-attribution metrics.
- Returns and cancellations are preserved and reported separately.
===============================================================================
*/


CREATE OR REPLACE VIEW analytics.vw_monthly_performance AS

WITH monthly_metrics AS (

    SELECT
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

        /* -------------------------------------------------------------------
           Sales activity
           ------------------------------------------------------------------- */

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

        /* -------------------------------------------------------------------
           Overall financial activity
           ------------------------------------------------------------------- */

        SUM(f.sales_amount) AS net_sales,

        /* -------------------------------------------------------------------
           Returns
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
           Cancellations
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
        ) AS cancellation_sales_amount

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
        )
),

performance_metrics AS (

    SELECT
        mm.*,

        /* -------------------------------------------------------------------
           Core monthly KPIs
           ------------------------------------------------------------------- */

        ROUND(
            mm.gross_sales
            / NULLIF(mm.sales_orders, 0),
            2
        ) AS average_order_value,

        ROUND(
            mm.units_sold::NUMERIC
            / NULLIF(mm.sales_orders, 0),
            2
        ) AS average_units_per_order,

        ROUND(
            100.0
            * mm.return_lines
            / NULLIF(mm.sale_lines, 0),
            2
        ) AS return_rate_pct,

        ROUND(
            100.0
            * mm.cancellation_lines
            / NULLIF(mm.sale_lines, 0),
            2
        ) AS cancellation_rate_pct,

        /* -------------------------------------------------------------------
           Month-over-month metrics
           ------------------------------------------------------------------- */

        LAG(mm.gross_sales) OVER (
            ORDER BY mm.month_start
        ) AS previous_month_gross_sales,

        LAG(mm.units_sold) OVER (
            ORDER BY mm.month_start
        ) AS previous_month_units_sold,

        LAG(mm.sales_orders) OVER (
            ORDER BY mm.month_start
        ) AS previous_month_sales_orders,

        /* -------------------------------------------------------------------
           Year-over-year metrics
           ------------------------------------------------------------------- */

        LAG(mm.gross_sales, 12) OVER (
            ORDER BY mm.month_start
        ) AS same_month_previous_year_gross_sales,

        LAG(mm.units_sold, 12) OVER (
            ORDER BY mm.month_start
        ) AS same_month_previous_year_units_sold,

        LAG(mm.sales_orders, 12) OVER (
            ORDER BY mm.month_start
        ) AS same_month_previous_year_sales_orders

    FROM monthly_metrics AS mm
)

SELECT
    month_start,
    year,
    month_number,
    year_month,

    /* -----------------------------------------------------------------------
       Sales activity
       ----------------------------------------------------------------------- */

    sale_lines,
    sales_orders,
    purchasing_customers,
    units_sold,
    gross_sales,

    /* -----------------------------------------------------------------------
       Overall financial activity
       ----------------------------------------------------------------------- */

    net_sales,

    /* -----------------------------------------------------------------------
       Returns
       ----------------------------------------------------------------------- */

    return_lines,
    return_orders,
    returned_units,
    return_sales_amount,

    /* -----------------------------------------------------------------------
       Cancellations
       ----------------------------------------------------------------------- */

    cancellation_lines,
    cancellation_orders,
    cancelled_units,
    cancellation_sales_amount,

    /* -----------------------------------------------------------------------
       Core KPIs
       ----------------------------------------------------------------------- */

    average_order_value,
    average_units_per_order,
    return_rate_pct,
    cancellation_rate_pct,

    /* -----------------------------------------------------------------------
       Month-over-month comparison
       ----------------------------------------------------------------------- */

    previous_month_gross_sales,

    gross_sales
        - previous_month_gross_sales AS mom_sales_change,

    ROUND(
        100.0
        * (
            gross_sales
            - previous_month_gross_sales
        )
        / NULLIF(
            previous_month_gross_sales,
            0
        ),
        2
    ) AS mom_sales_growth_pct,

    previous_month_units_sold,

    units_sold
        - previous_month_units_sold AS mom_units_change,

    ROUND(
        100.0
        * (
            units_sold
            - previous_month_units_sold
        )
        / NULLIF(
            previous_month_units_sold,
            0
        ),
        2
    ) AS mom_units_growth_pct,

    previous_month_sales_orders,

    sales_orders
        - previous_month_sales_orders AS mom_orders_change,

    ROUND(
        100.0
        * (
            sales_orders
            - previous_month_sales_orders
        )
        / NULLIF(
            previous_month_sales_orders,
            0
        ),
        2
    ) AS mom_orders_growth_pct,

    /* -----------------------------------------------------------------------
       Year-over-year comparison
       ----------------------------------------------------------------------- */

    same_month_previous_year_gross_sales,

    gross_sales
        - same_month_previous_year_gross_sales AS yoy_sales_change,

    ROUND(
        100.0
        * (
            gross_sales
            - same_month_previous_year_gross_sales
        )
        / NULLIF(
            same_month_previous_year_gross_sales,
            0
        ),
        2
    ) AS yoy_sales_growth_pct,

    same_month_previous_year_units_sold,

    units_sold
        - same_month_previous_year_units_sold AS yoy_units_change,

    ROUND(
        100.0
        * (
            units_sold
            - same_month_previous_year_units_sold
        )
        / NULLIF(
            same_month_previous_year_units_sold,
            0
        ),
        2
    ) AS yoy_units_growth_pct,

    same_month_previous_year_sales_orders,

    sales_orders
        - same_month_previous_year_sales_orders AS yoy_orders_change,

    ROUND(
        100.0
        * (
            sales_orders
            - same_month_previous_year_sales_orders
        )
        / NULLIF(
            same_month_previous_year_sales_orders,
            0
        ),
        2
    ) AS yoy_orders_growth_pct

FROM performance_metrics;


/*
===============================================================================
VALIDATION
===============================================================================

1. Inspect monthly performance
-------------------------------------------------------------------------------

SELECT *
FROM analytics.vw_monthly_performance
ORDER BY month_start;


2. Validate row count and date range
-------------------------------------------------------------------------------

SELECT
    COUNT(*) AS view_rows,
    MIN(month_start) AS first_month,
    MAX(month_start) AS last_month
FROM analytics.vw_monthly_performance;


3. Validate gross sales and order totals
-------------------------------------------------------------------------------

SELECT
    SUM(gross_sales) AS view_gross_sales,
    SUM(sales_orders) AS view_sales_orders,
    SUM(units_sold) AS view_units_sold

FROM analytics.vw_monthly_performance;


4. Compare against fact_sales
-------------------------------------------------------------------------------

SELECT
    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_gross_sales,

    COUNT(DISTINCT invoice_no) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_sales_orders,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS fact_units_sold

FROM analytics.fact_sales;


5. Check for duplicate months
-------------------------------------------------------------------------------

SELECT
    month_start,
    COUNT(*) AS row_count
FROM analytics.vw_monthly_performance
GROUP BY month_start
HAVING COUNT(*) > 1;

Expected result:
    0 rows.


6. Check chronological ordering / MoM baseline
-------------------------------------------------------------------------------

SELECT
    month_start,
    previous_month_gross_sales,
    mom_sales_growth_pct
FROM analytics.vw_monthly_performance
ORDER BY month_start;

The first available month should have NULL previous-month metrics.


7. Check YoY baseline
-------------------------------------------------------------------------------

SELECT
    month_start,
    same_month_previous_year_gross_sales,
    yoy_sales_growth_pct
FROM analytics.vw_monthly_performance
ORDER BY month_start;

The first 12 months should normally have NULL prior-year comparison metrics.

===============================================================================
*/