USE ROLE accountadmin;
USE DATABASE util_db;
USE SCHEMA public;
GRANT USAGE ON DATABASE util_db TO ROLE cortex_user_role;
GRANT USAGE ON SCHEMA public TO ROLE cortex_user_role;
GRANT USAGE ON ALL FUNCTIONS IN DATABASE util_db TO ROLE cortex_user_role;
USE ROLE cortex_user_role;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA2-1' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CORTEX_ANALYST_DEMO') as actual
 , 1 as expected
 ,'CORTEX_ANALYST_DEMO database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA2-2' as step
 ,(SELECT COUNT(*) FROM CORTEX_ANALYST_DEMO.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'REVENUE_TIMESERIES') as actual
 , 1 as expected
 ,'REVENUE_TIMESERIES schema successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA2-3' as step
 ,( select count(*) from cortex_analyst_demo.information_schema.stages 
   where stage_name = 'RAW_DATA') as actual
 , 1 as expected
 ,'RAW_DATA STAGE SUCCESSFULLY CREATED!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA2-4' as step
 ,(SELECT COUNT(*) FROM cortex_analyst_demo.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DAILY_REVENUE') as actual
 , 1 as expected
 ,'DAILY_REVENUE table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA3' as step
 ,( SELECT COUNT(*) FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE) as actual
 , 730 as expected
 , 'DAILY_REVENUE table successfully loaded!' as description
);

WITH check_results AS (
  SELECT 'BWCA2-1' AS step, 'Database (CORTEX_ANALYST_DEMO)' AS description,
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CORTEX_ANALYST_DEMO') = 1, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWCA2-2', 'Schema (REVENUE_TIMESERIES)',
    IFF((SELECT COUNT(*) FROM CORTEX_ANALYST_DEMO.INFORMATION_SCHEMA.SCHEMATA
           WHERE SCHEMA_NAME = 'REVENUE_TIMESERIES') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCA2-3', 'Stage (RAW_DATA)',
    IFF((SELECT count(*) FROM cortex_analyst_demo.information_schema.stages
           WHERE stage_name = 'RAW_DATA') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCA2-4', 'Table (DAILY_REVENUE)',
    IFF((SELECT COUNT(*) FROM cortex_analyst_demo.INFORMATION_SCHEMA.TABLES
           WHERE TABLE_NAME = 'DAILY_REVENUE') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCA3', 'DAILY_REVENUE Data (expected 730 rows)',
    IFF(
      CASE
        WHEN (SELECT COUNT(*) FROM cortex_analyst_demo.INFORMATION_SCHEMA.TABLES
                WHERE TABLE_NAME = 'DAILY_REVENUE') = 1
        THEN (SELECT COUNT(*) FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE)
        ELSE 0
      END = 730, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You''ve successfully completed the Cortex Analyst lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
