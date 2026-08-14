# Excel Formula Reference

## Retail Sales Profitability Analysis - Complete Formula Guide

This document provides a comprehensive reference for all formulas used in the Excel workbook.

## Summary Metrics

### Total Sales
```excel
=SUMIF(Transactions[Sales Amount], ">=0")
```

### Total Profit
```excel
=SUMPRODUCT(Transactions[Sales Amount] - Transactions[Cost Amount])
```

### Overall Profit Margin
```excel
=IF(SUM(Transactions[Sales Amount])=0, 0%, SUM(Transactions[Profit Amount])/SUM(Transactions[Sales Amount]))
```

### Transaction Count
```excel
=COUNTA(Transactions[Transaction ID])
```

### Customer Count (Unique)
```excel
=SUMPRODUCT(1/COUNTIF(Transactions[Customer ID], Transactions[Customer ID]))
```

### Average Order Value (AOV)
```excel
=SUM(Transactions[Sales Amount])/COUNTA(Transactions[Transaction ID])
```

## Sales Analysis Formulas

### Sales by Country
```excel
=SUMIF(Transactions[Country], [Country Name], Transactions[Sales Amount])
```

### Profit by Country
```excel
=SUMIF(Transactions[Country], [Country Name], Transactions[Profit Amount])
```

### Profit Margin by Country
```excel
=IF(SUMIF(Transactions[Country], [Country Name], Transactions[Sales Amount])=0, 0%, 
    SUMIF(Transactions[Country], [Country Name], Transactions[Profit Amount]) / 
    SUMIF(Transactions[Country], [Country Name], Transactions[Sales Amount]))
```

### Market Share %
```excel
=[Country Sales] / SUM($D$2:$D$50) * 100
```

## Customer Analysis

### Customer Lifetime Value (CLV)
```excel
=SUMIF(Transactions[Customer ID], [Customer ID], Transactions[Sales Amount])
```

### Customer Purchase Frequency
```excel
=COUNTIF(Transactions[Customer ID], [Customer ID])
```

### Customer AOV
```excel
=IF(COUNTIF(Transactions[Customer ID], [Customer ID])=0, 0,
    SUMIF(Transactions[Customer ID], [Customer ID], Transactions[Sales Amount]) / 
    COUNTIF(Transactions[Customer ID], [Customer ID]))
```

### Customer Profit Margin
```excel
=IF(SUMIF(Transactions[Customer ID], [Customer ID], Transactions[Sales Amount])=0, 0%,
    SUMIF(Transactions[Customer ID], [Customer ID], Transactions[Profit Amount]) / 
    SUMIF(Transactions[Customer ID], [Customer ID], Transactions[Sales Amount]))
```

### Days Since Last Purchase
```excel
=TODAY() - MAX(IF(Transactions[Customer ID]=[Customer ID], Transactions[Date]))
```

(Note: This is an array formula - press Ctrl+Shift+Enter)

### Customer Segment Count
```excel
=COUNTIF(Customers[Segment], [Segment Name])
```

## Product Analysis

### Product Total Sales
```excel
=SUMIF(Transactions[Product ID], [Product ID], Transactions[Sales Amount])
```

### Units Sold (Product)
```excel
=SUMIF(Transactions[Product ID], [Product ID], Transactions[Quantity])
```

### Product Profit
```excel
=SUMIF(Transactions[Product ID], [Product ID], Transactions[Profit Amount])
```

### Product Profit Margin
```excel
=IF(SUMIF(Transactions[Product ID], [Product ID], Transactions[Sales Amount])=0, 0%,
    SUMIF(Transactions[Product ID], [Product ID], Transactions[Profit Amount]) / 
    SUMIF(Transactions[Product ID], [Product ID], Transactions[Sales Amount]))
```

### Product Revenue Rank
```excel
=RANK([Product Sales], [All Product Sales], 0)
```

### Category Performance
```excel
=SUMIF(Products[Category], [Category Name], [Product Sales])
```

## Trend Analysis

### Monthly Sales
```excel
=SUMIFS(Transactions[Sales Amount], 
        Transactions[Date], ">="&DATE(Year, Month, 1),
        Transactions[Date], "<"&DATE(Year, Month+1, 1))
```

### Month-over-Month Growth %
```excel
=(Current_Month_Sales - Previous_Month_Sales) / Previous_Month_Sales * 100
```

### YTD Sales (Year-to-Date)
```excel
=SUMIFS(Transactions[Sales Amount],
        Transactions[Date], ">="&DATE(YEAR(TODAY()), 1, 1),
        Transactions[Date], "<="&TODAY())
```

### Previous Year Sales Comparison
```excel
=SUMIFS(Transactions[Sales Amount],
        Transactions[Date], ">="&DATE(YEAR(TODAY())-1, MONTH([Current Date]), DAY([Current Date])),
        Transactions[Date], "<="&DATE(YEAR(TODAY())-1, MONTH([Current Date]), DAY([Current Date])))
```

### Quarter Sales
```excel
=SUMIFS(Transactions[Sales Amount],
        Transactions[Date], ">="&DATE(Year, (Quarter-1)*3+1, 1),
        Transactions[Date], "<"&DATE(Year, Quarter*3+1, 1))
```

### Seasonality Index
```excel
=Month_Average_Sales / Annual_Average_Sales * 100
```

## Order Analysis

### Average Order Quantity
```excel
=AVERAGE(Transactions[Quantity])
```

### Order Count by Range
```excel
=COUNTIFS(Transactions[Sales Amount], ">="&[Lower Bound], 
          Transactions[Sales Amount], "<"&[Upper Bound])
```

### High-Value Orders (>$1000)
```excel
=COUNTIF(Transactions[Sales Amount], ">1000")
```

### Orders with Loss (Profit < 0)
```excel
=COUNTIF(Transactions[Profit Amount], "<0")
```

### Break-Even Orders (Profit = 0)
```excel
=COUNTIF(Transactions[Profit Amount], 0)
```

### Profitable Orders (Profit > 0)
```excel
=COUNTIF(Transactions[Profit Amount], ">0")
```

## Segmentation Analysis

### Segment Sales Distribution
```excel
=SUMIF(Transactions[Segment], [Segment Name], Transactions[Sales Amount]) / SUM(Transactions[Sales Amount]) * 100
```

### Segment Average Order Value
```excel
=AVERAGEIF(Transactions[Segment], [Segment Name], Transactions[Sales Amount])
```

### Segment Profit Margin
```excel
=SUMIF(Transactions[Segment], [Segment Name], Transactions[Profit Amount]) / 
SUMIF(Transactions[Segment], [Segment Name], Transactions[Sales Amount]) * 100
```

## Data Quality Metrics

### Null/Missing Values Count
```excel
=COUNTBLANK([Column Range])
```

### Duplicate Records
```excel
=SUMPRODUCT(--(COUNTIF(Transactions[Transaction ID], Transactions[Transaction ID])>1))
```

### Data Completeness %
```excel
=(COUNTA([Data Range]) - COUNTBLANK([Data Range])) / COUNTA([Data Range]) * 100
```

### Negative Sales (Should be 0)
```excel
=COUNTIF(Transactions[Sales Amount], "<0")
```

## Conditional Formatting Rules

### Profit Margin Color Scale
```
High (>30%): Green
Medium (15-30%): Yellow
Low (<15%): Red
```

### Sales Performance
```
Above Average: Light Green
Average: Light Yellow
Below Average: Light Red
```

### Data Validation
```
Valid: No highlight
Invalid (Text in number field): Red
Missing data: Yellow
Duplicate: Purple
```

## Performance Optimization Tips

### Large Dataset Formulas
- Use SUMIF/COUNTIF instead of array formulas
- Avoid volatile functions like TODAY() in frequently recalculated cells
- Use Named Ranges for cleaner formulas
- Create summary tables for repeated calculations

### Formula Audit Trail
- Document changes in CHANGELOG.md
- Use Cell Comments for complex formulas
- Version workbook before making major changes
- Keep formula backup in separate sheet

## Common Pitfalls to Avoid

1. **Circular References**: Check that formulas don't reference their own cell
2. **#DIV/0! Errors**: Add error handling with IFERROR()
3. **Incorrect Date Formats**: Ensure consistent date format (MM/DD/YYYY)
4. **Missing $ Signs**: Use absolute references ($) for fixed ranges
5. **Case Sensitivity**: Use EXACT() for case-sensitive comparisons

## Error Handling

### Safe Formulas with Error Handling
```excel
=IFERROR(SUMIF(...), 0)
=IFERROR(Division_Result, 0)
=IF(Denominator=0, 0, Numerator/Denominator)
=IFNA(VLOOKUP(...), "Not Found")
```

## Contact

For questions about formulas or to report errors:
- Check EXCEL_MODEL_GUIDE.md for usage instructions
- Review CHANGELOG.md for recent updates
- Contact the Business Intelligence team
