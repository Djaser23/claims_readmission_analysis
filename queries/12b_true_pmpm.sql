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

NOTE: This is a true PMPM calculation. This query updates the first attempt at
this query in 12_pmpm_analysis.sql 
A standard PMPM divides total cost by member-months of enrollment across ALL eligible members:
PMPM = (total cost across all members) / (member-months of enrollment)
DE-SynPUF does contain additional tables with beneficiary months- Table: beneficiary_summary, 
column: BENE_HI_CVRAGE_TOT_MONS, therefore the member-months denominator is able to be constructed. 


KNOWN LIMITATION (found during validation, see 13_pmpm_validation.sql):
This query's LEFT JOIN + HAVING member_months > 0 filter silently excludes
members with BENE_HI_CVRAGE_TOT_MONS = 0 from BOTH the numerator and
denominator. Investigation found this zero-coverage population is NOT
primarily explained by death (only ~1.6% of zero-coverage rows have a
BENE_DEATH_DT), contradicting an earlier assumption. The cause of the
remaining ~98% zero-coverage rows is unresolved. This means an unknown
population of real inpatient claims (~$486K in 2010 alone) is currently
excluded from this PMPM calculation without documented justification.
Follow-up needed: investigate what drives BENE_HI_CVRAGE_TOT_MONS = 0
for non-decedents before treating this exclusion as final.
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


-- mem_month_cte creates member_months variable and filters out patients who died 
, mem_month_cte AS (
SELECT BENE_YEAR, DESYNPUF_ID, BENE_HI_CVRAGE_TOT_MONS AS member_months
FROM beneficiary_summary
HAVING member_months > 0
)


/*
final query calculates per member per month metric and quantifies
the number of members used per year in the calculations
*/
SELECT mm.BENE_YEAR, ROUND(SUM(COALESCE(y.yearly_member_claim, 0)) / SUM(mm.member_months) ,2) AS pmpm, 
COUNT(DISTINCT mm.DESYNPUF_ID) AS members_per_year
FROM mem_month_cte mm 
LEFT JOIN yearly_claim_per_mem y ON y.DESYNPUF_ID = mm.DESYNPUF_ID AND
y.claim_year = mm.BENE_YEAR
GROUP BY mm.BENE_YEAR
ORDER BY mm.BENE_YEAR DESC
