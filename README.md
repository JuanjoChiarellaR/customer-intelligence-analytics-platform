# Customer Intelligence Analytics Platform

An end-to-end customer intelligence platform built on Snowflake, using telecom churn data to demonstrate how raw customer data becomes a governed analytical model, and how that governed model — not the AI layer — is what natural-language analytics should rely on.

Churn is the vehicle. The actual subject is the pipeline: **raw data → governed data model → analytical marts → metric governance → semantic layer → Cortex Analyst → AI validation → agent → business interface.** Several of these stages are fully built in Snowflake SQL and a working Cortex Analyst semantic model; the AI-agent, AI-validation, and Streamlit stages are scoped and documented but not yet implemented. Both states are called out explicitly throughout this document.

---

## Table of contents

1. [Why this project exists](#why-this-project-exists)
2. [Business problem and questions](#business-problem-and-questions)
3. [Data source and a critical limitation](#data-source-and-a-critical-limitation)
4. [Architecture](#architecture)
5. [Data pipeline and modeling layers](#data-pipeline-and-modeling-layers)
6. [Data quality and validation](#data-quality-and-validation)
7. [Analytical marts](#analytical-marts)
8. [Metric governance](#metric-governance)
9. [CLTV governance](#cltv-governance)
10. [Semantic layer](#semantic-layer)
11. [Cortex Analyst and AI analytics](#cortex-analyst-and-ai-analytics)
12. [AI validation strategy (planned)](#ai-validation-strategy-planned)
13. [Cortex Agent (planned)](#cortex-agent-planned)
14. [Business interface (planned)](#business-interface-planned)
15. [Key analytical insights](#key-analytical-insights)
16. [Repository structure](#repository-structure)
17. [Technology stack](#technology-stack)
18. [How to reproduce](#how-to-reproduce)
19. [Current status and roadmap](#current-status-and-roadmap)
20. [Design principles](#design-principles)

---

## Why this project exists

Most churn portfolio projects stop at a dashboard. This one is built around a different question: **what does it take for AI-generated analytics to be trustworthy?** The answer this project argues for is that trustworthy AI analytics are downstream of trustworthy analytics engineering, not a substitute for it. Concretely, that means building things in this order:

1. Preserve source truth (RAW layer, unmodified).
2. Standardize entities (CORE layer, one row per customer).
3. Build reusable analytical marts (ANALYTICS layer, purpose-built views).
4. Define governed metrics with explicit formulas and limitations (`docs/metric_dictionary.md`).
5. Encode business semantics into a machine-readable contract (Snowflake Semantic View).
6. Provide trusted, manually verified query examples (Cortex Analyst verified queries).
7. Add a natural-language interface on top of all of the above (Cortex Analyst).
8. Validate AI-generated answers against deterministic analytical truth (planned).
9. Only then expand toward autonomous agents and a user-facing application (planned).

Steps 1–7 are implemented in this repository. Steps 8 and 9 are scoped but not yet built — see [Current status and roadmap](#current-status-and-roadmap). The guiding principle is: **AI should consume governed analytical truth, not recreate business logic independently.**

---

## Business problem and questions

Business and product teams routinely need to answer questions like:

- What is the overall churn rate, and how many customers does that represent?
- Which customer segments have the highest churn *rate* — and separately, which contribute the largest *volume* of total churn?
- How does churn differ by contract type, payment method, or commercial offer?
- How does churn vary with product and service adoption?
- Which customer value (CLTV) segments show the highest churn?
- At what point in the customer lifecycle (observed tenure) does churn appear highest, and how large is the population supporting that observation?
- Which customer segments have the largest monthly charges associated with customers who have already churned?
- What do customers report as their reasons for churning?

Answering these reliably requires more than SQL access to raw data — it requires consistent definitions, reconciled data, purpose-built analytical models, and a shared vocabulary between people and AI systems. That is what the layers below are designed to provide. The platform deliberately keeps several related-but-distinct concepts separate rather than collapsing them into one number: **churn rate, churn volume, churn contribution, financial exposure, historical revenue, product adoption, and lifecycle churn are not interchangeable**, and the metric layer and semantic layer both enforce that distinction (see [Metric governance](#metric-governance)).

---

## Data source and a critical limitation

The source is the enhanced **IBM Telco Customer Churn** dataset: five related files — demographics, location, ZIP-level population, services/billing, and churn status — joinable on `Customer ID`, covering **7,043 customers**. A simpler "classic" version of the same dataset (`data/raw/ibm-telco-customer-churn-classic.csv`) is kept only as a reconciliation reference, not as an analytical source.

**This is a single customer-level snapshot (quarter `Q3` in the source data), not a historical time series.** There are no monthly customer snapshots and no reliable churn dates. This constrains what the platform can honestly claim:

- It **can** answer cross-sectional questions: how churn is distributed today across segments, products, value tiers, and observed tenure.
- It **cannot** answer genuinely historical or longitudinal questions: "how did churn change over the last 12 months," true cohort retention curves, or survival analysis — because the data required for those (repeated monthly observations of the same customers) does not exist in this dataset.

Every place in this platform where tenure-based analysis appears — SQL comments, the metric dictionary, and the Cortex Analyst guardrails — repeats this constraint deliberately. It is treated as a first-class analytical fact, not a footnote.

---

## Architecture

```mermaid
flowchart TD
    A["IBM Telco source data<br/>7,043 customers"]:::done --> B["RAW schema<br/>5 tables, source-shaped"]:::done
    B --> C["CORE schema<br/>standardized customer entities"]:::done
    C --> D["CUSTOMER_360_VIEW<br/>one row per customer"]:::done
    D --> E["ANALYTICS schema<br/>9 purpose-built marts"]:::done
    E --> F["Metric governance<br/>metric_dictionary.md"]:::done
    F --> G["SEMANTIC schema<br/>Cortex Analyst semantic view"]:::done
    G --> H["Cortex Analyst<br/>natural-language SQL"]:::done
    H --> I["AI output validation<br/>golden question set"]:::planned
    I --> J["Cortex Agent<br/>orchestration + guardrails"]:::planned
    J --> K["Business interface<br/>Streamlit in Snowflake"]:::planned

    classDef done fill:#e6f4ea,stroke:#34a853,stroke-width:1.5px,color:#1a1a1a;
    classDef planned fill:#fef7e0,stroke:#f9ab00,stroke-width:1.5px,stroke-dasharray:5 5,color:#1a1a1a;
```

🟢 Solid nodes are implemented and runnable in Snowflake today. 🟡 Dashed nodes (AI validation, Cortex Agent, business interface) are scoped in `docs/project_scope.md` but have no code or objects behind them yet — see [Current status and roadmap](#current-status-and-roadmap) for what that means concretely.

---

## Data pipeline and modeling layers

### RAW — `CUSTOMER_INTELLIGENCE.RAW`

Five tables created by [`sql/01_ingestion/01_create_raw_tables.sql`](sql/01_ingestion/01_create_raw_tables.sql), loaded from CSVs produced by [`python/convert_xlsx_to_csv.py`](python/convert_xlsx_to_csv.py) (a small pandas script that batch-converts the five source `.xlsx` files to CSV).

| Table | Rows | Grain |
|---|---|---|
| `CHURN_DEMOGRAPHICS` | 7,043 | 1 per customer |
| `CHURN_LOCATION` | 7,043 | 1 per customer |
| `CHURN_SERVICES` | 7,043 | 1 per customer |
| `CHURN_STATUS` | 7,043 | 1 per customer |
| `CHURN_POPULATION` | 1,671 | 1 per ZIP code |

Row counts above were computed directly from the processed CSVs, not assumed. The RAW layer intentionally stays close to the source structure instead of collapsing everything into one wide table immediately — this keeps lineage traceable and mirrors how ingestion is typically done in a real warehouse.

### CORE — `CUSTOMER_INTELLIGENCE.CORE`

Six files under [`sql/02_transformation/`](sql/02_transformation/) standardize the RAW tables into one-row-per-customer entities and derive the segmentation fields used everywhere downstream:

| Object | Type | Built from | Key derived fields |
|---|---|---|---|
| `CUSTOMER_PROFILE` | Table | `CHURN_DEMOGRAPHICS` | `AGE_BAND` (Under 30 / 30-44 / 45-59 / 60-74 / 75+) |
| `CUSTOMER_LOCATION` | Table | `CHURN_LOCATION` + `CHURN_POPULATION` (ZIP join) | ZIP-level `POPULATION` |
| `CUSTOMER_SERVICES` | Table | `CHURN_SERVICES` | `CORE_SERVICE_COUNT` (0-2), `ADD_ON_SERVICE_COUNT` (0-9), `TOTAL_SERVICE_COUNT` (0-11) |
| `CUSTOMER_SNAPSHOT` | Table | `CHURN_STATUS` + `CHURN_SERVICES` (tenure) | `TENURE_BAND`, `CHURN_FLAG`, `SATISFACTION_BAND` (Low ≤2 / Medium =3 / High ≥4), `CLTV_QUARTILE`, `CUSTOMER_VALUE_SEGMENT`, `HIGH_VALUE_FLAG` |
| `CUSTOMER_360_VIEW` | View | INNER JOIN of the four tables above on `CUSTOMER_ID` | — |

`CUSTOMER_VALUE_SEGMENT` is computed as `NTILE(4) OVER (ORDER BY CLTV)` — Q1 = Low Value through Q4 = High Value — a **relative** ranking within the observed customer base, not an absolute value tier.

**`CUSTOMER_360_VIEW` is a convenience view, not a replacement for the entity tables.** The CORE tables preserve structure and make lineage explicit (which source system contributed which field); the 360 view exists purely to make analytical querying convenient. Every ANALYTICS mart is built on top of `CUSTOMER_360_VIEW`.

---

## Data quality and validation

Validation is treated as an explicit step, not something implied by the transformation SQL. Two files carry it out:

- [`sql/01_ingestion/02_data_quality_checks.sql`](sql/01_ingestion/02_data_quality_checks.sql) — 11 checks against RAW: row counts, `CUSTOMER_ID` uniqueness and duplicate detection, null-ID checks, cross-table join completeness (demographics → location/services/status), ZIP-to-population reconciliation, churn label/value distribution, customer status distribution, churn-label/value consistency, tenure/charge/revenue range sanity checks, churn-category/reason null analysis, and quarter consistency.
- [`sql/02_transformation/06_core_validation.sql`](sql/02_transformation/06_core_validation.sql) — 5 checks against CORE: grain validation (no duplicate customers in `CUSTOMER_360_VIEW`), join completeness across all four CORE entities, churn reconciliation, RAW-vs-CORE revenue reconciliation, and CLTV/value-segment sanity checks.

Running these checks against the actual data confirms the customer-status reconciliation:

| Customer status | Customers | Share |
|---|---|---|
| Stayed | 4,720 | 67.03% |
| Joined | 454 | 6.45% |
| Churned | 1,869 | 26.54% |
| **Total** | **7,043** | **100%** |

Overall observed churn rate: **1,869 / 7,043 ≈ 26.54%**.

---

## Analytical marts

Schema: `CUSTOMER_INTELLIGENCE.ANALYTICS`. Rather than routing every business question through one customer-level table, the platform builds narrower, purpose-built views — each shaped around a specific analytical question so the SQL (and later, Cortex Analyst) doesn't have to reconstruct segmentation logic from scratch every time.

| Mart | Grain | Purpose |
|---|---|---|
| [`VW_EXECUTIVE_KPIS`](sql/03_marts/01_executive_kpis.sql) | 1 row per snapshot quarter | Headline KPIs: customer counts, churn rate, monthly/historical revenue, churned revenue, average CLTV, high-value churn rate, average tenure and satisfaction |
| [`VW_CHURN_SEGMENTS`](sql/03_marts/02_churn_segments.sql) | 1 row per segment value across 8 dimensions | Churn rate, churn contribution, and financial exposure by Contract, Payment Method, Tenure Band, Age Band, Offer, Internet Type, Customer Value, and Satisfaction |
| [`VW_PRODUCT_ADOPTION`](sql/03_marts/03_product_adoption.sql) | 1 row per product × adoption status (11 products) | Customer churn and financial profile among customers who have vs. haven't adopted each product |
| [`VW_PRODUCT_DEPTH`](sql/03_marts/04_product_depth.sql) | 1 row per total service count (0–11) | Churn behavior relative to the number of services a customer holds, including a `CHURN_INDEX` (segment rate ÷ overall rate) |
| [`VW_CUSTOMER_VALUE`](sql/03_marts/05_customer_value.sql) | 1 row per CLTV quartile | Churn rate, churn contribution, and revenue concentration by customer value segment |
| [`VW_CHURN_REASONS`](sql/03_marts/06_churn_reasons.sql) | 1 row per churn category/reason | Profile (tenure, charges, CLTV, satisfaction) of churned customers grouped by their reported reason |
| [`VW_CHURN_BY_TENURE`](sql/03_marts/07_churn_by_tenure.sql) | 1 row per observed tenure month | Cross-sectional churn-by-tenure curve across the whole customer base |
| [`VW_CHURN_BY_TENURE_SEGMENT`](sql/03_marts/09_churn_by_tenure_segment.sql) | 1 row per tenure month × segment (4 dimensions) | Same curve, segmented by Contract, Customer Value, Premium Tech Support, and Product Depth |

Two caveats that matter for interpreting these correctly:

- **Product adoption ≠ product discontinuation.** `VW_PRODUCT_ADOPTION`'s churn rate measures *customer* churn among customers in a given adoption group — it does not mean the customer stopped using that specific product.
- **Product depth is not linear.** `VW_PRODUCT_DEPTH` shows that the relationship between number of services held and churn is not a simple "more services, less churn" story. This is reported as an observed pattern, not a causal claim ("more products cause lower churn" is exactly the kind of statement this project avoids).

**A ninth file, [`VW_CHURN_BY_TENURE_ENHANCED`](sql/03_marts/08_churn_by_tenure_enhanced.sql), exists but is superseded.** It was an experimental exploration that added a 3-month centered rolling average and a hard-coded `BASE_SUPPORT_LEVEL` bucket (High/Medium/Low based on population size). The methodology this platform actually recommends — reflected in the semantic layer's guardrails — is simpler: show `CHURN_RATE_AT_TENURE` together with `CUSTOMERS_REACHING_TENURE` directly, without smoothing and without a hard-coded population cutoff, and let the reader (or the AI) apply judgment about small-sample volatility. `VW_CHURN_BY_TENURE_ENHANCED` is kept in the repo as a record of that exploration, not as the recommended approach.

---

## Metric governance

[`docs/metric_dictionary.md`](docs/metric_dictionary.md) is the single source of truth for how 21 metrics are defined — each with a business definition, formula, grain, source, interpretation, and known limitations. It closes with six analytical principles that this README, the SQL comments, and the semantic-layer guardrails all repeat consistently:

1. **Rate is not volume.** A segment can have a high churn rate but low business impact if it's small.
2. **Volume is not financial impact.** Churn contribution and revenue exposure are tracked separately.
3. **Association is not causation.** Product adoption, contract type, satisfaction, and CLTV may correlate with churn without causing it.
4. **Observed churn is not future churn risk.** `CHURNED_MONTHLY_REVENUE` describes customers who have already churned — the term "revenue at risk" is intentionally never used, because that would imply a forward-looking model that doesn't exist here.
5. **Lifecycle churn is not cohort retention.** `CHURN_RATE_AT_TENURE` is a cross-sectional approximation from one snapshot, not a true cohort retention curve.
6. **AI must use governed metrics.** Cortex Analyst and any future agent should answer quantitative questions using these approved definitions rather than inventing new logic.

The `CUSTOMER_INTELLIGENCE.VALIDATION` schema is created (empty) by [`sql/00_setup/create_environment.sql`](sql/00_setup/create_environment.sql), and an operational **`CUSTOMER_INTELLIGENCE.VALIDATION.METRIC_DEFINITIONS`** table exists in the deployed Snowflake environment holding the approved metric definitions. **The SQL to create and populate that table has not yet been committed to this repository** — it's tracked here as a known repository/version-control gap rather than a "not implemented" item, since the object itself is real and operational; closing the gap just means adding the corresponding `.sql` file to `sql/`.

---

## CLTV governance

CLTV in this dataset is **source-provided**. The underlying calculation methodology is not documented by IBM's dataset and is not recalculated or reverse-engineered anywhere in this project. Every place CLTV is used — the metric dictionary, the CORE tables, and the semantic layer — treats it strictly as a **relative customer-value indicator** for ranking and segmentation, never as a claim about predicted future revenue.

---

## Semantic layer

The Snowflake Semantic View definition lives at [`sql/04_semantic/customer_intelligence_view.yaml`](sql/04_semantic/customer_intelligence_view.yaml) and is version-controlled like any other analytical asset. It is not just metadata — it's the governed contract that Cortex Analyst uses to translate natural-language questions into SQL, and it's where the metric-governance principles above become machine-enforced rather than just documented.

**Four logical tables** are exposed: `CUSTOMER_360_VIEW`, `VW_CHURN_SEGMENTS`, `VW_PRODUCT_ADOPTION`, and `VW_CHURN_BY_TENURE_SEGMENT`. (`VW_EXECUTIVE_KPIS`, `VW_PRODUCT_DEPTH`, `VW_CUSTOMER_VALUE`, `VW_CHURN_REASONS`, and `VW_CHURN_BY_TENURE` exist as marts but aren't wired into the semantic layer yet — the ANALYTICS layer is broader than what Cortex Analyst currently sees.)

**Governed metrics** are formally defined once, on `CUSTOMER_360_VIEW`, and reused rather than redefined per table:

| Metric | Expression |
|---|---|
| `TOTAL_CUSTOMERS` | `COUNT(DISTINCT customer_id)` |
| `CHURNED_CUSTOMERS` | `COUNT_IF(churn_flag = 1)` |
| `CHURN_RATE` | `COUNT_IF(churn_flag = 1) / NULLIF(COUNT(DISTINCT customer_id), 0)` |
| `AVG_CLTV` | `AVG(cltv)` |
| `AVG_MONTHLY_CHARGE` | `AVG(monthly_charge)` |
| `AVG_TENURE_MONTHS` | `AVG(tenure_in_months)` |
| `TOTAL_MONTHLY_CHARGES` | `SUM(monthly_charge)` |
| `TOTAL_HISTORICAL_REVENUE` | `SUM(total_revenue)` |

`CHURN_RATE` is explicitly documented in the YAML as a **snapshot-based churn rate, not a historical beginning-of-period calculation**. Other mart-level views (like `VW_CHURN_SEGMENTS` and `VW_PRODUCT_ADOPTION`) expose the equivalent pre-aggregated numbers as **facts** rather than redefining the metric.

**Synonyms** are attached to key fields (e.g. `CHURN_RATE` ↔ "attrition rate," "churn percentage," "customer loss rate"; `TENURE_IN_MONTHS` ↔ "customer tenure," "months since joining"; `TOTAL_SERVICE_COUNT` ↔ "product depth," "service depth") so Cortex Analyst can map everyday business language onto the governed field names instead of requiring exact terminology.

**Named filters** currently defined: `CONTRACT_CHURN_BY_TENURE` (`dimension_name = 'Contract'`) and `CHURN_SEGMENTS_BY_CUSTOMER_VALUE` (`dimension_name = 'Customer Value'`). There is deliberately **no sample-size threshold filter** — an earlier version of this semantic view included an opt-in "sufficient sample" filter requiring at least 200 customers at a given tenure month, and it was removed. The methodology instead always exposes `CUSTOMERS_REACHING_TENURE` alongside `CHURN_RATE_AT_TENURE` and asks the reader (human or AI) to apply judgment about small-population volatility, rather than silently hiding or arbitrarily gating low-volume observations.

**Verified queries** — four manually reviewed, hand-corrected question/SQL pairs used as trusted examples for Cortex Analyst:

1. What is the range and average CLTV across each customer value segment?
2. For products that customers have adopted, which have the highest churn rate, and how do they compare on customer count, monthly charges, CLTV, and tenure?
3. For each contract type, at which observed tenure month is the churn rate highest, and how many customers reached that tenure?
4. Which customer segments have the highest monthly charges associated with churned customers, and what are their churn rates and contribution to total churn?

**Guardrail instructions** (`module_custom_instructions` in the YAML) constrain how Cortex Analyst is allowed to answer. A representative sample, quoted directly from the semantic model:

> "CHURN_RATE_AT_TENURE is a cross-sectional lifecycle approximation based on observed tenure in the available customer snapshot. Do not describe it as a historical cohort churn rate, cohort retention rate, survival rate, or true retention curve."
>
> "Do not apply a minimum sample-size threshold unless the user explicitly requests one. Smaller populations at higher tenure months should remain visible and should be interpreted with appropriate caution."
>
> "CHURNED_MONTHLY_REVENUE represents the sum of monthly charges associated with customers already identified as churned. Do not interpret it as forecasted revenue at risk, expected future revenue loss, or a forward-looking financial estimate."
>
> "CLTV is a source-provided Customer Lifetime Value indicator. The underlying CLTV calculation methodology is not available in the source dataset. Do not infer or invent its formula."
>
> "Do not infer causality from observed correlations or segment differences. Describe them as associations or observed patterns unless the available data explicitly supports causal conclusions."

There is also explicit **question-categorization logic**: if a user asks for the "biggest churn problem" without specifying what "biggest" means, the model is instructed to treat it as ambiguous and clarify whether they mean highest churn rate, highest churned-customer volume, highest contribution to total churn, or highest monthly charges associated with churned customers. If a user asks for cohort retention or a historical retention curve, the model is instructed to disclose that the dataset is a snapshot rather than fabricate an answer.

---

## Cortex Analyst and AI analytics

With the semantic view deployed, Snowflake Cortex Analyst can answer natural-language questions directly against governed metrics, dimensions, and verified query patterns — without users writing SQL. The point of this layer is not to demonstrate text-to-SQL as a novelty; it's to test whether a natural-language interface can operate reliably **on top of** governed analytical marts, documented business semantics, trusted examples, and explicit methodological limitations, rather than reasoning about the raw tables from scratch each time.

---

## AI validation strategy (planned)

**Not yet implemented** — `sql/06_validation/` does not exist in the repository yet. The intended approach is a golden question set covering basic KPI questions, segmentation questions, product-adoption questions, lifecycle questions, value-segmentation questions, deliberately ambiguous questions, methodological traps, and out-of-scope temporal questions — evaluated on logical table selection, metric selection, generated SQL, numerical correctness, business interpretation, and adherence to the guardrails above.

Two representative methodological traps the validation set is designed to catch:

- *"What is the revenue at risk from churn?"* — expected behavior is to explain that the dataset shows monthly charges associated with customers **already** identified as churned, not a forward-looking revenue-at-risk estimate.
- *"Show me the cohort retention curve."* — expected behavior is to explain that the dataset lacks the historical monthly snapshots required for true cohort retention, and to offer the cross-sectional lifecycle-by-tenure view instead.

---

## Cortex Agent (planned)

**Not yet implemented** — `sql/05_agent/` does not exist in the repository. The intended role of a Cortex Agent here is not to duplicate Cortex Analyst, but to orchestrate around it: understand user intent, route structured questions to Cortex Analyst, enforce the same business and methodological guardrails at the orchestration layer, surface limitations rather than papering over them, and leave room for additional tools later. Cortex Search is explicitly out of scope unless a genuine unstructured data source is added — there's no reason to introduce it while every source here is structured.

---

## Business interface (planned)

**Not yet implemented** — `streamlit/` exists as an empty folder. The intended scope is a Streamlit-in-Snowflake app exposing executive KPIs, segmentation/product/lifecycle exploration, and a natural-language question interface backed by Cortex Analyst.

---

## Key analytical insights

A small set of observed associations, verified directly against the processed data (not causal claims):

| Observation | Value |
|---|---|
| Overall churn rate | 1,869 / 7,043 = **26.54%** |
| Churn — Month-to-Month contract | **45.84%** (1,655 / 3,610) |
| Churn — One Year contract | **10.71%** (166 / 1,550) |
| Churn — Two Year contract | **2.55%** (48 / 1,883) |
| Churn — Low Value (CLTV Q1) | **34.41%** |
| Churn — Mid-Low Value (CLTV Q2) | **26.86%** |
| Churn — Mid-High Value (CLTV Q3) | **24.13%** |
| Churn — High Value (CLTV Q4) | **20.74%** |

Two patterns worth calling out: churn is strongly associated with contract commitment length (month-to-month customers churn at roughly 18× the rate of two-year customers), and churn decreases monotonically as CLTV quartile increases. Both are observed associations in this snapshot, not evidence of what would happen if a customer's contract or value tier were changed.

---

## Repository structure

```text
customer-intelligence-analytics-platform/
├── README.md                    # this file
├── .gitignore
├── assets/                      # currently empty — reserved for future diagrams/screenshots
├── data/
│   ├── README.md                # currently empty
│   ├── raw/                     # gitignored — source .xlsx files + classic reference CSV
│   └── processed/                # gitignored — CSVs converted from raw/
├── docs/
│   ├── project_scope.md         # original scope document (aspirational — some named objects, e.g. VW_REVENUE_RISK, were never built; code is the source of truth)
│   └── metric_dictionary.md     # governed metric definitions + analytical principles
├── python/
│   └── convert_xlsx_to_csv.py   # xlsx → csv batch conversion utility
├── sql/
│   ├── 00_setup/                # role, warehouse, database, 5 schemas
│   ├── 01_ingestion/            # RAW table DDL + 11 data quality checks
│   ├── 02_transformation/       # CORE layer: 4 entity tables + CUSTOMER_360_VIEW + validation
│   ├── 03_marts/                # ANALYTICS layer: 9 purpose-built views
│   └── 04_semantic/
│       └── customer_intelligence_view.yaml   # Cortex Analyst semantic model
└── streamlit/                   # currently empty — planned business interface
```

Note: `sql/05_agent/` and `sql/06_validation/` are referenced in the roadmap but **do not exist as directories yet** — they're listed under [Current status and roadmap](#current-status-and-roadmap) rather than in the tree above, so this structure reflects what's actually in the repository today.

---

## Technology stack

| Category | Used today |
|---|---|
| Data platform | Snowflake (database, warehouse, role-based access) |
| Query / modeling | Snowflake SQL |
| AI / conversational analytics | Snowflake Cortex Analyst, Snowflake Semantic Views |
| Data preparation | Python, pandas |
| Configuration | YAML (semantic model definition) |
| Version control | Git, GitHub |

Snowflake Cortex Agent and Streamlit in Snowflake are part of the target architecture (see [roadmap](#current-status-and-roadmap)) but are not yet used in this repository.

---

## How to reproduce

Requires a Snowflake account with Cortex enabled and `ACCOUNTADMIN` (or equivalent) access for initial setup.

1. Place the five source `.xlsx` files in `data/raw/`, then run `python python/convert_xlsx_to_csv.py` to produce `data/processed/*.csv`.
2. Run [`sql/00_setup/create_environment.sql`](sql/00_setup/create_environment.sql) to create the role, warehouse, database, and five schemas (`RAW`, `CORE`, `ANALYTICS`, `SEMANTIC`, `VALIDATION`).
3. Run both files in [`sql/01_ingestion/`](sql/01_ingestion/) in order — create the RAW tables, load the CSVs (via Snowsight upload or a stage of your choice), then run the data quality checks.
4. Run the six files in [`sql/02_transformation/`](sql/02_transformation/) in numeric order to build the CORE layer, ending with `CUSTOMER_360_VIEW` and its validation queries.
5. Run the nine files in [`sql/03_marts/`](sql/03_marts/) in numeric order to build the ANALYTICS marts.
6. Deploy [`sql/04_semantic/customer_intelligence_view.yaml`](sql/04_semantic/customer_intelligence_view.yaml) as a Snowflake Semantic View (Snowsight → Cortex Analyst → create from YAML, or `CREATE SEMANTIC VIEW` depending on your Snowflake release).
7. Query the semantic view through Cortex Analyst with natural-language questions, or query the ANALYTICS marts directly with SQL.

---

## Current status and roadmap

**Implemented:**
- Snowflake environment setup (role, warehouse, database, 5 schemas)
- RAW ingestion (5 tables) with 11 data quality checks
- CORE layer (4 standardized entity tables + `CUSTOMER_360_VIEW`) with 5 validation checks
- 9 ANALYTICS marts covering executive KPIs, segmentation, product adoption, product depth, customer value, churn reasons, and lifecycle-by-tenure analysis
- Governed metric dictionary (21 metrics, 6 analytical principles)
- Snowflake Semantic View for Cortex Analyst (4 logical tables, governed metrics, synonyms, named filters, 4 verified queries, and explicit AI guardrails)

**Planned, not yet implemented:**
- `VALIDATION.METRIC_DEFINITIONS` SQL — the table exists live in Snowflake; the repository is missing the SQL to reproduce it (see [Metric governance](#metric-governance))
- AI output validation framework and golden question set (`sql/06_validation/`)
- Cortex Agent for orchestration and guardrail enforcement (`sql/05_agent/`)
- Streamlit-in-Snowflake business interface (`streamlit/`)
- Wiring the remaining 5 ANALYTICS marts (`VW_EXECUTIVE_KPIS`, `VW_PRODUCT_DEPTH`, `VW_CUSTOMER_VALUE`, `VW_CHURN_REASONS`, `VW_CHURN_BY_TENURE`) into the semantic layer
- Python-based association/statistical analysis beyond the current xlsx→csv conversion utility

---

## Design principles

- **Traceability before convenience.** RAW and CORE entity tables are kept separate from the 360 view so lineage stays visible; the 360 view is a convenience layer on top, not a replacement.
- **Purpose-built marts over one giant table.** Each analytical question gets a view shaped for it, rather than forcing every question through the same wide customer table.
- **Metrics are defined once, with limitations attached.** Every governed metric documents not just its formula but what it does *not* mean — this is what keeps "churned monthly revenue" from silently becoming "revenue at risk" in a dashboard or an AI answer.
- **Expose the supporting population, don't hide it.** Lifecycle churn by tenure always shows `CUSTOMERS_REACHING_TENURE` next to `CHURN_RATE_AT_TENURE`, rather than applying an arbitrary cutoff that discards small-but-real observations.
- **CLTV is used, never reinvented.** Source-provided values are treated as relative indicators; this project does not claim to know or reproduce the underlying valuation model.
- **AI sits on top of governance, not instead of it.** The semantic layer, verified queries, and guardrails exist so that Cortex Analyst answers from the same governed definitions a human analyst would use — and so the next stages (validation, agent, interface) have something trustworthy to build on.