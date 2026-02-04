use role accountadmin;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT01' as step
 , (select count(*) from snowflake.information_schema.databases 
   where database_name in ('RAW_DB', 'ANALYTICS_DB')) as actual
 , 2 as expected
 ,'All databases was created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT02' as step
 , (select count(*) from raw_db.information_schema.functions where function_name in ('GEN_CUST_INFO', 'GEN_PROD_INV', 'GEN_CUST_PURCHASE')) as actual
 , 3 as expected
 ,'Created 3 Python UDTF successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT03' as step
 , (select count(*) from raw_db.information_schema.tables where table_name in ('CUSTOMERS', 'PRODUCTS', 'ORDERS')) as actual
 , 3 as expected
 ,'All tables were created successfully with data!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT04' as step
 , (select count(*) from analytics_db.information_schema.tables where table_name = 'STG_CUSTOMERS_DT') as actual
 , 1 as expected
 ,'First Dynamic Table were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT05' as step
 , (select count(*) from analytics_db.information_schema.tables where table_name = 'STG_ORDERS_DT') as actual
 , 1 as expected
 ,'Second Dynamic Table were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT06' as step
 , (select count(*) from analytics_db.information_schema.tables where table_name = 'FCT_CUSTOMER_ORDERS_DT') as actual
 , 1 as expected
 ,'Fact Dynamic Table were created successfully!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWDT07' as step
 , (select count(*) from analytics_db.public.fct_customer_orders_dt where product_id is null) as actual
 , 0 as expected
 ,'Data quality was integrated successfully!' as description
);

SELECT 'You\'ve successfully completed Build 2025\'s DE lab!' as STATUS;