# Snowflake Builder Workshops

In this repo, you'll find the SQL tests associated with each Snowflake Builder Workshop.

## Setup Auto Grader

From within Snowsight run the following SQL commands

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE GRADER_SETUP;
USE DATABASE GRADER_SETUP;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/Snowflake-Labs/builder-workshops.git')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY builder_workshops
  API_INTEGRATION = git_api_integration
  ORIGIN = 'https://github.com/Snowflake-Labs/builder-workshops.git';

ALTER GIT REPOSITORY builder_workshops FETCH;

-- make sure you get tests.sql and setup.sql files
ls @builder_workshops/branches/main;

-- Setup Auto Grader
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/auto-grader/setup.sql
    USING(email => '<student email>', first_name => '<student first name>', middle_name => '' ,last_name => '<student last name>');
```

## Run Tests

Each workshop `data-eng`, `gen-ai` and `ml` has the respective tests `tests.sql` run them to ensure the labs has been completed,

e.g. to validate `gen-ai` workshop

```sql
-- Run Grading
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/gen-ai/tests.sql;
```

The SQL should finish successfully with a response with `STATUS` **You've successfully completed this lab!**.
