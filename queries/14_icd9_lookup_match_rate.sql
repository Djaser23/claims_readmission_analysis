/*
14_icd9_lookup_match_rate.sql

ICD-9 lookup match rate validation
Checks how many claim rows find a description in icd9_dx_lookup
(CMS v28, loaded by scripts/load_icd9_dx_lookup.py).

Updated 10/13/26: both queries restricted to SEGMENT = 1 so the unit is one
row per claim (see 02d). The 68 SEGMENT = 2 continuation rows have blank
admitting and principal codes (see 10d), so they were counted as unmatched.

RESULTS (row level, SEGMENT = 1, 66,705 claims):
Admitting (ADMTNG_ICD9_DGNS_CD): 65,483 / 66,705 = 98.17%
Principal (ICD9_DGNS_CD_1):      66,456 / 66,705 = 99.63%

Both are high enough to use the lookup via LEFT JOIN.
Admitting codes match less often; not yet investigated. Blank ('') codes
(see 10d) are in the denominator and are not expected to match, so they
account for part of the gap.

TODO: distinct-code match rates; breakdown of unmatched codes
(junk values vs. codes retired before v28).
*/


-- Query 1: admitting diagnosis codes that map to a description in icd9_dx_lookup
WITH total_icd_cte AS (
SELECT COUNT(ADMTNG_ICD9_DGNS_CD) AS total_icd9_in_inp_clms
FROM inpatient_claims
WHERE SEGMENT = 1
)

, mapped_cte AS (
SELECT COUNT(*) AS mapped_admitting_codes
FROM inpatient_claims ic
LEFT JOIN icd9_dx_lookup i
ON i.icd9_code = ic.ADMTNG_ICD9_DGNS_CD
WHERE ic.SEGMENT = 1 AND i.icd9_code IS NOT NULL
)

SELECT
total_icd9_in_inp_clms,
mapped_admitting_codes,
ROUND((mapped_admitting_codes / total_icd9_in_inp_clms) * 100, 2) AS percent_admitting_mapped
FROM total_icd_cte, mapped_cte;


-- Query 2: principal diagnosis codes that map to a description in icd9_dx_lookup
WITH total_icd_cte2 AS (
SELECT COUNT(ICD9_DGNS_CD_1) AS total_p_icd9_inp_clms
FROM inpatient_claims
WHERE SEGMENT = 1
)

, mapped_cte2 AS (
SELECT COUNT(*) AS mapped_principal_codes
FROM inpatient_claims ic
LEFT JOIN icd9_dx_lookup i
ON i.icd9_code = ic.ICD9_DGNS_CD_1
WHERE ic.SEGMENT = 1 AND i.icd9_code IS NOT NULL
)

SELECT
total_p_icd9_inp_clms,
mapped_principal_codes,
ROUND((mapped_principal_codes / total_p_icd9_inp_clms) * 100, 2) AS percent_principal_mapped
FROM total_icd_cte2, mapped_cte2;