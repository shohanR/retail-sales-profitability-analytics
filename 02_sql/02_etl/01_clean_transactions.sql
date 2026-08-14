-- Clean Transactions
-- This script performs data cleaning operations on transaction data

-- Remove duplicates
DELETE FROM stg_sales
WHERE transaction_id IN (
    SELECT transaction_id
    FROM stg_sales
    GROUP BY transaction_id
    HAVING COUNT(*) > 1
);

-- Handle null values in critical fields
UPDATE stg_sales
SET quantity = 0
WHERE quantity IS NULL;

UPDATE stg_sales
SET amount = 0
WHERE amount IS NULL;

-- Remove invalid dates
DELETE FROM stg_sales
WHERE transaction_date IS NULL
   OR transaction_date < '1900-01-01'
   OR transaction_date > GETDATE();

-- Remove negative amounts
DELETE FROM stg_sales
WHERE amount < 0;
