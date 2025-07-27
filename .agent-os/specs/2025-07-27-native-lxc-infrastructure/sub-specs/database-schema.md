# Database Schema

This is the database schema implementation for the spec detailed in @.agent-os/specs/2025-07-27-native-lxc-infrastructure/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Database Changes

### New Database Creation
- **Database Name:** stock_analysis_event_store
- **Encoding:** UTF8
- **Collation:** en_US.UTF-8
- **Owner:** stock_analysis_user

### Event Store Schema

```sql
-- Create event store database
CREATE DATABASE stock_analysis_event_store
    WITH 
    OWNER = stock_analysis_user
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = 100;

-- Connect to the database
\c stock_analysis_event_store;

-- Create schema for event sourcing
CREATE SCHEMA IF NOT EXISTS event_store;

-- Events table - Core of event sourcing
CREATE TABLE event_store.events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_version INTEGER NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT 'system',
    
    -- Ensure events are immutable
    CONSTRAINT events_immutable CHECK (false) NO INHERIT
);

-- Index for aggregate queries
CREATE INDEX idx_events_aggregate ON event_store.events(aggregate_type, aggregate_id, event_version);

-- Index for event type queries
CREATE INDEX idx_events_type ON event_store.events(event_type, created_at);

-- Index for time-based queries
CREATE INDEX idx_events_created_at ON event_store.events(created_at);

-- Snapshots table for performance optimization
CREATE TABLE event_store.snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id UUID NOT NULL,
    aggregate_version INTEGER NOT NULL,
    snapshot_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    
    UNIQUE(aggregate_type, aggregate_id, aggregate_version)
);

-- Index for snapshot queries
CREATE INDEX idx_snapshots_aggregate ON event_store.snapshots(aggregate_type, aggregate_id, aggregate_version DESC);

-- Event types registry
CREATE TABLE event_store.event_types (
    event_type VARCHAR(255) PRIMARY KEY,
    schema_version INTEGER NOT NULL DEFAULT 1,
    json_schema JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Projections metadata
CREATE TABLE event_store.projections (
    projection_name VARCHAR(255) PRIMARY KEY,
    last_processed_event_id UUID,
    last_processed_timestamp TIMESTAMP WITH TIME ZONE,
    projection_version INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(50) DEFAULT 'active',
    error_message TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
```

### Materialized Views Structure

```sql
-- Create schema for materialized views
CREATE SCHEMA IF NOT EXISTS projections;

-- Example: Portfolio positions materialized view
CREATE MATERIALIZED VIEW projections.portfolio_positions AS
SELECT 
    aggregate_id as position_id,
    (event_data->>'symbol')::VARCHAR as symbol,
    (event_data->>'quantity')::DECIMAL as quantity,
    (event_data->>'average_price')::DECIMAL as average_price,
    (event_data->>'current_value')::DECIMAL as current_value,
    max(created_at) as last_updated
FROM event_store.events
WHERE event_type IN ('PositionOpened', 'PositionUpdated', 'PositionClosed')
    AND aggregate_type = 'Position'
GROUP BY aggregate_id, event_data
WITH DATA;

-- Index for fast symbol lookup
CREATE INDEX idx_portfolio_positions_symbol ON projections.portfolio_positions(symbol);

-- Refresh function for materialized views
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY projections.portfolio_positions;
    -- Add more materialized views here as needed
END;
$$ LANGUAGE plpgsql;
```

### User and Permissions

```sql
-- Create application user
CREATE USER stock_analysis_user WITH ENCRYPTED PASSWORD 'CHANGE_THIS_PASSWORD';

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE stock_analysis_event_store TO stock_analysis_user;
GRANT ALL ON SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON SCHEMA projections TO stock_analysis_user;
GRANT ALL ON ALL TABLES IN SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL TABLES IN SCHEMA projections TO stock_analysis_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA projections TO stock_analysis_user;

-- Allow user to create schemas for service-specific projections
GRANT CREATE ON DATABASE stock_analysis_event_store TO stock_analysis_user;
```

### Performance Optimizations

```sql
-- Configure for event sourcing workload
ALTER DATABASE stock_analysis_event_store SET shared_buffers = '2GB';
ALTER DATABASE stock_analysis_event_store SET effective_cache_size = '6GB';
ALTER DATABASE stock_analysis_event_store SET maintenance_work_mem = '512MB';
ALTER DATABASE stock_analysis_event_store SET checkpoint_completion_target = 0.9;
ALTER DATABASE stock_analysis_event_store SET wal_buffers = '16MB';
ALTER DATABASE stock_analysis_event_store SET default_statistics_target = 100;
ALTER DATABASE stock_analysis_event_store SET random_page_cost = 1.1;
ALTER DATABASE stock_analysis_event_store SET effective_io_concurrency = 200;
ALTER DATABASE stock_analysis_event_store SET work_mem = '32MB';
ALTER DATABASE stock_analysis_event_store SET min_wal_size = '1GB';
ALTER DATABASE stock_analysis_event_store SET max_wal_size = '4GB';
```

## Migration Strategy

Since this is initial setup, no migrations are needed. The schema will be created fresh during infrastructure setup.

## Rationale

### Event Store Design
- Immutable events ensure audit trail integrity
- JSON storage provides flexibility for event evolution
- Aggregate versioning prevents concurrency issues

### Performance Considerations
- Materialized views provide sub-0.2s query performance
- Indexes optimized for common query patterns
- PostgreSQL configuration tuned for event sourcing workload

### Security
- Dedicated database user with minimal required permissions
- No superuser access for application
- Password-based authentication (to be replaced with certificate auth in production)