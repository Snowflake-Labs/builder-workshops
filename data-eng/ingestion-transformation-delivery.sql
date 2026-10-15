USE ROLE accountadmin;
USE WAREHOUSE compute_wh;
USE DATABASE tasty_bytes;

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD01' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'TASTY_BYTES') as actual
 , 1 as expected
 ,'TASTY_BYTES database successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD02' as step
 ,(SELECT COUNT(*) FROM tasty_bytes.raw_pos.country) as actual
 , 30 as expected
 ,'Data successfully copied into the country table!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
  'BWITD03' as step
  ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'WINDSPEED_HAMBURG' AND TABLE_SCHEMA = 'HARMONIZED' AND TABLE_CATALOG = 'TASTY_BYTES') as actual
  , 1 as expected
  ,'WINDSPEED_HAMBURG view successfully created and contains correct data!' as description
);


select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
  'BWITD04' as step
  ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.FUNCTIONS WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER') AND FUNCTION_SCHEMA = 'ANALYTICS' AND FUNCTION_CATALOG = 'TASTY_BYTES') as actual
  , 2 as expected
  ,'fahrenheit_to_celsius and inch_to_millimeter UDFs successfully created!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
  'BWITD05' as step
  ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_NAME = 'WEATHER_HAMBURG' AND TABLE_SCHEMA = 'HARMONIZED' AND TABLE_CATALOG = 'TASTY_BYTES') as actual
  , 1 as expected
  ,'WEATHER_HAMBURG view successfully created and contains correct data!' as description
);

select util_db.public.grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'BWITD06' as step
 ,(SELECT COUNT(*) FROM INFORMATION_SCHEMA.STREAMLITS WHERE STREAMLIT_TITLE = 'HAMBURG_GERMANY_TRENDS' AND STREAMLIT_CATALOG = 'TASTY_BYTES' AND STREAMLIT_SCHEMA = 'HARMONIZED') as actual
 , 1 as expected
 ,'HAMBURG_GERMANY_TRENDS Streamlit app created and run successfully!' as description
);

WITH check_results AS (
  SELECT 'BWITD01' AS step, 'Database (TASTY_BYTES)' AS description,
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.DATABASES WHERE DATABASE_NAME = 'TASTY_BYTES') = 1, TRUE, FALSE) AS passed
  UNION ALL
  SELECT 'BWITD02', 'Country Table Data (expected 30 rows)',
    IFF(
      CASE
        WHEN (SELECT COUNT(*) FROM tasty_bytes.INFORMATION_SCHEMA.TABLES
                WHERE TABLE_NAME = 'COUNTRY' AND TABLE_SCHEMA = 'RAW_POS') = 1
        THEN (SELECT COUNT(*) FROM tasty_bytes.raw_pos.country)
        ELSE 0
      END = 30, TRUE, FALSE)
  UNION ALL
  SELECT 'BWITD03', 'View (WINDSPEED_HAMBURG)',
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS
           WHERE TABLE_NAME = 'WINDSPEED_HAMBURG' AND TABLE_SCHEMA = 'HARMONIZED'
             AND TABLE_CATALOG = 'TASTY_BYTES') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWITD04', 'UDFs (FAHRENHEIT_TO_CELSIUS, INCH_TO_MILLIMETER)',
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.FUNCTIONS
           WHERE FUNCTION_NAME IN ('FAHRENHEIT_TO_CELSIUS', 'INCH_TO_MILLIMETER')
             AND FUNCTION_SCHEMA = 'ANALYTICS' AND FUNCTION_CATALOG = 'TASTY_BYTES') = 2, TRUE, FALSE)
  UNION ALL
  SELECT 'BWITD05', 'View (WEATHER_HAMBURG)',
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.VIEWS
           WHERE TABLE_NAME = 'WEATHER_HAMBURG' AND TABLE_SCHEMA = 'HARMONIZED'
             AND TABLE_CATALOG = 'TASTY_BYTES') = 1, TRUE, FALSE)
  UNION ALL
  SELECT 'BWITD06', 'Streamlit App (HAMBURG_GERMANY_TRENDS)',
    IFF((SELECT COUNT(*) FROM INFORMATION_SCHEMA.STREAMLITS
           WHERE STREAMLIT_TITLE = 'HAMBURG_GERMANY_TRENDS'
             AND STREAMLIT_CATALOG = 'TASTY_BYTES' AND STREAMLIT_SCHEMA = 'HARMONIZED') = 1, TRUE, FALSE)
)
SELECT
  CASE
    WHEN SUM(IFF(passed, 0, 1)) = 0
    THEN 'Congratulations! You have successfully completed the Snowflake Northstar - Data Engineering workshop!'
    ELSE 'Not all steps passed. Failed: ' ||
         LISTAGG(CASE WHEN NOT passed THEN step || ' - ' || description END, ' | ')
           WITHIN GROUP (ORDER BY step)
  END AS STATUS
FROM check_results;
