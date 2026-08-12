-- validates ranked_members/high_utilizers CTEs give exactly the cutoff count per year

WITH full_years AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_FROM_DT, CLM_THRU_DT, CLM_PMT_AMT,
LEFT(CLM_FROM_DT, 4) AS claim_year
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01' AND
STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01')

, member_claims_per_yr AS (
SELECT claim_year, DESYNPUF_ID, COUNT(CLM_ID) AS claims_per_year
FROM full_years
GROUP BY claim_year, DESYNPUF_ID)

, total_members AS (
SELECT claim_year, COUNT(DISTINCT DESYNPUF_ID) AS total_members
FROM member_claims_per_yr
GROUP BY claim_year)

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

SELECT claim_year,
       COUNT(DISTINCT DESYNPUF_ID) AS selected_members,
       MAX(total_members) AS total_members,
       MAX(top_5pct_cutoff) AS cutoff_count,
       ROUND(100.0 * COUNT(DISTINCT DESYNPUF_ID) / MAX(total_members), 2) AS pct_selected
FROM ranked_members
WHERE utilizer_rank <= top_5pct_cutoff
GROUP BY claim_year
ORDER BY claim_year;