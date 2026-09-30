# Project TODO

## Completed
- [x] Load inpatient claims data (66,773 rows)
- [x] Data quality checks
- [x] Length of stay calculation
- [x] Average LOS by DRG
- [x] Patient admission ranking
- [x] 30-day readmission flag (with and without 1-day gap exclusion)
- [x] Readmission rate by DRG (06; Wilson 95% CIs computed in readmission_analysis.ipynb)
- [x] Address data censoring with Max date (see NCH_BENE_DSCHRG_DT,CLM_ADMSN_DT)
- [x] Explain CLT formula in HAVING in more detail in the comments (label now "minimum-count reliability filter"; see Upcoming for the comment rewording)
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
- [x] Condition-level readmission rates vs HRRP published benchmarks (query 11 + hrrp_condition_readmission_analysis.ipynb, Wilson 95% CIs, informal CI-vs-benchmark comparison, no formal test)
- [x] Update notebook with savefig before show 
- [x] PMPM approximation (12) and true PMPM using BENE_HI_CVRAGE_TOT_MONS as member-months denominator (12b, validated by 12c)
- [x] High-utilizer flagging
- [x] Add markdown cells to notebook explaining methodology and limitations
- [x] Fix hardcoded local paths (01_setup_table.sql, HRRP notebook)
- [x] Standardize database connection — remove per-file USE statements
- [x] Add README Setup section
- [x] Add caveat to 09/11 docstrings: HRRP condition mapping uses a single 3-digit ICD-9 prefix per condition, a simplification vs. CMS's actual broader code sets
- [x] Build 10b_readmission_rate_by_icd9_principal.sql (principal-diagnosis companion to 10); README Analyses and data_quality_log entries added
- [x] Join Beneficiary Summary file (`BENE_HI_CVRAGE_TOT_MONS`) for a true PMPM member-months denominator (12b; fixed 09/27/26 to include zero-coverage members)
- [x] 95% CI for overall 30-day readmission rate (9.67%, n=66,449): 9.45–9.89%, normal approximation (08b), reported in README
- [x] Zero-coverage claims contradiction check (12d): ~$4.76M in inpatient claims tied to zero-coverage member-years; root cause still open
- [x] Documentation consistency pass (09/29/26): BUG HISTORY pointers in 02b/02c/12c, CI-comparison wording in file 11 and README, HRRP field-choice citation separated from unvalidated prefix mapping, data_quality_log entry added
- [x] ICD-9 diagnosis description lookup table — scripts/load_icd9_dx_lookup.py parses CMS v28 file (CMS28_DESC_LONG_DX.txt, Latin-1, 14,432 codes), creates `icd9_dx_lookup`, loads all rows and verifies the row count

## In Progress



## Planned for Version 2
- [ ] BigQuery setup with real CMS Medicare data
- [ ] Logistic/linear regression readmission prediction model on BigQuery data
- [ ] Logistic/linear regression High-utilizer prediction model on BigQuery data (diagnosis and procedure coding)
- [ ] Tableau/PowerBI visualization - heatmap visualization of ICD-9 diagnosis code frequency among high-utilizers
- [ ] Run icd-9 frequency analysis - ICD-9 code frequency rates in the top 5% cohort vs.the same rates in the bottom 95% - Compute the ratio or percentage point difference
- [ ] Resolve iCloud duplicate folder issue


## Upcoming

- [ ] Polish and document final analyses
- [ ] Add Tableau/PowerBI visualization
- [ ] Add requirements.txt listing project dependencies (pandas, matplotlib, mysql-connector-python, python-dotenv)
- [ ] Join DRG codes to their descriptions (CMS DRG PDF) — both in queries and in readmission_analysis.ipynb's chart, which currently shows bare codes
- [ ] Rename 12_pmpm_analysis.sql's `three_years` CTE — misleading name, no additional year filtering happens there
- [ ] Reword "CLT" in the comments of 06, 10 and 10b to "minimum-count reliability filter (at least 10 readmissions and 10 non-readmissions; normal-approximation rule of thumb)" to match the README
- [ ] Name or replace the 14.67% all-cause benchmark source (Definitive Healthcare, 2025: commercial subset of ~4,100 of ~9,000 hospitals, sampling undisclosed)
- [ ] 13a: `inpatient_cte` skips the 2008–2010 claim-date filter that `full_years` applies; add the filter or a comment (does not change who is flagged)
- [ ] 12c: confirm "~34 members affected in 2010" is still the right member count (12d reports 42 claims / $486,000 for 2010)
- [ ] Dedicated planning session: map (not build) predictive layer — logistic regression vs. tree-based tradeoffs, admitting vs. principal diagnosis leakage question
- [ ] Verify how many DRGs drop below the minimum-count reliability filter (n×p≥10) under stricter (no single-day-gap) readmission definition
- [ ] Add PRIMARY KEY / indexes to 01_setup_table.sql, or note it wouldn't scale as-is
- [ ] Admitting vs. principal diagnosis comparison — % of claims where ADMTNG_ICD9_DGNS_CD differs from ICD9_DGNS_CD_1 (computed across all claims), joined to lookup table for readable names; report lookup match rate
- [ ] Zero-coverage distribution-comparison EDA — zero vs. non-zero coverage member-years across state, sex, age, other coverage fields; Jupyter notebook (primary write-up) + Tableau companion; goal: find the root cause of the ~$4.76M zero-coverage claims

## Known Data Limitations
- Synthetic data — patterns may not reflect real Medicare population
- Dates stored as YYYYMMDD strings, require STR_TO_DATE() conversion
- NCH_BENE_IP_DDCTBL_AMT: 3.26% blank, loaded as 0
- CLM_UTLZTN_DAY_CNT: 3.5% blank, loaded as 0
- BENE_HI_CVRAGE_TOT_MONS = 0 for 18,854 beneficiary_summary rows (5.49%); only 307 have a death date, root cause open (see 02b, 02c, 12d)