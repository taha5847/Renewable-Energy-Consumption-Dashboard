CREATE OR REPLACE STORAGE INTEGRATION tableau_Integration
  TYPE = EXTERNAL_STAGE
  STORAGE_PROVIDER = 'S3'
  ENABLED = TRUE
  STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::325319172226:role/tableau.role'
  STORAGE_ALLOWED_LOCATIONS = ('s3://tableau325.project/')
  COMMENT = 'Optional Comment'


  //description Integration Object
  desc integration tableau_Integration;


  CREATE database tableau;

create schema tableau_Data;

create table tableau_dataset (
Household_ID	string,Region	string,Country	string,Energy_Source	string,
Monthly_Usage_kWh	float,Year	int,Household_Size	int,Income_Level	string,
Urban_Rural	string,Adoption_Year	int,Subsidy_Received	string,Cost_Savings_USD float




);


select * from tableau_dataset;

//drop database tableau;

create stage tableau.tableau_Data.tableau_stage
url = 's3://tableau325.project'
storage_integration = tableau_Integration

//desc stage s1

//drop stage s1;


copy into tableau_dataset 
from @tableau_stage
file_format = (type=csv field_delimiter=',' skip_header=1 )
on_error = 'continue'

list @s1



-- Know the distinct count of the region
select region, count(*) Count
from tableau_dataset
group by region


-- Make a replica of the dataset for transformation 

create table energy_consumption as select * from tableau_dataset 

-- Check replica table have data or not

select * from energy_consumption


-- Know the income_level count by category (high,low,middle)
select income_level,count(*) Count_Income_Level
from energy_consumption
group by income_level

-- increase montly usage
-- for low -> 10%
-- for middle -> 20%
-- for High -> 30%

update energy_consumption
set MONTHLY_USAGE_KWH = case
when income_level = 'Low' then  monthly_usage_kwh * 1.1 
when income_level = 'Middle' then monthly_usage_kwh * 1.2
else  monthly_usage_kwh * 1.3
end

-- Reduce cost_saving_usd according to income level
-- Low -> 10%
-- Middle -> 20%
-- High -> 30%

update energy_consumption
set cost_savings_usd = case
when income_level = 'Low' then  cost_savings_usd * 0.9 
when income_level = 'Middle' then cost_savings_usd * 0.8
else  cost_savings_usd * 0.7
end