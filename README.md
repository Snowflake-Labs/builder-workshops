# Snowflake Builder Workshops

This repo contains the auto-grader and the tests for your Snowflake Northstar workshop. To receive your badge, you must follow these two steps:

## 1. Set up the auto-grader

1. Visit [https://northstarautograder.streamlit.app/](https://northstarautograder.streamlit.app/) to automate your script needed for the auto-grader setup.
  
2. Open a new SQL worksheet in the Snowflake account you used to complete the lab.

3. Paste the generated script from Step 1 in the worksheet.

4. Run the file.

### Guidelines for formatting your name in the auto-grader setup script

- Do **not** use all capital letters.

- Do **not** use all lowercase letters.

- Do **not** use CamelCase – put spaces between your words if there are spaces between the words in your name.

- You must enter both a first and last name. **Middle names are optional**.

- Single letters do not count as names. If your first or last name is a single character, please add a space after it. (Example: 'A ')

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
```sql
-- Data Engineering badge = data-eng/tests.sql
-- LLMOps badge = gen-ai/llm-ops.sql
-- Cortex Analyst = gen-ai/cortex-analyst.sql
   ```
   
3. Run the entire file at once.

If you passed the lab, you should see an output in the Snowflake console with a message like **You've successfully completed this lab!**.

#### Please allow up to 7 business days to receive your badge.
