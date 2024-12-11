-- Lab1: Customer Reviews Analytics using Snowflake Cortex

use role accountadmin;;
use database util_db;
use schema public;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR01' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'TB_VOC') as actual
 , 1 as expected
 ,'TB_VOC database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR02' as step
 ,(SELECT COUNT(*) FROM TB_VOC.INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'ANALYTICS') as actual
 , 1 as expected
 ,'ANALYTICS schema successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR03' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
      from table(information_schema.query_history())
      where query_text like 'SELECT snowflake.cortex.complete(\'mixtral%') as actual
 , 1 as expected
 ,'TRANSLATE REVIEWS!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR04' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
      from table(information_schema.query_history())
      where query_text like '%\'awful\') THEN \'awful\'%') as actual
 , 1 as expected
 ,'Sentiment!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR05' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
      from table(information_schema.query_history())
      where query_text like '%[INST]### Write me survey report email%') as actual
 , 1 as expected
 ,'Write the email!' as description
);

-- Lab2: A Getting Started Guide With Snowflake Arctic and Snowflake Cortex

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR06' as step
 ,(select count(*) from arctic_qs.hol.call_transcripts) as actual
 , 200 as expected
 ,'Setup Complete!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR07' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
      from table(information_schema.query_history())
      where query_text like 'select snowflake.cortex.complete(\'snowflake-arctic\'%') as actual
 , 1 as expected
 ,'Arctic Complete function was run!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWCR08' as step
 ,(select iff(count(*)=0, 0, count(*)/count(*))
      from table(information_schema.query_history())
      where query_text like '%Agent:%DryProof670 jackets%60877%') as actual
 , 1 as expected
 ,'Streamlit App was run!' as description
);

