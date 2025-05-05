# Snowflake Builder Workshops

This repo contains the auto-grader and the tests for your Snowflake Northstar workshop. To receive your badge, you must follow these two steps:

## 1. Set up the auto-grader

1. Open a new SQL worksheet in the Snowflake account you used to complete the lab.

2. Copy and paste the following code into the worksheet:

```sql
--!jinja
use role accountadmin;

create or replace api integration dora_api_integration 
api_provider = aws_api_gateway 
api_aws_role_arn = 'arn:aws:iam::321463406630:role/snowflakeLearnerAssumedRole' 
enabled = true 
api_allowed_prefixes = ('https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora');

create database if not exists util_db;
use database util_db;
use schema public;

create or replace external function util_db.public.grader(        
 step varchar     
 , passed boolean     
 , actual integer     
 , expected integer    
 , description varchar) 
 returns variant 
 api_integration = dora_api_integration 
 context_headers = (current_timestamp,current_account, current_statement, current_account_name) 
 as 'https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora/grader'  
;  

select grader(step, (actual = expected), actual, expected, description) as graded_results from (SELECT
 'AUTO_GRADER_IS_WORKING' as step
 ,(select 123) as actual
 ,123 as expected
 ,'The Snowflake auto-grader has been successfully set up in your account!' as description
);

create or replace external function util_db.public.greeting(
      email varchar
    , firstname varchar
    , middlename varchar
    , lastname varchar)
returns variant
api_integration = dora_api_integration
context_headers = (current_timestamp, current_account, current_statement, current_account_name) 
as 'https://awy6hshxy4.execute-api.us-west-2.amazonaws.com/dev/edu_dora/greeting'
; 


-- Be sure to follow the rules your session leader presents
-- Format your name CORRECTLY (do not use all lower case)
-- If you do not have a middle name, use an empty string '' ; do not use "null" in place of any values
-- Double-check your email. You must use the same email for the greeting as you used to register
select util_db.public.greeting('#insert-email-here', '#first-name',  '#middle-name',  '#last-name');
```

3. Fill out the last line of the auto-grader setup script with your email, first name, middle name (optional) and last name. **For email, please use the email you registered for the event with. If you use a different email, please allow up to 7 business days to receive your badge. For email changes, please reach out to the alias `developer-badges-DL@snowflake.com`.**

4. Run the file.

### Guidelines for formatting your name in the auto-grader setup script

- Do **not** use all capital letters.

- Do **not** use all lowercase letters.

- Do **not** use CamelCase – put spaces between your words if there are spaces between the words in your name.

- You must enter both a first and last name. **Middle names are optional**.

- Single letters do not count as names.

- You can use accents or letters from any language.

- You can use as many words as you want. For example, you can have a 3-word first name, a 3-word middle name and a 3-word last name! But please ensure there are spaces between the words in your name.

Example:

```sql
-- No middle name
select util_db.public.greeting('myemail@email.com', 'Snowflake',  '',  'Bear');

-- Middle name
select util_db.public.greeting('myemail@email.com', 'Snowflake',  'The',  'Bear');

-- Middle name with accent
select util_db.public.greeting("myemail@email.com", "Snowflake",  "O'Brien",  "Bear");
```

## 2. Run the tests for your lab

Your instructor will let you know which tests to run. For example, for the "Ingestion, Transformation, Delivery" workshop, you will run the **tests.sql** file in the **data-eng/** folder. To do so, follow these instructions:

1. Open a new SQL worksheet.

2. Copy the contents of the file containing your tests. For example, for data-eng, copy the code inside of **tests.sql**.

3. Run the entire file at once.

If you passed the lab, you should see an output in the Snowflake console with a message like **You've successfully completed this lab!**.
