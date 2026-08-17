# Executive Customer Intelligence Dashboard

## Purpose

A Streamlit-in-Snowflake application that gives business stakeholders a governed, no-SQL view into customer churn, segmentation, product adoption, and lifecycle patterns — reading directly from the same ANALYTICS marts used by the semantic layer and Cortex Analyst, so the dashboard never disagrees with the AI layer on a number.

## Intended business users

Product Data Analysts, Product Managers, Retention/Commercial Analytics teams, and senior business stakeholders who need recurring performance monitoring without writing SQL — the same audience described in [`docs/project_scope.md`](project_scope.md).

## Implementation

App code: [`streamlit/streamlit_app.py`](../streamlit/streamlit_app.py). Permissions to create the app were granted via [`sql/00_setup/03_streamlit_permissions.sql`](../sql/00_setup/03_streamlit_permissions.sql) (database usage, ANALYTICS schema usage, `CREATE STREAMLIT` on the ANALYTICS schema).

## Sections

| Section | Analytical mart(s) | What it shows |
|---|---|---|
| Executive KPIs | `VW_EXECUTIVE_KPIS` | Total customers, churned customers, observed churn rate, average CLTV, monthly charges associated with churned customers |
| Contract Churn Performance | `VW_CHURN_SEGMENTS` filtered `DIMENSION_NAME = 'Contract'` | Customers, churned customers, churn rate, and churn contribution per contract type |
| Customer Value Segments | `VW_CHURN_SEGMENTS` filtered `DIMENSION_NAME = 'Customer Value'` | Churn rate, churn contribution, and average CLTV per CLTV-quartile value segment |
| Product Adoption & Churn | `VW_PRODUCT_ADOPTION` | Adopted vs. non-adopted customer churn rate per product, and the churn-rate gap between the two groups |
| Lifecycle | `VW_CHURN_BY_TENURE_SEGMENT` filtered `DIMENSION_NAME = 'Contract'` | Observed churn rate by tenure month, per contract type, shown together with the supporting customer population at each month |

**Important correction for accuracy:** Customer Value Segments intentionally reuses `VW_CHURN_SEGMENTS` (the same generic segmentation mart used for Contract Churn Performance), filtered to `DIMENSION_NAME = 'Customer Value'` — it does **not** query the separate `VW_CUSTOMER_VALUE` mart, even though that mart exists in the ANALYTICS schema and covers similar ground. Keeping the dashboard on one generic mart for both sections keeps the segmentation logic and column names consistent across the app; `VW_CUSTOMER_VALUE`'s richer revenue-concentration fields are not currently surfaced here.

## Metric definitions

Every metric shown (`CHURN_RATE`, `CHURN_CONTRIBUTION`, `CHURNED_MONTHLY_REVENUE`, `AVG_CLTV`, `CUSTOMERS_REACHING_TENURE`, `CHURN_RATE_AT_TENURE`, etc.) follows the definitions in [`docs/metric_dictionary.md`](metric_dictionary.md). The dashboard does not recompute or redefine any metric — it queries the governed marts as-is.

## Methodology limitations (surfaced directly in the app)

- All figures come from a single observed customer snapshot, not a historical time series.
- The lifecycle section is a cross-sectional approximation, explicitly labeled as such in-app — not cohort retention, not a survival curve, not a longitudinal trend.
- Product Adoption & Churn gaps are observed associations between customer groups, not evidence that a product causes a churn difference.
- Customer value segments are relative CLTV quartiles; CLTV's underlying methodology is source-provided and unknown.
- "Churned Monthly Charges" is never described as revenue at risk — it describes customers already identified as churned.

## Screenshots

Captured from the deployed Streamlit-in-Snowflake app.

**Executive KPIs and Contract Churn Performance**

![Executive KPIs and Contract Churn Performance](../assets/dashboard-executive-kpis-contract-churn.png)

**Customer Value Segments**

![Customer Value Segments](../assets/dashboard-customer-value-segments.png)

**Product Adoption & Churn**

![Product Adoption and Churn](../assets/dashboard-product-adoption-churn.png)

**Observed Churn Across Customer Tenure (Lifecycle)**

![Observed Churn Across Customer Tenure](../assets/dashboard-lifecycle-tenure.png)

## Future Agent integration (planned)

The dashboard does not currently include a Cortex Agent chat interface. Integrating `CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT` (see [`docs/cortex_agent.md`](cortex_agent.md)) as an "Ask the Customer Intelligence Agent" section is the first item on the project roadmap — see the [README's roadmap section](../README.md#current-status-and-roadmap).
