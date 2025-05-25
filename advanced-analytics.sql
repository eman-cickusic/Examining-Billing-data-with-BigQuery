-- Advanced Analytics Queries for BigQuery Billing Data
-- These queries demonstrate complex analysis patterns and optimization insights

-- Query 1: Time-based cost analysis
-- Analyze spending patterns over time (monthly aggregation)
SELECT
  EXTRACT(YEAR FROM usage_start_time) AS year,
  EXTRACT(MONTH FROM usage_start_time) AS month,
  service.description,
  COUNT(*) AS billing_records,
  ROUND(SUM(cost),2) AS monthly_cost,
  ROUND(AVG(cost),4) AS avg_cost_per_record
FROM
  `billing_dataset.sampleinfotable`
WHERE usage_start_time IS NOT NULL AND cost > 0
GROUP BY
  EXTRACT(YEAR FROM usage_start_time),
  EXTRACT(MONTH FROM usage_start_time),
  service.description
ORDER BY
  year, month, monthly_cost DESC;

-- Query 2: Cost efficiency analysis
-- Compare cost per unit of usage across services
SELECT
  service.description,
  usage.unit,
  COUNT(*) AS records,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(SUM(usage.amount),2) AS total_usage,
  ROUND(SUM(cost) / NULLIF(SUM(usage.amount), 0),6) AS cost_per_unit
FROM
  `billing_dataset.sampleinfotable`
WHERE cost > 0 AND usage.amount > 0
GROUP BY
  service.description, usage.unit
HAVING SUM(usage.amount) > 0
ORDER BY
  cost_per_unit DESC;

-- Query 3: Outlier detection
-- Find unusually high charges (outliers) using statistical analysis
WITH cost_stats AS (
  SELECT
    service.description,
    AVG(cost) AS avg_cost,
    STDDEV(cost) AS stddev_cost
  FROM `billing_dataset.sampleinfotable`
  WHERE cost > 0
  GROUP BY service.description
)
SELECT
  b.service.description,
  b.cost,
  b.project.name,
  b.sku.description,
  cs.avg_cost,
  ROUND((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0), 2) AS z_score
FROM
  `billing_dataset.sampleinfotable` b
JOIN
  cost_stats cs ON b.service.description = cs.service.description
WHERE
  b.cost > 0
  AND ABS((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) > 2  -- More than 2 standard deviations
ORDER BY
  ABS((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) DESC
LIMIT 50;

-- Query 4: Resource utilization patterns
-- Analyze usage patterns to identify optimization opportunities
SELECT
  service.description,
  sku.description,
  usage.unit,
  COUNT(*) AS usage_instances,
  ROUND(SUM(usage.amount),2) AS total_usage,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(AVG(usage.amount),2) AS avg_usage_per_instance,
  ROUND(MIN(usage.amount),2) AS min_usage,
  ROUND(MAX(usage.amount),2) AS max_usage,
  ROUND(STDDEV(usage.amount),2) AS usage_stddev
FROM
  `billing_dataset.sampleinfotable`
WHERE cost > 0 AND usage.amount > 0
GROUP BY
  service.description, sku.description, usage.unit
HAVING COUNT(*) > 10  -- Only include SKUs with significant usage
ORDER BY
  total_cost DESC
LIMIT 100;

-- Query 5: Cross-service cost correlation
-- Identify services that tend to be used together
SELECT
  s1.service_name AS service_1,
  s2.service_name AS service_2,
  COUNT(*) AS co_occurrence_count,
  ROUND(AVG(s1.project_cost + s2.project_cost),2) AS avg_combined_cost
FROM (
  SELECT 
    project.id AS project_id,
    service.description AS service_name,
    SUM(cost) AS project_cost
  FROM `billing_dataset.sampleinfotable`
  WHERE cost > 0
  GROUP BY project.id, service.description
) s1
JOIN (
  SELECT 
    project.id AS project_id,
    service.description AS service_name,
    SUM(cost) AS project_cost
  FROM `billing_dataset.sampleinfotable`
  WHERE cost > 0
  GROUP BY project.id, service.description
) s2
ON s1.project_id = s2.project_id AND s1.service_name < s2.service_name
GROUP BY s1.service_name, s2.service_name
HAVING COUNT(*) > 5  -- Only show pairs that occur together frequently
ORDER BY co_occurrence_count DESC
LIMIT 20;

-- Query 6: Cost trend analysis with moving averages
-- Calculate rolling averages to smooth out cost fluctuations
WITH daily_costs AS (
  SELECT
    DATE(usage_start_time) AS usage_date,
    service.description,
    SUM(cost) AS daily_cost
  FROM `billing_dataset.sampleinfotable`
  WHERE usage_start_time IS NOT NULL AND cost > 0
  GROUP BY DATE(usage_start_time), service.description
)
SELECT
  usage_date,
  service.description,
  daily_cost,
  AVG(daily_cost) OVER (
    PARTITION BY service.description 
    ORDER BY usage_date 
    ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
  ) AS seven_day_avg,
  AVG(daily_cost) OVER (
    PARTITION BY service.description 
    ORDER BY usage_date 
    ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
  ) AS thirty_day_avg
FROM daily_costs
ORDER BY service.description, usage_date;

-- Query 7: Cost optimization recommendations
-- Identify potential areas for cost savings
WITH service_analysis AS (
  SELECT
    service.description,
    COUNT(*) AS total_records,
    COUNT(CASE WHEN cost = 0 THEN 1 END) AS zero_cost_records,
    SUM(cost) AS total_cost,
    AVG(cost) AS avg_cost,
    MAX(cost) AS max_cost,
    MIN(CASE WHEN cost > 0 THEN cost END) AS min_positive_cost
  FROM `billing_dataset.sampleinfotable`
  GROUP BY service.description
)
SELECT
  sa.service.description,
  sa.total_cost,
  sa.total_records,
  sa.zero_cost_records,
  ROUND(sa.zero_cost_records * 100.0 / sa.total_records, 2) AS zero_cost_percentage,
  sa.max_cost,
  sa.avg_cost,
  CASE
    WHEN sa.zero_cost_percentage > 50 THEN 'High unused resource allocation'
    WHEN sa.max_cost > sa.avg_cost * 10 THEN 'High cost variance - check for spikes'
    WHEN sa.total_cost > 1000 THEN 'High-cost service - review regularly'
    ELSE 'Normal usage pattern'
  END AS optimization_recommendation
FROM service_analysis sa
WHERE sa.total_cost > 0
ORDER BY sa.total_cost DESC;

-- Query 8: Resource allocation efficiency
-- Compare theoretical vs actual usage patterns
SELECT
  project.name AS project_name,
  service.description AS service_name,
  COUNT(*) AS billing_events,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(SUM(usage.amount),2) AS total_usage,
  usage.unit,
  ROUND(AVG(cost),4) AS avg_cost_per_event,
  ROUND(SUM(cost) / NULLIF(SUM(usage.amount), 0),6) AS cost_per_usage_unit,
  -- Calculate cost distribution
  ROUND(MIN(CASE WHEN cost > 0 THEN cost END),4) AS min_cost,
  ROUND(MAX(cost),4) AS max_cost,
  ROUND(STDDEV(cost),4) AS cost_stddev
FROM `billing_dataset.sampleinfotable`
WHERE project.name IS NOT NULL AND cost > 0
GROUP BY
  project.name, service.description, usage.unit
HAVING COUNT(*) > 5  -- Focus on frequently used resources
ORDER BY
  total_cost DESC, project_name, service_name
LIMIT 100;