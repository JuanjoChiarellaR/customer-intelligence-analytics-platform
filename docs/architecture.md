# Architecture

## End-to-end flow

```mermaid
flowchart TD
    A["Source files<br/>IBM Telco, 7,043 customers"]:::done --> B["RAW schema<br/>5 tables"]:::done
    B --> C["CORE schema<br/>CUSTOMER_360_VIEW"]:::done
    C --> D["ANALYTICS marts<br/>9 views"]:::done
    D --> E["Metric governance<br/>metric_dictionary.md"]:::done
    E --> F["SEMANTIC schema<br/>Semantic View"]:::done
    F --> G["Cortex Analyst"]:::done
    G -.-> X["Evaluation & guardrail testing<br/>native evaluations + T01–T14 suite"]:::partial

    U["Business user"]:::done --> S["Streamlit Dashboard"]:::done
    S -->|"5 executive sections<br/>direct SQL"| D
    S -->|"'Ask Customer Intelligence<br/>Agent' panel"| R["SNOWFLAKE.CORTEX.<br/>DATA_AGENT_RUN"]:::done
    R --> H["Cortex Agent<br/>CUSTOMER_INTELLIGENCE_AGENT"]:::done
    H --> G
    H -.->|"response: text, table, chart,<br/>suggested queries"| S
    H -.->|"observability: generated SQL,<br/>query ID, model, tokens"| T["Technical Details<br/>expander"]:::done
    T -.-> S

    classDef done fill:#e6f4ea,stroke:#34a853,stroke-width:1.5px,color:#1a1a1a;
    classDef partial fill:#fff8e1,stroke:#f9ab00,stroke-width:1.5px,color:#1a1a1a;
```

**Legend:** 🟢 Implemented and running · 🟡 Documented and partially automated (native Snowflake evaluations are automated; the broader guardrail suite is currently run manually).

## Reading the diagram

- **The Streamlit Dashboard has two independent, both-implemented paths into governed data.** Its five executive sections (`S → D`) query the ANALYTICS marts directly with SQL, exactly like before. Its "Ask Customer Intelligence Agent" panel (`S → R`) instead calls `SNOWFLAKE.CORTEX.DATA_AGENT_RUN`, which invokes the Cortex Agent (`R → H`).
- **`H → G` (Cortex Agent → Cortex Analyst) reflects that the Agent orchestrates Cortex Analyst as its one tool**, `analyst_customer_intelligence` (type `cortex_analyst_text_to_sql`) — it does not bypass Cortex Analyst or talk to the semantic view directly. See [`docs/cortex_agent.md`](cortex_agent.md#architecture).
- **The two dashed edges out of the Agent are the response path, not a separate data source.** One carries the business-facing content (narrative text, dynamic table, dynamic chart, suggested follow-up questions) straight into the Streamlit panel; the other carries execution observability (generated SQL, Verified Query flag, Query ID, model name, token usage) into the collapsed "Technical Details" expander. Both come from the same `DATA_AGENT_RUN` JSON response — see [`docs/cortex_agent.md`](cortex_agent.md#streamlit-integration) and [`docs/dashboard.md`](dashboard.md#ask-customer-intelligence-agent).
- **Evaluation and guardrail testing sits alongside `Cortex Analyst`, not inline in the main pipeline.** It's a cross-cutting activity, not a stage data flows through: the native Cortex Analyst Evaluations (100% accuracy at v1.2, see [`docs/cortex_analyst_evaluation_results.md`](cortex_analyst_evaluation_results.md)) are automated, while the 14-test-case business/guardrail suite (see [`docs/cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md)) is currently run manually — hence the intermediate ("documented and partially automated") styling. Separately, 4 end-to-end questions have been validated through the Agent via the deployed Streamlit app — see [`docs/cortex_agent.md`](cortex_agent.md#end-to-end-validation-streamlit--agent).

## What each stage owns

| Stage | Owns | Status |
|---|---|---|
| Source files | Raw IBM Telco Customer Churn extracts | Implemented |
| RAW | Source-shaped ingestion, minimal transformation | Implemented |
| CORE | Standardized one-row-per-customer entities + `CUSTOMER_360_VIEW` | Implemented |
| ANALYTICS | 9 purpose-built marts (churn segments, product adoption, lifecycle, etc.) | Implemented |
| Metric governance | Governed metric definitions and analytical principles | Implemented (`docs/metric_dictionary.md`); operational `VALIDATION.METRIC_DEFINITIONS` table exists live in Snowflake, SQL to reproduce it is not yet committed |
| Semantic View | Machine-readable governed contract for natural-language access | Implemented (4 of 9 ANALYTICS marts currently wired in) |
| Cortex Analyst | Natural-language → SQL over the semantic view | Implemented, evaluated (100% native accuracy at v1.2) |
| Cortex Agent | Orchestration + guardrail enforcement on top of Cortex Analyst | Implemented (single tool, response guardrails) |
| `DATA_AGENT_RUN` invocation | SQL entry point Streamlit uses to call the Agent | Implemented (`run_customer_intelligence_agent()`) |
| Streamlit Dashboard | Executive/business-facing view over the ANALYTICS marts, plus the Agent-integrated "Ask Customer Intelligence Agent" panel | Implemented, fully Agent-integrated |
| Observability / traceability | Generated SQL, Verified Query flag, Query ID, model name, token usage surfaced per response | Implemented (Technical Details expander) |
| Evaluation & guardrail testing | Native accuracy evaluation + manual T01–T14 suite + 4 end-to-end Agent validations | Partially automated |

This table intentionally does not include an automated AI-output-validation harness (a `sql/06_validation/` golden-test pipeline) — that remains planned, distinct from the evaluation work already done manually and via Snowflake's native evaluations.
