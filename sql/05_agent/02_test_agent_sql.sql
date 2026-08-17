-- ============================================================
-- CUSTOMER INTELLIGENCE AGENT - SQL INTEGRATION VALIDATION
-- ============================================================
--
-- Purpose:
-- Validate the Cortex Agent programmatically through
-- SNOWFLAKE.CORTEX.DATA_AGENT_RUN before integrating it
-- into the Streamlit application.
--
-- These tests were executed manually in Snowflake during
-- development and were used to inspect both Agent behavior
-- and the structure of the returned JSON payload.
--
-- This file is intended as a reproducible integration /
-- debugging reference, not as the full business evaluation
-- suite for the Agent.
-- ============================================================


USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;


-- ============================================================
-- TEST 01
-- Validate DATA_AGENT_RUN end-to-end
-- ============================================================
--
-- Confirms that the project role can call the Cortex Agent
-- programmatically and that the Agent can:
--
--   DATA_AGENT_RUN
--       -> Cortex Agent
--       -> Cortex Analyst
--       -> Semantic View
--       -> governed SQL
--       -> Agent response
--
-- The question intentionally matches a validated contract
-- churn use case.
-- ============================================================

SELECT
    TRY_PARSE_JSON(
        SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            'CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT',
            $${
              "messages": [
                {
                  "role": "user",
                  "content": [
                    {
                      "type": "text",
                      "text": "Compare churn rate and contribution across contract types."
                    }
                  ]
                }
              ]
            }$$
        )
    ) AS RESPONSE;



-- ============================================================
-- TEST 02
-- Inspect Agent response content structure
-- ============================================================
--
-- DATA_AGENT_RUN returns a structured JSON response.
--
-- This test flattens RESPONSE:content so the individual
-- response artifacts can be inspected independently.
--
-- Observed response types include:
-- - thinking
-- - tool_use
-- - tool_result
-- - text
-- - table
-- - chart
-- - suggested_queries
--
-- This inspection informed the Streamlit response renderer.
-- ============================================================

WITH AGENT_RESPONSE AS (

    SELECT TRY_PARSE_JSON(
        SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            'CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT',
            $${
              "messages": [
                {
                  "role": "user",
                  "content": [
                    {
                      "type": "text",
                      "text": "Compare churn rate and contribution across contract types."
                    }
                  ]
                }
              ]
            }$$
        )
    ) AS RESPONSE

),

CONTENT_ITEMS AS (

    SELECT
        f.index AS CONTENT_INDEX,
        f.value:type::STRING AS CONTENT_TYPE,
        f.value AS CONTENT

    FROM AGENT_RESPONSE,
    LATERAL FLATTEN(
        input => RESPONSE:content
    ) f

)

SELECT
    CONTENT_INDEX,
    CONTENT_TYPE,
    CONTENT

FROM CONTENT_ITEMS

ORDER BY CONTENT_INDEX;



-- ============================================================
-- TEST 03
-- Extract business and technical Agent artifacts
-- ============================================================
--
-- This test was used to validate that the DATA_AGENT_RUN
-- response exposes the information required by Streamlit.
--
-- Business-facing artifacts:
-- - narrative text
-- - table result
-- - Vega-Lite chart specification
-- - suggested follow-up questions
--
-- Technical / observability artifacts:
-- - generated SQL
-- - Verified Query usage flag
-- - Snowflake Query ID
-- - model name
-- - token usage
--
-- Important:
-- The Agent may return multiple text blocks interleaved with
-- tables and charts. The final Streamlit implementation
-- therefore preserves RESPONSE:content order instead of using
-- FINAL_ANSWER as the complete user response.
-- ============================================================

WITH AGENT_RESPONSE AS (

    SELECT TRY_PARSE_JSON(
        SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            'CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT',
            $${
              "messages": [
                {
                  "role": "user",
                  "content": [
                    {
                      "type": "text",
                      "text": "Compare churn rate and contribution across contract types."
                    }
                  ]
                }
              ]
            }$$
        )
    ) AS RESPONSE

),

CONTENT_ITEMS AS (

    SELECT
        f.index AS CONTENT_INDEX,
        f.value:type::STRING AS CONTENT_TYPE,
        f.value AS CONTENT

    FROM AGENT_RESPONSE,
    LATERAL FLATTEN(
        input => RESPONSE:content
    ) f

),

SQL_RESULT AS (

    SELECT
        CONTENT:tool_result:content[0]:json:sql::STRING
            AS GENERATED_SQL,

        CONTENT:tool_result:content[0]:json:verified_query_used::BOOLEAN
            AS VERIFIED_QUERY_USED,

        CONTENT:tool_result:content[0]:json:query_id::STRING
            AS QUERY_ID

    FROM CONTENT_ITEMS

    WHERE CONTENT_TYPE = 'tool_result'
      AND CONTENT:tool_result:name::STRING = 'system_execute_sql'

    QUALIFY ROW_NUMBER() OVER (
        ORDER BY CONTENT_INDEX DESC
    ) = 1

),

FINAL_TEXT AS (

    SELECT
        CONTENT:text::STRING AS FINAL_ANSWER

    FROM CONTENT_ITEMS

    WHERE CONTENT_TYPE = 'text'

    QUALIFY ROW_NUMBER() OVER (
        ORDER BY CONTENT_INDEX DESC
    ) = 1

),

TABLE_RESULT AS (

    SELECT
        CONTENT:table AS TABLE_CONTENT

    FROM CONTENT_ITEMS

    WHERE CONTENT_TYPE = 'table'

    QUALIFY ROW_NUMBER() OVER (
        ORDER BY CONTENT_INDEX DESC
    ) = 1

),

CHART_RESULT AS (

    SELECT
        CONTENT:chart:chart_spec::STRING AS CHART_SPEC

    FROM CONTENT_ITEMS

    WHERE CONTENT_TYPE = 'chart'

    QUALIFY ROW_NUMBER() OVER (
        ORDER BY CONTENT_INDEX DESC
    ) = 1

),

SUGGESTIONS AS (

    SELECT
        CONTENT:suggested_queries AS SUGGESTED_QUERIES

    FROM CONTENT_ITEMS

    WHERE CONTENT_TYPE = 'suggested_queries'

    QUALIFY ROW_NUMBER() OVER (
        ORDER BY CONTENT_INDEX DESC
    ) = 1

),

USAGE_METADATA AS (

    SELECT
        RESPONSE:metadata:usage:tokens_consumed[0]:model_name::STRING
            AS MODEL_NAME,

        RESPONSE:metadata:usage:tokens_consumed[0]:input_tokens:total::NUMBER
            AS INPUT_TOKENS,

        RESPONSE:metadata:usage:tokens_consumed[0]:input_tokens:cache_read::NUMBER
            AS CACHE_READ_TOKENS,

        RESPONSE:metadata:usage:tokens_consumed[0]:input_tokens:cache_write::NUMBER
            AS CACHE_WRITE_TOKENS,

        RESPONSE:metadata:usage:tokens_consumed[0]:input_tokens:uncached::NUMBER
            AS UNCACHED_INPUT_TOKENS,

        RESPONSE:metadata:usage:tokens_consumed[0]:output_tokens:total::NUMBER
            AS OUTPUT_TOKENS

    FROM AGENT_RESPONSE

)

SELECT
    FINAL_TEXT.FINAL_ANSWER,

    TABLE_RESULT.TABLE_CONTENT,

    CHART_RESULT.CHART_SPEC,

    SUGGESTIONS.SUGGESTED_QUERIES,

    SQL_RESULT.GENERATED_SQL,

    SQL_RESULT.VERIFIED_QUERY_USED,

    SQL_RESULT.QUERY_ID,

    USAGE_METADATA.MODEL_NAME,

    USAGE_METADATA.INPUT_TOKENS,

    USAGE_METADATA.CACHE_READ_TOKENS,

    USAGE_METADATA.CACHE_WRITE_TOKENS,

    USAGE_METADATA.UNCACHED_INPUT_TOKENS,

    USAGE_METADATA.OUTPUT_TOKENS

FROM FINAL_TEXT
CROSS JOIN TABLE_RESULT
CROSS JOIN CHART_RESULT
CROSS JOIN SUGGESTIONS
CROSS JOIN SQL_RESULT
CROSS JOIN USAGE_METADATA;
