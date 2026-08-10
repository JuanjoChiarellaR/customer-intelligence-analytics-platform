-- ============================================================
-- Customer Intelligence Analytics Platform
-- ANALYTICS - Lifecycle Churn by Tenure
--
-- Purpose:
-- Estimate the observed churn profile across customer tenure
-- using the latest customer snapshot.
--
-- IMPORTANT:
-- This is NOT a historical cohort retention curve.
-- It is a cross-sectional churn-by-tenure approximation.
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA ANALYTICS;

CREATE OR REPLACE VIEW
    CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_BY_TENURE AS

WITH BASE AS (

    SELECT
        CUSTOMER_ID,
        TENURE_IN_MONTHS,
        CHURN_FLAG,
        MONTHLY_CHARGE,
        TOTAL_REVENUE,
        CLTV
    FROM CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_360_VIEW

),

TENURE_MONTHS AS (

    SELECT DISTINCT TENURE_IN_MONTHS AS TENURE_MONTH
    FROM BASE
    WHERE TENURE_IN_MONTHS IS NOT NULL

),

TOTAL_CHURN AS (

    SELECT COUNT_IF(CHURN_FLAG = 1) AS TOTAL_CHURNED_CUSTOMERS
    FROM BASE

)

SELECT

    t.TENURE_MONTH,

    -- Customers whose observed lifecycle reached this tenure
    COUNT_IF(
        b.TENURE_IN_MONTHS >= t.TENURE_MONTH
    ) AS CUSTOMERS_REACHING_TENURE,

    -- Customers observed to churn at exactly this tenure
    COUNT_IF(
        b.CHURN_FLAG = 1
        AND b.TENURE_IN_MONTHS = t.TENURE_MONTH
    ) AS CHURNED_AT_TENURE,

    -- Churn rate among customers that reached this tenure
    ROUND(
        COUNT_IF(
            b.CHURN_FLAG = 1
            AND b.TENURE_IN_MONTHS = t.TENURE_MONTH
        )
        /
        NULLIF(
            COUNT_IF(
                b.TENURE_IN_MONTHS >= t.TENURE_MONTH
            ),
            0
        ),
        4
    ) AS CHURN_RATE_AT_TENURE,

    -- Contribution of this tenure month to total observed churn
    ROUND(
        COUNT_IF(
            b.CHURN_FLAG = 1
            AND b.TENURE_IN_MONTHS = t.TENURE_MONTH
        )
        /
        NULLIF(MAX(tc.TOTAL_CHURNED_CUSTOMERS), 0),
        4
    ) AS CHURN_CONTRIBUTION,

    -- Financial profile of customers churned at this tenure
    ROUND(
        AVG(
            IFF(
                b.CHURN_FLAG = 1
                AND b.TENURE_IN_MONTHS = t.TENURE_MONTH,
                b.MONTHLY_CHARGE,
                NULL
            )
        ),
        2
    ) AS AVG_MONTHLY_CHARGE_CHURNED,

    ROUND(
        AVG(
            IFF(
                b.CHURN_FLAG = 1
                AND b.TENURE_IN_MONTHS = t.TENURE_MONTH,
                b.CLTV,
                NULL
            )
        ),
        2
    ) AS AVG_CLTV_CHURNED

FROM TENURE_MONTHS t

CROSS JOIN BASE b

CROSS JOIN TOTAL_CHURN tc

GROUP BY
    t.TENURE_MONTH

ORDER BY
    t.TENURE_MONTH;