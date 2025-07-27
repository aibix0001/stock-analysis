#!/bin/bash
# Database Infrastructure Setup Script
# Sets up PostgreSQL 15+ with event store and Redis cluster

set -euo pipefail

# Configuration
POSTGRES_VERSION="15"
POSTGRES_DB="aktienanalyse_event_store"
POSTGRES_USER="stock_analysis"
POSTGRES_PASSWORD="${POSTGRES_PASSWORD:-secure_password}"
REDIS_NODES=3
REDIS_BASE_PORT=6379
CONTAINER_IP="10.1.1.120"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

# PostgreSQL setup already done in main setup
enhance_postgresql_config() {
    log "Enhancing PostgreSQL configuration for Event Store..."
    
    local pg_config="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    
    if [ ! -f "$pg_config" ]; then
        error "PostgreSQL configuration file not found: $pg_config"
        return 1
    fi
    
    # Backup original config
    cp "$pg_config" "${pg_config}.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Performance settings for Event Store
    cat >> "$pg_config" <<EOF

# Event Store Performance Optimizations
# Added by setup-databases.sh on $(date)

# Memory Settings
shared_buffers = 1GB              # 25% of RAM for dedicated DB server
effective_cache_size = 3GB        # 75% of RAM
work_mem = 32MB                   # Per query operation
maintenance_work_mem = 256MB      # For VACUUM, CREATE INDEX

# Checkpoint Settings
checkpoint_timeout = 15min
checkpoint_completion_target = 0.9
max_wal_size = 4GB
min_wal_size = 1GB

# Query Planner
random_page_cost = 1.1            # For SSD storage
effective_io_concurrency = 200    # For SSD storage

# Parallel Query
max_parallel_workers_per_gather = 2
max_parallel_workers = 4

# Logging
log_min_duration_statement = 100  # Log queries slower than 100ms
log_checkpoints = on
log_connections = on
log_disconnections = on
log_lock_waits = on
log_temp_files = 0

# Event Store Specific
max_connections = 200             # Enough for all services
EOF
    
    # Restart PostgreSQL to apply changes
    systemctl restart postgresql
    
    log "PostgreSQL configuration enhanced for Event Store"
}

# Create event store database and user
create_event_store_database() {
    log "Creating Event Store database and user..."
    
    # Create user if not exists
    sudo -u postgres psql <<EOF
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$POSTGRES_USER') THEN
        CREATE USER $POSTGRES_USER WITH ENCRYPTED PASSWORD '$POSTGRES_PASSWORD';
    END IF;
END
\$\$;

-- Grant necessary privileges
ALTER USER $POSTGRES_USER CREATEDB;

-- Create database if not exists
SELECT 'CREATE DATABASE $POSTGRES_DB OWNER $POSTGRES_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$POSTGRES_DB')
\gexec

-- Grant all privileges
GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO $POSTGRES_USER;
EOF
    
    # Configure authentication
    local pg_hba="/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
    
    # Add authentication rules if not already present
    if ! grep -q "host.*$POSTGRES_USER" "$pg_hba"; then
        echo "" >> "$pg_hba"
        echo "# Stock Analysis Event Store access" >> "$pg_hba"
        echo "host    $POSTGRES_DB    $POSTGRES_USER    127.0.0.1/32    md5" >> "$pg_hba"
        echo "host    $POSTGRES_DB    $POSTGRES_USER    $CONTAINER_IP/32    md5" >> "$pg_hba"
        echo "host    $POSTGRES_DB    $POSTGRES_USER    10.1.1.0/24    md5" >> "$pg_hba"
    fi
    
    # Reload PostgreSQL
    systemctl reload postgresql
    
    log "Event Store database and user created"
}

# Apply event store schema
apply_event_store_schema() {
    log "Applying Event Store schema..."
    
    local schema_file="shared/database/event-store-schema.sql"
    
    if [ ! -f "$schema_file" ]; then
        error "Event Store schema file not found: $schema_file"
        return 1
    fi
    
    # Apply schema
    PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$schema_file"
    
    if [ $? -eq 0 ]; then
        log "Event Store schema applied successfully"
        
        # Grant permissions on all objects
        PGPASSWORD="$POSTGRES_PASSWORD" psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" <<EOF
-- Grant permissions on all tables
GRANT ALL ON ALL TABLES IN SCHEMA public TO $POSTGRES_USER;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO $POSTGRES_USER;
GRANT ALL ON ALL FUNCTIONS IN SCHEMA public TO $POSTGRES_USER;

-- Grant permissions on future objects
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO $POSTGRES_USER;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO $POSTGRES_USER;

-- Refresh initial materialized views
REFRESH MATERIALIZED VIEW stock_analysis_unified;
REFRESH MATERIALIZED VIEW portfolio_unified;
REFRESH MATERIALIZED VIEW trading_activity_unified;
REFRESH MATERIALIZED VIEW system_health_unified;
EOF
    else
        error "Failed to apply Event Store schema"
        return 1
    fi
}

# Configure Redis for event bus
configure_redis_standalone() {
    log "Configuring Redis for event bus usage..."
    
    # Backup original config
    cp /etc/redis/redis.conf /etc/redis/redis.conf.backup.$(date +%Y%m%d_%H%M%S)
    
    # Create optimized Redis configuration
    cat > /etc/redis/redis.conf <<EOF
# Redis Configuration for Stock Analysis Event Bus
# Generated by setup-databases.sh on $(date)

# Network
bind 127.0.0.1 ::1 $CONTAINER_IP
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# General
daemonize yes
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16

# Persistence - Both RDB and AOF for reliability
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no
auto-aof-rewrite-percentage 100
auto-aof-rewrite-min-size 64mb

# Memory Management
maxmemory 2gb
maxmemory-policy allkeys-lru
maxmemory-samples 5

# Performance
lazyfree-lazy-eviction no
lazyfree-lazy-expire no
lazyfree-lazy-server-del no
replica-lazy-flush no

# Event Bus Optimizations
# High performance for pub/sub
client-output-buffer-limit normal 0 0 0
client-output-buffer-limit replica 256mb 64mb 60
client-output-buffer-limit pubsub 32mb 8mb 60

# Allow more connections for microservices
maxclients 10000

# Disable dangerous commands
rename-command FLUSHDB ""
rename-command FLUSHALL ""
rename-command KEYS ""
rename-command CONFIG ""

# Enable keyspace notifications for event patterns
notify-keyspace-events AKE

# Modules (if needed in future)
# loadmodule /path/to/module.so
EOF
    
    # Set correct permissions
    chown redis:redis /etc/redis/redis.conf
    chmod 640 /etc/redis/redis.conf
    
    # Restart Redis
    systemctl restart redis-server
    
    log "Redis configured for event bus"
}

# Setup Redis cluster nodes (for future scaling)
setup_redis_cluster_config() {
    log "Creating Redis cluster configuration templates..."
    
    # Create cluster config directory
    mkdir -p /etc/redis/cluster
    
    # Create configs for additional nodes (not started by default)
    for i in $(seq 1 $((REDIS_NODES-1))); do
        local port=$((REDIS_BASE_PORT + i))
        local config_file="/etc/redis/cluster/redis-$port.conf"
        
        cat > "$config_file" <<EOF
# Redis Cluster Node $i Configuration
# Port: $port

include /etc/redis/redis.conf

# Override for cluster node
port $port
pidfile /var/run/redis/redis-server-$port.pid
logfile /var/log/redis/redis-server-$port.log
dbfilename dump-$port.rdb
appendfilename "appendonly-$port.aof"
dir /var/lib/redis/cluster-$port

# Cluster configuration
cluster-enabled yes
cluster-config-file /etc/redis/cluster/nodes-$port.conf
cluster-node-timeout 5000
cluster-announce-ip $CONTAINER_IP
cluster-announce-port $port
cluster-announce-bus-port $((port + 10000))
EOF
        
        # Create data directory
        mkdir -p "/var/lib/redis/cluster-$port"
        chown redis:redis "/var/lib/redis/cluster-$port"
        
        info "Created cluster config for Redis node on port $port"
    done
    
    # Create cluster setup script
    cat > /opt/stock-analysis/scripts/enable-redis-cluster.sh <<'EOF'
#!/bin/bash
# Enable Redis cluster mode (optional)

echo "This will convert Redis to cluster mode. Continue? (y/N)"
read -r response
if [[ ! "$response" =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

# Start additional Redis instances
for port in 6380 6381; do
    redis-server /etc/redis/cluster/redis-$port.conf
done

# Wait for nodes to start
sleep 5

# Create cluster
redis-cli --cluster create \
    127.0.0.1:6379 \
    127.0.0.1:6380 \
    127.0.0.1:6381 \
    --cluster-replicas 0 \
    --cluster-yes

echo "Redis cluster created successfully"
EOF
    
    chmod +x /opt/stock-analysis/scripts/enable-redis-cluster.sh
    
    log "Redis cluster configuration templates created"
}

# Create database initialization script
create_init_script() {
    log "Creating database initialization script..."
    
    cat > /opt/stock-analysis/scripts/init-databases.sh <<EOF
#!/bin/bash
# Initialize databases for Stock Analysis Ecosystem

set -euo pipefail

# Configuration
POSTGRES_DB="$POSTGRES_DB"
POSTGRES_USER="$POSTGRES_USER"
POSTGRES_PASSWORD="$POSTGRES_PASSWORD"

echo "Initializing databases..."

# Test PostgreSQL connection
if PGPASSWORD="\$POSTGRES_PASSWORD" psql -h localhost -U "\$POSTGRES_USER" -d "\$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
    echo "✅ PostgreSQL connection successful"
else
    echo "❌ PostgreSQL connection failed"
    exit 1
fi

# Test Redis connection
if redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis connection successful"
else
    echo "❌ Redis connection failed"
    exit 1
fi

# Initialize event store if needed
PGPASSWORD="\$POSTGRES_PASSWORD" psql -h localhost -U "\$POSTGRES_USER" -d "\$POSTGRES_DB" <<SQL
-- Check if events table exists
DO \\\$\\\$
BEGIN
    IF NOT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'events') THEN
        RAISE NOTICE 'Events table does not exist. Please run schema creation first.';
    ELSE
        RAISE NOTICE 'Events table exists.';
    END IF;
END
\\\$\\\$;

-- Insert test event
INSERT INTO events (
    stream_id,
    stream_type,
    event_type,
    event_version,
    event_data,
    event_metadata
) VALUES (
    'system-init',
    'system',
    'system.initialized',
    1,
    '{"message": "Stock Analysis Ecosystem initialized", "timestamp": "' || NOW() || '"}'::jsonb,
    '{"source": "init-script"}'::jsonb
) ON CONFLICT DO NOTHING;

-- Refresh materialized views
REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
REFRESH MATERIALIZED VIEW CONCURRENTLY portfolio_unified;
REFRESH MATERIALIZED VIEW CONCURRENTLY trading_activity_unified;
REFRESH MATERIALIZED VIEW CONCURRENTLY system_health_unified;
SQL

echo "✅ Database initialization complete"
EOF
    
    chmod +x /opt/stock-analysis/scripts/init-databases.sh
    
    log "Database initialization script created"
}

# Create database backup script
create_backup_script() {
    log "Creating database backup script..."
    
    cat > /opt/stock-analysis/scripts/backup-databases.sh <<'EOF'
#!/bin/bash
# Backup databases for Stock Analysis Ecosystem

set -euo pipefail

# Configuration
BACKUP_DIR="/opt/stock-analysis/backups"
POSTGRES_DB="aktienanalyse_event_store"
POSTGRES_USER="stock_analysis"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

echo "Starting database backup..."

# Backup PostgreSQL
echo "Backing up PostgreSQL..."
PGPASSWORD="${POSTGRES_PASSWORD:-secure_password}" pg_dump \
    -h localhost \
    -U "$POSTGRES_USER" \
    -d "$POSTGRES_DB" \
    -f "$BACKUP_DIR/postgres_${POSTGRES_DB}_${TIMESTAMP}.sql"

if [ $? -eq 0 ]; then
    echo "✅ PostgreSQL backup completed"
else
    echo "❌ PostgreSQL backup failed"
fi

# Backup Redis
echo "Backing up Redis..."
redis-cli BGSAVE
sleep 2
cp /var/lib/redis/dump.rdb "$BACKUP_DIR/redis_dump_${TIMESTAMP}.rdb"

if [ $? -eq 0 ]; then
    echo "✅ Redis backup completed"
else
    echo "❌ Redis backup failed"
fi

# Compress backups
echo "Compressing backups..."
cd "$BACKUP_DIR"
tar -czf "backup_${TIMESTAMP}.tar.gz" \
    "postgres_${POSTGRES_DB}_${TIMESTAMP}.sql" \
    "redis_dump_${TIMESTAMP}.rdb"

# Clean up uncompressed files
rm -f "postgres_${POSTGRES_DB}_${TIMESTAMP}.sql" "redis_dump_${TIMESTAMP}.rdb"

# Remove old backups (keep last 7 days)
find "$BACKUP_DIR" -name "backup_*.tar.gz" -mtime +7 -delete

echo "✅ Backup completed: $BACKUP_DIR/backup_${TIMESTAMP}.tar.gz"
EOF
    
    chmod +x /opt/stock-analysis/scripts/backup-databases.sh
    
    # Create backup cron job
    echo "0 2 * * * /opt/stock-analysis/scripts/backup-databases.sh" | crontab -
    
    log "Database backup script created and scheduled"
}

# Main setup function
main() {
    log "Starting Database Infrastructure Setup..."
    
    # Check if running as root
    check_root
    
    # Check if base setup was done
    if ! systemctl is-active --quiet postgresql || ! systemctl is-active --quiet redis-server; then
        error "PostgreSQL or Redis not running. Please run setup-lxc-native.sh first"
        exit 1
    fi
    
    # Setup steps
    enhance_postgresql_config
    create_event_store_database
    apply_event_store_schema
    configure_redis_standalone
    setup_redis_cluster_config
    create_init_script
    create_backup_script
    
    log "✅ Database infrastructure setup completed successfully!"
    echo ""
    echo "Databases configured:"
    echo "- PostgreSQL $POSTGRES_VERSION with Event Store schema"
    echo "- Redis configured for event bus"
    echo ""
    echo "Connection details:"
    echo "- PostgreSQL: psql -h localhost -U $POSTGRES_USER -d $POSTGRES_DB"
    echo "- Redis: redis-cli -h localhost"
    echo ""
    echo "Next steps:"
    echo "1. Run initialization: /opt/stock-analysis/scripts/init-databases.sh"
    echo "2. Test connections from services"
    echo "3. Configure service connection strings"
}

# Run main function
main "$@"