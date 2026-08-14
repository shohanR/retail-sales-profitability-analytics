# Data Cleaning Report

> Automated cleaning and transformation audit for the UCI Online Retail II dataset.

## 1. Processing Summary

| Metric | Value |
|---|---:|
| Raw rows | 1,067,371 |
| Duplicate transaction rows removed | 34,335 |
| Rows after deduplication | 1,033,036 |
| Analytically usable rows | 1,033,036 |

## 2. Transaction Classification

| Classification | Rows |
|---|---:|
| Sales | 1,010,539 |
| Returns | 22,496 |
| Cancellations | 19,104 |
| Invalid | 0 |

## 3. Data Quality Flags

| Quality Check | Rows |
|---|---:|
| Missing CustomerID | 235,151 |
| Zero unit price | 6,014 |
| Negative unit price | 5 |
| Invalid invoice date | 0 |
| Unknown product description | 363 |

## 4. Description Resolution

- Missing descriptions before mapping: 4,275
- Missing descriptions after mapping: 363
- Descriptions resolved through product mapping: 3,912

## 5. Financial Baseline

| Metric | Value |
|---|---:|
| Net transaction value | 18,855,533.70 |
| Positive transaction value | 20,476,634.02 |
| Negative transaction value | -1,621,100.32 |

## 6. Output Tables

| Table | Rows |
|---|---:|
| fact_sales | 1,033,036 |
| dim_customer | 5,942 |
| dim_product | 5,304 |
| dim_country | 43 |
| dim_date | 604 |

## 7. Transformation Principles

1. The raw source workbook remains unchanged.
2. Duplicate transaction records matching the defined business-key attributes are removed from the analytical layer after identification.
3. Returns and cancellations are retained and explicitly classified.
4. Missing CustomerID values are retained as unknown customers.
5. Zero and negative prices are flagged rather than silently deleted.
6. Product descriptions are resolved from valid product-level mappings where possible.
7. No synthetic customer or product information is fabricated.
8. All calculated sales values are derived from quantity multiplied by unit price.

## 8. Next Step

The processed data will next undergo independent SQL-based validation before analytical queries and reporting models are built.