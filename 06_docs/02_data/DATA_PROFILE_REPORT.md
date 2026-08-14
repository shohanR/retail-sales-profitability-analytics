# Raw Data Profile Report

> Automated baseline profile of the UCI Online Retail II dataset before transformation.

## 1. Dataset Overview

| Metric | Value |
|---|---:|
| Total rows | 1,067,371 |
| Total columns | 9 |
| Worksheets | 2 |
| Unique invoices | 53,628 |
| Unique products | 5,305 |
| Unique customers | 5,942 |
| Unique countries | 43 |
| Date range | 2009-12-01 07:45:00 → 2011-12-09 12:50:00 |

## 2. Data Quality Baseline

| Check | Count |
|---|---:|
| Exact duplicate rows | 12,133 |
| Invoices containing multiple line items | 40,334 |
| Cancelled transaction rows | 19,494 |
| Negative quantity rows | 22,950 |
| Zero quantity rows | 0 |
| Negative unit-price rows | 5 |
| Zero unit-price rows | 6,202 |
| Missing customer IDs | 243,007 |
| Missing descriptions | 4,382 |
| Invalid invoice dates | 0 |

## 3. Missing-Value Analysis

| Column | Missing Values | Missing % |
|---|---:|---:|
| customer_id | 243,007 | 22.77% |
| description | 4,382 | 0.41% |
| invoice_no | 0 | 0.00% |
| quantity | 0 | 0.00% |
| stock_code | 0 | 0.00% |
| invoice_date | 0 | 0.00% |
| unit_price | 0 | 0.00% |
| country | 0 | 0.00% |
| source_sheet | 0 | 0.00% |

## 4. Column Profile

| Column | Data Type | Non-Null | Missing | Missing % | Unique |
|---|---|---:|---:|---:|---:|
| invoice_no | object | 1,067,371 | 0 | 0.00% | 53,628 |
| stock_code | object | 1,067,371 | 0 | 0.00% | 5,305 |
| description | object | 1,062,989 | 4,382 | 0.41% | 5,698 |
| quantity | int64 | 1,067,371 | 0 | 0.00% | 1,057 |
| invoice_date | datetime64[us] | 1,067,371 | 0 | 0.00% | 47,635 |
| unit_price | float64 | 1,067,371 | 0 | 0.00% | 2,807 |
| customer_id | float64 | 824,364 | 243,007 | 22.77% | 5,942 |
| country | str | 1,067,371 | 0 | 0.00% | 43 |
| source_sheet | str | 1,067,371 | 0 | 0.00% | 2 |

## 5. Revenue Baseline

| Metric | Value |
|---|---:|
| Gross transaction value | 19,287,250.57 |
| Positive transaction value | 20,972,968.14 |
| Negative transaction value | -1,685,717.57 |

## 6. Initial Observations

- The raw workbook contains multiple worksheets that are combined for profiling only.
- Duplicate invoice numbers are expected because an invoice may contain multiple line items.
- Cancellation transactions require explicit business-rule handling rather than blind deletion.
- Missing CustomerID values require documented treatment.
- Negative quantities and negative transaction values require classification before analytical modeling.
- The raw source remains unchanged; all transformations will occur downstream.

## 7. Next Step

The next stage is to define the formal data-cleaning and validation rules before loading the analytical model.