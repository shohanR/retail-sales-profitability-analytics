"""
Data Validation Script for Retail Sales Profitability Analysis
===============================================================

This script performs data quality validations:
- Check for null values in critical fields
- Verify data types
- Check for duplicates
- Validate business rules
- Generate quality report

Author: BI Team
Date: 2024
Version: 1.0
"""

import pandas as pd
import numpy as np
import logging
from pathlib import Path
from datetime import datetime
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/validate_data.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DataValidator:
    """
    Class to handle data validation and quality checks
    """
    
    def __init__(self, processed_data_dir='01_data/02_processed'):
        """
        Initialize the DataValidator
        
        Args:
            processed_data_dir: Directory containing processed data files
        """
        self.processed_data_dir = Path(processed_data_dir)
        self.validation_results = {}
        self.quality_score = 100.0
        
    def check_null_values(self, df, name, critical_columns=None):
        """
        Check for null/missing values
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            critical_columns: List of columns that cannot be null
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking null values in {name}")
        
        results = {
            'dataset': name,
            'check': 'null_values',
            'total_rows': len(df),
            'null_columns': {},
            'critical_null_found': False,
            'status': 'PASS'
        }
        
        # Check all columns
        for col in df.columns:
            null_count = df[col].isnull().sum()
            if null_count > 0:
                null_pct = (null_count / len(df)) * 100
                results['null_columns'][col] = {
                    'count': null_count,
                    'percentage': round(null_pct, 2)
                }
                logger.warning(f"  {col}: {null_count} nulls ({null_pct:.2f}%)")
                
                # Check if critical column has nulls
                if critical_columns and col in critical_columns:
                    results['critical_null_found'] = True
                    results['status'] = 'FAIL'
        
        if not results['null_columns']:
            logger.info(f"  No null values found in {name}")
        
        return results
    
    def check_duplicates(self, df, name, key_columns=None):
        """
        Check for duplicate records
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            key_columns: Columns to check for duplicates
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking duplicates in {name}")
        
        results = {
            'dataset': name,
            'check': 'duplicates',
            'total_rows': len(df),
            'duplicate_rows': 0,
            'status': 'PASS'
        }
        
        if key_columns:
            duplicates = df.duplicated(subset=key_columns, keep=False)
            duplicate_count = duplicates.sum()
            
            if duplicate_count > 0:
                results['duplicate_rows'] = duplicate_count
                results['status'] = 'FAIL'
                logger.warning(f"  Found {duplicate_count} duplicate rows on {key_columns}")
            else:
                logger.info(f"  No duplicates found on {key_columns}")
        else:
            duplicates = df.duplicated(keep=False)
            duplicate_count = duplicates.sum()
            
            if duplicate_count > 0:
                results['duplicate_rows'] = duplicate_count
                results['status'] = 'FAIL'
                logger.warning(f"  Found {duplicate_count} complete duplicate rows")
            else:
                logger.info("  No complete duplicates found")
        
        return results
    
    def check_data_types(self, df, name, expected_types=None):
        """
        Check data types
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            expected_types: Dictionary of column -> expected dtype
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking data types in {name}")
        
        results = {
            'dataset': name,
            'check': 'data_types',
            'actual_types': {},
            'type_mismatches': {},
            'status': 'PASS'
        }
        
        for col in df.columns:
            actual_type = str(df[col].dtype)
            results['actual_types'][col] = actual_type
            
            if expected_types and col in expected_types:
                expected = expected_types[col]
                if actual_type != expected:
                    results['type_mismatches'][col] = {
                        'expected': expected,
                        'actual': actual_type
                    }
                    results['status'] = 'FAIL'
                    logger.warning(f"  {col}: expected {expected}, got {actual_type}")
        
        if not results['type_mismatches']:
            logger.info(f"  All data types are correct")
        
        return results
    
    def check_value_ranges(self, df, name, range_checks=None):
        """
        Check value ranges for columns
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            range_checks: Dictionary of column -> (min, max) tuples
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking value ranges in {name}")
        
        results = {
            'dataset': name,
            'check': 'value_ranges',
            'range_violations': {},
            'status': 'PASS'
        }
        
        if range_checks:
            for col, (min_val, max_val) in range_checks.items():
                if col in df.columns:
                    violations = df[(df[col] < min_val) | (df[col] > max_val)]
                    
                    if len(violations) > 0:
                        results['range_violations'][col] = {
                            'expected_range': f'[{min_val}, {max_val}]',
                            'violation_count': len(violations)
                        }
                        results['status'] = 'FAIL'
                        logger.warning(f"  {col}: {len(violations)} values outside range [{min_val}, {max_val}]")
                    else:
                        logger.info(f"  {col}: all values within range [{min_val}, {max_val}]")
        
        return results
    
    def check_business_rules(self, df, name):
        """
        Check business-specific rules
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking business rules in {name}")
        
        results = {
            'dataset': name,
            'check': 'business_rules',
            'violations': [],
            'status': 'PASS'
        }
        
        # Transaction-specific rules
        if name == 'transactions':
            # Profit should equal sales - cost
            profit_mismatch = df[
                abs(df['sales_amount'] - df['cost_amount'] - df.get('profit_amount', df['sales_amount'] - df['cost_amount'])) > 0.01
            ]
            if len(profit_mismatch) > 0:
                results['violations'].append({
                    'rule': 'Profit = Sales - Cost',
                    'violation_count': len(profit_mismatch)
                })
                results['status'] = 'FAIL'
                logger.warning(f"  Profit calculation mismatch: {len(profit_mismatch)} rows")
            
            # Quantity * Unit Price should equal sales
            quantity_mismatch = df[
                abs((df['quantity'] * df['unit_price']) - df['sales_amount']) > 0.01
            ]
            if len(quantity_mismatch) > 0:
                results['violations'].append({
                    'rule': 'Sales = Quantity * Unit Price',
                    'violation_count': len(quantity_mismatch)
                })
                results['status'] = 'FAIL'
                logger.warning(f"  Quantity x Price mismatch: {len(quantity_mismatch)} rows")
            
            # Negative sales should not exist
            negative_sales = df[df['sales_amount'] < 0]
            if len(negative_sales) > 0:
                results['violations'].append({
                    'rule': 'Sales amount must be >= 0',
                    'violation_count': len(negative_sales)
                })
                results['status'] = 'FAIL'
                logger.warning(f"  Negative sales found: {len(negative_sales)} rows")
        
        if not results['violations']:
            logger.info(f"  All business rules validated successfully")
        
        return results
    
    def check_referential_integrity(self, df, name, reference_dfs=None):
        """
        Check referential integrity with other tables
        
        Args:
            df: DataFrame to validate
            name: Name of the dataset
            reference_dfs: Dictionary of referenced tables
            
        Returns:
            Dictionary with validation results
        """
        logger.info(f"Checking referential integrity for {name}")
        
        results = {
            'dataset': name,
            'check': 'referential_integrity',
            'violations': [],
            'status': 'PASS'
        }
        
        if reference_dfs and name == 'transactions':
            # Check customer references
            if 'customers' in reference_dfs:
                customers = reference_dfs['customers']
                invalid_customers = df[~df['customer_id'].isin(customers['customer_id'])]
                if len(invalid_customers) > 0:
                    results['violations'].append({
                        'reference': 'customer_id -> customers',
                        'violation_count': len(invalid_customers)
                    })
                    results['status'] = 'FAIL'
                    logger.warning(f"  Invalid customer references: {len(invalid_customers)} rows")
            
            # Check product references
            if 'products' in reference_dfs:
                products = reference_dfs['products']
                invalid_products = df[~df['product_id'].isin(products['product_id'])]
                if len(invalid_products) > 0:
                    results['violations'].append({
                        'reference': 'product_id -> products',
                        'violation_count': len(invalid_products)
                    })
                    results['status'] = 'FAIL'
                    logger.warning(f"  Invalid product references: {len(invalid_products)} rows")
        
        if not results['violations']:
            logger.info(f"  All referential integrity checks passed")
        
        return results
    
    def generate_quality_report(self, validation_results):
        """
        Generate data quality report
        
        Args:
            validation_results: List of validation result dictionaries
            
        Returns:
            Quality score (0-100)
        """
        logger.info("Generating quality report")
        
        total_checks = len(validation_results)
        passed_checks = sum(1 for r in validation_results if r.get('status') == 'PASS')
        
        quality_score = (passed_checks / total_checks * 100) if total_checks > 0 else 0
        
        logger.info(f"Quality Score: {quality_score:.2f}% ({passed_checks}/{total_checks} checks passed)")
        
        # Save report
        report_file = self.processed_data_dir / 'data_quality_report.csv'
        report_df = pd.DataFrame(validation_results)
        report_df.to_csv(report_file, index=False)
        logger.info(f"Quality report saved to {report_file}")
        
        return quality_score
    
    def validate_all(self):
        """
        Run all validation checks
        
        Returns:
            Overall quality score
        """
        validation_results = []
        
        # Load all datasets
        datasets = {}
        for dataset_name in ['transactions', 'customers', 'products', 'countries']:
            try:
                file_path = self.processed_data_dir / f'{dataset_name}.csv'
                if file_path.exists():
                    datasets[dataset_name] = pd.read_csv(file_path)
            except Exception as e:
                logger.error(f"Error loading {dataset_name}: {str(e)}")
        
        # Define validation rules
        transactions = datasets.get('transactions')
        if transactions is not None:
            validation_results.append(
                self.check_null_values(transactions, 'transactions', 
                                      ['transaction_id', 'customer_id', 'product_id', 'sales_amount'])
            )
            validation_results.append(
                self.check_duplicates(transactions, 'transactions', ['transaction_id'])
            )
            validation_results.append(
                self.check_value_ranges(transactions, 'transactions',
                                       {'quantity': (1, 10000), 'sales_amount': (0, 1000000)})
            )
            validation_results.append(
                self.check_business_rules(transactions, 'transactions')
            )
            validation_results.append(
                self.check_referential_integrity(transactions, 'transactions', datasets)
            )
        
        customers = datasets.get('customers')
        if customers is not None:
            validation_results.append(
                self.check_null_values(customers, 'customers', ['customer_id', 'customer_name'])
            )
            validation_results.append(
                self.check_duplicates(customers, 'customers', ['customer_id'])
            )
        
        products = datasets.get('products')
        if products is not None:
            validation_results.append(
                self.check_null_values(products, 'products', ['product_id', 'product_name', 'price'])
            )
            validation_results.append(
                self.check_duplicates(products, 'products', ['product_id'])
            )
        
        # Generate report
        quality_score = self.generate_quality_report(validation_results)
        
        return quality_score


def main():
    """Main validation workflow"""
    try:
        logger.info("Starting data validation process")
        
        validator = DataValidator()
        quality_score = validator.validate_all()
        
        if quality_score >= 95:
            logger.info("✓ Data quality is excellent")
            return 0
        elif quality_score >= 80:
            logger.warning("⚠ Data quality is acceptable but needs attention")
            return 0
        else:
            logger.error("✗ Data quality is poor - review issues before proceeding")
            return 1
            
    except Exception as e:
        logger.error(f"Data validation failed: {str(e)}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
