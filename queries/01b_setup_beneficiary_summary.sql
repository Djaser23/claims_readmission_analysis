-- Sets up and loads CMS DE-SynPUF Beneficiary Summary Files, Sample 1, 2008-2010.
-- One combined table (BENE_YEAR distinguishes each year's snapshot) rather than
-- three parallel tables, so year-over-year and enrollment-based queries (e.g. PMPM)
-- don't require UNIONing three tables together.
-- Run once, after 01_setup_table.sql has already created the claims_practice database.
-- Source: CMS Synthetic Public Use Files, 2008-2010 sample.

-- Enable LOAD DATA LOCAL INFILE (required on both client and server sides;
-- also pass --local-infile=1 to the mysql client when running this script)
SET GLOBAL local_infile = 1;

DROP TABLE IF EXISTS beneficiary_summary;

CREATE TABLE beneficiary_summary (
  `DESYNPUF_ID` VARCHAR(20),
  `BENE_YEAR` INT,
  `BENE_BIRTH_DT` VARCHAR(8),
  `BENE_DEATH_DT` VARCHAR(8),
  `BENE_SEX_IDENT_CD` VARCHAR(2),
  `BENE_RACE_CD` VARCHAR(2),
  `BENE_ESRD_IND` VARCHAR(2),
  `SP_STATE_CODE` VARCHAR(4),
  `BENE_COUNTY_CD` VARCHAR(4),
  `BENE_HI_CVRAGE_TOT_MONS` INT,
  `BENE_SMI_CVRAGE_TOT_MONS` INT,
  `BENE_HMO_CVRAGE_TOT_MONS` INT,
  `PLAN_CVRG_MOS_NUM` INT,
  `SP_ALZHDMTA` VARCHAR(2),
  `SP_CHF` VARCHAR(2),
  `SP_CHRNKIDN` VARCHAR(2),
  `SP_CNCR` VARCHAR(2),
  `SP_COPD` VARCHAR(2),
  `SP_DEPRESSN` VARCHAR(2),
  `SP_DIABETES` VARCHAR(2),
  `SP_ISCHMCHT` VARCHAR(2),
  `SP_OSTEOPRS` VARCHAR(2),
  `SP_RA_OA` VARCHAR(2),
  `SP_STRKETIA` VARCHAR(2),
  `MEDREIMB_IP` DECIMAL(10,2),
  `BENRES_IP` DECIMAL(10,2),
  `PPPYMT_IP` DECIMAL(10,2),
  `MEDREIMB_OP` DECIMAL(10,2),
  `BENRES_OP` DECIMAL(10,2),
  `PPPYMT_OP` DECIMAL(10,2),
  `MEDREIMB_CAR` DECIMAL(10,2),
  `BENRES_CAR` DECIMAL(10,2),
  `PPPYMT_CAR` DECIMAL(10,2)
);

-- Paths below are relative to the repo root, matching 01_setup_table.sql's convention.
-- Adjust to match wherever you've placed the unzipped CSVs.
-- Each LOAD DATA assigns BENE_YEAR via SET, since the source files don't include a year column.
--
-- Run via (from repo root):
-- mysql --local-infile=1 -u <user> -p claims_practice < queries/01b_setup_beneficiary_summary.sql

LOAD DATA LOCAL INFILE 'data/raw/DE1_0_2008_Beneficiary_Summary_File_Sample_1.csv'
INTO TABLE beneficiary_summary
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DESYNPUF_ID, BENE_BIRTH_DT, BENE_DEATH_DT, BENE_SEX_IDENT_CD, BENE_RACE_CD, BENE_ESRD_IND,
 SP_STATE_CODE, BENE_COUNTY_CD, BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS,
 BENE_HMO_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, SP_ALZHDMTA, SP_CHF, SP_CHRNKIDN, SP_CNCR,
 SP_COPD, SP_DEPRESSN, SP_DIABETES, SP_ISCHMCHT, SP_OSTEOPRS, SP_RA_OA, SP_STRKETIA,
 MEDREIMB_IP, BENRES_IP, PPPYMT_IP, MEDREIMB_OP, BENRES_OP, PPPYMT_OP,
 MEDREIMB_CAR, BENRES_CAR, PPPYMT_CAR)
SET BENE_YEAR = 2008;



LOAD DATA LOCAL INFILE 'data/raw/DE1_0_2009_Beneficiary_Summary_File_Sample_1.csv'
INTO TABLE beneficiary_summary
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DESYNPUF_ID, BENE_BIRTH_DT, BENE_DEATH_DT, BENE_SEX_IDENT_CD, BENE_RACE_CD, BENE_ESRD_IND,
 SP_STATE_CODE, BENE_COUNTY_CD, BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS,
 BENE_HMO_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, SP_ALZHDMTA, SP_CHF, SP_CHRNKIDN, SP_CNCR,
 SP_COPD, SP_DEPRESSN, SP_DIABETES, SP_ISCHMCHT, SP_OSTEOPRS, SP_RA_OA, SP_STRKETIA,
 MEDREIMB_IP, BENRES_IP, PPPYMT_IP, MEDREIMB_OP, BENRES_OP, PPPYMT_OP,
 MEDREIMB_CAR, BENRES_CAR, PPPYMT_CAR)
SET BENE_YEAR = 2009;



LOAD DATA LOCAL INFILE 'data/raw/DE1_0_2010_Beneficiary_Summary_File_Sample_1.csv'
INTO TABLE beneficiary_summary
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(DESYNPUF_ID, BENE_BIRTH_DT, BENE_DEATH_DT, BENE_SEX_IDENT_CD, BENE_RACE_CD, BENE_ESRD_IND,
 SP_STATE_CODE, BENE_COUNTY_CD, BENE_HI_CVRAGE_TOT_MONS, BENE_SMI_CVRAGE_TOT_MONS,
 BENE_HMO_CVRAGE_TOT_MONS, PLAN_CVRG_MOS_NUM, SP_ALZHDMTA, SP_CHF, SP_CHRNKIDN, SP_CNCR,
 SP_COPD, SP_DEPRESSN, SP_DIABETES, SP_ISCHMCHT, SP_OSTEOPRS, SP_RA_OA, SP_STRKETIA,
 MEDREIMB_IP, BENRES_IP, PPPYMT_IP, MEDREIMB_OP, BENRES_OP, PPPYMT_OP,
 MEDREIMB_CAR, BENRES_CAR, PPPYMT_CAR)
SET BENE_YEAR = 2010;

-- # sanity check
SHOW WARNINGS LIMIT 50; 
SELECT COUNT(*) FROM beneficiary_summary;

-- After each LOAD DATA above, run SHOW WARNINGS LIMIT 50; to inspect any conversion issues.

-- Sanity checks worth running immediately after all three loads:
-- 1. Row counts per year should roughly match the source file line counts (minus header row).
-- SELECT BENE_YEAR, COUNT(*) FROM beneficiary_summary GROUP BY BENE_YEAR;
--
-- 2. Confirm the beneficiaries in the 2010 file are genuinely Sample 1 (not a mislabeled
--    Sample 20 file) by checking DESYNPUF_ID overlap with 2008/2009:
-- SELECT COUNT(DISTINCT DESYNPUF_ID) FROM beneficiary_summary WHERE BENE_YEAR = 2010;
-- SELECT COUNT(DISTINCT DESYNPUF_ID) FROM beneficiary_summary b2010
-- WHERE b2010.BENE_YEAR = 2010
--   AND EXISTS (SELECT 1 FROM beneficiary_summary b2008
--               WHERE b2008.DESYNPUF_ID = b2010.DESYNPUF_ID AND b2008.BENE_YEAR = 2008);