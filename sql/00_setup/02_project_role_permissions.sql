-- ============================================================
-- Customer Intelligence Analytics Platform
-- Project Role Permissions
-- ============================================================
-- Purpose:
-- Configure CUSTOMER_INTELLIGENCE_ROLE with the privileges
-- required to query the analytical platform, use Cortex Analyst,
-- manage the semantic view, and execute Cortex Analyst evaluations.
--
-- Run this script using ACCOUNTADMIN or another role with
-- sufficient privilege-management permissions.
-- ============================================================

USE ROLE ACCOUNTADMIN;

-- ------------------------------------------------------------
-- Cortex access
-- ------------------------------------------------------------

GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Database and schema access
-- ------------------------------------------------------------

GRANT USAGE ON DATABASE CUSTOMER_INTELLIGENCE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE ON SCHEMA CUSTOMER_INTELLIGENCE.RAW
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE ON SCHEMA CUSTOMER_INTELLIGENCE.CORE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE ON SCHEMA CUSTOMER_INTELLIGENCE.ANALYTICS
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE ON SCHEMA CUSTOMER_INTELLIGENCE.SEMANTIC
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT USAGE ON SCHEMA CUSTOMER_INTELLIGENCE.VALIDATION
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Warehouse access
-- ------------------------------------------------------------

GRANT USAGE ON WAREHOUSE CUSTOMER_INTELLIGENCE_WH
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Data access
-- ------------------------------------------------------------

GRANT SELECT ON ALL TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.RAW
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON ALL TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.CORE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON ALL VIEWS
IN SCHEMA CUSTOMER_INTELLIGENCE.CORE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON ALL VIEWS
IN SCHEMA CUSTOMER_INTELLIGENCE.ANALYTICS
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON ALL TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.VALIDATION
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Future object access
-- ------------------------------------------------------------

GRANT SELECT ON FUTURE TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.RAW
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON FUTURE TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.CORE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON FUTURE VIEWS
IN SCHEMA CUSTOMER_INTELLIGENCE.CORE
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON FUTURE VIEWS
IN SCHEMA CUSTOMER_INTELLIGENCE.ANALYTICS
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT SELECT ON FUTURE TABLES
IN SCHEMA CUSTOMER_INTELLIGENCE.VALIDATION
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Semantic View management
-- ------------------------------------------------------------

GRANT CREATE SEMANTIC VIEW
ON SCHEMA CUSTOMER_INTELLIGENCE.SEMANTIC
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- CUSTOMER_INTELLIGENCE_ROLE is intended to own the semantic view.
-- Run the following statement only when ownership still belongs
-- to another administrative role.

-- GRANT OWNERSHIP
-- ON SEMANTIC VIEW
-- CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_VIEW
-- TO ROLE CUSTOMER_INTELLIGENCE_ROLE
-- COPY CURRENT GRANTS;

-- ------------------------------------------------------------
-- Cortex Analyst Evaluation permissions
-- ------------------------------------------------------------

GRANT EXECUTE TASK ON ACCOUNT
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT CREATE TASK
ON SCHEMA CUSTOMER_INTELLIGENCE.SEMANTIC
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

GRANT CREATE DATASET
ON SCHEMA CUSTOMER_INTELLIGENCE.SEMANTIC
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- Run these after CUSTOMER_INTELLIGENCE_VIEW has been created.

GRANT SELECT, REFERENCES, MONITOR
ON SEMANTIC VIEW
CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_VIEW
TO ROLE CUSTOMER_INTELLIGENCE_ROLE;

-- ------------------------------------------------------------
-- Verification
-- ------------------------------------------------------------

SHOW GRANTS TO ROLE CUSTOMER_INTELLIGENCE_ROLE;