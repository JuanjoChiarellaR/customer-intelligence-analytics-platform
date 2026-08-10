-- ============================================================
-- Customer Intelligence Analytics Platform
-- ANALYTICS - Product Adoption
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW
    CUSTOMER_INTELLIGENCE.ANALYTICS.VW_PRODUCT_ADOPTION AS

WITH BASE AS (

    SELECT *
    FROM CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_360_VIEW

),

PRODUCTS AS (

    SELECT
        'Phone Service' AS PRODUCT_NAME,
        PHONE_SERVICE AS ADOPTION_STATUS,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Multiple Lines',
        MULTIPLE_LINES,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Internet Service',
        INTERNET_SERVICE,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Online Security',
        ONLINE_SECURITY,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Online Backup',
        ONLINE_BACKUP,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Device Protection Plan',
        DEVICE_PROTECTION_PLAN,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Premium Tech Support',
        PREMIUM_TECH_SUPPORT,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Streaming TV',
        STREAMING_TV,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Streaming Movies',
        STREAMING_MOVIES,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Streaming Music',
        STREAMING_MUSIC,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

    UNION ALL

    SELECT
        'Unlimited Data',
        UNLIMITED_DATA,
        CUSTOMER_ID,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV,
        TENURE_IN_MONTHS
    FROM BASE

)

SELECT
    PRODUCT_NAME,
    COALESCE(ADOPTION_STATUS, 'Not Applicable') AS ADOPTION_STATUS,

    COUNT(DISTINCT CUSTOMER_ID) AS CUSTOMERS,

    ROUND(
        COUNT(DISTINCT CUSTOMER_ID)
        / SUM(COUNT(DISTINCT CUSTOMER_ID))
            OVER (PARTITION BY PRODUCT_NAME),
        4
    ) AS CUSTOMER_SHARE,

    COUNT_IF(CHURN_FLAG = 1) AS CHURNED_CUSTOMERS,

    ROUND(
        COUNT_IF(CHURN_FLAG = 1)
        / NULLIF(COUNT(DISTINCT CUSTOMER_ID), 0),
        4
    ) AS CHURN_RATE,

    ROUND(AVG(MONTHLY_CHARGE), 2) AS AVG_MONTHLY_CHARGE,

    ROUND(AVG(TOTAL_REVENUE), 2) AS AVG_TOTAL_REVENUE,

    ROUND(AVG(CLTV), 2) AS AVG_CLTV,

    ROUND(AVG(TENURE_IN_MONTHS), 2) AS AVG_TENURE_MONTHS

FROM PRODUCTS

GROUP BY
    PRODUCT_NAME,
    COALESCE(ADOPTION_STATUS, 'Not Applicable');