#!/bin/bash
# Database initialization script for Stock Analysis ecosystem
# Initializes PostgreSQL Event Store and Redis cluster

set -euo pipefail

# Configuration
DB_NAME="stock_analysis_event_store"
DB_USER="stock_analysis_user"
DB_PASSWORD="${DB_PASSWORD:-CHANGE_THIS_PASSWORD}"
REDIS_PASSWORD="${REDIS_PASSWORD:-CHANGE_THIS_PASSWORD}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Initialize PostgreSQL Event Store
init_postgresql() {
    log_info "Initializing PostgreSQL Event Store..."
    
    # Check if database already exists
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$DB_NAME"; then
        log_info "Database '$DB_NAME' already exists, skipping creation"
        return
    fi
    
    # Create the database initialization SQL
    cat > /tmp/init_event_store.sql << EOF
-- Create database user
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = '$DB_USER') THEN
        CREATE USER $DB_USER WITH ENCRYPTED PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Create event store database
CREATE DATABASE $DB_NAME
    WITH 
    OWNER = $DB_USER
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = 100;

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;

-- Configure database settings
ALTER DATABASE $DB_NAME SET shared_buffers = '2GB';
ALTER DATABASE $DB_NAME SET effective_cache_size = '6GB';
ALTER DATABASE $DB_NAME SET maintenance_work_mem = '512MB';
ALTER DATABASE $DB_NAME SET checkpoint_completion_target = 0.9;
ALTER DATABASE $DB_NAME SET wal_buffers = '16MB';
ALTER DATABASE $DB_NAME SET default_statistics_target = 100;
ALTER DATABASE $DB_NAME SET random_page_cost = 1.1;
ALTER DATABASE $DB_NAME SET effective_io_concurrency = 200;
ALTER DATABASE $DB_NAME SET work_mem = '32MB';
ALTER DATABASE $DB_NAME SET min_wal_size = '1GB';
ALTER DATABASE $DB_NAME SET max_wal_size = '4GB';
EOF

    # Execute the database creation
    sudo -u postgres psql < /tmp/init_event_store.sql
    
    # Create the schema
    cat > /tmp/create_event_schema.sql << 'EOF'
-- Create event store schema
CREATE SCHEMA IF NOT EXISTS event_store;

-- Events table - Core of event sourcing
CREATE TABLE IF NOT EXISTS event_store.events (
    event_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id UUID NOT NULL,
    event_version INTEGER NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    created_by VARCHAR(255) DEFAULT 'system'
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_events_aggregate 
    ON event_store.events(aggregate_type, aggregate_id, event_version);
CREATE INDEX IF NOT EXISTS idx_events_type 
    ON event_store.events(event_type, created_at);
CREATE INDEX IF NOT EXISTS idx_events_created_at 
    ON event_store.events(created_at);

-- Snapshots table for performance optimization
CREATE TABLE IF NOT EXISTS event_store.snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id UUID NOT NULL,
    aggregate_version INTEGER NOT NULL,
    snapshot_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(aggregate_type, aggregate_id, aggregate_version)
);

CREATE INDEX IF NOT EXISTS idx_snapshots_aggregate 
    ON event_store.snapshots(aggregate_type, aggregate_id, aggregate_version DESC);

-- Event types registry
CREATE TABLE IF NOT EXISTS event_store.event_types (
    event_type VARCHAR(255) PRIMARY KEY,
    schema_version INTEGER NOT NULL DEFAULT 1,
    json_schema JSONB NOT NULL,
    description TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Projections metadata
CREATE TABLE IF NOT EXISTS event_store.projections (
    projection_name VARCHAR(255) PRIMARY KEY,
    last_processed_event_id UUID,
    last_processed_timestamp TIMESTAMP WITH TIME ZONE,
    projection_version INTEGER NOT NULL DEFAULT 1,
    status VARCHAR(50) DEFAULT 'active',
    error_message TEXT,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- Create projections schema
CREATE SCHEMA IF NOT EXISTS projections;

-- Example materialized view for portfolio positions
CREATE MATERIALIZED VIEW IF NOT EXISTS projections.portfolio_positions AS
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

CREATE INDEX IF NOT EXISTS idx_portfolio_positions_symbol 
    ON projections.portfolio_positions(symbol);

-- Refresh function for materialized views
CREATE OR REPLACE FUNCTION refresh_materialized_views()
RETURNS void AS \$\$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY projections.portfolio_positions;
    -- Add more materialized views here as needed
END;
\$\$ LANGUAGE plpgsql;

-- Grant permissions
GRANT ALL ON SCHEMA event_store TO $DB_USER;
GRANT ALL ON SCHEMA projections TO $DB_USER;
GRANT ALL ON ALL TABLES IN SCHEMA event_store TO $DB_USER;
GRANT ALL ON ALL TABLES IN SCHEMA projections TO $DB_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA event_store TO $DB_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA projections TO $DB_USER;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA event_store TO $DB_USER;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA projections TO $DB_USER;

-- Allow user to create schemas for service-specific projections
GRANT CREATE ON DATABASE $DB_NAME TO $DB_USER;
EOF

    # Execute schema creation
    sudo -u postgres psql -d "$DB_NAME" < /tmp/create_event_schema.sql
    
    # Clean up temporary files
    rm -f /tmp/init_event_store.sql /tmp/create_event_schema.sql
    
    log_success "PostgreSQL Event Store initialized successfully"
}

# Initialize Redis Cluster
init_redis_cluster() {
    log_info "Initializing Redis cluster..."
    
    # Check if Redis instances are running
    for port in 6379 6380 6381; do
        if ! systemctl is-active --quiet redis-$port; then
            log_error "Redis instance on port $port is not running"
            return 1
        fi
    done
    
    # Check if cluster is already initialized
    if redis-cli -p 6379 -a "$REDIS_PASSWORD" cluster info 2>/dev/null | grep -q "cluster_state:ok"; then
        log_info "Redis cluster already initialized"
        return
    fi
    
    # Create the cluster
    log_info "Creating Redis cluster with 3 nodes..."
    echo "yes" | redis-cli --cluster create \
        127.0.0.1:6379 127.0.0.1:6380 127.0.0.1:6381 \
        --cluster-replicas 0 \
        -a "$REDIS_PASSWORD"
    
    # Verify cluster status
    sleep 2
    if redis-cli -p 6379 -a "$REDIS_PASSWORD" cluster info | grep -q "cluster_state:ok"; then
        log_success "Redis cluster initialized successfully"
    else
        log_error "Redis cluster initialization failed"
        return 1
    fi
    
    # Set up some initial keys for testing
    redis-cli -c -p 6379 -a "$REDIS_PASSWORD" SET health:check "ok" EX 3600
    
    log_success "Redis cluster is ready"
}

# Initialize RabbitMQ
init_rabbitmq() {
    log_info "Initializing RabbitMQ..."
    
    # Check if RabbitMQ is running
    if ! systemctl is-active --quiet rabbitmq-server; then
        log_error "RabbitMQ is not running"
        return 1
    fi
    
    # Wait for RabbitMQ to be fully started
    sleep 5
    
    # Create virtual host
    if ! rabbitmqctl list_vhosts | grep -q "/stock-analysis"; then
        rabbitmqctl add_vhost /stock-analysis
        log_success "Created virtual host: /stock-analysis"
    else
        log_info "Virtual host /stock-analysis already exists"
    fi
    
    # Create user if not exists
    if ! rabbitmqctl list_users | grep -q "stock_analysis"; then
        rabbitmqctl add_user stock_analysis "$RABBITMQ_PASSWORD"
        rabbitmqctl set_user_tags stock_analysis administrator
        log_success "Created RabbitMQ user: stock_analysis"
    else
        log_info "RabbitMQ user stock_analysis already exists"
    fi
    
    # Set permissions
    rabbitmqctl set_permissions -p /stock-analysis stock_analysis ".*" ".*" ".*"
    
    # Create exchanges and queues
    cat > /tmp/rabbitmq_setup.py << 'EOF'
#!/usr/bin/env python3
import pika
import os
import sys

try:
    # Get credentials from environment or arguments
    password = os.environ.get('RABBITMQ_PASSWORD', sys.argv[1] if len(sys.argv) > 1 else 'CHANGE_THIS_PASSWORD')
    
    # Connect to RabbitMQ
    credentials = pika.PlainCredentials('stock_analysis', password)
    parameters = pika.ConnectionParameters(
        'localhost',
        5672,
        '/stock-analysis',
        credentials
    )
    connection = pika.BlockingConnection(parameters)
    channel = connection.channel()
    
    # Declare main topic exchange
    channel.exchange_declare(
        exchange='stock-analysis-events',
        exchange_type='topic',
        durable=True
    )
    
    # Declare dead letter exchange
    channel.exchange_declare(
        exchange='stock-analysis-dlx',
        exchange_type='topic',
        durable=True
    )
    
    # Declare service queues
    services = ['broker-gateway', 'intelligent-core', 'event-bus', 'monitoring', 'frontend']
    
    for service in services:
        # Main queue
        channel.queue_declare(
            queue=f'{service}-events',
            durable=True,
            arguments={
                'x-dead-letter-exchange': 'stock-analysis-dlx',
                'x-message-ttl': 86400000  # 24 hours
            }
        )
        
        # Bind queue to exchange
        channel.queue_bind(
            exchange='stock-analysis-events',
            queue=f'{service}-events',
            routing_key=f'{service}.*'
        )
        
        # Dead letter queue
        channel.queue_declare(
            queue=f'{service}-events-dlq',
            durable=True
        )
        
        channel.queue_bind(
            exchange='stock-analysis-dlx',
            queue=f'{service}-events-dlq',
            routing_key=f'{service}.*'
        )
    
    print("RabbitMQ exchanges and queues created successfully")
    connection.close()
    
except Exception as e:
    print(f"Error setting up RabbitMQ: {e}")
    sys.exit(1)
EOF

    # Execute RabbitMQ setup
    python3 /tmp/rabbitmq_setup.py "$RABBITMQ_PASSWORD"
    
    # Clean up
    rm -f /tmp/rabbitmq_setup.py
    
    log_success "RabbitMQ initialized successfully"
}

# Create test data
create_test_data() {
    log_info "Creating test data..."
    
    # Create PostgreSQL test data
    cat > /tmp/test_data.sql << EOF
-- Insert test event
INSERT INTO event_store.events (
    event_type,
    aggregate_type,
    aggregate_id,
    event_version,
    event_data,
    metadata
) VALUES (
    'SystemInitialized',
    'System',
    gen_random_uuid(),
    1,
    '{"timestamp": "$(date -u +%Y-%m-%dT%H:%M:%SZ)", "version": "1.0.0"}',
    '{"source": "init_script"}'
);

-- Insert test event type
INSERT INTO event_store.event_types (
    event_type,
    schema_version,
    json_schema,
    description
) VALUES (
    'SystemInitialized',
    1,
    '{"type": "object", "properties": {"timestamp": {"type": "string"}, "version": {"type": "string"}}}',
    'System initialization event'
);
EOF

    sudo -u postgres psql -d "$DB_NAME" < /tmp/test_data.sql
    rm -f /tmp/test_data.sql
    
    log_success "Test data created"
}

# Verify all services
verify_services() {
    log_info "Verifying all services..."
    
    echo -e "\nService Status:"
    echo "==============="
    
    # PostgreSQL
    if sudo -u postgres psql -d "$DB_NAME" -c "SELECT 1" &>/dev/null; then
        echo -e "${GREEN}✓${NC} PostgreSQL: Connected to $DB_NAME"
    else
        echo -e "${RED}✗${NC} PostgreSQL: Cannot connect to $DB_NAME"
    fi
    
    # Redis
    if redis-cli -p 6379 -a "$REDIS_PASSWORD" ping &>/dev/null; then
        echo -e "${GREEN}✓${NC} Redis: Cluster responding on port 6379"
    else
        echo -e "${RED}✗${NC} Redis: Not responding"
    fi
    
    # RabbitMQ
    if rabbitmqctl status &>/dev/null; then
        echo -e "${GREEN}✓${NC} RabbitMQ: Running"
    else
        echo -e "${RED}✗${NC} RabbitMQ: Not running"
    fi
}

# Main function
main() {
    log_info "Starting database initialization..."
    
    # Check for password environment variables
    if [ "$DB_PASSWORD" = "CHANGE_THIS_PASSWORD" ]; then
        log_error "Please set DB_PASSWORD environment variable"
        exit 1
    fi
    
    if [ "$REDIS_PASSWORD" = "CHANGE_THIS_PASSWORD" ]; then
        log_error "Please set REDIS_PASSWORD environment variable"
        exit 1
    fi
    
    # Initialize services
    init_postgresql
    init_redis_cluster
    init_rabbitmq
    create_test_data
    
    # Verify everything is working
    verify_services
    
    log_success "Database initialization completed successfully!"
}

# Run main function if script is executed directly
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi