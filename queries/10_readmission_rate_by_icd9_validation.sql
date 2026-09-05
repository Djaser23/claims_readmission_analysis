/*
Validates the 09/04/26 fix to 10_readmission_rate_by_icd9.sql: compares the old 
(buggy) rounded-rate reconstruction against the new (correct) raw-count filter 
side by side. Returns rows only where the two disagree — i.e. diagnosis codes 
whose reliability-threshold inclusion/exclusion changed due to rounding error.
Final SELECT statement specifies the prior and new filtering logic, computes whether
each row passes each filter, then uses HAVING passed_old_filter <> passed_new_filter
to return only the rows where the two disagree.
Results indicate that the original filter produced 7 false negatives, resulting in the 
30-day readmission list being under-represented. These diagnoses sit right on the boundary 
of statistical significance, with a readmission_count of exactly 10. For these 7 diagnosis 
codes specifically, rounding happened to move the rate downward, causing it to fall just 
under the threshold and evade capture.
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
    COUNT(*) AS total_admissions,
    CASE WHEN 
        ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) * COUNT(*) >= 10
        AND COUNT(*) * (1 - ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3)) >= 10
    THEN 1 ELSE 0 END AS passed_old_filter,
    CASE WHEN 
        SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) >= 10
        AND COUNT(*) - SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) >= 10
    THEN 1 ELSE 0 END AS passed_new_filter
FROM CTE3
GROUP BY ADMTNG_ICD9_DGNS_CD
HAVING passed_old_filter <> passed_new_filter
ORDER BY readmission_rate DESC;