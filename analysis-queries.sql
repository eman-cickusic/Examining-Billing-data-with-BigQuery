-- Advanced Analysis Queries for BigQuery Billing Data
-- These queries provide deeper insights into spending patterns and resource usage

-- Query 1: Latest 100 charges
-- Find the most recent 100 records where there were actual charges
SELECT
  service.description,
  sku.description,
  location.country,
  cost,
  project.id,
  project.name,
  currency,
  currency_conversion_rate,
  usage.amount,
  usage.unit,
  usage_end_time
FROM
  `billing_dataset.sampleinfotable`
WHERE
  Cost > 0
ORDER BY usage_end_time DESC
LIMIT 100;

-- Query 2: High-value transactions
-- Find all charges that were more than $10
SELECT
  service.description,
  sku.description,
  location.country,
  cost,
  project.id,
  project.name,
  currency,
  currency_conversion_rate,
  usage.amount,
  usage.unit
FROM
  `billing_dataset.sampleinfotable`
WHERE
  cost > 10
ORDER BY cost DESC;

-- Query 3: Service frequency analysis
-- Find which product/service has the most billing records
SELECT
  service.description,
  COUNT(*) AS billing_records,
  SUM(cost) AS total_cost,
  AVG(cost) AS avg_cost_per_record
FROM
  `billing_dataset.sampleinfotable`
GROUP BY
  service.description
ORDER BY billing_records DESC;

-- Query 4: Expensive service transactions
-- Find the most frequently used services costing more than $1
SELECT
  service.description,
  COUNT(*) AS billing_records,
  SUM(cost) AS total_cost,
  AVG(cost) AS avg_cost
FROM
  `billing_dataset.sampleinfotable`
WHERE
  cost > 1
GROUP BY
  service.description
ORDER BY
  billing_records DESC;

-- Query 5: Usage unit analysis
-- Find the most commonly charged unit of measure
SELECT
  usage.unit,
  COUNT(*) AS billing_records,
  SUM(usage.amount) AS total_usage,
  SUM(cost) AS total_cost
FROM
  `billing_dataset.sampleinfotable`
WHERE cost > 0
GROUP BY
  usage.unit
ORDER BY
  billing_records DESC;

-- Query 6: Top services by total cost
-- Find services with the highest aggregate cost
SELECT
  service.description,
  ROUND(SUM(cost),2) AS total_cost,
  COUNT(*) AS record_count,
  ROUND(AVG(cost),4) AS avg_cost_per_record
FROM
  `billing_dataset.sampleinfotable`
GROUP BY
  service.description
ORDER BY
  total_cost DESC;

-- Query 7: Geographic cost distribution
-- Analyze costs by location/country
SELECT
  location.country,
  COUNT(*) AS billing_records,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(AVG(cost),4) AS avg_cost
FROM
  `billing_dataset.sampleinfotable`
WHERE location.country IS NOT NULL AND cost > 0
GROUP BY
  location.country
ORDER BY
  total_cost DESC;

-- Query 8: Project-wise cost analysis
-- Analyze spending by project
SELECT
  project.name,
  project.id,
  COUNT(*) AS billing_records,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(AVG(cost),4) AS avg_cost_per_record
FROM
  `billing_dataset.sampleinfotable`
WHERE project.id IS NOT NULL
GROUP BY
  project.name, project.id
ORDER BY
  total_cost DESC;

-- Query 9: SKU (Stock Keeping Unit) analysis
-- Top SKUs by cost and frequency
SELECT
  service.description AS service,
  sku.description AS sku,
  COUNT(*) AS billing_records,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(AVG(cost),4) AS avg_cost
FROM
  `billing_dataset.sampleinfotable`
WHERE sku.description IS NOT NULL AND cost > 0
GROUP BY
  service.description, sku.description
ORDER BY
  total_cost DESC
LIMIT 50;

-- Query 10: Cost distribution analysis
-- Understand the distribution of charges
SELECT
  CASE 
    WHEN cost = 0 THEN 'No charge'
    WHEN cost <= 1 THEN '$0-$1'
    WHEN cost <= 10 THEN '$1-$10'
    WHEN cost <= 100 THEN '$10-$100'
    WHEN cost <= 1000 THEN '$100-$1000'
    ELSE 'Over $1000'
  END AS cost_range,
  COUNT(*) AS record_count,
  ROUND(SUM(cost),2) AS total_cost_in_range
FROM
  `billing_dataset.sampleinfotable`
GROUP BY
  CASE 
    WHEN cost = 0 THEN 'No charge'
    WHEN cost <= 1 THEN '$0-$1'
    WHEN cost <= 10 THEN '$1-$10'
    WHEN cost <= 100 THEN '$10-$100'
    WHEN cost <= 1000 THEN '$100-$1000'
    ELSE 'Over $1000'
  END
ORDER BY
  MIN(cost);