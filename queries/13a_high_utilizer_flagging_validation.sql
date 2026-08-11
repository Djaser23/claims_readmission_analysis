
-- This query is designed to validate the yearly percentile results of `13a_high_utilizer_flagging`.sql

/*
KNOWN ISSUE: PERCENT_RANK() >= 0.95 does not reliably select exactly the 
top 5% of members. Validated against actual population size (see 
13a_high_utilizer_flagging_validation.sql): selected 2.98% (2008), 
1.81% (2009), 2.01% (2010) — likely due to large tied blocks in 
claims_per_year at the percentile boundary. Needs a ROW_NUMBER() + 
explicit-cutoff-count rewrite for an accurate top-5% selection. 
Output below should not be cited as "top 5%" until fixed.
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
fourth cte creates a table with diagnosis and procedure codes to join
with main query on patient id (DESYNPUF_ID) and claim year
*/
, inpatient_cte AS (
SELECT LEFT(CLM_FROM_DT, 4) AS claim_year, DESYNPUF_ID, ICD9_DGNS_CD_1, 
ICD9_PRCDR_CD_1
FROM inpatient_claims )

/*
final query utilizes a join to view the diagnosis and procedure codes of 
the highest 5% of utilizers as measured by claims per year
*/


, high_utilizers AS (
SELECT ps.claim_year, ps.DESYNPUF_ID, ps.claims_per_year,
ps.percentile_claims_ranking,
ic.ICD9_DGNS_CD_1, ic.ICD9_PRCDR_CD_1
FROM percentile_rankings ps
JOIN inpatient_cte ic ON ic.claim_year = ps.claim_year AND
ic.DESYNPUF_ID = ps.DESYNPUF_ID
WHERE percentile_claims_ranking >= 0.95
ORDER BY claim_year, percentile_claims_ranking DESC
)

, total_members AS (
  SELECT claim_year, COUNT(DISTINCT DESYNPUF_ID) AS total_members
  FROM member_claims_per_yr
  GROUP BY claim_year
)

SELECT h.claim_year, 
       COUNT(DISTINCT h.DESYNPUF_ID) AS selected_members,
       t.total_members,
       ROUND(100.0 * COUNT(DISTINCT h.DESYNPUF_ID) / t.total_members, 2) AS pct_selected
FROM high_utilizers h
JOIN total_members t ON t.claim_year = h.claim_year
GROUP BY h.claim_year, t.total_members
ORDER BY h.claim_year;
