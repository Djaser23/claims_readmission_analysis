/*
30 Day Readmission Analysis
Includes single day intervals since discharge
This may capture planned transfers

Updated 10/05/26: added SEGMENT = 1 inside the CTE of all four queries
(see 02d). Totals: Query 2 6,423 -> 6,421; Query 4 6,131 -> 6,129.
The filter must sit inside the CTE, before LEAD() runs.


Note: 05 has no explicit censoring filter (unlike 06/08/10/11), but its
Query 2 total matches 08's corrected total exactly. 05's LEAD() runs over
each patient's full SEGMENT = 1 admission sequence with no censoring
filter, so it was never subject to the filter-before-LEAD() ordering bug
fixed 08/06/26 in 06/08/10/11. See data_quality_log.md for the bug fix
history.
*/


WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims
WHERE SEGMENT = 1
)

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
Total is 6,421
*/

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims
WHERE SEGMENT = 1)

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
FROM inpatient_claims
WHERE SEGMENT = 1)

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
Total is 6,129
The difference between the readmission count including single day 
and readmission count excluding single day readmission is 292
*/

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims
WHERE SEGMENT = 1)


SELECT COUNT(*) AS readmission_count
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <= 30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 1;


