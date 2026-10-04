-- 1. Create Warehouse and Database Architecture
CREATE WAREHOUSE IF NOT EXISTS OT_IT_WH
    WAREHOUSE_SIZE = 'SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE;

CREATE DATABASE IF NOT EXISTS OT_IT_DB;
CREATE SCHEMA IF NOT EXISTS OT_IT_DB.PREDICTIVE_MAINTENANCE;

USE WAREHOUSE OT_IT_WH;
USE SCHEMA OT_IT_DB.PREDICTIVE_MAINTENANCE;

-- 2. Create Core Tables
CREATE TABLE IF NOT EXISTS ot_sensor_telemetry (
    telemetry_id VARCHAR DEFAULT UUID_STRING(),
    asset_id VARCHAR NOT NULL,
    recorded_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    vibration_mm_s FLOAT,
    temperature_c FLOAT,
    rpm INT
);

CREATE TABLE IF NOT EXISTS erp_asset_master (
    asset_id VARCHAR PRIMARY KEY,
    asset_name VARCHAR,
    plant_location VARCHAR,
    manufacturer VARCHAR,
    install_date DATE
);

CREATE TABLE IF NOT EXISTS erp_work_orders (
    work_order_id VARCHAR DEFAULT UUID_STRING(),
    asset_id VARCHAR,
    created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    failure_mode VARCHAR,
    notes TEXT
);

CREATE TABLE IF NOT EXISTS pdf_manual_chunks (
    doc_id VARCHAR DEFAULT UUID_STRING(),
    file_name VARCHAR,
    chunk_id INT,
    chunk_text VARCHAR,
    last_updated TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- 3. Populate Initial Test Data
INSERT INTO erp_asset_master (asset_id, asset_name, plant_location, manufacturer, install_date) VALUES
('CM-102', 'Conveyor Drive Motor CM-102', 'Plant North - Line 1', 'Siemens', '2021-03-15'),
('P-301', 'High Pressure Slurry Pump P-301', 'Plant South - Line 2', 'Flowserve', '2019-08-22');

INSERT INTO ot_sensor_telemetry (asset_id, vibration_mm_s, temperature_c, rpm) VALUES
('CM-102', 5.2, 88.5, 1750),
('CM-102', 4.9, 86.1, 1745),
('P-301', 1.2, 42.0, 1800);

INSERT INTO erp_work_orders (asset_id, failure_mode, notes) VALUES
('CM-102', 'BEARING_OVERHEAT', 'Replaced drive end bearing after high vibration recorded at 5.0 mm/s.'),
('P-301', 'SEAL_LEAK', 'Routine seal replacement on fluid pump during quarterly service.');

INSERT INTO pdf_manual_chunks (file_name, chunk_id, chunk_text) VALUES
('Conveyor_Motor_CM102_Manual.pdf', 1, 'Section 4.2 Bearing Maintenance: Vibrations exceeding 4.5 mm/s accompanied by housing temperatures over 80C indicate impending bearing cage failure. Immediate lubrication or replacement of drive end bearing required.'),
('Conveyor_Motor_CM102_Manual.pdf', 2, 'Section 5.1 Alignment: Shaft misalignment causes excessive 2X vibration harmonics. Ensure laser alignment within 0.05mm tolerance.');
