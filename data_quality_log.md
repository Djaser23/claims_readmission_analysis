## inpatient_claims — loaded 6/23/26
- 66,773 rows loaded, 0 skipped
- NCH_BENE_IP_DDCTBL_AMT: 2,178 rows (3.26%) blank in source table. Loaded as 0's by MySQL.
  Decision: treat as 0 for now. REVISIT if doing per-claim financial sums.
- CLM_UTLZTN_DAY_CNT: 2,334 rows (3.5%) blank in source, loaded as 0 by MySQL.
  Decision: treat as 0 for now. REVISIT: decide whether 0 vs NULL affects utilization-count or PMPM-style calculations before using this field downstream.
- Dates stored as YYYYMMDD strings, not DATE type. Must STR_TO_DATE() before doing any date math.

## 30-Day Readmission Flag — 07/08/26
- Based on online figures, the national Medicare baseline is ~15–20%, so a single-digit rate is plausible but on the low end.
- Likely explanation: synthetic data may not replicate known clustering patterns.
- Known limitation: the primary readmission definition includes 1-day gaps, which may represent transfers rather than true readmissions.
  Decision: write an accompanying query excluding 1-day readmissions. The difference between the two counts is 292, approximately 4.5% of total 30-day readmission occurrences.
- Known limitation: data censoring — discharge dates within the last 30 days of the dataset preclude the possibility of observing a 30-day readmission for those claims.
  Decision: create a CTE-based filter to remove that subset and get accurate readmission rates.
- 324 discharges (0.49%) fell within 30 days of the observation window end date (2010-12-31) and were excluded from readmission rate calculations due to censoring. Minimal impact on analysis.
- Results of query `13_high_utilizer_flagging` reveal that the multiple diagnosis and procedure codes do not contain believable clinical patterns. The results appear to be a random data artifact of the synthetic data creation process.
  Decision: acknowledge and suggest that predictive modeling using multiple diagnosis-procedure codes should be limited to real claims data such as available on BigQuery.

## Censoring Filter Bug Fix — 08/06/26
- Bug: the censoring filter was originally applied *before* computing LEAD(), which could hide a valid next-admission date if that later discharge itself fell within the censored window.
- Fix: moved the filter to run *after* LEAD() computes `next_admission`, so the window function sees the full unfiltered admission sequence before censoring is applied.
- Impact: recovered 11 previously-missed readmissions (6,412 → 6,423), shifting the overall 30-day readmission rate from 9.65% to 9.67% (of 66,449 index discharges).
- Applied to: `06_readmission_by_drg.sql`, `08_overall_readmission_rate.sql`, `10_readmission_rate_by_icd9.sql`, `11_hrrp_condition_readmission_rates.sql`.

## High-utilizer flagging filter Bug Fix - 08/12/26
- Bug: Determined percentages were not coming back at five percent as anticipated, returned 2.9%, 1.8%, and 2.01% for 2008-2010 instead of the intended five percent, issue with using PERCENT_RANK() window function and not accounting for patients with the same number of claims per year. 
- Fix: Reworked query using ROW_NUMBER() instead of PERCENT_RANK() and using CEILING() to calculate top five percent cutoff, created validation query, verified five percent for years two thousand eight, nine, and two thousand ten. 
- Impact: Query now results in 5.01%, 5.00%, 5.00% for 2008-2010. Ties at the cutoff boundary broken by patient ID, meaning members with identical claim counts near the threshold may be arbitrarily included or excluded.
- Applied to `13a_high_utilizer_flagging`, `13a_high_utilizer_flagging_validation`,
`13b_high_utilizer_first_claim`
