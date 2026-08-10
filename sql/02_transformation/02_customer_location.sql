-- ============================================================
-- Customer Intelligence Analytics Platform
-- CORE - Customer Location
-- Grain: one row per customer
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA CORE;

CREATE OR REPLACE TABLE
    CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_LOCATION AS

SELECT
    l.CUSTOMER_ID,

    -- Observed geographic attributes
    l.COUNTRY,
    l.STATE,
    l.CITY,
    l.ZIP_CODE,
    l.LATITUDE,
    l.LONGITUDE,

    -- ZIP-level contextual attribute
    p.POPULATION

FROM CUSTOMER_INTELLIGENCE.RAW.CHURN_LOCATION l

LEFT JOIN CUSTOMER_INTELLIGENCE.RAW.CHURN_POPULATION p
    ON l.ZIP_CODE = p.ZIP_CODE;