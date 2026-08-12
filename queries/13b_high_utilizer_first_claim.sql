/*
This query calculates the highest service utilizers by count of claims per
year. It returns the top five percent of all members in that cohort with
only the initial diagnosis code per year per patient, anchored to their
first admission of the year.

METHOD NOTE: Previously used PERCENT_RANK() >= 0.95, which validated at
1.8-3.0% selected (2008-2010) instead of 5%, due to large tied blocks in
claims_per_year at the percentile boundary. Rewritten using ROW_NUMBER()
against an explicit per-year cutoff count (CEILING(total members * 0.05)),
matching the fix applied to 13a_high_utilizer_flagging.sql.

LIMITATION: Ties at the cutoff boundary are broken by DESYNPUF_ID for
reproducibility -- members tied with the cutoff person on claims_per_year
may be arbitrarily included or excluded depending on ID order. This is a
known, documented limitation, not a bug.
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
GROUP BY claim_year, DESYNPUF_ID)

-- third cte gets total distinct members per year, to compute the cutoff count
, total_members AS (
SELECT claim_year, COUNT(DISTINCT DESYNPUF_ID) AS total_members
FROM member_claims_per_yr
GROUP BY claim_year)

/*
fourth cte ranks members within each year by claims_per_year descending,
with DESYNPUF_ID as a deterministic tiebreaker, and carries the explicit
top-5% cutoff count for that year
*/
, ranked_members AS (
SELECT m.claim_year, m.DESYNPUF_ID, m.claims_per_year,
ROW_NUMBER() OVER (
  PARTITION BY m.claim_year
  ORDER BY m.claims_per_year DESC, m.DESYNPUF_ID ASC
) AS utilizer_rank,
t.total_members,
CEILING(t.total_members * 0.05) AS top_5pct_cutoff
FROM member_claims_per_yr m
JOIN total_members t ON t.claim_year = m.claim_year)

/*
fifth cte creates a table with diagnosis and procedure codes as well
as a claim order field by year, for joining with main query on patient id
and claim year and then filtering to claim order 1 (first admission of the year)
*/
, inpatient_cte AS (
SELECT LEFT(CLM_FROM_DT, 4) AS claim_year, DESYNPUF_ID, ICD9_DGNS_CD_1,
ICD9_PRCDR_CD_1,
ROW_NUMBER() OVER (
  PARTITION BY DESYNPUF_ID, LEFT(CLM_FROM_DT, 4)
  ORDER BY CLM_FROM_DT
) AS claim_order
FROM inpatient_claims)

/*
final query joins the top-5% members to their first admission's diagnosis
and procedure codes of the year. Results are limited to one row per
patient per year via claim_order = 1.
*/
SELECT rm.claim_year, rm.DESYNPUF_ID, rm.claims_per_year, rm.utilizer_rank,
ic.ICD9_DGNS_CD_1, ic.ICD9_PRCDR_CD_1
FROM ranked_members rm
JOIN inpatient_cte ic ON ic.claim_year = rm.claim_year AND
ic.DESYNPUF_ID = rm.DESYNPUF_ID
WHERE rm.utilizer_rank <= rm.top_5pct_cutoff AND
ic.claim_order = 1
ORDER BY rm.claim_year, rm.utilizer_rank;