# Examining Billing data with BigQuery

A comprehensive project demonstrating how to analyze Google Cloud billing data using BigQuery, including dataset creation, data import, and complex SQL queries for cost analysis.

## Video 

https://youtu.be/_EbXHA3IwOY

## Overview

This project walks through the complete process of setting up BigQuery to analyze billing data, from creating datasets and tables to running sophisticated queries that provide insights into cloud spending patterns and resource usage.

## Prerequisites 

- Google Cloud Platform account
- Access to Google Cloud Console
- BigQuery service enabled
- Basic understanding of SQL

## Project Structure

```
bigquery-billing-analysis/
├── README.md
├── sql-queries/
│   ├── 01-basic-queries.sql
│   ├── 02-analysis-queries.sql
│   └── 03-advanced-analytics.sql
├── setup/
│   └── dataset-setup.md
├── docs/
│   ├── step-by-step-guide.md
│   └── query-explanations.md

```

## Quick Start

### 1. Setup BigQuery Dataset

1. Navigate to BigQuery in Google Cloud Console
2. Create a new dataset with the following specifications:
   - **Dataset ID**: `billing_dataset`
   - **Data location**: US
   - **Default maximum table age**: 1 day (with table expiration enabled)

### 2. Import Billing Data

1. Create a new table in your dataset
2. Configure the source:
   - **Create table from**: Google Cloud Storage
   - **File path**: `cloud-training/archinfra/BillingExport-2020-09-18.avro`
   - **File format**: Avro
3. Set destination:
   - **Table name**: `sampleinfotable`
   - **Table type**: Native table

### 3. Run Analysis Queries

Execute the provided SQL queries to analyze your billing data and gain insights into cost patterns and resource usage.

## Key Features

- **Automated Schema Detection**: BigQuery automatically creates schema from imported Avro files
- **Cost Analysis**: Identify high-cost services and resources
- **Usage Patterns**: Analyze billing frequency and common charge units
- **Service Comparison**: Compare costs across different Google Cloud services
- **Time-based Analysis**: Track spending over time periods

## Sample Queries

### Basic Cost Filtering
```sql
SELECT * FROM `billing_dataset.sampleinfotable`
WHERE Cost > 0
```

### Top Services by Cost
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

### High-Value Transactions
```sql
SELECT
  service.description,
  sku.description,
  location.country,
  cost,
  project.id,
  project.name,
  currency,
  usage.amount,
  usage.unit
FROM
  `billing_dataset.sampleinfotable`
WHERE
  cost > 10
```

## Key Insights from Analysis

Based on the sample dataset analysis:

- **Total Records**: 415,602 billing entries
- **Records with Charges**: 70,765 entries (Cost > 0)
- **Most Active Service**: Compute Engine (281,136 records)
- **Common Charge Unit**: Byte-seconds
- **High-Cost Services**: Various services with charges > $1

## Dataset Schema

The imported billing data includes the following key fields:

- `billing_account_id`: Account identifier
- `project.id` & `project.name`: Project information
- `service.description`: Service name
- `sku.description`: Stock Keeping Unit details
- `cost`: Charge amount
- `currency`: Currency type
- `usage.amount` & `usage.unit`: Usage metrics
- `location.country`: Geographic location
- `usage_start_time` & `usage_end_time`: Time periods

## Advanced Analytics

The project includes queries for:

- **Cost Trend Analysis**: Track spending over time
- **Service Utilization**: Compare usage across services
- **Geographic Distribution**: Analyze costs by location
- **Resource Optimization**: Identify cost-saving opportunities

## Best Practices

1. **Regular Analysis**: Run billing queries monthly for trend analysis
2. **Cost Alerts**: Set up automated alerts for unusual spending
3. **Resource Tagging**: Use proper labeling for better cost attribution
4. **Query Optimization**: Use partitioning and clustering for large datasets
5. **Security**: Implement proper IAM controls for billing data access

## Troubleshooting

### Common Issues

- **Permission Errors**: Ensure proper BigQuery and Cloud Storage permissions
- **Schema Mismatches**: Verify file format matches expected structure
- **Query Timeouts**: Use LIMIT clauses for large dataset exploration
- **Cost Concerns**: Monitor query costs, especially for large datasets

### Performance Tips

- Use `LIMIT` for exploratory queries
- Leverage BigQuery's automatic query optimization
- Consider materialized views for frequently accessed data
- Use appropriate data types and avoid unnecessary columns

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add your improvements or additional queries
4. Submit a pull request with detailed descriptions

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Additional Resources

- [BigQuery Documentation](https://cloud.google.com/bigquery/docs)
- [Cloud Billing Export Guide](https://cloud.google.com/billing/docs/how-to/export-data-bigquery)
- [SQL Best Practices](https://cloud.google.com/bigquery/docs/best-practices-performance-overview)
- [Cost Optimization Guide](https://cloud.google.com/billing/docs/how-to/cost-optimization)

## Support

For questions or issues:
1. Check the troubleshooting section
2. Review Google Cloud documentation
3. Open an issue in this repository
4. Contact the project maintainers

---

**Note**: This project uses sample billing data for demonstration purposes. In production environments, ensure proper security measures and compliance with your organization's data handling policies.
