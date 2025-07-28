-- Stock Analysis Event Store Schema
CREATE SCHEMA IF NOT EXISTS event_store;

-- Events table
CREATE TABLE IF NOT EXISTS event_store.events (
    id BIGSERIAL PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    event_metadata JSONB,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    version INTEGER NOT NULL
);

-- Indexes for performance
CREATE INDEX idx_events_aggregate_id ON event_store.events(aggregate_id);
CREATE INDEX idx_events_aggregate_type ON event_store.events(aggregate_type);
CREATE INDEX idx_events_event_type ON event_store.events(event_type);
CREATE INDEX idx_events_created_at ON event_store.events(created_at);

-- Snapshots table
CREATE TABLE IF NOT EXISTS event_store.snapshots (
    id BIGSERIAL PRIMARY KEY,
    aggregate_id UUID NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    snapshot_data JSONB NOT NULL,
    snapshot_metadata JSONB,
    version INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP
);

-- Index for snapshots
CREATE INDEX idx_snapshots_aggregate_id ON event_store.snapshots(aggregate_id);

-- Grant permissions
GRANT ALL ON SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL TABLES IN SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA event_store TO stock_analysis_user;
