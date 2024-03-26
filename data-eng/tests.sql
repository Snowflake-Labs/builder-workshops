use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDE3' as step
 ,( select count(*) from hol_db.information_schema.stages 
   where stage_name = 'FROSTBYTE_RAW_STAGE') as actual
 , 1 as expected
 ,'HOL_DB and FROSTBYTE_RAW_STAGE SUCCESSFULLY CREATED!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDE4' as step
 ,( select count(*) from frostbyte_weathersource.information_schema.databases 
   where database_name = 'FROSTBYTE_WEATHERSOURCE') as actual
 , 1 as expected
 ,'FROSTBYTE_WEATHERSOURCE successfully loaded!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDE5' as step
 ,( select count(*) from hol_db.information_schema.tables where table_name in ('LOCATION', 'ORDER_DETAIL')) as actual
 , 2 as expected
 ,'LOCATION AND ORDER_DETAIL tables successfully created.' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDE6' as step
 ,( select count(*) from hol_db.information_schema.procedures
   where procedure_name = 'LOAD_DAILY_CITY_METRICS_SP') as actual
 , 1 as expected
 ,'LOAD_DAILY_CITY_METRICS_SP stored procedure successfully created.' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDE7' as step
 ,( select count(*) from hol_db.information_schema.object_privileges where object_name ilike '%HOL_DAG%') as actual
 , 4 as expected
 ,'DAG and tasks successfully created.' as description
);

SELECT 'You\'ve successfully completed this lab!' as STATUS;
