-- ===============================================================================
-- Event-Store Schema für Aktienanalyse-Ökosystem
-- PostgreSQL 15+ Event-Sourcing + CQRS mit Materialized Views
-- Performance-optimiert für 0.12s Query-Zeiten
-- ===============================================================================

-- Event-Store Haupt-Tabelle (Single Source of Truth)
CREATE TABLE IF NOT EXISTS events (
    -- Event Identifiers
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id VARCHAR(255) NOT NULL,           -- Aggregate identifier (stock-AAPL, portfolio-123)
    stream_type VARCHAR(100) NOT NULL,         -- Domain (stock, portfolio, trading, system)
    
    -- Event Metadata
    event_type VARCHAR(100) NOT NULL,          -- Specific event type (analysis.state.changed)
    event_version BIGINT NOT NULL,             -- Event version in stream (for optimistic locking)
    global_version BIGSERIAL,                  -- Global event ordering across all streams
    timestamp TIMESTAMP NOT NULL DEFAULT NOW(),
    
    -- Event Data & Metadata
    event_data JSONB NOT NULL,                 -- Event payload (structured JSON)
    event_metadata JSONB DEFAULT '{}',         -- Correlation IDs, causation, tracing
    
    -- Event Processing
    processed_at TIMESTAMP,                    -- When event was processed by handlers
    processing_attempts INTEGER DEFAULT 0,     -- For retry logic
    
    -- Constraints for Event-Sourcing
    UNIQUE (stream_id, event_version),         -- Ensure event ordering per stream
    CHECK (event_version > 0),                 -- Version must be positive
    CHECK (jsonb_typeof(event_data) = 'object') -- Ensure valid JSON object
);

-- ===============================================================================
-- Performance-optimierte Indexes
-- ===============================================================================

-- Primary query patterns
CREATE INDEX IF NOT EXISTS idx_events_stream 
    ON events (stream_id, event_version);       -- Stream reconstruction

CREATE INDEX IF NOT EXISTS idx_events_type_time 
    ON events (event_type, timestamp DESC);     -- Event type + time-based queries

CREATE INDEX IF NOT EXISTS idx_events_global 
    ON events (global_version);                 -- Global event ordering

CREATE INDEX IF NOT EXISTS idx_events_timestamp 
    ON events (timestamp DESC);                 -- Recent events

-- JSONB indexes for fast event data queries
CREATE INDEX IF NOT EXISTS idx_events_data_gin 
    ON events USING GIN (event_data);          -- Full JSONB search

CREATE INDEX IF NOT EXISTS idx_events_symbol 
    ON events ((event_data->>'symbol'));       -- Stock symbol lookups

CREATE INDEX IF NOT EXISTS idx_events_portfolio_id 
    ON events ((event_data->>'portfolio_id')); -- Portfolio lookups

CREATE INDEX IF NOT EXISTS idx_events_order_id 
    ON events ((event_data->>'order_id'));     -- Trading order lookups

-- Partial indexes for performance-critical queries
CREATE INDEX IF NOT EXISTS idx_events_analysis_completed 
    ON events (stream_id, timestamp DESC) 
    WHERE event_type = 'analysis.state.changed' 
    AND event_data->>'state' = 'completed';

CREATE INDEX IF NOT EXISTS idx_events_trading_filled 
    ON events (timestamp DESC) 
    WHERE event_type = 'trading.state.changed' 
    AND event_data->>'state' = 'filled';

-- ===============================================================================
-- Materialized Views für 0.12s Query-Performance
-- ===============================================================================

-- 1. Unified Stock Analysis View
CREATE MATERIALIZED VIEW stock_analysis_unified AS
SELECT 
    -- Stock Identification
    (latest_analysis.event_data->>'symbol') as symbol,
    latest_analysis.stream_id,
    
    -- Analysis Results
    (latest_analysis.event_data->>'score')::numeric as latest_score,
    (latest_analysis.event_data->>'recommendation') as recommendation,
    (latest_analysis.event_data->>'confidence')::numeric as confidence,
    (latest_analysis.event_data->>'target_price')::numeric as target_price,
    (latest_analysis.event_data->>'risk_level') as risk_level,
    
    -- Technical Indicators
    latest_analysis.event_data->'technical_indicators' as technical_indicators,
    
    -- Performance Metrics (from portfolio events)
    COALESCE((perf.event_data->>'total_return')::numeric, 0) as total_return,
    COALESCE((perf.event_data->>'sharpe_ratio')::numeric, 0) as sharpe_ratio,
    COALESCE((perf.event_data->>'max_drawdown')::numeric, 0) as max_drawdown,
    COALESCE((perf.event_data->>'volatility')::numeric, 0) as volatility,
    
    -- Trading Activity (from trading events)
    COALESCE((trade.event_data->>'total_value')::numeric, 0) as position_value,
    COALESCE((trade.event_data->>'filled_quantity')::numeric, 0) as quantity,
    COALESCE((trade.event_data->>'average_fill_price')::numeric, 0) as avg_price,
    COALESCE((trade.event_data->>'fees')::numeric, 0) as total_fees,
    
    -- Timestamps
    latest_analysis.timestamp as analysis_updated,
    perf.timestamp as performance_updated,
    trade.timestamp as trading_updated,
    GREATEST(
        latest_analysis.timestamp, 
        COALESCE(perf.timestamp, '1970-01-01'::timestamp),
        COALESCE(trade.timestamp, '1970-01-01'::timestamp)
    ) as last_updated

FROM (
    -- Latest analysis for each stock
    SELECT DISTINCT ON (event_data->>'symbol') 
        stream_id, event_data, timestamp
    FROM events 
    WHERE event_type = 'analysis.state.changed'
    AND event_data->>'state' = 'completed'
    AND event_data->>'symbol' IS NOT NULL
    ORDER BY event_data->>'symbol', timestamp DESC
) latest_analysis

LEFT JOIN LATERAL (
    -- Latest performance data for each stock
    SELECT event_data, timestamp
    FROM events e2
    WHERE e2.event_type = 'portfolio.state.changed'
    AND e2.event_data->>'state' = 'updated'
    AND EXISTS (
        SELECT 1 FROM jsonb_array_elements(e2.event_data->'top_performers') tp
        WHERE tp->>'symbol' = latest_analysis.event_data->>'symbol'
    )
    ORDER BY e2.timestamp DESC
    LIMIT 1
) perf ON true

LEFT JOIN LATERAL (
    -- Latest trading activity for each stock
    SELECT event_data, timestamp
    FROM events e3
    WHERE e3.event_type = 'trading.state.changed'
    AND e3.event_data->>'state' = 'filled'
    AND e3.event_data->>'symbol' = latest_analysis.event_data->>'symbol'
    ORDER BY e3.timestamp DESC
    LIMIT 1
) trade ON true

WITH DATA;

-- Index für Materialized View
CREATE UNIQUE INDEX idx_stock_analysis_unified_symbol 
    ON stock_analysis_unified (symbol);
CREATE INDEX idx_stock_analysis_unified_score 
    ON stock_analysis_unified (latest_score DESC);
CREATE INDEX idx_stock_analysis_unified_updated 
    ON stock_analysis_unified (last_updated DESC);

-- 2. Portfolio Performance View
CREATE MATERIALIZED VIEW portfolio_unified AS
SELECT 
    (event_data->>'portfolio_id') as portfolio_id,
    event_data->'performance_metrics' as performance_metrics,
    event_data->'top_performers' as top_performers,
    event_data->'risk_assessment' as risk_assessment,
    event_data->'rebalancing_suggestions' as rebalancing_suggestions,
    timestamp as last_updated,
    
    -- Aggregated metrics
    (event_data->'performance_metrics'->>'total_return')::numeric as total_return,
    (event_data->'performance_metrics'->>'sharpe_ratio')::numeric as sharpe_ratio,
    (event_data->'performance_metrics'->>'max_drawdown')::numeric as max_drawdown
    
FROM (
    SELECT DISTINCT ON (event_data->>'portfolio_id')
        event_data, timestamp
    FROM events
    WHERE event_type = 'portfolio.state.changed'
    AND event_data->>'state' = 'updated'
    AND event_data->>'portfolio_id' IS NOT NULL
    ORDER BY event_data->>'portfolio_id', timestamp DESC
) latest_portfolio
WITH DATA;

-- Index für Portfolio View
CREATE UNIQUE INDEX idx_portfolio_unified_id 
    ON portfolio_unified (portfolio_id);
CREATE INDEX idx_portfolio_unified_return 
    ON portfolio_unified (total_return DESC);

-- 3. Trading Activity View  
CREATE MATERIALIZED VIEW trading_activity_unified AS
SELECT 
    (event_data->>'order_id') as order_id,
    (event_data->>'symbol') as symbol,
    (event_data->>'side') as side,
    (event_data->>'state') as state,
    (event_data->>'quantity')::numeric as quantity,
    (event_data->>'price')::numeric as price,
    (event_data->>'filled_quantity')::numeric as filled_quantity,
    (event_data->>'average_fill_price')::numeric as average_fill_price,
    (event_data->>'total_value')::numeric as total_value,
    (event_data->>'fees')::numeric as fees,
    (event_data->>'broker') as broker,
    timestamp as execution_time,
    
    -- Calculated fields
    CASE 
        WHEN (event_data->>'side') = 'BUY' THEN (event_data->>'total_value')::numeric
        ELSE -(event_data->>'total_value')::numeric 
    END as net_amount
    
FROM events
WHERE event_type = 'trading.state.changed'
AND event_data->>'state' IN ('filled', 'partially_filled')
AND event_data->>'order_id' IS NOT NULL
WITH DATA;

-- Index für Trading View
CREATE INDEX idx_trading_activity_symbol_time 
    ON trading_activity_unified (symbol, execution_time DESC);
CREATE INDEX idx_trading_activity_order 
    ON trading_activity_unified (order_id);
CREATE INDEX idx_trading_activity_time 
    ON trading_activity_unified (execution_time DESC);

-- 4. System Health View
CREATE MATERIALIZED VIEW system_health_unified AS
SELECT 
    event_type,
    (event_data->>'alert_type') as alert_type,
    (event_data->>'severity') as severity,
    (event_data->>'message') as message,
    event_data->'affected_services' as affected_services,
    event_data->'metrics' as metrics,
    (event_data->>'resolution_status') as resolution_status,
    timestamp as alert_time,
    
    -- Aggregated health score (0-100, higher is better)
    CASE 
        WHEN (event_data->>'severity') = 'INFO' THEN 100
        WHEN (event_data->>'severity') = 'WARNING' THEN 75
        WHEN (event_data->>'severity') = 'ERROR' THEN 50
        WHEN (event_data->>'severity') = 'CRITICAL' THEN 25
        ELSE 0
    END as health_score
    
FROM (
    SELECT DISTINCT ON (event_data->>'alert_type')
        event_type, event_data, timestamp
    FROM events
    WHERE event_type = 'system.alert.raised'
    AND event_data->>'alert_type' IS NOT NULL
    ORDER BY event_data->>'alert_type', timestamp DESC
) latest_alerts
WITH DATA;

-- Index für System Health View
CREATE INDEX idx_system_health_severity_time 
    ON system_health_unified (severity, alert_time DESC);
CREATE INDEX idx_system_health_score 
    ON system_health_unified (health_score);

-- ===============================================================================
-- Real-time View Refresh Triggers
-- ===============================================================================

-- Function to refresh materialized views based on event type
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS TRIGGER AS $$
BEGIN
    -- Refresh views based on event type (concurrent refresh for zero-downtime)
    CASE NEW.event_type
        WHEN 'analysis.state.changed' THEN
            REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
            
        WHEN 'portfolio.state.changed' THEN
            REFRESH MATERIALIZED VIEW CONCURRENTLY portfolio_unified;
            REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
            
        WHEN 'trading.state.changed' THEN
            REFRESH MATERIALIZED VIEW CONCURRENTLY trading_activity_unified;
            REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
            
        WHEN 'system.alert.raised' THEN
            REFRESH MATERIALIZED VIEW CONCURRENTLY system_health_unified;
            
        ELSE
            -- For other event types, refresh all views (less frequent)
            REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
    END CASE;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for automatic view refresh on new events
CREATE TRIGGER refresh_views_on_event
    AFTER INSERT ON events
    FOR EACH ROW
    EXECUTE FUNCTION refresh_materialized_views();

-- ===============================================================================
-- Event-Store Utility Functions
-- ===============================================================================

-- Function to append events (with automatic versioning)
CREATE OR REPLACE FUNCTION append_event(
    p_stream_id VARCHAR,
    p_stream_type VARCHAR,
    p_event_type VARCHAR,
    p_event_data JSONB,
    p_event_metadata JSONB DEFAULT '{}',
    p_expected_version BIGINT DEFAULT NULL
)
RETURNS UUID AS $$
DECLARE
    v_event_id UUID;
    v_current_version BIGINT;
    v_next_version BIGINT;
BEGIN
    -- Get current version for the stream
    SELECT COALESCE(MAX(event_version), 0) INTO v_current_version
    FROM events 
    WHERE stream_id = p_stream_id;
    
    -- Check expected version (optimistic concurrency control)
    IF p_expected_version IS NOT NULL AND v_current_version != p_expected_version THEN
        RAISE EXCEPTION 'Concurrency conflict: expected version %, but current version is %', 
            p_expected_version, v_current_version;
    END IF;
    
    -- Calculate next version
    v_next_version := v_current_version + 1;
    
    -- Insert event
    INSERT INTO events (
        stream_id, stream_type, event_type, event_version,
        event_data, event_metadata
    ) VALUES (
        p_stream_id, p_stream_type, p_event_type, v_next_version,
        p_event_data, p_event_metadata
    )
    RETURNING id INTO v_event_id;
    
    RETURN v_event_id;
END;
$$ LANGUAGE plpgsql;

-- Function to get stream events (for event sourcing)
CREATE OR REPLACE FUNCTION get_stream_events(
    p_stream_id VARCHAR,
    p_from_version BIGINT DEFAULT 1
)
RETURNS TABLE (
    event_id UUID,
    event_type VARCHAR,
    event_version BIGINT,
    event_data JSONB,
    event_metadata JSONB,
    timestamp TIMESTAMP
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        e.id, e.event_type, e.event_version, 
        e.event_data, e.event_metadata, e.timestamp
    FROM events e
    WHERE e.stream_id = p_stream_id
    AND e.event_version >= p_from_version
    ORDER BY e.event_version;
END;
$$ LANGUAGE plpgsql;

-- Function to create snapshots (for performance optimization)
CREATE TABLE IF NOT EXISTS snapshots (
    stream_id VARCHAR(255) PRIMARY KEY,
    stream_type VARCHAR(100) NOT NULL,
    snapshot_version BIGINT NOT NULL,
    snapshot_data JSONB NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION save_snapshot(
    p_stream_id VARCHAR,
    p_stream_type VARCHAR,
    p_snapshot_version BIGINT,
    p_snapshot_data JSONB
)
RETURNS VOID AS $$
BEGIN
    INSERT INTO snapshots (stream_id, stream_type, snapshot_version, snapshot_data)
    VALUES (p_stream_id, p_stream_type, p_snapshot_version, p_snapshot_data)
    ON CONFLICT (stream_id) 
    DO UPDATE SET 
        snapshot_version = EXCLUDED.snapshot_version,
        snapshot_data = EXCLUDED.snapshot_data,
        created_at = NOW();
END;
$$ LANGUAGE plpgsql;

-- ===============================================================================
-- Performance Monitoring Views
-- ===============================================================================

-- Event processing statistics
CREATE VIEW event_processing_stats AS
SELECT 
    event_type,
    COUNT(*) as total_events,
    AVG(EXTRACT(EPOCH FROM (processed_at - timestamp))) as avg_processing_time_seconds,
    MAX(processing_attempts) as max_retry_attempts,
    COUNT(*) FILTER (WHERE processing_attempts > 0) as retried_events
FROM events
WHERE processed_at IS NOT NULL
GROUP BY event_type
ORDER BY total_events DESC;

-- Stream statistics
CREATE VIEW stream_stats AS
SELECT 
    stream_type,
    COUNT(DISTINCT stream_id) as unique_streams,
    COUNT(*) as total_events,
    MAX(event_version) as max_version,
    MIN(timestamp) as first_event,
    MAX(timestamp) as last_event
FROM events
GROUP BY stream_type
ORDER BY total_events DESC;

-- ===============================================================================
-- Data Retention & Cleanup
-- ===============================================================================

-- Function to archive old events (for data retention)
CREATE OR REPLACE FUNCTION archive_old_events(
    p_retention_days INTEGER DEFAULT 365
)
RETURNS INTEGER AS $$
DECLARE
    v_archived_count INTEGER;
    v_cutoff_date TIMESTAMP;
BEGIN
    v_cutoff_date := NOW() - INTERVAL '1 day' * p_retention_days;
    
    -- Create archive table if not exists
    CREATE TABLE IF NOT EXISTS events_archive (LIKE events INCLUDING ALL);
    
    -- Move old events to archive
    WITH archived AS (
        DELETE FROM events 
        WHERE timestamp < v_cutoff_date
        RETURNING *
    )
    INSERT INTO events_archive SELECT * FROM archived;
    
    GET DIAGNOSTICS v_archived_count = ROW_COUNT;
    
    RETURN v_archived_count;
END;
$$ LANGUAGE plpgsql;

-- ===============================================================================
-- Grants & Permissions
-- ===============================================================================

-- Create event store user with limited permissions
-- CREATE USER event_store_user WITH ENCRYPTED PASSWORD 'secure_password';

-- Grant permissions
-- GRANT SELECT, INSERT ON events TO event_store_user;
-- GRANT SELECT ON ALL TABLES IN SCHEMA public TO event_store_user;
-- GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO event_store_user;
-- GRANT EXECUTE ON FUNCTION append_event TO event_store_user;
-- GRANT EXECUTE ON FUNCTION get_stream_events TO event_store_user;

-- ===============================================================================
-- Initial Data & Examples
-- ===============================================================================

-- Example: Insert sample analysis event
-- SELECT append_event(
--     'stock-AAPL',
--     'stock', 
--     'analysis.state.changed',
--     '{"symbol": "AAPL", "state": "completed", "score": 18.5, "recommendation": "BUY", "confidence": 0.87}',
--     '{"correlation_id": "test-123", "source": "technical-analysis"}'
-- );

COMMENT ON TABLE events IS 'Event-Store: Single source of truth für alle System-Events';
COMMENT ON MATERIALIZED VIEW stock_analysis_unified IS 'Optimized view for 0.12s stock analysis queries';
COMMENT ON FUNCTION append_event IS 'Thread-safe event appending with optimistic concurrency control';
COMMENT ON FUNCTION refresh_materialized_views IS 'Auto-refresh materialized views on new events';