/*
02f_claim_volume_by_period_check.sql

Checks whether inpatient claim volume is stable across the file. Prompted by
the drop in true PMPM from 2008 to 2010 (12b_true_pmpm.sql: 198.77 in 2008,
190.45 in 2009, 105.09 in 2010).

QUESTION
A PMPM is (total paid) / (member-months). If it falls, either the numerator
fell (fewer claims, or smaller payments), or the denominator rose (more
enrolled member-months). Which one is it?

HOW THE SECTIONS FIT TOGETHER
  1. Claims by year       numerator side, same filters as 12b/12c
  2. Claims by month      shape of the decline, no date filter
  3. Members by year      denominator side (beneficiary_summary)
  4. PMPM reconciliation  rebuilds the 12b/12c PMPM from sections 1 and 3
  5. Row accounting       where the rows excluded by the date filter went

YEAR DEFINITION
Years are assigned by CLM_FROM_DT, with claims limited to 2008-01-01 through
2010-12-31, exactly as in 12b and 12c. Claims are not filtered on SEGMENT,
matching the cost files (see 02d, 02e).

RESULTS (sections 1, 2, 3 and 5, run 10/13/26)
  Claims by year (section 1):
    2008: 27,678 claims, $257,732,880 paid, avg $9,312 per claim
    2009: 25,231 claims, $244,810,270 paid, avg $9,703 per claim
    2010: 13,572 claims, $132,669,330 paid, avg $9,775 per claim
  Member-months (section 3):
    2008: 1,296,626   2009: 1,285,433   2010: 1,262,399
  From 2009 to 2010, claims and total paid each fall about 46%; member-months
  fall about 2%; payment per claim is flat. Dividing the section 1 totals by
  the section 3 member-months gives 198.77, 190.45 and 105.09, matching 12b
  and 12c. The PMPM decline is a claim-volume effect, not a payment-size
  effect or an enrollment effect.
  Monthly claims (section 2, by CLM_FROM_DT): 2 in Nov 2007 and 222 in Dec
  2007; 1,535 in Jan 2008, rising to a peak of 2,587 in May 2008; about
  2,300-2,600 a month through 2008; 2,330 in Jan 2009 falling to 1,893 in
  Dec 2009; 1,785 in Jan 2010 falling to 257 in Dec 2010 (about 10% of the
  May 2008 peak). There is no step at the January 2010 boundary.
  Row accounting (section 5): 66,773 rows = 68 blank-date rows (all
  SEGMENT = 2) + 224 rows in 2007 + 66,481 rows in 2008-2010.
  Claims per 1,000 member-months (section 4): 21.3 (2008), 19.6 (2009),
  10.8 (2010). The section 4 PMPM reproduces 198.77 / 190.45 / 105.09,
  matching 12b and 12c.

INTERPRETATION
Claim volume is thin at both ends of the file while enrollment and payment
per claim are roughly flat. That pattern is more consistent with how the
synthetic file was constructed than with a real change in utilization or
cost. Treat that as an interpretation: no formal test was run, and the
mechanism has not been established or checked against CMS documentation.
The PMPM series should not be presented as a cost trend.

WHAT THIS DOES NOT ESTABLISH
  - Why claim volume tapers (not investigated; synthetic-data construction
    is a hypothesis, not a finding).
  - Whether other claim types (e.g. outpatient) show the same pattern.
  - Whether the readmission rate is affected. A missing follow-up admission
    would look like a non-readmission; untested.

BLANK-DATE ROWS
The 68 SEGMENT = 2 rows have a blank CLM_FROM_DT. STR_TO_DATE of a blank
returns NULL, so those rows cannot pass the date filter and were never in
the 12b/12c totals. Their payments ($1,277,700, see 02e) would add at most
about $1 PMPM to a single year, and no 12b/12c figure changes.
*/


-- ---------------------------------------------------------------------
-- Section 1: claims and payments by year (numerator side)
-- Same date filter and year logic as 12b/12c. total_paid should equal
-- 12c's payments_total_per_year for each year; if it does not, the filters
-- have drifted apart.
-- Read: if n_claims and total_paid both fall while avg_paid_per_claim holds
-- steady, the change is in how many claims there are, not what they pay.
-- ---------------------------------------------------------------------
SELECT LEFT(CLM_FROM_DT, 4) AS claim_year,
       COUNT(*) AS n_rows,
       COUNT(DISTINCT CLM_ID) AS n_claims,
       COUNT(DISTINCT DESYNPUF_ID) AS n_patients_with_claims,
       SUM(CLM_PMT_AMT) AS total_paid,
       ROUND(SUM(CLM_PMT_AMT) / COUNT(*), 0) AS avg_paid_per_row,
       ROUND(100 * SUM(CLM_PMT_AMT > 0) / COUNT(*), 1) AS pct_rows_with_payment
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01'
  AND STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01'
GROUP BY claim_year
ORDER BY claim_year;


-- ---------------------------------------------------------------------
-- Section 2: claims and payments by month (shape of the decline)
-- Deliberately NOT date-filtered, so both ends of the file are visible.
-- The first row, with an empty from_month, is the 68 blank-date rows.
-- Read: a smooth ramp-up and taper suggests a property of the file; a
-- sudden step at one month would suggest a cutoff or a processing change.
-- ---------------------------------------------------------------------
SELECT LEFT(CLM_FROM_DT, 6) AS from_month,
       COUNT(*) AS n_rows,
       SUM(CLM_PMT_AMT) AS total_paid
FROM inpatient_claims
GROUP BY from_month
ORDER BY from_month;


-- ---------------------------------------------------------------------
-- Section 3: members and member-months by year (denominator side)
-- One row per member per year in beneficiary_summary. The zero-coverage
-- rows are included, as in 12b (see 12d).
-- Read: roughly flat member_months means the denominator is not driving
-- the PMPM change.
-- ---------------------------------------------------------------------
SELECT BENE_YEAR,
       COUNT(*) AS n_rows,
       COUNT(DISTINCT DESYNPUF_ID) AS n_members,
       SUM(BENE_HI_CVRAGE_TOT_MONS) AS member_months,
       ROUND(AVG(BENE_HI_CVRAGE_TOT_MONS), 2) AS avg_months_per_member,
       SUM(BENE_HI_CVRAGE_TOT_MONS = 0) AS zero_coverage_rows
FROM beneficiary_summary
GROUP BY BENE_YEAR
ORDER BY BENE_YEAR;


-- ---------------------------------------------------------------------
-- Section 4: PMPM reconciliation (numerator and denominator together)
-- Rebuilds the 12b/12c PMPM from the section 1 and 3 totals. pmpm should
-- match 12c's rounded_pmpm for each year. claims_per_1000_member_months
-- puts claim volume on a per-member basis, so the decline is visible
-- without reference to enrollment size.
-- ---------------------------------------------------------------------
WITH claims AS (
SELECT YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) AS yr,
       COUNT(*) AS n_claims,
       SUM(CLM_PMT_AMT) AS total_paid
FROM inpatient_claims
WHERE STR_TO_DATE(CLM_FROM_DT, '%Y%m%d') >= '2008-01-01'
  AND STR_TO_DATE(CLM_THRU_DT, '%Y%m%d') < '2011-01-01'
GROUP BY YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d'))
)

, members AS (
SELECT BENE_YEAR AS yr,
       SUM(BENE_HI_CVRAGE_TOT_MONS) AS member_months
FROM beneficiary_summary
GROUP BY BENE_YEAR
)

SELECT c.yr,
       c.n_claims,
       c.total_paid,
       m.member_months,
       ROUND(c.total_paid / m.member_months, 2) AS pmpm,
       ROUND(c.total_paid / c.n_claims, 0) AS avg_paid_per_claim,
       ROUND(1000 * c.n_claims / m.member_months, 1) AS claims_per_1000_member_months
FROM claims c
JOIN members m ON m.yr = c.yr
ORDER BY c.yr;


-- ---------------------------------------------------------------------
-- Section 5: row accounting by SEGMENT and blank date
-- Shows where rows excluded by the section 1 date filter went.
-- Expected: SEGMENT 1 = 66,705 rows, none blank; SEGMENT 2 = 68 rows, all
-- blank, $1,277,700 (matches 02e).
-- ---------------------------------------------------------------------
SELECT SEGMENT,
       COUNT(*) AS n_rows,
       SUM(CLM_FROM_DT = '' OR CLM_FROM_DT IS NULL) AS blank_from_dt,
       SUM(CLM_PMT_AMT) AS total_paid
FROM inpatient_claims
GROUP BY SEGMENT;