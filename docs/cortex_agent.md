# Cortex Agent

## Purpose

`CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT` is a Snowflake Cortex Agent that sits on top of Cortex Analyst. Its job is not to duplicate Cortex Analyst's text-to-SQL capability — it's to **orchestrate** around it: route business questions to the right tool, and enforce the platform's analytical guardrails at a layer that survives even when the underlying model's self-reported reasoning doesn't (see [Analyst vs. Agent](#analyst-vs-agent) below for a concrete case where this mattered).

Configuration is versioned in [`sql/05_agent/01_configure_customer_intelligence_agent.sql`](../sql/05_agent/01_configure_customer_intelligence_agent.sql). The agent object itself was created via Snowsight; its live specification was set with `ALTER AGENT ... MODIFY LIVE VERSION SET SPECIFICATION = $$ ... $$` — that is the exact command captured in the file, not `CREATE OR REPLACE AGENT ... FROM SPECIFICATION`. The executable block in that file contains **only** the `tools` and `tool_resources` configuration (tool type, tool name, semantic view, execution environment) — that is the part actually tested and validated live. The source of truth is the live object; this SQL is checked in to close the gap between that live object and the repository.

## Architecture

The Agent has exactly one tool:

| Tool name | Type | Points at |
|---|---|---|
| `analyst_customer_intelligence` | `cortex_analyst_text_to_sql` | `CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_VIEW` |

The tool's `tool_resources` specify an `execution_environment` of type `warehouse`, pointed at `CUSTOMER_INTELLIGENCE_WH` — the same warehouse used throughout the rest of the platform, so query execution is billed and monitored consistently with everything else.

**A configuration note worth keeping:** an earlier attempt added a second tool of type `cortex_analyst_sql_exec` alongside the text-to-SQL tool. Snowflake rejected it outright with `"Tool type cortex_analyst_sql_exec is not valid."` The Agent uses only `cortex_analyst_text_to_sql` — that single tool both generates and executes the SQL.

## Orchestration and response instructions

**These guardrails were configured through the Agent's "Instructions" UI in Snowsight, not typed into the SQL file.** The executable specification in `sql/05_agent/01_configure_customer_intelligence_agent.sql` contains only the `tools`/`tool_resources` block described above. What follows is a conceptual description of the instructions, written to match the platform's documented guardrails and the behavior observed live (see [The historical-period test](#the-historical-period-test) below) — it is not a verified verbatim transcript of the exact text entered in the Agent UI.

The Agent's instructions are split into three parts, matching Snowflake's agent specification shape:

- **`system`** — establishes the Agent's role and that it has no data source other than the `analyst_customer_intelligence` tool.
- **`orchestration`** — routes quantitative questions to that tool rather than answering from general knowledge, and instructs the Agent not to silently "fix" or reinterpret a tool result that looks inconsistent with the question.
- **`response`** — the guardrail layer, applied to every answer regardless of what the tool itself returns:

  1. **Unsupported historical periods** — the dataset is a single snapshot, not a time series; questions about specific past periods ("last year," "last quarter") should be disclosed as unanswerable, not silently answered with current-snapshot numbers.
  2. **Predictive churn** — no predictive model exists; observed metrics must not be presented as predicted probabilities.
  3. **Cohort / survival analysis** — tenure-based churn curves are cross-sectional approximations, never described as cohort retention or survival analysis, and always shown with their supporting population.
  4. **Causal interpretation** — segment/product churn differences are associations, never described as causal effects.
  5. **Future revenue-at-risk** — churn-associated revenue figures describe customers already churned, never a forecast.
  6. **Unknown CLTV methodology** — CLTV is source-provided; its formula is not known and must not be invented.
  7. **Ambiguous questions** — ambiguous terms like "biggest" churn problem should prompt a clarifying question rather than an assumed interpretation.
  8. **Observed vs. predicted** — every figure is framed as an observed outcome in the snapshot, not a forecast.

These mirror the guardrails already encoded in the semantic view's `module_custom_instructions` (see the [README's semantic layer section](../README.md#semantic-layer)) — the Agent layer restates them at the orchestration/response level rather than relying solely on the semantic model to enforce them.

## Analyst vs. Agent

| | Cortex Analyst alone | Customer Intelligence Agent |
|---|---|---|
| Tool access | Direct semantic-view querying | Wraps Cortex Analyst as a tool |
| Guardrails | Encoded in the semantic view's custom instructions | Re-enforced at the orchestration/response layer |
| Failure mode observed | Can acknowledge a limitation in prose while still returning a number that answers the question anyway | Designed to refuse/disclose rather than silently substitute |

### The historical-period test

**Question:** *"What was the churn rate last year?"*

- **Cortex Analyst alone: FAIL.** It recognized the snapshot limitation in its explanation, but still returned the current snapshot's churn rate as if it answered the historical question — see T10 in [`docs/cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md).
- **Customer Intelligence Agent: PASS.** The Agent correctly responded that the dataset is a point-in-time snapshot and cannot provide a historical last-year churn rate, without substituting the current figure.

This is the concrete evidence for the value of the orchestration layer: guardrail *instructions* alone (in the semantic view) were not sufficient to prevent a silent substitution; guardrail *enforcement* at the Agent layer was.

## Current limitations

- **No Cortex Search Service.** All data here is structured (SQL tables/views); there is no unstructured document corpus, so Search is intentionally not part of this Agent. It will only be introduced if a genuine unstructured data source is added to the project.
- **No Skills.** The Agent has a single tool today; it does not yet compose multiple specialized skills.
- **No MCP integration.** Exposing this Agent (or its tools) over MCP is on the roadmap, not implemented.
- **Guardrail testing against the Agent is not yet as exhaustive as the Cortex-Analyst-alone suite.** Only the historical-period case above has been explicitly compared Analyst-vs-Agent so far; running the full T01–T14 suite against the Agent is future work (see [`docs/cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md#future-cortex-agent-comparison)).
