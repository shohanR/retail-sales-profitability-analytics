/*
===============================================================================
02_duplicate_checks.sql

Purpose
-------
Identify duplicate transaction rows and validate the expected transaction
grain of the analytical fact table.
===============================================================================
*/

/*
Known source-level exceptions
------------------------------
Two duplicate transaction groups remain after loading because the source
contains multiple descriptions for the same stock_code within the same
invoice/timestamp/customer/quantity/price combination.

Affected transactions:
- Invoice 554084 / Stock 23298
- Invoice 575335 / Stock 23203

These are not treated as duplicate products. dim_product resolves each
stock_code to one canonical description.

Therefore, duplicate results from this query must be reconciled against
these documented source-level exceptions.
*/

/*
===============================================================================
01. Broad Duplicate Detection — finds candidate duplicates.
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
    COUNT(*) AS duplicate_count
FROM analytics.fact_sales
GROUP BY
    invoice_no,
    stock_code,
    invoice_timestamp,
    customer_id,
    quantity,
    unit_price,
    sales_amount
HAVING COUNT(*) > 1
ORDER BY duplicate_count DESC;

/*
===============================================================================
02. Duplicate investigation — confirms whether they are genuinely identical.
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
    source_sheet,
    COUNT(*) AS row_count
FROM analytics.fact_sales
WHERE (invoice_no, stock_code, invoice_date, customer_id, quantity, unit_price, sales_amount)
IN (
    ('492807', '21813', '2009-12-20', 17211, 6, 4.95, 29.70),
    ('554084', '23298', '2011-05-22', 12909, 3, 4.95, 14.85),
    ('567183', '22659', '2011-09-18', 14769, 2, 1.95, 3.90),
    ('575335', '23203', '2011-11-09', 12931, 300, 1.79, 537.00)
)
GROUP BY
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
ORDER BY invoice_no;

/*
===============================================================================
03. Duplicate impact summary — quantifies the duplicate problem.
===============================================================================
*/

SELECT
    COUNT(*) AS duplicate_groups,
    SUM(row_count - 1) AS excess_duplicate_rows
FROM (
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
        source_sheet,
        COUNT(*) AS row_count
    FROM analytics.fact_sales
    GROUP BY
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
    HAVING COUNT(*) > 1
) d;


/*
===============================================================================
04. unexplained duplicates
===============================================================================
*/

SELECT
    COUNT(*) AS unexplained_duplicate_groups,
    COALESCE(SUM(duplicate_count - 1), 0) AS unexplained_excess_rows
FROM (
    SELECT
        invoice_no,
        stock_code,
        invoice_timestamp,
        customer_id,
        quantity,
        unit_price,
        sales_amount,
        COUNT(*) AS duplicate_count
    FROM analytics.fact_sales
    GROUP BY
        invoice_no,
        stock_code,
        invoice_timestamp,
        customer_id,
        quantity,
        unit_price,
        sales_amount
    HAVING COUNT(*) > 1
) AS duplicates
WHERE NOT (
    (invoice_no = '554084' AND stock_code = '23298')
    OR
    (invoice_no = '575335' AND stock_code = '23203')
);