-- ============================================================
-- NORTHSTAR DATA ENGINEERING LAB — ANSWER KEY / AUTOGRADER
-- ============================================================
-- Run this script AS-IS after completing all steps in the lab,
-- including the Delivery section (Semantic View + Cortex Agent)
-- in the Snowsight UI. Run it BEFORE the teardown cell.
--
-- DO NOT modify any queries in this script.
-- Hardcoding expected values or altering checks invalidates
-- your grading and defeats the purpose of the lab.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ── PRE-CHECK ── Confirm the autograder is set up ──────────────────────────
-- Stops the script with a clear message if the autograder setup script has
-- not been run in this account (util_db.public.grader is missing).
DECLARE
  autograder_not_set_up EXCEPTION (-20002, 'ACTION REQUIRED: The Snowflake autograder is not set up in this account. Run the autograder setup script provided for this lab first (including the greeting with the same email you used to register), then run this answer key again from top to bottom.');
  grader_count INTEGER DEFAULT 0;
BEGIN
  BEGIN
    SHOW EXTERNAL FUNCTIONS LIKE 'GRADER' IN SCHEMA util_db.public;
    grader_count := (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID())));
  EXCEPTION
    WHEN OTHER THEN
      grader_count := 0;
  END;
  IF (grader_count = 0) THEN
    RAISE autograder_not_set_up;
  END IF;
END;
USE WAREHOUSE COMPUTE_WH;
-- ── PRE-CHECK ── Confirm the lab database exists ───────────────────────────
-- Stops the script with a clear message if the lab has not been completed in
-- this account, instead of a generic "Object does not exist" error.
DECLARE
  lab_not_completed EXCEPTION (-20001, 'ACTION REQUIRED: The TASTY_BYTES database was not found in this account. Complete every step of the lab before running this answer key, and make sure you are signed in to the same Snowflake account you used for the lab. Then run this full script again from top to bottom.');
BEGIN
  IF ((SELECT COUNT(*) FROM SNOWFLAKE.INFORMATION_SCHEMA.DATABASES
       WHERE DATABASE_NAME = 'TASTY_BYTES') = 0) THEN
    RAISE lab_not_completed;
  END IF;
END;

USE DATABASE TASTY_BYTES;

-- Pre-fetch agent list once for reuse in step 6 and the summary
SHOW AGENTS IN SCHEMA TASTY_BYTES.ANALYTICS;
CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ── STEP 1 ── Database setup ───────────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC01' AS step,
    (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME IN ('RAW_POS', 'HARMONIZED', 'ANALYTICS')) AS actual,
    3 AS expected,
    'TASTY_BYTES database created with RAW_POS, HARMONIZED, and ANALYTICS schemas — if this fails, re-run the Setup cell in the notebook' AS description
);

-- ── STEP 2 ── Marketplace install ──────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC02' AS step,
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES
     WHERE DATABASE_NAME = 'FROSTBYTE_WEATHERSOURCE') AS actual,
    1 AS expected,
    'FROSTBYTE_WEATHERSOURCE Marketplace listing installed — if this fails, re-run the weather_install cell in the notebook' AS description
);

-- ── STEP 3 ── Data ingestion ───────────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC03' AS step,
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.RAW_POS.COUNTRY) = 30
      AND (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
           WHERE TABLE_SCHEMA = 'RAW_POS' AND TABLE_TYPE = 'BASE TABLE') = 7,
      1, 0) AS actual,
    1 AS expected,
    'All raw POS tables loaded (COUNTRY: 30 rows, all 7 tables populated) — if this fails, re-run the copy_country and copy_bulk cells in the notebook' AS description
);

-- ── STEP 4 ── SQL UDFs (existence + correctness check) ────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC04' AS step,
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.FUNCTIONS
       WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER')
         AND FUNCTION_SCHEMA = 'ANALYTICS') = 2
      AND TASTY_BYTES.ANALYTICS.FAHRENHEIT_TO_CELSIUS(32) = 0
      AND TASTY_BYTES.ANALYTICS.INCH_TO_MILLIMETER(1) = 25.4,
      1, 0) AS actual,
    1 AS expected,
    'FAHRENHEIT_TO_CELSIUS and INCH_TO_MILLIMETER UDFs created in TASTY_BYTES.ANALYTICS with correct logic — if this fails, re-run the udfs cell in the notebook' AS description
);

-- ── STEP 5 ── Dynamic Tables (existence + data check) ─────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC05' AS step,
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = 'HARMONIZED'
         AND TABLE_NAME IN ('DAILY_WEATHER_DT', 'WINDSPEED_HAMBURG_DT',
                            'WEATHER_HAMBURG_DT', 'SALES_HAMBURG_DT')) = 4
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.WEATHER_HAMBURG_DT) > 0
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.SALES_HAMBURG_DT) > 0,
      1, 0) AS actual,
    1 AS expected,
    'All 4 Dynamic Tables created and populated in TASTY_BYTES.HARMONIZED — if this fails, re-run the DT cells and wait for the initial refresh to complete' AS description
);

-- ── STEP 6 ── Delivery — Semantic View + Cortex Agent ─────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWDC06' AS step,
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'TASTY_BYTES'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'HAMBURG_INSIGHTS_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check
           WHERE "name" = 'HAMBURG_AGENT') = 1,
      1, 0) AS actual,
    1 AS expected,
    'HAMBURG_INSIGHTS_SV Semantic View and HAMBURG_AGENT Cortex Agent created in TASTY_BYTES.ANALYTICS — if this fails, confirm the exact names match the guide' AS description
);

-- ── FINAL SUMMARY ──────────────────────────────────────────────────────────
-- Self-contained block: rebuilds its own lookup table, submits every step to
-- the grader, AND reports overall status. Running only this block still
-- records all steps, so the "Congratulations" message can never appear
-- without a grader submission.
DECLARE
  res RESULTSET;
  msg STRING;
BEGIN
  SHOW AGENTS IN SCHEMA TASTY_BYTES.ANALYTICS;
  CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
    SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

  res := (
WITH check_results AS (
  SELECT 'BWDC01' AS step,
    'TASTY_BYTES database created with RAW_POS, HARMONIZED, and ANALYTICS schemas — if this fails, re-run the Setup cell in the notebook' AS description,
    (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME IN ('RAW_POS', 'HARMONIZED', 'ANALYTICS')) AS actual,
    3 AS expected
  UNION ALL
  SELECT 'BWDC02',
    'FROSTBYTE_WEATHERSOURCE Marketplace listing installed — if this fails, re-run the weather_install cell in the notebook',
    (SELECT COUNT(*) FROM SNOWFLAKE.INFORMATION_SCHEMA.DATABASES
     WHERE DATABASE_NAME = 'FROSTBYTE_WEATHERSOURCE'),
    1
  UNION ALL
  SELECT 'BWDC03',
    'All raw POS tables loaded (COUNTRY: 30 rows, all 7 tables populated) — if this fails, re-run the copy_country and copy_bulk cells in the notebook',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.RAW_POS.COUNTRY) = 30
      AND (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
           WHERE TABLE_SCHEMA = 'RAW_POS' AND TABLE_TYPE = 'BASE TABLE') = 7,
      1, 0),
    1
  UNION ALL
  SELECT 'BWDC04',
    'FAHRENHEIT_TO_CELSIUS and INCH_TO_MILLIMETER UDFs created in TASTY_BYTES.ANALYTICS with correct logic — if this fails, re-run the udfs cell in the notebook',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.FUNCTIONS
       WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER')
         AND FUNCTION_SCHEMA = 'ANALYTICS') = 2
      AND TASTY_BYTES.ANALYTICS.FAHRENHEIT_TO_CELSIUS(32) = 0
      AND TASTY_BYTES.ANALYTICS.INCH_TO_MILLIMETER(1) = 25.4,
      1, 0),
    1
  UNION ALL
  SELECT 'BWDC05',
    'All 4 Dynamic Tables created and populated in TASTY_BYTES.HARMONIZED — if this fails, re-run the DT cells and wait for the initial refresh to complete',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = 'HARMONIZED'
         AND TABLE_NAME IN ('DAILY_WEATHER_DT', 'WINDSPEED_HAMBURG_DT',
                            'WEATHER_HAMBURG_DT', 'SALES_HAMBURG_DT')) = 4
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.WEATHER_HAMBURG_DT) > 0
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.SALES_HAMBURG_DT) > 0,
      1, 0),
    1
  UNION ALL
  SELECT 'BWDC06',
    'HAMBURG_INSIGHTS_SV Semantic View and HAMBURG_AGENT Cortex Agent created in TASTY_BYTES.ANALYTICS — if this fails, confirm the exact names match the guide',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'TASTY_BYTES'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'HAMBURG_INSIGHTS_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check
           WHERE "name" = 'HAMBURG_AGENT') = 1,
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
    THEN 'Congratulations! You have successfully completed the Snowflake Northstar — Data Ingestion, Transformation, and Delivery with CoCo lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step END, ', ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS,
  -- Referencing graded_results keeps the grader call from being optimized away
  COUNT(graded_results) AS STEPS_SUBMITTED
FROM graded
  );
  RETURN TABLE(res);
EXCEPTION
  -- Lab objects are missing (or this block ran before the lab was completed).
  -- Return a readable message instead of a raw SQL compilation error.
  WHEN OTHER THEN
    msg := 'ACTION REQUIRED: Please be sure to run the full script from top to bottom, not just the last line. To do this: (1) click anywhere inside the worksheet, (2) select all of the script with Cmd+A (Mac) or Ctrl+A (Windows), and (3) click Run or press Cmd+Enter (Mac) or Ctrl+Enter (Windows). If you still see this message after running the full script, make sure you have completed every step of the lab.';
    -- If the grader itself is missing, point to the setup script instead.
    BEGIN
      SHOW EXTERNAL FUNCTIONS LIKE 'GRADER' IN SCHEMA util_db.public;
      IF ((SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))) = 0) THEN
        msg := 'ACTION REQUIRED: The Snowflake autograder is not set up in this account. Run the autograder setup script provided for this lab first (including the greeting with the same email you used to register), then run this answer key again from top to bottom.';
      END IF;
    EXCEPTION
      WHEN OTHER THEN
        msg := 'ACTION REQUIRED: The Snowflake autograder is not set up in this account. Run the autograder setup script provided for this lab first (including the greeting with the same email you used to register), then run this answer key again from top to bottom.';
    END;
    res := (SELECT :msg AS STATUS, 0 AS STEPS_SUBMITTED);
    RETURN TABLE(res);
END;
