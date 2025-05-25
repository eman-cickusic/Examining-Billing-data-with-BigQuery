# BigQuery Billing Analysis: Query Explanations

This document provides detailed explanations of the SQL queries used in the billing data analysis project, including their purpose, key concepts, and expected results.

## Basic Queries (01-basic-queries.sql)

### Query 1: Simple Cost Filtering
```sql
SELECT * FROM `billing_dataset.sampleinfotable`
WHERE Cost > 0;
```

**Purpose**: Filter out zero-cost entries to focus on actual charges
**Key Concepts**: 
- Basic WHERE clause filtering
- Excludes free tier usage and $0 charges
**Expected Results**: ~70,765 records with actual costs
**Business Value**: Understand what services are actually generating charges

---

### Query 2: Basic Data Exploration
```sql
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
FROM `billing_dataset.sampleinfotable`
LIMIT 100;
```

**Purpose**: Explore the data structure and key fields
**Key Concepts**:
- Nested field access (project.id, usage.amount)
- LIMIT clause for controlled exploration
**Expected Results**: 100 sample records showing data structure
**Business Value**: Understand available data fields for deeper analysis

---

### Query 3: Record Count Statistics
```sql
SELECT
  COUNT(*) as total_records,
  COUNT(CASE WHEN cost > 0 THEN 1 END) as charged_records,
  MIN(cost) as min_cost,
  MAX(cost) as max_cost,
  AVG(cost) as avg_cost,
  SUM(cost) as total_cost
FROM `billing_dataset.sampleinfotable`;
```

**Purpose**: Get high-level statistics about the billing data
**Key Concepts**:
- Aggregate functions (COUNT, MIN, MAX, AVG, SUM)
- Conditional counting with CASE WHEN
**Expected Results**: Complete statistical overview
**Business Value**: Baseline understanding of spending patterns and data completeness

## Analysis Queries (02-analysis-queries.sql)

### Query 1: Latest Charges Analysis
```sql
SELECT
  service.description,
  sku.description,
  location.country,
  cost,
  project.id,
  project.name,
  currency,
  usage_end_time
FROM `billing_dataset.sampleinfotable`
WHERE Cost > 0
ORDER BY usage_end_time DESC
LIMIT 100;
```

**Purpose**: Identify most recent billing activity
**Key Concepts**:
- ORDER BY with DESC for reverse chronological order
- Multi-field selection for comprehensive view
**Expected Results**: 100 most recent charges
**Business Value**: Understand current spending patterns and recent service usage

---

### Query 2: High-Value Transaction Detection
```sql
SELECT
  service.description,
  sku.description,
  location.country,
  cost,
  project.id,
  project.name
FROM `billing_dataset.sampleinfotable`
WHERE cost > 10
ORDER BY cost DESC;
```

**Purpose**: Identify expensive transactions that warrant attention
**Key Concepts**:
- Threshold-based filtering (cost > 10)
- Descending sort by cost amount
**Expected Results**: All charges over $10, highest first
**Business Value**: Focus cost optimization efforts on high-impact items

---

### Query 3: Service Frequency Analysis
```sql
SELECT
  service.description,
  COUNT(*) AS billing_records,
  SUM(cost) AS total_cost,
  AVG(cost) AS avg_cost_per_record
FROM `billing_dataset.sampleinfotable`
GROUP BY service.description
ORDER BY billing_records DESC;
```

**Purpose**: Understand which services generate the most billing activity
**Key Concepts**:
- GROUP BY for aggregation
- Multiple aggregate functions in single query
**Expected Results**: Compute Engine likely has highest record count (~281,136)
**Business Value**: Identify services that drive operational complexity and cost

---

### Query 4: Premium Service Usage
```sql
SELECT
  service.description,
  COUNT(*) AS billing_records,
  SUM(cost) AS total_cost,
  AVG(cost) AS avg_cost
FROM `billing_dataset.sampleinfotable`
WHERE cost > 1
GROUP BY service.description
ORDER BY billing_records DESC;
```

**Purpose**: Focus on services with substantial per-transaction costs
**Key Concepts**:
- Combining WHERE filtering with GROUP BY aggregation
- Multiple metrics for comprehensive view
**Expected Results**: Services with meaningful charges (>$1)
**Business Value**: Identify premium service usage patterns

## Advanced Analytics (03-advanced-analytics.sql)

### Query 1: Time-Based Cost Analysis
```sql
SELECT
  EXTRACT(YEAR FROM usage_start_time) AS year,
  EXTRACT(MONTH FROM usage_start_time) AS month,
  service.description,
  COUNT(*) AS billing_records,
  ROUND(SUM(cost),2) AS monthly_cost
FROM `billing_dataset.sampleinfotable`
WHERE usage_start_time IS NOT NULL AND cost > 0
GROUP BY
  EXTRACT(YEAR FROM usage_start_time),
  EXTRACT(MONTH FROM usage_start_time),
  service.description
ORDER BY year, month, monthly_cost DESC;
```

**Purpose**: Analyze spending trends over time by service
**Key Concepts**:
- EXTRACT function for date/time manipulation
- Multi-level grouping (time + service)
- NULL handling with IS NOT NULL
**Expected Results**: Monthly cost breakdown by service
**Business Value**: Identify seasonal patterns and growth trends

---

### Query 2: Cost Efficiency Analysis
```sql
SELECT
  service.description,
  usage.unit,
  COUNT(*) AS records,
  ROUND(SUM(cost),2) AS total_cost,
  ROUND(SUM(usage.amount),2) AS total_usage,
  ROUND(SUM(cost) / NULLIF(SUM(usage.amount), 0),6) AS cost_per_unit
FROM `billing_dataset.sampleinfotable`
WHERE cost > 0 AND usage.amount > 0
GROUP BY service.description, usage.unit
HAVING SUM(usage.amount) > 0
ORDER BY cost_per_unit DESC;
```

**Purpose**: Calculate cost efficiency metrics across services
**Key Concepts**:
- NULLIF to prevent division by zero
- HAVING clause for post-aggregation filtering
- Multi-column grouping for granular analysis
**Expected Results**: Cost per unit of usage for different services
**Business Value**: Compare efficiency across services and identify optimization opportunities

---

### Query 3: Statistical Outlier Detection
```sql
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
  cs.avg_cost,
  ROUND((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0), 2) AS z_score
FROM `billing_dataset.sampleinfotable` b
JOIN cost_stats cs ON b.service.description = cs.service.description
WHERE
  b.cost > 0
  AND ABS((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) > 2
ORDER BY ABS((b.cost - cs.avg_cost) / NULLIF(cs.stddev_cost, 0)) DESC
LIMIT 50;
```

**Purpose**: Identify unusually high charges using statistical analysis
**Key Concepts**:
- Common Table Expressions (WITH clause)
- Statistical functions (STDDEV)
- Z-score calculation for outlier detection
- Self-joins for complex analysis
**Expected Results**: Charges that are >2 standard deviations from the mean
**Business Value**: Quickly identify anomalous charges that need investigation

---

### Query 4: Cross-Service Correlation
```sql
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
HAVING COUNT(*) > 5
ORDER BY co_occurrence_count DESC
LIMIT 20;
```

**Purpose**: Find services that are commonly used together
**Key Concepts**:
- Subqueries for data preparation
- Self-joins with inequality conditions
- String comparison for avoiding duplicate pairs
**Expected Results**: Service pairs that frequently appear in the same projects
**Business Value**: Understand service dependencies and bundle optimization opportunities

## Key SQL Concepts Explained

### 1. Nested Field Access
BigQuery's billing data contains nested (RECORD) fields:
```sql
project.id          -- Access nested field
service.description -- Access nested field
usage.amount        -- Access nested field
```

### 2. Window Functions
Used for advanced analytics like moving averages:
```sql
AVG(daily_cost) OVER (
  PARTITION BY service.description 
  ORDER BY usage_date 
  ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
) AS seven_day_avg
```

### 3. Common Table Expressions (CTEs)
Break complex queries into readable parts:
```sql
WITH cost_stats AS (
  SELECT service.description, AVG(cost) AS avg_cost
  FROM billing_table
  GROUP BY service.description
)
SELECT * FROM cost_stats WHERE avg_cost > 10;
```

### 4. Conditional Aggregation
Count or sum based on conditions:
```sql
COUNT(CASE WHEN cost > 0 THEN 1 END) AS charged_records
SUM(CASE WHEN cost > 10 THEN cost ELSE 0 END) AS high_cost_total
```

### 5. Statistical Functions
Calculate statistical measures:
```sql
STDDEV(cost)     -- Standard deviation
PERCENTILE_CONT(0.5) OVER() -- Median
```

## Query Performance Best Practices

### 1. Use Appropriate Filtering
```sql
-- Good: Filter early
WHERE cost > 0 AND usage_start_time > '2020-01-01'

-- Avoid: No filtering on large tables
SELECT * FROM large_table
```

### 2. Limit Exploration Queries
```sql
-- Good for exploration
SELECT * FROM table LIMIT 1000

-- Expensive for large tables
SELECT * FROM table
```

### 3. Use Proper Aggregations
```sql
-- Efficient: Single pass aggregation
SELECT service, COUNT(*), SUM(cost), AVG(cost)
FROM table GROUP BY service

-- Less efficient: Multiple queries
SELECT COUNT(*) FROM table WHERE service = 'Compute Engine'
SELECT SUM(cost) FROM table WHERE service = 'Compute Engine'
```

## Business Intelligence Insights

### Cost Optimization Patterns
1. **High-frequency, low-cost services** may benefit from reserved capacity
2. **High-variance services** need spike investigation
3. **Geographic distribution** analysis reveals data transfer costs
4. **Time-based patterns** help with capacity planning

### Anomaly Detection
1. **Z-score analysis** identifies unusual charges
2. **Percentage-based thresholds** catch proportion anomalies
3. **Time-series analysis** reveals trending issues

### Resource Planning
1. **Co-occurrence analysis** informs architecture decisions
2. **Usage efficiency metrics** guide technology choices
3. **Cost trend analysis** supports budget planning