-- ============================================================
-- Customer Intelligence Analytics Platform
-- ANALYTICS - Churn Segmentation
-- Grain: one row per dimension / dimension value
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW
    CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_SEGMENTS AS

WITH BASE AS (

    SELECT *
    FROM CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_360_VIEW

),

TOTAL_CHURN AS (

    SELECT COUNT_IF(CHURN_FLAG = 1) AS TOTAL_CHURNED_CUSTOMERS
    FROM BASE

),

SEGMENTS AS (

    -- Contract
    SELECT
        'Contract' AS DIMENSION_NAME,
        CONTRACT AS SEGMENT_VALUE,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Payment Method
    SELECT
        'Payment Method',
        PAYMENT_METHOD,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Tenure Band
    SELECT
        'Tenure Band',
        TENURE_BAND,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Age Band
    SELECT
        'Age Band',
        AGE_BAND,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Offer
    SELECT
        'Offer',
        COALESCE(OFFER, 'No Offer'),
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Internet Type
    SELECT
        'Internet Type',
        COALESCE(INTERNET_TYPE, 'No Internet'),
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Customer Value
    SELECT
        'Customer Value',
        CUSTOMER_VALUE_SEGMENT,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

    UNION ALL

    -- Satisfaction
    SELECT
        'Satisfaction',
        SATISFACTION_BAND,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM BASE

)

SELECT

    s.DIMENSION_NAME,
    s.SEGMENT_VALUE,

    COUNT(DISTINCT s.CUSTOMER_ID) AS TOTAL_CUSTOMERS,

    COUNT_IF(s.CHURN_FLAG = 1) AS CHURNED_CUSTOMERS,

    ROUND(
        COUNT_IF(s.CHURN_FLAG = 1)
        / NULLIF(COUNT(DISTINCT s.CUSTOMER_ID), 0),
        4
    ) AS CHURN_RATE,

    ROUND(
        COUNT_IF(s.CHURN_FLAG = 1)
        / NULLIF(MAX(t.TOTAL_CHURNED_CUSTOMERS), 0),
        4
    ) AS CHURN_CONTRIBUTION,

    ROUND(
        AVG(s.MONTHLY_CHARGE),
        2
    ) AS AVG_MONTHLY_CHARGE,

    ROUND(
        AVG(s.CLTV),
        2
    ) AS AVG_CLTV,

    ROUND(
        SUM(IFF(s.CHURN_FLAG = 1, s.MONTHLY_CHARGE, 0)),
        2
    ) AS CHURNED_MONTHLY_REVENUE,

    ROUND(
        SUM(IFF(s.CHURN_FLAG = 1, s.TOTAL_REVENUE, 0)),
        2
    ) AS CHURNED_HISTORICAL_REVENUE

FROM SEGMENTS s

CROSS JOIN TOTAL_CHURN t

GROUP BY
    s.DIMENSION_NAME,
    s.SEGMENT_VALUE

ORDER BY
    s.DIMENSION_NAME,
    CHURN_RATE DESC;