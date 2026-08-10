-- ============================================================
-- Customer Intelligence Analytics Platform
-- CORE - Customer 360 View
-- Grain: one row per customer
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA CORE;

CREATE OR REPLACE VIEW
    CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_360_VIEW AS

SELECT

    -- ========================================================
    -- Customer Key
    -- ========================================================
    p.CUSTOMER_ID,


    -- ========================================================
    -- Customer Profile
    -- ========================================================
    p.GENDER,
    p.AGE,
    p.AGE_BAND,
    p.UNDER_30,
    p.SENIOR_CITIZEN,
    p.MARRIED,
    p.DEPENDENTS,
    p.NUMBER_OF_DEPENDENTS,


    -- ========================================================
    -- Geography
    -- ========================================================
    l.COUNTRY,
    l.STATE,
    l.CITY,
    l.ZIP_CODE,
    l.LATITUDE,
    l.LONGITUDE,
    l.POPULATION,


    -- ========================================================
    -- Customer Relationship / Referrals
    -- ========================================================
    sv.REFERRED_A_FRIEND,
    sv.NUMBER_OF_REFERRALS,


    -- ========================================================
    -- Commercial Offer / Product Relationship
    -- ========================================================
    sv.OFFER,
    sv.CONTRACT,
    sv.PAYMENT_METHOD,
    sv.PAPERLESS_BILLING,


    -- ========================================================
    -- Core Services
    -- ========================================================
    sv.PHONE_SERVICE,
    sv.MULTIPLE_LINES,
    sv.INTERNET_SERVICE,
    sv.INTERNET_TYPE,


    -- ========================================================
    -- Usage
    -- ========================================================
    sv.AVG_MONTHLY_LONG_DISTANCE_CHARGES,
    sv.AVG_MONTHLY_GB_DOWNLOAD,


    -- ========================================================
    -- Add-on Services
    -- ========================================================
    sv.ONLINE_SECURITY,
    sv.ONLINE_BACKUP,
    sv.DEVICE_PROTECTION_PLAN,
    sv.PREMIUM_TECH_SUPPORT,
    sv.STREAMING_TV,
    sv.STREAMING_MOVIES,
    sv.STREAMING_MUSIC,
    sv.UNLIMITED_DATA,


    -- ========================================================
    -- Product Adoption Features
    -- ========================================================
    sv.CORE_SERVICE_COUNT,
    sv.ADD_ON_SERVICE_COUNT,
    sv.TOTAL_SERVICE_COUNT,


    -- ========================================================
    -- Financials
    -- ========================================================
    sv.MONTHLY_CHARGE,
    sv.TOTAL_CHARGES,
    sv.TOTAL_REFUNDS,
    sv.TOTAL_EXTRA_DATA_CHARGES,
    sv.TOTAL_LONG_DISTANCE_CHARGES,
    sv.TOTAL_REVENUE,


    -- ========================================================
    -- Snapshot / Lifecycle
    -- ========================================================
    sn.SNAPSHOT_QUARTER,
    sn.TENURE_IN_MONTHS,
    sn.TENURE_BAND,


    -- ========================================================
    -- Customer Status / Churn
    -- ========================================================
    sn.CUSTOMER_STATUS,
    sn.CHURN_LABEL,
    sn.CHURN_VALUE,
    sn.CHURN_FLAG,
    sn.CHURN_SCORE,


    -- ========================================================
    -- Customer Experience
    -- ========================================================
    sn.SATISFACTION_SCORE,
    sn.SATISFACTION_BAND,


    -- ========================================================
    -- Customer Value
    -- ========================================================
    sn.CLTV,
    sn.CLTV_QUARTILE,
    sn.CUSTOMER_VALUE_SEGMENT,
    sn.HIGH_VALUE_FLAG,


    -- ========================================================
    -- Reported Churn Explanation
    -- ========================================================
    sn.CHURN_CATEGORY,
    sn.CHURN_REASON


FROM CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_PROFILE p

INNER JOIN CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_LOCATION l
    ON p.CUSTOMER_ID = l.CUSTOMER_ID

INNER JOIN CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_SERVICES sv
    ON p.CUSTOMER_ID = sv.CUSTOMER_ID

INNER JOIN CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_SNAPSHOT sn
    ON p.CUSTOMER_ID = sn.CUSTOMER_ID;