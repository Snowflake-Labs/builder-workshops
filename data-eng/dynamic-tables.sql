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

WITH check_results AS (
  SELECT 'BWDT01' AS step, 'Databases (RAW_DB, ANALYTICS_DB)' AS description,
    IFF((SELECT count(*) FROM snowflake.information_schema.databases
           WHERE database_name IN ('RAW_DB', 'ANALYTICS_DB')) = 2, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWDT02', 'Python UDTFs (expected 3)',
    IFF((SELECT count(*) FROM raw_db.information_schema.functions
           WHERE function_name IN ('GEN_CUST_INFO', 'GEN_PROD_INV', 'GEN_CUST_PURCHASE')) = 3, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDT03', 'Tables (CUSTOMERS, PRODUCTS, ORDERS)',
    IFF((SELECT count(*) FROM raw_db.information_schema.tables
           WHERE table_name IN ('CUSTOMERS', 'PRODUCTS', 'ORDERS')) = 3, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDT04', 'Dynamic Table (STG_CUSTOMERS_DT)',
    IFF((SELECT count(*) FROM analytics_db.information_schema.tables
           WHERE table_name = 'STG_CUSTOMERS_DT') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDT05', 'Dynamic Table (STG_ORDERS_DT)',
    IFF((SELECT count(*) FROM analytics_db.information_schema.tables
           WHERE table_name = 'STG_ORDERS_DT') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDT06', 'Fact Dynamic Table (FCT_CUSTOMER_ORDERS_DT)',
    IFF((SELECT count(*) FROM analytics_db.information_schema.tables
           WHERE table_name = 'FCT_CUSTOMER_ORDERS_DT') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWDT07', 'Data Quality (no null product_id)',
    IFF(
      CASE
        WHEN (SELECT count(*) FROM analytics_db.information_schema.tables
                WHERE table_name = 'FCT_CUSTOMER_ORDERS_DT') = 1
        THEN (SELECT count(*) FROM analytics_db.public.fct_customer_orders_dt WHERE product_id IS NULL)
        ELSE 1
      END = 0, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'You''ve successfully completed Dynamic Tables lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
