/*
30 Day Readmission Analysis
Includes single day intervals since discharge
This may capture planned transfers
*/
WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)

SELECT DESYNPUF_ID, NCH_BENE_DSCHRG_DT, next_admission, 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) 
AS days_since_discharge
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
ORDER BY days_since_discharge;

/*
Query 2 
Total readmission count including 1-day gaps
Total is 6,423
*/

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)
SELECT COUNT(*) AS readmission_count
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <= 30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0;

/* 
Query #3
30 Day Readmission Analysis
Excludes single day intervals since discharge
This may fail to capture actual single day readmissions 
in favor of avoiding inclusion of planned transfers 
*/ 

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)

SELECT DESYNPUF_ID, NCH_BENE_DSCHRG_DT, next_admission, 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) 
AS days_since_discharge
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 1
ORDER BY days_since_discharge;

/* 
Query #4
Quantifies total readmissions after excluding 1 day readmissions
Total is 6,131
The difference between the readmission count including single day 
and readmission count excluding single day readmission is 292
*/

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)
SELECT COUNT(*) AS readmission_count
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <= 30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 1;


