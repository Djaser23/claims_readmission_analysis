/*
Query of readmission rates by diagnosis code
Ordered by readmission rate desceding
*/


WITH censored_data_filter AS (
SELECT
DATE_SUB(STR_TO_DATE(MAX(NCH_BENE_DSCHRG_DT), '%Y%m%d'), INTERVAL 30 DAY) 
AS adj_max_discharge 
FROM inpatient_claims)


,CTE2 AS (
SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, ADMTNG_ICD9_DGNS_CD,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims
WHERE NCH_BENE_DSCHRG_DT < (SELECT adj_max_discharge  
FROM censored_data_filter)
)


,CTE3 AS (
SELECT 
ADMTNG_ICD9_DGNS_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2 )


SELECT 
	ADMTNG_ICD9_DGNS_CD, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY ADMTNG_ICD9_DGNS_CD
HAVING readmission_rate * total_admissions >=10 AND -- filters out statistically unreliable rates
total_admissions * (1 - readmission_rate) >= 10 
ORDER BY readmission_rate DESC