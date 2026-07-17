# 30-Day Readmission Analysis — CMS Medicare Claims (DE-SynPUF)

SQL-based analysis of 66,773 Medicare inpatient claims identifying 30-day
readmission patterns by diagnosis, with data quality auditing, censoring
correction, and comparison against the national readmission benchmark.

## Key Findings

- Overall 30-day readmission rate: **9.65%** across 66,449 index discharges
- National all-cause benchmark: **14.67%** (Definitive Healthcare, 2025, sourced from CMS data)
- Highest readmission rates: 
**Coagulation Disorders (DRG 813)** at 22.8%, 
**Prostatectomy with MCC (DRG 665)** at 19.5%,
**Hand or Wrist Proc, Except Major Thumb or Joint Proc w CC/MCC (DRG 513)** at 18.8%,
**Reticuloendothelial & Immunity Disorders (DRG 815)** at 18.6%, and 
**Extracranial Procedures w MCC (DRG 037)** at 18.2%
  
- Notable: the highest-rate DRGs span hematologic, urologic, orthopedic, 
  immunologic, and neurologic conditions — no cardiac DRGs appear in the 
  top 5, despite cardiac conditions being the primary focus of CMS HRRP 
  readmission reduction programs.

![Top 20 DRGs by 30-Day Readmission Rate](images/top20_drg_readmission_rate.png)  


## Research Question

Which diagnosis groups drive 30-day readmissions in this Medicare
population, and how do their rates compare to the national benchmark once
low-volume and censored discharges are handled correctly?


## Methods

- **Readmission flagging:** LEAD() window functions over per-patient
  discharge sequences (CTE-structured), computed two ways — including and
  excluding 1-day gaps — with the tradeoffs documented in query comments
- **Censoring correction:** Excluded [324] discharges (0.49%) within 30
  days of the observation window end, since their readmission status is
  unobservable; naive inclusion understates the true rate
- **Statistical reliability filter:** DRGs retained only where n×p ≥ 10 and
  n×(1−p) ≥ 10 (CLT proportions check), preventing unstable rates from
  low-volume diagnosis groups
- **Rate calculation:** Conditional aggregation (AVG of CASE WHEN) by DRG



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