/*
Adds diagnosis descriptions to the readmission-rate-by-principal-code
results from 10b_readmission_rate_by_icd9_principal.sql, joining
against icd9_dx_lookup (CMS v28) for readability.
LEFT JOIN used so codes without a v28 match still appear in output.

Updated 10/06/26: added SEGMENT = 1 inside CTE2, before LEAD() runs
(see 02d). Segment-2 rows no longer enter the admission sequence.
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
  WHERE SEGMENT = 1
 
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

, CTE4 AS (
SELECT 
	ICD9_DGNS_CD_1, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY ICD9_DGNS_CD_1
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
)
SELECT 
	C.ICD9_DGNS_CD_1, 
	i.diagnosis_description, 
	C.readmission_rate, 
	C.readmission_count,
	C.total_admissions
FROM CTE4 C
LEFT JOIN icd9_dx_lookup i ON
C.ICD9_DGNS_CD_1 = i.icd9_code
ORDER BY C.readmission_rate DESC;

