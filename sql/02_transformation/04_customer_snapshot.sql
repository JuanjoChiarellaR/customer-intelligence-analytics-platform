-- ============================================================
-- Customer Intelligence Analytics Platform
-- CORE - Customer Snapshot
-- Grain: one row per customer at the observed Q3 snapshot
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA CORE;

CREATE OR REPLACE TABLE
    CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_SNAPSHOT AS

SELECT
    s.CUSTOMER_ID,

    -- Snapshot context
    s.QUARTER AS SNAPSHOT_QUARTER,

    -- Lifecycle
    sv.TENURE_IN_MONTHS,

    CASE
        WHEN sv.TENURE_IN_MONTHS <= 6 THEN '0-6 months'
        WHEN sv.TENURE_IN_MONTHS <= 12 THEN '7-12 months'
        WHEN sv.TENURE_IN_MONTHS <= 24 THEN '13-24 months'
        WHEN sv.TENURE_IN_MONTHS <= 48 THEN '25-48 months'
        WHEN sv.TENURE_IN_MONTHS <= 60 THEN '49-60 months'
        ELSE '61+ months'
    END AS TENURE_BAND,

    -- Customer status / churn outcome
    s.CUSTOMER_STATUS,
    s.CHURN_LABEL,
    s.CHURN_VALUE,
    IFF(s.CHURN_VALUE = 1, 1, 0) AS CHURN_FLAG,
    s.CHURN_SCORE,

    -- Experience
    s.SATISFACTION_SCORE,

    CASE
        WHEN s.SATISFACTION_SCORE <= 2 THEN 'Low'
        WHEN s.SATISFACTION_SCORE = 3 THEN 'Medium'
        WHEN s.SATISFACTION_SCORE >= 4 THEN 'High'
        ELSE 'Unknown'
    END AS SATISFACTION_BAND,

    -- Customer value
    s.CLTV,

    NTILE(4) OVER (ORDER BY s.CLTV) AS CLTV_QUARTILE,

    CASE
        WHEN NTILE(4) OVER (ORDER BY s.CLTV) = 1 THEN 'Low Value'
        WHEN NTILE(4) OVER (ORDER BY s.CLTV) = 2 THEN 'Mid-Low Value'
        WHEN NTILE(4) OVER (ORDER BY s.CLTV) = 3 THEN 'Mid-High Value'
        WHEN NTILE(4) OVER (ORDER BY s.CLTV) = 4 THEN 'High Value'
    END AS CUSTOMER_VALUE_SEGMENT,

    IFF(
        NTILE(4) OVER (ORDER BY s.CLTV) = 4,
        1,
        0
    ) AS HIGH_VALUE_FLAG,

    -- Reported churn explanation
    s.CHURN_CATEGORY,
    s.CHURN_REASON

FROM CUSTOMER_INTELLIGENCE.RAW.CHURN_STATUS s

LEFT JOIN CUSTOMER_INTELLIGENCE.RAW.CHURN_SERVICES sv
    ON s.CUSTOMER_ID = sv.CUSTOMER_ID;