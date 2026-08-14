/*
===============================================================================
05_monthly_trends.sql

Purpose
-------
Analyze monthly sales trends, growth, seasonality, transaction activity,
customer activity, and year-over-year performance.

Sources
-------
analytics.fact_sales

Grain
-----
One row per calendar month.

Business definitions
--------------------
Gross Sales
    Sales amount from Sale transactions.

Units Sold
    Quantity from Sale transactions.

Sales Orders
    Distinct invoice numbers from Sale transactions.

Purchasing Customers
    Distinct known customer IDs associated with Sale transactions.

Important
---------
Returns and cancellations are reported separately.

They are not mixed into Gross Sales because Gross Sales represents
commercial sales activity.

===============================================================================
*/


/*
===============================================================================
1. MONTHLY SALES PERFORMANCE
===============================================================================

Core monthly commercial performance.

===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

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

    SUM(f.sales_amount) AS net_sales

FROM analytics.fact_sales AS f

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    month_start;


/*
===============================================================================
2. MONTHLY SALES WITH MONTH-OVER-MONTH GROWTH
===============================================================================

Calculates absolute and percentage MoM growth.

===============================================================================
*/

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        SUM(sales_amount) AS gross_sales

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    gross_sales,

    LAG(gross_sales) OVER (
        ORDER BY month_start
    ) AS previous_month_sales,

    gross_sales
        - LAG(gross_sales) OVER (
            ORDER BY month_start
        ) AS sales_change,

    ROUND(
        100.0
        * (
            gross_sales
            - LAG(gross_sales) OVER (
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(gross_sales) OVER (
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS mom_growth_pct

FROM monthly_sales

ORDER BY
    month_start;


/*
===============================================================================
3. MONTHLY UNITS WITH MONTH-OVER-MONTH GROWTH
===============================================================================
*/

WITH monthly_units AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        SUM(quantity) AS units_sold

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    units_sold,

    LAG(units_sold) OVER (
        ORDER BY month_start
    ) AS previous_month_units,

    units_sold
        - LAG(units_sold) OVER (
            ORDER BY month_start
        ) AS unit_change,

    ROUND(
        100.0
        * (
            units_sold
            - LAG(units_sold) OVER (
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(units_sold) OVER (
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS mom_unit_growth_pct

FROM monthly_units

ORDER BY
    month_start;


/*
===============================================================================
4. MONTHLY ORDER PERFORMANCE
===============================================================================

Tracks order volume and average order value.

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
5. MONTHLY CUSTOMER ACTIVITY
===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    COUNT(DISTINCT f.customer_id) AS purchasing_customers,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.customer_id), 0),
        2
    ) AS sales_per_customer,

    ROUND(
        COUNT(DISTINCT f.invoice_no)::NUMERIC
        / NULLIF(COUNT(DISTINCT f.customer_id), 0),
        2
    ) AS orders_per_customer

FROM analytics.fact_sales AS f

WHERE f.transaction_type = 'Sale'
  AND f.customer_id IS NOT NULL

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    month_start;


/*
===============================================================================
6. MONTHLY TRANSACTION MIX
===============================================================================

Shows sales, returns, and cancellations by month.

===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    COUNT(*) AS total_transaction_lines,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS return_lines,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancellation_lines,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sold_quantity,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS returned_quantity,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancelled_quantity,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Return'
    ) AS return_sales_amount,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) AS cancellation_sales_amount

FROM analytics.fact_sales AS f

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    month_start;


/*
===============================================================================
7. MONTHLY RETURN RATE
===============================================================================

Return rate based on transaction-line counts.

===============================================================================
*/

WITH monthly_activity AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS sale_lines,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Return'
        ) AS return_lines

    FROM analytics.fact_sales

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    sale_lines,

    return_lines,

    ROUND(
        100.0 * return_lines
        / NULLIF(sale_lines, 0),
        2
    ) AS return_rate_pct

FROM monthly_activity

WHERE sale_lines > 0

ORDER BY
    month_start;


/*
===============================================================================
8. MONTHLY CANCELLATION RATE
===============================================================================
*/

WITH monthly_activity AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS sale_lines,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Cancellation'
        ) AS cancellation_lines

    FROM analytics.fact_sales

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    sale_lines,

    cancellation_lines,

    ROUND(
        100.0 * cancellation_lines
        / NULLIF(sale_lines, 0),
        2
    ) AS cancellation_rate_pct

FROM monthly_activity

WHERE sale_lines > 0

ORDER BY
    month_start;


/*
===============================================================================
9. MONTHLY YEAR-OVER-YEAR PERFORMANCE
===============================================================================

Compares each month against the same calendar month in the previous year.

===============================================================================
*/

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        SUM(sales_amount) AS gross_sales,

        SUM(quantity) AS units_sold,

        COUNT(DISTINCT invoice_no) AS sales_orders,

        COUNT(DISTINCT customer_id)
            FILTER (
                WHERE customer_id IS NOT NULL
            ) AS purchasing_customers

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    gross_sales,

    LAG(gross_sales, 12) OVER (
        ORDER BY month_start
    ) AS same_month_previous_year_sales,

    ROUND(
        100.0
        * (
            gross_sales
            - LAG(gross_sales, 12) OVER (
                ORDER BY month_start
            )
        )
        / NULLIF(
            LAG(gross_sales, 12) OVER (
                ORDER BY month_start
            ),
            0
        ),
        2
    ) AS yoy_sales_growth_pct,

    units_sold,

    sales_orders,

    purchasing_customers

FROM monthly_sales

ORDER BY
    month_start;


/*
===============================================================================
10. MONTH-OF-YEAR SEASONALITY
===============================================================================

Aggregates performance by calendar month number.

Useful for identifying recurring seasonal patterns across years.

===============================================================================
*/

SELECT
    EXTRACT(
        MONTH FROM f.invoice_date
    )::INTEGER AS month_number,

    TO_CHAR(
        f.invoice_date,
        'Month'
    ) AS month_name,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        AVG(f.sales_amount),
        2
    ) AS average_sale_line_value

FROM analytics.fact_sales AS f

WHERE f.transaction_type = 'Sale'

GROUP BY
    EXTRACT(
        MONTH FROM f.invoice_date
    ),
    TO_CHAR(
        f.invoice_date,
        'Month'
    )

ORDER BY
    month_number;


/*
===============================================================================
11. TOP 12 MONTHS BY GROSS SALES
===============================================================================

Identifies the strongest individual calendar months.

===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    SUM(f.sales_amount) AS gross_sales,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers

FROM analytics.fact_sales AS f

WHERE f.transaction_type = 'Sale'

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    gross_sales DESC

LIMIT 12;


/*
===============================================================================
12. BOTTOM 12 MONTHS BY GROSS SALES
===============================================================================
*/

SELECT
    DATE_TRUNC(
        'month',
        f.invoice_date
    )::DATE AS month_start,

    SUM(f.sales_amount) AS gross_sales,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.invoice_no) AS sales_orders,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers

FROM analytics.fact_sales AS f

WHERE f.transaction_type = 'Sale'

GROUP BY
    DATE_TRUNC(
        'month',
        f.invoice_date
    )

ORDER BY
    gross_sales ASC

LIMIT 12;


/*
===============================================================================
13. ROLLING 3-MONTH SALES
===============================================================================

Smooths short-term volatility.

===============================================================================
*/

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        SUM(sales_amount) AS gross_sales

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    gross_sales,

    ROUND(
        AVG(gross_sales) OVER (
            ORDER BY month_start
            ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_3_month_avg_sales,

    SUM(gross_sales) OVER (
        ORDER BY month_start
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ) AS rolling_3_month_sales

FROM monthly_sales

ORDER BY
    month_start;


/*
===============================================================================
14. ROLLING 12-MONTH SALES
===============================================================================

Provides a longer-term trend view.

===============================================================================
*/

WITH monthly_sales AS (
    SELECT
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE AS month_start,

        SUM(sales_amount) AS gross_sales

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'

    GROUP BY
        DATE_TRUNC(
            'month',
            invoice_date
        )
)

SELECT
    month_start,

    gross_sales,

    SUM(gross_sales) OVER (
        ORDER BY month_start
        ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
    ) AS rolling_12_month_sales,

    ROUND(
        AVG(gross_sales) OVER (
            ORDER BY month_start
            ROWS BETWEEN 11 PRECEDING AND CURRENT ROW
        ),
        2
    ) AS rolling_12_month_avg_sales

FROM monthly_sales

ORDER BY
    month_start;


/*
===============================================================================
15. MONTHLY PERFORMANCE SUMMARY
===============================================================================

Compact KPI baseline for downstream reporting.

===============================================================================
*/

SELECT
    COUNT(DISTINCT DATE_TRUNC(
        'month',
        invoice_date
    )) AS active_months,

    MIN(
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE
    ) AS first_month,

    MAX(
        DATE_TRUNC(
            'month',
            invoice_date
        )::DATE
    ) AS last_month,

    COUNT(DISTINCT invoice_no) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS total_sales_orders,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS total_units_sold,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS total_gross_sales

FROM analytics.fact_sales;