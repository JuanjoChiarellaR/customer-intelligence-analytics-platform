-- ============================================================
-- Customer Intelligence Analytics Platform
-- 01 - Create RAW Tables
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA RAW;

-- ------------------------------------------------------------
-- 1. Customer Demographics
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE CHURN_DEMOGRAPHICS (
    CUSTOMER_ID              VARCHAR,
    COUNT                    NUMBER,
    GENDER                   VARCHAR,
    AGE                      NUMBER,
    UNDER_30                 VARCHAR,
    SENIOR_CITIZEN           VARCHAR,
    MARRIED                  VARCHAR,
    DEPENDENTS               VARCHAR,
    NUMBER_OF_DEPENDENTS     NUMBER
);

-- ------------------------------------------------------------
-- 2. Customer Location
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE CHURN_LOCATION (
    CUSTOMER_ID              VARCHAR,
    COUNT                    NUMBER,
    COUNTRY                  VARCHAR,
    STATE                    VARCHAR,
    CITY                     VARCHAR,
    ZIP_CODE                 NUMBER,
    LAT_LONG                 VARCHAR,
    LATITUDE                 FLOAT,
    LONGITUDE                FLOAT
);

-- ------------------------------------------------------------
-- 3. Population by ZIP Code
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE CHURN_POPULATION (
    ID                       NUMBER,
    ZIP_CODE                 NUMBER,
    POPULATION               NUMBER
);

-- ------------------------------------------------------------
-- 4. Customer Services
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE CHURN_SERVICES (
    CUSTOMER_ID                          VARCHAR,
    COUNT                                NUMBER,
    QUARTER                              VARCHAR,
    REFERRED_A_FRIEND                    VARCHAR,
    NUMBER_OF_REFERRALS                  NUMBER,
    TENURE_IN_MONTHS                     NUMBER,
    OFFER                                VARCHAR,
    PHONE_SERVICE                        VARCHAR,
    AVG_MONTHLY_LONG_DISTANCE_CHARGES    FLOAT,
    MULTIPLE_LINES                       VARCHAR,
    INTERNET_SERVICE                     VARCHAR,
    INTERNET_TYPE                        VARCHAR,
    AVG_MONTHLY_GB_DOWNLOAD              NUMBER,
    ONLINE_SECURITY                      VARCHAR,
    ONLINE_BACKUP                        VARCHAR,
    DEVICE_PROTECTION_PLAN               VARCHAR,
    PREMIUM_TECH_SUPPORT                 VARCHAR,
    STREAMING_TV                         VARCHAR,
    STREAMING_MOVIES                     VARCHAR,
    STREAMING_MUSIC                      VARCHAR,
    UNLIMITED_DATA                       VARCHAR,
    CONTRACT                             VARCHAR,
    PAPERLESS_BILLING                    VARCHAR,
    PAYMENT_METHOD                       VARCHAR,
    MONTHLY_CHARGE                       FLOAT,
    TOTAL_CHARGES                        FLOAT,
    TOTAL_REFUNDS                        FLOAT,
    TOTAL_EXTRA_DATA_CHARGES             NUMBER,
    TOTAL_LONG_DISTANCE_CHARGES          FLOAT,
    TOTAL_REVENUE                        FLOAT
);

-- ------------------------------------------------------------
-- 5. Customer Churn Status
-- ------------------------------------------------------------

CREATE OR REPLACE TABLE CHURN_STATUS (
    CUSTOMER_ID              VARCHAR,
    COUNT                    NUMBER,
    QUARTER                  VARCHAR,
    SATISFACTION_SCORE       NUMBER,
    CUSTOMER_STATUS          VARCHAR,
    CHURN_LABEL              VARCHAR,
    CHURN_VALUE              NUMBER,
    CHURN_SCORE              NUMBER,
    CLTV                     NUMBER,
    CHURN_CATEGORY           VARCHAR,
    CHURN_REASON             VARCHAR
);

-- ------------------------------------------------------------
-- 6. Validation
-- ------------------------------------------------------------

SHOW TABLES IN SCHEMA CUSTOMER_INTELLIGENCE.RAW;