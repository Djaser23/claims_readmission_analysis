-- Row-level length of stay calculation, exploratory
-- Week 1 | CMS DE-SynPUF Inpatient Claims Sample 1

SELECT 
  DESYNPUF_ID,
  CLM_ID,
  CLM_ADMSN_DT,
  NCH_BENE_DSCHRG_DT,
  DATEDIFF(
    STR_TO_DATE(NCH_BENE_DSCHRG_DT, '%Y%m%d'),
    STR_TO_DATE(CLM_ADMSN_DT, '%Y%m%d')
  ) AS length_of_stay
FROM inpatient_claims
LIMIT 10;