/*
This query computes the 95% confidence interval for the overall admission rate 
calculated in 08_overall_readmission_rate

n = 66,449
rate = 0.0967
se = square root of (p(1-p)/n)
95% confidence interval = 1.96 x se

Result: 9.67% (95% CI: 9.45% - 9.89%)
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
  WHERE STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') < (SELECT adj_max_discharge FROM censored_data_filter)
)

,CTE3 AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )

,CTE4 AS (
SELECT 
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS total_readmissions,
    COUNT(*) AS total_index_discharges,
    ROUND(SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) / COUNT(*), 4) AS overall_rate
	FROM CTE3)


SELECT
    overall_rate,
    ROUND(overall_rate - 1.96 * SQRT(overall_rate * (1 - overall_rate) / total_index_discharges), 4) AS ci_lower,
    ROUND(overall_rate + 1.96 * SQRT(overall_rate * (1 - overall_rate) / total_index_discharges), 4) AS ci_upper
FROM CTE4;