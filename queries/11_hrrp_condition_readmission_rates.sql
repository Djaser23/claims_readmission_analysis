
/*
Query of top relevant HRRP diagnoses with readmission rates and total admissions.
4 of the 6 HRRP conditions are included because ICD-9 diagnosis code mapping is possible.
Coronary Artery Bypass Graft (CABG) Surgery and 
Elective Primary Total Hip Arthroplasty and/or Total Knee Arthroplasty (THA/TKA)
have been excluded because they are identified by procedure codes, not diagnosis codes.

Rates are expressed as percentages. Censoring correction applied — discharges within 
30 days of the observation window end (2010-12-31) are excluded.

2010 national benchmark rates for comparison (BMJ Open, 2024 — PMC11367292):
  Heart Failure: 24.8%
  COPD:          20.8%
  Pneumonia:     16.4%
  AMI:           15.6%

All four observed rates are substantially lower than national benchmarks, 
consistent with DE-SynPUF synthetic data producing dampened readmission patterns.
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

-- SELECT *
-- FROM CTE3

, CTE4 AS (
SELECT
ADMTNG_ICD9_DGNS_CD, NCH_BENE_DSCHRG_DT, next_admission, readmission_class, 
CASE WHEN ADMTNG_ICD9_DGNS_CD LIKE '410%' THEN 'AMI' 
WHEN ADMTNG_ICD9_DGNS_CD LIKE '428%' THEN 'Heart Failure'
WHEN ADMTNG_ICD9_DGNS_CD LIKE '486%' THEN 'Pneumonia'
WHEN ADMTNG_ICD9_DGNS_CD LIKE '491%' 
  OR ADMTNG_ICD9_DGNS_CD LIKE '492%' 
  OR ADMTNG_ICD9_DGNS_CD LIKE '496%' THEN 'COPD'
ELSE NULL END AS mapped_HRRP_diagnosis
FROM CTE3)

-- SELECT * 
-- FROM CTE4

SELECT
mapped_HRRP_diagnosis, 
ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END)* 100, 1) AS readmission_rate,
COUNT(*) AS total_admissions
FROM CTE4
WHERE mapped_HRRP_diagnosis IS NOT NULL
GROUP BY mapped_HRRP_diagnosis
order by readmission_rate DESC, total_admissions DESC
