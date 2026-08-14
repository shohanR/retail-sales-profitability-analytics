# Power BI Guide

## Retail Sales Profitability Dashboard

This guide provides comprehensive documentation for the Power BI dashboard and reports.

## File Information
- **Filename**: Retail_Sales_Profitability.pbix
- **Format**: Power BI Desktop (.pbix)
- **Published To**: Power BI Service (URL: [your-service-url])
- **Refresh Schedule**: Daily at 2:00 AM UTC
- **Last Updated**: [Date]

## Dashboard Overview

### Main Dashboard - Executive Summary
**Purpose**: High-level overview for executives and stakeholders

**Key Visuals:**
1. **KPI Cards**
   - Total Sales ($)
   - Total Profit ($)
   - Profit Margin (%)
   - Transaction Count
   - Customer Count
   - Average Order Value

2. **Trend Charts**
   - Sales Trend (Line chart - 12 months)
   - Profit Margin Trend (Area chart)
   - Month-over-Month Growth (Column chart)

3. **Performance Indicators**
   - Sales by Country (Horizontal bar)
   - Top 10 Products (Vertical bar)
   - Sales by Segment (Donut chart)

4. **Slicers**
   - Date Range (From-To picker)
   - Country (Multi-select dropdown)
   - Product Category (Multi-select dropdown)
   - Customer Segment (Multi-select dropdown)

### Sales Analysis Report
**Purpose**: Detailed sales performance breakdown

**Pages:**
1. **Sales Overview**
   - Total sales by country
   - Sales contribution %
   - Sales trend by segment
   - Top performing regions

2. **Product Performance**
   - Top 20 products by sales
   - Product category breakdown
   - Product profitability ranking
   - Category margin comparison

3. **Customer Insights**
   - Top 20 customers
   - Customer segment performance
   - Average order value by segment
   - New vs. returning customers

### Profitability Analysis Report
**Purpose**: Deep-dive into profit margins and cost efficiency

**Pages:**
1. **Profit Summary**
   - Profit by country
   - Profit by product
   - Profit trend
   - Cost breakdown

2. **Margin Analysis**
   - Profit margin % by country
   - Margin by product category
   - Margin by customer segment
   - Low-margin products alert

3. **Cost Analysis**
   - Cost as % of sales
   - Cost trend analysis
   - High-cost products
   - Cost efficiency index

### Geographic Performance Report
**Purpose**: Market-specific analysis and regional insights

**Pages:**
1. **Country Overview**
   - Country performance scorecard
   - Sales and profit by country
   - Market share distribution
   - Growth rate by country

2. **Regional Analysis**
   - Sales density map (if geography data available)
   - Top products by country
   - Customer concentration by region
   - Regional trends

3. **Market Comparison**
   - Benchmark countries against each other
   - Market share trends
   - Growth comparison
   - Profitability comparison

### Trend & Forecasting Report
**Purpose**: Historical trends and future projections

**Pages:**
1. **Trend Analysis**
   - Monthly sales trend
   - Quarterly performance
   - Year-over-year comparison
   - Seasonality patterns

2. **Forecasting**
   - 90-day sales forecast
   - Confidence intervals
   - Trend direction
   - Seasonal adjustments

## Data Model

### Tables and Relationships

```
fact_sales
├── date_id → dim_date
├── customer_id → dim_customer
├── product_id → dim_product
└── country_id → dim_country

dim_date
├── date_id (Primary Key)
├── date_value
├── year
├── month
├── quarter
└── day_of_week

dim_customer
├── customer_id (Primary Key)
├── customer_name
├── segment
└── country_id → dim_country

dim_product
├── product_id (Primary Key)
├── product_name
├── category
├── sub_category
└── price

dim_country
├── country_id (Primary Key)
├── country_name
└── country_code
```

### Data Refresh Settings

**Power BI Service Configuration:**
- **Gateway**: Required for on-premises SQL Server
- **Refresh Frequency**: Daily (configurable)
- **Credentials**: Service account with SQL Server read permissions
- **Timeout**: 120 minutes

**Performance Optimization:**
- Aggregations for large fact tables
- Incremental refresh for historical data
- Direct Query for real-time data (if needed)
- Query folding enabled where possible

## Key Measures (DAX)

### Sales Metrics
```dax
Total Sales = SUM(fact_sales[sales_amount])
Total Profit = SUM(fact_sales[profit_amount])
Profit Margin = DIVIDE([Total Profit], [Total Sales], 0)
Profit Margin % = [Profit Margin] * 100
```

### Customer Metrics
```dax
Customer Count = DISTINCTCOUNT(fact_sales[customer_id])
Sales per Customer = DIVIDE([Total Sales], [Customer Count], 0)
Customer LTV = DIVIDE([Total Profit], [Customer Count], 0)
```

### Product Metrics
```dax
Units Sold = SUM(fact_sales[quantity])
Avg Order Value = DIVIDE([Total Sales], DISTINCTCOUNT(fact_sales[transaction_id]), 0)
Product Count = DISTINCTCOUNT(fact_sales[product_id])
```

### Time Metrics
```dax
YTD Sales = TOTALYTD([Total Sales], dim_date[date_value])
Prior Year Sales = CALCULATE([Total Sales], SAMEPERIODLASTYEAR(dim_date[date_value]))
YoY Growth = DIVIDE([YTD Sales] - [Prior Year Sales], [Prior Year Sales], 0)
```

## Interactivity & Filters

### Report-Level Filters
- **Date Range**: Controls all visuals across report
- **Country**: Multi-select for geographic filtering
- **Category**: Filter by product category
- **Segment**: Filter by customer segment

### Visual-Level Interactions
- **Cross-filtering**: Clicking one visual filters others
- **Cross-highlighting**: Related data highlighted
- **Drill-through**: Click details to see drill-down view
- **Tooltips**: Hover for additional information

## Sharing and Permissions

### Access Levels
- **Viewers**: Can view dashboards and reports (read-only)
- **Editors**: Can modify reports and dashboards
- **Admins**: Full control of workspaces and settings

### Sharing Options
1. **Power BI Service**: Share entire report or specific pages
2. **Direct Link**: Share with specific users/groups
3. **Export**: Download as PDF or PowerPoint
4. **Email**: Schedule email subscriptions for updates
5. **Embed**: Embed dashboard in SharePoint or website

### Row-Level Security (RLS)
```dax
IF(
    USERPRINCIPALNAME() IN {"admin@company.com"},
    TRUE(),
    [country_id] = VALUES(dim_country[country_id])
)
```

This allows filtering data by country for regional managers.

## Mobile Optimization

### Mobile Layout
- Optimized for phone and tablet viewing
- Single-column layout for mobile
- Larger touch targets for buttons/slicers
- Simplified visuals for mobile screens

### Mobile Features
- Offline view (when sync'd to mobile device)
- Bookmarks for saved filter states
- Q&A for natural language queries

## Performance Best Practices

### Optimization Techniques
1. **Aggregation Tables**: For sales by month/country
2. **Incremental Refresh**: Load only new/changed data
3. **Aggregation Strategy**: Pre-aggregate high-volume data
4. **Query Folding**: Ensure transformations occur in SQL
5. **Relationships**: Use single direction filtering

### Monitoring Performance
- **Query Duration**: Check Data tab for slow queries
- **Model Size**: Keep model under 1GB if possible
- **Cardinality**: Review column cardinality
- **Redundancy**: Remove unused columns

## Troubleshooting

### Common Issues

**Issue**: "Refresh failed" error
- **Cause**: Database connection issue or credentials expired
- **Solution**: Check gateway status, verify credentials, test connection

**Issue**: Visuals showing blank/no data
- **Cause**: Filter interaction issue or missing data
- **Solution**: Remove filters, check data model relationships, verify data exists

**Issue**: Reports loading slowly
- **Cause**: Large dataset or complex calculations
- **Solution**: Enable aggregations, optimize DAX, reduce data volume

**Issue**: Data inconsistency between reports
- **Cause**: Different measure definitions or filters
- **Solution**: Review measure definitions, check filter context

## Maintenance Schedule

- **Daily**: Monitor refresh status
- **Weekly**: Review user engagement metrics
- **Monthly**: Update documentation, archive old versions
- **Quarterly**: Review performance metrics, optimize as needed
- **Annual**: Full audit of data model and measures

## Export and Distribution

### Export Options
1. **PDF Export**: For presentations and archiving
2. **PowerPoint Export**: For editing and combining with other content
3. **Excel Export**: For detailed data analysis
4. **Scheduled Email**: Automatic daily/weekly distribution

### Best Practices for Exports
- Include date and refresh time
- Add context and interpretation
- Highlight key findings
- Include drill-down details for support

## Advanced Features

### Q&A Capabilities
Users can ask natural language questions:
- "What were sales last month?"
- "Which product had highest profit margin?"
- "Show me top 10 customers"

### Bookmarks
Pre-configured dashboard states for quick access:
- "Executive Summary"
- "Problem Analysis"
- "Deep Dive by Region"

### Alerts
Automated notifications when metrics exceed thresholds:
- Profit margin drops below 15%
- Sales below target
- High-profit products identified

### Custom Tooltips
Hover-over details providing:
- Data point values
- Percent of total
- Trend indicators
- Related metrics

## Security and Compliance

- **Data Encryption**: In transit (TLS) and at rest
- **Access Control**: Azure AD integration for authentication
- **Audit Logging**: Track all data access and modifications
- **Data Retention**: Configure backup and archival policies

## Support and Training

- **User Guide**: Available in Power BI Service
- **Training Videos**: Embedded in dashboards
- **FAQ**: Contact BI team for common questions
- **Technical Support**: For connection/performance issues

## Contact Information

For questions or issues:
- **BI Team Email**: [email]
- **Slack Channel**: #bi-support
- **Scheduled Office Hours**: [Days and times]

---

**Dashboard Version**: 1.0
**Last Updated**: [Date]
**Next Review**: [Date]
