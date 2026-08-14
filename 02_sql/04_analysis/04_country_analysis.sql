/*
===============================================================================
04_country_analysis.sql

Purpose
-------
Analyze sales performance, customer reach, transaction activity, and
operational behavior by country.

Sources
-------
analytics.fact_sales
analytics.dim_country

Grain
-----
One row per country in country-level summaries.

Important
---------
Country analysis includes all transactions with a valid country_key.

Sale transactions are used for commercial performance metrics.

Returns and cancellations are analyzed separately so that negative
transaction activity is not confused with gross sales performance.

===============================================================================
*/


/*
===============================================================================
1. COUNTRY SALES PERFORMANCE
===============================================================================

Core commercial performance by country.

===============================================================================
*/

SELECT
    c.country,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_invoices,

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

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

GROUP BY
    c.country

ORDER BY
    gross_sales DESC;


/*
===============================================================================
2. TOP 20 COUNTRIES BY GROSS SALES
===============================================================================
*/

SELECT
    c.country,

    SUM(f.sales_amount) AS gross_sales,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'

GROUP BY
    c.country

ORDER BY
    gross_sales DESC

LIMIT 20;


/*
===============================================================================
3. COUNTRY SALES CONTRIBUTION
===============================================================================

Measures each country's contribution to total gross sales.

===============================================================================
*/

WITH country_sales AS (
    SELECT
        f.country_key,
        SUM(f.sales_amount) AS gross_sales
    FROM analytics.fact_sales AS f
    WHERE f.transaction_type = 'Sale'
    GROUP BY f.country_key
)

SELECT
    c.country,

    cs.gross_sales,

    ROUND(
        100.0 * cs.gross_sales
        / NULLIF(SUM(cs.gross_sales) OVER (), 0),
        2
    ) AS gross_sales_contribution_pct,

    SUM(cs.gross_sales) OVER (
        ORDER BY cs.gross_sales DESC
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_gross_sales,

    ROUND(
        100.0
        * SUM(cs.gross_sales) OVER (
            ORDER BY cs.gross_sales DESC
            ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
        )
        / NULLIF(SUM(cs.gross_sales) OVER (), 0),
        2
    ) AS cumulative_sales_pct

FROM country_sales AS cs

INNER JOIN analytics.dim_country AS c
    ON cs.country_key = c.country_key

ORDER BY
    cs.gross_sales DESC;


/*
===============================================================================
4. COUNTRY CUSTOMER REACH
===============================================================================

Measures the number of distinct known customers purchasing from each country.

===============================================================================
*/

SELECT
    c.country,

    COUNT(DISTINCT f.customer_id) AS customers,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.customer_id), 0),
        2
    ) AS sales_per_customer

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'
  AND f.customer_id IS NOT NULL

GROUP BY
    c.country

ORDER BY
    customers DESC;


/*
===============================================================================
5. COUNTRY AVERAGE ORDER VALUE
===============================================================================

Average gross sales per sales invoice.

===============================================================================
*/

SELECT
    c.country,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.invoice_no), 0),
        2
    ) AS average_order_value

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'

GROUP BY
    c.country

ORDER BY
    average_order_value DESC;


/*
===============================================================================
6. COUNTRY RETURN ACTIVITY
===============================================================================
*/

SELECT
    c.country,

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

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

GROUP BY
    c.country

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Return'
    ) > 0

ORDER BY
    return_lines DESC;


/*
===============================================================================
7. COUNTRY RETURN RATE
===============================================================================

Return rate based on transaction-line counts.

===============================================================================
*/

WITH country_activity AS (
    SELECT
        country_key,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS sale_lines,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Return'
        ) AS return_lines

    FROM analytics.fact_sales

    GROUP BY
        country_key
)

SELECT
    c.country,

    ca.sale_lines,

    ca.return_lines,

    ROUND(
        100.0 * ca.return_lines
        / NULLIF(ca.sale_lines, 0),
        2
    ) AS return_rate_pct

FROM country_activity AS ca

INNER JOIN analytics.dim_country AS c
    ON ca.country_key = c.country_key

WHERE ca.sale_lines > 0

ORDER BY
    return_rate_pct DESC,
    return_lines DESC;


/*
===============================================================================
8. COUNTRY CANCELLATION ACTIVITY
===============================================================================
*/

SELECT
    c.country,

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

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

GROUP BY
    c.country

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) > 0

ORDER BY
    cancellation_lines DESC;


/*
===============================================================================
9. COUNTRY TRANSACTION MIX
===============================================================================

Shows the distribution of Sale, Return, and Cancellation transactions.

===============================================================================
*/

SELECT
    c.country,

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

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE f.transaction_type = 'Sale'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS sale_mix_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE f.transaction_type = 'Return'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS return_mix_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE f.transaction_type = 'Cancellation'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_mix_pct

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

GROUP BY
    c.country

ORDER BY
    total_transaction_lines DESC;


/*
===============================================================================
10. COUNTRY ANNUAL PERFORMANCE
===============================================================================

Tracks country performance over time.

===============================================================================
*/

SELECT
    EXTRACT(YEAR FROM f.invoice_date)::INTEGER AS sales_year,

    c.country,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'

GROUP BY
    EXTRACT(YEAR FROM f.invoice_date),
    c.country

ORDER BY
    sales_year,
    gross_sales DESC;


/*
===============================================================================
11. COUNTRY RANKING
===============================================================================

Ranks countries by revenue, volume, and customer reach.

===============================================================================
*/

WITH country_metrics AS (
    SELECT
        f.country_key,

        SUM(f.sales_amount) AS gross_sales,

        SUM(f.quantity) AS units_sold,

        COUNT(DISTINCT f.customer_id)
            FILTER (
                WHERE f.customer_id IS NOT NULL
            ) AS purchasing_customers

    FROM analytics.fact_sales AS f

    WHERE f.transaction_type = 'Sale'

    GROUP BY
        f.country_key
)

SELECT
    c.country,

    cm.gross_sales,

    cm.units_sold,

    cm.purchasing_customers,

    RANK() OVER (
        ORDER BY cm.gross_sales DESC
    ) AS revenue_rank,

    RANK() OVER (
        ORDER BY cm.units_sold DESC
    ) AS volume_rank,

    RANK() OVER (
        ORDER BY cm.purchasing_customers DESC
    ) AS customer_reach_rank

FROM country_metrics AS cm

INNER JOIN analytics.dim_country AS c
    ON cm.country_key = c.country_key

ORDER BY
    revenue_rank;


/*
===============================================================================
12. LOW-VOLUME COUNTRIES
===============================================================================

Countries with limited sales activity.

Useful for identifying smaller markets.

===============================================================================
*/

SELECT
    c.country,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    COUNT(DISTINCT f.customer_id)
        FILTER (
            WHERE f.customer_id IS NOT NULL
        ) AS purchasing_customers,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales

FROM analytics.fact_sales AS f

INNER JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key

WHERE f.transaction_type = 'Sale'

GROUP BY
    c.country

HAVING
    COUNT(DISTINCT f.invoice_no) <= 10

ORDER BY
    gross_sales DESC;


/*
===============================================================================
13. COUNTRY DATA-COVERAGE CHECK
===============================================================================

Confirms that all fact rows resolve to a valid country dimension record.

===============================================================================
*/

SELECT
    COUNT(*) AS total_fact_rows,

    COUNT(*) FILTER (
        WHERE f.country_key IS NULL
    ) AS missing_country_key,

    COUNT(*) FILTER (
        WHERE c.country_key IS NULL
    ) AS invalid_country_reference

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key;


/*
===============================================================================
14. COUNTRY PERFORMANCE SUMMARY
===============================================================================

Compact country-level KPI baseline for downstream reporting.

===============================================================================
*/

SELECT
    COUNT(DISTINCT f.country_key) AS active_countries,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_invoices,

    COUNT(DISTINCT f.customer_id) FILTER (
        WHERE f.transaction_type = 'Sale'
          AND f.customer_id IS NOT NULL
    ) AS purchasing_customers,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS total_units_sold,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS total_gross_sales

FROM analytics.fact_sales AS f;