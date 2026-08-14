"""
Data Export Script for Retail Sales Profitability Analysis
===========================================================

This script exports processed data to various formats:
- CSV export
- Excel export
- SQL export
- JSON export

Author: BI Team
Date: 2024
Version: 1.0
"""

import pandas as pd
import numpy as np
import logging
from pathlib import Path
from datetime import datetime
import json
import sys

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('logs/export_data.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)


class DataExporter:
    """
    Class to handle data export to multiple formats
    """
    
    def __init__(self, processed_data_dir='01_data/02_processed',
                 export_dir='01_data/03_exports'):
        """
        Initialize the DataExporter
        
        Args:
            processed_data_dir: Directory containing processed data files
            export_dir: Directory to save exported data
        """
        self.processed_data_dir = Path(processed_data_dir)
        self.export_dir = Path(export_dir)
        self.excel_export_dir = self.export_dir / 'excel'
        self.powerbi_export_dir = self.export_dir / 'powerbi'
        
        # Create directories
        self.excel_export_dir.mkdir(parents=True, exist_ok=True)
        self.powerbi_export_dir.mkdir(parents=True, exist_ok=True)
    
    def load_processed_data(self):
        """
        Load all processed data files
        
        Returns:
            Dictionary of DataFrames by name
        """
        data = {}
        
        for dataset_name in ['transactions', 'customers', 'products', 'countries', 'dates']:
            try:
                file_path = self.processed_data_dir / f'{dataset_name}.csv'
                if file_path.exists():
                    data[dataset_name] = pd.read_csv(file_path)
                    logger.info(f"Loaded {dataset_name}: {len(data[dataset_name])} rows")
            except Exception as e:
                logger.error(f"Error loading {dataset_name}: {str(e)}")
        
        return data
    
    def export_to_csv(self, data):
        """
        Export data to CSV format
        
        Args:
            data: Dictionary of DataFrames
        """
        logger.info("Exporting data to CSV format")
        
        for name, df in data.items():
            try:
                output_file = self.excel_export_dir / f'{name}.csv'
                df.to_csv(output_file, index=False)
                logger.info(f"Exported {name} to {output_file}")
            except Exception as e:
                logger.error(f"Error exporting {name} to CSV: {str(e)}")
    
    def export_to_excel(self, data, filename='Retail_Sales_Data.xlsx'):
        """
        Export data to Excel workbook with multiple sheets
        
        Args:
            data: Dictionary of DataFrames
            filename: Output filename
        """
        logger.info(f"Exporting data to Excel: {filename}")
        
        try:
            output_file = self.excel_export_dir / filename
            
            with pd.ExcelWriter(output_file, engine='openpyxl') as writer:
                for name, df in data.items():
                    df.to_excel(writer, sheet_name=name, index=False)
                    logger.info(f"Exported sheet: {name}")
            
            logger.info(f"Excel file saved to {output_file}")
            
        except ImportError:
            logger.warning("openpyxl not installed. Installing required package...")
            import subprocess
            subprocess.check_call([sys.executable, "-m", "pip", "install", "openpyxl"])
            self.export_to_excel(data, filename)
        except Exception as e:
            logger.error(f"Error exporting to Excel: {str(e)}")
    
    def export_to_json(self, data):
        """
        Export data to JSON format
        
        Args:
            data: Dictionary of DataFrames
        """
        logger.info("Exporting data to JSON format")
        
        for name, df in data.items():
            try:
                output_file = self.powerbi_export_dir / f'{name}.json'
                
                # Convert to records format
                records = df.to_dict(orient='records')
                
                # Handle datetime serialization
                json_str = json.dumps(records, default=str)
                
                with open(output_file, 'w') as f:
                    f.write(json_str)
                
                logger.info(f"Exported {name} to {output_file}")
            except Exception as e:
                logger.error(f"Error exporting {name} to JSON: {str(e)}")
    
    def export_to_sql_insert(self, data):
        """
        Export data as SQL INSERT statements
        
        Args:
            data: Dictionary of DataFrames
        """
        logger.info("Generating SQL INSERT statements")
        
        for name, df in data.items():
            try:
                output_file = self.export_dir / f'{name}_insert.sql'
                
                with open(output_file, 'w') as f:
                    # Write table name
                    f.write(f"-- INSERT statements for {name}\n")
                    f.write(f"-- Generated: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n")
                    
                    # Get column names and types
                    columns = df.columns.tolist()
                    f.write(f"INSERT INTO {name} ({', '.join(columns)})\n")
                    f.write("VALUES\n")
                    
                    # Generate INSERT statements
                    for idx, row in df.iterrows():
                        values = []
                        for col in columns:
                            val = row[col]
                            if pd.isna(val):
                                values.append("NULL")
                            elif isinstance(val, (int, float)):
                                values.append(str(val))
                            elif isinstance(val, bool):
                                values.append("1" if val else "0")
                            else:
                                # Escape single quotes
                                escaped = str(val).replace("'", "''")
                                values.append(f"'{escaped}'")
                        
                        f.write(f"({', '.join(values)})")
                        f.write("," if idx < len(df) - 1 else ";")
                        f.write("\n")
                
                logger.info(f"Exported {name} to SQL INSERT file")
            except Exception as e:
                logger.error(f"Error exporting {name} to SQL: {str(e)}")
    
    def create_summary_report(self, data):
        """
        Create summary statistics report
        
        Args:
            data: Dictionary of DataFrames
        """
        logger.info("Creating summary report")
        
        try:
            report_lines = []
            report_lines.append("DATA QUALITY EXPORT SUMMARY")
            report_lines.append("=" * 50)
            report_lines.append(f"Export Date: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
            report_lines.append("")
            
            for name, df in data.items():
                report_lines.append(f"\n{name.upper()}")
                report_lines.append("-" * 30)
                report_lines.append(f"Total Rows: {len(df):,}")
                report_lines.append(f"Total Columns: {len(df.columns)}")
                report_lines.append(f"Columns: {', '.join(df.columns.tolist())}")
                report_lines.append(f"Memory Usage: {df.memory_usage(deep=True).sum() / 1024 / 1024:.2f} MB")
                
                # Add data type info
                report_lines.append("Data Types:")
                for col in df.columns:
                    report_lines.append(f"  - {col}: {df[col].dtype}")
            
            # Save report
            report_file = self.export_dir / f'export_summary_{datetime.now().strftime("%Y%m%d_%H%M%S")}.txt'
            with open(report_file, 'w') as f:
                f.write('\n'.join(report_lines))
            
            logger.info(f"Summary report saved to {report_file}")
            
        except Exception as e:
            logger.error(f"Error creating summary report: {str(e)}")
    
    def export_all(self, formats=['csv', 'json']):
        """
        Export data in multiple formats
        
        Args:
            formats: List of export formats ('csv', 'excel', 'json', 'sql')
        """
        logger.info("Starting data export process")
        
        # Load processed data
        data = self.load_processed_data()
        
        if not data:
            logger.error("No data to export")
            return False
        
        # Export in requested formats
        try:
            if 'csv' in formats:
                self.export_to_csv(data)
            
            if 'excel' in formats:
                self.export_to_excel(data)
            
            if 'json' in formats:
                self.export_to_json(data)
            
            if 'sql' in formats:
                self.export_to_sql_insert(data)
            
            # Create summary report
            self.create_summary_report(data)
            
            logger.info("Data export completed successfully")
            return True
            
        except Exception as e:
            logger.error(f"Data export failed: {str(e)}")
            return False


def main():
    """Main export workflow"""
    try:
        logger.info("Starting data export process")
        
        exporter = DataExporter()
        
        # Export in all formats
        success = exporter.export_all(formats=['csv', 'json', 'sql'])
        
        if success:
            logger.info("✓ Data export completed successfully")
            return 0
        else:
            logger.error("✗ Data export encountered errors")
            return 1
            
    except Exception as e:
        logger.error(f"Data export failed: {str(e)}")
        return 1


if __name__ == '__main__':
    sys.exit(main())
