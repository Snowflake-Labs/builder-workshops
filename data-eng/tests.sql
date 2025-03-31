USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE DATABASE tasty_bytes;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD01' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'tasty_bytes') as actual
 , 1 as expected
 ,'tasty_bytes database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD02' as step
 ,(SELECT COUNT(*) FROM tasty_bytes.raw_pos.country) as actual
 , 30 as expected
 ,'Data successfully copied into the country table!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results 
from (
    SELECT
        'BWITD03' as step,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'hamburg_wind_speed_v' AND TABLE_SCHEMA = 'harmonized' AND TABLE_CATALOG = 'tasty_bytes') as actual, 1 as expected,         'hamburg_wind_speed_v view successfully created and contains correct data!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results 
from (
    SELECT
        'BWITD04' as step,
        (SELECT COUNT(*) FROM INFORMATION_SCHEMA.FUNCTIONS WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER') AND FUNCTION_SCHEMA = 'ANALYTICS' AND FUNCTION_CATALOG = 'TASTY_BYTES') as actual, 2 as expected, 'fahrenheit_to_celsius and inch_to_millimeter UDFs successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD05' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.STREAMLITS WHERE STREAMLIT_TITLE = 'HAMBURG_GERMANY_TRENDS' AND STREAMLIT_CATALOG = 'TASTY_BYTES' AND STREAMLIT_SCHEMA = 'HARMONIZED') as actual
 , 1 as expected
 ,'HAMBURG_GERMANY_TRENDS Streamlit app created and run successfully!' as description
);

SELECT 'Congratulations! You have successfully completed the Snowflake Northstar - Data Engineering workshop!' as STATUS;
