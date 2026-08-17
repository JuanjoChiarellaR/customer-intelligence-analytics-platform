import streamlit as st
import pandas as pd
import json

from snowflake.snowpark.context import get_active_session

st.set_page_config(
    page_title="Customer Intelligence Dashboard",
    page_icon="📊",
    layout="wide"
)

session = get_active_session()


# ---------------------------------------------------------
# Functions
# ---------------------------------------------------------

def run_customer_intelligence_agent(question):
    """
    Sends a natural-language question to the governed
    Customer Intelligence Cortex Agent.
    """

    escaped_question = question.replace("'", "''")

    query = f"""
        SELECT SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
            'CUSTOMER_INTELLIGENCE.SEMANTIC.CUSTOMER_INTELLIGENCE_AGENT',
            $$
            {{
              "messages": [
                {{
                  "role": "user",
                  "content": [
                    {{
                      "type": "text",
                      "text": "{escaped_question}"
                    }}
                  ]
                }}
              ]
            }}
            $$
        ) AS RESPONSE
    """

    result = session.sql(query).collect()

    if not result:
        return None

    response_raw = result[0]["RESPONSE"]

    if isinstance(response_raw, str):
        return json.loads(response_raw)

    return response_raw


def render_agent_table(table_content):
    """
    Renders a business-friendly table returned by the Cortex Agent.

    Improvements:
    - Converts technical column names into readable business labels.
    - Formats churn-related rate fields as percentages.
    - Formats customer counts as integers with thousands separators.
    - Formats monetary values when they appear.
    - Preserves unknown columns instead of failing.
    """

    try:
        # ---------------------------------------------------------
        # 1. Extract the result set returned by the Agent
        # ---------------------------------------------------------

        result_set = table_content["result_set"]

        rows = result_set["data"]
        metadata = result_set["resultSetMetaData"]["rowType"]

        columns = [
            column["name"]
            for column in metadata
        ]

        df = pd.DataFrame(
            rows,
            columns=columns
        )

        # ---------------------------------------------------------
        # 2. Business-friendly column names
        # ---------------------------------------------------------

        friendly_names = {

            # General segmentation
            "SEGMENT_VALUE": "Segment",
            "DIMENSION_NAME": "Dimension",

            # Customer counts
            "TOTAL_CUSTOMERS": "Total Customers",
            "CUSTOMERS": "Customers",
            "CHURNED_CUSTOMERS": "Churned Customers",

            # Churn metrics
            "CHURN_RATE": "Churn Rate",
            "CHURN_CONTRIBUTION": "Churn Contribution",

            # Product adoption
            "PRODUCT_NAME": "Product",
            "ADOPTION_STATUS": "Adoption Status",
            "ADOPTED_CUSTOMERS": "Adopted Customers",
            "ADOPTED_CHURN_RATE": "Adopted Churn Rate",
            "NOT_ADOPTED_CUSTOMERS": "Non-Adopted Customers",
            "NOT_ADOPTED_CHURN_RATE": "Non-Adopted Churn Rate",
            "CHURN_RATE_GAP": "Churn Rate Gap",

            # Customer value / CLTV
            "CUSTOMER_VALUE_SEGMENT": "Customer Value Segment",
            "CLTV": "CLTV",
            "AVG_CLTV": "Average CLTV",
            "MIN_CLTV": "Minimum CLTV",
            "MAX_CLTV": "Maximum CLTV",

            # Revenue / charges
            "MONTHLY_CHARGE": "Monthly Charge",
            "AVG_MONTHLY_CHARGE": "Average Monthly Charge",
            "TOTAL_MONTHLY_CHARGES": "Total Monthly Charges",
            "CHURNED_MONTHLY_REVENUE": "Churned Monthly Charges",
            "TOTAL_HISTORICAL_REVENUE": "Historical Revenue",
            "CHURNED_HISTORICAL_REVENUE": "Churned Historical Revenue",
            "AVG_TOTAL_REVENUE": "Average Historical Revenue",

            # Tenure / lifecycle
            "TENURE_MONTH": "Tenure Month",
            "TENURE_IN_MONTHS": "Tenure (Months)",
            "AVG_TENURE_MONTHS": "Average Tenure (Months)",
            "CUSTOMERS_REACHING_TENURE": "Customers Reaching Tenure",
            "CHURNED_AT_TENURE": "Churned at Tenure",
            "CHURN_RATE_AT_TENURE": "Observed Churn Rate at Tenure",

            # Other dimensions
            "CONTRACT": "Contract",
            "CONTRACT_TYPE": "Contract Type",
            "PAYMENT_METHOD": "Payment Method",
            "OFFER": "Offer",
            "AGE_BAND": "Age Band",
            "SATISFACTION_SCORE": "Satisfaction Score",
            "CHURN_CATEGORY": "Reported Churn Category",
            "CHURN_REASON": "Reported Churn Reason",
        }

        df = df.rename(
            columns=friendly_names
        )

        # ---------------------------------------------------------
        # 3. Percentage formatting
        # ---------------------------------------------------------

        percentage_columns = [
            "Churn Rate",
            "Churn Contribution",
            "Adopted Churn Rate",
            "Non-Adopted Churn Rate",
            "Churn Rate Gap",
            "Observed Churn Rate at Tenure",
        ]

        for column in percentage_columns:

            if column in df.columns:

                numeric_values = pd.to_numeric(
                    df[column],
                    errors="coerce"
                )

                df[column] = numeric_values.map(
                    lambda x: (
                        f"{x:.2%}"
                        if pd.notnull(x)
                        else ""
                    )
                )

        # ---------------------------------------------------------
        # 4. Customer / volume formatting
        # ---------------------------------------------------------

        integer_columns = [
            "Total Customers",
            "Customers",
            "Churned Customers",
            "Adopted Customers",
            "Non-Adopted Customers",
            "Customers Reaching Tenure",
            "Churned at Tenure",
            "Tenure Month",
        ]

        for column in integer_columns:

            if column in df.columns:

                numeric_values = pd.to_numeric(
                    df[column],
                    errors="coerce"
                )

                df[column] = numeric_values.map(
                    lambda x: (
                        f"{x:,.0f}"
                        if pd.notnull(x)
                        else ""
                    )
                )

        # ---------------------------------------------------------
        # 5. Monetary formatting
        # ---------------------------------------------------------

        currency_columns = [
            "Monthly Charge",
            "Average Monthly Charge",
            "Total Monthly Charges",
            "Churned Monthly Charges",
            "Historical Revenue",
            "Churned Historical Revenue",
            "Average Historical Revenue",
        ]

        for column in currency_columns:

            if column in df.columns:

                numeric_values = pd.to_numeric(
                    df[column],
                    errors="coerce"
                )

                df[column] = numeric_values.map(
                    lambda x: (
                        f"${x:,.2f}"
                        if pd.notnull(x)
                        else ""
                    )
                )

        # ---------------------------------------------------------
        # 6. CLTV formatting
        #
        # CLTV is source-provided and should not be presented
        # as currency unless the source explicitly defines it
        # that way.
        # ---------------------------------------------------------

        cltv_columns = [
            "CLTV",
            "Average CLTV",
            "Minimum CLTV",
            "Maximum CLTV",
        ]

        for column in cltv_columns:

            if column in df.columns:

                numeric_values = pd.to_numeric(
                    df[column],
                    errors="coerce"
                )

                df[column] = numeric_values.map(
                    lambda x: (
                        f"{x:,.2f}"
                        if pd.notnull(x)
                        else ""
                    )
                )

        # ---------------------------------------------------------
        # 7. Display table title
        # ---------------------------------------------------------

        title = table_content.get("title")

        if title:
            st.markdown(
                f"**{title}**"
            )

        # ---------------------------------------------------------
        # 8. Render the final business-friendly table
        # ---------------------------------------------------------

        st.dataframe(
            df,
            use_container_width=True,
            hide_index=True
        )

    except Exception as e:

        st.warning(
            f"Unable to render Agent table: {e}"
        )

def render_agent_chart(chart_content):
    """
    Renders Vega-Lite charts returned by the Cortex Agent.
    """

    try:
        chart_spec_raw = chart_content["chart_spec"]

        if isinstance(chart_spec_raw, str):
            chart_spec = json.loads(chart_spec_raw)
        else:
            chart_spec = chart_spec_raw

        st.vega_lite_chart(
            chart_spec,
            use_container_width=True
        )

    except Exception as e:
        st.warning(f"Unable to render Agent chart: {e}")

def render_agent_technical_details(response):
    """
    Extracts and displays Agent execution metadata for
    governance, traceability, and usage observability.
    """

    generated_sql = None
    verified_query_used = None
    query_id = None

    for item in response.get("content", []):

        if item.get("type") != "tool_result":
            continue

        tool_result = item.get("tool_result", {})

        if tool_result.get("name") != "system_execute_sql":
            continue

        try:
            result_json = tool_result["content"][0]["json"]

            generated_sql = result_json.get("sql")
            verified_query_used = result_json.get(
                "verified_query_used"
            )
            query_id = result_json.get("query_id")

        except (KeyError, IndexError, TypeError):
            pass

    usage = (
        response
        .get("metadata", {})
        .get("usage", {})
        .get("tokens_consumed", [])
    )

    with st.expander("Technical Details"):

        col1, col2, col3 = st.columns(3)

        col1.metric(
            "Verified Query",
            "Yes" if verified_query_used else "No"
        )

        col2.metric(
            "Query ID",
            query_id if query_id else "N/A"
        )

        model_name = "N/A"

        if usage:
            model_name = usage[0].get(
                "model_name",
                "N/A"
            )

        col3.metric(
            "Model",
            model_name
        )

        if generated_sql:
            st.markdown("**Generated SQL**")
            st.code(
                generated_sql,
                language="sql"
            )

        if usage:

            token_usage = usage[0]

            input_tokens = token_usage.get(
                "input_tokens",
                {}
            )

            output_tokens = token_usage.get(
                "output_tokens",
                {}
            )

            st.markdown("**Token Usage**")

            t1, t2, t3, t4 = st.columns(4)

            t1.metric(
                "Input",
                f"{input_tokens.get('total', 0):,}"
            )

            t2.metric(
                "Cache Read",
                f"{input_tokens.get('cache_read', 0):,}"
            )

            t3.metric(
                "Cache Write",
                f"{input_tokens.get('cache_write', 0):,}"
            )

            t4.metric(
                "Output",
                f"{output_tokens.get('total', 0):,}"
            )

            st.caption(
                f"Uncached input tokens: "
                f"{input_tokens.get('uncached', 0):,}"
            )

def render_agent_response(response):
    """
    Renders the user-facing artifacts returned by the Agent
    while preserving their original response order.
    """

    if not response:
        st.error("The Agent did not return a response.")
        return

    for item in response.get("content", []):

        content_type = item.get("type")

        # -------------------------
        # Narrative
        # -------------------------

        if content_type == "text":

            text = item.get("text")

            if text:
                st.markdown(text)

        # -------------------------
        # Table
        # -------------------------

        elif content_type == "table":

            table_content = item.get("table")

            if table_content:
                render_agent_table(
                    table_content
                )

        # -------------------------
        # Chart
        # -------------------------

        elif content_type == "chart":

            chart_content = item.get("chart")

            if chart_content:
                render_agent_chart(
                    chart_content
                )

        # -------------------------
        # Suggested Questions
        # -------------------------

        elif content_type == "suggested_queries":

            suggestions = item.get(
                "suggested_queries",
                []
            )

            if suggestions:

                st.markdown(
                    "**Suggested follow-up questions**"
                )

                for suggestion in suggestions:

                    question = suggestion.get("query")

                    if question:
                        st.markdown(
                            f"- {question}"
                        )

    render_agent_technical_details(response)

# ---------------------------------------------------------
# Header
# ---------------------------------------------------------

st.title("Customer Intelligence Dashboard")
st.caption(
    "Executive view of customer churn, customer value, "
    "product adoption, and lifecycle analytics."
)

# ---------------------------------------------------------
# Executive KPIs
# ---------------------------------------------------------

kpi_df = session.sql("""
    SELECT *
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_EXECUTIVE_KPIS
""").to_pandas()

if not kpi_df.empty:
    row = kpi_df.iloc[0]

    c1, c2, c3, c4, c5 = st.columns(5)

    c1.metric(
        "Total Customers",
        f"{int(row['TOTAL_CUSTOMERS']):,}"
    )

    c2.metric(
        "Churned Customers",
        f"{int(row['CHURNED_CUSTOMERS']):,}"
    )

    c3.metric(
        "Observed Churn Rate",
        f"{row['CHURN_RATE']:.1%}"
    )

    c4.metric(
        "Average CLTV",
        f"${row['AVG_CLTV']:,.0f}"
    )

    c5.metric(
        "Churned Monthly Charges",
        f"${row['CHURNED_MONTHLY_REVENUE']:,.0f}"
    )

st.divider()

# ---------------------------------------------------------
# Contract Analysis
# ---------------------------------------------------------

st.subheader("Contract Churn Performance")

contract_df = session.sql("""
    SELECT
        SEGMENT_VALUE AS CONTRACT_TYPE,
        TOTAL_CUSTOMERS,
        CHURNED_CUSTOMERS,
        CHURN_RATE,
        CHURN_CONTRIBUTION
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_SEGMENTS
    WHERE DIMENSION_NAME = 'Contract'
    ORDER BY CHURN_RATE DESC
""").to_pandas()

contract_display = contract_df.copy()
contract_display["CHURN_RATE"] *= 100
contract_display["CHURN_CONTRIBUTION"] *= 100

contract_chart = contract_df.set_index("CONTRACT_TYPE")[
    ["CHURN_RATE", "CHURN_CONTRIBUTION"]
]

st.bar_chart(contract_chart)

st.dataframe(
    contract_display,
    use_container_width=True,
    hide_index=True,
    column_config={
        "CONTRACT_TYPE": st.column_config.TextColumn("Contract"),
        "TOTAL_CUSTOMERS": st.column_config.NumberColumn(
            "Customers", format="%d"
        ),
        "CHURNED_CUSTOMERS": st.column_config.NumberColumn(
            "Churned", format="%d"
        ),
        "CHURN_RATE": st.column_config.NumberColumn(
            "Churn Rate", format="%.2f%%"
        ),
        "CHURN_CONTRIBUTION": st.column_config.NumberColumn(
            "Churn Contribution", format="%.2f%%"
        ),
    }
)

st.caption(
    "Churn rate measures churn within each contract segment. "
    "Churn contribution measures each segment's share of total churn."
)

st.divider()

# ---------------------------------------------------------
# Customer Value
# ---------------------------------------------------------

st.subheader("Customer Value Segments")

value_df = session.sql("""
    SELECT
        SEGMENT_VALUE AS VALUE_SEGMENT,
        TOTAL_CUSTOMERS,
        CHURNED_CUSTOMERS,
        CHURN_RATE,
        CHURN_CONTRIBUTION
    FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_CHURN_SEGMENTS
    WHERE DIMENSION_NAME = 'Customer Value'
    ORDER BY CHURN_RATE DESC
""").to_pandas()

value_display = value_df.copy()
value_display["CHURN_RATE"] *= 100
value_display["CHURN_CONTRIBUTION"] *= 100

value_chart = value_df.set_index("VALUE_SEGMENT")[["CHURN_RATE"]]

st.bar_chart(value_chart)

st.dataframe(
    value_display,
    use_container_width=True,
    hide_index=True,
    column_config={
        "VALUE_SEGMENT": st.column_config.TextColumn("Value Segment"),
        "TOTAL_CUSTOMERS": st.column_config.NumberColumn(
            "Customers", format="%d"
        ),
        "CHURNED_CUSTOMERS": st.column_config.NumberColumn(
            "Churned", format="%d"
        ),
        "CHURN_RATE": st.column_config.NumberColumn(
            "Churn Rate", format="%.2f%%"
        ),
        "CHURN_CONTRIBUTION": st.column_config.NumberColumn(
            "Contribution", format="%.2f%%"
        ),
    }
)

st.divider()

# ---------------------------------------------------------
# Product Adoption
# ---------------------------------------------------------

st.subheader("Product Adoption & Churn")

product_df = session.sql("""
    WITH adopted AS (
        SELECT
            PRODUCT_NAME,
            CUSTOMERS AS ADOPTED_CUSTOMERS,
            CHURN_RATE AS ADOPTED_CHURN_RATE
        FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_PRODUCT_ADOPTION
        WHERE ADOPTION_STATUS = 'Yes'
    ),
    not_adopted AS (
        SELECT
            PRODUCT_NAME,
            CUSTOMERS AS NOT_ADOPTED_CUSTOMERS,
            CHURN_RATE AS NOT_ADOPTED_CHURN_RATE
        FROM CUSTOMER_INTELLIGENCE.ANALYTICS.VW_PRODUCT_ADOPTION
        WHERE ADOPTION_STATUS = 'No'
    )
    SELECT
        a.PRODUCT_NAME,
        a.ADOPTED_CUSTOMERS,
        a.ADOPTED_CHURN_RATE,
        n.NOT_ADOPTED_CUSTOMERS,
        n.NOT_ADOPTED_CHURN_RATE,
        a.ADOPTED_CHURN_RATE - n.NOT_ADOPTED_CHURN_RATE AS CHURN_RATE_GAP
    FROM adopted a
    JOIN not_adopted n
        ON a.PRODUCT_NAME = n.PRODUCT_NAME
    ORDER BY CHURN_RATE_GAP
""").to_pandas()

product_display = product_df.copy()

product_display["ADOPTED_CHURN_RATE"] *= 100
product_display["NOT_ADOPTED_CHURN_RATE"] *= 100
product_display["CHURN_RATE_GAP"] *= 100

# Horizontal bar chart so long product names fit better
product_chart = product_display.set_index("PRODUCT_NAME")[["CHURN_RATE_GAP"]]

st.bar_chart(
    product_chart,
    horizontal=True
)

st.dataframe(
    product_display,
    use_container_width=True,
    hide_index=True,
    column_config={
        "PRODUCT_NAME": st.column_config.TextColumn(
            "Product", width="medium"
        ),
        "ADOPTED_CUSTOMERS": st.column_config.NumberColumn(
            "Adopted", format="%d"
        ),
        "ADOPTED_CHURN_RATE": st.column_config.NumberColumn(
            "Adopted Churn", format="%.2f%%"
        ),
        "NOT_ADOPTED_CUSTOMERS": st.column_config.NumberColumn(
            "Not Adopted", format="%d"
        ),
        "NOT_ADOPTED_CHURN_RATE": st.column_config.NumberColumn(
            "Non-Adopted Churn", format="%.2f%%"
        ),
        "CHURN_RATE_GAP": st.column_config.NumberColumn(
            "Churn Gap", format="%.2f%%"
        ),
    }
)

st.caption(
    "Negative churn-rate gaps mean adopters show lower observed churn "
    "than non-adopters. These are associations, not causal effects."
)

st.divider()

# ---------------------------------------------------------
# Lifecycle
# ---------------------------------------------------------

st.subheader("Observed Churn Across Customer Tenure")

tenure_df = session.sql("""
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
""").to_pandas()

tenure_chart = tenure_df.set_index("TENURE_MONTH")[["CHURN_RATE_AT_TENURE"]]

st.line_chart(tenure_chart)

st.caption(
    "Cross-sectional lifecycle view based on observed tenure. "
    "This is not a historical cohort retention or survival curve."
)

with st.expander("View supporting tenure data"):
    st.dataframe(
        tenure_df,
        use_container_width=True,
        hide_index=True,
        column_config={
            "TENURE_MONTH": st.column_config.NumberColumn(
                "Tenure Month", format="%d"
            ),
            "CUSTOMERS_REACHING_TENURE": st.column_config.NumberColumn(
                "Customers Reaching Tenure", format="%d"
            ),
            "CHURNED_AT_TENURE": st.column_config.NumberColumn(
                "Churned at Tenure", format="%d"
            ),
            "CHURN_RATE_AT_TENURE": st.column_config.NumberColumn(
                "Observed Churn Rate", format="%.2f%%"
            ),
        }
    )

# ============================================================
# CUSTOMER INTELLIGENCE AGENT
# ============================================================

st.divider()

st.header("Ask Customer Intelligence Agent")

st.caption(
    "Ask natural-language questions about governed churn, "
    "customer value, product adoption, contracts, and lifecycle analytics."
)

agent_question = st.text_area(
    "Business question",
    placeholder=(
        "Example: Compare churn rate and contribution "
        "across contract types."
    ),
    height=100
)

ask_agent = st.button(
    "Ask Agent",
    type="primary"
)

if ask_agent:

    if not agent_question.strip():

        st.warning(
            "Enter a question before running the Agent."
        )

    else:

        with st.spinner(
            "Customer Intelligence Agent is analyzing..."
        ):

            try:

                agent_response = (
                    run_customer_intelligence_agent(
                        agent_question
                    )
                )

                st.session_state[
                    "agent_response"
                ] = agent_response

                st.session_state[
                    "agent_question"
                ] = agent_question

            except Exception as e:

                st.error(
                    f"Agent execution failed: {e}"
                )


if "agent_response" in st.session_state:

    st.subheader("Agent Response")

    st.caption(
        f"Question: "
        f"{st.session_state.get('agent_question', '')}"
    )

    render_agent_response(
        st.session_state["agent_response"]
    )