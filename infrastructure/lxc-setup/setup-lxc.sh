#!/bin/bash
# LXC Container Setup Script for Stock Analysis Ecosystem
# This script sets up a Debian 12 LXC container with all required infrastructure

set -euo pipefail

# Configuration
CONTAINER_HOSTNAME="stock-analysis"
DB_PASSWORD="CHANGE_THIS_PASSWORD"
REDIS_PASSWORD="CHANGE_THIS_PASSWORD"
RABBITMQ_PASSWORD="CHANGE_THIS_PASSWORD"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        log_error "This script must be run as root"
    fi
}

# Check if running inside LXC container
check_lxc() {
    if ! grep -q "container=lxc" /proc/1/environ 2>/dev/null && [ ! -f /run/systemd/container ]; then
        log_warning "This script is designed to run inside an LXC container"
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Configure network
configure_network() {
    log_info "Configuring network settings..."
    
    # Set hostname
    hostnamectl set-hostname "$CONTAINER_HOSTNAME"
    echo "$CONTAINER_HOSTNAME" > /etc/hostname
    
    # Update /etc/hosts
    if ! grep -q "$CONTAINER_HOSTNAME" /etc/hosts; then
        echo "127.0.1.1    $CONTAINER_HOSTNAME" >> /etc/hosts
    fi
    
    # Configure network interface for DHCP (assuming eth0)
    cat > /etc/network/interfaces.d/eth0 << EOF
auto eth0
iface eth0 inet dhcp
EOF
    
    # Ensure main interfaces file includes the interfaces.d directory
    if ! grep -q "source /etc/network/interfaces.d/*" /etc/network/interfaces 2>/dev/null; then
        echo "source /etc/network/interfaces.d/*" >> /etc/network/interfaces
    fi
    
    # Restart networking
    systemctl restart networking || log_warning "Network restart failed, may need manual restart"
    
    # Wait for DHCP to assign IP
    sleep 3
    
    # Display assigned IP
    ip_addr=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$ip_addr" ]; then
        log_success "Network configured with DHCP. Assigned IP: $ip_addr"
    else
        log_warning "No IP address assigned yet. Check DHCP server."
    fi
}

# Update system and install base packages
install_base_packages() {
    log_info "Updating system and installing base packages..."
    
    # Update package lists
    apt-get update
    
    # Upgrade system
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    
    # Install base packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        libpq-dev \
        libssl-dev \
        libffi-dev \
        systemd \
        systemd-sysv \
        htop \
        net-tools \
        vim \
        nano \
        sudo \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        apt-transport-https \
        ufw \
        fail2ban \
        ntp \
        bc \
        jq \
        netcat-openbsd
    
    log_success "Base packages installed"
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    # Main directories
    mkdir -p /opt/stock-analysis/{venvs,services,config,logs,data,scripts}
    mkdir -p /etc/stock-analysis
    
    # Service-specific directories
    services=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")
    for service in "${services[@]}"; do
        mkdir -p "/opt/stock-analysis/services/$service"
        mkdir -p "/opt/stock-analysis/venvs/$service"
        mkdir -p "/opt/stock-analysis/logs/$service"
    done
    
    # Set permissions
    chown -R root:root /opt/stock-analysis
    chmod -R 755 /opt/stock-analysis
    
    log_success "Directory structure created"
}

# Install Python and uv
install_python_uv() {
    log_info "Installing Python 3.11+ and uv package manager..."
    
    # Ensure Python 3.11+ is installed
    python_version=$(python3 --version | cut -d' ' -f2)
    log_info "Python version: $python_version"
    
    # Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add uv to PATH for this session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    # Add to system-wide PATH
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /etc/profile.d/uv.sh
    chmod +x /etc/profile.d/uv.sh
    
    # Verify uv installation
    if command -v uv &> /dev/null; then
        log_success "uv installed successfully: $(uv --version)"
    else
        log_error "uv installation failed"
    fi
}

# Install and configure PostgreSQL
install_postgresql() {
    log_info "Installing PostgreSQL 15+..."
    
    # Add PostgreSQL APT repository
    curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /etc/apt/trusted.gpg.d/postgresql.gpg
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    
    # Update and install PostgreSQL
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql-15 postgresql-client-15 postgresql-contrib-15
    
    # Start and enable PostgreSQL
    systemctl start postgresql
    systemctl enable postgresql
    
    # Configure PostgreSQL
    log_info "Configuring PostgreSQL..."
    
    # Update postgresql.conf for performance
    PG_VERSION="15"
    PG_CONFIG="/etc/postgresql/$PG_VERSION/main/postgresql.conf"
    
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = 'localhost'/" "$PG_CONFIG"
    sed -i "s/shared_buffers = .*/shared_buffers = 2GB/" "$PG_CONFIG"
    sed -i "s/#effective_cache_size = .*/effective_cache_size = 6GB/" "$PG_CONFIG"
    sed -i "s/#work_mem = .*/work_mem = 32MB/" "$PG_CONFIG"
    sed -i "s/#maintenance_work_mem = .*/maintenance_work_mem = 512MB/" "$PG_CONFIG"
    
    # Restart PostgreSQL
    systemctl restart postgresql
    
    log_success "PostgreSQL installed and configured"
}

# Create PostgreSQL database and schema
setup_postgresql_database() {
    log_info "Setting up PostgreSQL database and schema..."
    
    # Create setup script
    cat > /tmp/setup_database.sql << EOF
-- Create user
CREATE USER stock_analysis_user WITH ENCRYPTED PASSWORD '$DB_PASSWORD';

-- Create database
CREATE DATABASE stock_analysis_event_store
    WITH 
    OWNER = stock_analysis_user
    ENCODING = 'UTF8'
    LC_COLLATE = 'en_US.UTF-8'
    LC_CTYPE = 'en_US.UTF-8'
    TABLESPACE = pg_default
    CONNECTION LIMIT = 100;

-- Grant permissions
GRANT ALL PRIVILEGES ON DATABASE stock_analysis_event_store TO stock_analysis_user;
EOF

    # Execute as postgres user
    sudo -u postgres psql < /tmp/setup_database.sql
    
    # Create schema script
    cat > /tmp/create_schema.sql << EOF
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
    created_by VARCHAR(255) DEFAULT 'system'
);

-- Indexes
CREATE INDEX idx_events_aggregate ON event_store.events(aggregate_type, aggregate_id, event_version);
CREATE INDEX idx_events_type ON event_store.events(event_type, created_at);
CREATE INDEX idx_events_created_at ON event_store.events(created_at);

-- Snapshots table
CREATE TABLE event_store.snapshots (
    snapshot_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_type VARCHAR(255) NOT NULL,
    aggregate_id UUID NOT NULL,
    aggregate_version INTEGER NOT NULL,
    snapshot_data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(aggregate_type, aggregate_id, aggregate_version)
);

CREATE INDEX idx_snapshots_aggregate ON event_store.snapshots(aggregate_type, aggregate_id, aggregate_version DESC);

-- Grant permissions
GRANT ALL ON SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL TABLES IN SCHEMA event_store TO stock_analysis_user;
GRANT ALL ON ALL SEQUENCES IN SCHEMA event_store TO stock_analysis_user;

-- Create projections schema
CREATE SCHEMA IF NOT EXISTS projections;
GRANT ALL ON SCHEMA projections TO stock_analysis_user;
EOF

    # Execute schema creation
    sudo -u postgres psql < /tmp/create_schema.sql
    
    # Clean up
    rm -f /tmp/setup_database.sql /tmp/create_schema.sql
    
    log_success "PostgreSQL database and schema created"
}

# Install and configure Redis cluster
install_redis() {
    log_info "Installing Redis and configuring 3-node cluster..."
    
    # Install Redis
    DEBIAN_FRONTEND=noninteractive apt-get install -y redis-server redis-tools
    
    # Stop default Redis instance
    systemctl stop redis-server
    systemctl disable redis-server
    
    # Create Redis directories
    mkdir -p /etc/redis/cluster
    mkdir -p /var/lib/redis/cluster/{6379,6380,6381}
    mkdir -p /var/log/redis/cluster
    
    # Create Redis configuration for each node
    for port in 6379 6380 6381; do
        cat > "/etc/redis/cluster/redis-$port.conf" << EOF
# Redis configuration for port $port
port $port
bind 127.0.0.1
protected-mode yes
requirepass $REDIS_PASSWORD
masterauth $REDIS_PASSWORD
cluster-enabled yes
cluster-config-file /var/lib/redis/cluster/$port/nodes.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-$port.aof"
dir /var/lib/redis/cluster/$port
logfile /var/log/redis/cluster/redis-$port.log
pidfile /var/run/redis/redis-$port.pid
maxmemory 2gb
maxmemory-policy allkeys-lru
save 900 1
save 300 10
save 60 10000
EOF
        
        # Create systemd service for each Redis instance
        cat > "/etc/systemd/system/redis-$port.service" << EOF
[Unit]
Description=Redis Server on port $port
After=network.target

[Service]
Type=notify
ExecStart=/usr/bin/redis-server /etc/redis/cluster/redis-$port.conf --supervised systemd
ExecStop=/usr/bin/redis-cli -p $port -a $REDIS_PASSWORD shutdown
TimeoutStopSec=0
Restart=on-failure
User=redis
Group=redis
RuntimeDirectory=redis
RuntimeDirectoryMode=0755

[Install]
WantedBy=multi-user.target
EOF
    done
    
    # Set permissions
    chown -R redis:redis /var/lib/redis/cluster
    chown -R redis:redis /var/log/redis/cluster
    chmod -R 750 /var/lib/redis/cluster
    
    # Reload systemd and start Redis instances
    systemctl daemon-reload
    for port in 6379 6380 6381; do
        systemctl start redis-$port
        systemctl enable redis-$port
    done
    
    # Wait for Redis instances to start
    sleep 5
    
    # Create cluster
    log_info "Creating Redis cluster..."
    echo "yes" | redis-cli --cluster create \
        127.0.0.1:6379 127.0.0.1:6380 127.0.0.1:6381 \
        --cluster-replicas 0 \
        -a "$REDIS_PASSWORD" || log_warning "Cluster creation failed - may already exist"
    
    log_success "Redis cluster configured"
}

# Install and configure RabbitMQ
install_rabbitmq() {
    log_info "Installing RabbitMQ..."
    
    # Add RabbitMQ repository
    curl -1sLf 'https://keys.openpgp.org/vks/v1/by-fingerprint/0A9AF2115F4687BD29803A206B73A36E6026DFCA' | gpg --dearmor -o /etc/apt/trusted.gpg.d/com.rabbitmq.team.gpg
    curl -1sLf 'https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey' | gpg --dearmor -o /etc/apt/trusted.gpg.d/rabbitmq.gpg
    
    cat > /etc/apt/sources.list.d/rabbitmq.list << EOF
deb http://ppa.launchpad.net/rabbitmq/rabbitmq-erlang/ubuntu jammy main
deb https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ bookworm main
EOF
    
    # Update and install
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server
    
    # Start and enable RabbitMQ
    systemctl start rabbitmq-server
    systemctl enable rabbitmq-server
    
    # Enable management plugin
    rabbitmq-plugins enable rabbitmq_management
    
    # Configure RabbitMQ
    log_info "Configuring RabbitMQ..."
    
    # Create user and virtual host
    rabbitmqctl add_user stock_analysis "$RABBITMQ_PASSWORD" || log_warning "User may already exist"
    rabbitmqctl set_user_tags stock_analysis administrator
    rabbitmqctl add_vhost /stock-analysis || log_warning "Virtual host may already exist"
    rabbitmqctl set_permissions -p /stock-analysis stock_analysis ".*" ".*" ".*"
    
    # Delete default guest user for security
    rabbitmqctl delete_user guest || log_warning "Guest user may already be deleted"
    
    log_success "RabbitMQ installed and configured"
}

# Create systemd service templates
create_systemd_templates() {
    log_info "Creating systemd service templates..."
    
    # Service template
    cat > /etc/systemd/system/stock-analysis-service@.service << 'EOF'
[Unit]
Description=Stock Analysis %i Service
After=network.target postgresql.service redis-6379.service rabbitmq-server.service
Wants=postgresql.service redis-6379.service rabbitmq-server.service

[Service]
Type=simple
User=stock-analysis
Group=stock-analysis
WorkingDirectory=/opt/stock-analysis/services/%i
Environment="PATH=/opt/stock-analysis/venvs/%i/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/stock-analysis/%i.env
EnvironmentFile=/etc/stock-analysis/common.env
ExecStart=/opt/stock-analysis/venvs/%i/bin/python -m %i
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stock-analysis-%i

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/stock-analysis/logs/%i /opt/stock-analysis/data

[Install]
WantedBy=multi-user.target
EOF

    # Create individual service files for each service
    services=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")
    for service in "${services[@]}"; do
        ln -sf /etc/systemd/system/stock-analysis-service@.service \
               "/etc/systemd/system/stock-analysis-$service.service"
    done
    
    # Create service user
    useradd -r -s /bin/false -d /opt/stock-analysis -c "Stock Analysis Service User" stock-analysis || log_warning "User may already exist"
    
    # Set ownership
    chown -R stock-analysis:stock-analysis /opt/stock-analysis
    
    log_success "Systemd service templates created"
}

# Create environment files
create_environment_files() {
    log_info "Creating environment files..."
    
    # Common environment file
    cat > /etc/stock-analysis/common.env << EOF
# Common environment variables for all services
DATABASE_URL=postgresql://stock_analysis_user:$DB_PASSWORD@localhost:5432/stock_analysis_event_store
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=$REDIS_PASSWORD
RABBITMQ_URL=amqp://stock_analysis:$RABBITMQ_PASSWORD@localhost:5672/stock-analysis
LOG_LEVEL=INFO
ENVIRONMENT=production
EOF

    # Service-specific environment files
    cat > /etc/stock-analysis/broker-gateway.env << EOF
# Broker Gateway Service Configuration
SERVICE_NAME=broker-gateway
SERVICE_PORT=8001
BITPANDA_API_KEY=
BITPANDA_API_SECRET=
EOF

    cat > /etc/stock-analysis/intelligent-core.env << EOF
# Intelligent Core Service Configuration
SERVICE_NAME=intelligent-core
SERVICE_PORT=8002
ALPHA_VANTAGE_API_KEY=
EODHD_API_KEY=
ML_MODEL_PATH=/opt/stock-analysis/data/models
EOF

    cat > /etc/stock-analysis/event-bus.env << EOF
# Event Bus Service Configuration
SERVICE_NAME=event-bus
SERVICE_PORT=8003
EVENT_RETENTION_DAYS=90
MAX_EVENT_SIZE_MB=10
EOF

    cat > /etc/stock-analysis/monitoring.env << EOF
# Monitoring Service Configuration
SERVICE_NAME=monitoring
SERVICE_PORT=8004
HEALTH_CHECK_INTERVAL=30
ALERT_WEBHOOK_URL=
EOF

    cat > /etc/stock-analysis/frontend.env << EOF
# Frontend Service Configuration
SERVICE_NAME=frontend
SERVICE_PORT=8005
API_BASE_URL=http://localhost:8000
WEBSOCKET_URL=ws://localhost:8003
EOF

    # Set permissions
    chmod 640 /etc/stock-analysis/*.env
    chown root:stock-analysis /etc/stock-analysis/*.env
    
    log_success "Environment files created"
}

# Create health check script
create_health_check() {
    log_info "Creating health check endpoints..."
    
    cat > /opt/stock-analysis/scripts/health_check.py << 'EOF'
#!/usr/bin/env python3
"""
Health check endpoint implementation for Stock Analysis services
"""
import os
import sys
import json
import psycopg2
import redis
import pika
from http.server import HTTPServer, BaseHTTPRequestHandler
from urllib.parse import urlparse
import logging

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class HealthCheckHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == '/health':
            health_status = self.check_health()
            
            if health_status['status'] == 'healthy':
                self.send_response(200)
            else:
                self.send_response(503)
            
            self.send_header('Content-Type', 'application/json')
            self.end_headers()
            self.wfile.write(json.dumps(health_status).encode())
        else:
            self.send_response(404)
            self.end_headers()
    
    def check_health(self):
        status = {
            'status': 'healthy',
            'service': os.environ.get('SERVICE_NAME', 'unknown'),
            'checks': {}
        }
        
        # Check PostgreSQL
        try:
            conn = psycopg2.connect(os.environ.get('DATABASE_URL'))
            conn.close()
            status['checks']['postgresql'] = 'ok'
        except Exception as e:
            status['checks']['postgresql'] = f'error: {str(e)}'
            status['status'] = 'unhealthy'
        
        # Check Redis
        try:
            r = redis.Redis.from_url(
                os.environ.get('REDIS_URL'),
                password=os.environ.get('REDIS_PASSWORD')
            )
            r.ping()
            status['checks']['redis'] = 'ok'
        except Exception as e:
            status['checks']['redis'] = f'error: {str(e)}'
            status['status'] = 'unhealthy'
        
        # Check RabbitMQ
        try:
            url = os.environ.get('RABBITMQ_URL')
            params = pika.URLParameters(url)
            connection = pika.BlockingConnection(params)
            connection.close()
            status['checks']['rabbitmq'] = 'ok'
        except Exception as e:
            status['checks']['rabbitmq'] = f'error: {str(e)}'
            status['status'] = 'unhealthy'
        
        return status
    
    def log_message(self, format, *args):
        return  # Suppress access logs

def run_health_server(port):
    server = HTTPServer(('0.0.0.0', port), HealthCheckHandler)
    logger.info(f"Health check server listening on port {port}")
    server.serve_forever()

if __name__ == '__main__':
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    run_health_server(port)
EOF

    chmod +x /opt/stock-analysis/scripts/health_check.py
    
    log_success "Health check script created"
}

# Create virtual environments
create_virtual_environments() {
    log_info "Creating Python virtual environments..."
    
    services=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")
    
    for service in "${services[@]}"; do
        log_info "Creating virtual environment for $service..."
        
        # Create venv using uv
        cd "/opt/stock-analysis/venvs/$service"
        uv venv
        
        # Create requirements.txt template
        cat > "/opt/stock-analysis/services/$service/requirements.txt" << EOF
# $service service dependencies
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
psycopg2-binary==2.9.9
redis==5.0.1
pika==1.3.2
python-dotenv==1.0.0
httpx==0.25.2
sqlalchemy==2.0.23
alembic==1.13.0
EOF

        # Add service-specific dependencies
        case $service in
            "broker-gateway")
                echo "ccxt==4.1.56  # Cryptocurrency exchange library" >> "/opt/stock-analysis/services/$service/requirements.txt"
                ;;
            "intelligent-core")
                cat >> "/opt/stock-analysis/services/$service/requirements.txt" << EOF
pandas==2.1.4
numpy==1.26.2
scikit-learn==1.3.2
xgboost==2.0.3
ta==0.11.0  # Technical analysis library
yfinance==0.2.33
EOF
                ;;
            "event-bus")
                echo "websockets==12.0" >> "/opt/stock-analysis/services/$service/requirements.txt"
                ;;
            "frontend")
                echo "jinja2==3.1.2" >> "/opt/stock-analysis/services/$service/requirements.txt"
                ;;
        esac
        
        # Install base dependencies
        /opt/stock-analysis/venvs/$service/bin/pip install -r "/opt/stock-analysis/services/$service/requirements.txt"
    done
    
    # Set ownership
    chown -R stock-analysis:stock-analysis /opt/stock-analysis/venvs
    
    log_success "Virtual environments created"
}

# Configure firewall
configure_firewall() {
    log_info "Configuring firewall..."
    
    # Get current network subnet from DHCP-assigned IP
    local ip_addr=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    local subnet=""
    
    if [ -n "$ip_addr" ]; then
        # Extract subnet (assuming /24 for simplicity, could be made more dynamic)
        subnet=$(echo "$ip_addr" | cut -d. -f1-3).0/24
        log_info "Detected subnet: $subnet"
    else
        log_warning "Could not detect subnet, using permissive rules"
        subnet="any"
    fi
    
    # Enable UFW
    ufw --force enable
    
    # Allow SSH (adjust port as needed)
    ufw allow 22/tcp
    
    # Allow service ports
    for port in 8001 8002 8003 8004 8005; do
        if [ "$subnet" = "any" ]; then
            # If no subnet detected, allow from anywhere (less secure)
            ufw allow $port/tcp
        else
            # Restrict to local subnet
            ufw allow from $subnet to any port $port
        fi
    done
    
    # Allow PostgreSQL
    if [ "$subnet" = "any" ]; then
        ufw allow 5432/tcp
    else
        ufw allow from $subnet to any port 5432
    fi
    
    # Allow Redis cluster
    if [ "$subnet" = "any" ]; then
        ufw allow 6379:6381/tcp
    else
        ufw allow from $subnet to any port 6379:6381/tcp
    fi
    
    # Allow RabbitMQ
    if [ "$subnet" = "any" ]; then
        ufw allow 5672/tcp
        ufw allow 15672/tcp
    else
        ufw allow from $subnet to any port 5672
        ufw allow from $subnet to any port 15672
    fi
    
    log_success "Firewall configured"
}

# Final setup and validation
final_setup() {
    log_info "Performing final setup..."
    
    # Reload systemd
    systemctl daemon-reload
    
    # Create a setup completion marker
    date > /opt/stock-analysis/.setup_complete
    
    # Create a simple status script
    cat > /opt/stock-analysis/scripts/status.sh << 'EOF'
#!/bin/bash
echo "Stock Analysis Infrastructure Status"
echo "===================================="
echo
echo "PostgreSQL: $(systemctl is-active postgresql)"
echo "Redis 6379: $(systemctl is-active redis-6379)"
echo "Redis 6380: $(systemctl is-active redis-6380)"
echo "Redis 6381: $(systemctl is-active redis-6381)"
echo "RabbitMQ: $(systemctl is-active rabbitmq-server)"
echo
echo "Services:"
for service in broker-gateway intelligent-core event-bus monitoring frontend; do
    echo "  stock-analysis-$service: $(systemctl is-active stock-analysis-$service 2>/dev/null || echo 'not started')"
done
EOF
    chmod +x /opt/stock-analysis/scripts/status.sh
    
    log_success "Setup completed!"
}

# Main execution
main() {
    log_info "Starting Stock Analysis LXC container setup..."
    
    check_root
    check_lxc
    configure_network
    install_base_packages
    create_directory_structure
    install_python_uv
    install_postgresql
    setup_postgresql_database
    install_redis
    install_rabbitmq
    create_systemd_templates
    create_environment_files
    create_health_check
    create_virtual_environments
    configure_firewall
    final_setup
    
    echo
    log_success "Stock Analysis infrastructure setup completed successfully!"
    echo
    echo "Next steps:"
    echo "1. Update passwords in /etc/stock-analysis/*.env files"
    echo "2. Configure API keys for external services"
    echo "3. Deploy your application code to /opt/stock-analysis/services/"
    echo "4. Start services with: systemctl start stock-analysis-<service-name>"
    echo "5. Check status with: /opt/stock-analysis/scripts/status.sh"
    echo
    echo "To run tests: /infrastructure/lxc-setup/tests/test_lxc_setup.sh"
}

# Run main function
main "$@"