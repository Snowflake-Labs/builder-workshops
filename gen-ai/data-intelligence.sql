USE ROLE accountadmin;
USE WAREHOUSE HOL_WH;
USE DATABASE DASH_AUTOMATED_INTELLIGENCE_DB;


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
'BWDI01' as step
,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'DASH_AUTOMATED_INTELLIGENCE_DB') as actual
, 1 as expected
,'DASH_AUTOMATED_INTELLIGENCE_DB database successfully created!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI02' as step
 ,(SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAW', 'STAGING', 'INTERACTIVE', 'SEMANTIC')) as actual
 , 4 as expected
 ,'RAW, STAGING, INTERACTIVE, and SEMANTIC schemas successfully created!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI03' as step
 ,(SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN ('ENRICHED_ORDERS', 'FACT_ORDERS', 'DAILY_BUSINESS_METRICS')) as actual
 , 3 as expected
 ,'Dynamic Tables pipeline (ENRICHED_ORDERS, FACT_ORDERS, DAILY_BUSINESS_METRICS) successfully created!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI04' as step
 ,(SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CUSTOMER_ORDER_ANALYTICS' AND TABLE_SCHEMA = 'INTERACTIVE') as actual
 , 1 as expected
 ,'CUSTOMER_ORDER_ANALYTICS Interactive Table successfully created!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI05' as step
 ,(SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'DBT_INTERMEDIATE') as actual
 , 1 as expected
 ,'DBT_INTERMEDIATE schema successfully created!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI06' as step
 ,(SELECT IFF(COUNT(*) >= 1, 1, 0) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'DBT_ANALYTICS') as actual
 , 1 as expected
 ,'DBT_ANALYTICS schema contains data!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI07' as step
 ,(SELECT IFF(COUNT(*) >= 1, 1, 0) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'DBT_STAGING') as actual
 , 1 as expected
 ,'DBT_STAGING schema contains data!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWDI08' as step
 ,(SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.STREAMLITS WHERE STREAMLIT_NAME = 'THE_DASHBOARD' AND STREAMLIT_SCHEMA = 'RAW') as actual
 , 1 as expected
 ,'THE_DASHBOARD Streamlit app successfully created!' as description
);


WITH check_results AS (
 SELECT 'BWDI01' AS step, 'Database (DASH_AUTOMATED_INTELLIGENCE_DB)' AS description,
   IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'DASH_AUTOMATED_INTELLIGENCE_DB') = 1, TRUE, FALSE) AS passed
 UNION ALL
 SELECT 'BWDI02', 'Schemas (RAW, STAGING, INTERACTIVE, SEMANTIC)',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAW', 'STAGING', 'INTERACTIVE', 'SEMANTIC')) = 4, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI03', 'Dynamic Tables Pipeline (ENRICHED_ORDERS, FACT_ORDERS, DAILY_BUSINESS_METRICS)',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME IN ('ENRICHED_ORDERS', 'FACT_ORDERS', 'DAILY_BUSINESS_METRICS')) = 3, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI04', 'Interactive Table (CUSTOMER_ORDER_ANALYTICS)',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CUSTOMER_ORDER_ANALYTICS' AND TABLE_SCHEMA = 'INTERACTIVE') = 1, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI05', 'Schema (DBT_INTERMEDIATE)',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'DBT_INTERMEDIATE') = 1, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI06', 'DBT_ANALYTICS schema contains data',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'DBT_ANALYTICS') >= 1, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI07', 'DBT_STAGING schema contains data',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'DBT_STAGING') >= 1, TRUE, FALSE)
 UNION ALL
 SELECT 'BWDI08', 'Streamlit App (THE_DASHBOARD) in RAW schema',
   IFF((SELECT COUNT(*) FROM DASH_AUTOMATED_INTELLIGENCE_DB.INFORMATION_SCHEMA.STREAMLITS WHERE STREAMLIT_NAME = 'THE_DASHBOARD' AND STREAMLIT_SCHEMA = 'RAW') = 1, TRUE, FALSE)
)
SELECT
 CASE
   WHEN SUM(IFF(passed, 0, 1)) = 0
   THEN 'Congratulations! You have successfully completed the Build an End-to-End AI Application on Snowflake workshop!'
   ELSE 'Not all steps passed. Failed: ' ||
        LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
          WITHIN GROUP (ORDER BY step)
 END AS STATUS
FROM check_results;




