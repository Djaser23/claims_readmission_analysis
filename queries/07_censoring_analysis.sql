/*
Analysis quantifies the proportion of data being censored. This is important 
to determine the scale of the data limitation which turns out 
to be insignificant at 323 discharges - 0.48% of the total dataset.

Note: earlier calculation without STR_TO_DATE() returned 20.86% — incorrect 
result due to string arithmetic on date fields.

Updated 10/07/26: added SEGMENT = 1 (see 02d). Segment-2 rows no longer
counted. total_discharges 66,773 -> 66,705; censored 324 -> 323 (0.49% -> 0.48%).
Matches 08's post-fix denominator: 66,705 - 323 = 66,382.
*/

SELECT 
    COUNT(*) AS total_discharges,
    SUM(CASE WHEN STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') >= 
             DATE_SUB(STR_TO_DATE(max_date, '%Y%m%d'), INTERVAL 30 DAY) 
             THEN 1 ELSE 0 END) AS censored_discharges,
    ROUND(100.0 * SUM(CASE WHEN STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d') >= 
             DATE_SUB(STR_TO_DATE(max_date, '%Y%m%d'), INTERVAL 30 DAY) 
             THEN 1 ELSE 0 END) / COUNT(*), 2) AS pct_censored
FROM inpatient_claims
CROSS JOIN (SELECT MAX(NCH_BENE_DSCHRG_DT) AS max_date FROM inpatient_claims) AS m
WHERE SEGMENT = 1;

