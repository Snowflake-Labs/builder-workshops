use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI01' as step
 , (select count(*) from snowflake.information_schema.databases 
   where database_name in ('DASH_DB_SI', 'SNOWFLAKE_INTELLIGENCE')) as actual
 , 2 as expected
 ,'All databases was created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI02' as step
 , (select count(*) from dash_db_si.information_schema.stages) as actual
 , 6 as expected
 ,'All stages were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI03' as step
 , (select count(*) from dash_db_si.information_schema.tables where table_name in ('MARKETING_CAMPAIGN_METRICS', 'PRODUCTS', 'SALES','SOCIAL_MEDIA', 'SUPPORT_CASES')) as actual
 , 5 as expected
 ,'All tables were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI04' as step
 , (select count(*) from dash_db_si.information_schema.applicable_roles where role_name = 'SNOWFLAKE_INTELLIGENCE_ADMIN') as actual
 , 1 as expected
 ,'Role for snowflake intelligence admin created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI05' as step
 , (select count(distinct service_name) from snowflake.account_usage.cortex_search_serving_usage_history where service_name = 'SUPPORT_CASES') as actual
 , 1 as expected
 ,'Created and used Cortex Search named Support_Cases successfully' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI06' as step
 , (select count(distinct metadata$filename) from @dash_db_si.retail.semantic_models where metadata$filename = 'marketing_campaigns.yaml') as actual
 , 1 as expected
 ,'Uploaded semantic model file needed for Cortex Analyst successfully!' as description
);

WITH check_results AS (
  SELECT 'BWSI01' AS step, 'Databases (DASH_DB_SI, SNOWFLAKE_INTELLIGENCE)' AS description,
    IFF((SELECT count(*) FROM snowflake.information_schema.databases
           WHERE database_name IN ('DASH_DB_SI', 'SNOWFLAKE_INTELLIGENCE')) = 2, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWSI02', 'Stages (expected 6)',
    IFF((SELECT count(*) FROM dash_db_si.information_schema.stages) = 6, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSI03', 'Tables (expected 5)',
    IFF((SELECT count(*) FROM dash_db_si.information_schema.tables
           WHERE table_name IN ('MARKETING_CAMPAIGN_METRICS', 'PRODUCTS', 'SALES',
                                'SOCIAL_MEDIA', 'SUPPORT_CASES')) = 5, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSI04', 'Role (SNOWFLAKE_INTELLIGENCE_ADMIN)',
    IFF((SELECT count(*) FROM dash_db_si.information_schema.applicable_roles
           WHERE role_name = 'SNOWFLAKE_INTELLIGENCE_ADMIN') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSI05', 'Cortex Search Usage (SUPPORT_CASES)',
    IFF((SELECT count(distinct service_name) FROM snowflake.account_usage.cortex_search_serving_usage_history
           WHERE service_name = 'SUPPORT_CASES') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSI06', 'Semantic Model File (marketing_campaigns.yaml)',
    IFF(
      CASE
        WHEN (SELECT count(*) FROM dash_db_si.information_schema.stages
                WHERE stage_name = 'SEMANTIC_MODELS') >= 1
        THEN (SELECT count(distinct metadata$filename) FROM @dash_db_si.retail.semantic_models
                WHERE metadata$filename = 'marketing_campaigns.yaml')
        ELSE 0
      END = 1, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'You''ve successfully completed the Snowflake Intelligence lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
