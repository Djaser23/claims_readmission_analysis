-- Query ranks patients 'DESYNPUF_ID' by admission count

SELECT DESYNPUF_ID, COUNT(CLM_ID) AS admission_count,
DENSE_RANK() OVER (ORDER BY COUNT(CLM_ID) DESC) AS admin_rank
FROM inpatient_claims
GROUP BY DESYNPUF_ID
ORDER BY admission_count DESC;

