/*
===============================================================================
01_sales_performance.sql

Purpose
-------
Provide the core sales-performance analysis for the retail transaction model.

Source
------
analytics.fact_sales

Grain
-----
One row per cleaned transaction line.

Business definitions
--------------------
Gross Sales
    Sum of positive sales amounts from Sale transactions.

Returns
    Return transactions are reported separately because their sales amount
    may be zero in the source-cleaning model.

Cancellations
    Cancellation transactions are reported separately.

Net Sales
    Sum of sales_amount across all transactions.

Important
---------
This analysis does NOT silently remove source-data anomalies. Transaction
classification and analytical usability flags are preserved so downstream
analysis can make explicit business decisions.

===============================================================================
*/


/*
===============================================================================
1. OVERALL TRANSACTION PERFORMANCE
===============================================================================

Provides the primary business-performance baseline.

===============================================================================
*/

SELECT
    COUNT(*) AS total_transaction_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Return'
    ) AS return_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Cancellation'
    ) AS cancellation_lines,

    SUM(quantity) AS total_quantity,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sold_quantity,

    SUM(sales_amount) AS net_sales_amount,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales_amount,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Return'
    ) AS return_sales_amount,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Cancellation'
    ) AS cancellation_sales_amount

FROM analytics.fact_sales;


/*
===============================================================================
2. ANALYTICALLY USABLE SALES PERFORMANCE
===============================================================================

Focuses on transactions explicitly marked as analytically usable.

This provides the baseline for downstream KPI reporting.

===============================================================================
*/

SELECT
    COUNT(*) AS analytically_usable_rows,

    SUM(quantity) AS total_quantity,

    SUM(sales_amount) AS total_sales_amount,

    AVG(unit_price) AS average_unit_price,

    AVG(sales_amount) AS average_transaction_value

FROM analytics.fact_sales
WHERE is_analytically_usable = TRUE;


/*
===============================================================================
3. SALES KPIs
===============================================================================

Core commercial KPIs for management reporting.

===============================================================================
*/

SELECT
    SUM(sales_amount) AS net_sales,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_transaction_lines,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS units_sold,

    AVG(unit_price) FILTER (
        WHERE transaction_type = 'Sale'
          AND unit_price > 0
    ) AS average_selling_price,

    AVG(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS average_sale_line_value

FROM analytics.fact_sales
WHERE is_analytically_usable = TRUE;


/*
===============================================================================
4. TRANSACTION MIX
===============================================================================

Shows the relative contribution of each transaction classification.

===============================================================================
*/

SELECT
    transaction_type,

    COUNT(*) AS transaction_lines,

    ROUND(
        100.0 * COUNT(*) / SUM(COUNT(*)) OVER (),
        2
    ) AS transaction_line_pct,

    SUM(quantity) AS total_quantity,

    SUM(sales_amount) AS total_sales_amount,

    ROUND(
        100.0
        * SUM(sales_amount)
        / NULLIF(SUM(SUM(sales_amount)) OVER (), 0),
        2
    ) AS sales_amount_pct

FROM analytics.fact_sales

GROUP BY transaction_type

ORDER BY
    total_sales_amount DESC;


/*
===============================================================================
5. SALES BY YEAR
===============================================================================

Annual sales-performance baseline.

===============================================================================
*/

SELECT
    EXTRACT(YEAR FROM invoice_date)::INTEGER AS sales_year,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_lines,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS units_sold,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(sales_amount) AS net_sales

FROM analytics.fact_sales

GROUP BY
    EXTRACT(YEAR FROM invoice_date)

ORDER BY
    sales_year;


/*
===============================================================================
6. SALES BY YEAR AND TRANSACTION TYPE
===============================================================================

Provides a more detailed annual reconciliation.

===============================================================================
*/

SELECT
    EXTRACT(YEAR FROM invoice_date)::INTEGER AS sales_year,

    transaction_type,

    COUNT(*) AS transaction_lines,

    SUM(quantity) AS total_quantity,

    SUM(sales_amount) AS total_sales_amount

FROM analytics.fact_sales

GROUP BY
    EXTRACT(YEAR FROM invoice_date),
    transaction_type

ORDER BY
    sales_year,
    transaction_type;


/*
===============================================================================
7. CUSTOMER SALES COVERAGE
===============================================================================

Measures the number of customers represented in the transaction data.

Missing customer IDs are retained and explicitly excluded from customer-level
coverage metrics.

===============================================================================
*/

SELECT
    COUNT(DISTINCT customer_id) AS customers_with_customer_id,

    COUNT(DISTINCT customer_id) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS purchasing_customers,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS transactions_without_customer_id,

    SUM(sales_amount) FILTER (
        WHERE customer_id IS NULL
    ) AS sales_without_customer_id

FROM analytics.fact_sales;


/*
===============================================================================
8. AVERAGE ORDER-LINE VALUE
===============================================================================

Calculates the average sales value per transaction line.

This is deliberately line-level because the current fact table grain is one
row per cleaned transaction line.

===============================================================================
*/

SELECT
    AVG(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS average_sale_line_value,

    AVG(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS average_sale_line_value_with_customer

FROM analytics.fact_sales;


/*
===============================================================================
9. RETURN AND CANCELLATION RATES
===============================================================================

Calculates operational rates based on transaction-line counts.

===============================================================================
*/

SELECT
    COUNT(*) AS total_transaction_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Return'
    ) AS return_lines,

    COUNT(*) FILTER (
        WHERE transaction_type = 'Cancellation'
    ) AS cancellation_lines,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE transaction_type = 'Return'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS return_line_rate_pct,

    ROUND(
        100.0
        * COUNT(*) FILTER (
            WHERE transaction_type = 'Cancellation'
        )
        / NULLIF(COUNT(*), 0),
        2
    ) AS cancellation_line_rate_pct

FROM analytics.fact_sales;


/*
===============================================================================
10. SALES QUALITY OVERVIEW
===============================================================================

Provides a compact overview of records that may require special treatment
during downstream analysis.

===============================================================================
*/

SELECT
    COUNT(*) AS total_rows,

    COUNT(*) FILTER (
        WHERE is_analytically_usable = TRUE
    ) AS analytically_usable_rows,

    COUNT(*) FILTER (
        WHERE is_analytically_usable = FALSE
    ) AS analytically_unusable_rows,

    COUNT(*) FILTER (
        WHERE customer_id IS NULL
    ) AS missing_customer_rows,

    COUNT(*) FILTER (
        WHERE unit_price <= 0
    ) AS non_positive_price_rows,

    COUNT(*) FILTER (
        WHERE quantity < 0
    ) AS negative_quantity_rows,

    COUNT(*) FILTER (
        WHERE sales_amount < 0
    ) AS negative_sales_rows

FROM analytics.fact_sales;


/*
===============================================================================
11. TOP SALES DAYS
===============================================================================

Identifies the strongest days by gross Sale revenue.

Only Sale transactions are included.

===============================================================================
*/

SELECT
    invoice_date,

    COUNT(*) AS sale_lines,

    SUM(quantity) AS units_sold,

    SUM(sales_amount) AS gross_sales

FROM analytics.fact_sales

WHERE transaction_type = 'Sale'

GROUP BY
    invoice_date

ORDER BY
    gross_sales DESC

LIMIT 20;


/*
===============================================================================
12. SALES PERFORMANCE SUMMARY
===============================================================================

Final compact KPI output suitable for later validation against Excel and
Power BI.

===============================================================================
*/

SELECT
    COUNT(*) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sale_lines,

    SUM(quantity) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS units_sold,

    SUM(sales_amount) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS gross_sales,

    SUM(sales_amount) AS net_sales,

    COUNT(DISTINCT customer_id) FILTER (
        WHERE transaction_type = 'Sale'
          AND customer_id IS NOT NULL
    ) AS purchasing_customers,

    COUNT(DISTINCT stock_code) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS products_sold,

    COUNT(DISTINCT invoice_no) FILTER (
        WHERE transaction_type = 'Sale'
    ) AS sales_invoices

FROM analytics.fact_sales;