/*
===============================================================================
04_business_rule_checks.sql

Purpose
-------
Validate business rules for the cleaned retail transaction model.

Sources
-------
analytics.fact_sales
analytics.dim_customer
analytics.dim_product
analytics.dim_country
analytics.dim_date

Business rules
--------------
1. Sale transactions should not have negative quantities.
2. Return transactions should have negative quantities.
3. Cancellation transactions normally represent negative merchandise movement.
4. Sale transactions must not be marked as returns.
5. Sale transactions must not be marked as cancellations.
6. Return transactions must be marked as returns.
7. Cancellation transactions must be marked as cancellations.
8. Sales amount must equal quantity * unit_price.
9. Every fact transaction must resolve to a valid product.
10. Every fact transaction must resolve to a valid country.
11. Invoice timestamp must match invoice date.
12. Analytically usable transactions must contain core measures.
13. Transaction classification must reconcile to the fact-table population.
14. Transaction flags must reconcile with transaction classifications.

Known source/business exceptions
--------------------------------
1. One Cancellation transaction has positive quantity and positive sales amount:

       Invoice:       C496350
       Stock code:    M
       Quantity:      1
       Unit price:    373.5700
       Sales amount:  373.5700
       is_cancelled:  TRUE
       is_return:     FALSE

   This is retained because it is a valid source record and is explicitly
   classified and flagged as a Cancellation.

2. Some Cancellation transactions are also marked as returns. This is expected
   from the source classification and is preserved.

3. Return transactions may have zero sales amount because of the source-data
   cleaning/business rules. This is retained rather than silently modified.

Important
---------
These checks are READ-ONLY.

Known source-data exceptions are reported and documented rather than silently
removed or transformed.

===============================================================================
*/


/*
===============================================================================
1. SALE TRANSACTIONS WITH NEGATIVE QUANTITY
===============================================================================

A Sale should represent positive merchandise movement.

Expected result: 0
===============================================================================
*/

SELECT
    'Sale - negative quantity' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Sale'
  AND quantity < 0;


/*
===============================================================================
2. RETURN TRANSACTIONS WITH NON-NEGATIVE QUANTITY
===============================================================================

Return transactions should have negative quantities.

Expected result: 0
===============================================================================
*/

SELECT
    'Return - non-negative quantity' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Return'
  AND quantity >= 0;


/*
===============================================================================
3. CANCELLATION TRANSACTIONS WITH NON-NEGATIVE QUANTITY
===============================================================================

Most Cancellation transactions represent cancelled/returned merchandise and
therefore have negative quantities.

One known source-level exception exists:

    Invoice:       C496350
    Stock code:    M
    Quantity:      1
    Unit price:    373.5700
    Sales amount:  373.5700

The record is classified as Cancellation and is_cancelled = TRUE, but has
positive quantity and positive sales amount.

Expected result: 1 known exception
===============================================================================
*/

SELECT
    'Cancellation - non-negative quantity (known exception)' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Cancellation'
  AND quantity >= 0;


/*
===============================================================================
4. SALE TRANSACTIONS MARKED AS RETURNS
===============================================================================

A Sale must not simultaneously be classified as a Return.

Expected result: 0
===============================================================================
*/

SELECT
    'Sale - incorrectly marked as return' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Sale'
  AND is_return = TRUE;


/*
===============================================================================
5. SALE TRANSACTIONS MARKED AS CANCELLATIONS
===============================================================================

A Sale must not simultaneously be classified as cancelled.

Expected result: 0
===============================================================================
*/

SELECT
    'Sale - incorrectly marked as cancellation' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Sale'
  AND is_cancelled = TRUE;


/*
===============================================================================
6. RETURN FLAG CONSISTENCY
===============================================================================

Every Return transaction should have is_return = TRUE.

Expected result: 0
===============================================================================
*/

SELECT
    'Return - missing return flag' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Return'
  AND is_return = FALSE;


/*
===============================================================================
7. CANCELLATION FLAG CONSISTENCY
===============================================================================

Every Cancellation transaction should have is_cancelled = TRUE.

Expected result: 0
===============================================================================
*/

SELECT
    'Cancellation - missing cancellation flag' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Cancellation'
  AND is_cancelled = FALSE;


/*
===============================================================================
8. SALES AMOUNT CALCULATION
===============================================================================

sales_amount should equal quantity * unit_price.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - amount calculation mismatch' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE ABS(
    sales_amount - (quantity * unit_price)
) > 0.0001;


/*
===============================================================================
9. INVALID PRODUCT BUSINESS REFERENCE
===============================================================================

Every fact transaction must resolve to a known product.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - unknown product' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_product AS p
    ON f.stock_code = p.stock_code
WHERE p.stock_code IS NULL;


/*
===============================================================================
10. INVALID COUNTRY BUSINESS REFERENCE
===============================================================================

Every fact transaction must resolve to a known country.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - unknown country' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key
WHERE c.country_key IS NULL;


/*
===============================================================================
11. INVOICE DATE / TIMESTAMP CONSISTENCY
===============================================================================

The date portion of invoice_timestamp must match invoice_date.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - timestamp/date mismatch' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE invoice_timestamp::DATE <> invoice_date;


/*
===============================================================================
12. ANALYTICALLY USABLE ROWS WITH MISSING CORE MEASURES
===============================================================================

Analytically usable transactions must have the core quantitative measures
required for sales analysis.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - usable row with missing measure' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE is_analytically_usable = TRUE
  AND (
        quantity IS NULL
        OR unit_price IS NULL
        OR sales_amount IS NULL
      );


/*
===============================================================================
13. ANALYTICALLY USABLE ROWS WITH MISSING PRODUCT
===============================================================================

Every analytically usable transaction must resolve to a product.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - usable row with missing product' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_product AS p
    ON f.stock_code = p.stock_code
WHERE f.is_analytically_usable = TRUE
  AND p.stock_code IS NULL;


/*
===============================================================================
14. ANALYTICALLY USABLE ROWS WITH MISSING COUNTRY
===============================================================================

Every analytically usable transaction must resolve to a country.

Expected result: 0
===============================================================================
*/

SELECT
    'Fact sales - usable row with missing country' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key
WHERE f.is_analytically_usable = TRUE
  AND c.country_key IS NULL;


/*
===============================================================================
15. TRANSACTION CLASSIFICATION DISTRIBUTION
===============================================================================

Provides the primary business-level reconciliation of transaction
classification.

Expected baseline:

    Sale                  1,010,539
    Return                    3,393
    Cancellation             19,104

Total:

    1,033,036
===============================================================================
*/

SELECT
    transaction_type,
    COUNT(*) AS row_count
FROM analytics.fact_sales
GROUP BY transaction_type
ORDER BY transaction_type;


/*
===============================================================================
16. TRANSACTION FLAG RECONCILIATION
===============================================================================

Reconcile transaction flags against transaction classifications.

Expected baseline:

    Cancellation:
        row_count              = 19,104
        return_flag_count      = 19,103
        cancellation_flag_count= 19,104

    Return:
        row_count              = 3,393
        return_flag_count      = 3,393
        cancellation_flag_count= 0

    Sale:
        row_count              = 1,010,539
        return_flag_count      = 0
        cancellation_flag_count= 0

The 19,103 Cancellation rows also marked as returns are a known source-level
classification characteristic and are preserved.
===============================================================================
*/

SELECT
    transaction_type,
    COUNT(*) AS row_count,
    COUNT(*) FILTER (
        WHERE is_return = TRUE
    ) AS return_flag_count,
    COUNT(*) FILTER (
        WHERE is_cancelled = TRUE
    ) AS cancellation_flag_count
FROM analytics.fact_sales
GROUP BY transaction_type
ORDER BY transaction_type;


/*
===============================================================================
17. BUSINESS MEASURE RECONCILIATION
===============================================================================

Summarize transaction volume, quantity, and sales amount by transaction type.

This establishes a baseline for downstream analytical SQL, views, Excel, and
Power BI reporting.
===============================================================================
*/

SELECT
    transaction_type,
    COUNT(*) AS transaction_rows,
    SUM(quantity) AS total_quantity,
    SUM(sales_amount) AS total_sales_amount
FROM analytics.fact_sales
GROUP BY transaction_type
ORDER BY transaction_type;


/*
===============================================================================
18. KNOWN CANCELLATION EXCEPTION DETAIL
===============================================================================

Explicitly validates the documented source-level Cancellation exception.

Expected result: exactly one row.

===============================================================================
*/

SELECT
    invoice_no,
    stock_code,
    invoice_timestamp,
    customer_id,
    quantity,
    unit_price,
    sales_amount,
    transaction_type,
    is_cancelled,
    is_return,
    source_sheet
FROM analytics.fact_sales
WHERE invoice_no = 'C496350'
  AND stock_code = 'M';


/*
===============================================================================
19. TOTAL FACT ROW RECONCILIATION
===============================================================================

Final business-rule population check.

Expected result: 1,033,036
===============================================================================
*/

SELECT
    COUNT(*) AS fact_row_count
FROM analytics.fact_sales;