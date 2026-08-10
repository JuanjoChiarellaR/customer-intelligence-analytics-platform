-- ============================================================
-- Customer Intelligence Analytics Platform
-- 02 - Data Quality & Reconciliation
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA RAW;

-- ------------------------------------------------------------
-- 1. Row counts
-- ------------------------------------------------------------

SELECT 'CHURN_DEMOGRAPHICS' AS TABLE_NAME, COUNT(*) AS ROW_COUNT
FROM CHURN_DEMOGRAPHICS

UNION ALL

SELECT 'CHURN_LOCATION', COUNT(*)
FROM CHURN_LOCATION

UNION ALL

SELECT 'CHURN_POPULATION', COUNT(*)
FROM CHURN_POPULATION

UNION ALL

SELECT 'CHURN_SERVICES', COUNT(*)
FROM CHURN_SERVICES

UNION ALL

SELECT 'CHURN_STATUS', COUNT(*)
FROM CHURN_STATUS;


-- ------------------------------------------------------------
-- 2. Customer ID uniqueness
-- Each customer-level table should have exactly one row per customer
-- ------------------------------------------------------------

SELECT
    'CHURN_DEMOGRAPHICS' AS TABLE_NAME,
    COUNT(*) AS TOTAL_ROWS,
    COUNT(DISTINCT CUSTOMER_ID) AS DISTINCT_CUSTOMERS,
    COUNT(*) - COUNT(DISTINCT CUSTOMER_ID) AS DUPLICATE_ROWS
FROM CHURN_DEMOGRAPHICS

UNION ALL

SELECT
    'CHURN_LOCATION',
    COUNT(*),
    COUNT(DISTINCT CUSTOMER_ID),
    COUNT(*) - COUNT(DISTINCT CUSTOMER_ID)
FROM CHURN_LOCATION

UNION ALL

SELECT
    'CHURN_SERVICES',
    COUNT(*),
    COUNT(DISTINCT CUSTOMER_ID),
    COUNT(*) - COUNT(DISTINCT CUSTOMER_ID)
FROM CHURN_SERVICES

UNION ALL

SELECT
    'CHURN_STATUS',
    COUNT(*),
    COUNT(DISTINCT CUSTOMER_ID),
    COUNT(*) - COUNT(DISTINCT CUSTOMER_ID)
FROM CHURN_STATUS;


-- ------------------------------------------------------------
-- 3. Null Customer IDs
-- ------------------------------------------------------------

SELECT
    'CHURN_DEMOGRAPHICS' AS TABLE_NAME,
    COUNT_IF(CUSTOMER_ID IS NULL) AS NULL_CUSTOMER_IDS
FROM CHURN_DEMOGRAPHICS

UNION ALL

SELECT
    'CHURN_LOCATION',
    COUNT_IF(CUSTOMER_ID IS NULL)
FROM CHURN_LOCATION

UNION ALL

SELECT
    'CHURN_SERVICES',
    COUNT_IF(CUSTOMER_ID IS NULL)
FROM CHURN_SERVICES

UNION ALL

SELECT
    'CHURN_STATUS',
    COUNT_IF(CUSTOMER_ID IS NULL)
FROM CHURN_STATUS;


-- ------------------------------------------------------------
-- 4. Customer ID reconciliation across tables
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS DEMOGRAPHICS_CUSTOMERS,
    COUNT_IF(l.CUSTOMER_ID IS NULL) AS MISSING_LOCATION,
    COUNT_IF(s.CUSTOMER_ID IS NULL) AS MISSING_SERVICES,
    COUNT_IF(cs.CUSTOMER_ID IS NULL) AS MISSING_STATUS
FROM CHURN_DEMOGRAPHICS d
LEFT JOIN CHURN_LOCATION l
    ON d.CUSTOMER_ID = l.CUSTOMER_ID
LEFT JOIN CHURN_SERVICES s
    ON d.CUSTOMER_ID = s.CUSTOMER_ID
LEFT JOIN CHURN_STATUS cs
    ON d.CUSTOMER_ID = cs.CUSTOMER_ID;


-- ------------------------------------------------------------
-- 5. ZIP Code reconciliation
-- ------------------------------------------------------------

SELECT
    COUNT(*) AS CUSTOMER_ROWS,
    COUNT_IF(p.ZIP_CODE IS NULL) AS CUSTOMERS_WITHOUT_POPULATION_MATCH
FROM CHURN_LOCATION l
LEFT JOIN CHURN_POPULATION p
    ON l.ZIP_CODE = p.ZIP_CODE;


-- ------------------------------------------------------------
-- 6. Churn distribution
-- ------------------------------------------------------------

SELECT
    CHURN_LABEL,
    CHURN_VALUE,
    COUNT(*) AS CUSTOMERS,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS PCT_CUSTOMERS
FROM CHURN_STATUS
GROUP BY CHURN_LABEL, CHURN_VALUE
ORDER BY CHURN_VALUE;


-- ------------------------------------------------------------
-- 7. Customer status distribution
-- ------------------------------------------------------------

SELECT
    CUSTOMER_STATUS,
    COUNT(*) AS CUSTOMERS,
    ROUND(
        COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (),
        2
    ) AS PCT_CUSTOMERS
FROM CHURN_STATUS
GROUP BY CUSTOMER_STATUS
ORDER BY CUSTOMERS DESC;


-- ------------------------------------------------------------
-- 8. Churn field consistency
-- CHURN_LABEL and CHURN_VALUE should represent the same outcome
-- ------------------------------------------------------------

SELECT
    CHURN_LABEL,
    CHURN_VALUE,
    COUNT(*) AS CUSTOMERS
FROM CHURN_STATUS
GROUP BY CHURN_LABEL, CHURN_VALUE
ORDER BY CHURN_LABEL, CHURN_VALUE;


-- ------------------------------------------------------------
-- 9. Basic numeric validation
-- ------------------------------------------------------------

SELECT
    MIN(TENURE_IN_MONTHS) AS MIN_TENURE,
    MAX(TENURE_IN_MONTHS) AS MAX_TENURE,
    MIN(MONTHLY_CHARGE) AS MIN_MONTHLY_CHARGE,
    MAX(MONTHLY_CHARGE) AS MAX_MONTHLY_CHARGE,
    MIN(TOTAL_REVENUE) AS MIN_TOTAL_REVENUE,
    MAX(TOTAL_REVENUE) AS MAX_TOTAL_REVENUE
FROM CHURN_SERVICES;


-- ------------------------------------------------------------
-- 10. Churn-specific null analysis
-- ------------------------------------------------------------

SELECT
    CHURN_LABEL,
    COUNT(*) AS CUSTOMERS,
    COUNT_IF(CHURN_CATEGORY IS NULL) AS NULL_CHURN_CATEGORY,
    COUNT_IF(CHURN_REASON IS NULL) AS NULL_CHURN_REASON
FROM CHURN_STATUS
GROUP BY CHURN_LABEL
ORDER BY CHURN_LABEL;


-- ------------------------------------------------------------
-- 11. Quarter consistency
-- ------------------------------------------------------------

SELECT
    'CHURN_SERVICES' AS TABLE_NAME,
    QUARTER,
    COUNT(*) AS ROW_COUNT
FROM CHURN_SERVICES
GROUP BY QUARTER

UNION ALL

SELECT
    'CHURN_STATUS',
    QUARTER,
    COUNT(*)
FROM CHURN_STATUS
GROUP BY QUARTER;