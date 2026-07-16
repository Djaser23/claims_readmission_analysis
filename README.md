# Claims Readmission Analysis

## Overview
This project analyzes CMS Medicare claims data to identify readmission patterns and cost utilization opportunities. Using the 2008-2010 DE-SynPUF synthetic inpatient and outpatient claims files, the analysis applies SQL-based methods common in health plan and population health analytics — including length of stay by diagnosis, high-utilizer identification, and 30-day readmission flagging.

## Data Source

CMS 2008-2010 DE-SynPUF synthetic Medicare claims files. 66,773 inpatient claims rows loaded (Sample 1).

**File Names:**
- DE1_0_2008_to_2010_Inpatient_Claims_Sample_1.csv
- DE1_0_2008_to_2010_Outpatient_Claims_Sample_1.csv


**Source:** 
https://www.cms.gov/data-research/statistics-trends-and-reports/medicare-claims-synthetic-public-use-files/cms-2008-2010-data-entrepreneurs-synthetic-public-use-file-de-synpuf


## Project Structure
- `queries/` — SQL scripts for data setup, quality checks, and analysis
- `data_quality_log.md` — running log of data quality findings
- `analysis/` - folder for ipynb files with continued analysis and visualization


## Analyses
- 30 day readmission analysis (2 versions - with and without single day readmissions with discussion of advantages of each approach in comments)
- `readmission_analysis.ipynb` - Top 20 readmission rates by DRG with national average comparison. 

## Preview
![Top 20 DRGs by 30-Day Readmission Rate](images/top20_drg_readmission_rate.png)

## Tools
MySQL Workbench
GitHub
Python
pandas
matplotlib

## Status
In progress — SQL analysis complete, Python visualization underway, ICD-9 condition mapping and BigQuery extension planned