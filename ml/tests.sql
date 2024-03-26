use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWGA2' as step
 ,( select count(*) from ml_hol_db.information_schema.stages 
   where stage_name = 'DIAMONDS_ASSETS') as actual
 , 1 as expected
 ,'ML_HOL_DB, ML_HOL_ASSETS, and DIAMONDS_ASSETS SUCCESSFULLY CREATED!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWGA4' as step
 ,( select count(*) from ml_hol_db.information_schema.tables 
   where table_name = 'DIAMONDS') as actual
 , 1 as expected
 ,'DIAMONDS table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWGA5' as step
 ,( SELECT COUNT(*) FROM ( SELECT DISTINCT METADATA$FILENAME from @"ML_HOL_DB"."ML_HOL_SCHEMA"."ML_HOL_ASSETS" where METADATA$FILENAME = 'preprocessing_pipeline.joblib.gz')) as actual
 , 1 as expected
 ,'PREPROCESSING_PIPELINE joblib file in ML_HOL_ASSETS stage successfully created!' as description
);

use database ML_HOL_DB;
use schema ML_HOL_SCHEMA;
SHOW MODELS;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWGA6-1' as step
 ,( SELECT count(*) FROM table(result_scan(last_query_id()))) as actual
 , 1 as expected
 ,'DIAMONDS_PRICE_PREDICTION model successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWGA6-2' as step
 ,( select COUNT(*) from ml_hol_db.information_schema.functions where function_name = 'BATCH_PREDICT_DIAMOND') as actual
 , 1 as expected
 ,'BATCH_PREDICT_DIAMOND UDF successfully created!' as description
);

SELECT 'You\'ve successfully completed this lab!' as STATUS;
