/*
tableau_dashboard_exports.sql

Export queries for the Tableau dashboard. Each result is saved as a CSV in
data/tableau/. Both add SEGMENT = 1 explicitly; the blank-date filter in 02f
already excluded the 68 SEGMENT = 2 rows, so the results are unchanged.
*/

-- Export 1: pmpm_by_year.csv
-- Year-level PMPM, built as in 02f section 4 and 12b/12c.
WITH claims AS (
SELECT YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) AS yr,
       COUNT(*) AS n_claims,
       SUM(CLM_PMT_AMT) AS total_paid
FROM inpatient_claims
WHERE SEGMENT = 1
  AND STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01'
  AND STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01'
GROUP BY YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d'))
)
, members AS (
SELECT BENE_YEAR AS yr,
       SUM(BENE_HI_CVRAGE_TOT_MONS) AS member_months
FROM beneficiary_summary
GROUP BY BENE_YEAR
)
SELECT c.yr,
       c.n_claims,
       c.total_paid,
       m.member_months,
       ROUND(c.total_paid / m.member_months, 2) AS pmpm,
       ROUND(c.total_paid / c.n_claims, 0) AS avg_paid_per_claim,
       ROUND(1000 * c.n_claims / m.member_months, 1) AS claims_per_1000_member_months
FROM claims c
JOIN members m ON m.yr = c.yr
ORDER BY c.yr;

-- Export 2: claims_by_month.csv
-- Monthly claims, as in 02f section 2, with the SEGMENT = 1 filter.
SELECT LEFT(CLM_FROM_DT, 6) AS from_month,
       COUNT(*) AS n_claims,
       SUM(CLM_PMT_AMT) AS total_paid
FROM inpatient_claims
WHERE SEGMENT = 1
GROUP BY from_month
ORDER BY from_month;

-- Export 3: dx_readmission_counts.csv
-- 30-day readmissions by diagnosis code, principal and admitting bases.
-- Same readmission logic as 10b/10c (SEGMENT = 1 before LEAD(), censoring
-- cutoff). No reliability filter: Tableau ranks by readmission_count, and
-- counts don't have the small-n problem a rate does.
WITH censored_data_filter AS (
SELECT DATE_SUB(STR_TO_DATE(MAX(NCH_BENE_DSCHRG_DT), '%Y%m%d'), INTERVAL 30 DAY)
       AS adj_max_discharge
FROM inpatient_claims)

,CTE2 AS (
  SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
         ICD9_DGNS_CD_1, ADMTNG_ICD9_DGNS_CD,
         LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
  FROM inpatient_claims
  WHERE SEGMENT = 1
)
,CTE2_filtered AS (
  SELECT * FROM CTE2
  WHERE STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') < (SELECT adj_max_discharge FROM censored_data_filter)
)
,CTE3 AS (
SELECT ICD9_DGNS_CD_1, ADMTNG_ICD9_DGNS_CD,
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <= 30
  AND DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 1 ELSE 0 END AS is_readmission
FROM CTE2_filtered)

,by_code AS (
SELECT 'principal' AS dx_basis, ICD9_DGNS_CD_1 AS dx_code,
       SUM(is_readmission) AS readmission_count, COUNT(*) AS total_admissions
FROM CTE3
WHERE ICD9_DGNS_CD_1 <> ''
GROUP BY ICD9_DGNS_CD_1
UNION ALL
SELECT 'admitting', ADMTNG_ICD9_DGNS_CD,
       SUM(is_readmission), COUNT(*)
FROM CTE3
WHERE ADMTNG_ICD9_DGNS_CD <> ''
GROUP BY ADMTNG_ICD9_DGNS_CD
)
SELECT b.dx_basis, b.dx_code, i.diagnosis_description,
       b.readmission_count, b.total_admissions,
       ROUND(b.readmission_count / b.total_admissions, 4) AS readmission_rate
FROM by_code b
LEFT JOIN icd9_dx_lookup i ON b.dx_code = i.icd9_code
ORDER BY b.dx_basis, b.readmission_count DESC;