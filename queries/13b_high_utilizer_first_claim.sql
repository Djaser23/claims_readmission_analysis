
/*
This query is designed to calculate the highest service utilizers
by count of claims per year. It returns the top five percent of all members 
in that cohort with only the initial diagnosis code per year per patient, 
anchored to their first admission of the year.
*/

-- first cte filters out the partial year data from 2007
WITH full_years AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_FROM_DT, CLM_THRU_DT, CLM_PMT_AMT, 
LEFT(CLM_FROM_DT, 4) AS claim_year
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01' AND
STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01')

-- second cte calculates the per member claim count per year
, member_claims_per_yr AS (
SELECT claim_year, DESYNPUF_ID, COUNT(CLM_ID) AS claims_per_year 
FROM full_years
GROUP BY claim_year, DESYNPUF_ID 
ORDER BY claim_year DESC, claims_per_year DESC)

/*
third cte uses a window function to percentile rank the members in terms
of claim count
*/
, percentile_rankings AS (
SELECT claim_year, DESYNPUF_ID, claims_per_year,
PERCENT_RANK() OVER (PARTITION BY claim_year ORDER BY claims_per_year) 
AS percentile_claims_ranking
FROM member_claims_per_yr)

/*
fourth cte creates a table with diagnosis and procedure codes as well
as a claim order field by year for the purpose of joining
with main query on patient id (DESYNPUF_ID) and claim year and then filtering by 
claim order 1
*/

, inpatient_cte AS (
SELECT LEFT(CLM_FROM_DT, 4) AS claim_year, DESYNPUF_ID, ICD9_DGNS_CD_1, 
ICD9_PRCDR_CD_1, ROW_NUMBER() OVER (PARTITION BY DESYNPUF_ID, LEFT(CLM_FROM_DT, 4) ORDER BY CLM_FROM_DT) AS claim_order
FROM inpatient_claims 
)

/*
final query utilizes a join to view the diagnosis and procedure codes of 
the highest 5% of utilizers as measured by claims per year. This version
uses an additional WHERE clause to limit the claims to the first CLM_FROM_DT
of the year per patient. Results are therefore limited to one per patient per year. 
*/

-- , prior AS (
SELECT ps.claim_year, ps.DESYNPUF_ID, ps.claims_per_year,
ps.percentile_claims_ranking,
ic.ICD9_DGNS_CD_1, ic.ICD9_PRCDR_CD_1
FROM percentile_rankings ps
JOIN inpatient_cte ic ON ic.claim_year = ps.claim_year AND
ic.DESYNPUF_ID = ps.DESYNPUF_ID
WHERE percentile_claims_ranking >= 0.95 AND
ic.claim_order = 1
ORDER BY claim_year, percentile_claims_ranking DESC
-- )

/* 
The following query checks to verify that the final query - labeled prior as
a commented out cte produces an accurate result. The expectation is
that the count per year and the distinct count per year is the same which it is

SELECT COUNT(DESYNPUF_ID), COUNT(DISTINCT DESYNPUF_ID) 
FROM prior
GROUP BY claim_year
*/


