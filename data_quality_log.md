## inpatient_claims - loaded 6/23/26
- 66,773 rows loaded, 0 skipped 
- NCH_BENE_IP_DDCTBL_AMT: 2,178 rows (3.26%) blank in source table. Loaded as 0's by MySQL
Decision: treat as 0 for now. REVISIT if doing per-claim financial sums.
- CLM_UTLZTN_DAY_CNT: 2,334 rows (3.5%) blank in source, loaded as 0 by MySQL.
Decision: treat as 0 for now. REVISIT: decide whether 0 vs NULL affects utilization -count or PMPM-style calculations before using this field downstream.
- Dates stored as YYYYMMDD strings, not DATE type. Must STR_TO_DATE() before doing any date math.