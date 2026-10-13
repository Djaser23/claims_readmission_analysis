/*
02e_segment_payment_check.sql
Date: 2026-10-12

QUESTION
Follow-up to 02d. The 68 SEGMENT = 2 rows in inpatient_claims were filtered out
of the readmission queries. Do the cost files (12, 12b, 12c, 12d) need the same
filter? That depends on whether segment-2 payments duplicate the parent claim's
payment or are additional money.

RESULTS
Query 1: segment 1 = 66,705 rows, $637,982,480 paid.
         segment 2 = 68 rows, $1,277,700 paid (66 rows with a payment), ~0.2% of total.
Query 2: all 68 segment-2 rows matched a SEGMENT = 1 parent (no orphans).
         Segment-2 total $1,277,700 vs. parent total $1,212,000.
         10 rows have the same payment as the parent, but one of those is 0 = 0,
         so 9 are identical nonzero payments ($121,000, ~0.02% of total).
         63 rows are paid on both sides; 3 are paid on segment 2 where the parent is $0.
Query 3: row-level listing, sorted with identical-payment rows first. The other 58
         rows differ in both directions with no consistent pattern.

DECISION
Treated as additional payments, not duplicates. 12, 12b, 12c, 12d left unchanged.
Limitation: the 9 identical nonzero rows could be duplicates. 
Nearly all amounts are whole multiples of $1,000 (one exception: $700),
so chance matches are plausible. Even if all 9 were duplicates, 
the impact is about 0.02% of total payments.
Not investigated: one row has a segment-2 payment of $700 vs. $7,000 on the parent.
*/

-- Query 1: row counts and payment totals by segment 
SELECT SEGMENT,
       COUNT(*) AS n_rows,
       SUM(CLM_PMT_AMT) AS total_paid,
       SUM(CLM_PMT_AMT > 0) AS rows_with_payment
FROM inpatient_claims
GROUP BY SEGMENT;

-- Query 2: compare each segment-2 row to its segment-1 parent (summary) 
SELECT COUNT(*) AS seg2_rows,
       SUM(s2.CLM_PMT_AMT = s1.CLM_PMT_AMT) AS same_payment_as_parent,  -- includes 0 = 0 matches 
       SUM(s2.CLM_PMT_AMT > 0 AND s1.CLM_PMT_AMT > 0) AS both_paid,
       SUM(s2.CLM_PMT_AMT) AS seg2_paid,
       SUM(s1.CLM_PMT_AMT) AS parent_paid
FROM inpatient_claims s2
JOIN inpatient_claims s1 ON s1.CLM_ID = s2.CLM_ID AND s1.SEGMENT = 1
WHERE s2.SEGMENT = 2;

-- Query 3: same comparison, row level (identical-payment rows sort first) 
SELECT s2.CLM_ID,
       s1.CLM_PMT_AMT AS parent_pmt,
       s2.CLM_PMT_AMT AS seg2_pmt
FROM inpatient_claims s2
JOIN inpatient_claims s1 ON s1.CLM_ID = s2.CLM_ID AND s1.SEGMENT = 1
WHERE s2.SEGMENT = 2
ORDER BY (s2.CLM_PMT_AMT = s1.CLM_PMT_AMT) DESC, s2.CLM_PMT_AMT DESC;