use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX2' as step
 ,( SELECT ROW_COUNT FROM QUICKSTART.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'TASTY_BYTE_SALES' AND TABLE_SCHEMA='ML_FUNCTIONS') as actual
 , 183398 as expected
 ,'TASTY_BYTE_SALES table successfully created and loaded!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX3-1' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.OBJECT_PRIVILEGES WHERE OBJECT_NAME = 'LOBSTERMAC_FORECAST' AND OBJECT_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'LOBSTERMAC_FORECAST model successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX3-2' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'MACNCHEESE_PREDICTIONS' AND TABLE_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'MACNCHEESE_PREDICTIONS table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX4-1' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.OBJECT_PRIVILEGES WHERE OBJECT_NAME = 'VANCOUVER_FORECAST' AND OBJECT_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'VANCOUVER_FORECAST model successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX4-2' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VANCOUVER_PREDICTIONS' AND TABLE_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'VANCOUVER_PREDICTIONS table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX5-1' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.OBJECT_PRIVILEGES WHERE OBJECT_NAME = 'VANCOUVER_ANOMALY_MODEL' AND OBJECT_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'VANCOUVER_ANOMALY_MODEL model successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX5-2' as step
 ,( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'VANCOUVER_ANOMALIES' AND TABLE_SCHEMA='ML_FUNCTIONS') as actual
 , 1 as expected
 , 'VANCOUVER_ANOMALIES table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCX6' as step
 ,( SELECT
( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.OBJECT_PRIVILEGES WHERE OBJECT_NAME IN ('AD_VANCOUVER_TRAINING_TASK', 'SEND_ANOMALY_REPORT_TASK') AND OBJECT_SCHEMA='ML_FUNCTIONS' ) + ( SELECT COUNT(*) FROM QUICKSTART.INFORMATION_SCHEMA.PROCEDURES WHERE PROCEDURE_NAME IN ('SEND_ANOMALY_REPORT', 'EXTRACT_ANOMALIES') AND PROCEDURE_SCHEMA='ML_FUNCTIONS')) as actual
 , 4 as expected
 ,'TASKS AND STORED PROCEDURES successfully created!' as description
);

SELECT 'You\'ve successfully completed this lab!' as STATUS;
