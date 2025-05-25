# Complete Step-by-Step Guide: BigQuery Billing Data Analysis

This comprehensive guide walks through every step of analyzing Google Cloud billing data using BigQuery, from initial setup to advanced analytics.

## Phase 1: Environment Setup

### Step 1: Access Google Cloud Console

1. **Open Google Cloud Console**
   - Navigate to [console.cloud.google.com](https://console.cloud.google.com)
   - Sign in with your Google Cloud account credentials

2. **Navigate to BigQuery**
   - Click the navigation menu (☰) in the top-left corner
   - Select "BigQuery" from the list of services
   - If prompted with a welcome dialog, click "Done"

### Step 2: Create Your Dataset

1. **Locate Your Project**
   - In the BigQuery console, find your project in the left sidebar
   - Project ID typically starts with "qwiklabs-gcp" for lab environments

2. **Create New Dataset**
   - Click the **View actions** icon (⋮) next to your project ID
   - Select **"Create dataset"**

3. **Configure Dataset Settings**
   ```
   Dataset ID: billing_dataset
   Data location: US
   Default maximum table age: 1 days
   ✅ Enable table expiration
   ```

4. **Confirm Creation**
   - Click **"Create Dataset"**
   - Verify `billing_dataset` appears in the left sidebar

## Phase 2: Data Import

### Step 3: Create Billing Table

1. **Access Dataset**
   - Click the **View actions** icon (⋮) next to `billing_dataset`
   - Select **"Open"** to expand the dataset
   - Click **"Create Table"**

2. **Configure Source Data**
   ```
   Create table from: Google Cloud Storage
   Select file from GCS bucket: cloud-training/archinfra/BillingExport-2020-09-18.avro
   File format: Avro
   ```

3. **Configure Destination**
   ```
   Project: [Your project ID - auto-filled]
   Dataset: billing_dataset
   Table name: sampleinfotable
   Table type: Native table
   ```

4. **Create the Table**
   - Leave schema as "Auto detect" (Avro files include schema)
   - Click **"Create Table"**
   - Wait for the import job to complete

### Step 4: Verify Data Import

1. **Check Table Structure**
   - Click `sampleinfotable` in the left sidebar
   - Review the **Schema** tab to see detected fields
   - Key fields should include: billing_account_id, project, service, cost, usage

2. **Verify Data Volume**
   - Click the **Details** tab
   - Confirm **Number of Rows**: 415,602

3. **Preview Sample Data**
   - Click the **Preview** tab
   - Review sample billing records to understand data structure

## Phase 3: Basic Data Exploration

### Step 5: Run Your First Query

1. **Open Query Editor**
   - Click **"Compose New Query"** button
   - The query editor will open in the main panel

2. **Execute Basic Query**
   ```sql
   SELECT * FROM `billing_dataset.sampleinfotable`
   WHERE Cost > 0
   LIMIT 100
   ```
   - Click **"Run"** to execute
   - This shows records with actual charges

3. **Analyze Results**
   - Expected result: ~70,765 rows with Cost > 0
   - Review the data structure and field types

### Step 6: Data Overview Queries

1. **Count Total Records**
   ```sql
   SELECT COUNT(*) as total_records
   FROM `billing_dataset.sampleinfotable`
   ```
   - Expected: 415,602 total records

2. **Count Charged Records**
   ```sql
   SELECT COUNT(*) as charged_records
   FROM `billing_dataset.sampleinfotable`
   WHERE cost > 0
   ```
   - Expected: 70,765 records with charges

3. **Basic Statistics**
   ```sql
   SELECT
     COUNT(*) as total_records,
     SUM(cost) as total_cost,
     AVG(cost) as average_cost,
     MAX(cost) as max_cost,
     MIN(cost) as min_cost
   FROM `billing_dataset.sampleinfotable`
   ```

## Phase 4: Service Analysis

### Step 7: Identify Top Services

1. **Services by Record Count**
   ```sql
   SELECT
     service.description,
     COUNT(*) AS billing_records
   FROM
     `billing_dataset.sampleinfotable`
   GROUP BY
     service.description
   ORDER BY billing_records DESC
   ```
   - Expected top result: Compute Engine with ~281,136 records

2. **Services by Total Cost**
   ```sql
   SELECT
     service.description,
     ROUND(SUM(cost),2) AS total_cost
   FROM
     `billing_dataset.sampleinfotable`
   GROUP BY
     service.description
   ORDER BY
     total_cost DESC
   ```

### Step 8: High-Value Transaction Analysis

1. **Transactions Over $10**
   ```sql
   SELECT
     service.description,
     sku.description,
     location.country,
     cost,
     project.id,
     project.name
   FROM
     `billing_dataset.sampleinfotable`
   WHERE
     cost > 10
   ORDER BY cost DESC
   ```

2. **Most Expensive Single Charges**
   ```sql
   SELECT
     service.description,
     cost,
     project.name,
     usage.amount,
     usage.unit
   FROM
     `billing_dataset.sampleinfotable`
   ORDER BY cost DESC
   LIMIT 20
   ```

## Phase 5: Usage Pattern Analysis

### Step 9: Usage Unit Analysis

1. **Most Common Billing Units**
   ```sql
   SELECT
     usage.unit,
     COUNT(*) AS billing_records
   FROM
     `billing_dataset.sampleinfotable`
   WHERE cost > 0
   GROUP BY
     usage.unit
   ORDER BY
     billing_records DESC
   ```
   - Expected top result: Byte-seconds as most common unit

2. **Cost Per Unit Analysis**
   ```sql
   SELECT
     usage.unit,
     COUNT(*) as records,
     ROUND(SUM(cost),2) as total_cost,
     ROUND(SUM(cost) / COUNT(*),4) as avg_cost_per_record
   FROM
     `billing_dataset.sampleinfotable`
   WHERE cost > 0
   GROUP BY usage.unit
   ORDER BY total_cost DESC
   ```

### Step 10: Geographic Analysis

1. **Costs by Country**
   ```sql
   SELECT
     location.country,
     COUNT(*) AS billing_records,
     ROUND(SUM(cost),2) AS total_cost
   FROM
     `billing_dataset.sampleinfotable`
   WHERE location.country IS NOT NULL AND cost > 0
   GROUP BY
     location.country
   ORDER BY
     total_cost DESC
   ```

## Phase 6: Project and Time Analysis

### Step 11: Project-Level Analysis

1. **Project Cost Breakdown**
   ```sql
   SELECT
     project.name,
     project.id,
     COUNT(*) AS billing_records,
     ROUND(SUM(cost),2) AS total_cost
   FROM
     `billing_dataset.sampleinfotable`
   WHERE project.id IS NOT NULL
   GROUP BY
     project.name, project.id
   ORDER BY
     total_cost DESC
   ```

### Step 12: Time-Based Analysis

1. **Recent Activity (Last 100 Charges)**
   ```sql
   SELECT
     service.description,
     cost,
     usage_end_time,
     project.name
   FROM
     `billing_dataset.sampleinfotable`
   WHERE
     Cost > 0
   ORDER BY usage_end_time DESC
   LIMIT 100
   ```

2. **Monthly Cost Trends**
   ```sql
   SELECT
     EXTRACT(YEAR FROM usage_start_time) AS year,
     EXTRACT(MONTH FROM usage_start_time) AS month,
     COUNT(*) AS records,
     ROUND(SUM(cost),2) AS monthly_cost
   FROM
     `billing_dataset.sampleinfotable`
   WHERE usage_start_time IS NOT NULL AND cost > 0
   GROUP BY
     EXTRACT(YEAR FROM usage_start_time),
     EXTRACT(MONTH FROM usage_start_time)
   ORDER BY year, month
   ```

## Phase 7: Advanced Analytics

### Step 13: Cost Distribution Analysis

1. **Cost Range Distribution**
   ```sql
   SELECT
     CASE 
       WHEN cost = 0 THEN 'No charge'
       WHEN cost <= 1 THEN '$0-$1'
       WHEN cost <= 10 THEN '$1-$10'
       WHEN cost <= 100 THEN '$10-$100'
       ELSE 'Over $100'
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
       ELSE 'Over $100'
     END
   ORDER BY MIN(cost)
   ```

### Step 14: Efficiency Metrics

1. **Services with High Zero-Cost Records**
   ```sql
   SELECT
     service.description,
     COUNT(*) AS total_records,
     COUNT(CASE WHEN cost = 0 THEN 1 END) AS zero_cost_records,
     ROUND(COUNT(CASE WHEN cost = 0 THEN 1 END) * 100.0 / COUNT(*), 2) AS zero_cost_percentage
   FROM
     `billing_dataset.sampleinfotable`
   GROUP BY
     service.description
   ORDER BY
     zero_cost_percentage DESC
   ```

## Phase 8: Optimization Insights

### Step 15: Cost Optimization Opportunities

1. **High-Variance Services (Potential Optimization)**
   ```sql
   SELECT
     service.description,
     COUNT(*) as records,
     ROUND(AVG(cost),4) as avg_cost,
     ROUND(MAX(cost),2) as max_cost,
     ROUND(STDDEV(cost),4) as cost_stddev,
     ROUND(MAX(cost) / NULLIF(AVG(cost), 0), 2) as cost_variance_ratio
   FROM
     `billing_dataset.sampleinfotable`
   WHERE cost > 0
   GROUP BY service.description
   HAVING COUNT(*) > 100  -- Focus on frequently used services
   ORDER BY cost_variance_ratio DESC
   ```

### Step 16: Summary Dashboard Query

1. **Executive Summary**
   ```sql
   SELECT
     'Total Records' as metric,
     CAST(COUNT(*) AS STRING) as value
   FROM `billing_dataset.sampleinfotable`
   
   UNION ALL
   
   SELECT
     'Records with Charges' as metric,
     CAST(COUNT(*) AS STRING) as value
   FROM `billing_dataset.sampleinfotable`
   WHERE cost > 0
   
   UNION ALL
   
   SELECT
     'Total Cost' as metric,
     CONCAT(', CAST(ROUND(SUM(cost),2) AS STRING)) as value
   FROM `billing_dataset.sampleinfotable`
   
   UNION ALL
   
   SELECT
     'Top Service by Records' as metric,
     service.description as value
   FROM `billing_dataset.sampleinfotable`
   GROUP BY service.description
   ORDER BY COUNT(*) DESC
   LIMIT 1
   ```

## Phase 9: Best Practices and Next Steps

### Step 17: Query Optimization

1. **Use LIMIT for exploration**
   - Add `LIMIT 1000` to large queries during development
   - Remove limits for final analysis

2. **Leverage BigQuery's performance**
   - Use appropriate WHERE clauses to filter data
   - Group by specific fields rather than SELECT *

3. **Monitor query costs**
   - Check query validator for data processing estimates
   - Use query history to track spending

### Step 18: Ongoing Monitoring Setup

1. **Create Scheduled Queries** (Optional)
   - Set up automated reports for regular billing analysis
   - Schedule weekly or monthly cost summaries

2. **Export Results**
   - Save query results to Google Sheets for sharing
   - Export to CSV for external analysis tools

## Expected Results Summary

After completing all steps, you should have discovered:

- **Total Records**: 415,602 billing entries
- **Charged Records**: ~70,765 entries with cost > 0
- **Top Service**: Compute Engine (~281,136 records)
- **Common Charge Unit**: Byte-seconds
- **Cost Distribution**: Varied across services and projects

## Troubleshooting Common Issues

**Query Errors:**
- Check table names match exactly: `billing_dataset.sampleinfotable`
- Ensure proper backticks around table references
- Verify field names in schema tab

**Performance Issues:**
- Use LIMIT clauses for large result sets
- Add WHERE conditions to filter unnecessary data
- Avoid SELECT * on large tables

**Access Issues:**
- Verify BigQuery permissions
- Check project ID is correct
- Ensure billing dataset was created successfully

## Next Steps for Production Use

1. **Set up real billing export** to BigQuery from your production account
2. **Implement cost alerting** based on query insights
3. **Create automated dashboards** using Data Studio or similar tools
4. **Establish regular review processes** for cost optimization
5. **Set up proper IAM controls** for billing data access