USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE DATABASE coco_workshop;

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
 'BWCC01' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'COCO_WORKSHOP') as actual
 , 1 as expected
 ,'COCO_WORKSHOP database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWCC02' as step
  ,(SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('PIPELINE_LAB', 'SOURCE_DATA')) as actual
  , 2 as expected
  ,'PIPELINE_LAB and SOURCE_DATA schemas successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWCC03' as step
  ,(SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'SOURCE_DATA' AND TABLE_TYPE = 'BASE TABLE') as actual
  , 5 as expected
  ,'All 5 source data tables successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWCC04' as step
  ,(SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SILVER_AP_INVOICES' AND TABLE_SCHEMA = 'PIPELINE_LAB') as actual
  , 1 as expected
  ,'SILVER_AP_INVOICES dynamic table successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWCC05' as step
  ,(SELECT COUNT(*) FROM coco_workshop.pipeline_lab.silver_ap_invoices) as actual
  , 50 as expected
  ,'SILVER_AP_INVOICES contains all 50 rows from all source systems!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected,
description) as graded_results from (SELECT
  'BWCC06' as step
  ,(SELECT IFF(COUNT(*) >= 1, 1, 0) FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY WHERE SERVICE_TYPE = 'CORTEX_CODE_CLI') as actual
  , 1 as expected
  ,'Cortex Code CLI usage detected!' as description
);

WITH check_results AS (
  SELECT 'BWCC01' AS step, 'Database (COCO_WORKSHOP)' AS description,
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'COCO_WORKSHOP') = 1, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWCC02', 'Schemas (PIPELINE_LAB, SOURCE_DATA)',
    IFF((SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME IN ('PIPELINE_LAB', 'SOURCE_DATA')) = 2, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCC03', 'Source Data Tables (expected 5)',
    IFF((SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'SOURCE_DATA' AND TABLE_TYPE = 'BASE TABLE') = 5, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCC04', 'Dynamic Table (SILVER_AP_INVOICES)',
    IFF((SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SILVER_AP_INVOICES' AND TABLE_SCHEMA = 'PIPELINE_LAB') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCC05', 'SILVER_AP_INVOICES Row Count (expected 50)',
    IFF(
      CASE
        WHEN (SELECT COUNT(*) FROM coco_workshop.INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = 'SILVER_AP_INVOICES' AND TABLE_SCHEMA = 'PIPELINE_LAB') = 1
        THEN (SELECT COUNT(*) FROM coco_workshop.pipeline_lab.silver_ap_invoices)
        ELSE 0
      END = 50, TRUE, FALSE)
  UNION ALL
  SELECT 'BWCC06', 'Cortex Code CLI Usage',
    IFF((SELECT COUNT(*) FROM SNOWFLAKE.ACCOUNT_USAGE.METERING_HISTORY WHERE SERVICE_TYPE = 'CORTEX_CODE_CLI') >= 1, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Cortex Code Foundations workshop!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
