# Renewable Energy Consumption Dashboard

An end-to-end analytics project: a household renewable-energy dataset is stored in **AWS S3**, loaded into **Snowflake**, transformed with SQL, and visualised in a **Tableau** dashboard.

```
CSV  ──►  AWS S3  ──►  Snowflake (stage + COPY INTO)  ──►  SQL transformations  ──►  Tableau dashboard
```
Dashboard Screenshots:

https://github.com/taha5847/taha7.github/blob/main/Dashboard%20Pic1.png?raw=true



## Repository contents

| File | Purpose |
|------|---------|
| `Renewable_Energy_Usage_Sampled.csv` | Source dataset (1,000 households) |
| `Tableau_integration_with_Aws_and_Load.sql` | Snowflake script: S3 integration, table creation, data load, exploration and transformations |
| `Energy_Consumption_Dashboard.twb` | Tableau workbook with 6 worksheets and 1 dashboard, connected live to Snowflake |

## Dataset

`Renewable_Energy_Usage_Sampled.csv`: 1,000 rows, one per household, 12 columns.

| Column | Type | Description |
|--------|------|-------------|
| `Household_ID` | string | Unique household identifier (e.g. `H01502`) |
| `Region` | string | 6 regions: Africa, Asia, Australia, Europe, North America, South America |
| `Country` | string | 25 countries |
| `Energy_Source` | string | Biomass, Geothermal, Hydro, Solar, Wind |
| `Monthly_Usage_kWh` | float | Monthly energy usage in kWh (~50 to ~1,500) |
| `Year` | int | Observation year (2020 to 2024) |
| `Household_Size` | int | Number of people (1 to 8) |
| `Income_Level` | string | Low, Middle, High |
| `Urban_Rural` | string | Urban or Rural |
| `Adoption_Year` | int | Year the household adopted renewable energy (2010 to 2024) |
| `Subsidy_Received` | string | Yes / No |
| `Cost_Savings_USD` | float | Cost savings in USD (~10 to ~500) |

## Pipeline

### 1. AWS S3 and Snowflake integration
The SQL script creates a Snowflake **storage integration** (`tableau_Integration`) that lets Snowflake assume an IAM role to read from the S3 bucket. After creating it, run `DESC INTEGRATION tableau_Integration;` and copy `STORAGE_AWS_IAM_USER_ARN` and `STORAGE_AWS_EXTERNAL_ID` into the IAM role's trust policy.

### 2. Database, table and stage
- Database `tableau`, schema `tableau_Data`
- Table `tableau_dataset` matching the CSV columns
- External stage `tableau_stage` pointing at the S3 bucket via the integration

### 3. Load
```sql
COPY INTO tableau_dataset
FROM @tableau_stage
FILE_FORMAT = (TYPE = CSV FIELD_DELIMITER = ',' SKIP_HEADER = 1)
ON_ERROR = 'CONTINUE';
```
Bad rows are skipped rather than aborting the load.

### 4. Exploration
- Row counts per `Region`
- Row counts per `Income_Level`

### 5. Transformations
The raw table is copied to `energy_consumption`, which is the table Tableau reads. Two adjustments are then applied by income level:

| Income level | `Monthly_Usage_kWh` | `Cost_Savings_USD` |
|--------------|--------------------|--------------------|
| Low | +10% (×1.1) | −10% (×0.9) |
| Middle | +20% (×1.2) | −20% (×0.8) |
| High | +30% (×1.3) | −30% (×0.7) |

> **Warning:** these `UPDATE` statements are not idempotent. Running them twice compounds the multipliers. To reset, recreate the table with `CREATE OR REPLACE TABLE energy_consumption AS SELECT * FROM tableau_dataset;` and run each update once.

## Tableau dashboard

`Energy_Consumption_Dashboard.twb` contains a dashboard named **Energy Consumption Dashboard**, built from six bar-chart worksheets on a live Snowflake connection (`TABLEAU.TABLEAU_DATA.ENERGY_CONSUMPTION`):

| Worksheet | Measure | Dimension |
|-----------|---------|-----------|
| KWH by Region | Sum of `Monthly_Usage_kWh` | Region |
| KWH by Country | Sum of `Monthly_Usage_kWh` | Country |
| KWH by Energy Source | Sum of `Monthly_Usage_kWh` | Energy Source |
| CSU by Region | Sum of `Cost_Savings_USD` | Region |
| CSU by Country | Sum of `Cost_Savings_USD` | Country |
| CSU by Energy Source | Sum of `Cost_Savings_USD` | Energy Source |

("CSU" = Cost Savings USD.)

## Getting started

**Prerequisites:** an AWS account with an S3 bucket and IAM role, a Snowflake account with a warehouse, and Tableau Desktop.

1. Upload `Renewable_Energy_Usage_Sampled.csv` to your S3 bucket.
2. Edit the placeholders in the SQL script: IAM role ARN, bucket name (`STORAGE_AWS_ROLE_ARN`, `STORAGE_ALLOWED_LOCATIONS`, stage `url`).
3. Run the script in Snowflake from top to bottom, then update the IAM trust policy as described above.
4. Open `Energy_Consumption_Dashboard.twb` in Tableau. When prompted, re-enter the Snowflake server, warehouse and credentials for your own account.

## Tech stack

AWS S3, AWS IAM, Snowflake, SQL, Tableau.

## Notes and known issues

- **Credentials and identifiers:** the SQL file contains an AWS account ID and role ARN, and the `.twb` file contains a Snowflake server URL and username. Replace these with placeholders before publishing the repository publicly. Tableau does not store the password in the `.twb`.
- `list @s1` in the SQL script refers to a stage that is never created (the stage is `tableau_stage`). Change it to `list @tableau_stage;` or remove it.
- `CREATE DATABASE tableau;` will fail if the database already exists; use `CREATE DATABASE IF NOT EXISTS` for re-runs.
- The income-level multipliers are illustrative scenario adjustments, not measured values, so dashboard figures reflect the adjusted data rather than the raw CSV.
- The dataset is a 1,000-row sample, so results are best treated as a demonstration rather than population-level conclusions.

## Possible extensions

- Add filters and charts for `Income_Level`, `Urban_Rural` and `Subsidy_Received`
- Trend analysis over `Year` and `Adoption_Year`
- Compare savings between subsidised and non-subsidised households
- Automate loading with Snowpipe
