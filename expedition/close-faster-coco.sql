-- ============================================================
-- EXPEDITION 2026 DAY 3 — FINANCE CLOSE LAB — ANSWER KEY / AUTOGRADER (BWEF)
-- ============================================================
-- Run this script AS-IS after completing all steps in the lab,
-- including the "Ask It With CoWork" section (Semantic View +
-- Cortex Agent) in the Snowsight UI. Run it BEFORE the teardown cell.
--
-- DO NOT modify any queries in this script.
-- Hardcoding expected values or altering checks invalidates
-- your grading and defeats the purpose of the lab.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE MERIDIAN_STAY_FINANCE;

-- Pre-fetch Iceberg table and agent lists once for reuse in the checks and the summary
SHOW ICEBERG TABLES IN DATABASE MERIDIAN_STAY_FINANCE;
CREATE OR REPLACE TEMPORARY TABLE _lab_iceberg_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW AGENTS IN SCHEMA MERIDIAN_STAY_FINANCE.ANALYTICS;
CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ── STEP 1 ── Database setup ───────────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEF01' AS step,
    (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) AS actual,
    3 AS expected,
    'MERIDIAN_STAY_FINANCE database created with RAW, CURATED, and ANALYTICS schemas — if this fails, re-run the setup cell in the notebook' AS description
);

-- ── STEP 2 ── Land raw exports in Iceberg ──────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEF02' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'RAW'
         AND "name" IN ('PAYROLL_REGISTER', 'GL_JOURNAL_ENTRIES', 'BANK_STATEMENT')) = 3
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.PAYROLL_REGISTER) = 13
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.GL_JOURNAL_ENTRIES) = 18
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.BANK_STATEMENT) = 18,
      1, 0) AS actual,
    1 AS expected,
    'Three raw Iceberg tables loaded (PAYROLL_REGISTER 13, GL_JOURNAL_ENTRIES 18, BANK_STATEMENT 18 rows) — if this fails, re-run the raw_tables and upload_files cells, then STEP 1 (copy_raw)' AS description
);

-- ── STEP 3 ── Clean and standardize: CURATED.TRANSACTIONS ─────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEF03' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'TRANSACTIONS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 46
      AND (SELECT COUNT_IF(department IS NULL OR category IS NULL
                           OR transaction_date IS NULL OR amount IS NULL)
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0
      AND (SELECT COUNT(DISTINCT source_system) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 3
      AND (SELECT COUNT_IF(source_system NOT IN ('Payroll Register', 'General Ledger', 'Bank Statement'))
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0
      AND (SELECT COUNT(DISTINCT category) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 9
      AND (SELECT COUNT(DISTINCT department) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 11
      AND (SELECT COUNT_IF(UPPER(TRIM(description)) LIKE '%REVERSAL%' OR
                           (source_system = 'General Ledger' AND transaction_id IN ('JE-2013', 'JE-2014')))
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.TRANSACTIONS is an Iceberg table with 46 transactions, 0 unmapped values, 3 source systems (Payroll Register, General Ledger, Bank Statement), 9 categories, 11 departments, and no reversed or cancelled entries — if this fails, use the CoCo fix-up prompts under STEP 3 and re-run check_transactions' AS description
);

-- ── STEP 4 ── Reconciliation gaps: CURATED.RECONCILIATION_GAPS ─────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEF04' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'RECONCILIATION_GAPS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'RECONCILIATION_GAPS'
             AND COLUMN_NAME IN ('GAP_ID', 'TRANSACTION_ID', 'TRANSACTION_DATE', 'DESCRIPTION',
                                 'AMOUNT', 'SOURCE_SYSTEM', 'GAP_TYPE', 'NOTES')) = 8
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 2
      AND (SELECT SUM(amount) FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 47200
      AND (SELECT COUNT_IF(transaction_id = 'BK-3006' AND amount = 47000)
           FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 1
      AND (SELECT COUNT_IF(transaction_id = 'BK-3018' AND amount = 200)
           FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 1,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.RECONCILIATION_GAPS is an Iceberg table with the 8 named columns, 2 gaps totaling $47,200 (BK-3006 $47,000 + BK-3018 $200) — if this fails, re-run STEP 4 and check_gaps' AS description
);

-- ── STEP 5 ── Ask It With CoWork — Semantic View + Cortex Agent ────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEF05' AS step,
    IFF(
      (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'MERIDIAN_STAY_FINANCE'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'CLOSE_RECONCILIATION_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check
           WHERE "name" = 'CLOSE_RECONCILIATION_AGENT') = 1,
      1, 0) AS actual,
    1 AS expected,
    'CLOSE_RECONCILIATION_SV Semantic View and CLOSE_RECONCILIATION_AGENT Cortex Agent created in MERIDIAN_STAY_FINANCE.ANALYTICS — if this fails, confirm the exact names match the guide' AS description
);

-- ── FINAL SUMMARY ──────────────────────────────────────────────────────────
-- Self-contained block: rebuilds its own lookup tables, submits every step to
-- the grader, AND reports overall status. Running only this block still
-- records all steps, so the "Congratulations" message can never appear
-- without a grader submission.
DECLARE
  res RESULTSET;
BEGIN
  SHOW ICEBERG TABLES IN DATABASE MERIDIAN_STAY_FINANCE;
  CREATE OR REPLACE TEMPORARY TABLE _lab_iceberg_check AS
    SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  SHOW AGENTS IN SCHEMA MERIDIAN_STAY_FINANCE.ANALYTICS;
  CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
    SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  res := (
WITH check_results AS (
  SELECT 'BWEF01' AS step,
    'MERIDIAN_STAY_FINANCE database created with RAW, CURATED, and ANALYTICS schemas — if this fails, re-run the setup cell in the notebook' AS description,
    (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) AS actual,
    3 AS expected
  UNION ALL
  SELECT 'BWEF02',
    'Three raw Iceberg tables loaded (PAYROLL_REGISTER 13, GL_JOURNAL_ENTRIES 18, BANK_STATEMENT 18 rows) — if this fails, re-run the raw_tables and upload_files cells, then STEP 1 (copy_raw)',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'RAW'
         AND "name" IN ('PAYROLL_REGISTER', 'GL_JOURNAL_ENTRIES', 'BANK_STATEMENT')) = 3
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.PAYROLL_REGISTER) = 13
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.GL_JOURNAL_ENTRIES) = 18
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.RAW.BANK_STATEMENT) = 18,
      1, 0),
    1
  UNION ALL
  SELECT 'BWEF03',
    'CURATED.TRANSACTIONS is an Iceberg table with 46 transactions, 0 unmapped values, 3 source systems (Payroll Register, General Ledger, Bank Statement), 9 categories, 11 departments, and no reversed or cancelled entries — if this fails, use the CoCo fix-up prompts under STEP 3 and re-run check_transactions',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'TRANSACTIONS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 46
      AND (SELECT COUNT_IF(department IS NULL OR category IS NULL
                           OR transaction_date IS NULL OR amount IS NULL)
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0
      AND (SELECT COUNT(DISTINCT source_system) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 3
      AND (SELECT COUNT_IF(source_system NOT IN ('Payroll Register', 'General Ledger', 'Bank Statement'))
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0
      AND (SELECT COUNT(DISTINCT category) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 9
      AND (SELECT COUNT(DISTINCT department) FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 11
      AND (SELECT COUNT_IF(UPPER(TRIM(description)) LIKE '%REVERSAL%' OR
                           (source_system = 'General Ledger' AND transaction_id IN ('JE-2013', 'JE-2014')))
           FROM MERIDIAN_STAY_FINANCE.CURATED.TRANSACTIONS) = 0,
      1, 0),
    1
  UNION ALL
  SELECT 'BWEF04',
    'CURATED.RECONCILIATION_GAPS is an Iceberg table with the 8 named columns, 2 gaps totaling $47,200 (BK-3006 $47,000 + BK-3018 $200) — if this fails, re-run STEP 4 and check_gaps',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'RECONCILIATION_GAPS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'RECONCILIATION_GAPS'
             AND COLUMN_NAME IN ('GAP_ID', 'TRANSACTION_ID', 'TRANSACTION_DATE', 'DESCRIPTION',
                                 'AMOUNT', 'SOURCE_SYSTEM', 'GAP_TYPE', 'NOTES')) = 8
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 2
      AND (SELECT SUM(amount) FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 47200
      AND (SELECT COUNT_IF(transaction_id = 'BK-3006' AND amount = 47000)
           FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 1
      AND (SELECT COUNT_IF(transaction_id = 'BK-3018' AND amount = 200)
           FROM MERIDIAN_STAY_FINANCE.CURATED.RECONCILIATION_GAPS) = 1,
      1, 0),
    1
  UNION ALL
  SELECT 'BWEF05',
    'CLOSE_RECONCILIATION_SV Semantic View and CLOSE_RECONCILIATION_AGENT Cortex Agent created in MERIDIAN_STAY_FINANCE.ANALYTICS — if this fails, confirm the exact names match the guide',
    IFF(
      (SELECT COUNT(*) FROM MERIDIAN_STAY_FINANCE.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'MERIDIAN_STAY_FINANCE'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'CLOSE_RECONCILIATION_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check
           WHERE "name" = 'CLOSE_RECONCILIATION_AGENT') = 1,
      1, 0),
    1
),
graded AS (
  SELECT step, description, (actual = expected) AS passed,
         util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
  FROM check_results
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Expedition 2026 Day 3 — Close Faster, Audit Smarter: Build It with CoCo, Ask It with CoWork lab! Please allow 7 business days for your badge to process.'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step END, ', ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS,
  -- Referencing graded_results keeps the grader call from being optimized away
  COUNT(graded_results) AS STEPS_SUBMITTED
FROM graded
  );
  RETURN TABLE(res);
END;
