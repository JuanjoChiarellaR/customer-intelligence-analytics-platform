# Cortex Analyst Evaluation Results

## Purpose

This document reports the results of Snowflake's **native Cortex Analyst Evaluations** feature run against the Customer Intelligence semantic view's Verified Queries. It measures a narrower, more mechanical thing than [`docs/cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md): whether Cortex Analyst reproduces analytically equivalent SQL for a Verified Query's question when that query is temporarily excluded from the semantic model, evaluated automatically by Snowflake.

The two evaluation efforts are complementary, not the same:

| | Native Cortex Analyst Evaluations (this document) | Manual guardrail suite ([evaluation plan](cortex_analyst_evaluation_plan.md)) |
|---|---|---|
| Question count | 8 Verified Queries | 14 test cases (T01–T14) |
| Measures | Can Cortex Analyst reproduce the expected SQL/result? | Does Cortex Analyst behave correctly on business intent, guardrails, and ambiguity? |
| Output | A single accuracy percentage | Pass/fail per test case, with root-cause notes |
| Run by | Snowflake's built-in evaluation harness | Manual question-by-question testing in Snowsight |

## Evaluation progression

**v1 — baseline**
- Accuracy: **50%** (4 of 8 Verified Queries)
- Manual root-cause analysis of the four failures found they were driven primarily by **Verified Query output-specification mismatches** — the SQL logic Cortex Analyst generated was analytically reasonable, but its output column selection or shape didn't match what the Verified Query's `sql` block specified as "correct." This is a distinction worth being explicit about: a 50% score here does not mean half the underlying analytical logic was wrong.

**v1.1 — after correcting Verified Query specifications**
- Accuracy: **88%** (7 of 8)
- Query regressions: 1 (a query that had previously passed at v1 regressed after other Verified Queries were edited)

**v1.2 — after correcting the remaining CLTV Verified Query**
- Accuracy: **100%** (8 of 8)
- Query regressions: **0**
- Latency: P50 ≈ **4.0 seconds**, P95 ≈ **4.6 seconds**

## What this progression demonstrates

The failures at v1 were not primarily failures of the underlying analytical model (the ANALYTICS marts, the governed metrics, or the semantic view's dimensions/facts) — they were failures of the **Verified Query ground truth itself**: how precisely a Verified Query's expected SQL specified its output columns and shape. Refining that ground truth, rather than changing analytical logic, is what moved accuracy from 50% to 100%. This is treated as an important project result: semantic-layer engineering is iterative, and evaluation is what makes the iteration visible instead of anecdotal.

## A failure the native evaluation does not catch

Native evaluation accuracy measures reproducibility against Verified Queries — it does not test open-ended questions outside that set. One such question, part of the manual guardrail suite (T10 in [`cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md)):

> "What was the churn rate last year?"

Cortex Analyst correctly recognized the snapshot limitation in its explanation, but **still returned the current snapshot's churn rate as if it were an answer to the historical question** — a silent-substitution failure that a pure SQL-reproduction score would not surface. This result was a direct motivation for adding an orchestration/guardrail layer on top of Cortex Analyst — see [`docs/cortex_agent.md`](cortex_agent.md), where the same question passes when routed through the Customer Intelligence Agent instead of Cortex Analyst alone.

## Related documents

- [`docs/cortex_analyst_evaluation_plan.md`](cortex_analyst_evaluation_plan.md) — the 14-test-case manual guardrail/business evaluation suite and current per-test status.
- [`docs/cortex_agent.md`](cortex_agent.md) — the Cortex Agent built partly in response to the historical-period finding above.
- [`sql/04_semantic/customer_intelligence_view.yaml`](../sql/04_semantic/customer_intelligence_view.yaml) — the semantic view these evaluations are run against, now containing all 8 Verified Queries evaluated here (re-exported from Snowflake; previously only 4 were committed).
