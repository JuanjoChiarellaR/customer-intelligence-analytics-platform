# Customer Intelligence Analytics Platform
## Project Scope

## 1. Project Overview

The Customer Intelligence Analytics Platform is an end-to-end product and customer analytics solution built with Snowflake, SQL, Python, semantic layers, Snowflake Cortex AI Agents, Streamlit, and governed metric validation.

The project uses customer churn as the primary business use case, but the analytical architecture is designed around broader and transferable product analytics capabilities:

- Customer behavior analysis
- Customer lifecycle and retention
- Product and service adoption
- Revenue exposure
- Customer segmentation
- Performance monitoring
- Metric governance
- Executive reporting
- Conversational analytics
- AI output validation

The objective is to demonstrate how structured customer data can be transformed into governed business metrics and then consumed through both traditional analytics and natural-language AI interfaces.

---

## 2. Business Problem

Business teams often need to answer questions such as:

- Which customer segments are performing differently?
- Where is customer attrition concentrated?
- Which products or services are associated with higher retention?
- Which customer segments represent the greatest revenue exposure?
- Which behavioral characteristics differentiate retained and churned customers?
- What should analysts investigate first when performance changes?

The challenge is not simply having access to data.

Reliable decision-making requires:

1. Consistent business definitions
2. Clean and reconciled data
3. Analytical models designed around business questions
4. Governed metrics
5. Fast access to insights
6. Validation of AI-generated answers against deterministic calculations

This project builds an analytics architecture designed to address those requirements.

---

## 3. Target Users

The platform is designed for users such as:

- Product Data Analysts
- Product Managers
- Business Analysts
- Customer Lifecycle teams
- Retention teams
- Commercial Analytics teams
- Strategy teams
- Senior business stakeholders

The application should support both recurring performance monitoring and ad-hoc analytical questions.

---

## 4. Dataset

The primary data source is the enhanced IBM Telco Customer Churn dataset.

The source package contains five related datasets:

- Customer demographics
- Customer location
- ZIP-code population
- Customer services and billing
- Customer churn status

The customer-level datasets contain 7,043 customers and can be joined using Customer ID. The enhanced dataset includes variables related to customer tenure, services, contracts, payment methods, offers, referrals, satisfaction, churn, CLTV, revenue, churn categories, churn reasons, and geography.

The classic IBM churn CSV is retained only as a reconciliation/reference dataset and is not the primary analytical source.

---

## 5. Important Data Limitation

The dataset represents a customer-level snapshot.

It does not contain a true historical sequence of monthly customer observations or reliable churn dates.

Therefore, the project will NOT create unsupported historical churn trends.

Questions such as:

"How did churn change over the last 12 months?"

cannot be answered reliably from the observed dataset.

Instead, the analysis will focus on cross-sectional customer behavior, tenure, segmentation, revenue exposure, service adoption, customer value, and churn outcomes.

Any future reconstructed or synthetic historical data must be explicitly identified as such and separated from observed source data.

---

## 6. Analytical Architecture

The platform follows a layered analytical architecture:

Raw Data
    ↓
Data Quality & Reconciliation
    ↓
Core Customer Model
    ↓
Analytical Marts
    ↓
Governed Metric Definitions
    ↓
Semantic Layer
    ↓
Snowflake Cortex Analyst
    ↓
Churn / Customer Intelligence Agent
    ↓
AI Output Validation
    ↓
Streamlit Executive Application

The architecture separates raw source data from business-ready analytical data and prevents the AI layer from defining business metrics independently.

---

## 7. Snowflake Data Layers

### RAW

Contains source data with minimal modification.

Planned objects:

- RAW.CHURN_DEMOGRAPHICS
- RAW.CHURN_LOCATION
- RAW.CHURN_POPULATION
- RAW.CHURN_SERVICES
- RAW.CHURN_STATUS

### CORE

Contains cleaned, standardized, customer-level data.

Primary object:

- CORE.CUSTOMER_360

Expected grain:

One row per customer.

The model will combine demographics, services, billing, location, customer value, and churn status.

### ANALYTICS

Contains business-ready views and analytical marts.

Planned objects:

- ANALYTICS.MART_CUSTOMER_INTELLIGENCE
- ANALYTICS.VW_EXECUTIVE_KPIS
- ANALYTICS.VW_CHURN_SEGMENTS
- ANALYTICS.VW_REVENUE_RISK
- ANALYTICS.VW_CHURN_REASONS
- ANALYTICS.VW_PRODUCT_ADOPTION

### SEMANTIC

Contains governed business definitions exposed to conversational analytics.

Primary object:

- SEMANTIC.CUSTOMER_INTELLIGENCE_VIEW

### VALIDATION

Contains deterministic SQL tests and AI evaluation datasets.

Planned objects:

- VALIDATION.METRIC_RECONCILIATION
- VALIDATION.AGENT_GOLDEN_TEST_SET
- VALIDATION.AGENT_TEST_RESULTS

---

## 8. Core Business Metrics

The first version of the governed metric layer will include:

### Customer Metrics

- Total Customers
- Churned Customers
- Retained Customers
- Churn Rate
- Retention Rate

### Revenue Metrics

- Total Revenue
- Average Monthly Charge
- Average Customer Revenue
- Churned Customer Revenue
- Revenue at Risk
- Average Revenue of Churned Customers

### Customer Value Metrics

- Average CLTV
- CLTV of Churned Customers
- High-Value Customer Count
- High-Value Customer Churn Rate

### Product / Customer Behavior Metrics

- Churn Rate by Contract Type
- Churn Rate by Payment Method
- Churn Rate by Tenure Band
- Churn Rate by Offer
- Churn Rate by Internet Service
- Churn Rate by Support Adoption
- Churn Rate by Product / Service Adoption
- Churn Rate by Satisfaction Score

All metrics must have one approved definition and should produce consistent results across SQL, the semantic layer, the AI agent, and Streamlit.

---

## 9. Analytical Principles

The project distinguishes between:

### Churn Rate

How likely customers within a segment are to churn.

### Churn Volume

How many churned customers come from a segment.

### Revenue Exposure

How much business value is associated with churned customers or high-risk segments.

These concepts should not be treated as interchangeable.

A segment may have a high churn rate but low financial impact, while another may have a lower churn rate but represent substantially more customer or revenue exposure.

---

## 10. Business Questions

The analytical platform should be able to answer questions such as:

### Executive Performance

- What is the overall churn rate?
- How many customers churned?
- How much revenue is associated with churned customers?
- What is the average CLTV of churned versus retained customers?

### Customer Segmentation

- Which customer segments have the highest churn rate?
- Which tenure groups have the highest churn?
- How does churn vary by contract type?
- How does churn differ by payment method?
- Which customer groups combine high churn and high customer value?

### Product Analytics

- Which products and services are associated with higher churn?
- How does churn differ between customers with and without technical support?
- Which offers have the highest and lowest churn rates?
- How does product adoption differ between churned and retained customers?

### Revenue & Value

- Which customer segments represent the highest revenue at risk?
- Which segments contribute most to churned revenue?
- Which high-value customers or segments show elevated churn?
- Which segments combine high CLTV, high monthly charges, and high churn?

### Customer Experience

- How does satisfaction relate to churn?
- What are the most common churn categories?
- What are the most common reasons customers leave?
- Which customer segments are most affected by competitor-related churn?

### Diagnostic Analytics

- What characteristics are most common among churned customers?
- Which factors are most strongly associated with churn?
- Which segments should analysts investigate first?

The platform should distinguish association from causation and avoid claiming that a characteristic causes churn unless the analysis supports a causal conclusion.

---

## 11. Semantic Layer

The semantic layer will translate technical data structures into governed business concepts.

It will define:

- Business-friendly dimension names
- Approved measures
- Metric formulas
- Field descriptions
- Synonyms
- Categorical values
- Business definitions
- Verified analytical queries

Examples of dimensions:

- Contract Type
- Payment Method
- Tenure Band
- Customer Value Segment
- Satisfaction Segment
- Internet Service
- Offer
- Product Adoption
- Churn Category
- Geography

Examples of governed measures:

- Total Customers
- Churned Customers
- Churn Rate
- Retention Rate
- Total Revenue
- Revenue at Risk
- Average Monthly Charge
- Average CLTV

The AI agent should use these approved semantic definitions instead of independently inventing calculations.

---

## 12. AI Agent

The project will include a specialized Snowflake Cortex Agent:

**Customer Intelligence Agent**

The agent will answer natural-language questions about:

- Customer performance
- Churn
- Segmentation
- Revenue exposure
- Product adoption
- Customer value
- Retention indicators

The primary analytical tool will be Cortex Analyst connected to the governed semantic layer.

The agent must:

- Use approved metrics
- Use the semantic layer for quantitative analysis
- Avoid inventing fields or definitions
- Avoid unsupported causal claims
- Identify data limitations
- Clarify ambiguous questions
- Report relevant sample sizes when necessary
- Distinguish rate, volume, and financial impact
- Provide evidence before business interpretation

Cortex Search will only be introduced if a legitimate unstructured data source is added to the project.

---

## 13. AI Validation

A core component of this project is validation of AI-generated analytical answers.

A golden test set will contain representative business questions with:

- Expected metric
- Expected analytical tool
- Approved SQL calculation
- Expected result
- Validation tolerance
- Expected limitations

The validation framework will evaluate:

- Metric accuracy
- SQL consistency
- Correct tool selection
- Unsupported claims
- Response completeness
- Business relevance

The objective is to demonstrate that conversational analytics can be evaluated against deterministic analytical logic.

---

## 14. Python Analytics

Python will complement Snowflake SQL where analytical methods are more appropriate outside simple aggregation.

Potential applications include:

- Churn association analysis
- Logistic regression
- Feature importance
- Customer segmentation
- Statistical comparison
- AI output validation

Predictive relationships will be described as predictive or associative rather than causal unless causality can be established.

---

## 15. Streamlit Application

The final Streamlit in Snowflake application will provide a simple executive analytics interface.

Planned sections:

### Executive Overview

- Total Customers
- Churn Rate
- Churned Customers
- Revenue at Risk
- Average CLTV

### Customer & Product Analytics

- Customer segmentation
- Contract performance
- Product/service adoption
- Payment behavior
- Tenure analysis

### Churn & Retention

- Churn by segment
- Churn reasons
- Satisfaction
- High-value churn

### Revenue & Customer Value

- Revenue exposure
- CLTV
- High-value customer analysis
- Revenue concentration

### Ask the Customer Intelligence Agent

Natural-language conversational interface powered by Snowflake Cortex.

---

## 16. Data Quality & Reconciliation

Before metrics are exposed to users or AI systems, the project will validate:

- Customer ID uniqueness
- Join completeness
- Duplicate records
- Missing values
- Data type consistency
- Categorical consistency
- Churn counts
- Revenue totals
- Customer counts
- Metric reconciliation

The classic churn dataset may be used as an additional reconciliation reference where applicable.

---

## 17. Payments / Product Analytics Transferability

Although churn is the primary business use case, the analytical patterns demonstrated in this project are transferable to payments and product analytics.

Examples include:

Customer churn → Customer / merchant attrition

Service adoption → Product / feature adoption

Monthly charges → Customer revenue

Payment method → Payment behavior

Customer lifecycle → Account lifecycle

CLTV → Customer lifetime value

Revenue at risk → Revenue or payment-volume exposure

Customer segmentation → Customer / merchant segmentation

Retention analytics → Lifecycle management

Performance monitoring → Product / payments KPI reporting

The goal is to demonstrate reusable analytical capabilities rather than a telecom-specific dashboard.

---

## 18. Skills Demonstrated

- Snowflake
- SQL
- Python
- Data Modeling
- Analytics Engineering
- Product Analytics
- Customer Analytics
- Metric Definition
- Metric Governance
- Semantic Layers
- Snowflake Cortex
- Cortex Analyst
- AI Agents
- Agentic AI Development
- Conversational Analytics
- AI Output Validation
- Data Quality
- Reconciliation
- Customer Segmentation
- Revenue Analytics
- Customer Lifetime Value
- Executive Reporting
- Streamlit in Snowflake
- Business Intelligence
- Data Storytelling

---

## 19. Definition of Success

The project will be considered complete when a business user can:

1. Open the Streamlit analytics application.
2. Review governed customer and product KPIs.
3. Explore churn, customer value, product adoption, and revenue exposure.
4. Ask business questions in natural language.
5. Receive answers based on approved semantic definitions.
6. Validate important AI-generated metrics against deterministic SQL logic.
7. Understand the limitations and source of the analysis.

The final repository should allow a recruiter or interviewer to understand both the business problem and the technical implementation without needing access to the original development environment.