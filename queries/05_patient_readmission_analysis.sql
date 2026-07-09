-- 30 Day Readmission Analysis
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