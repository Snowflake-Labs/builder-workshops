# Snowflake Builder Workshops

In this repo, you'll find the SQL tests associated with each Snowflake Builder Workshop.

## AUTO-GRADER Setup Guidelines

>[!IMPORTANT]
>
> Please use the email you registered for the event with. and it shoud be the same email you will use for logging into Snowsight.
>
> **IF YOU USE A DIFFERENT EMAIL,YOUR BADGE WILL NOT BE AUTO-ISSUED.**


- Do not use all capital letters.
- Do not use all lowercase letters.
- Do not use CamelCase – put spaces between your words if there are spaces between the words in your name.
- You must enter both a first and last name. Middle names are optional. Single letters do not count as names.
- You can use accents or letters from any language.
- You can use as many words as you want. For example, you can have a 3-word first name, a 3-word middle name and a 3-word last name! But please ensure there are spaces between the words in your name.

For email changes, please reach out to the alias developer-badges-DL@snowflake.com

## Setup Auto Grader

Assuming you are running [`gen-ai`](./gen-ai) workshop.

From within Snowsight SQL Worksheet run the following SQL commands:

>[!NOTE]
> Ensure `student email`, `student first name`, `middle name`(optional, you can leave it blank) and `last_name` are updated as per the instructions in previous section.

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE DATABASE GRADER_SETUP;
USE DATABASE GRADER_SETUP;

CREATE OR REPLACE API INTEGRATION git_api_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/Snowflake-Labs')
  ENABLED = TRUE;

CREATE OR REPLACE GIT REPOSITORY builder_workshops
  API_INTEGRATION = git_api_integration
  ORIGIN = 'https://github.com/Snowflake-Labs/builder-workshops.git';

ALTER GIT REPOSITORY builder_workshops FETCH;

-- make sure you get tests.sql and setup.sql files
ls @builder_workshops/branches/main;

-- Setup Auto Grader
-- Be sure to follow the rules your session leader presents
-- Format your name CORRECTLY (do not use all lower case)
-- If you do not have a middle name, use an empty string '' ; do not use "null" in place of any values
-- Double-check your email. You must use the same email for the greeting as you used to register
-- e.g.
-- EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/auto-grader/setup.sql
-- USING(email => 'jdoe@example.com', first_name => 'John', middle_name => '' ,last_name => 'Doe');
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/auto-grader/setup.sql
    USING(email => /* update your email used to register for the workshop */, first_name => /*your first name */, middle_name => '' ,last_name => /* your last name*/);
```

## Run Tests

>[!IMPORTANT]
> If you dont run the follwing setep, your badges will not be generated/issued.

Each workshop `data-eng`, `gen-ai` and `ml` has the respective tests `tests.sql` run them to ensure the labs has been completed,

e.g. to validate `gen-ai` workshop

```sql
-- Run Grading
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main//*ask the sessions leader on the workshop tests*//tests.sql;
```

The SQL should finish successfully with a response with `STATUS` **You've successfully completed this lab!**.

>[!NOTE]
> - If you run `data-eng` workshop please ensure the `gen-ai` references in the above SQL scripts are duly updated with `data-eng`
