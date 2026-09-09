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

## Query 05 Total Verification — 08/14/26
- Audit flagged 05_patient_readmission_analysis.sql's hardcoded totals (6,423 / 6,131) as unverifiable, since the 08/06/26 censoring filter bug fix was applied to 
  06/08/10/11 but not 05, and 6,423 exactly matches 08's post-fix total.
- Verified: isolated and reran Query 2 and Query 4 in 05 independently — both totals 
  (6,423 / 6,131) confirmed live, not stale copy-paste.
- Explanation: 05 has no censoring filter, so it was never subject to the 
  filter-before-LEAD() ordering bug that 06/08/10/11 had. 05's naive (uncensored) 
  approach and 08's corrected censoring filter independently converge on the same 
  count for this dataset.
- Decision: no code change needed in 05. Added clarifying comment to the file 
  documenting the verification and the reason for the match.

## Query 09 & 11 Diagnosis code update — 08/16/26 
- Replaced admitting diagnosis code (ADMTNG_ICD9_DGNS_CD) with principal discharge diagnosis code (ICD9_DGNS_CD_1) in queries 09 and 11, per CMS HRRP cohort methodology (Suter et al., 2014).
- Recomputing shifted rates by ≤0.5 percentage points across all four conditions; no substantial change to the overall finding that observed rates fall substantially below national benchmarks.
- Decision: updated README HRRP table and Methods section with corrected rates and field justification; added citation to References.

## Query 10 Readmission Count Fix — 09/04/26
- Bug: 10_readmission_rate_by_icd9.sql's HAVING clause reconstructed readmission counts via `readmission_rate * total_admissions`, using an already-rounded rate (3 decimal places). Rounding error could push a diagnosis code across the n≥10 CLT reliability threshold incorrectly.
- Fix: Added a direct `SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count` column alongside the existing rounded rate; updated HAVING to filter on `readmission_count >= 10 AND total_admissions - readmission_count >= 10`. Same pattern as 06_readmission_by_drg.sql.
- Verified via `10_readmission_rate_by_icd9_validation.sql`: found 7 false-negative diagnosis codes, all with `readmission_count` exactly equal to 10 — the true count cleared the threshold, but the rounded rate multiplied back through `total_admissions` fell just under it in each case. No false positives found. Fix expands the set of admitting diagnosis codes included in the 30-day readmission results by 7 codes.
- Applied to: `10_readmission_rate_by_icd9.sql`.

## Query 09 & 11 HRRP Mapping Caveats — 09/07/26
- Gap 1 (code breadth): queries 09 and 11 map HRRP conditions using a single leading ICD-9 prefix per condition (410/428/486/491-492-496), not validated against any official CMS specification of condition-defining codes. Checked two candidate CMS sources (HRRP overview page, QualityNet readmission methodology page) via find-in-page search for "ICD-9" — neither contains the
term, consistent with CMS's current specifications using ICD-10-CM (ICD-9 was retired for U.S. clinical coding in Oct 2015); this explanation is unverified.
- Gap 2 (citation scope): the Suter et al. (2014) citation used to justify the principal-diagnosis field choice (ICD9_DGNS_CD_1 over ADMTNG_ICD9_DGNS_CD) was applied to all four conditions in 11's docstring and the README. Fetched and read the full paper directly — its cohort is defined as AMI, HF, and pneumonia only; COPD is not mentioned anywhere in the paper. The citation does not
support the field choice for COPD.
- These two gaps are independent of each other and of the 08/16/26 diagnosis-field fix — that fix addressed which field to read from; Gap 1 is about how many codes are matched within that field; Gap 2 is about which conditions the original citation for the field choice actually covers.
- Decision: added caveats to 09/11 docstrings and README (Methods + Limitations) stating both gaps without overclaiming validation or citation support that doesn't exist. Did not attempt to source COPD's field-choice justification separately — flagged as unsourced rather than guessed at.
- Also corrected in passing: 09's docstring said "admitting diagnosis" though the query uses `ICD9_DGNS_CD_1` (principal diagnosis) — a leftover from before the 08/16/26 Suter fix that was never updated in 09 (11 was updated correctly at the time).

**[Sep 8, 2026] Added `readmission_count` to `11_hrrp_condition_readmission_rates.sql`**
- Query previously output only `readmission_rate` (rounded to 1 decimal) and `total_admissions`, with no raw numerator. Per the same reconstruction-risk logic flagged in the Sep 4 2026 entry, adding this directly as `SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END)` rather than back-deriving from the rounded rate avoids introducing rounding error, consistent with the fix pattern already applied in `06_readmission_by_drg.sql` and `10_readmission_rate_by_icd9.sql`.
- Verified: `readmission_count / total_admissions * 100` rounds to the pre-existing `readmission_rate` for all 4 conditions (Heart Failure 330/3132, Pneumonia 251/2442, AMI 161/1633, COPD 198/2021) — no discrepancy found, confirming the original point estimates were already accurate.
- This `readmission_count` is needed as direct input to the Wilson 95% CI computation (`statsmodels.stats.proportion_confint`) added to `hrrp_condition_readmission_analysis.ipynb`.