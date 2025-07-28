#!/bin/bash
# Build script for Stock Analysis LXC Template
# This script creates a distributable LXC template with all required components

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}"
OUTPUT_DIR="${BUILD_DIR}/output"
ROOTFS_DIR="${OUTPUT_DIR}/rootfs"
TEMPLATE_NAME="stock-analysis-lxc-template"
VERSION="1.0.0"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    local required_tools=("tar" "gzip" "python3")
    local missing_tools=()
    
    for tool in "${required_tools[@]}"; do
        if ! command -v "$tool" &> /dev/null; then
            missing_tools+=("$tool")
        fi
    done
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        log_error "Missing required tools: ${missing_tools[*]}"
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Create directory structure
create_directory_structure() {
    log_info "Creating directory structure..."
    
    # Clean and create output directory
    rm -rf "$OUTPUT_DIR"
    mkdir -p "$OUTPUT_DIR"
    
    # Create rootfs structure
    mkdir -p "${ROOTFS_DIR}/etc/systemd/system"
    mkdir -p "${ROOTFS_DIR}/opt/stock-analysis"/{scripts,config,venvs}
    mkdir -p "${ROOTFS_DIR}/var/lib"/{postgresql,redis,rabbitmq}
    mkdir -p "${ROOTFS_DIR}/etc/stock-analysis"
    mkdir -p "${ROOTFS_DIR}/usr/local/bin"
    
    # Create build directories if they don't exist
    mkdir -p "${BUILD_DIR}"/{scripts,config/{systemd,postgresql,redis,rabbitmq},templates}
    
    log_success "Directory structure created"
}

# Generate installation scripts
generate_installation_scripts() {
    log_info "Generating installation scripts..."
    
    # Create setup-system.sh
    cat > "${BUILD_DIR}/scripts/setup-system.sh" << 'EOF'
#!/bin/bash
# System setup script for Stock Analysis
set -euo pipefail

echo "Starting Stock Analysis system setup..."

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install base packages
echo "Installing base system packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libpq-dev \
    postgresql-client \
    redis-tools \
    systemd \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release

# Create stock-analysis user
if ! id -u stock-analysis >/dev/null 2>&1; then
    echo "Creating stock-analysis user..."
    useradd -m -s /bin/bash -d /opt/stock-analysis stock-analysis
fi

# Set up directories
echo "Setting up directories..."
chown -R stock-analysis:stock-analysis /opt/stock-analysis
chmod 755 /opt/stock-analysis

echo "System setup completed successfully!"
EOF

    # Create setup-python.sh
    cat > "${BUILD_DIR}/scripts/setup-python.sh" << 'EOF'
#!/bin/bash
# Python and uv setup script
set -euo pipefail

echo "Setting up Python environment..."

# Install uv
echo "Installing uv package manager..."
curl -LsSf https://astral.sh/uv/install.sh | sh
export PATH="/root/.cargo/bin:$PATH"

# Create virtual environments for each service
SERVICES=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")

for service in "${SERVICES[@]}"; do
    echo "Creating virtual environment for $service..."
    cd /opt/stock-analysis
    /root/.cargo/bin/uv venv "venvs/$service"
    
    # Create requirements file for service
    cat > "venvs/$service/requirements.txt" << REQUIREMENTS
fastapi==0.104.1
uvicorn==0.24.0
pydantic==2.5.0
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
redis==5.0.1
pika==1.3.2
httpx==0.25.2
python-dotenv==1.0.0
REQUIREMENTS
    
    # Install base requirements
    /root/.cargo/bin/uv pip install -r "venvs/$service/requirements.txt" --python "venvs/$service/bin/python"
done

# Make uv available system-wide
ln -sf /root/.cargo/bin/uv /usr/local/bin/uv

echo "Python environment setup completed!"
EOF

    # Create setup-databases.sh
    cat > "${BUILD_DIR}/scripts/setup-databases.sh" << 'EOF'
#!/bin/bash
# Database setup script
set -euo pipefail

echo "Setting up databases..."

# PostgreSQL setup
echo "Installing PostgreSQL 15..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-15 postgresql-contrib-15

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
systemctl stop postgresql
cat > /etc/postgresql/15/main/postgresql.conf << PGCONF
# PostgreSQL configuration for Stock Analysis
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
PGCONF

# Create database and user
systemctl start postgresql
sudo -u postgres psql << SQL
CREATE USER stock_analysis_user WITH PASSWORD 'changeme';
CREATE DATABASE stock_analysis_event_store OWNER stock_analysis_user;
GRANT ALL PRIVILEGES ON DATABASE stock_analysis_event_store TO stock_analysis_user;
SQL

# Redis setup
echo "Installing Redis..."
apt-get install -y redis-server

# Configure Redis cluster
echo "Configuring Redis..."
for port in 6379 6380 6381; do
    mkdir -p /etc/redis/cluster-$port
    cat > /etc/redis/cluster-$port/redis.conf << REDISCONF
port $port
cluster-enabled yes
cluster-config-file nodes-$port.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-$port.aof"
dir /var/lib/redis/cluster-$port
bind 127.0.0.1
protected-mode yes
requirepass changeme
masterauth changeme
REDISCONF
    
    mkdir -p /var/lib/redis/cluster-$port
    chown redis:redis /var/lib/redis/cluster-$port
done

# RabbitMQ setup
echo "Installing RabbitMQ..."
apt-get install -y rabbitmq-server

# Configure RabbitMQ
echo "Configuring RabbitMQ..."
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl add_user stock_analysis changeme
rabbitmqctl add_vhost /stock-analysis
rabbitmqctl set_permissions -p /stock-analysis stock_analysis ".*" ".*" ".*"
rabbitmqctl set_user_tags stock_analysis administrator

echo "Database setup completed!"
EOF

    # Create setup-services.sh
    cat > "${BUILD_DIR}/scripts/setup-services.sh" << 'EOF'
#!/bin/bash
# Service setup script
set -euo pipefail

echo "Setting up systemd services..."

# Copy service files
cp /opt/stock-analysis/config/systemd/*.service /etc/systemd/system/

# Create environment files
for service in broker-gateway intelligent-core event-bus monitoring frontend; do
    cat > "/etc/stock-analysis/stock-analysis-${service}.env" << ENV
# Environment variables for ${service}
DATABASE_URL=postgresql://stock_analysis_user:changeme@localhost/stock_analysis_event_store
REDIS_URL=redis://:changeme@localhost:6379
RABBITMQ_URL=amqp://stock_analysis:changeme@localhost:5672//stock-analysis
SERVICE_PORT=$((8000 + $(echo $service | od -An -N1 -i)))
SERVICE_NAME=stock-analysis-${service}
ENV
done

# Reload systemd
systemctl daemon-reload

# Enable services
for service in broker-gateway intelligent-core event-bus monitoring frontend; do
    systemctl enable stock-analysis-${service}.service
done

echo "Service setup completed!"
echo "Services can be started with: systemctl start stock-analysis-*.service"
EOF

    # Create health-check.py
    cat > "${BUILD_DIR}/scripts/health-check.py" << 'EOF'
#!/usr/bin/env python3
"""
Health check script for Stock Analysis services
"""
import sys
import json
import subprocess
from typing import Dict, Tuple, Any

def check_service_status(service_name: str) -> Tuple[bool, str]:
    """Check if a systemd service is running"""
    try:
        result = subprocess.run(
            ["systemctl", "is-active", service_name],
            capture_output=True,
            text=True
        )
        is_active = result.returncode == 0
        status = "active" if is_active else "inactive"
        return is_active, f"Service {service_name} is {status}"
    except Exception as e:
        return False, f"Failed to check {service_name}: {str(e)}"

def check_postgresql() -> Tuple[bool, str]:
    """Check PostgreSQL connectivity"""
    try:
        result = subprocess.run(
            ["pg_isready", "-h", "localhost", "-p", "5432"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return True, "PostgreSQL is accepting connections"
        return False, "PostgreSQL is not accepting connections"
    except Exception as e:
        return False, f"PostgreSQL check failed: {str(e)}"

def check_redis() -> Tuple[bool, str]:
    """Check Redis connectivity"""
    try:
        result = subprocess.run(
            ["redis-cli", "-a", "changeme", "ping"],
            capture_output=True,
            text=True
        )
        if result.stdout.strip() == "PONG":
            return True, "Redis is responding to ping"
        return False, "Redis is not responding"
    except Exception as e:
        return False, f"Redis check failed: {str(e)}"

def check_rabbitmq() -> Tuple[bool, str]:
    """Check RabbitMQ status"""
    try:
        result = subprocess.run(
            ["rabbitmqctl", "status"],
            capture_output=True,
            text=True
        )
        if result.returncode == 0:
            return True, "RabbitMQ is running"
        return False, "RabbitMQ is not running"
    except Exception as e:
        return False, f"RabbitMQ check failed: {str(e)}"

def main():
    """Run all health checks"""
    checks = {
        "postgresql": check_postgresql(),
        "redis": check_redis(),
        "rabbitmq": check_rabbitmq(),
    }
    
    # Check services if they exist
    services = [
        "stock-analysis-broker-gateway",
        "stock-analysis-intelligent-core",
        "stock-analysis-event-bus",
        "stock-analysis-monitoring",
        "stock-analysis-frontend"
    ]
    
    for service in services:
        checks[service] = check_service_status(service)
    
    # Calculate overall health
    all_healthy = all(status for status, _ in checks.values())
    
    # Output results
    output = {
        "healthy": all_healthy,
        "timestamp": subprocess.run(["date", "-u", "+%Y-%m-%dT%H:%M:%SZ"], 
                                  capture_output=True, text=True).stdout.strip(),
        "checks": {
            name: {"healthy": status, "message": msg}
            for name, (status, msg) in checks.items()
        }
    }
    
    print(json.dumps(output, indent=2))
    sys.exit(0 if all_healthy else 1)

if __name__ == "__main__":
    main()
EOF

    # Make scripts executable
    chmod +x "${BUILD_DIR}/scripts/"*.sh
    chmod +x "${BUILD_DIR}/scripts/"*.py
    
    log_success "Installation scripts generated"
}

# Generate systemd service templates
generate_systemd_templates() {
    log_info "Generating systemd service templates..."
    
    local services=("broker-gateway" "intelligent-core" "event-bus" "monitoring" "frontend")
    local ports=(8001 8002 8003 8004 8005)
    
    for i in "${!services[@]}"; do
        local service="${services[$i]}"
        local port="${ports[$i]}"
        
        cat > "${BUILD_DIR}/config/systemd/stock-analysis-${service}.service" << EOF
[Unit]
Description=Stock Analysis ${service^} Service
After=network.target postgresql.service redis.service rabbitmq-server.service
Wants=postgresql.service redis.service rabbitmq-server.service

[Service]
Type=simple
User=stock-analysis
Group=stock-analysis
WorkingDirectory=/opt/stock-analysis
Environment="PATH=/opt/stock-analysis/venvs/${service}/bin:/usr/local/bin:/usr/bin:/bin"
EnvironmentFile=/etc/stock-analysis/stock-analysis-${service}.env
ExecStart=/opt/stock-analysis/venvs/${service}/bin/python -m uvicorn app:app --host 0.0.0.0 --port ${port}
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=stock-analysis-${service}

# Security settings
PrivateTmp=true
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/stock-analysis

[Install]
WantedBy=multi-user.target
EOF
    done
    
    log_success "Systemd service templates generated"
}

# Generate configuration files
generate_config_files() {
    log_info "Generating configuration files..."
    
    # PostgreSQL init script
    cat > "${BUILD_DIR}/config/postgresql/init.sql" << 'EOF'
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
EOF

    # Redis cluster setup script
    cat > "${BUILD_DIR}/config/redis/setup-cluster.sh" << 'EOF'
#!/bin/bash
# Setup Redis cluster
echo "yes" | redis-cli -a changeme --cluster create \
    127.0.0.1:6379 \
    127.0.0.1:6380 \
    127.0.0.1:6381 \
    --cluster-replicas 0
EOF
    chmod +x "${BUILD_DIR}/config/redis/setup-cluster.sh"

    # RabbitMQ configuration
    cat > "${BUILD_DIR}/config/rabbitmq/definitions.json" << 'EOF'
{
    "vhosts": [
        {
            "name": "/stock-analysis"
        }
    ],
    "exchanges": [
        {
            "name": "stock-analysis-events",
            "vhost": "/stock-analysis",
            "type": "topic",
            "durable": true,
            "auto_delete": false
        },
        {
            "name": "stock-analysis-dlx",
            "vhost": "/stock-analysis",
            "type": "topic",
            "durable": true,
            "auto_delete": false
        }
    ],
    "queues": [
        {
            "name": "broker-gateway-events",
            "vhost": "/stock-analysis",
            "durable": true,
            "auto_delete": false,
            "arguments": {
                "x-dead-letter-exchange": "stock-analysis-dlx"
            }
        },
        {
            "name": "intelligent-core-events",
            "vhost": "/stock-analysis",
            "durable": true,
            "auto_delete": false,
            "arguments": {
                "x-dead-letter-exchange": "stock-analysis-dlx"
            }
        },
        {
            "name": "event-bus-events",
            "vhost": "/stock-analysis",
            "durable": true,
            "auto_delete": false,
            "arguments": {
                "x-dead-letter-exchange": "stock-analysis-dlx"
            }
        }
    ],
    "bindings": [
        {
            "source": "stock-analysis-events",
            "vhost": "/stock-analysis",
            "destination": "broker-gateway-events",
            "destination_type": "queue",
            "routing_key": "broker.*"
        },
        {
            "source": "stock-analysis-events",
            "vhost": "/stock-analysis",
            "destination": "intelligent-core-events",
            "destination_type": "queue",
            "routing_key": "analysis.*"
        },
        {
            "source": "stock-analysis-events",
            "vhost": "/stock-analysis",
            "destination": "event-bus-events",
            "destination_type": "queue",
            "routing_key": "#"
        }
    ]
}
EOF

    log_success "Configuration files generated"
}

# Generate LXC metadata
generate_lxc_metadata() {
    log_info "Generating LXC metadata..."
    
    cat > "${OUTPUT_DIR}/metadata.yaml" << EOF
architecture: x86_64
creation_date: $(date +%s)
properties:
  name: ${TEMPLATE_NAME}
  description: Stock Analysis LXC Template with Event-Driven Architecture
  os: debian
  release: bookworm
  version: "12"
  variant: default
templates:
  /etc/hostname:
    when:
      - create
      - rename
    template: hostname.tpl
  /etc/hosts:
    when:
      - create
      - rename
    template: hosts.tpl
  /etc/network/interfaces:
    when:
      - create
    template: interfaces.tpl
    create_only: true
EOF

    # Create template files
    mkdir -p "${OUTPUT_DIR}/templates"
    cat > "${OUTPUT_DIR}/templates/hostname.tpl" << 'EOF'
{{ container.name }}
EOF

    cat > "${OUTPUT_DIR}/templates/hosts.tpl" << 'EOF'
127.0.0.1   localhost
127.0.1.1   {{ container.name }}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

    cat > "${OUTPUT_DIR}/templates/interfaces.tpl" << 'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

    log_success "LXC metadata generated"
}

# Copy files to rootfs
copy_to_rootfs() {
    log_info "Copying files to rootfs..."
    
    # Copy scripts
    cp -r "${BUILD_DIR}/scripts/"* "${ROOTFS_DIR}/opt/stock-analysis/scripts/"
    
    # Copy configurations
    cp -r "${BUILD_DIR}/config/"* "${ROOTFS_DIR}/opt/stock-analysis/config/"
    
    # Create first-boot script
    cat > "${ROOTFS_DIR}/opt/stock-analysis/first-boot.sh" << 'EOF'
#!/bin/bash
# First boot setup script
set -euo pipefail

MARKER_FILE="/opt/stock-analysis/.first-boot-complete"

if [ -f "$MARKER_FILE" ]; then
    echo "First boot setup already completed"
    exit 0
fi

echo "Running first boot setup..."

# Run setup scripts in order
/opt/stock-analysis/scripts/setup-system.sh
/opt/stock-analysis/scripts/setup-python.sh
/opt/stock-analysis/scripts/setup-databases.sh
/opt/stock-analysis/scripts/setup-services.sh

# Initialize databases
sudo -u postgres psql < /opt/stock-analysis/config/postgresql/init.sql

# Create marker file
touch "$MARKER_FILE"

echo "First boot setup completed!"
echo "You can now start services with: systemctl start stock-analysis-*.service"
EOF
    chmod +x "${ROOTFS_DIR}/opt/stock-analysis/first-boot.sh"
    
    # Create systemd service for first boot
    cat > "${ROOTFS_DIR}/etc/systemd/system/stock-analysis-first-boot.service" << 'EOF'
[Unit]
Description=Stock Analysis First Boot Setup
After=network.target
ConditionPathExists=!/opt/stock-analysis/.first-boot-complete

[Service]
Type=oneshot
ExecStart=/opt/stock-analysis/first-boot.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

    # Enable first boot service
    mkdir -p "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants"
    ln -sf /etc/systemd/system/stock-analysis-first-boot.service \
        "${ROOTFS_DIR}/etc/systemd/system/multi-user.target.wants/stock-analysis-first-boot.service"
    
    log_success "Files copied to rootfs"
}

# Package template
package_template() {
    log_info "Packaging template..."
    
    cd "${OUTPUT_DIR}"
    
    # Create the tarball
    tar -czf "${TEMPLATE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz" \
        rootfs metadata.yaml templates
    
    # Create a symlink to latest
    ln -sf "${TEMPLATE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz" \
        "${TEMPLATE_NAME}-latest.tar.gz"
    
    # Calculate checksum
    sha256sum "${TEMPLATE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz" > \
        "${TEMPLATE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz.sha256"
    
    log_success "Template packaged: ${OUTPUT_DIR}/${TEMPLATE_NAME}-${VERSION}-${TIMESTAMP}.tar.gz"
}

# Generate documentation
generate_documentation() {
    log_info "Generating documentation..."
    
    cat > "${OUTPUT_DIR}/README.md" << EOF
# Stock Analysis LXC Template

Version: ${VERSION}
Build Date: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Description

This LXC template contains a complete Stock Analysis ecosystem with:
- Event-driven microservices architecture
- PostgreSQL event store
- Redis cluster for caching and pub/sub
- RabbitMQ for message queuing
- Python 3.11+ with uv package manager
- Systemd service management

## Deployment Instructions

### On Proxmox

1. Copy the template to your Proxmox template directory:
   \`\`\`bash
   scp ${TEMPLATE_NAME}-latest.tar.gz root@proxmox:/var/lib/vz/template/cache/
   \`\`\`

2. Create a new container:
   \`\`\`bash
   pct create 100 /var/lib/vz/template/cache/${TEMPLATE_NAME}-latest.tar.gz \\
     --hostname stock-analysis \\
     --memory 8192 \\
     --cores 4 \\
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \\
     --storage local-lvm \\
     --rootfs local-lvm:50 \\
     --unprivileged 1 \\
     --features nesting=1
   \`\`\`

3. Start the container:
   \`\`\`bash
   pct start 100
   \`\`\`

4. The first boot will automatically run the setup scripts.

### Post-Deployment

1. Enter the container:
   \`\`\`bash
   pct enter 100
   \`\`\`

2. Check setup status:
   \`\`\`bash
   systemctl status stock-analysis-first-boot
   \`\`\`

3. Run health checks:
   \`\`\`bash
   python3 /opt/stock-analysis/scripts/health-check.py
   \`\`\`

4. Start services:
   \`\`\`bash
   systemctl start stock-analysis-broker-gateway
   systemctl start stock-analysis-intelligent-core
   systemctl start stock-analysis-event-bus
   systemctl start stock-analysis-monitoring
   systemctl start stock-analysis-frontend
   \`\`\`

## Service Ports

- Broker Gateway: 8001
- Intelligent Core: 8002
- Event Bus: 8003
- Monitoring: 8004
- Frontend: 8005

## Default Credentials

- PostgreSQL: stock_analysis_user / changeme
- Redis: changeme
- RabbitMQ: stock_analysis / changeme

**Important:** Change all default passwords after deployment!

## Troubleshooting

Check logs with:
\`\`\`bash
journalctl -u stock-analysis-first-boot
journalctl -u stock-analysis-*
\`\`\`

## Build Information

- Build Host: $(hostname)
- Build User: $(whoami)
- Build Directory: ${BUILD_DIR}
EOF

    log_success "Documentation generated"
}

# Main execution
main() {
    log_info "Starting Stock Analysis LXC Template build..."
    log_info "Version: ${VERSION}"
    log_info "Build directory: ${BUILD_DIR}"
    
    check_prerequisites
    create_directory_structure
    generate_installation_scripts
    generate_systemd_templates
    generate_config_files
    generate_lxc_metadata
    copy_to_rootfs
    package_template
    generate_documentation
    
    log_success "Build completed successfully!"
    log_info "Template location: ${OUTPUT_DIR}/${TEMPLATE_NAME}-latest.tar.gz"
    log_info "Documentation: ${OUTPUT_DIR}/README.md"
}

# Run main function
main "$@"