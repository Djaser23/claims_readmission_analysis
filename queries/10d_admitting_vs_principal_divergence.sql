/*
This series of queries checks where admitting and principal diagnosis codes diverge
in the inpatient claims table. This is important in the context of trying to predict
which patients are at high risk of readmission. 
CMS Methodology uses principal diagnosis code in calculating 30 day readmission rates
in its Hospital Readmission Reduction Program (HRRP).
Admitting Diagnosis code is known earlier in the patient hostitalization process and therefore
knowing how often those diagnosis codes align offers insight into the degree that potential 
30 day readmissions may be able to be reduced using admitting diagnosis codes and whether a more 
complicated model is clearly warrented. 

The first query checks for data quality issues within the two diagnosis code variables.
The second checks the percentage match without filtering out the observed ghost nulls.
The third query calculates the match percentage after filtering out the observed ghost nulls.
The final query validates the expected change in row count after removing the ghost nulls.
*/


WITH CTE_1 AS (
SELECT 
SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD IS NULL THEN 1 ELSE 0 END) AS ADMTNG_NULL,
SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = '' THEN 1 ELSE 0 END) AS ADMTING_GHOST_NULL,
SUM(CASE WHEN ICD9_DGNS_CD_1 IS NULL THEN 1 ELSE 0 END) AS PRINCIPAL_NULL,
SUM(CASE WHEN ICD9_DGNS_CD_1 = '' THEN 1 ELSE 0 END) AS PRINCIPAL_GHOST_NULL,
COUNT(*) AS TOTAL_ROWS
FROM inpatient_claims
)

SELECT *,
ROUND(ADMTING_GHOST_NULL / TOTAL_ROWS * 100, 2) AS Pct_Admitting_Ghost_Nulls,
ROUND(PRINCIPAL_GHOST_NULL / TOTAL_ROWS * 100, 2) AS Pct_Principal_Ghost_Nulls
FROM CTE_1;

-- Query #2 percent of matching codes without ghost null filtering
SELECT
    SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) AS match_count,
    COUNT(*) AS total_count,
    ROUND(SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pct_match
FROM inpatient_claims;

# Query 3 - match percentage after removing ghost nulls from the calculation
SELECT
    SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) AS match_count,
    COUNT(*) AS total_count,
    ROUND(SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pct_match
FROM inpatient_claims
WHERE ADMTNG_ICD9_DGNS_CD != '' AND ICD9_DGNS_CD_1 != '';

/*
Final query checks for instances where both diagnosis codes have
ghost nulls to ensure the correct number of expected total rows after 
the filter has been applied.
Note: 599 + 95 ≠ 625 (the actual row count excluded in Query 3) because
69 rows have both fields blank simultaneously and would otherwise be
double-counted. Confirmed via a direct COUNT(*) WHERE both = ''.
*/

SELECT COUNT(*) AS both_blank
FROM inpatient_claims
WHERE ADMTNG_ICD9_DGNS_CD = '' AND ICD9_DGNS_CD_1 = '';

/*
Result: ~79% of claims show a different admitting vs. principal diagnosis
code (20.67% match on all rows, 20.76% match after excluding ghost nulls —
the near-identical result confirms this isn't a data-quality artifact).
This suggests admitting diagnosis alone would be a poor substitute for
principal diagnosis in a 30-day readmission model; further work would be
needed to assess whether that gap matters clinically (see Roadmap) before
drawing conclusions about model complexity.
*/
