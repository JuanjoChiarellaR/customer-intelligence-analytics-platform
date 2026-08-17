-- ============================================================
-- Customer Intelligence Analytics Platform
-- Cortex Agent Configuration
-- ============================================================
-- Purpose:
-- Record the specification applied to
-- CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT,
-- a Cortex Agent that orchestrates Cortex Analyst (rather than
-- duplicating it) on top of the governed Customer Intelligence
-- semantic view.
--
-- IMPORTANT -- command actually validated live:
-- The agent object itself was created via Snowsight. Its live
-- specification was set with:
--
--   ALTER AGENT CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT
--   MODIFY LIVE VERSION SET SPECIFICATION = $$ ... $$;
--
-- That is the command captured below and the one actually tested
-- in Snowsight. Do NOT replace it with CREATE OR REPLACE AGENT ...
-- FROM SPECIFICATION -- that syntax was not what was executed or
-- validated for this object.
--
-- IMPORTANT -- what is exact vs. conceptual:
-- The executable block below (tools + tool_resources: tool type
-- cortex_analyst_text_to_sql, tool name analyst_customer_intelligence,
-- semantic view, execution_environment/warehouse) is the exact
-- configuration pattern tested and validated live -- nothing more.
--
-- The Agent's orchestration/response guardrails (unsupported
-- historical periods, predictive churn, cohort/survival framing,
-- causal interpretation, future revenue-at-risk, unknown CLTV
-- methodology, ambiguous questions, observed-vs-predicted framing)
-- were configured through the Agent's "Instructions" UI in
-- Snowsight, not typed into this SQL file. They are documented
-- conceptually below and in docs/cortex_agent.md, reflecting the
-- platform's known guardrails and the behavior observed live. This
-- is NOT a verified verbatim transcript of the exact text entered
-- in the Agent UI -- treat it as documentation, not as executable
-- specification, until the live agent's instructions are exported
-- and diffed against it.
--
-- Documented guardrails (see docs/cortex_agent.md for full detail):
--   1. Unsupported historical periods -- disclose the snapshot
--      limitation rather than answering with current-snapshot data.
--   2. Predictive churn -- do not convert observed metrics into
--      predicted churn probabilities.
--   3. Cohort / survival analysis -- CHURN_RATE_AT_TENURE is a
--      cross-sectional approximation, never cohort retention or a
--      survival curve; always show it with CUSTOMERS_REACHING_TENURE.
--   4. Causal interpretation -- segment/product churn differences
--      are associations, not causal effects.
--   5. Future revenue-at-risk -- churned monthly/historical revenue
--      describes customers already churned, never a forecast.
--   6. Unknown CLTV methodology -- CLTV is source-provided; never
--      invent its formula.
--   7. Ambiguous questions -- clarify ambiguous terms like "biggest"
--      churn problem before answering.
--   8. Observed vs. predicted -- frame every figure as an observed
--      outcome in the snapshot, never a forecast.
--
-- Do NOT add a second tool of type "cortex_analyst_sql_exec".
-- That configuration was tested live and rejected by Snowflake with:
--   "Tool type cortex_analyst_sql_exec is not valid."
-- The only supported/valid tool here is "cortex_analyst_text_to_sql".
-- ============================================================

USE ROLE CUSTOMER_INTELLIGENCE_ROLE;
USE WAREHOUSE CUSTOMER_INTELLIGENCE_WH;
USE DATABASE CUSTOMER_INTELLIGENCE;
USE SCHEMA SEMANTIC;

ALTER AGENT CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT
MODIFY LIVE VERSION SET SPECIFICATION =
$$
{
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "analyst_customer_intelligence"
      }
    }
  ],
  "tool_resources": {
    "analyst_customer_intelligence": {
      "semantic_view": "CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_VIEW",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "CUSTOMER_INTELLIGENCE_WH"
      }
    }
  }
}
$$;

-- ------------------------------------------------------------
-- Verification
-- ------------------------------------------------------------

SHOW AGENTS IN SCHEMA CUSTOMER_INTELLIGENCE.SEMANTIC;
DESCRIBE AGENT CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT;
