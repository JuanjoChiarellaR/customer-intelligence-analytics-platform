-- ============================================================
-- Customer Intelligence Analytics Platform
-- Streamlit Permissions
-- ============================================================
-- Purpose:
-- Grant CUSTOMER_INTELLIGENCE_ROLE the privileges required to
-- create and own the Executive Customer Intelligence Dashboard
-- as a Streamlit-in-Snowflake app in the ANALYTICS schema.
--
-- This file is the version-controlled record of grants that were
-- executed live in Snowsight. It is checked in here to close the
-- gap between the live Snowflake environment and this repository
-- -- it has not been executed from this repository.
--
-- Run this script using ACCOUNTADMIN or another role with
-- sufficient privilege-management permissions.
-- ============================================================

USE ROLE ACCOUNTADMIN;

GRANT USAGE
ON DATABASE CUSTOMER_INTELLIGENCE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE
ON SCHEMA CUSTOMER_INTELLIGENCE.ANALYTICS
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT CREATE STREAMLIT
ON SCHEMA CUSTOMER_INTELLIGENCE.ANALYTICS
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Verification
-- ------------------------------------------------------------

SHOW GRANTS TO ROLE CUSTOMER_INTELLIGENCE_ROLE;
