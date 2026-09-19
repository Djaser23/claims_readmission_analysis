/* 
This is a data quality check investigating the percentage of rows
where members report 0 months of coverage for Medicare Part A 
(BENE_HI_CVRAGE_TOT_MONS) and why these incidents occur.
It is separated into 2 main query sections: 1) the percentage, 2) the cause
Finding 1 - this impacts 5.49% of rows in the data
Finding 2 [CORRECTED] - originally reported as "entirely explained by member
deaths." That was wrong: BENE_DEATH_DT also stores empty strings ('') for living
members in addition to true NULLs, so the original `IS NOT NULL` check treated
even the empty string rows as non-null and passed everything through as "Died." Re-run with
an empty-string-aware check: of the 18,854 zero-coverage rows, only 307
(~1.6%) have a real death date. The remaining ~98% (18,547 rows) have no
death date at all -- root cause unresolved as of 2026-09-18. This bug also
affected 12b_true_pmpm.sql's filter design; see that file's KNOWN LIMITATION
note.
*/

-- Section 1: percentage of missingness

WITH CTE AS (
SELECT COUNT(*) AS total_members
FROM beneficiary_summary
)

, CTE2 AS (
SELECT COUNT(*) AS no_mem_months
FROM beneficiary_summary
WHERE BENE_HI_CVRAGE_TOT_MONS = 0
)

SELECT 
	no_mem_months, 
    total_members, 
    ROUND(no_mem_months/total_members * 100, 2) AS percent_no_mm
FROM CTE, CTE2;


-- Section 2: Why the missingness

SELECT
    CASE
        WHEN BENE_DEATH_DT IS NOT NULL AND BENE_DEATH_DT != '' THEN 'Died'
        ELSE 'No death date recorded' -- Original version used IS NOT NULL alone, which
                              -- missed empty-string rows and misclassified them as "Died"
    END AS death_status,
    COUNT(*) AS row_count
FROM beneficiary_summary
WHERE BENE_HI_CVRAGE_TOT_MONS = 0
GROUP BY death_status;