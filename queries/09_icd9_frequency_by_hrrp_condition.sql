/*
ICD-9 Condition Mapping
Maps admitting diagnosis codes to HRRP condition categories:
AMI, Heart Failure, Pneumonia, COPD
Based on CMS HRRP condition definitions.
Starting point for condition-level readmission rate analysis.
Source: https://www.cms.gov/medicare/quality/value-based-programs/hospital-readmissions
*/

SELECT ICD9_DGNS_CD_1,
CASE WHEN ICD9_DGNS_CD_1 LIKE '410%' THEN 'AMI' 
WHEN ICD9_DGNS_CD_1 LIKE '428%' THEN 'Heart Failure'
WHEN ICD9_DGNS_CD_1 LIKE '486%' THEN 'Pneumonia'
WHEN ICD9_DGNS_CD_1 LIKE '491%' 
  OR ICD9_DGNS_CD_1 LIKE '492%' 
  OR ICD9_DGNS_CD_1 LIKE '496%' THEN 'COPD'
ELSE NULL END 
FROM inpatient_claims LIMIT 50;