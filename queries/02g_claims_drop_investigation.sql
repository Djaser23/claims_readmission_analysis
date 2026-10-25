/*
02g_claims_drop_investigation.sql

Investigates the ~50% drop in inpatient claims between 2008 and 2010.
Hypothesis: synthetic data artifact in DE-SynPUF, not a real utilization trend.

Approach:
  - Compare beneficiary counts and coverage months by year to rule out
    population shrinkage as the cause.
  - Check whether zero-coverage members are concentrated in 2010, which
    could inflate earlier years' claims relative to 2010.

Findings:
  - Total members declined only ~3% (116,352 → 112,754) while claims
    fell ~50%, ruling out population shrinkage.
  - Zero-coverage members are not concentrated in 2010 (2008: 5,294;
    2009: 7,241; 2010: 6,319), ruling out a coverage-pattern shift.
  - Conclusion: the drop is in the claims data itself, not explained by
    membership shrinkage or coverage patterns. CMS documentation confirms
    this is a known limitation: "Claim counts for 2010 are lower due to
    attrition from death, and some effects of disclosure treatment."
    Source: https://www.cms.gov/Research-Statistics-Data-and-Systems/
    Downloadable-Public-Use-Files/SynPUFs/DE_Syn_PUF
*/

-- Section 1: Beneficiary count and coverage months by year
SELECT BENE_YEAR,
       COUNT(DISTINCT DESYNPUF_ID)      AS n_members,
       SUM(BENE_HI_CVRAGE_TOT_MONS)    AS total_member_months
FROM beneficiary_summary
GROUP BY BENE_YEAR
ORDER BY BENE_YEAR;

-- Section 2: Zero-coverage members by year
SELECT BENE_YEAR,
       SUM(CASE WHEN BENE_HI_CVRAGE_TOT_MONS = 0 THEN 1 ELSE 0 END) AS zero_coverage_members
FROM beneficiary_summary
GROUP BY BENE_YEAR
ORDER BY BENE_YEAR;
