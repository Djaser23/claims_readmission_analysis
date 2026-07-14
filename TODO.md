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
- [] Explain date limitation in comments section and then in data quality log

## In Progress

- [ ] Resolve additional folder appearing in icloud

## Upcoming
- [ ] PMPM approximation
- [ ] High-utilizer flagging
- [ ] Polish and document final analyses
- [ ] Update README Analyses section
- [ ] Add Tableau visualization (stretch goal)

## Known Data Limitations
- Synthetic data — patterns may not reflect real Medicare population
- Dates stored as YYYYMMDD strings, require STR_TO_DATE() conversion
- NCH_BENE_IP_DDCTBL_AMT: 3.26% blank, loaded as 0
- CLM_UTLZTN_DAY_CNT: 3.5% blank, loaded as 0
