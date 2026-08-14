/*
===============================================================================
03_create_fact_sales.sql

Purpose
-------
Create the central retail transaction fact table.

Grain
-----
One row represents one cleaned transaction line.

The table intentionally retains transaction-level quality and classification
attributes so downstream reporting can distinguish sales, returns,
cancellations, and data-quality exceptions.
===============================================================================
*/

BEGIN;

CREATE TABLE IF NOT EXISTS analytics.fact_sales (
    sales_key BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,

    invoice_no TEXT NOT NULL,

    stock_code TEXT NOT NULL,

    invoice_date DATE NOT NULL,

    invoice_timestamp TIMESTAMP,

    customer_id INTEGER,

    country_key INTEGER NOT NULL,

    quantity INTEGER NOT NULL,

    unit_price NUMERIC(18, 4) NOT NULL,

    sales_amount NUMERIC(18, 4) NOT NULL,

    transaction_type TEXT NOT NULL,

    is_cancelled BOOLEAN NOT NULL,

    is_return BOOLEAN NOT NULL,

    customer_status TEXT NOT NULL,

    description_status TEXT NOT NULL,

    price_quality_status TEXT NOT NULL,

    date_quality_status TEXT NOT NULL,

    is_analytically_usable BOOLEAN NOT NULL,

    source_sheet TEXT,

    CONSTRAINT fk_fact_product
        FOREIGN KEY (stock_code)
        REFERENCES analytics.dim_product (stock_code),

    CONSTRAINT fk_fact_customer
        FOREIGN KEY (customer_id)
        REFERENCES analytics.dim_customer (customer_id),

    CONSTRAINT fk_fact_country
        FOREIGN KEY (country_key)
        REFERENCES analytics.dim_country (country_key),

    CONSTRAINT fk_fact_date
        FOREIGN KEY (invoice_date)
        REFERENCES analytics.dim_date (date),

    CONSTRAINT chk_fact_quantity
        CHECK (quantity <> 0),

    CONSTRAINT chk_fact_transaction_type
        CHECK (
            transaction_type IN (
                'Sale',
                'Return',
                'Cancellation',
                'Invalid'
            )
        )
);

COMMIT;