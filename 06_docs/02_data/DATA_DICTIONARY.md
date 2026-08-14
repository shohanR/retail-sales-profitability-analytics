# Data Dictionary

## Retail Sales Profitability Analysis

### Document Information
- **Version**: 1.0
- **Date**: 2024
- **Status**: Active
- **Owner**: Business Intelligence Team

---

## Fact Table: fact_sales

**Description**: Core transaction-level sales data

**Grain**: One row per transaction

**Volume**: Millions of rows (depends on business size)

### Columns

| Column Name | Data Type | Nullable | Description | Example |
|-------------|-----------|----------|-------------|---------|
| transaction_id | VARCHAR(50) | NO | Unique transaction identifier | TRX20240115001 |
| date_id | INTEGER | NO | Foreign key to dim_date | 20240115 |
| customer_id | VARCHAR(50) | NO | Foreign key to dim_customer | CUST001234 |
| product_id | VARCHAR(50) | NO | Foreign key to dim_product | PROD005678 |
| country_id | INTEGER | NO | Foreign key to dim_country | 1 |
| quantity | INTEGER | NO | Number of units sold | 5 |
| unit_price | DECIMAL(10,2) | NO | Price per unit | 99.99 |
| sales_amount | DECIMAL(12,2) | NO | Total sales (Qty × Unit Price) | 499.95 |
| cost_amount | DECIMAL(12,2) | NO | Total cost | 299.97 |
| profit_amount | DECIMAL(12,2) | NO | Profit (Sales - Cost) | 199.98 |
| created_date | DATETIME | NO | Record creation timestamp | 2024-01-15 10:30:45 |
| updated_date | DATETIME | YES | Last record update | 2024-01-15 10:30:45 |

### Indexes
- PRIMARY KEY: transaction_id
- FOREIGN KEY: date_id → dim_date.date_id
- FOREIGN KEY: customer_id → dim_customer.customer_id
- FOREIGN KEY: product_id → dim_product.product_id
- FOREIGN KEY: country_id → dim_country.country_id

### Business Rules
- quantity must be > 0
- sales_amount = quantity × unit_price (within 0.01 tolerance)
- profit_amount = sales_amount - cost_amount (within 0.01 tolerance)
- cost_amount <= sales_amount (unless losses are allowed)
- transaction_id must be unique

---

## Dimension Table: dim_customer

**Description**: Customer master data

**Grain**: One row per unique customer

**Volume**: Thousands to millions of rows

### Columns

| Column Name | Data Type | Nullable | Description | Example |
|-------------|-----------|----------|-------------|---------|
| customer_id | VARCHAR(50) | NO | Unique customer identifier | CUST001234 |
| customer_name | VARCHAR(255) | NO | Full customer name | ABC Corp |
| segment | VARCHAR(50) | NO | Customer segment | Corporate |
| country_id | INTEGER | NO | Foreign key to dim_country | 1 |
| created_date | DATETIME | NO | Account creation date | 2023-01-15 |
| last_purchase_date | DATETIME | YES | Date of most recent purchase | 2024-01-10 |

### Segment Values
- Corporate
- Consumer
- Premium
- Partner

### Indexes
- PRIMARY KEY: customer_id
- FOREIGN KEY: country_id → dim_country.country_id
- INDEX: segment

### Business Rules
- customer_id must be unique
- segment must be one of predefined values
- customer_name cannot be blank

---

## Dimension Table: dim_product

**Description**: Product catalog master data

**Grain**: One row per unique product

**Volume**: Hundreds to thousands of rows

### Columns

| Column Name | Data Type | Nullable | Description | Example |
|-------------|-----------|----------|-------------|---------|
| product_id | VARCHAR(50) | NO | Unique product identifier | PROD005678 |
| product_name | VARCHAR(255) | NO | Product name | Widget A |
| category | VARCHAR(50) | NO | Product category | Electronics |
| sub_category | VARCHAR(50) | YES | Product sub-category | Laptops |
| price | DECIMAL(10,2) | NO | Standard list price | 999.99 |
| created_date | DATETIME | NO | Product creation date | 2023-01-01 |
| discontinued_date | DATETIME | YES | Product discontinuation date | NULL |

### Category Examples
- Electronics
- Apparel
- Home & Garden
- Sports & Outdoors
- Health & Beauty

### Indexes
- PRIMARY KEY: product_id
- INDEX: category, sub_category

### Business Rules
- product_id must be unique
- product_name cannot be blank
- price must be > 0
- category must be one of predefined values

---

## Dimension Table: dim_country

**Description**: Geographic country reference

**Grain**: One row per country

**Volume**: 100+ rows (depends on geographic scope)

### Columns

| Column Name | Data Type | Nullable | Description | Example |
|-------------|-----------|----------|-------------|---------|
| country_id | INTEGER | NO | Unique country identifier | 1 |
| country_name | VARCHAR(100) | NO | Full country name | United States |
| country_code | VARCHAR(2) | NO | ISO 3166-1 alpha-2 code | US |
| region | VARCHAR(50) | YES | Geographic region | North America |
| currency_code | VARCHAR(3) | YES | ISO 4217 currency code | USD |

### Indexes
- PRIMARY KEY: country_id
- UNIQUE: country_code, country_name

### Business Rules
- country_id must be unique
- country_code must follow ISO-3166-1 standard
- country_code must be 2 characters

---

## Dimension Table: dim_date

**Description**: Calendar date dimension for time-based analysis

**Grain**: One row per calendar date

**Volume**: ~37,000 rows (100 years of dates)

### Columns

| Column Name | Data Type | Nullable | Description | Example |
|-------------|-----------|----------|-------------|---------|
| date_id | INTEGER | NO | Date in YYYYMMDD format | 20240115 |
| date_value | DATE | NO | Actual calendar date | 2024-01-15 |
| year | INTEGER | NO | 4-digit year | 2024 |
| quarter | INTEGER | NO | Quarter (1-4) | 1 |
| month | INTEGER | NO | Month (1-12) | 1 |
| day | INTEGER | NO | Day of month (1-31) | 15 |
| week_number | INTEGER | NO | ISO week number (1-53) | 3 |
| day_of_week | INTEGER | NO | Day of week (1=Mon, 7=Sun) | 1 |
| day_name | VARCHAR(10) | NO | Day name | Monday |
| month_name | VARCHAR(10) | NO | Month name | January |
| quarter_name | VARCHAR(10) | NO | Quarter name | Q1 |
| is_weekend | BIT | NO | Weekend flag (0=weekday, 1=weekend) | 0 |
| is_holiday | BIT | NO | Holiday flag (configurable) | 0 |

### Indexes
- PRIMARY KEY: date_id
- INDEX: date_value, year, month

### Business Rules
- date_id format must be YYYYMMDD
- date_value must be valid calendar date
- Quarter must match month (e.g., month 1-3 = Q1)

---

## Materialized Views

### vw_customer_metrics

Aggregated customer-level metrics

**Columns**:
- customer_id
- customer_name
- segment
- purchase_frequency
- total_units_purchased
- lifetime_sales
- lifetime_profit
- avg_order_value
- profit_margin_percent

**Refresh**: Daily

---

### vw_product_metrics

Aggregated product-level metrics

**Columns**:
- product_id
- product_name
- category
- unique_customers
- units_sold
- total_sales
- total_profit
- profit_margin_percent

**Refresh**: Daily

---

### vw_monthly_performance

Aggregated monthly metrics

**Columns**:
- year
- month
- monthly_sales
- monthly_profit
- monthly_transactions
- profit_margin_percent

**Refresh**: Daily

---

## Calculated Fields

### Profit
```
Profit = Sales Amount - Cost Amount
```

### Profit Margin %
```
Profit Margin % = (Profit / Sales Amount) × 100
```

### Average Order Value
```
AOV = Total Sales / Number of Transactions
```

### Customer Lifetime Value
```
CLV = Total Profit / Number of Customers
```

### Market Share %
```
Market Share = (Country Sales / Total Sales) × 100
```

### Month-over-Month Growth %
```
MoM Growth = ((Current Month - Previous Month) / Previous Month) × 100
```

---

## Data Quality Standards

### Nullable Columns
- Columns marked "NO" cannot be NULL
- Columns marked "YES" can be NULL when appropriate

### Data Types
- VARCHAR: For text/string data
- INTEGER: For whole numbers
- DECIMAL: For monetary amounts (minimum 2 decimal places)
- DATE: For calendar dates
- DATETIME: For timestamps
- BIT: For boolean (0 or 1)

### Uniqueness Constraints
- All primary keys must be unique
- Dimension keys must be unique
- Transaction IDs must be unique

### Referential Integrity
- All foreign keys must match primary key in referenced table
- Foreign key values cannot reference non-existent records
- Cascade delete rules: TBD per business requirements

### Value Ranges
- Quantities: >= 1
- Amounts (Sales, Cost, Profit): >= 0
- Month: 1-12
- Day: 1-31
- Quarter: 1-4

---

## Data Lineage

### Source → Processing → Warehouse → Analytics

1. **Source Systems**
   - ERP System → Sales transactions
   - POS System → Point-of-sale transactions
   - Finance System → Cost data
   - Customer Database → Customer master

2. **ETL Processing**
   - Data extraction from sources
   - Data cleaning and validation
   - Data transformation and enrichment
   - Data loading to warehouse

3. **Data Warehouse**
   - fact_sales (transaction level)
   - dim_customer (customer master)
   - dim_product (product catalog)
   - dim_country (geographic reference)
   - dim_date (calendar reference)

4. **Reporting & Analytics**
   - SQL Server Analysis Services (SSAS) cubes
   - Excel pivot tables
   - Power BI dashboards
   - Python analysis notebooks

---

## Change Log

### Version 1.0 (Initial Release)
- Created data dictionary
- Defined all tables and columns
- Established data quality standards

---

## Glossary

**Transaction**: A single sales event (order)

**Customer**: An individual or organization making purchases

**Product**: Item available for sale

**Country**: Geographic sales territory

**Segment**: Customer classification (Corporate, Consumer, Premium)

**Profit Margin**: Profit as percentage of sales

**Customer Lifetime Value (CLV)**: Total profit from a customer

**Average Order Value (AOV)**: Average sales per transaction

---

**Document Version**: 1.0
**Last Updated**: 2024
**Data Steward**: Business Intelligence Team
