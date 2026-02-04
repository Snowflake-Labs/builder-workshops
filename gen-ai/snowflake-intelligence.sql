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

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI07' as step
 , (select case when sum(request_count) > 1 then 1 else 0 end as result from snowflake.account_usage.cortex_analyst_usage_history) as actual
 , 1 as expected
 ,'Sent requests to Cortex Analyst successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI08' as step
 , (select count(*) from dash_db_si.information_schema.functions where function_name = 'ROUNDTOWHOLE') as actual
 , 1 as expected
 ,'Created Python UDF successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI09' as step
 , (select count(*) from dash_db_si.information_schema.functions where function_name = 'AVGPRICEPERUNITPRODUCTPERSALE') as actual
 , 1 as expected
 ,'Created SQL UDTF successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI10' as step
 , (select count(*) from dash_db_si.information_schema.views where table_name = 'AVG_PRICE_PER_UNIT_PRODUCT_PER_SALE') as actual
 , 1 as expected
 ,'Created a new view using UDF/UDTF successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWSI11' as step
 , (select count(*) from dash_db_si.information_schema.tables where table_name = 'PRODUCTS_WITH_AVG_PRICE') as actual
 , 1 as expected
 ,'Created a new table using the view successfully!' as description
);

SELECT 'You\'ve successfully completed Build 2025\'s AI lab!' as STATUS;