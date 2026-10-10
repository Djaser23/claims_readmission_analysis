/*
30 Day Readmission Rate by DRG
Excludes single-day intervals since discharge (strict definition)

This version excludes readmissions that occur one day or less after discharge,
because a portion of these are likely transfers between facilities rather than
true readmissions. The 1-day cutoff is a simplifying assumption, not CMS's
planned-readmission methodology (see 06c).

It also excludes discharges within the last 30 days of the data (censoring
correction), since a 30-day readmission can't be observed for them; including
them would understate the rate.

Low-volume DRGs are excluded: a DRG is kept only if it has at least 10 readmissions
and at least 10 non-readmissions (a minimum-count reliability filter;
normal-approximation rule of thumb). This reduces, but does not eliminate,
instability in small-group rates.

Note: readmission_rate and total_admissions here are point estimates. 
95% confidence intervals (Wilson) are computed downstream in 
readmission_analysis.ipynb using readmission_count and total_admissions as inputs, 
prior to any DRG-level ranking or benchmarking.

Updated 10/09/26: added SEGMENT = 1 inside CTE2, before LEAD() runs
(see 02d). Segment-2 rows no longer enter the admission sequence.
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
  WHERE SEGMENT = 1
 
)
,CTE2_filtered AS (
  SELECT * FROM CTE2
  WHERE STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') < (SELECT adj_max_discharge 
  FROM censored_data_filter) 
)

-- This version adds stricter definition of 30 day readmission rate
-- excludes readmissions one day or less after discharge (a portion are likely transfers)
,CTE3 AS (
SELECT 
CLM_DRG_CD, NCH_BENE_DSCHRG_DT, next_admission, 
CASE WHEN DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) <=30 
AND 
DATEDIFF(STR_TO_DATE(next_admission, '%Y%m%d'), STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d')) > 1 -- filter adjusted here
THEN 'thirty_day_readmission' ELSE 'non_readmission' END AS readmission_class 
FROM CTE2_filtered )


SELECT 
    CLM_DRG_CD, 
    ROUND(AVG(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1.0 ELSE 0 END),3) AS readmission_rate,
    SUM(CASE WHEN readmission_class = 'thirty_day_readmission' THEN 1 ELSE 0 END) AS readmission_count,
    COUNT(*) AS total_admissions
FROM CTE3
GROUP BY CLM_DRG_CD
HAVING readmission_count >= 10 AND
total_admissions - readmission_count >= 10
ORDER BY readmission_rate DESC;



