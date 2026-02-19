use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA01' as step
 , (select count(*) from snowflake.information_schema.databases 
   where database_name in ('DASH_DB_SI', 'SNOWFLAKE_INTELLIGENCE')) as actual
 , 2 as expected
 ,'All databases was created successfully!' as description
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
 ,'Role for snowflake intelligence admin created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA05' as step
 , (select count(*) from dash_db_si.information_schema.semantic_views where name = 'SEMANTIC_VIEW') as actual
 , 1 as expected
 ,'Semantic view created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWZA06' as step
 , (select count(*) from dash_db_si.information_schema.cortex_search_services where service_name = 'CAMPAIGN_SEARCH') as actual
 , 1 as expected
 ,'Cortex Search Services created successfully!' as description
);

SELECT 'You\'ve successfully completed the From Zero to Agents lab!' as STATUS;
