-- ============================================================
-- Customer Intelligence Analytics Platform
-- CORE - Customer Services
-- Grain: one row per customer
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA CORE;

CREATE OR REPLACE TABLE
    CUSTOMER_INTELLIGENCE.CORE.CUSTOMER_SERVICES AS

SELECT
    CUSTOMER_ID,

    -- Relationship / referral
    REFERRED_A_FRIEND,
    NUMBER_OF_REFERRALS,

    -- Commercial offer
    OFFER,

    -- Core services
    PHONE_SERVICE,
    MULTIPLE_LINES,
    INTERNET_SERVICE,
    INTERNET_TYPE,

    -- Usage
    AVG_MONTHLY_LONG_DISTANCE_CHARGES,
    AVG_MONTHLY_GB_DOWNLOAD,

    -- Add-on services
    ONLINE_SECURITY,
    ONLINE_BACKUP,
    DEVICE_PROTECTION_PLAN,
    PREMIUM_TECH_SUPPORT,
    STREAMING_TV,
    STREAMING_MOVIES,
    STREAMING_MUSIC,
    UNLIMITED_DATA,

    -- Commercial relationship
    CONTRACT,
    PAPERLESS_BILLING,
    PAYMENT_METHOD,

    -- Financials
    MONTHLY_CHARGE,
    TOTAL_CHARGES,
    TOTAL_REFUNDS,
    TOTAL_EXTRA_DATA_CHARGES,
    TOTAL_LONG_DISTANCE_CHARGES,
    TOTAL_REVENUE,

    -- --------------------------------------------------------
    -- Derived Product / Adoption Features
    -- --------------------------------------------------------

    (
        IFF(PHONE_SERVICE = 'Yes', 1, 0)
        + IFF(INTERNET_SERVICE = 'Yes', 1, 0)
    ) AS CORE_SERVICE_COUNT,

    (
        IFF(MULTIPLE_LINES = 'Yes', 1, 0)
        + IFF(ONLINE_SECURITY = 'Yes', 1, 0)
        + IFF(ONLINE_BACKUP = 'Yes', 1, 0)
        + IFF(DEVICE_PROTECTION_PLAN = 'Yes', 1, 0)
        + IFF(PREMIUM_TECH_SUPPORT = 'Yes', 1, 0)
        + IFF(STREAMING_TV = 'Yes', 1, 0)
        + IFF(STREAMING_MOVIES = 'Yes', 1, 0)
        + IFF(STREAMING_MUSIC = 'Yes', 1, 0)
        + IFF(UNLIMITED_DATA = 'Yes', 1, 0)
    ) AS ADD_ON_SERVICE_COUNT,

    (
        IFF(PHONE_SERVICE = 'Yes', 1, 0)
        + IFF(INTERNET_SERVICE = 'Yes', 1, 0)
        + IFF(MULTIPLE_LINES = 'Yes', 1, 0)
        + IFF(ONLINE_SECURITY = 'Yes', 1, 0)
        + IFF(ONLINE_BACKUP = 'Yes', 1, 0)
        + IFF(DEVICE_PROTECTION_PLAN = 'Yes', 1, 0)
        + IFF(PREMIUM_TECH_SUPPORT = 'Yes', 1, 0)
        + IFF(STREAMING_TV = 'Yes', 1, 0)
        + IFF(STREAMING_MOVIES = 'Yes', 1, 0)
        + IFF(STREAMING_MUSIC = 'Yes', 1, 0)
        + IFF(UNLIMITED_DATA = 'Yes', 1, 0)
    ) AS TOTAL_SERVICE_COUNT

FROM CUSTOMER_INTELLIGENCE.RAW.CHURN_SERVICES;