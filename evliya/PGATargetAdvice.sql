-- =====================================================================================
-- Script Name  : pga_target_advice.sql
-- Description  : Shows PGA target advice for optimal PGA sizing
-- =====================================================================================
-- Purpose:
--   - Display PGA target recommendations
--   - Show estimated cache hit percentage for different PGA sizes
--   - Help determine optimal PGA_TARGET value
-- =====================================================================================

SELECT
    ROUND(pga_target_for_estimate / 1024 / 1024 / 1024, 2) AS estimated_pga_gb,
    pga_target_factor,
    estd_pga_cache_hit_percentage,
    estd_overalloc_count
FROM
    v$pga_target_advice
ORDER BY
    pga_target_factor;
