/*
30 Day Readmission Analysis
Includes single day intervals since discharge
This may capture planned transfers


Verified 08/14/26: totals below (6,423 / 6,131) confirmed live against 
current queries -- not stale copy-paste from 08_overall_readmission_rate.sql.

Note: 05 has no explicit censoring filter (unlike 06/08/10/11), but its
Query 2 total matches 08's corrected total exactly. This isn't coincidence:
05's LEAD() always ran over the full unfiltered admission sequence, so it
was never subject to the filter-before-LEAD() ordering bug fixed 08/06/26
in 06/08/10/11. 05's naive approach and 08's corrected censoring filter
independently arrive at the same count. See data_quality_log.md for the
bug fix history.
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


