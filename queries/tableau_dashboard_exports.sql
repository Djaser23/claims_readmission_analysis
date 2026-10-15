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