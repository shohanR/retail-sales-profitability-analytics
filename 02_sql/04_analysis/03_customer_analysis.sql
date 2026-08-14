/*
===============================================================================
03_customer_analysis.sql

Purpose
-------
Analyze customer-level purchasing behavior, sales contribution, customer
reach, purchasing frequency, and return/cancellation activity.

Sources
-------
analytics.fact_sales
analytics.dim_customer

Fact grain
----------
One row per cleaned transaction line.

Customer grain
--------------
One customer identified by customer_id.

Important
---------
Customer-level analysis intentionally distinguishes between:

    1. Transactions with a valid customer_id
    2. Transactions where customer_id is missing

Missing customer IDs are not fabricated, imputed, or silently discarded.

Because 235,151 fact rows have NULL customer_id, customer-level metrics
represent only transactions that can be attributed to a known customer.

Gross Sales
    Sales amount from Sale transactions.

Net Sales
    Sum of sales_amount across all transaction types.

Customer Revenue
    Gross Sale revenue attributable to a known customer.

Customer Frequency
    Number of distinct invoices associated with the customer.

===============================================================================
*/


/*
===============================================================================
1. CUSTOMER SALES PERFORMANCE
===============================================================================

Core customer-level commercial performance.

Only Sale transactions contribute to gross sales and units sold.

===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_invoices,

    SUM(f.quantity) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS units_sold,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(f.sales_amount) AS net_sales,

    AVG(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS average_sale_line_value

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

ORDER BY
    gross_sales DESC;


/*
===============================================================================
2. TOP 20 CUSTOMERS BY GROSS SALES
===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    SUM(f.sales_amount) AS gross_sales,

    SUM(f.quantity) AS units_sold,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    COUNT(*) AS sale_lines

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL
  AND f.transaction_type = 'Sale'

GROUP BY
    f.customer_id

ORDER BY
    gross_sales DESC

LIMIT 20;


/*
===============================================================================
3. TOP 20 CUSTOMERS BY UNITS SOLD
===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL
  AND f.transaction_type = 'Sale'

GROUP BY
    f.customer_id

ORDER BY
    units_sold DESC

LIMIT 20;


/*
===============================================================================
4. CUSTOMER SALES CONTRIBUTION
===============================================================================

Shows each customer's contribution to total known-customer gross sales.

===============================================================================
*/

WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(sales_amount) AS gross_sales
    FROM analytics.fact_sales
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
)

SELECT
    cs.customer_id,

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

FROM customer_sales AS cs

LEFT JOIN analytics.dim_customer AS c
    ON cs.customer_id = c.customer_id

ORDER BY
    cs.gross_sales DESC;


/*
===============================================================================
5. CUSTOMER VALUE SEGMENTATION
===============================================================================

Segments customers using gross-sales contribution ranking.

High Value
    Top 20% of customers by gross sales.

Mid Value
    Middle 50%.

Low Value
    Bottom 30%.

This is a portfolio-analysis segmentation, not a formal CRM policy.

===============================================================================
*/

WITH customer_sales AS (
    SELECT
        customer_id,
        SUM(sales_amount) AS gross_sales
    FROM analytics.fact_sales
    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL
    GROUP BY customer_id
),

ranked_customers AS (
    SELECT
        customer_id,
        gross_sales,

        NTILE(10) OVER (
            ORDER BY gross_sales DESC
        ) AS decile

    FROM customer_sales
)

SELECT
    rc.customer_id,

    c.country,

    rc.gross_sales,

    rc.decile,

    CASE
        WHEN rc.decile <= 2
            THEN 'High Value'

        WHEN rc.decile <= 7
            THEN 'Mid Value'

        ELSE 'Low Value'
    END AS customer_value_segment

FROM ranked_customers AS rc

LEFT JOIN analytics.dim_customer AS c
    ON rc.customer_id = c.customer_id

ORDER BY
    rc.gross_sales DESC;


/*
===============================================================================
6. CUSTOMER PURCHASE FREQUENCY
===============================================================================

Measures customer ordering frequency using distinct sales invoices.

===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    COUNT(*) AS sale_lines,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales,

    ROUND(
        SUM(f.sales_amount)
        / NULLIF(COUNT(DISTINCT f.invoice_no), 0),
        2
    ) AS average_invoice_value

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL
  AND f.transaction_type = 'Sale'

GROUP BY
    f.customer_id

ORDER BY
    sales_invoices DESC;


/*
===============================================================================
7. CUSTOMER RETURN ACTIVITY
===============================================================================

Identifies customers associated with Return transactions.

===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

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

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Return'
    ) > 0

ORDER BY
    return_lines DESC;


/*
===============================================================================
8. CUSTOMER RETURN RATE
===============================================================================

Return rate based on transaction-line counts.

===============================================================================
*/

WITH customer_activity AS (
    SELECT
        customer_id,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Sale'
        ) AS sale_lines,

        COUNT(*) FILTER (
            WHERE transaction_type = 'Return'
        ) AS return_lines

    FROM analytics.fact_sales

    WHERE customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    ca.customer_id,

    c.country,

    ca.sale_lines,

    ca.return_lines,

    ROUND(
        100.0 * ca.return_lines
        / NULLIF(ca.sale_lines, 0),
        2
    ) AS return_rate_pct

FROM customer_activity AS ca

LEFT JOIN analytics.dim_customer AS c
    ON ca.customer_id = c.customer_id

WHERE ca.sale_lines > 0

ORDER BY
    return_rate_pct DESC,
    ca.return_lines DESC;


/*
===============================================================================
9. CUSTOMER CANCELLATION ACTIVITY
===============================================================================
*/

SELECT
    f.customer_id,

    MAX(c.country) AS country,

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

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

HAVING
    COUNT(*) FILTER (
        WHERE f.transaction_type = 'Cancellation'
    ) > 0

ORDER BY
    cancellation_lines DESC;


/*
===============================================================================
10. CUSTOMER ANNUAL PERFORMANCE
===============================================================================

Tracks customer purchasing performance by year.

===============================================================================
*/

SELECT
    EXTRACT(YEAR FROM f.invoice_date)::INTEGER AS sales_year,

    f.customer_id,

    MAX(c.country) AS country,

    COUNT(DISTINCT f.invoice_no) AS sales_invoices,

    SUM(f.quantity) AS units_sold,

    SUM(f.sales_amount) AS gross_sales

FROM analytics.fact_sales AS f

LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id

WHERE f.customer_id IS NOT NULL
  AND f.transaction_type = 'Sale'

GROUP BY
    EXTRACT(YEAR FROM f.invoice_date),
    f.customer_id

ORDER BY
    sales_year,
    gross_sales DESC;


/*
===============================================================================
11. CUSTOMER FIRST AND LAST PURCHASE
===============================================================================

Establishes basic customer lifecycle timing from the available transaction
history.

===============================================================================
*/

SELECT
    f.customer_id,

    MIN(f.invoice_date) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS first_purchase_date,

    MAX(f.invoice_date) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS last_purchase_date,

    COUNT(DISTINCT f.invoice_no) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS sales_invoices,

    SUM(f.sales_amount) FILTER (
        WHERE f.transaction_type = 'Sale'
    ) AS gross_sales

FROM analytics.fact_sales AS f

WHERE f.customer_id IS NOT NULL

GROUP BY
    f.customer_id

ORDER BY
    last_purchase_date DESC;


/*
===============================================================================
12. CUSTOMER SALES WITHOUT CUSTOMER ID
===============================================================================

Explicitly quantifies the portion of sales that cannot be attributed to a
known customer.

Known baseline:
    235,151 fact rows have NULL customer_id.

===============================================================================
*/

SELECT
    COUNT(*) AS transactions_without_customer_id,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_lines_without_customer_id,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS units_sold_without_customer_id,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales_without_customer_id,

    SUM(sales_amount) AS net_sales_without_customer_id

FROM analytics.fact_sales

WHERE customer_id IS NULL;


/*
===============================================================================
13. KNOWN-CUSTOMER VS UNKNOWN-CUSTOMER SALES
===============================================================================

Compares customer-attributed sales with unattributed sales.

===============================================================================
*/

SELECT
    CASE
        WHEN customer_id IS NULL
            THEN 'Unknown Customer'
        ELSE 'Known Customer'
    END AS customer_attribution,

    COUNT(*) AS transaction_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_lines,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS units_sold,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales

FROM analytics.fact_sales

GROUP BY
    CASE
        WHEN customer_id IS NULL
            THEN 'Unknown Customer'
        ELSE 'Known Customer'
    END

ORDER BY
    gross_sales DESC;


/*
===============================================================================
14. CUSTOMER RANKING
===============================================================================

Ranks known customers by revenue, units, and invoice frequency.

===============================================================================
*/

WITH customer_metrics AS (
    SELECT
        customer_id,

        SUM(sales_amount) AS gross_sales,

        SUM(quantity) AS units_sold,

        COUNT(DISTINCT invoice_no) AS sales_invoices

    FROM analytics.fact_sales

    WHERE transaction_type = 'Sale'
      AND customer_id IS NOT NULL

    GROUP BY
        customer_id
)

SELECT
    cm.customer_id,

    c.country,

    cm.gross_sales,

    cm.units_sold,

    cm.sales_invoices,

    RANK() OVER (
        ORDER BY cm.gross_sales DESC
    ) AS revenue_rank,

    RANK() OVER (
        ORDER BY cm.units_sold DESC
    ) AS volume_rank,

    RANK() OVER (
        ORDER BY cm.sales_invoices DESC
    ) AS frequency_rank

FROM customer_metrics AS cm

LEFT JOIN analytics.dim_customer AS c
    ON cm.customer_id = c.customer_id

ORDER BY
    revenue_rank;


/*
===============================================================================
15. CUSTOMER PERFORMANCE SUMMARY
===============================================================================

Compact customer-level KPI baseline for downstream reporting.

===============================================================================
*/

SELECT
    COUNT(DISTINCT customer_id) AS customers_with_transactions,

    COUNT(DISTINCT customer_id) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS purchasing_customers,

    COUNT(DISTINCT invoice_no) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sales_invoices,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS customer_attributed_units_sold,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS customer_attributed_gross_sales,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS transactions_without_customer_id

FROM analytics.fact_sales;