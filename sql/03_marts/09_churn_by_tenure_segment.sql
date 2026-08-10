-- ============================================================
-- Customer Intelligence Analytics Platform
-- ANALYTICS - Lifecycle Churn by Tenure & Segment
--
-- Grain:
-- one row per tenure month / dimension / segment
--
-- IMPORTANT:
-- Cross-sectional lifecycle approximation from one snapshot.
-- Not historical cohort retention.
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW
    CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_BY_TENURE_SEGMENT AS

WITH BASE AS (

    SELECT
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG,

        CONTRACT,
        CUSTOMER_VALUE_SEGMENT,
        PREMIUM_TECH_SUPPORT,

        CASE
            WHEN TOTAL_SERVICE_COUNT <= 2 THEN '1-2 Services'
            WHEN TOTAL_SERVICE_COUNT <= 4 THEN '3-4 Services'
            WHEN TOTAL_SERVICE_COUNT <= 7 THEN '5-7 Services'
            ELSE '8+ Services'
        END AS PRODUCT_DEPTH_SEGMENT

    FROM CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_360_VIEW

),

SEGMENTED_BASE AS (

    -- Contract
    SELECT
        'Contract' AS DIMENSION_NAME,
        CONTRACT AS SEGMENT_VALUE,
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG
    FROM BASE

    UNION ALL

    -- Customer Value
    SELECT
        'Customer Value',
        CUSTOMER_VALUE_SEGMENT,
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG
    FROM BASE

    UNION ALL

    -- Premium Tech Support
    SELECT
        'Premium Tech Support',
        PREMIUM_TECH_SUPPORT,
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG
    FROM BASE

    UNION ALL

    -- Product Depth
    SELECT
        'Product Depth',
        PRODUCT_DEPTH_SEGMENT,
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG
    FROM BASE

),

TENURE_SEGMENTS AS (

    SELECT DISTINCT
        DIMENSION_NAME,
        SEGMENT_VALUE,
        TENURE_IN_MONTHS AS TENURE_MONTH
    FROM SEGMENTED_BASE
    WHERE TENURE_IN_MONTHS IS NOT NULL

),

CURVE AS (

    SELECT

        ts.DIMENSION_NAME,
        ts.SEGMENT_VALUE,
        ts.TENURE_MONTH,

        COUNT_IF(
            b.TENURE_IN_MONTHS >= ts.TENURE_MONTH
        ) AS CUSTOMERS_REACHING_TENURE,

        COUNT_IF(
            b.CHURN_FLAG = 1
            AND b.TENURE_IN_MONTHS = ts.TENURE_MONTH
        ) AS CHURNED_AT_TENURE,

        ROUND(
            COUNT_IF(
                b.CHURN_FLAG = 1
                AND b.TENURE_IN_MONTHS = ts.TENURE_MONTH
            )
            /
            NULLIF(
                COUNT_IF(
                    b.TENURE_IN_MONTHS >= ts.TENURE_MONTH
                ),
                0
            ),
            4
        ) AS CHURN_RATE_AT_TENURE

    FROM TENURE_SEGMENTS ts

    JOIN SEGMENTED_BASE b
        ON ts.DIMENSION_NAME = b.DIMENSION_NAME
       AND ts.SEGMENT_VALUE = b.SEGMENT_VALUE

    GROUP BY
        ts.DIMENSION_NAME,
        ts.SEGMENT_VALUE,
        ts.TENURE_MONTH

)

SELECT

    DIMENSION_NAME,
    SEGMENT_VALUE,
    TENURE_MONTH,

    CUSTOMERS_REACHING_TENURE,
    CHURNED_AT_TENURE,
    CHURN_RATE_AT_TENURE,

    ROUND(
        AVG(CHURN_RATE_AT_TENURE) OVER (
            PARTITION BY DIMENSION_NAME, SEGMENT_VALUE
            ORDER BY TENURE_MONTH
            ROWS BETWEEN 1 PRECEDING AND 1 FOLLOWING
        ),
        4
    ) AS ROLLING_3M_CHURN_RATE,

    CASE
        WHEN CUSTOMERS_REACHING_TENURE >= 500 THEN 'High Support'
        WHEN CUSTOMERS_REACHING_TENURE >= 200 THEN 'Medium Support'
        ELSE 'Low Support'
    END AS BASE_SUPPORT_LEVEL

FROM CURVE

ORDER BY
    DIMENSION_NAME,
    SEGMENT_VALUE,
    TENURE_MONTH;