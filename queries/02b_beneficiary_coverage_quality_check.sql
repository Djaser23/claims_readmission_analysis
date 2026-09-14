-- This is a data quality check investigating the percentage of rows
-- where members report 0 months of coverage for Medicare Part A 
-- (BENE_HI_CVRAGE_TOT_MONS) and why these incidents occur.
-- It is separated into 2 main query sections: 1) the percentage, 2) the cause
-- Finding 1 - this impacts 5.49% of rows in the data
-- Finding 2 - the missingness is entirely explained by member deaths

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

SELECT no_mem_months, total_members, ROUND(no_mem_months/total_members * 100, 2) AS percent_no_mm
FROM CTE, CTE2;


-- Section 2: Why the missingness

SELECT
    CASE
        WHEN BENE_DEATH_DT IS NOT NULL THEN 'Died'
        ELSE 'Alive'
    END AS death_status,
    COUNT(*) AS row_count
FROM beneficiary_summary
WHERE BENE_HI_CVRAGE_TOT_MONS = 0
GROUP BY death_status;