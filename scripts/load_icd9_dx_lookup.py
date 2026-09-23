"""
load_icd9_dx_lookup.py

Loads the CMS ICD-9-CM diagnosis code descriptions into a lookup table
in the claims_practice MySQL database, so diagnosis codes in
inpatient_claims can be joined to human-readable names.

Source: CMS ICD-9-CM Diagnosis and Procedure Codes: Abbreviated and
Full Code Titles, Version 28 (effective October 1, 2010).
File: CMS28_DESC_LONG_DX.txt (long descriptions, diagnosis codes only)

Run from the project root: python scripts/load_icd9_dx_lookup.py

Status: complete. Parses, validates, creates the table, loads all
14,432 rows, and verifies the row count.
"""

import mysql.connector
import pandas as pd
import os
from dotenv import load_dotenv


# --- Set working directory ---
# Move to the project root so relative paths (data/raw/...) resolve
# the same way no matter which folder the script is launched from.
script_dir = os.path.dirname(os.path.abspath(__file__))
project_root = os.path.dirname(script_dir)
os.chdir(project_root)


# --- Connect to MySQL ---
# Password is read from a .env file so it never appears in the repo.
load_dotenv()

conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password=os.getenv('MYSQL_PASSWORD'),
    database='claims_practice'
)

print("Connection successful" if conn.is_connected() else "Connection failed")


# --- Parse the fixed-width description file ---
# Codes occupy characters 0-4; descriptions start at character 6.
# dtype=str keeps leading zeros (e.g., '0010' would otherwise become 10).
# The file is Latin-1 encoded, not UTF-8 (contains accented characters).
icd9 = pd.read_fwf(
    'data/raw/CMS28_DESC_LONG_DX.txt',
    colspecs=[(0, 5), (6, None)],
    header=None,
    names=['icd9_code', 'diagnosis_description'],
    dtype=str,
    encoding='latin-1'
)


# --- Validate the parse ---
# Row count: expect ~14,400 ICD-9-CM diagnosis codes.
print(len(icd9))

# Spot check: leading zeros intact, descriptions aligned with codes.
print(icd9.head())

# Longest description: used to size the VARCHAR column (max was 222).
print(icd9['diagnosis_description'].str.len().max())

# Non-ASCII check: Latin-1 decodes any byte without error, so confirm
# accented characters read as real letters rather than garbled symbols.
print(icd9[icd9['diagnosis_description'].str.contains(r'[^\x00-\x7F]')])


# --- Create the lookup table ---
# DROP first so the script can be re-run cleanly without
# "table already exists" errors or duplicate rows.
cursor = conn.cursor()

cursor.execute("DROP TABLE IF EXISTS icd9_dx_lookup")

cursor.execute("""
    CREATE TABLE icd9_dx_lookup (
        icd9_code VARCHAR(5) PRIMARY KEY,
        diagnosis_description VARCHAR(255) NOT NULL
    ) CHARACTER SET utf8mb4
""")

# --- Load Rows ---
# Turn the df into rows that MySQL can take
# by converting from a dataframe to a Python list of tuples
rows = list(icd9.itertuples(index=False, name=None))

# Write the SQL insert with placeholders
insert_sql = """
    INSERT INTO icd9_dx_lookup (icd9_code, diagnosis_description)
    VALUES (%s, %s)
"""
# Send all of the rows at once
cursor.executemany(insert_sql, rows)

# Commit the insert of rows
conn.commit()

# --- Verify ---
# Expect (14432,), matching the row count from the parse above.
cursor.execute("SELECT COUNT(*) FROM icd9_dx_lookup")
print(cursor.fetchone())

# Close the cursor and connector
cursor.close()
conn.close()
