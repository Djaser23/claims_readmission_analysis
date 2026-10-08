-- Query ranks patients 'DESYNPUF_ID' by admission count

-- Updated 10/07/26: added SEGMENT = 1 (see 02d). Segment-2 rows share their
-- parent's CLM_ID and no longer add to admission counts. Total 66,773 -> 66,705.

SELECT DESYNPUF_ID, COUNT(CLM_ID) AS admission_count,
DENSE_RANK() OVER (ORDER BY COUNT(CLM_ID) DESC) AS admin_rank
FROM inpatient_claims
WHERE SEGMENT = 1
GROUP BY DESYNPUF_ID
ORDER BY admission_count DESC;

