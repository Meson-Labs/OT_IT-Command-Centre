USE WAREHOUSE OT_IT_WH;
USE SCHEMA OT_IT_DB.PREDICTIVE_MAINTENANCE;

-- Real-Time Aggregated Feature Store
CREATE OR REPLACE DYNAMIC TABLE dt_asset_health_features
TARGET_LAG = '1 minute'
WAREHOUSE = OT_IT_WH
AS
SELECT 
    t.asset_id,
    a.asset_name,
    a.plant_location,
    MAX(t.recorded_at) AS last_telemetry_time,
    AVG(t.vibration_mm_s) AS avg_vibration_10m,
    MAX(t.vibration_mm_s) AS max_vibration_10m,
    AVG(t.temperature_c) AS avg_temp_10m,
    AVG(t.rpm) AS avg_rpm_10m
FROM ot_sensor_telemetry t
JOIN erp_asset_master a ON t.asset_id = a.asset_id
WHERE t.recorded_at >= DATEADD('minute', -10, CURRENT_TIMESTAMP())
GROUP BY t.asset_id, a.asset_name, a.plant_location;

-- Dynamic OEE Calculation View
CREATE OR REPLACE VIEW v_oee_metrics AS
SELECT 
    asset_id,
    DATE_TRUNC('hour', recorded_at) AS metric_hour,
    COUNT(CASE WHEN rpm > 0 THEN 1 END) / NULLIF(COUNT(*), 0) AS availability,
    AVG(rpm) / 1800.0 AS performance,
    0.985 AS quality,
    (COUNT(CASE WHEN rpm > 0 THEN 1 END) / NULLIF(COUNT(*), 0)) * (AVG(rpm) / 1800.0) * 0.985 AS oee
FROM ot_sensor_telemetry
GROUP BY asset_id, DATE_TRUNC('hour', recorded_at);
