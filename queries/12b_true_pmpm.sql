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


KNOWN LIMITATION (found during validation, see 12c_pmpm_validation.sql):
This query's LEFT JOIN + HAVING member_months > 0 filter silently excludes
members with BENE_HI_CVRAGE_TOT_MONS = 0 from BOTH the numerator and
denominator. This filter was originally written on the assertion that
zero-coverage rows were explained by member death - this was due to a
100% incidence of NOT NULL BENE_DEATH_DT having 0 BENE_HI_CVRAGE_TOT_MONS
That assumption was wrong. 02b's original death check used BENE_DEATH_DT
IS NOT NULL alone, which missed that the field stores empty strings ('')
for rows with no recorded death date, not true NULLs, and so counted every
zero-coverage row as "Died." Corrected check (IS NOT NULL AND != ''): of
18,854 zero-coverage rows, only 307 (~1.6%) have a real death date; the
remaining 18,547 (~98%) have no death date recorded at all, and their
cause is unresolved as of 2026-09-18. This means an unknown population of
real inpatient claims (~$486K in 2010 alone) is currently excluded from
this PMPM calculation without documented justification.
Follow-up needed: investigate what drives BENE_HI_CVRAGE_TOT_MONS = 0
for the ~98% with no death date, before treating this exclusion as final.
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
mem_month_cte creates member_months variable and filters out rows with
0 coverage months (originally believed to be deaths only -- see KNOWN
LIMITATION above, this is not accurate)
*/
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
