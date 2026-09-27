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

This is a true PMPM calculation, updating the first attempt in 12_pmpm_analysis.sql.
A standard PMPM divides total cost by member-months of enrollment across ALL eligible members:
PMPM = (total cost across all members) / (member-months of enrollment)
DE-SynPUF contains beneficiary months in beneficiary_summary.BENE_HI_CVRAGE_TOT_MONS,
so the member-months denominator can be constructed directly.

BUG HISTORY (resolved Sep 27, 2026, see 12c_pmpm_validation.sql):
This query originally filtered out members with BENE_HI_CVRAGE_TOT_MONS = 0 via
HAVING member_months > 0, on the assumption that zero-coverage rows were all
explained by member death. That assumption came from a flawed death check (02b)
that treated empty-string BENE_DEATH_DT values as NULLs. Corrected, only 307 of
18,854 zero-coverage rows (~1.6%) actually had a death date — the filter had been
silently excluding ~$486K in real 2010 inpatient claims with no valid justification.
The filter has been removed; zero-coverage members are now included in both
numerator and denominator. All three years now reconcile exactly against 12c:
2008: 198.77 (was 196.95)
2009: 190.45 (was 188.96)
2010: 105.09 (was 104.71)
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

-- mem_month_cte creates member_months variable; all beneficiary_summary
-- rows are included, including zero-coverage members (see BUG HISTORY above)
, mem_month_cte AS (
SELECT BENE_YEAR, DESYNPUF_ID, BENE_HI_CVRAGE_TOT_MONS AS member_months
FROM beneficiary_summary
)

SELECT mm.BENE_YEAR, ROUND(SUM(COALESCE(y.yearly_member_claim, 0)) / SUM(mm.member_months) ,2) AS pmpm, 
COUNT(DISTINCT mm.DESYNPUF_ID) AS members_per_year
FROM mem_month_cte mm 
LEFT JOIN yearly_claim_per_mem y ON y.DESYNPUF_ID = mm.DESYNPUF_ID AND
y.claim_year = mm.BENE_YEAR
GROUP BY mm.BENE_YEAR
ORDER BY mm.BENE_YEAR DESC