/*
Query of readmission rates by admitting diagnosis code 'ADMTNG_ICD9_DGNS_CD'
Ordered by readmission rate descending
Admitting diagnosis code has been chosen here as opposed to primary diagnosis code - 'ICD9_DGNS_CD_1'
due to its clinical accessibility early in the patient onboarding process. This early accessibility
may offer predictive insights especially when combined with comorbidities and other variables such as
the primary diagnosis code.
Note: An earlier version of this query contained a filtering error in the HAVING clause -
namely
'HAVING readmission_rate * total_admissions >=10 AND -- filters out statistically unreliable rates
total_admissions * (1 - readmission_rate) >= 10'
The original query excluded 7 diagnosis codes that are included in the corrected version, due to a 
false-negative error in the reliability filter. The fix expands the set of admitting diagnosis codes 
included in the 30-day readmission results.
This was due to the fact that the readmission_rate utilized rounding in its construction. The lesson here
is that any variable feeding into a HAVING or WHERE clause should be in raw count form, not a rounded 
or derived rate, in order to preserve sufficient statistical accuracy.
For a more detailed account of the difference in results of these queries see '10_readmission_rate_by_icd9_validation.sql'
*/

use claims_practice;

WITH censored_data_filter AS (
SELECT
DATE_SUB(STR_TO_DATE(MAX(NCH_BENE_DSCHRG_DT), '%Y%m%d'), INTERVAL 30 DAY) 
AS adj_max_discharge 
FROM inpatient_claims)


,CTE2 AS (
  SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, ADMTNG_ICD9_DGNS_CD,
  LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
  FROM inpatient_claims
 
)
,CTE2_filtered AS (
  SELECT * FROM CTE2
  WHERE STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') < (SELECT adj_max_discharge 
  FROM censored_data_filter)
)

,CTE3 AS (
SELECT 
ADMTNG_ICD9_DGNS_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )


SELECT 
	ADMTNG_ICD9_DGNS_CD, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY ADMTNG_ICD9_DGNS_CD
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC