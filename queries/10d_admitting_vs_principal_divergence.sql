/*
10d_admitting_vs_principal_divergence.sql

PURPOSE
Measure how often the admitting diagnosis (ADMTNG_ICD9_DGNS_CD, known at intake)
and the principal diagnosis (ICD9_DGNS_CD_1, confirmed at discharge) are the same
ICD-9 code on the same claim. CMS's Hospital Readmissions Reduction Program (HRRP)
uses the principal diagnosis. If the two codes usually agree, the admitting
diagnosis could stand in for it in an early readmission-risk model; if they often
differ, it could not do so directly.

QUERIES
1. Data quality: counts of NULL and blank ('') values in each field (blanks are
   called "ghost nulls" in the column aliases).
2. Match rate on all rows, including rows where a field is blank.
3. Match rate excluding rows where either field is blank.
4. Count of rows where both fields are blank (reconciles Queries 2 and 3).

Updated 10/12/26: all queries restricted to SEGMENT = 1 so the unit is one row per
claim (see 02d). The 68 SEGMENT = 2 continuation rows are excluded.
*/


-- Query 1: NULL and blank counts in each diagnosis field
WITH CTE_1 AS (
SELECT 
SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD IS NULL THEN 1 ELSE 0 END) AS ADMTNG_NULL,
SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = '' THEN 1 ELSE 0 END) AS ADMTNG_GHOST_NULL,
SUM(CASE WHEN ICD9_DGNS_CD_1 IS NULL THEN 1 ELSE 0 END) AS PRINCIPAL_NULL,
SUM(CASE WHEN ICD9_DGNS_CD_1 = '' THEN 1 ELSE 0 END) AS PRINCIPAL_GHOST_NULL,
COUNT(*) AS TOTAL_ROWS
FROM inpatient_claims
WHERE SEGMENT = 1
)

SELECT *,
ROUND(ADMTNG_GHOST_NULL / TOTAL_ROWS * 100, 2) AS Pct_Admitting_Ghost_Nulls,
ROUND(PRINCIPAL_GHOST_NULL / TOTAL_ROWS * 100, 2) AS Pct_Principal_Ghost_Nulls
FROM CTE_1;

-- Query 2: percent of matching codes without ghost null filtering
SELECT
    SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) AS match_count,
    COUNT(*) AS total_count,
    ROUND(SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pct_match
FROM inpatient_claims
WHERE SEGMENT = 1;

-- Query 3: match percentage after removing ghost nulls from the calculation
SELECT
    SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) AS match_count,
    COUNT(*) AS total_count,
    ROUND(SUM(CASE WHEN ADMTNG_ICD9_DGNS_CD = ICD9_DGNS_CD_1 THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS pct_match
FROM inpatient_claims
WHERE SEGMENT = 1 AND ADMTNG_ICD9_DGNS_CD != '' AND ICD9_DGNS_CD_1 != '';

-- Query 4: rows where both fields are blank (checks the row count removed in Query 3)
SELECT COUNT(*) AS both_blank
FROM inpatient_claims
WHERE SEGMENT = 1 AND ADMTNG_ICD9_DGNS_CD = '' AND ICD9_DGNS_CD_1 = '';

/*
RESULTS (rerun 10/12/26, SEGMENT = 1, 66,705 rows)
Query 1: 66,705 rows; no NULLs in either field. Blank ('') values: 531 admitting
(0.80%), 27 principal (0.04%).
Query 2: 13,736 of 66,705 claims have identical admitting and principal codes
(20.59%), counting blank = blank as a match.
Query 3: 13,735 of 66,148 (20.76%) after excluding rows where either field is
blank (557 rows excluded).
Query 4: 1 row has both fields blank. That is the 1-match difference between
Queries 2 and 3.

Effect of the SEGMENT = 1 fix: before it, Query 2 was 13,804 / 66,773 (20.67%).
68 of the 69 both-blank rows were SEGMENT = 2 rows, so the fix removed 68
blank-equals-blank matches. Query 3 is unchanged because its blank filter had
already excluded those rows.

INTERPRETATION
About 79% of claims with both codes populated have different admitting and
principal ICD-9 codes. This is exact-code agreement: a pair such as 4280 and
42821 counts as a mismatch, so the figure does not mean 79% differ in clinical
condition. Blank values do not drive the result: excluding them moves the match
rate by about 0.2 percentage points (20.59% vs. 20.76%). Whether the admitting
diagnosis could substitute for the principal diagnosis in a readmission model
would need a comparison at the 3-digit category level, which was not done here.
*/

