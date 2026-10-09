-- ============================================================
-- EXPEDITION 2026 DAY 2 — CAMPAIGN PLANNING LAB — ANSWER KEY / AUTOGRADER (BWEM)
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
USE DATABASE MERIDIAN_STAY;

-- Pre-fetch Iceberg table and agent lists once for reuse in the checks and the summary
SHOW ICEBERG TABLES IN DATABASE MERIDIAN_STAY;
CREATE OR REPLACE TEMPORARY TABLE _lab_iceberg_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW AGENTS IN SCHEMA MERIDIAN_STAY.ANALYTICS;
CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ── STEP 1 ── Database setup ───────────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEM01' AS step,
    (SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.SCHEMATA
     WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) AS actual,
    3 AS expected,
    'MERIDIAN_STAY database created with RAW, CURATED, and ANALYTICS schemas — if this fails, re-run the setup cell in the notebook' AS description
);

-- ── STEP 2 ── Land raw exports in Iceberg ──────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEM02' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'RAW'
         AND "name" IN ('PAID_MEDIA_EXPORT', 'EMAIL_SMS_EXPORT', 'CRM_CAMPAIGNS_EXPORT')) = 3
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.PAID_MEDIA_EXPORT) = 16
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.EMAIL_SMS_EXPORT) = 10
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.CRM_CAMPAIGNS_EXPORT) = 7,
      1, 0) AS actual,
    1 AS expected,
    'Three raw Iceberg tables loaded (PAID_MEDIA_EXPORT 16, EMAIL_SMS_EXPORT 10, CRM_CAMPAIGNS_EXPORT 7 rows) — if this fails, re-run the raw_tables and upload_files cells, then STEP 1 (copy_raw)' AS description
);

-- ── STEP 3 ── Clean and standardize: CURATED.CAMPAIGNS ─────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEM03' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'CAMPAIGNS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 27
      AND (SELECT COUNT_IF(channel IS NULL OR region IS NULL OR audience IS NULL
                           OR start_date IS NULL OR end_date IS NULL OR budget_usd IS NULL)
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0
      AND (SELECT COUNT(DISTINCT channel) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 5
      AND (SELECT COUNT(DISTINCT region) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 5
      AND (SELECT COUNT(DISTINCT audience) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 7
      AND (SELECT COUNT_IF(LOWER(campaign_name) LIKE '%veterans day%')
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0
      AND (SELECT COUNT(*) - COUNT(DISTINCT LOWER(TRIM(campaign_name)), start_date)
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.CAMPAIGNS is an Iceberg table with 27 deduplicated campaigns, 0 unmapped values, 5 channels, 5 regions, 7 audiences, and no cancelled campaigns — if this fails, use the CoCo fix-up prompts under STEP 3 and re-run check_campaigns' AS description
);

-- ── STEP 4 ── Audience collisions: CURATED.CAMPAIGN_COLLISIONS ─────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEM04' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'CAMPAIGN_COLLISIONS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'CAMPAIGN_COLLISIONS'
             AND COLUMN_NAME IN ('CAMPAIGN_A_ID', 'CAMPAIGN_A_NAME', 'CAMPAIGN_B_ID', 'CAMPAIGN_B_NAME',
                                 'REGION', 'AUDIENCE', 'OVERLAP_START', 'OVERLAP_END',
                                 'OVERLAP_DAYS', 'COMBINED_BUDGET_USD')) = 10
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 9
      AND (SELECT SUM(combined_budget_usd) FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 557500
      AND (SELECT COUNT_IF(overlap_start BETWEEN '2026-11-01' AND '2026-11-30')
           FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 5,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.CAMPAIGN_COLLISIONS is an Iceberg table with the 10 named columns, 9 collisions (5 in November 2026), and $557,500 combined budget — if this fails, re-run STEP 4 and check_collisions (18 rows means each pair is listed twice)' AS description
);

-- ── STEP 5 ── Ask It With CoWork — Semantic View + Cortex Agent ────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEM05' AS step,
    IFF(
      (SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'MERIDIAN_STAY'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'CAMPAIGN_PLANNING_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check
           WHERE "name" = 'CAMPAIGN_PLANNING_AGENT') = 1,
      1, 0) AS actual,
    1 AS expected,
    'CAMPAIGN_PLANNING_SV Semantic View and CAMPAIGN_PLANNING_AGENT Cortex Agent created in MERIDIAN_STAY.ANALYTICS — if this fails, confirm the exact names match the guide' AS description
);

-- ── FINAL SUMMARY ──────────────────────────────────────────────────────────
WITH check_results AS (
  SELECT 'BWEM01' AS step, 'Database setup (MERIDIAN_STAY + 3 schemas)' AS description,
    IFF((SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.SCHEMATA
         WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) = 3, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWEM02', 'Raw Iceberg tables loaded (16 / 10 / 7 rows)',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'RAW'
         AND "name" IN ('PAID_MEDIA_EXPORT', 'EMAIL_SMS_EXPORT', 'CRM_CAMPAIGNS_EXPORT')) = 3
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.PAID_MEDIA_EXPORT) = 16
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.EMAIL_SMS_EXPORT) = 10
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.RAW.CRM_CAMPAIGNS_EXPORT) = 7,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEM03', 'CURATED.CAMPAIGNS — 27 clean, deduplicated campaigns (Iceberg)',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'CAMPAIGNS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 27
      AND (SELECT COUNT_IF(channel IS NULL OR region IS NULL OR audience IS NULL
                           OR start_date IS NULL OR end_date IS NULL OR budget_usd IS NULL)
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0
      AND (SELECT COUNT(DISTINCT channel) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 5
      AND (SELECT COUNT(DISTINCT region) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 5
      AND (SELECT COUNT(DISTINCT audience) FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 7
      AND (SELECT COUNT_IF(LOWER(campaign_name) LIKE '%veterans day%')
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0
      AND (SELECT COUNT(*) - COUNT(DISTINCT LOWER(TRIM(campaign_name)), start_date)
           FROM MERIDIAN_STAY.CURATED.CAMPAIGNS) = 0,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEM04', 'CURATED.CAMPAIGN_COLLISIONS — 9 collisions, $557,500 (Iceberg)',
    IFF(
      (SELECT COUNT(*) FROM _lab_iceberg_check
       WHERE "schema_name" = 'CURATED' AND "name" = 'CAMPAIGN_COLLISIONS') = 1
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'CAMPAIGN_COLLISIONS'
             AND COLUMN_NAME IN ('CAMPAIGN_A_ID', 'CAMPAIGN_A_NAME', 'CAMPAIGN_B_ID', 'CAMPAIGN_B_NAME',
                                 'REGION', 'AUDIENCE', 'OVERLAP_START', 'OVERLAP_END',
                                 'OVERLAP_DAYS', 'COMBINED_BUDGET_USD')) = 10
      AND (SELECT COUNT(*) FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 9
      AND (SELECT SUM(combined_budget_usd) FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 557500
      AND (SELECT COUNT_IF(overlap_start BETWEEN '2026-11-01' AND '2026-11-30')
           FROM MERIDIAN_STAY.CURATED.CAMPAIGN_COLLISIONS) = 5,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEM05', 'Ask It With CoWork — CAMPAIGN_PLANNING_SV + CAMPAIGN_PLANNING_AGENT',
    IFF(
      (SELECT COUNT(*) FROM MERIDIAN_STAY.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'MERIDIAN_STAY'
         AND SCHEMA = 'ANALYTICS'
         AND NAME = 'CAMPAIGN_PLANNING_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check WHERE "name" = 'CAMPAIGN_PLANNING_AGENT') = 1,
      TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Expedition 2026 Day 2 — Campaign Planning, Simplified: Build It with CoCo, Ask It with CoWork lab! Please allow 7 business days for your badge to process.'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' — ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
