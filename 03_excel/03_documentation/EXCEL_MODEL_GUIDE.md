# Excel Model Guide

## Retail Sales Profitability Analysis Workbook

This guide provides comprehensive documentation for the `Retail_Sales_Profitability_Analysis.xlsx` workbook.

## Workbook Structure

### 1. Dashboard Sheet
- **Purpose**: Executive summary with key metrics and KPIs
- **Key Metrics**:
  - Total Sales
  - Total Profit
  - Profit Margin %
  - Transaction Count
  - Customer Count
  - Average Order Value

### 2. Sales Performance Sheet
- Sales by Country
- Sales by Customer Segment
- Top 20 Products by Sales
- Monthly Sales Trend

### 3. Customer Analysis Sheet
- Top Customers by Revenue
- Customer Segmentation Breakdown
- Customer Lifetime Value (CLV) Analysis
- Inactive Customers List

### 4. Product Analysis Sheet
- Top Products by Profit Margin
- Products by Category Performance
- Low-Performing Products
- Product Profitability Ranking

### 5. Geographic Analysis Sheet
- Country Performance Summary
- Market Share by Country
- Regional Sales Trends
- Country-level Profitability

### 6. Trend Analysis Sheet
- Monthly Sales Trend
- Month-over-Month Growth %
- Seasonality Patterns
- Year-to-Date Comparison

### 7. Raw Data Sheets
- Transactions (from fact_sales)
- Customers (from dim_customer)
- Products (from dim_product)
- Dates (from dim_date)
- Countries (from dim_country)

## Key Formulas

### Profit Margin % (Column H in most sheets)
```
=IF(SUM_SALES=0, 0, SUM_PROFIT / SUM_SALES * 100)
```

### Month-over-Month Growth %
```
=(Current_Month_Sales - Previous_Month_Sales) / Previous_Month_Sales * 100
```

### Customer Lifetime Value
```
=SUM(Customer_Sales) / COUNT(Customer_Transactions)
```

### Average Order Value (AOV)
```
=SUM(Sales) / COUNT(Transactions)
```

## Data Validation Rules

1. **Sales Amount**: Must be >= 0
2. **Cost Amount**: Must be >= 0 and <= Sales Amount (optional)
3. **Quantity**: Must be > 0
4. **Dates**: Must be within valid business date range

## Refresh Instructions

1. Update data connections to pull from SQL database
2. Refresh all pivot tables (Data → Refresh All)
3. Refresh all formulas (Press Ctrl+Shift+F9)
4. Verify all month-end reports are generated

## Chart and Visualization Guide

### Dashboard Charts
- **Sales Trend**: Line chart showing monthly progression
- **Top Products Pie**: Pie chart of top 10 products
- **Customer Segment Bar**: Bar chart of sales by segment
- **Country Performance**: Horizontal bar chart

### Key Performance Indicators (KPIs)
- Green background: Exceeds target (>15% profit margin)
- Yellow background: Meets target (10-15% profit margin)
- Red background: Below target (<10% profit margin)

## Color Coding

- **Green**: Positive values, high performance
- **Yellow**: Neutral, meeting expectations
- **Red**: Negative values, needs attention
- **Blue**: Headers, category labels

## Data Connections

- **SQL Server Connection**: Update server name and database in Data → Connections
- **CSV Import**: Update file paths in External Data → Refresh All
- **Manual Updates**: Update raw data sheets quarterly

## Maintenance Schedule

- **Weekly**: Review dashboard for anomalies
- **Monthly**: Refresh all data and verify totals
- **Quarterly**: Update KPI targets and review formulas
- **Annual**: Audit data quality and reconcile with source systems

## Troubleshooting

### Common Issues

1. **#REF! Error**: Check that referenced sheets/columns still exist
2. **#VALUE! Error**: Check for text in numeric fields
3. **Incorrect Totals**: Refresh all data and recalculate formulas
4. **Pivot Table Not Updating**: Right-click → Refresh

### Performance Tips

- Use filtering to reduce visible data before copying
- Archive historical data to separate sheet if workbook becomes slow
- Avoid using "select all" (*) in data pulls; specify columns

## Security and Sharing

- Protect sensitive sheets with passwords
- Lock formula cells and hide calculations if sharing externally
- Use "Save As" to create distribution copies
- Audit trail: Document all formula changes in CHANGELOG

## Contact and Support

For questions about this workbook:
- Check the EXCEL_FORMULA_REFERENCE.md file
- Review this guide's troubleshooting section
- Contact the Business Intelligence team
