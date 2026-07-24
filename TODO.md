# Project TODO

## Completed
- [x] Load inpatient claims data (66,773 rows)
- [x] Data quality checks
- [x] Length of stay calculation
- [x] Average LOS by DRG
- [x] Patient admission ranking
- [x] 30-day readmission flag (with and without 1-day gap exclusion)
- [x] Readmission rate by DRG — in progress (classification complete, aggregation pending)
- [x] Address data censoring with Max date (see NCH_BENE_DSCHRG_DT,CLM_ADMSN_DT)
- [x] Explain CLT formula in HAVING in more detail in the comments
- [x] Review and discuss DRG readmission rates in comments
- [x] Explain date limitation in comments section and then in data quality log
- [x] MySQL connection via python-dotenv
- [x] Pull readmission rate by DRG query into pandas DataFrame
- [x] Basic horizontal bar chart - top 20 DRGs
- [x] Add CMS national benchmark reference line (~15%) to chart
- [x] Add citation for CMS benchmark rate
- [x] Add markdown cells explaining methodology and limitations
- [x] Save chart as image file for README
- [x] Update README to reference notebook
- [x] ICD-9 condition mapping (AMI, Heart Failure, Pneumonia, COPD)
- [x] Condition-level readmission rates vs HRRP published benchmarks (because synthetic data on ICD-9 is so much lower than national averages I will pass on this part of the analysis)
- [x] Update notebook with savefig before show 
- [x] PMPM approximation
- [x] High-utilizer flagging
- [x] Add markdown cells to notebook explaining methodology and limitations

## In Progress



## Planned for Version 2
- [ ] BigQuery setup with real CMS Medicare data
- [ ] Logistic/linear regression readmission prediction model on BigQuery data
- [ ] Logistic/linear regression High-utilizer prediction model on BigQuery data (diagnosis and procedure coding)
- [ ] Tableau/PowerBI visualization - heatmap visualization of ICD-9 diagnosis code frequency among high-utilizers
- [] Run icd-9 frequency analysis - ICD-9 code frequency rates in the top 5% cohort vs.the same rates in the bottom 95% - Compute the ratio or percentage point difference
- [ ] Resolve iCloud duplicate folder issue


## Upcoming

- [ ] Polish and document final analyses
- [ ] Update README Analyses section
- [ ] Add Tableau/PowerBI visualization 

## Known Data Limitations
- Synthetic data — patterns may not reflect real Medicare population
- Dates stored as YYYYMMDD strings, require STR_TO_DATE() conversion
- NCH_BENE_IP_DDCTBL_AMT: 3.26% blank, loaded as 0
- CLM_UTLZTN_DAY_CNT: 3.5% blank, loaded as 0
