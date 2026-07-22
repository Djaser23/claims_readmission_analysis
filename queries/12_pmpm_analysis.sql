/*
The goal of the query is to quantify the average monthly cost per member. 
This allows for year-over-year comparison of inpatient cost trends within 
this population sample.

Before running the query I did a check on the date range to ensure we had
3 complete years of data. See explanation below...

Date range check — run before PMPM calculation:
SELECT 
    MIN(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) AS earliest_claim,
    MAX(STR_TO_DATE(CLM_THRU_DT, '%Y%m%d')) AS latest_claim
FROM inpatient_claims;

Result: 2007-11-27 to 2010-12-31
Decision: Filter to 2008-2010 only — 2007 contains only ~5 weeks of claims
and cannot be treated as a full year for PMPM calculation.
*/


-- first cte filters out the partial year data from 2007
WITH full_years AS (
SELECT DESYNPUF_ID, CLM_FROM_DT, CLM_THRU_DT, CLM_PMT_AMT 
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01' AND
STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01'
)

-- second cte creates a claim year column to group by in next cte
,three_years AS (
SELECT DESYNPUF_ID, CLM_FROM_DT, CLM_THRU_DT, CLM_PMT_AMT, 
LEFT(CLM_FROM_DT, 4) AS claim_year
FROM full_years)

-- third cte sums the member claim amount by year
, yearly_claim_per_mem AS (
SELECT claim_year, DESYNPUF_ID, SUM(CLM_PMT_AMT) AS yearly_member_claim
FROM  three_years
GROUP BY claim_year, DESYNPUF_ID)

/*
final query calculates per member per month metric and quantifies
the number of members used per year in the calculations
*/
SELECT claim_year, ROUND(AVG(yearly_member_claim) / 12 ,2) AS pmpm, 
COUNT(DISTINCT DESYNPUF_ID) AS members_per_year
FROM  yearly_claim_per_mem
GROUP BY claim_year
ORDER BY claim_year DESC


