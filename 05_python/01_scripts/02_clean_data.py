"""
Data Cleaning Script for Retail Sales Profitability Analysis
==============================================================

This script performs data cleaning and transformation operations:
- Remove duplicates
- Handle missing values
- Fix data type issues
- Standardize formats
- Remove outliers and anomalies

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
        logging.FileHandler('logs/clean_data.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DataCleaner:
    """
    Class to handle data cleaning and transformation
    """
    
    def __init__(self, processed_data_dir='01_data/02_processed'):
        """
        Initialize the DataCleaner
        
        Args:
            processed_data_dir: Directory containing processed data files
        """
        self.processed_data_dir = Path(processed_data_dir)
        self.cleaning_report = {}
        
    def remove_duplicates(self, df, subset=None, keep='first'):
        """
        Remove duplicate rows
        
        Args:
            df: DataFrame to clean
            subset: Column(s) to consider for identifying duplicates
            keep: Which duplicates to keep ('first', 'last', False)
            
        Returns:
            Cleaned DataFrame
        """
        initial_rows = len(df)
        df_clean = df.drop_duplicates(subset=subset, keep=keep)
        removed_rows = initial_rows - len(df_clean)
        
        logger.info(f"Removed {removed_rows} duplicate rows")
        return df_clean
    
    def handle_missing_values(self, df, strategy='drop'):
        """
        Handle missing values in DataFrame
        
        Args:
            df: DataFrame to clean
            strategy: How to handle missing values
                      'drop': Remove rows with missing values
                      'fill_numeric': Fill with mean for numeric columns
                      'fill_forward': Forward fill
                      'fill_backward': Backward fill
            
        Returns:
            Cleaned DataFrame
        """
        initial_rows = len(df)
        
        if strategy == 'drop':
            df_clean = df.dropna()
            removed_rows = initial_rows - len(df_clean)
            logger.info(f"Removed {removed_rows} rows with missing values")
            
        elif strategy == 'fill_numeric':
            df_clean = df.copy()
            numeric_cols = df_clean.select_dtypes(include=[np.number]).columns
            df_clean[numeric_cols] = df_clean[numeric_cols].fillna(df_clean[numeric_cols].mean())
            logger.info(f"Filled {len(numeric_cols)} numeric columns with mean")
            
        elif strategy == 'fill_forward':
            df_clean = df.fillna(method='ffill')
            logger.info("Filled missing values using forward fill")
            
        elif strategy == 'fill_backward':
            df_clean = df.fillna(method='bfill')
            logger.info("Filled missing values using backward fill")
        else:
            logger.warning(f"Unknown strategy: {strategy}")
            df_clean = df
        
        return df_clean
    
    def fix_data_types(self, df, dtype_mapping=None):
        """
        Fix data type issues
        
        Args:
            df: DataFrame to fix
            dtype_mapping: Dictionary of column -> dtype mappings
            
        Returns:
            DataFrame with corrected data types
        """
        df_clean = df.copy()
        
        if dtype_mapping:
            for column, dtype in dtype_mapping.items():
                if column in df_clean.columns:
                    try:
                        df_clean[column] = df_clean[column].astype(dtype)
                        logger.info(f"Converted {column} to {dtype}")
                    except Exception as e:
                        logger.error(f"Error converting {column} to {dtype}: {str(e)}")
        
        # Auto-detect common types
        for column in df_clean.columns:
            # Try to convert to numeric
            try:
                df_clean[column] = pd.to_numeric(df_clean[column], errors='ignore')
            except:
                pass
            
            # Try to convert to datetime
            if 'date' in column.lower() or 'time' in column.lower():
                try:
                    df_clean[column] = pd.to_datetime(df_clean[column], errors='ignore')
                except:
                    pass
        
        return df_clean
    
    def standardize_formats(self, df):
        """
        Standardize data formats (dates, strings, numbers)
        
        Args:
            df: DataFrame to standardize
            
        Returns:
            Standardized DataFrame
        """
        df_clean = df.copy()
        
        # Standardize string columns (trim whitespace, lowercase where appropriate)
        string_cols = df_clean.select_dtypes(include=['object']).columns
        for col in string_cols:
            if df_clean[col].dtype == 'object':
                df_clean[col] = df_clean[col].str.strip()
                logger.info(f"Trimmed whitespace from {col}")
        
        # Standardize date formats
        datetime_cols = df_clean.select_dtypes(include=['datetime64']).columns
        for col in datetime_cols:
            # Ensure consistent date format (YYYY-MM-DD)
            logger.info(f"Standardized datetime format for {col}")
        
        # Standardize numeric formats (2 decimal places for currency)
        numeric_cols = df_clean.select_dtypes(include=[np.number]).columns
        for col in numeric_cols:
            if 'amount' in col.lower() or 'price' in col.lower() or 'cost' in col.lower():
                df_clean[col] = df_clean[col].round(2)
        
        return df_clean
    
    def remove_outliers(self, df, columns=None, method='iqr', threshold=1.5):
        """
        Remove outliers using IQR method
        
        Args:
            df: DataFrame to clean
            columns: Columns to check for outliers
            method: 'iqr' for interquartile range or 'zscore' for z-score
            threshold: IQR multiplier (1.5 for moderate outliers)
            
        Returns:
            DataFrame with outliers removed
        """
        df_clean = df.copy()
        
        if columns is None:
            columns = df_clean.select_dtypes(include=[np.number]).columns
        
        removed_count = 0
        
        for col in columns:
            if method == 'iqr':
                Q1 = df_clean[col].quantile(0.25)
                Q3 = df_clean[col].quantile(0.75)
                IQR = Q3 - Q1
                lower_bound = Q1 - threshold * IQR
                upper_bound = Q3 + threshold * IQR
                
                mask = (df_clean[col] >= lower_bound) & (df_clean[col] <= upper_bound)
                removed_in_col = len(df_clean) - mask.sum()
                removed_count += removed_in_col
                
                df_clean = df_clean[mask]
                logger.info(f"Removed {removed_in_col} outliers from {col} using IQR method")
            
            elif method == 'zscore':
                from scipy import stats
                z_scores = np.abs(stats.zscore(df_clean[col].dropna()))
                mask = z_scores < 3
                removed_in_col = len(z_scores) - mask.sum()
                removed_count += removed_in_col
                logger.info(f"Removed {removed_in_col} outliers from {col} using z-score method")
        
        logger.info(f"Total outliers removed: {removed_count}")
        return df_clean
    
    def clean_transactions(self, df):
        """
        Clean transaction data
        
        Args:
            df: Raw transactions DataFrame
            
        Returns:
            Cleaned transactions DataFrame
        """
        logger.info("Starting transaction data cleaning")
        
        # Step 1: Remove duplicates
        df = self.remove_duplicates(df, subset=['transaction_id'])
        
        # Step 2: Fix data types
        dtype_mapping = {
            'transaction_id': 'string',
            'customer_id': 'string',
            'product_id': 'string',
            'quantity': 'int64',
            'unit_price': 'float64',
            'sales_amount': 'float64',
            'cost_amount': 'float64'
        }
        df = self.fix_data_types(df, dtype_mapping)
        
        # Step 3: Handle missing values
        df = self.handle_missing_values(df, strategy='drop')
        
        # Step 4: Standardize formats
        df = self.standardize_formats(df)
        
        # Step 5: Remove invalid records
        # Remove negative amounts
        df = df[df['sales_amount'] >= 0]
        df = df[df['cost_amount'] >= 0]
        
        # Remove zero quantity
        df = df[df['quantity'] > 0]
        
        logger.info("Transaction data cleaning completed")
        return df
    
    def clean_customers(self, df):
        """
        Clean customer data
        
        Args:
            df: Raw customers DataFrame
            
        Returns:
            Cleaned customers DataFrame
        """
        logger.info("Starting customer data cleaning")
        
        # Remove duplicates
        df = self.remove_duplicates(df, subset=['customer_id'])
        
        # Handle missing values
        df = self.handle_missing_values(df, strategy='drop')
        
        # Standardize formats
        df = self.standardize_formats(df)
        
        logger.info("Customer data cleaning completed")
        return df
    
    def clean_products(self, df):
        """
        Clean product data
        
        Args:
            df: Raw products DataFrame
            
        Returns:
            Cleaned products DataFrame
        """
        logger.info("Starting product data cleaning")
        
        # Remove duplicates
        df = self.remove_duplicates(df, subset=['product_id'])
        
        # Handle missing values
        df = self.handle_missing_values(df, strategy='drop')
        
        # Standardize formats
        df = self.standardize_formats(df)
        
        # Remove invalid prices
        df = df[df['price'] > 0]
        
        logger.info("Product data cleaning completed")
        return df
    
    def clean_countries(self, df):
        """
        Clean country data
        
        Args:
            df: Raw countries DataFrame
            
        Returns:
            Cleaned countries DataFrame
        """
        logger.info("Starting country data cleaning")
        
        # Remove duplicates
        df = self.remove_duplicates(df, subset=['country_id', 'country_name'])
        
        # Handle missing values
        df = self.handle_missing_values(df, strategy='drop')
        
        # Standardize formats
        df = self.standardize_formats(df)
        
        logger.info("Country data cleaning completed")
        return df
    
    def save_cleaned_data(self, df, name):
        """
        Save cleaned data
        
        Args:
            df: DataFrame to save
            name: Name of the dataset
        """
        try:
            output_file = self.processed_data_dir / f'{name}.csv'
            df.to_csv(output_file, index=False)
            logger.info(f"Saved cleaned {name} data to {output_file}")
        except Exception as e:
            logger.error(f"Error saving {name} data: {str(e)}")
            raise


def main():
    """Main cleaning workflow"""
    try:
        logger.info("Starting data cleaning process")
        
        cleaner = DataCleaner()
        
        # Clean each dataset
        datasets = ['transactions', 'customers', 'products', 'countries']
        
        for dataset in datasets:
            try:
                input_file = cleaner.processed_data_dir / f'{dataset}.csv'
                if input_file.exists():
                    df = pd.read_csv(input_file)
                    
                    if dataset == 'transactions':
                        df_clean = cleaner.clean_transactions(df)
                    elif dataset == 'customers':
                        df_clean = cleaner.clean_customers(df)
                    elif dataset == 'products':
                        df_clean = cleaner.clean_products(df)
                    elif dataset == 'countries':
                        df_clean = cleaner.clean_countries(df)
                    
                    cleaner.save_cleaned_data(df_clean, dataset)
            except Exception as e:
                logger.error(f"Error cleaning {dataset}: {str(e)}")
        
        logger.info("Data cleaning completed successfully")
        return 0
        
    except Exception as e:
        logger.error(f"Data cleaning failed: {str(e)}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
