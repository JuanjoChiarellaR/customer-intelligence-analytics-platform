"""
Customer Intelligence Analytics Platform
Executive Customer Intelligence Dashboard (Streamlit in Snowflake)

Reads exclusively from the governed CUSTOMER_INTELLIGENCE.ANALYTICS marts.
No business logic is recomputed here -- every number comes from the same
views used by the semantic layer and Cortex Analyst, so the dashboard,
Cortex Analyst, and the Cortex Agent all agree on the same numbers.

Scope note: this app does not yet include a Cortex Agent chat interface.
That integration is planned (see docs/dashboard.md).
"""

import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(
    page_title="Customer Intelligence Dashboard",
    layout="wide",
)

session = get_active_session()


def run_query(sql: str) -> pd.DataFrame:
    return session.sql(sql).to_pandas()


st.title("Customer Intelligence Dashboard")
st.caption(
    "Executive view of customer churn, customer value, product adoption, "
    "and lifecycle analytics."
)

# ------------------------------------------------------------------
# Executive KPIs
# ------------------------------------------------------------------

kpis = run_query(
    "SELECT * FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_EXECUTIVE_KPIS"
).iloc[0]

kpi_cols = st.columns(5)
kpi_cols[0].metric("Total Customers", f"{int(kpis['TOTAL_CUSTOMERS']):,}")
kpi_cols[1].metric("Churned Customers", f"{int(kpis['CHURNED_CUSTOMERS']):,}")
kpi_cols[2].metric("Observed Churn Rate", f"{kpis['CHURN_RATE'] * 100:.1f}%")
kpi_cols[3].metric("Average CLTV", f"${kpis['AVG_CLTV']:,.0f}")
kpi_cols[4].metric(
    "Churned Monthly Charges",
    f"${kpis['CHURNED_MONTHLY_REVENUE']:,.0f}",
)

st.divider()

# ------------------------------------------------------------------
# Contract Churn Performance
# ------------------------------------------------------------------

st.header("Contract Churn Performance")

contract_df = run_query(
    """
    SELECT
        SEGMENT_VALUE       AS CONTRACT,
        TOTAL_CUSTOMERS,
        CHURNED_CUSTOMERS,
        CHURN_RATE,
        CHURN_CONTRIBUTION
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_SEGMENTS
    WHERE DIMENSION_NAME = 'Contract'
    ORDER BY CHURN_RATE DESC
    """
)

st.bar_chart(
    contract_df.set_index("CONTRACT")[["CHURN_RATE", "CHURN_CONTRIBUTION"]]
)

display_contract = contract_df.copy()
display_contract["CHURN_RATE"] = (
    (display_contract["CHURN_RATE"] * 100).round(2).astype(str) + "%"
)
display_contract["CHURN_CONTRIBUTION"] = (
    (display_contract["CHURN_CONTRIBUTION"] * 100).round(2).astype(str) + "%"
)
st.dataframe(display_contract, hide_index=True, use_container_width=True)

st.caption(
    "Churn rate measures churn within each contract segment. Churn "
    "contribution measures each segment's share of total churn."
)

st.divider()

# ------------------------------------------------------------------
# Customer Value Segments
#
# NOTE: this section deliberately reuses VW_CHURN_SEGMENTS filtered to
# DIMENSION_NAME = 'Customer Value', the same generic segmentation mart
# used above for Contract -- not the separate VW_CUSTOMER_VALUE mart.
# ------------------------------------------------------------------

st.header("Customer Value Segments")

value_order = ["Low Value", "Mid-Low Value", "Mid-High Value", "High Value"]

value_df = run_query(
    """
    SELECT
        SEGMENT_VALUE       AS CUSTOMER_VALUE_SEGMENT,
        TOTAL_CUSTOMERS,
        CHURNED_CUSTOMERS,
        CHURN_RATE,
        CHURN_CONTRIBUTION,
        AVG_CLTV
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_SEGMENTS
    WHERE DIMENSION_NAME = 'Customer Value'
    """
)
value_df["CUSTOMER_VALUE_SEGMENT"] = pd.Categorical(
    value_df["CUSTOMER_VALUE_SEGMENT"], categories=value_order, ordered=True
)
value_df = value_df.sort_values("CUSTOMER_VALUE_SEGMENT")

st.bar_chart(value_df.set_index("CUSTOMER_VALUE_SEGMENT")["CHURN_RATE"])

display_value = value_df.copy()
display_value["CHURN_RATE"] = (
    (display_value["CHURN_RATE"] * 100).round(2).astype(str) + "%"
)
display_value["CHURN_CONTRIBUTION"] = (
    (display_value["CHURN_CONTRIBUTION"] * 100).round(2).astype(str) + "%"
)
st.dataframe(display_value, hide_index=True, use_container_width=True)

st.caption(
    "Customer value segments are relative CLTV quartiles (source-provided "
    "CLTV, methodology unknown). Lower observed churn in higher-value "
    "segments is an association in this snapshot, not a causal effect of "
    "customer value on churn."
)

st.divider()

# ------------------------------------------------------------------
# Product Adoption & Churn
# ------------------------------------------------------------------

st.header("Product Adoption & Churn")

adoption_df = run_query(
    """
    SELECT PRODUCT_NAME, ADOPTION_STATUS, CUSTOMERS, CHURN_RATE
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_PRODUCT_ADOPTION
    WHERE ADOPTION_STATUS IN ('Yes', 'No')
    """
)

adopted = adoption_df[adoption_df["ADOPTION_STATUS"] == "Yes"].set_index("PRODUCT_NAME")
not_adopted = adoption_df[adoption_df["ADOPTION_STATUS"] == "No"].set_index("PRODUCT_NAME")

gap_df = pd.DataFrame(
    {
        "ADOPTED_CUSTOMERS": adopted["CUSTOMERS"],
        "ADOPTED_CHURN_RATE": adopted["CHURN_RATE"],
        "NOT_ADOPTED_CUSTOMERS": not_adopted["CUSTOMERS"],
        "NOT_ADOPTED_CHURN_RATE": not_adopted["CHURN_RATE"],
    }
).dropna()
gap_df["CHURN_RATE_GAP"] = (
    (gap_df["ADOPTED_CHURN_RATE"] - gap_df["NOT_ADOPTED_CHURN_RATE"]) * 100
).round(2)
gap_df = gap_df.sort_values("CHURN_RATE_GAP")

st.bar_chart(gap_df["CHURN_RATE_GAP"], horizontal=True)

display_gap = gap_df.reset_index().rename(columns={"index": "PRODUCT_NAME"})
display_gap["ADOPTED_CHURN_RATE"] = (
    (display_gap["ADOPTED_CHURN_RATE"] * 100).round(2).astype(str) + "%"
)
display_gap["NOT_ADOPTED_CHURN_RATE"] = (
    (display_gap["NOT_ADOPTED_CHURN_RATE"] * 100).round(2).astype(str) + "%"
)
display_gap["CHURN_RATE_GAP"] = display_gap["CHURN_RATE_GAP"].astype(str) + "%"
st.dataframe(
    display_gap[
        [
            "PRODUCT_NAME",
            "ADOPTED_CUSTOMERS",
            "ADOPTED_CHURN_RATE",
            "NOT_ADOPTED_CUSTOMERS",
            "NOT_ADOPTED_CHURN_RATE",
            "CHURN_RATE_GAP",
        ]
    ],
    hide_index=True,
    use_container_width=True,
)

st.caption(
    "Negative churn-rate gaps mean adopters show lower observed churn than "
    "non-adopters. These are associations, not causal effects."
)

st.divider()

# ------------------------------------------------------------------
# Lifecycle — observed churn by tenure, aggregated across contract types
# ------------------------------------------------------------------

st.header("Observed Churn Across Customer Tenure")

lifecycle_df = run_query(
    """
    SELECT
        TENURE_MONTH,
        SUM(CUSTOMERS_REACHING_TENURE) AS CUSTOMERS_REACHING_TENURE,
        SUM(CHURNED_AT_TENURE) AS CHURNED_AT_TENURE,
        SUM(CHURNED_AT_TENURE)
            / NULLIF(SUM(CUSTOMERS_REACHING_TENURE), 0)
            AS CHURN_RATE_AT_TENURE
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_BY_TENURE_SEGMENT
    WHERE DIMENSION_NAME = 'Contract'
    GROUP BY TENURE_MONTH
    ORDER BY TENURE_MONTH
    """
)

st.line_chart(lifecycle_df.set_index("TENURE_MONTH")["CHURN_RATE_AT_TENURE"])

st.caption(
    "Cross-sectional lifecycle view based on observed tenure. This is not "
    "a historical cohort retention or survival curve."
)

with st.expander("View supporting tenure data"):
    st.dataframe(lifecycle_df, hide_index=True, use_container_width=True)
