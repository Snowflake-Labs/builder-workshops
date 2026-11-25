use role accountadmin;

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
use database util_db;
use schema public;

-- ── PRE-CHECK ── Confirm the lab objects exist ─────────────────────────────
-- Stops the script with a clear message if the lab has not been completed in
-- this account, instead of a generic "Object does not exist" error.
DECLARE
  lab_not_completed EXCEPTION (-20001, 'ACTION REQUIRED: The DASH_DB_SI database was not found in this account. Complete every step of the lab before running this answer key, and make sure you are signed in to the same Snowflake account you used for the lab. Then run this full script again from top to bottom.');
BEGIN
  IF ((SELECT COUNT(*) FROM SNOWFLAKE.INFORMATION_SCHEMA.DATABASES
       WHERE DATABASE_NAME = 'DASH_DB_SI') = 0) THEN
    RAISE lab_not_completed;
  END IF;
END;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA01' as step
 , (select count(*) from snowflake.information_schema.databases 
   where database_name in ('DASH_DB_SI', 'SNOWFLAKE_INTELLIGENCE')) as actual
 , 2 as expected
 ,'All databases were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA02' as step
 , (select count(*) from dash_db_si.information_schema.stages) as actual
 , 7 as expected
 ,'All stages were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA03' as step
 , (select count(*) from dash_db_si.information_schema.tables where table_name in ('MARKETING_CAMPAIGN_METRICS', 'PRODUCTS', 'SALES','SOCIAL_MEDIA', 'SUPPORT_CASES','ENRICHED_MARKETING_INTELLIGENCE')) as actual
 , 6 as expected
 ,'All tables were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA04' as step
 , (select count(*) from dash_db_si.information_schema.applicable_roles where role_name = 'SNOWFLAKE_INTELLIGENCE_ADMIN') as actual
 , 1 as expected
 ,'Role for Snowflake CoWork admin created successfully!' as description
);

select util_db.public.grader(step, (actual >= expected), actual, expected, description) as graded_results from (SELECT
 'BWZA05' as step
 , (select count(*) from dash_db_si.information_schema.semantic_views where owner = 'SNOWFLAKE_INTELLIGENCE_ADMIN') as actual
 , 1 as expected
 ,'Semantic view created successfully!' as description
);

select util_db.public.grader(step, (actual >= expected), actual, expected, description) as graded_results from (SELECT
 'BWZA06' as step
 , (select count(*) from dash_db_si.information_schema.cortex_search_services where owner = 'SNOWFLAKE_INTELLIGENCE_ADMIN') as actual
 , 1 as expected
 ,'Cortex Search Services created successfully!' as description
);

-- ── FINAL SUMMARY ──────────────────────────────────────────────────────────
-- Self-contained block: submits every step to the grader AND reports overall
-- status. Running only this block still records all steps, so the
-- "Congratulations" message can never appear without a grader submission.
DECLARE
  res RESULTSET;
  msg STRING;
BEGIN
  res := (
WITH check_results AS (
  SELECT 'BWZA01' AS step,
    'All databases were created successfully!' AS description,
    (select count(*) from snowflake.information_schema.databases 
   where database_name in ('DASH_DB_SI', 'SNOWFLAKE_INTELLIGENCE')) AS actual,
    2 AS expected,
    '=' AS op
  UNION ALL
  SELECT 'BWZA02',
    'All stages were created successfully!',
    (select count(*) from dash_db_si.information_schema.stages),
    7,
    '='
  UNION ALL
  SELECT 'BWZA03',
    'All tables were created successfully!',
    (select count(*) from dash_db_si.information_schema.tables where table_name in ('MARKETING_CAMPAIGN_METRICS', 'PRODUCTS', 'SALES','SOCIAL_MEDIA', 'SUPPORT_CASES','ENRICHED_MARKETING_INTELLIGENCE')),
    6,
    '='
  UNION ALL
  SELECT 'BWZA04',
    'Role for Snowflake CoWork admin created successfully!',
    (select count(*) from dash_db_si.information_schema.applicable_roles where role_name = 'SNOWFLAKE_INTELLIGENCE_ADMIN'),
    1,
    '='
  UNION ALL
  SELECT 'BWZA05',
    'Semantic view created successfully!',
    (select count(*) from dash_db_si.information_schema.semantic_views where owner = 'SNOWFLAKE_INTELLIGENCE_ADMIN'),
    1,
    '>='
  UNION ALL
  SELECT 'BWZA06',
    'Cortex Search Services created successfully!',
    (select count(*) from dash_db_si.information_schema.cortex_search_services where owner = 'SNOWFLAKE_INTELLIGENCE_ADMIN'),
    1,
    '>='
),
graded AS (
  SELECT step, description,
         IFF(op = '>=', actual >= expected, actual = expected) AS passed,
         util_db.public.grader(step, IFF(op = '>=', actual >= expected, actual = expected),
                               actual, expected, description) AS graded_results
  FROM check_results
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You''ve successfully completed the From Zero to Agents lab!'
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
