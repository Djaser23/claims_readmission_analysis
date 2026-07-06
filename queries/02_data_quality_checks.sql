-- Checks for data quality issues
USE claims_practice;

SELECT 
  SUM(CASE WHEN DESYNPUF_ID = '' OR DESYNPUF_ID IS NULL THEN 1 ELSE 0 END) AS missing_patient_id,
  SUM(CASE WHEN CLM_ID = '' OR CLM_ID IS NULL THEN 1 ELSE 0 END) AS missing_claim_id,
  SUM(CASE WHEN CLM_ADMSN_DT = '' OR CLM_ADMSN_DT IS NULL THEN 1 ELSE 0 END) AS missing_admsn_dt,
  SUM(CASE WHEN NCH_BENE_DSCHRG_DT = '' OR NCH_BENE_DSCHRG_DT IS NULL THEN 1 ELSE 0 END) AS missing_dschrg_dt,
  SUM(CASE WHEN CLM_DRG_CD = '' OR CLM_DRG_CD IS NULL THEN 1 ELSE 0 END) AS missing_drg,
  SUM(CASE WHEN CLM_PMT_AMT IS NULL THEN 1 ELSE 0 END) AS missing_pmt_amt
FROM inpatient_claims;

-- Deductible field: check how many rows show 0 (forced from blank on load)
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN NCH_BENE_IP_DDCTBL_AMT = 0 THEN 1 ELSE 0 END) AS zero_ddctbl_rows,
       SUM(CASE WHEN NCH_BENE_IP_DDCTBL_AMT = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_zero_ddctbl
FROM inpatient_claims;

-- Utilization day count: same check
SELECT COUNT(*) AS total_rows,
       SUM(CASE WHEN CLM_UTLZTN_DAY_CNT = 0 THEN 1 ELSE 0 END) AS zero_utlztn_rows,
       SUM(CASE WHEN CLM_UTLZTN_DAY_CNT = 0 THEN 1 ELSE 0 END) / COUNT(*) * 100 AS pct_zero_utlztn
FROM inpatient_claims;

SHOW WARNINGS LIMIT 50;