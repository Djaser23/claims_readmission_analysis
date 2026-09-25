/*
ICD-9 lookup match rate validation
Checks how many claim rows find a description in icd9_dx_lookup
(CMS v28, loaded by scripts/load_icd9_dx_lookup.py).
--
Results (row level):
  Admitting (ADMTNG_ICD9_DGNS_CD): 65,483 / 66,773 = 98.07%
  Principal (ICD9_DGNS_CD_1):      66,456 / 66,773 = 99.53%
--
Both high enough to use the lookup via LEFT JOIN. 
Admitting codes match less often; not yet investigated.
--
TODO: distinct-code match rates; breakdown of unmatched codes
(junk values vs. codes retired before v28).
*/


# Find total number of ICD9 Admitting Diagnosis codes in the inpatient_claims table
# that map to Descriptions in icd9_dx_lookup table
WITH total_icd_cte AS (
SELECT COUNT(ADMTNG_ICD9_DGNS_CD) AS total_icd9_in_inp_clms
FROM inpatient_claims
)

, mapped_cte AS (
SELECT COUNT(*) AS mapped_admitting_codes
FROM inpatient_claims ic
LEFT JOIN icd9_dx_lookup i
ON i.icd9_code = ic.ADMTNG_ICD9_DGNS_CD
WHERE i.icd9_code IS NOT NULL
)

SELECT
total_icd9_in_inp_clms,
mapped_admitting_codes,
ROUND((mapped_admitting_codes / total_icd9_in_inp_clms) * 100, 2) AS percent_admitting_mapped
FROM total_icd_cte, mapped_cte;



# Find total number of ICD9 Principal Diagnosis codes in the inpatient_claims table
# that map to Descriptions in icd9_dx_lookup table

WITH total_icd_cte2 AS (
SELECT COUNT(ICD9_DGNS_CD_1) AS total_p_icd9_inp_clms
FROM inpatient_claims
)

, mapped_cte2 AS (
SELECT COUNT(*) AS mapped_principal_codes
FROM inpatient_claims ic
LEFT JOIN icd9_dx_lookup i
ON i.icd9_code = ic.ICD9_DGNS_CD_1
WHERE i.icd9_code IS NOT NULL
)

SELECT
total_p_icd9_inp_clms,
mapped_principal_codes,
ROUND((mapped_principal_codes / total_p_icd9_inp_clms) * 100, 2) AS percent_principal_mapped
FROM total_icd_cte2, mapped_cte2;


