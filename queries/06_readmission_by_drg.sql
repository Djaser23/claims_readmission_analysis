/*
30 Day Readmission Rate by DRG
Includes single day intervals since discharge
This may capture planned transfers
*/
WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, CLM_DRG_CD,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)

SELECT * 
FROM CTE

SELECT DESYNPUF_ID, NCH_BENE_DSCHRG_DT, next_admission, CLM_DRG_CD,
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) 
AS days_since_discharge
FROM CTE
WHERE
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
ORDER BY days_since_discharge

# new attempt

WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, CLM_DRG_CD,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)

SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE;

