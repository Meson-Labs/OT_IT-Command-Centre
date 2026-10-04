# OT/IT Data Convergence & Predictive Maintenance on Snowflake

This solution converges real-time Operational Technology (OT) telemetry with Enterprise IT context (ERP, Work Orders, Manuals) to predict failures, calculate dynamic OEE, and support RAG-based root cause analysis using Snowflake Cortex.

## 🚀 Getting Started

1. **Database Setup**: Execute `sql/01_setup_database_and_tables.sql` in Snowsight to initialize warehouses, schemas, core tables, and mock data.
2. **Cortex Search Index**: Run `sql/02_cortex_search_service.sql` to build the unified RAG knowledge base view and deploy the Cortex Search Service.
3. **Features & OEE Views**: Run `sql/03_dynamic_tables_and_oee.sql` to build real-time feature aggregation tables and OEE calculation logic.
4. **Deploy Streamlit App**: Create a new **Streamlit in Snowflake (SiS)** app in project directory `OT_IT_DB.PREDICTIVE_MAINTENANCE` and paste the contents of `app/streamlit_app.py`.

## 🛠️ Components
- **Snowpipe Streaming / Telemetry Table**: OT vibration, temperature, RPM ingress.
- **Snowflake Cortex Search**: Native vector indexing across PDF chunks and maintenance logs.
- **Snowflake Cortex LLM**: Root cause analysis and action recommendation generation.
- **Streamlit in Snowflake**: Dual-pane command center UI.