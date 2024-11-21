import streamlit as st
import logging

import re

from snowflake.snowpark.session import Session
from snowflake.core import Root
from snowflake.core.account import Account, AccountResource

st.session_state.debug = True

st.header("Snowflake Builder Workshop Auto Grader")
st.write(
    """
Auto Grader - Evaluate [Builder Workshop](https://github.com/Snowflake-Labs/builder-workshops) assignments and earn your badges within 7 days of successful completion.
         """
)

logger = logging.getLogger("builder_workshop_grader")
logging.basicConfig(
    level=logging.WARNING,
)
logger.setLevel(logging.DEBUG)

# TODO pull using Git API
builder_workshops = {
    "-1": "Select a Workshop to Grade",
    "data-eng": "Data Engineering",
    "gen-ai": "Generative AI",
    "ml": "Machine Learning",
    "apps": "Applications",
}


@st.cache_resource(show_spinner="Connecting to Snowflake")
def get_root(
    account_id: str,
    user: str,
    password: str,
) -> Root:
    session = Session.builder.configs(
        {
            "account": account_id,
            "user": user,
            "password": password,
            "role": "accountadmin",
        }
    ).getOrCreate()
    return Root(session)


def validate_email(email):
    """
    Validates an email address based on common rules:
    - Must contain exactly one @ symbol
    - Local part (before @) must not be empty and contain valid characters
    - Domain part (after @) must have at least one period
    - Domain must end with a valid TLD (at least 2 characters)
    - No consecutive dots
    - No spaces

    Args:
        email (str): Email address to validate

    Returns:
        tuple: (bool, str) - (is_valid, error_message)
    """
    if not email or not isinstance(email, str):
        return False, "Email cannot be empty and must be a string"

    # Remove leading/trailing whitespace
    email = email.strip()

    # Basic pattern matching
    pattern = r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"
    if not re.match(pattern, email):
        return False, "Invalid email format"

    # Additional checks
    try:
        local_part, domain = email.split("@")

        # Check local part
        if not local_part:
            return False, "Local part cannot be empty"
        if len(local_part) > 64:
            return False, "Local part cannot exceed 64 characters"

        # Check domain
        if not domain:
            return False, "Domain cannot be empty"
        if len(domain) > 255:
            return False, "Domain cannot exceed 255 characters"
        if ".." in domain:
            return False, "Domain cannot contain consecutive dots"
        if domain.count(".") < 1:
            return False, "Domain must contain at least one period"

        return True, "Valid email address"

    except ValueError:
        return False, "Email must contain exactly one @ symbol"


def email_matched(
    email: str,
    account_id: str,
    user: str,
    password: str,
) -> bool:
    """
    Check if the account email and user provided email matches. This method uses `ACCOUNTADMIN` role to check the account details

    Args:
        email - user provided email
        account_id - the snowflake account ID
        user - the Snowflake user name
        password - the Snowflake user password

    Returns:
        tuple: (bool, str) - (is_valid, error_message)
    """
    try:
        logger.debug("Checking account email.")
        root: Root = get_root(account_id, user, password)
        account = root.accounts[account_id].fetch()
        logger.debug(f"Account Email:{account.email}")
        return (
            account.email is not None and email == account.email,
            "Account Email and Grader email should be same.",
        )
    except Exception as e:
        logger.error(e, stack_info=True)
        return False, "Error checking account email"


def validate(
    first_name: str,
    middle_name: str,
    last_name: str,
    email: str,
    account_id: str,
    user: str,
    password: str,
) -> bool:
    """
    Validates all user provided details. Some rules that will be checked and the details will be sanitized to comply with it:
    - Do not use all capital letters.
    - Do not use all lowercase letters.
    - Do not use CamelCase, put spaces between your words if there are spaces between the words in your name.
    - You must enter both a first and last name. Middle names are optional. Single letters do not count as names.
    - You can use accents or letters from any language.
    - You can use as many words as you want. For example, you can have a 3-word first name, a 3-word middle name and a 3-word last name! But please ensure there are spaces between the words in your name.

    Args:
        first_name - user's first name
        middle_name - user's middle name
        last_name - user's last name
        email - user provided email
        account_id - the snowflake account ID
        user - the Snowflake user name
        password - the Snowflake user password

    Returns:
        bool: `True`: If validation passes, else will return False
    """
    logger.debug(f"Workshop:{workshop}")

    if workshop == "-1":
        messages.error("Select a Workshop to grade.")
        return False, None, None, None, None

    if email is None:
        messages.error("Email is required.")
        return False, None, None, None, None
    elif email is not None:
        # is it a valid email
        is_valid, message = validate_email(email)
        if not is_valid:
            messages.error(message)
            return is_valid, None, None, None, None
        # check account email and user provided email
        is_valid, email_msg = email_matched(email, account_id, user, password)
        if not is_valid:
            messages.error(email_msg)
            return False, None, None, None, None

    if first_name is None or len(first_name) < 2:
        messages.error(
            "First Name is required and should be greater than 2 characters."
        )
        return False, None, None, None, None

    if last_name is None or len(last_name) < 2:
        messages.error("Last Name is required and should be greater than 2 characters.")
        return False, None, None, None, None

    logger.debug(f"{middle_name is not None} - >>{middle_name}<<")

    if not middle_name is not None:
        if len(middle_name) < 2:
            messages.error("Middle Name should be greater than 2 characters.")
            return False, None, None, None, None
        middle_name = middle_name.title(middle_name)

    first_name = str.title(first_name)
    last_name = str.title(last_name)

    return True, first_name, middle_name, last_name, email


@st.spinner(text="Grading, please wait...")
def run_grader(
    first_name: str,
    middle_name: str,
    last_name: str,
    email: str,
    account_id: str,
    user: str,
    password: str,
):
    """
    Will setup the auto grader and run the tests
    """

    is_valid, first_name, middle_name, last_name, email = validate(
        first_name,
        middle_name,
        last_name,
        email,
        account_id,
        user,
        password,
    )
    if not is_valid:
        return

    logger.debug("Running Grader")
    _grader_setup_sql = f"""
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
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/auto-grader/setup.sql
    USING(email => '{email}', first_name => '{first_name}', middle_name => '{middle_name}'' ,last_name => ''{last_name}'');
        """
    _grader_test_sql = f"""
-- Run Grading
EXECUTE IMMEDIATE FROM @GRADER_SETUP.PUBLIC.builder_workshops/branches/main/{workshop}/tests.sql;
"""
    if st.session_state.debug:
        with st.expander("Auto Grader Scripts"):
            st.write(
                "The grader scripts that will be automatically run, its provided here for reference."
            )
            st.subheader("Grader Setup")
            st.write(
                f""" 
```sql
{_grader_setup_sql}
```
    """
            )
            st.subheader("Grader Tests")
            st.write(
                f""" 
```sql
{_grader_test_sql}
```
    """
            )


messages = st.empty()
workshop = st.selectbox(
    "Select a Workshop to Grade",
    options=builder_workshops.keys(),
    format_func=lambda x: builder_workshops[x],
    index=0,
    label_visibility="hidden",
)

with st.container():

    st.write("#### User Details")

    student_first_name = st.text_input(
        "First Name",
        key="txt_fname",
    )

    student_middle_name = st.text_input(
        "Middle Name",
        key="txt_mname",
    )

    student_last_name = st.text_input(
        "Last Name",
        key="txt_lname",
    )

    student_email = st.text_input(
        "Email",
        key="txt_email",
    )

    st.divider()

    st.write("#### Snowflake Account Details")

    snowflake_account_id = st.text_input(
        "Snowflake Account",
        key="txt_sf_ac",
    )
    snowflake_user = st.text_input(
        "Snowflake User Name",
        key="txt_sf_user",
    )
    snowflake_user_password = st.text_input(
        "Password",
        key="txt_sf_pwd",
        type="password",
    )

    can_grade = (
        student_first_name is not None
        or student_last_name is not None
        or student_email is not None
        or snowflake_account_id is not None
        or snowflake_user is not None
        or snowflake_user_password is not None
    )
    grade = st.button("Grade me!", type="primary")

    if grade:
        run_grader(
            student_first_name.strip(),
            student_middle_name.strip(),
            student_last_name.strip(),
            student_email.strip(),
            snowflake_account_id.strip(),
            snowflake_user.strip(),
            snowflake_user_password,
        )
