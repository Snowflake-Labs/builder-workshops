USE ROLE accountadmin;
GRANT USAGE ON DATABASE util_db TO ROLE s3_role;
GRANT USAGE ON SCHEMA util_db.public TO ROLE s3_role;
GRANT USAGE ON ALL FUNCTIONS IN DATABASE util_db TO ROLE s3_role;

show storage integrations; --REQUIRED TO RUN NEXT STEP

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
     FROM INFORMATION_SCHEMA.STAGES 
     WHERE STAGE_NAME = 'S3_STAGE') AS actual,
    1 AS expected,
    'Stage S3_STAGE successfully created!' AS description
);
SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS03' AS step,
    (SELECT COUNT(*) 
     FROM INFORMATION_SCHEMA.PIPES 
     WHERE PIPE_NAME = 'S3_PIPE') AS actual,
    1 AS expected,
    'Pipe successfully created in S3_db.public schema!' AS description
);

use role s3_role; --REQUIRED TO RUN NEXT STEP

SELECT util_db.public.grader(step, (actual = expected), actual, expected, description) AS graded_results 
FROM (
  SELECT 
    'BWSS04' AS step,
    (SELECT COUNT(*) FROM (SELECT PIPE_OWNER FROM S3_DB.INFORMATION_SCHEMA.PIPES WHERE PIPE_NAME = 'S3_PIPE')) AS actual,
    1 AS expected,
    'Ownership of pipe successfully granted to role!' AS description
);

