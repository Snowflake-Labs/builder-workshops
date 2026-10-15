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
USE WAREHOUSE COMPUTE_WH;
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
WITH check_results AS (
  SELECT 'BWDC01' AS step, 'Database setup (TASTY_BYTES + 3 schemas)' AS description,
    IFF((SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SCHEMATA
         WHERE SCHEMA_NAME IN ('RAW_POS', 'HARMONIZED', 'ANALYTICS')) = 3, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWDC02', 'Marketplace install (FROSTBYTE_WEATHERSOURCE)',
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES
         WHERE DATABASE_NAME = 'FROSTBYTE_WEATHERSOURCE') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDC03', 'Data ingestion (7 RAW_POS tables, COUNTRY = 30 rows)',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.RAW_POS.COUNTRY) = 30
      AND (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
           WHERE TABLE_SCHEMA = 'RAW_POS' AND TABLE_TYPE = 'BASE TABLE') = 7,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWDC04', 'UDFs — functional check (32°F = 0°C, 1 inch = 25.4 mm)',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.FUNCTIONS
       WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER')
         AND FUNCTION_SCHEMA = 'ANALYTICS') = 2
      AND TASTY_BYTES.ANALYTICS.FAHRENHEIT_TO_CELSIUS(32) = 0
      AND TASTY_BYTES.ANALYTICS.INCH_TO_MILLIMETER(1) = 25.4,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWDC05', 'Dynamic Tables — all 4 created and populated',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.TABLES
       WHERE TABLE_SCHEMA = 'HARMONIZED'
         AND TABLE_NAME IN ('DAILY_WEATHER_DT', 'WINDSPEED_HAMBURG_DT',
                            'WEATHER_HAMBURG_DT', 'SALES_HAMBURG_DT')) = 4
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.WEATHER_HAMBURG_DT) > 0
      AND (SELECT COUNT(*) FROM TASTY_BYTES.HARMONIZED.SALES_HAMBURG_DT) > 0,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWDC06', 'Delivery — HAMBURG_INSIGHTS_SV + HAMBURG_AGENT',
    IFF(
      (SELECT COUNT(*) FROM TASTY_BYTES.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'TASTY_BYTES'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'HAMBURG_INSIGHTS_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check WHERE "name" = 'HAMBURG_AGENT') = 1,
      TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Snowflake Northstar — Data Ingestion, Transformation, and Delivery with CoCo lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' — ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
