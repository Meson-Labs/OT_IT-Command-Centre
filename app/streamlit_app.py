import streamlit as st
import json
from snowflake.snowpark.context import get_active_session

# Initialize Snowpark Session
session = get_active_session()

st.set_page_config(
    page_title="OT/IT RAG Root Cause Investigator", 
    layout="wide"
)

st.title("🛠️ Root Cause Investigator (Cortex Search + LLM)")
st.caption("Converging PDF Equipment Manuals & Maintenance Logs with Snowflake Cortex")

# Input Query Section
user_query = st.text_input(
    "Describe the asset issue or enter anomaly symptoms:",
    value="High vibration (>4.8 mm/s) and bearing overheating on Conveyor Motor CM-102",
    placeholder="e.g. Pump P-301 seal leak and pressure drop"
)

# Configuration Options
with st.sidebar:
    st.header("Search & RAG Settings")
    model_choice = st.selectbox(
        "Cortex LLM Model", 
        ["mistral-large2", "llama3.1-70b", "snowflake-arctic"],
        index=0
    )
    top_k = st.slider("Top Sources to Retrieve (k)", min_value=1, max_value=10, value=4)
    source_filter = st.multiselect(
        "Filter Source Types", 
        ["PDF_MANUAL", "MAINTENANCE_LOG"],
        default=["PDF_MANUAL", "MAINTENANCE_LOG"]
    )

if st.button("🔍 Run Root Cause Analysis", type="primary"):
    with st.spinner("Querying Cortex Search Index & Generating AI Diagnosis..."):
        try:
            # 1. Build Cortex Search Filter Payload
            filter_dict = {}
            if len(source_filter) == 1:
                filter_dict = {"@eq": {"source_type": source_filter[0]}}
            elif len(source_filter) > 1:
                filter_dict = {"@or": [{"@eq": {"source_type": s}} for s in source_filter]}

            search_request = {
                "query": user_query,
                "columns": ["search_id", "source_type", "asset_or_file_reference", "search_content"],
                "limit": top_k
            }
            if filter_dict:
                search_request["filter"] = filter_dict

            # 2. Execute Cortex Search Query via SQL
            search_json_str = json.dumps(search_request).replace("'", "''")
            search_sql = f"""
                SELECT SNOWFLAKE.CORTEX.SEARCH_PREVIEW(
                    'equipment_rag_search_service',
                    '{search_json_str}'
                ) AS search_results
            """
            raw_results = session.sql(search_sql).collect()[0][0]
            parsed_results = json.loads(raw_results)
            retrieved_chunks = parsed_results.get("results", [])

            # 3. Create Side-by-Side Layout
            col_sources, col_analysis = st.columns([1, 1], gap="medium")

            # --- LEFT COLUMN: Retrieved Sources & Grounding Data ---
            with col_sources:
                st.subheader(f"📚 Grounding Context ({len(retrieved_chunks)} Sources)")
                
                if not retrieved_chunks:
                    st.warning("No relevant document chunks or logs found matching criteria.")
                    context_text = "No context available."
                else:
                    context_chunks = []
                    for idx, chunk in enumerate(retrieved_chunks, start=1):
                        source_type = chunk.get("source_type", "UNKNOWN")
                        ref = chunk.get("asset_or_file_reference", "N/A")
                        content = chunk.get("search_content", "")
                        
                        context_chunks.append(f"Source [{idx}] ({source_type} - {ref}): {content}")
                        
                        st.markdown(f"**[{idx}] `{source_type}`** — *{ref}*")
                        with st.expander("View Fragment Excerpt...", expanded=(idx == 1)):
                            st.write(content)
                        st.divider()
                        
                    context_text = "\n\n".join(context_chunks)

            # --- RIGHT COLUMN: LLM Root Cause Diagnosis ---
            with col_analysis:
                st.subheader("🤖 Cortex LLM Root Cause Diagnosis")
                
                if retrieved_chunks:
                    prompt = f"""
                    You are a Lead Reliability Engineer. Analyze the user's issue based strictly on the provided Context Sources from equipment manuals and past work orders.

                    USER ISSUE / SYMPTOM:
                    {user_query}

                    RETRIEVED GROUNDING CONTEXT:
                    {context_text}

                    INSTRUCTIONS:
                    1. Provide a concise 2-sentence probable Root Cause summary.
                    2. List 3-4 recommended step-by-step corrective maintenance actions.
                    3. Explicitly cite which Source numbers (e.g., [1], [2]) support each recommendation.
                    """
                    
                    escaped_prompt = prompt.replace("'", "''")
                    llm_sql = f"""
                        SELECT SNOWFLAKE.CORTEX.COMPLETE(
                            '{model_choice}',
                            '{escaped_prompt}'
                        ) AS llm_response
                    """
                    llm_response = session.sql(llm_sql).collect()[0][0]
                    
                    st.info(llm_response)
                    
                    st.markdown("### Next Actions")
                    c1, c2 = st.columns(2)
                    with c1:
                        if st.button("⚡ Create Automated Work Order"):
                            st.success("Work order draft created in SAP/ServiceNow!")
                    with c2:
                        st.download_button(
                            label="📥 Export Report (PDF/MD)",
                            data=f"# RAG Maintenance Report\n\n## Symptom\n{user_query}\n\n## Analysis\n{llm_response}",
                            file_name="root_cause_report.md",
                            mime="text/markdown"
                        )

        except Exception as e:
            st.error(f"Error executing RAG pipeline: {str(e)}")
