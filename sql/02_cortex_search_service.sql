USE WAREHOUSE OT_IT_WH;
USE SCHEMA OT_IT_DB.PREDICTIVE_MAINTENANCE;

-- Unified RAG View merging unstructured manuals and logs
CREATE OR REPLACE VIEW v_unified_knowledge_base AS
SELECT 
    CONCAT('PDF_', doc_id) AS search_id,
    'PDF_MANUAL' AS source_type,
    file_name AS asset_or_file_reference,
    chunk_text AS search_content,
    last_updated
FROM pdf_manual_chunks
UNION ALL
SELECT 
    CONCAT('LOG_', work_order_id) AS search_id,
    'MAINTENANCE_LOG' AS source_type,
    asset_id AS asset_or_file_reference,
    CONCAT('Failure Mode: ', failure_mode, ' | Operator Notes: ', notes) AS search_content,
    created_at AS last_updated
FROM erp_work_orders;

-- Deploy Cortex Vector Search Service
CREATE OR REPLACE CORTEX SEARCH SERVICE equipment_rag_search_service
    ON search_content
    ATTRIBUTES source_type, asset_or_file_reference
    WAREHOUSE = OT_IT_WH
    TARGET_LAG = '1 hour'
AS 
SELECT 
    search_id,
    source_type,
    asset_or_file_reference,
    search_content,
    last_updated
FROM v_unified_knowledge_base;
