/*
The purpose of this query is to compare the number of DRG's captured by the strict
30 readmission rate definition (excludes 1 day transfers) and the more lax version which 
allows them. 
Neither of these approaches completely align with CMS methodology which uses an algorithm 
utilizing diagnosis and procedure codes to determine planned readmissions.

Source: 
https://hscrc.maryland.gov/documents/HSCRC_Initiatives/readmissions/
Version-2-1-Readmission-Planned-CMS-Readmission-Algorithm-Report-03-14-2013.pdf
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
 
)
,CTE2_filtered AS (
  SELECT * FROM CTE2
  WHERE STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') < (SELECT adj_max_discharge 
  FROM censored_data_filter)
)

, CTE_LAX AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )

, CTE_STRICT AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 1 -- filter adjusted here
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )

, CTE_LAX2 AS (
SELECT 
	CLM_DRG_CD, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE_LAX
GROUP BY CLM_DRG_CD
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC
)

, CTE_STRICT2 AS (
SELECT 
    CLM_DRG_CD, 
    ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE_STRICT
GROUP BY CLM_DRG_CD
HAVING readmission_count >= 10 AND
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC
)


, TOTAL_LAX AS (
SELECT COUNT(DISTINCT CLM_DRG_CD) AS total_drgs_lax
FROM CTE_LAX2
)

, TOTAL_STRICT AS (
SELECT COUNT(DISTINCT CLM_DRG_CD) AS total_drgs_strict
FROM CTE_STRICT2
)

SELECT total_drgs_lax, total_drgs_strict
FROM TOTAL_LAX, TOTAL_STRICT;

/*
This query shows that excluding single-day gaps drops the reliable DRG set from 256 to 243 — 
a 13-DRG difference. This is not based on CMS's planned-readmission algorithm, which classifies 
planned readmissions using procedure and diagnosis codes rather than a time-gap cutoff
(See citation listed in comments at top of file). The 1-day exclusion here is a simplified assumption that 
very short gaps are more likely to represent transfers than true readmissions, 
and the 13-DRG impact is the practical cost of that assumption on this filtered analysis.
*/
