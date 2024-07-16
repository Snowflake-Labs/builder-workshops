use role accountadmin;
use database util_db;
use schema public;


select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA5-1' as step
 ,( SELECT
( select count(*) from ( select distinct role_name from chairlift_consumer_data.information_schema.applicable_roles where role_name in ('CHAIRLIFT_ADMIN', 'CHAIRLIFT_VIEWER'))) + ( select count(*) from ( select distinct table_name from chairlift_consumer_data.information_schema.tables where table_name in ('MACHINES', 'SENSORS', 'SENSOR_READINGS', 'SENSOR_TYPES', 'LAST_READINGS'))) + ( SELECT COUNT(*) FROM CHAIRLIFT_CONSUMER_DATA.INFORMATION_SCHEMA.OBJECT_PRIVILEGES WHERE OBJECT_NAME = 'POPULATE_READING_EVERY_MINUTE') + ( SELECT COUNT(*) FROM CHAIRLIFT_CONSUMER_DATA.INFORMATION_SCHEMA.PROCEDURES WHERE PROCEDURE_NAME = 'POPULATE_READING')) as actual
 , 9 as expected
 ,'All CONSUMER objects successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA5-2' as step
 ,( SELECT
( select count(*) from ( select distinct role_name from chairlift_provider_data.information_schema.applicable_roles where role_name = 'CHAIRLIFT_PROVIDER')) + ( select count(*) from ( select distinct table_name from chairlift_provider_data.information_schema.tables where table_name = 'SENSOR_TYPES'))) as actual
 , 2 as expected
 ,'All PROVIDER objects successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA6' as step
 ,( SELECT COUNT(*) FROM CHAIRLIFT_PKG.INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CHAIRLIFT_PKG') as actual
 , 1 as expected
 ,'Application package CHAIRLIFT_PKG successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA7' as step
 ,( SELECT COUNT(*) FROM CHAIRLIFT_PKG.INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CHAIRLIFT_PKG') as actual
 , 1 as expected
 ,'Stage CHAIRLIFT_PKG.CODE.SOURCE successfully created!' as description
);

SHOW VERSIONS IN APPLICATION PACKAGE CHAIRLIFT_PKG;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA8' as step
 ,( SELECT COUNT(*)/COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID()))) as actual
 , 1 as expected
 ,'First version of application package exists!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWNA9' as step
 ,( SELECT COUNT(*) FROM( SELECT DISTINCT DATABASE_NAME FROM CHAIRLIFT_APP.INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'CHAIRLIFT_APP')) as actual
 , 1 as expected
 ,'Application CHAIRLIFT_APP successfully installed!' as description
);

SELECT 'You\'ve successfully completed this lab!' as STATUS;
