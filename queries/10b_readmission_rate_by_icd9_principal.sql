/*
Query of readmission rates by primary diagnosis code 'ICD9_DGNS_CD_1'
Ordered by readmission rate descending.
This version contrasts the predictive framing of the admitting diagnosis 
code on 10_readmission_rate_by_icd9.sql in favor of a more standard approach 
to the rate using principal diagnosis code. Both approaches have analytical 
value and so both are explored.
*/


WITH censored_data_filter AS (
SELECT
DATE_SUB(STR_TO_DATE(MAX(NCH_BENE_DSCHRG_DT), '%Y%m%d'), INTERVAL 30 DAY) 
AS adj_max_discharge 
FROM inpatient_claims)


,CTE2 AS (
  SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, ICD9_DGNS_CD_1,
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
ICD9_DGNS_CD_1, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )


SELECT 
	ICD9_DGNS_CD_1, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY ICD9_DGNS_CD_1
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC