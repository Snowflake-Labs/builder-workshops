use role accountadmin;
use database util_db;
use schema public;

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
 ,(SELECT COUNT(*) FROM cortex_analyst_demo.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'DAILY_REVENUE_BY_REGION') as actual
 , 1 as expected
 ,'DAILY_REVENUE_BY_REGION table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA3' as step
 ,( SELECT COUNT(*) FROM CORTEX_ANALYST_DEMO.REVENUE_TIMESERIES.DAILY_REVENUE_BY_REGION) as actual
 , 3650 as expected
 , 'DAILY_REVENUE_BY_REGION table successfully loaded!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA4' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
   from snowflake.account_usage.query_history
    where query_text like 'execute streamlit "CORTEX_ANALYST_DEMO".%') as actual, 1 as expected, 'Had a chat with Cortex via SIS!' as description);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCA6' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
   from snowflake.account_usage.query_history
    where query_text like 'execute streamlit "CORTEX_ANALYST_SEMANTICS"."SEMANTIC_MODEL_GEN%') as actual, 1 as expected, 'Installed the Semantic Gen Native App!' as description);
