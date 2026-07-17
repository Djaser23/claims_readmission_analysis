/*
Total Qualifying Readmission Rate

This query provides a total readmission rate while filtering out discharges within the last 30 days of the data
to avoid including rows where a 30 day readmission rate is impossible.
The reason for this filter it to ensure a more accurate readmission rate which
uses total admissions in its calculation.

*/


WITH censored_data_filter AS (
SELECT
DATE_SUB(STR_TO_DATE(MAX(NCH_BENE_DSCHRG_DT), '%Y%m%d'), INTERVAL 30 DAY) 
AS adj_max_discharge 
FROM inpatient_claims)


,CTE2 AS (
SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, CLM_DRG_CD,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims
WHERE NCH_BENE_DSCHRG_DT < (SELECT adj_max_discharge  
FROM censored_data_filter)
)


,CTE3 AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2 )


,CTE4 AS (
SELECT 
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS total_readmissions,
    COUNT(*) AS total_index_discharges,
    ROUND(SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) / COUNT(*), 4) AS overall_rate
	FROM CTE3)


SELECT *
FROM CTE4;


