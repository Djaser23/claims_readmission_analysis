/*
ICD-9 Condition Mapping
Maps admitting diagnosis codes to HRRP condition categories:
AMI, Heart Failure, Pneumonia, COPD
Based on CMS HRRP condition definitions.
Starting point for condition-level readmission rate analysis.
Source: https://www.cms.gov/medicare/quality/value-based-programs/hospital-readmissions
*/

SELECT ADMTNG_ICD9_DGNS_CD,
CASE WHEN ADMTNG_ICD9_DGNS_CD LIKE '410%' THEN 'AMI' 
WHEN ADMTNG_ICD9_DGNS_CD LIKE '428%' THEN 'Heart Failure'
WHEN ADMTNG_ICD9_DGNS_CD LIKE '486%' THEN 'Pneumonia'
WHEN ADMTNG_ICD9_DGNS_CD LIKE '491%' 
  OR ADMTNG_ICD9_DGNS_CD LIKE '492%' 
  OR ADMTNG_ICD9_DGNS_CD LIKE '496%' THEN 'COPD'
ELSE NULL END 
FROM inpatient_claims LIMIT 50;