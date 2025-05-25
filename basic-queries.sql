-- Basic BigQuery Billing Data Analysis Queries
-- These queries demonstrate fundamental operations on billing data

-- Query 1: Simple cost filtering
-- Returns all records where there was an actual charge
SELECT * FROM `billing_dataset.sampleinfotable`
WHERE Cost > 0;

-- Query 2: Basic data exploration
-- Shows the structure and sample data from the billing table
SELECT
  billing_account_id,
  project.id,
  project.name,
  service.description,
  currency,
  currency_conversion_rate,
  cost,
  usage.amount,
  usage.pricing_unit
FROM
  `billing_dataset.sampleinfotable`
LIMIT 100;

-- Query 3: Count total records
-- Get the total number of billing records
SELECT COUNT(*) as total_records
FROM `billing_dataset.sampleinfotable`;

-- Query 4: Count records with charges
-- Count how many records actually have costs > 0
SELECT COUNT(*) as records_with_charges
FROM `billing_dataset.sampleinfotable`
WHERE cost > 0;

-- Query 5: Basic cost statistics
-- Get basic statistical overview of costs
SELECT
  COUNT(*) as total_records,
  COUNT(CASE WHEN cost > 0 THEN 1 END) as charged_records,
  MIN(cost) as min_cost,
  MAX(cost) as max_cost,
  AVG(cost) as avg_cost,
  SUM(cost) as total_cost
FROM `billing_dataset.sampleinfotable`;

-- Query 6: Unique services overview
-- See what services are represented in the data
SELECT DISTINCT service.description as service_name
FROM `billing_dataset.sampleinfotable`
ORDER BY service_name;

-- Query 7: Unique projects overview
-- See what projects are represented in the data
SELECT DISTINCT 
  project.id,
  project.name
FROM `billing_dataset.sampleinfotable`
WHERE project.id IS NOT NULL
ORDER BY project.name;

-- Query 8: Currency breakdown
-- See what currencies are used in the billing data
SELECT 
  currency,
  COUNT(*) as record_count,
  SUM(cost) as total_cost_in_currency
FROM `billing_dataset.sampleinfotable`
GROUP BY currency
ORDER BY record_count DESC;