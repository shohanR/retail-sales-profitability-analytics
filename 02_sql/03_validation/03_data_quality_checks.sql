/*
===============================================================================
03_data_quality_checks.sql

Purpose
-------
Perform comprehensive data-quality validation against the analytical retail
data model.

Sources
-------
analytics.fact_sales
analytics.dim_customer
analytics.dim_product
analytics.dim_country
analytics.dim_date

Validation areas
----------------
1. Quantity quality
2. Unit-price quality
3. Sales-amount quality
4. Date integrity
5. Customer integrity
6. Product integrity
7. Country integrity
8. Product-description completeness
9. Transaction classification consistency
10. Analytical usability

Important
---------
These checks are READ-ONLY. They do not modify source, staging, dimension,
or fact tables.

Known source-data characteristics are reported rather than automatically
treated as pipeline failures.

===============================================================================
KNOWN DATA-QUALITY EXCEPTIONS
===============================================================================

The following conditions were identified during the Python cleaning and SQL
validation stages.

1. Missing customer IDs
   ---------------------
   235,151 fact rows have NULL customer_id values.

   This is a known limitation of the source dataset. These transactions are
   retained for sales analysis while customer-level analysis excludes rows
   without a customer identifier.

2. Negative quantities
   --------------------
   22,496 fact rows have negative quantities.

   These correspond to return/cancellation activity and are expected.

3. Zero unit prices
   -----------------
   6,014 fact rows have a unit price of zero.

   These records are retained for traceability and downstream quality analysis.

4. Negative unit prices
   ---------------------
   5 fact rows have negative unit prices.

   These are source-data anomalies. They are retained rather than silently
   removed.

5. Negative sales amounts
   -----------------------
   19,108 fact rows have negative sales amounts.

   This consists of:
       - 19,103 cancellation/return rows
       - 5 Sale rows caused by the five negative unit-price records

6. Missing product descriptions
   -----------------------------
   355 products in dim_product have NULL/blank descriptions.

   This is a known source-data quality issue.

7. Source-level duplicate exceptions
   ----------------------------------
   Two transaction groups were identified during duplicate validation:

       Invoice 554084 / Stock 23298
       Invoice 575335 / Stock 23203

   These are caused by source-level description variation rather than
   unexplained duplicate transactions. The product dimension resolves each
   stock_code to one canonical description.

8. Invalid dimension references
   -----------------------------
   No invalid customer, product, country, or date references were found.

===============================================================================
*/


/*
===============================================================================
1. NEGATIVE QUANTITY
===============================================================================

Negative quantities are expected for return/cancellation activity.

Expected baseline: 22,496
===============================================================================
*/

SELECT
    'fact_sales - negative quantity' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE quantity < 0;


/*
===============================================================================
2. ZERO QUANTITY
===============================================================================

Zero-quantity transactions should not exist in the cleaned analytical fact.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - zero quantity' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE quantity = 0;


/*
===============================================================================
3. NEGATIVE UNIT PRICE
===============================================================================

Negative prices are retained for traceability but represent source-data
anomalies.

Expected baseline: 5
===============================================================================
*/

SELECT
    'fact_sales - negative unit price' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE unit_price < 0;


/*
===============================================================================
4. ZERO UNIT PRICE
===============================================================================

Zero prices are present in the source dataset and are retained.

Expected baseline: 6,014
===============================================================================
*/

SELECT
    'fact_sales - zero unit price' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE unit_price = 0;


/*
===============================================================================
5. NEGATIVE SALES AMOUNT
===============================================================================

Negative sales amounts are expected for return/cancellation transactions.

Five Sale records also have negative sales amounts because their unit prices
are negative in the source data.

Expected baseline: 19,108
===============================================================================
*/

SELECT
    'fact_sales - negative sales amount' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE sales_amount < 0;


/*
===============================================================================
6. SALES AMOUNT CALCULATION CONSISTENCY
===============================================================================

Validate that sales_amount is mathematically consistent with:

    quantity * unit_price

A small tolerance is used for decimal arithmetic.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - sales amount calculation mismatch' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE ABS(
    sales_amount - (quantity * unit_price)
) > 0.0001;


/*
===============================================================================
7. INVALID DATE REFERENCES
===============================================================================

Every fact invoice_date must have a corresponding record in dim_date.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - invalid date reference' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_date AS d
    ON f.invoice_date = d.date
WHERE d.date IS NULL;


/*
===============================================================================
8. MISSING CUSTOMER IDs
===============================================================================

NULL customer IDs are a known characteristic of the source data.

Expected baseline: 235,151
===============================================================================
*/

SELECT
    'fact_sales - missing customer_id' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE customer_id IS NULL;


/*
===============================================================================
9. INVALID CUSTOMER REFERENCES
===============================================================================

Every non-null customer_id must exist in dim_customer.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - invalid customer reference' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_customer AS c
    ON f.customer_id = c.customer_id
WHERE f.customer_id IS NOT NULL
  AND c.customer_id IS NULL;


/*
===============================================================================
10. INVALID PRODUCT REFERENCES
===============================================================================

Every stock_code in fact_sales must exist in dim_product.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - invalid product reference' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_product AS p
    ON f.stock_code = p.stock_code
WHERE p.stock_code IS NULL;


/*
===============================================================================
11. INVALID COUNTRY REFERENCES
===============================================================================

Every country_key in fact_sales must exist in dim_country.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - invalid country reference' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales AS f
LEFT JOIN analytics.dim_country AS c
    ON f.country_key = c.country_key
WHERE c.country_key IS NULL;


/*
===============================================================================
12. MISSING PRODUCT DESCRIPTIONS
===============================================================================

Products with NULL or blank descriptions are reported.

Expected baseline: 355
===============================================================================
*/

SELECT
    'dim_product - missing description' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.dim_product
WHERE description IS NULL
   OR TRIM(description) = '';


/*
===============================================================================
13. RETURN CLASSIFICATION CONSISTENCY
===============================================================================

A row marked as a return should have a negative quantity.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - return with non-negative quantity' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE is_return = TRUE
  AND quantity >= 0;


/*
===============================================================================
14. CANCELLATION CLASSIFICATION CONSISTENCY
===============================================================================

Cancelled transactions should be classified as Cancellation.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - cancellation classification' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE is_cancelled = TRUE
  AND transaction_type <> 'Cancellation';


/*
===============================================================================
15. RETURN FLAG CONSISTENCY
===============================================================================

Rows classified as Return/Cancellation return activity should have the
return flag enabled.

This check focuses on transactions explicitly classified as Return.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - return transaction without return flag' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Return'
  AND is_return = FALSE;


/*
===============================================================================
16. CANCELLATION FLAG CONSISTENCY
===============================================================================

Rows classified as Cancellation should have is_cancelled = TRUE.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - cancellation without cancellation flag' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE transaction_type = 'Cancellation'
  AND is_cancelled = FALSE;


/*
===============================================================================
17. ANALYTICAL USABILITY
===============================================================================

Report the number of fact rows currently marked as analytically usable.

Expected baseline: 1,033,036
===============================================================================
*/

SELECT
    'fact_sales - analytically usable' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE is_analytically_usable = TRUE;


/*
===============================================================================
18. NON-ANALYTICALLY-USABLE TRANSACTIONS
===============================================================================

This provides the complementary count to the previous check.

Expected baseline: 0
===============================================================================
*/

SELECT
    'fact_sales - non-analytically usable' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales
WHERE is_analytically_usable = FALSE;


/*
===============================================================================
19. FACT ROW COUNT
===============================================================================

Final row-count sanity check against the processed dataset.

Expected baseline: 1,033,036
===============================================================================
*/

SELECT
    'fact_sales - total row count' AS check_name,
    COUNT(*) AS issue_count
FROM analytics.fact_sales;