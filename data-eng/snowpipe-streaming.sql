USE ROLE accountadmin;
GRANT USAGE ON DATABASE util_db TO ROLE s3_role;
GRANT USAGE ON SCHEMA util_db.public TO ROLE s3_role;
GRANT USAGE ON ALL FUNCTIONS IN DATABASE util_db TO ROLE s3_role;

USE DATABASE util_db;
USE SCHEMA public;

show storage integrations; --REQUIRED TO RUN FOR NEXT STEP

SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS01' AS step,
    (SELECT COUNT(*) FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1))) WHERE "name" = 'S3_ROLE_INTEGRATION') AS actual,
    1 AS expected,
    'Storage integration successfully created!' AS description
);

SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS02' AS step,
    (SELECT COUNT(*) 
     FROM S3_DB.INFORMATION_SCHEMA.STAGES 
     WHERE STAGE_NAME = 'S3_STAGE') AS actual,
    1 AS expected,
    'Stage S3_STAGE successfully created!' AS description
);

USE ROLE s3_role; --REQUIRED TO RUN FOR NEXT STEP

SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS03' AS step,
    (SELECT COUNT(*) 
     FROM S3_DB.INFORMATION_SCHEMA.PIPES 
     WHERE PIPE_NAME = 'S3_PIPE') AS actual,
    1 AS expected,
    'Pipe successfully created in S3_db.public schema!' AS description
);

SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS04' AS step,
    (SELECT COUNT(*) FROM (SELECT PIPE_OWNER FROM S3_DB.INFORMATION_SCHEMA.PIPES WHERE PIPE_NAME = 'S3_PIPE')) AS actual,
    1 AS expected,
    'Ownership of pipe successfully granted to role!' AS description
);

USE ROLE accountadmin;

SHOW STORAGE INTEGRATIONS;

WITH si_check AS (
  SELECT COUNT(*) AS cnt
  FROM TABLE(RESULT_SCAN(LAST_QUERY_ID(-1)))
  WHERE "name" = 'S3_ROLE_INTEGRATION'
),
check_results AS (
  SELECT 'BWSS01' AS step, 'Storage Integration (S3_ROLE_INTEGRATION)' AS description,
    IFF((SELECT cnt FROM si_check) = 1, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWSS02', 'Stage (S3_STAGE)',
    IFF((SELECT COUNT(*) FROM S3_DB.INFORMATION_SCHEMA.STAGES
           WHERE STAGE_NAME = 'S3_STAGE') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSS03', 'Pipe (S3_PIPE)',
    IFF((SELECT COUNT(*) FROM S3_DB.INFORMATION_SCHEMA.PIPES
           WHERE PIPE_NAME = 'S3_PIPE') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWSS04', 'Pipe Ownership (S3_PIPE)',
    IFF((SELECT COUNT(*) FROM (SELECT PIPE_OWNER FROM S3_DB.INFORMATION_SCHEMA.PIPES
           WHERE PIPE_NAME = 'S3_PIPE')) = 1, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You''ve successfully completed the Snowpipe Streaming lab!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
