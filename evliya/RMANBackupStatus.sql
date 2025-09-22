-- =====================================================================================
-- Description  : Monitors RMAN backup jobs status for the last 7 days
-- =====================================================================================
-- Purpose:
--   - Display all RMAN backup jobs from the last 7 days
--   - Show backup duration, size, compression ratio and performance metrics
--   - Highlight failed or problematic backups that need attention
-- =====================================================================================

SELECT 
    start_time AS "Backup Start",
    end_time AS "Backup End",
    input_type AS "Backup Type",
    status AS "Status",
    ROUND(elapsed_seconds/60, 2) AS "Duration (Min)",
    ROUND(input_bytes/1024/1024/1024, 2) AS "Input GB",
    ROUND(output_bytes/1024/1024/1024, 2) AS "Output GB",
    ROUND(compression_ratio, 2) AS "Compression Ratio",
    input_bytes_per_sec/1024/1024 AS "MB/sec",
    output_device_type AS "Device Type",
    CASE 
        WHEN status NOT IN ('COMPLETED', 'RUNNING') THEN 'ATTENTION REQUIRED!'
        ELSE 'OK'
    END AS "Action Required"
FROM v$rman_backup_job_details
WHERE start_time > SYSDATE - 7
ORDER BY start_time DESC;
