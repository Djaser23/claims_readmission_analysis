/*
30 Day Readmission Rate by DRG
Includes single day intervals since discharge
This may capture planned transfers
*/


WITH CTE AS (
SELECT DESYNPUF_ID, CLM_ADMSN_DT, NCH_BENE_DSCHRG_DT, CLM_DRG_CD,
LEAD(CLM_ADMSN_DT) OVER (PARTITION BY DESYNPUF_ID ORDER BY CLM_ADMSN_DT) AS next_admission
FROM inpatient_claims)

,CTE2 AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE )


SELECT 
	CLM_DRG_CD, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),2) AS readmission_rate,
    COUNT(*) AS total_admissions
FROM CTE2
GROUP BY CLM_DRG_CD
HAVING readmission_rate * total_admissions >=10 AND
total_admissions * (1 - readmission_rate) >= 10
ORDER BY readmission_rate DESC

/*
Next up:
address data censoring with max date
write the limitation
consider low volume threshold for total admissions = updated query with HAVING condition 
to display only statistically significant readmission rates with CLT formula 
review drg readmission rates given these limitations
*/
