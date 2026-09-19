/*
Independent validation of 12b_true_pmpm.sql's PMPM calculation.

Uses a structurally different query path than 12b: no per-member CTE,
YEAR(STR_TO_DATE(...)) instead of LEFT(CLM_FROM_DT, 4), and a direct
year-level join between beneficiary_summary and inpatient_claims totals.

Purpose: confirm 12b's claims-side aggregation and date filtering are
correct by reconstructing the same totals through an independent path.

RESULT: This query's totals do NOT match 12b_true_pmpm.sql exactly.
2010: this query = 105.09 pmpm, 12b = 104.71 pmpm.
Traced the gap to 12b's LEFT JOIN + HAVING member_months > 0, which
silently drops ~$486K in inpatient claims (2010 alone) when a
member's BENE_HI_CVRAGE_TOT_MONS = 0 -- because their mem_month_cte
row is filtered out before the join, so their claims never find a
match (~34 members affected in 2010). This query does NOT apply that
same filter, so those claims are included here but excluded in 12b.

That filter was originally written on the assumption that zero-coverage
rows were explained by member death (see 02b, Finding 2). That assumption
was WRONG, caused by a hidden bug in the original death check (BENE_DEATH_DT
IS NOT NULL alone missed that the field stores empty strings for rows with
no recorded death date). Corrected check: of 18,854 zero-coverage rows,
only 307 (~1.6%) have a real death date; the remaining ~98% are
unexplained as of 2026-09-18. See 12b_true_pmpm.sql's own KNOWN LIMITATION
note for the full explanation and open follow-up.
*/

WITH MM AS (
SELECT BENE_YEAR, SUM(BENE_HI_CVRAGE_TOT_MONS) AS member_months_per_year
FROM beneficiary_summary
GROUP BY BENE_YEAR)

, PT AS (
SELECT 
	YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) AS claim_year, 
	SUM(CLM_PMT_AMT) AS payments_total_per_year
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01'
	AND STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01'  
GROUP BY YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d'))    
    )
    
SELECT 
	MM.BENE_YEAR AS benefit_year, 
    payments_total_per_year,
    member_months_per_year,
    payments_total_per_year / member_months_per_year AS pmpm_per_year,
    ROUND(payments_total_per_year / member_months_per_year, 2) AS rounded_pmpm
FROM MM
JOIN PT ON MM.BENE_YEAR = PT.claim_year