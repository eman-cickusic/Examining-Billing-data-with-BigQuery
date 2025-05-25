# BigQuery Dataset Setup Guide

This guide provides detailed instructions for setting up your BigQuery environment to analyze billing data.

## Prerequisites

Before starting, ensure you have:
- Access to Google Cloud Console
- BigQuery API enabled in your project
- Appropriate IAM permissions:
  - BigQuery Admin or BigQuery User
  - Storage Object Viewer (for accessing sample data)

## Step 1: Access BigQuery

1. Open the [Google Cloud Console](https://console.cloud.google.com)
2. Navigate to BigQuery by:
   - Using the navigation menu (☰) → BigQuery
   - Or searching for "BigQuery" in the search bar
3. If prompted with a welcome dialog, click "Done"

## Step 2: Create a Dataset

1. In the BigQuery console, locate your project in the left sidebar
2. Click the **View actions** icon (⋮) next to your project ID
3. Select **Create dataset**
4. Configure the dataset with these settings:

   | Property | Value | Description |
   |----------|-------|-------------|
   | Dataset ID | `billing_dataset` | Unique identifier for your dataset |
   | Data location | `US` | Geographic location for data storage |
   | Default table expiration | `1 days` | Automatic cleanup of old tables |
   | Enable table expiration | ✅ Checked | Automatically remove old data |

5. Click **Create Dataset**
6. Verify that `billing_dataset` appears in the left sidebar

## Step 3: Create and Import Table

### Create the Table

1. Click the **View actions** icon (⋮) next to your `billing_dataset`
2. Select **Open** to expand the dataset
3. Click **Create Table**

### Configure Source Data

In the **Source** section:

| Property | Value | Notes |
|----------|-------|-------|
| Create table from | `Google Cloud Storage` | Import from cloud storage |
| Select file from GCS bucket | `cloud-training/archinfra/BillingExport-2020-09-18.avro` | Pre-prepared sample data |
| File format | `Avro` | Binary format with embedded schema |

### Configure Destination

In the **Destination** section:

| Property | Value | Notes |
|----------|-------|-------|
| Project | *(auto-filled)* | Your current project |
| Dataset | `billing_dataset` | Previously created dataset |
| Table name | `sampleinfotable` | Name for your billing table |
| Table type | `Native table` | Standard BigQuery table |

### Schema Configuration

- Leave schema as **Auto detect** - BigQuery will automatically detect the schema from the Avro file
- The Avro format includes embedded schema information

### Advanced Options (Optional)

You can leave these as default, but useful options include:
- **Write preference**: Write if empty (default)
- **Create disposition**: Create if needed (default)

## Step 4: Execute Table Creation

1. Click **Create Table**
2. Wait for the job to complete (this may take a few minutes)
3. Once complete, you'll see `sampleinfotable` under your dataset in the left sidebar

## Step 5: Verify the Import

### Check Table Details
1. Click on `sampleinfotable` in the left sidebar
2. Review the **Schema** tab to see the automatically detected fields
3. Click the **Details** tab to verify:
   - Number of rows: Should show 415,602 rows
   - Table size and creation time

### Preview the Data
1. Click the **Preview** tab
2. You should see sample billing records with fields like:
   - `billing_account_id`
   - `project` (nested object with id and name)
   - `service` (nested object with description)
   - `cost`
   - `currency`
   - `usage` (nested object with amount and unit)

## Expected Schema

The imported table should have the following key fields:

```
billing_account_id (STRING)
project (RECORD)
  ├── id (STRING)
  └── name (STRING)
service (RECORD)
  └── description (STRING)
sku (RECORD)
  └── description (STRING)
location (RECORD)
  └── country (STRING)
cost (FLOAT)
currency (STRING)
currency_conversion_rate (FLOAT)
usage (RECORD)
  ├── amount (FLOAT)
  ├── unit (STRING)
  └── pricing_unit (STRING)
usage_start_time (TIMESTAMP)
usage_end_time (TIMESTAMP)
```

## Troubleshooting

### Common Issues and Solutions

**Error: "Access Denied"**
- Ensure you have BigQuery Admin or User permissions
- Check that BigQuery API is enabled for your project

**Error: "File not found"**
- Verify the GCS path exactly: `cloud-training/archinfra/BillingExport-2020-09-18.avro`
- Ensure you have Storage Object Viewer permissions

**Schema Detection Failed**
- Avro files include embedded schema - this should not occur
- Try recreating the table with manual schema specification if needed

**Import Job Timeout**
- Large files may take time to import
- Check the job history in BigQuery for completion status

### Verification Queries

Run these queries to verify your setup:

```sql
-- Check total row count
SELECT COUNT(*) as total_rows 
FROM `billing_dataset.sampleinfotable`;

-- Check for records with costs
SELECT COUNT(*) as charged_records 
FROM `billing_dataset.sampleinfotable` 
WHERE cost > 0;

-- Sample data preview
SELECT * FROM `billing_dataset.sampleinfotable` 
LIMIT 10;
```

## Next Steps

After successful setup:
1. Run the basic queries from `01-basic-queries.sql`
2. Explore the analysis queries in `02-analysis-queries.sql`
3. Try advanced analytics from `03-advanced-analytics.sql`

## Security Best Practices

- Use IAM roles to control access to billing data
- Consider data classification and compliance requirements
- Set up appropriate table expiration policies
- Monitor query costs, especially for large datasets
- Use authorized views to restrict access to sensitive fields

## Cost Optimization

- Set table expiration to avoid storage costs for temporary data
- Use partitioned tables for large, time-series billing data
- Consider clustering for frequently filtered columns
- Monitor slot usage for query optimization