/*
30 Day Readmission Rate by DRG
Includes single day intervals since discharge
This may capture planned transfers.
This query filters out discharges within the last 30 days of the data
to avoid including rows where a 30 day readmission rate is impossible.
The reason for this filter it to ensure a more accurate readmission rate which
uses total admissions in its calculation.
Volume thresholds for rate accuracy have been accounted for by filtering out DRGs 
where the readmission count is less than ten or the non-readmission count 
(total admissions minus readmissions) is less than ten — a practice that 
reflects the use of the Central Limit Theorem in the context of rates.
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
Note: readmission_rate and total_admissions here are point estimates. 
95% confidence intervals (Wilson and Clopper-Pearson) are computed downstream 
in hrrp_condition_readmission_analysis.ipynb using readmission_count and 
total_admissions as inputs, prior to any DRG-level ranking or benchmarking.
These DRG grouped readmission rates are ready for scrutiny given the acknowledgement
that single day interval readmissions are included which may have been planned transfers.
A mapping of DRG to expected length of stay is appropriate to determine where 
inefficiencies may exist within the dataset.
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

,CTE3 AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 0
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )


SELECT 
	CLM_DRG_CD, 
	ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY CLM_DRG_CD
HAVING readmission_count >= 10 AND -- filters out statistically unreliable rates
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC




