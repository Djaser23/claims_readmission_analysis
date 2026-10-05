/*
PURPOSE: Test whether one row in inpatient_claims equals one admission.
Every readmission query (05, 06, 08, 10, 11) uses LEAD() over each patient's
rows ordered by CLM_ADMSN_DT, so any row that is not a distinct admission can
distort the next-admission gap or inflate the denominator.

SUMMARY OF FINDINGS:
- 66,773 rows but 66,705 distinct CLM_IDs: 68 extra rows.
- Those 68 are SEGMENT = 2 rows. Every one belongs to a claim that also has a
  SEGMENT = 1 row, and all 68 share their parent's discharge date,
  so they are the same stay as the parent, not new admissions.
- Their admit dates are populated but usually earlier than the parent's, and
  their DRG is a placeholder ('OTH' or '000') rather than a real DRG.
  Meaning of 'OTH' / '000': not yet checked against the codebook.
  Reason for the earlier admit dates: unknown (date perturbation is a guess,
  not verified).
- 160 (patient, admit date) pairs have more than one row. At most 7 of these
  come from the segment-2 rows; the rest involve different CLM_IDs, so they
  are distinct claims, not duplicate rows of one claim. Cause not yet
  explained. Lower priority than the segment-2 rows. Possible next step:
  profile them by discharge date and DRG.

WHY IT MATTERS: LEAD() assumes one row per admission. 68 segment-2 rows
(continuation lines of existing claims) break that assumption. Impact on
the 9.67% rate not yet measured; likely small (68 rows is ~0.1% of the
table). Fix: filter to SEGMENT = 1 and rerun 08.

Separately, 160 pairs share a patient and admit date but are distinct
claims (different CLM_IDs), not duplicates of one claim. Some may be
legitimate same-day admissions; others may be billing artifacts or
transfers. Cause not yet investigated. Lower priority than the segment-2
rows, which are confirmed non-admissions. Whether any should be excluded
from the readmission calculation is an open question. CMS's actual HRRP
methodology resolves cases like this with information this project doesn't
have (see 06c).

FIX (not yet applied): add WHERE SEGMENT = 1 to the first CTE in 05, 06, 08,
10, 11, then rerun 08 and compare to the current 9.67%.
*/


-- Query 1: total rows vs. distinct claim IDs.
-- If these differ, some CLM_IDs appear on more than one row.
-- Result: 66,773 rows vs. 66,705 distinct claims (68 extra rows).
SELECT COUNT(*) AS total_rows,
       COUNT(DISTINCT CLM_ID) AS distinct_claims
FROM inpatient_claims;


-- Query 2: how many (patient, admit date) combinations appear on more than one row?
-- Matching CLM_IDs don't prove one row = one admission. Two different claims can
-- describe the same stay. Duplicate patient + admit date pairs create ties in
-- the LEAD() ordering and can produce a zero-day gap.
-- (The trailing "d" is the alias MySQL requires for a subquery in FROM.)
-- Result: 160 pairs.
SELECT COUNT(*) AS dup_patient_admit_pairs
FROM (
  SELECT DESYNPUF_ID, CLM_ADMSN_DT
  FROM inpatient_claims
  GROUP BY DESYNPUF_ID, CLM_ADMSN_DT
  HAVING COUNT(*) > 1
) d;


-- Query 3: distribution of SEGMENT (CMS codebook label: "Claim Line Segment").
-- Result: SEGMENT 1 = 66,705 rows (matches distinct CLM_ID count); SEGMENT 2 = 68 rows.
SELECT SEGMENT, COUNT(*) AS n
FROM inpatient_claims
GROUP BY SEGMENT
ORDER BY SEGMENT;


-- Query 4: orphan check. Does any SEGMENT = 2 row lack a SEGMENT = 1 row
-- under the same CLM_ID?
-- Result: 0 orphans, so every segment-2 row is a continuation of an existing claim.
SELECT COUNT(*) AS orphan_seg2
FROM inpatient_claims s2
WHERE s2.SEGMENT = 2
  AND NOT EXISTS (SELECT 1 FROM inpatient_claims s1
                  WHERE s1.CLM_ID = s2.CLM_ID AND s1.SEGMENT = 1);


-- Query 5: how closely do segment-2 rows match their segment-1 parent?
-- Counts matches on patient + admit date, discharge date, and DRG.
-- Result (of 68): same patient + admit date = 7; same discharge date = 68;
-- same DRG = 1. Same stay (discharge dates match), but admit date and DRG
-- mostly differ, so segment-2 rows are not copies of the parent.
SELECT COUNT(*) AS seg2_total,
       SUM(s1.DESYNPUF_ID = s2.DESYNPUF_ID
           AND s1.CLM_ADMSN_DT = s2.CLM_ADMSN_DT) AS same_patient_admit,
       SUM(s1.NCH_BENE_DSCHRG_DT = s2.NCH_BENE_DSCHRG_DT) AS same_discharge,
       SUM(s1.CLM_DRG_CD = s2.CLM_DRG_CD) AS same_drg
FROM inpatient_claims s2
JOIN inpatient_claims s1
  ON s1.CLM_ID = s2.CLM_ID AND s1.SEGMENT = 1
WHERE s2.SEGMENT = 2;


-- Query 6: eyeball 10 parent/continuation pairs side by side.
-- Result: segment-2 admit dates are populated and usually earlier than the
-- parent's; discharge dates match; segment-2 DRG is 'OTH' or '000'.
-- LIMIT 10 is a sample, not a full audit. No ORDER BY, so rows are arbitrary.
SELECT s1.CLM_ID,
       s1.CLM_ADMSN_DT AS adm_1, s2.CLM_ADMSN_DT AS adm_2,
       s1.NCH_BENE_DSCHRG_DT AS dschrg_1, s2.NCH_BENE_DSCHRG_DT AS dschrg_2,
       s1.CLM_DRG_CD AS drg_1, s2.CLM_DRG_CD AS drg_2
FROM inpatient_claims s2
JOIN inpatient_claims s1 ON s1.CLM_ID = s2.CLM_ID AND s1.SEGMENT = 1
WHERE s2.SEGMENT = 2
LIMIT 10;