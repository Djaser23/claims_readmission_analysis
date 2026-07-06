-- Average length of stay by DRG, defensive NULL handling
-- Week 1 | CMS DE-SynPUF Inpatient Claims Sample 1

SELECT CLM_DRG_CD, 
ROUND(AVG(DATEDIFF(STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d'), STR_TO_DATE(CLM_ADMSN_DT, '%Y%m%d'))),1) AS avg_los, 
COUNT(*) AS num_claims
FROM inpatient_claims
WHERE NCH_BENE_DSCHRG_DT <> '' AND NCH_BENE_DSCHRG_DT IS NOT NULL 
AND CLM_ADMSN_DT <> '' AND CLM_ADMSN_DT IS NOT NULL
GROUP BY CLM_DRG_CD
ORDER BY avg_los DESC;