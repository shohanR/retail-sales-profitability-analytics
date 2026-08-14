/*
===============================================================================
01_create_schema.sql

Purpose
-------
Create the PostgreSQL schemas used by the Retail Sales & Profitability
Analytics project.

Architecture
------------
staging  -> raw/import-oriented objects
analytics -> dimensional analytical model

Design principles
-----------------
- Separate ingestion/staging objects from analytical objects.
- Use explicit schemas instead of placing everything in public.
- Keep the analytical model compatible with Excel and Power BI.
===============================================================================
*/

BEGIN;

CREATE SCHEMA IF NOT EXISTS staging;

CREATE SCHEMA IF NOT EXISTS analytics;

COMMIT;