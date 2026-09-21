/*
PURPOSE: Test whether members with BENE_HI_CVRAGE_TOT_MONS = 0 (zero months of 
Part A coverage) in a given year nonetheless have paid inpatient claims in that 
same year. A paid claim against zero coverage months is a direct contradiction --
either these members were misclassified as uncovered, or something else is off 
in how coverage and claims are being reconciled.
--
FIELD VERIFICATION: Before treating this as a real finding, confirmed both fields
against the official CMS DE-SynPUF codebook (not just secondary sources):
  - BENE_HI_CVRAGE_TOT_MONS = "Total number of months of Part A coverage for the
    beneficiary" (Beneficiary Summary file, codebook variable #9). Part A is the
    correct coverage type to check against inpatient claims specifically.
  - CLM_PMT_AMT = "Claim Payment Amount" (Inpatient Claims file, codebook 
    variable #7), and per Appendix 2 of the codebook, CLM_PMT_AMT feeds directly 
    into CMS's own MEDREIMB_IP (inpatient annual Medicare reimbursement) formula.
    This confirms it's a real reimbursement figure, not a charge/estimate field.
Source: CMS DE-SynPUF Codebook, https://www.cms.gov/files/document/de-10-codebook.pdf-0
--
RESULT: $4.76M in inpatient claims tied to member-years with zero recorded 
Part A coverage months, across 2008-2010:
  2010: 42 claims, $486,000
  2009: 177 claims, $1,914,000
  2008: 260 claims, $2,360,400
The 2010 figure exactly matches the discrepancy originally surfaced in 
12b_true_pmpm.sql, cross-validating that this is a real, consistent pattern 
and not a one-off artifact of this query.
--
CAVEAT: CMS states all DE-SynPUF variables are imputed, suppressed, or 
coarsened as part of disclosure protection, and that the file "does not have 
research utility due to the synthetic process used to generate the data." So 
this may reflect synthetic-data noise from CMS's own generation process rather 
than a real-world coverage/claims processing error. In real claims data, this 
exact pattern would typically prompt an eligibility data sync review or, if 
systemic, escalation to program integrity.
--
STATUS: Only 1.6% of zero-coverage rows (307 of 18,854) have a recorded death 
date -- the remaining ~98% (18,547 rows) have no death-date explanation for 
their zero-coverage status, and root cause for this majority is still open 
(see 02b, 02c). This finding (12d) narrows the question by showing a subset 
of that unexplained population has real paid claims, but doesn't close it.
*/


WITH CTE AS (
SELECT 
	ic.DESYNPUF_ID, 
    ic.CLM_ID, 
    YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) AS claim_year,
    ic.CLM_PMT_AMT
FROM inpatient_claims ic
JOIN beneficiary_summary bs ON ic.DESYNPUF_ID = bs.DESYNPUF_ID
AND YEAR(STR_TO_DATE(CLM_FROM_DT, '%Y%m%d')) = bs.BENE_YEAR
WHERE bs.BENE_HI_CVRAGE_TOT_MONS = 0
)

SELECT 
	claim_year, 
	COUNT(CLM_PMT_AMT) AS total_claims, 
	SUM(CLM_PMT_AMT) AS sum_of_claims
FROM CTE
GROUP BY claim_year 
ORDER BY claim_year DESC