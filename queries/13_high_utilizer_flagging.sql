
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


SELECT LEFT(CLM_FROM_DT, 4) AS claim_year, ICD9_DGNS_CD_1, 
ic.ICD9_PRCDR_CD_1
FROM inpatient_claims 

-- SELECT ps.claim_year, ps.DESYNPUF_ID, ps.claims_per_year,
-- ps.percentile_claims_ranking,
-- ic.ICD9_DGNS_CD_1, ic.ICD9_PRCDR_CD_1
-- FROM percentile_rankings ps
-- JOIN inpatient_claims ic 
-- WHERE percentile_claims_ranking >= 0.95
-- ORDER BY claim_year, percentile_claims_ranking DESC
