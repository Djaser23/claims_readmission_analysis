## inpatient_claims - loaded 6/23/26
- 66,773 rows loaded, 0 skipped 
- NCH_BENE_IP_DDCTBL_AMT: 2,178 rows (3.26%) blank in source table. Loaded as 0's by MySQL
Decision: treat as 0 for now. REVISIT if doing per-claim financial sums.
- CLM_UTLZTN_DAY_CNT: 2,334 rows (3.5%) blank in source, loaded as 0 by MySQL.
Decision: treat as 0 for now. REVISIT: decide whether 0 vs NULL affects utilization -count or PMPM-style calculations before using this field downstream.
- Dates stored as YYYYMMDD strings, not DATE type. Must STR_TO_DATE() before doing any date math.
## 30-Day Readmission Flag — 07/08/26
- Raw readmission count: 6,423 (9.6% of 66,773 claims)
- Based on online figures the national Medicare baseline is ~15-20%, so 9.6% is plausible but on the low end.
- Likely explanation: synthetic data may not replicate known clustering patterns
- Known limitation: Query 1 definition includes 1-day gaps which may represent transfers rather than true readmissions. 
- Decision: Write an accompanying query which excludes the 1 day readmission incidence. The difference between the two counts is 292 accounting for approximately 4.5% of the total 30 day readmission occurrences. 
- Known limitation: Data censoring due to discharge dates within the last 30 days in the dataset preclude the possibility of having a 30 day readmission for those DRG claims. 
- Decision: Create a filter using a CTE to remove that subset of data to get accurate readmission rates
-324 discharges (0.49%) fell within 30 days of the observation window end date (2010-12-31) and were excluded from readmission rate calculations due to censoring. Minimal impact on analysis. Note: date fields stored as YYYYMMDD strings — STR_TO_DATE() required for all date math.