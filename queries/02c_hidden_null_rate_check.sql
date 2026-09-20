/*
Follow-up to 02b_beneficiary_coverage_quality_check.sql.

02b found that 18,547 of 18,854 zero-coverage rows (BENE_HI_CVRAGE_TOT_MONS = 0)
have a "hidden null" death date -- BENE_DEATH_DT stores an empty string ('')
rather than a true NULL for these rows, and only 307 (~1.6%) have a real
death date on file.

Open question after 02b: is that empty-string rate elevated specifically
within the zero-coverage group, or is it just background noise? This query
checks by comparing the empty-string rate in the zero-coverage group against
the empty-string rate across the entire beneficiary_summary table.

RESULT: The rates are effectively identical.
- Zero-coverage group: 18,547 / 18,854 = 98.37% empty string
- Full table:          338,183 / 343,644 = 98.41% empty string

CONCLUSION: The empty-string death date is not a distinguishing feature of
the zero-coverage group -- it's simply the default representation for any
living beneficiary, table-wide. This rules out death-date patterns as an
explanation for the zero-coverage rows and confirms the root cause of
BENE_HI_CVRAGE_TOT_MONS = 0 for non-decedents remains unresolved (see
02b and 12b_true_pmpm.sql's KNOWN LIMITATION note).
*/

-- Section 1: empty-string rate within the zero-coverage group

WITH zero_coverage_total AS (
SELECT COUNT(*) AS total_zero_coverage
FROM beneficiary_summary
WHERE BENE_HI_CVRAGE_TOT_MONS = 0
)

, zero_coverage_empty_death AS (
SELECT COUNT(*) AS empty_death_zero_coverage
FROM beneficiary_summary
WHERE BENE_HI_CVRAGE_TOT_MONS = 0
AND BENE_DEATH_DT = ''
)

SELECT
    empty_death_zero_coverage,
    total_zero_coverage,
    ROUND(empty_death_zero_coverage / total_zero_coverage * 100, 2) AS percent_empty_death_zero_coverage
FROM zero_coverage_empty_death, zero_coverage_total;


-- Section 2: empty-string rate across the full table (comparison baseline)

WITH full_table_total AS (
SELECT COUNT(*) AS total_rows
FROM beneficiary_summary
)

, full_table_empty_death AS (
SELECT COUNT(*) AS empty_death_total
FROM beneficiary_summary
WHERE BENE_DEATH_DT = ''
)

SELECT
    empty_death_total,
    total_rows,
    ROUND(empty_death_total / total_rows * 100, 2) AS percent_empty_death_full_table
FROM full_table_empty_death, full_table_total;