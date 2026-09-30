
/*
Query of top relevant HRRP diagnoses with readmission rates and total admissions.
4 of the 6 HRRP conditions are included because ICD-9 diagnosis code mapping is possible.
Coronary Artery Bypass Graft (CABG) Surgery and 
Elective Primary Total Hip Arthroplasty and/or Total Knee Arthroplasty (THA/TKA)
have been excluded because they are identified by procedure codes, not diagnosis codes.

Rates are expressed as percentages. Censoring correction applied — discharges within 30 
days of the latest discharge date in the data are excluded.

2010 national benchmark rates for comparison (BMJ Open, 2024 — PMC11367292):
  Heart Failure: 24.8%
  Pneumonia:     16.4%
  COPD:          20.8%
  AMI:           15.6%

Comparison with the 2010 benchmarks is informal: for all four conditions the
95% CI (computed downstream in hrrp_condition_readmission_analysis.ipynb)
lies entirely below the published benchmark. No formal test was run, and
these are synthetic-data rates (see README for full discussion).

Uses ICD9_DGNS_CD_1 (principal discharge diagnosis), not ADMTNG_ICD9_DGNS_CD.
This field choice follows Suter et al. (2014, see References) for AMI, Heart
Failure, and Pneumonia; that study does not address COPD, so the same field is
applied to COPD by extension, without separate citation support.

The ICD-9 prefix mapping (one leading prefix per condition, used as a proxy)
is a simplification not validated against any official CMS code list.

Readmission_count added on 9/8/26 to support Wilson 95% CI computation
downstream (avoids reconstructing from the rounded readmission_rate —
see data_quality_log.md).
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



, CTE4 AS (
SELECT
ICD9_DGNS_CD_1, NCH_BENE_DSCHRG_DT, next_admission, readmission_class, 
CASE WHEN ICD9_DGNS_CD_1 LIKE '410%' THEN 'AMI' 
WHEN ICD9_DGNS_CD_1 LIKE '428%' THEN 'Heart Failure'
WHEN ICD9_DGNS_CD_1 LIKE '486%' THEN 'Pneumonia'
WHEN ICD9_DGNS_CD_1 LIKE '491%' 
  OR ICD9_DGNS_CD_1 LIKE '492%' 
  OR ICD9_DGNS_CD_1 LIKE '496%' THEN 'COPD'
ELSE NULL END AS mapped_HRRP_diagnosis
FROM CTE3)


SELECT
mapped_HRRP_diagnosis, 
ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END)* 100, 1) AS readmission_rate,
SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
COUNT(*) AS total_admissions
FROM CTE4
WHERE mapped_HRRP_diagnosis IS NOT NULL
GROUP BY mapped_HRRP_diagnosis
order by readmission_rate DESC, total_admissions DESC
