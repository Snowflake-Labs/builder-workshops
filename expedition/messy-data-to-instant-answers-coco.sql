-- ============================================================
-- FROM MESSY DATA TO INSTANT ANSWERS — ANSWER KEY / AUTOGRADER (BWEI)
-- ============================================================
-- Run this script AS-IS after completing all steps in the lab,
-- including STEP 8 (RETURNS_SV), STEP 9 (Fix the Agent), and
-- STEP 10 (Ask in CoWork) in Snowsight. Run it BEFORE the teardown cell.
--
-- DO NOT modify any queries in this script.
-- Hardcoding expected values or altering checks invalidates
-- your grading and defeats the purpose of the lab.
-- ============================================================

USE ROLE ACCOUNTADMIN;
USE WAREHOUSE COMPUTE_WH;
USE DATABASE ONLINE_RETURNS;

-- Pre-fetch object lists once for reuse in the checks and the summary
SHOW STAGES IN SCHEMA ONLINE_RETURNS.RAW;
CREATE OR REPLACE TEMPORARY TABLE _lab_stage_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW CORTEX SEARCH SERVICES IN SCHEMA ONLINE_RETURNS.ANALYTICS;
CREATE OR REPLACE TEMPORARY TABLE _lab_search_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

SHOW AGENTS IN SCHEMA ONLINE_RETURNS.ANALYTICS;
CREATE OR REPLACE TEMPORARY TABLE _lab_agent_check AS
  SELECT * FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

DESCRIBE AGENT ONLINE_RETURNS.ANALYTICS.RETURNS_AGENT;
CREATE OR REPLACE TEMPORARY TABLE _lab_agent_spec AS
  SELECT "agent_spec"::VARCHAR AS agent_spec FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()));

-- ── STEP 1 ── Database setup ───────────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI01' AS step,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.SCHEMATA
       WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) = 3
      AND (SELECT COUNT(*) FROM _lab_stage_check WHERE "name" = 'LAB_FILES') = 1,
      1, 0) AS actual,
    1 AS expected,
    'ONLINE_RETURNS database created with RAW, CURATED, and ANALYTICS schemas and the RAW.LAB_FILES stage — if this fails, re-run the setup cell in the notebook' AS description
);

-- ── STEP 2 ── Load the raw files ───────────────────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI02' AS step,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.ORDERS) = 2000
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.RETURN_EVENTS e, LATERAL FLATTEN(input => e.payload)) = 1900
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.RETURN_COMMENTS c, LATERAL FLATTEN(input => c.payload)) = 775,
      1, 0) AS actual,
    1 AS expected,
    'Raw tables loaded: RAW.ORDERS 2,000 order lines, RAW.RETURN_EVENTS 1,900 events, RAW.RETURN_COMMENTS 775 comments — if this fails, re-run the upload_files and load_raw cells' AS description
);

-- ── STEP 5 ── Define a return: CURATED.ORDER_LINE_RETURNS ──────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI03' AS step,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'ORDER_LINE_RETURNS'
         AND COLUMN_NAME IN ('ORDER_LINE_ID', 'CATEGORY', 'REGION', 'ITEM_PRICE', 'ORDER_DT',
                             'LATEST_RETURN_STATUS', 'IS_RETURNED', 'IS_DELIVERED')) = 8
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 2000
      AND (SELECT COUNT(DISTINCT order_line_id) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 2000
      AND (SELECT COUNT_IF(category IS NULL OR region IS NULL OR item_price IS NULL OR order_dt IS NULL)
           FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 0
      AND (SELECT COUNT(DISTINCT category) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 4
      AND (SELECT COUNT(DISTINCT region) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 4
      AND (SELECT COUNT_IF(is_delivered) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 1800
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 500
      AND (SELECT SUM(IFF(is_returned, item_price, 0)) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 46958
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS
           WHERE category = 'Footwear') = 200,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.ORDER_LINE_RETURNS has the 8 named columns, 2,000 unique lines, 0 unmapped values, 4 categories, 4 regions, 1,800 delivered, 500 returned ($46,958.00), 200 Footwear returns — if this fails, use the CoCo fix-up prompt under STEP 5 and re-run check1' AS description
);

-- ── STEP 6 ── Translate and tag comments: CURATED.RETURN_REVIEW ────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI04' AS step,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.RETURN_COMMENT_INSIGHTS) = 775
      AND (SELECT COUNT_IF(comment_english IS NULL) FROM ONLINE_RETURNS.CURATED.RETURN_COMMENT_INSIGHTS) = 0
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'RETURN_REVIEW'
             AND COLUMN_NAME IN ('COMMENT', 'COMMENT_ENGLISH', 'RETURN_REASON')) = 3
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 2000
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 500
      AND (SELECT COUNT_IF(return_reason IS NOT NULL AND return_reason NOT IN
             ('Wrong size', 'Damaged or defective', 'Not as described', 'Arrived late', 'Changed mind', 'Other'))
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 0
      AND (SELECT COUNT_IF(is_returned AND return_reason = 'Wrong size')
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 175
      AND (SELECT COUNT_IF(is_returned AND return_reason = 'Wrong size')
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW
           WHERE category = 'Footwear' AND region = 'EMEA') = 75,
      1, 0) AS actual,
    1 AS expected,
    'CURATED.RETURN_COMMENT_INSIGHTS has 775 translated comments; CURATED.RETURN_REVIEW keeps 2,000 lines (500 returned) with only the six allowed labels, 175 Wrong size returns, 75 in Footwear/EMEA — if this fails, re-run check2 and use the CoCo fix-up prompts under STEP 6' AS description
);

-- ── STEP 7 ── Make the comments searchable: RETURN_COMMENTS_SEARCH ─────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI05' AS step,
    IFF(
      (SELECT COUNT(*) FROM _lab_search_check WHERE "name" = 'RETURN_COMMENTS_SEARCH') = 1,
      1, 0) AS actual,
    1 AS expected,
    'Cortex Search service RETURN_COMMENTS_SEARCH created in ONLINE_RETURNS.ANALYTICS — if this fails, re-run the STEP 7 CoCo prompt or its expected SQL' AS description
);

-- ── STEPS 8-9 ── Semantic view + fixed agent ───────────────────────────────
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results
FROM (
  SELECT
    'BWEI06' AS step,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'ONLINE_RETURNS' AND SCHEMA = 'ANALYTICS' AND NAME = 'RETURNS_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check WHERE "name" = 'RETURNS_AGENT') = 1
      AND (SELECT COUNT_IF(agent_spec ILIKE '%ANALYTICS.RETURNS_SV%'
                           AND agent_spec ILIKE '%RETURN_COMMENTS_SEARCH%'
                           AND agent_spec NOT ILIKE '%QUICK_RETURNS_SV%')
           FROM _lab_agent_spec) = 1,
      1, 0) AS actual,
    1 AS expected,
    'RETURNS_SV semantic view published, and RETURNS_AGENT uses RETURNS_SV and RETURN_COMMENTS_SEARCH with no QUICK_RETURNS_SV tool — if this fails, check the Tools list in STEP 9 and click Save' AS description
);

-- ── FINAL SUMMARY ──────────────────────────────────────────────────────────
WITH check_results AS (
  SELECT 'BWEI01' AS step, 'Database setup (ONLINE_RETURNS + 3 schemas + stage)' AS description,
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.SCHEMATA
       WHERE SCHEMA_NAME IN ('RAW', 'CURATED', 'ANALYTICS')) = 3
      AND (SELECT COUNT(*) FROM _lab_stage_check WHERE "name" = 'LAB_FILES') = 1,
      TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWEI02', 'Raw tables loaded (2,000 / 1,900 / 775)',
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.ORDERS) = 2000
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.RETURN_EVENTS e, LATERAL FLATTEN(input => e.payload)) = 1900
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.RAW.RETURN_COMMENTS c, LATERAL FLATTEN(input => c.payload)) = 775,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEI03', 'CURATED.ORDER_LINE_RETURNS — 500 of 1,800 returned, $46,958.00',
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.COLUMNS
       WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'ORDER_LINE_RETURNS'
         AND COLUMN_NAME IN ('ORDER_LINE_ID', 'CATEGORY', 'REGION', 'ITEM_PRICE', 'ORDER_DT',
                             'LATEST_RETURN_STATUS', 'IS_RETURNED', 'IS_DELIVERED')) = 8
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 2000
      AND (SELECT COUNT(DISTINCT order_line_id) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 2000
      AND (SELECT COUNT_IF(category IS NULL OR region IS NULL OR item_price IS NULL OR order_dt IS NULL)
           FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 0
      AND (SELECT COUNT(DISTINCT category) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 4
      AND (SELECT COUNT(DISTINCT region) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 4
      AND (SELECT COUNT_IF(is_delivered) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 1800
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 500
      AND (SELECT SUM(IFF(is_returned, item_price, 0)) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS) = 46958
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.ORDER_LINE_RETURNS
           WHERE category = 'Footwear') = 200,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEI04', 'CURATED.RETURN_REVIEW — AI labels, 175 Wrong size returns',
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.RETURN_COMMENT_INSIGHTS) = 775
      AND (SELECT COUNT_IF(comment_english IS NULL) FROM ONLINE_RETURNS.CURATED.RETURN_COMMENT_INSIGHTS) = 0
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.COLUMNS
           WHERE TABLE_SCHEMA = 'CURATED' AND TABLE_NAME = 'RETURN_REVIEW'
             AND COLUMN_NAME IN ('COMMENT', 'COMMENT_ENGLISH', 'RETURN_REASON')) = 3
      AND (SELECT COUNT(*) FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 2000
      AND (SELECT COUNT_IF(is_returned) FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 500
      AND (SELECT COUNT_IF(return_reason IS NOT NULL AND return_reason NOT IN
             ('Wrong size', 'Damaged or defective', 'Not as described', 'Arrived late', 'Changed mind', 'Other'))
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 0
      AND (SELECT COUNT_IF(is_returned AND return_reason = 'Wrong size')
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW) = 175
      AND (SELECT COUNT_IF(is_returned AND return_reason = 'Wrong size')
           FROM ONLINE_RETURNS.CURATED.RETURN_REVIEW
           WHERE category = 'Footwear' AND region = 'EMEA') = 75,
      TRUE, FALSE)
  UNION ALL
  SELECT 'BWEI05', 'Cortex Search service RETURN_COMMENTS_SEARCH',
    IFF((SELECT COUNT(*) FROM _lab_search_check WHERE "name" = 'RETURN_COMMENTS_SEARCH') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWEI06', 'RETURNS_SV + RETURNS_AGENT fixed to use RETURNS_SV and RETURN_COMMENTS_SEARCH',
    IFF(
      (SELECT COUNT(*) FROM ONLINE_RETURNS.INFORMATION_SCHEMA.SEMANTIC_VIEWS
       WHERE CATALOG = 'ONLINE_RETURNS' AND SCHEMA = 'ANALYTICS' AND NAME = 'RETURNS_SV') = 1
      AND (SELECT COUNT(*) FROM _lab_agent_check WHERE "name" = 'RETURNS_AGENT') = 1
      AND (SELECT COUNT_IF(agent_spec ILIKE '%ANALYTICS.RETURNS_SV%'
                           AND agent_spec ILIKE '%RETURN_COMMENTS_SEARCH%'
                           AND agent_spec NOT ILIKE '%QUICK_RETURNS_SV%')
           FROM _lab_agent_spec) = 1,
      TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the From Messy Data to Instant Answers with Snowflake CoCo and CoWork lab! Please allow 7 business days for your badge to process.'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' — ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
