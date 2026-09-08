/*
ICD-9 Condition Mapping
Maps principal discharge diagnosis codes (ICD9_DGNS_CD_1) to HRRP condition categories:
AMI, Heart Failure, Pneumonia, COPD
This mapping uses a single leading ICD-9 prefix per condition (e.g., 428% for
Heart Failure) as a simplified proxy for demonstration purposes. This
simplification has not been validated against any official CMS specification
of condition-defining diagnosis codes. 
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