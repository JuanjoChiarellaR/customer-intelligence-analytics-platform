-- ============================================================
-- Customer Intelligence Analytics Platform
-- CORE - Customer Profile
-- Grain: one row per customer
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA CORE;

CREATE OR REPLACE TABLE
    CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_PROFILE AS

SELECT
    CUSTOMER_ID,

    -- Observed demographic attributes
    GENDER,
    AGE,
    UNDER_30,
    SENIOR_CITIZEN,
    MARRIED,
    DEPENDENTS,
    NUMBER_OF_DEPENDENTS,

    -- Derived business segmentation
    CASE
        WHEN AGE < 30 THEN 'Under 30'
        WHEN AGE BETWEEN 30 AND 44 THEN '30-44'
        WHEN AGE BETWEEN 45 AND 59 THEN '45-59'
        WHEN AGE BETWEEN 60 AND 74 THEN '60-74'
        WHEN AGE >= 75 THEN '75+'
        ELSE 'Unknown'
    END AS AGE_BAND

FROM CUSTOMER_INTELLIGENCE.RAW.CHURN_DEMOGRAPHICS;