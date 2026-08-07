USE ROLE accountadmin;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE AI_WORKSHOP_DB;

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWRA01' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'AI_WORKSHOP_DB') as actual
 , 1 as expected
 ,'AI_WORKSHOP_DB database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWRA02' as step
  ,(SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAG_DATA', 'ANALYTICS')) as actual
  , 2 as expected
  ,'RAG_DATA and ANALYTICS schemas successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWRA03' as step
  ,(SELECT COUNT(*) FROM AI_WORKSHOP_DB.RAG_DATA.FEATURE_DOCS) as actual
  , 15 as expected
  ,'FEATURE_DOCS contains all 15 documents!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWRA04' as step
  ,(SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CHUNKED_DOCS' AND TABLE_SCHEMA = 'RAG_DATA') as actual
  , 1 as expected
  ,'CHUNKED_DOCS table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWRA05' as step
  ,(SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES WHERE SERVICE_NAME = 'FEATURE_SEARCH_SERVICE') as actual
  , 1 as expected
  ,'FEATURE_SEARCH_SERVICE Cortex Search Service successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWRA06' as step
  ,(SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.SEMANTIC_VIEWS WHERE NAME = 'TPCH_ORDER_ANALYTICS' AND SCHEMA = 'ANALYTICS') as actual
  , 1 as expected
  ,'TPCH_ORDER_ANALYTICS Semantic View successfully created!' as description
);

WITH check_results AS (
  SELECT 'BWRA01' AS step, 'Database (AI_WORKSHOP_DB)' AS description,
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'AI_WORKSHOP_DB') = 1, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWRA02', 'Schemas (RAG_DATA, ANALYTICS)',
    IFF((SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('RAG_DATA', 'ANALYTICS')) = 2, TRUE, FALSE)
  UNION ALL
  SELECT 'BWRA03', 'FEATURE_DOCS Row Count (expected 15)',
    IFF(
      CASE
        WHEN (SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'FEATURE_DOCS' AND TABLE_SCHEMA = 'RAG_DATA') = 1
        THEN (SELECT COUNT(*) FROM AI_WORKSHOP_DB.RAG_DATA.FEATURE_DOCS)
        ELSE 0
      END = 15, TRUE, FALSE)
  UNION ALL
  SELECT 'BWRA04', 'Table (CHUNKED_DOCS)',
    IFF((SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'CHUNKED_DOCS' AND TABLE_SCHEMA = 'RAG_DATA') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWRA05', 'Cortex Search Service (FEATURE_SEARCH_SERVICE)',
    IFF((SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.CORTEX_SEARCH_SERVICES WHERE SERVICE_NAME = 'FEATURE_SEARCH_SERVICE') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWRA06', 'Semantic View (TPCH_ORDER_ANALYTICS)',
    IFF((SELECT COUNT(*) FROM AI_WORKSHOP_DB.INFORMATION_SCHEMA.SEMANTIC_VIEWS WHERE NAME = 'TPCH_ORDER_ANALYTICS' AND SCHEMA = 'ANALYTICS') = 1, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Building AI Applications with Snowflake Cortex: RAG, Text-to-SQL & CoCo workshop!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
