"""
Data Ingestion Script for Retail Sales Profitability Analysis
==============================================================

This script ingests raw data from various sources (CSV, database, API)
and loads it into the data warehouse.

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
        logging.FileHandler('logs/ingest_data.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DataIngester:
    """
    Class to handle data ingestion from multiple sources
    """
    
    def __init__(self, raw_data_dir='01_data/01_raw', processed_data_dir='01_data/02_processed'):
        """
        Initialize the DataIngester
        
        Args:
            raw_data_dir: Directory containing raw data files
            processed_data_dir: Directory to save processed data
        """
        self.raw_data_dir = Path(raw_data_dir)
        self.processed_data_dir = Path(processed_data_dir)
        self.processed_data_dir.mkdir(parents=True, exist_ok=True)
        
    def ingest_from_csv(self, file_path, **kwargs):
        """
        Ingest data from CSV file
        
        Args:
            file_path: Path to CSV file
            **kwargs: Additional arguments to pass to pd.read_csv()
            
        Returns:
            DataFrame containing the data
        """
        try:
            logger.info(f"Reading CSV file: {file_path}")
            df = pd.read_csv(file_path, **kwargs)
            logger.info(f"Successfully loaded {len(df)} rows from {file_path}")
            return df
        except Exception as e:
            logger.error(f"Error reading CSV file {file_path}: {str(e)}")
            raise
    
    def ingest_from_database(self, connection_string, query):
        """
        Ingest data from SQL Server database
        
        Args:
            connection_string: SQLAlchemy connection string
            query: SQL query to execute
            
        Returns:
            DataFrame containing the query results
        """
        try:
            from sqlalchemy import create_engine
            logger.info(f"Connecting to database: {connection_string}")
            engine = create_engine(connection_string)
            
            logger.info("Executing database query")
            df = pd.read_sql_query(query, engine)
            logger.info(f"Successfully loaded {len(df)} rows from database")
            return df
        except Exception as e:
            logger.error(f"Error reading from database: {str(e)}")
            raise
    
    def ingest_from_api(self, api_url, params=None, headers=None):
        """
        Ingest data from REST API
        
        Args:
            api_url: API endpoint URL
            params: Query parameters
            headers: HTTP headers
            
        Returns:
            DataFrame containing the API response
        """
        try:
            import requests
            logger.info(f"Fetching data from API: {api_url}")
            
            response = requests.get(api_url, params=params, headers=headers)
            response.raise_for_status()
            
            data = response.json()
            df = pd.json_normalize(data)
            logger.info(f"Successfully loaded {len(df)} rows from API")
            return df
        except Exception as e:
            logger.error(f"Error fetching from API {api_url}: {str(e)}")
            raise
    
    def load_all_data_sources(self):
        """
        Load data from all configured sources
        
        Returns:
            Dictionary of DataFrames by source name
        """
        data = {}
        
        # Load transactions (example: from CSV)
        logger.info("Loading transactions data...")
        try:
            transactions_file = self.raw_data_dir / 'transactions.csv'
            if transactions_file.exists():
                data['transactions'] = self.ingest_from_csv(transactions_file)
            else:
                logger.warning(f"Transactions file not found: {transactions_file}")
        except Exception as e:
            logger.error(f"Failed to load transactions: {str(e)}")
        
        # Load customers
        logger.info("Loading customers data...")
        try:
            customers_file = self.raw_data_dir / 'customers.csv'
            if customers_file.exists():
                data['customers'] = self.ingest_from_csv(customers_file)
            else:
                logger.warning(f"Customers file not found: {customers_file}")
        except Exception as e:
            logger.error(f"Failed to load customers: {str(e)}")
        
        # Load products
        logger.info("Loading products data...")
        try:
            products_file = self.raw_data_dir / 'products.csv'
            if products_file.exists():
                data['products'] = self.ingest_from_csv(products_file)
            else:
                logger.warning(f"Products file not found: {products_file}")
        except Exception as e:
            logger.error(f"Failed to load products: {str(e)}")
        
        # Load countries
        logger.info("Loading countries data...")
        try:
            countries_file = self.raw_data_dir / 'countries.csv'
            if countries_file.exists():
                data['countries'] = self.ingest_from_csv(countries_file)
            else:
                logger.warning(f"Countries file not found: {countries_file}")
        except Exception as e:
            logger.error(f"Failed to load countries: {str(e)}")
        
        return data
    
    def save_raw_data(self, data, name):
        """
        Save ingested data to processed directory
        
        Args:
            data: DataFrame to save
            name: Name of the data (used for filename)
        """
        try:
            output_file = self.processed_data_dir / f'{name}.csv'
            data.to_csv(output_file, index=False)
            logger.info(f"Saved {name} data to {output_file}")
        except Exception as e:
            logger.error(f"Error saving {name} data: {str(e)}")
            raise


def main():
    """Main ingestion workflow"""
    try:
        logger.info("Starting data ingestion process")
        
        # Initialize ingester
        ingester = DataIngester()
        
        # Load all data sources
        all_data = ingester.load_all_data_sources()
        
        # Save each data source
        for name, df in all_data.items():
            if df is not None and len(df) > 0:
                ingester.save_raw_data(df, name)
        
        logger.info("Data ingestion completed successfully")
        return 0
        
    except Exception as e:
        logger.error(f"Data ingestion failed: {str(e)}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
