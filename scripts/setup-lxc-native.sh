#!/bin/bash
# Native LXC Setup Script for Stock Analysis Ecosystem
# Sets up Debian 12 LXC container with all required infrastructure
# No Docker - uses native systemd services

set -euo pipefail

# Configuration
DEBIAN_VERSION="12"
CONTAINER_IP="10.1.1.120"
CONTAINER_HOSTNAME="stock-analysis"
BASE_DIR="/opt/stock-analysis"
SERVICE_USER="stock-analysis"
PYTHON_VERSION="3.11"

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

# Detect if we're inside LXC or on the host
detect_environment() {
    if [ -f /run/systemd/container ]; then
        info "Running inside LXC container"
        return 0
    elif command -v lxc >/dev/null 2>&1; then
        info "Running on LXC host"
        return 1
    else
        error "Neither inside LXC container nor on LXC host"
        exit 1
    fi
}

# Create LXC container (if on host)
create_lxc_container() {
    local container_name="stock-analysis-lxc"
    
    log "Creating LXC container $container_name..."
    
    # Check if container already exists
    if lxc list | grep -q "$container_name"; then
        warning "Container $container_name already exists"
        return 0
    fi
    
    # Create container with Debian 12
    lxc launch images:debian/12 "$container_name"
    
    # Wait for container to be ready
    sleep 10
    
    # Configure container resources
    lxc config set "$container_name" limits.cpu 4
    lxc config set "$container_name" limits.memory 6GB
    lxc config set "$container_name" limits.memory.swap false
    
    # Configure network
    lxc config device add "$container_name" eth0 nic \
        nictype=bridged \
        parent=lxdbr0 \
        ipv4.address="$CONTAINER_IP"
    
    log "Container $container_name created successfully"
}

# Configure network inside container
configure_network() {
    log "Configuring network settings..."
    
    # Set hostname
    hostnamectl set-hostname "$CONTAINER_HOSTNAME"
    echo "$CONTAINER_HOSTNAME" > /etc/hostname
    
    # Update /etc/hosts
    if ! grep -q "$CONTAINER_HOSTNAME" /etc/hosts; then
        echo "127.0.0.1 $CONTAINER_HOSTNAME" >> /etc/hosts
        echo "$CONTAINER_IP $CONTAINER_HOSTNAME" >> /etc/hosts
    fi
    
    # Configure static IP (if using systemd-networkd)
    if [ -d /etc/systemd/network ]; then
        cat > /etc/systemd/network/10-static.network <<EOF
[Match]
Name=eth0

[Network]
Address=$CONTAINER_IP/24
Gateway=10.1.1.1
DNS=8.8.8.8
DNS=8.8.4.4

[DHCP]
UseDNS=false
EOF
        systemctl restart systemd-networkd
    fi
    
    log "Network configuration completed"
}

# Update system and install base packages
install_base_packages() {
    log "Updating system and installing base packages..."
    
    # Update package lists
    apt-get update
    
    # Upgrade system
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    
    # Install essential packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        gnupg \
        lsb-release \
        sudo \
        systemd \
        systemd-sysv \
        htop \
        iotop \
        net-tools \
        dnsutils \
        vim \
        nano \
        tmux \
        unzip \
        jq \
        rsync \
        cron \
        logrotate
    
    log "Base packages installed successfully"
}

# Install Python 3.11+
install_python() {
    log "Installing Python $PYTHON_VERSION..."
    
    # Check current Python version
    if command -v python3 >/dev/null 2>&1; then
        current_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        info "Current Python version: $current_version"
    fi
    
    # Install Python and development packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        libpython3-dev \
        libffi-dev \
        libssl-dev
    
    # Install uv (fast Python package manager)
    log "Installing uv package manager..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add uv to PATH for all users
    echo 'export PATH="$HOME/.cargo/bin:$PATH"' >> /etc/profile.d/uv.sh
    
    # Source it for current session
    export PATH="$HOME/.cargo/bin:$PATH"
    
    log "Python installation completed"
}

# Install PostgreSQL 15
install_postgresql() {
    log "Installing PostgreSQL 15..."
    
    # Add PostgreSQL APT repository
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
    apt-get update
    
    # Install PostgreSQL 15
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        postgresql-15 \
        postgresql-client-15 \
        postgresql-contrib-15 \
        libpq-dev
    
    # Configure PostgreSQL
    systemctl enable postgresql
    systemctl start postgresql
    
    # Create database and user
    sudo -u postgres psql <<EOF
CREATE DATABASE aktienanalyse_event_store;
CREATE USER stock_analysis WITH ENCRYPTED PASSWORD 'secure_password';
GRANT ALL PRIVILEGES ON DATABASE aktienanalyse_event_store TO stock_analysis;
ALTER USER stock_analysis CREATEDB;
EOF
    
    # Configure PostgreSQL for local connections
    echo "host    all             stock_analysis  127.0.0.1/32            md5" >> /etc/postgresql/15/main/pg_hba.conf
    echo "host    all             stock_analysis  $CONTAINER_IP/32        md5" >> /etc/postgresql/15/main/pg_hba.conf
    
    # Enable listening on all interfaces
    sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/15/main/postgresql.conf
    
    systemctl restart postgresql
    
    log "PostgreSQL 15 installation completed"
}

# Install Redis
install_redis() {
    log "Installing Redis..."
    
    # Install Redis from official packages
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        redis-server \
        redis-tools
    
    # Configure Redis for event bus usage
    cat > /etc/redis/redis.conf <<EOF
# Basic configuration
bind 127.0.0.1 $CONTAINER_IP
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300

# Persistence
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis

# Logging
loglevel notice
logfile /var/log/redis/redis-server.log

# Memory management
maxmemory 2gb
maxmemory-policy allkeys-lru

# Append only file
appendonly yes
appendfilename "appendonly.aof"
appendfsync everysec
no-appendfsync-on-rewrite no

# Cluster configuration (for future use)
# cluster-enabled yes
# cluster-config-file nodes.conf
# cluster-node-timeout 5000
EOF
    
    # Set permissions
    chown redis:redis /etc/redis/redis.conf
    chmod 640 /etc/redis/redis.conf
    
    # Enable and start Redis
    systemctl enable redis-server
    systemctl restart redis-server
    
    log "Redis installation completed"
}

# Install RabbitMQ
install_rabbitmq() {
    log "Installing RabbitMQ..."
    
    # Add RabbitMQ repository
    curl -1sLf 'https://packagecloud.io/rabbitmq/rabbitmq-server/gpgkey' | apt-key add -
    
    cat > /etc/apt/sources.list.d/rabbitmq.list <<EOF
deb https://packagecloud.io/rabbitmq/rabbitmq-server/debian/ $(lsb_release -cs) main
EOF
    
    apt-get update
    
    # Install RabbitMQ
    DEBIAN_FRONTEND=noninteractive apt-get install -y rabbitmq-server
    
    # Enable management plugin
    rabbitmq-plugins enable rabbitmq_management
    
    # Create admin user
    rabbitmqctl add_user admin admin_password
    rabbitmqctl set_user_tags admin administrator
    rabbitmqctl set_permissions -p / admin ".*" ".*" ".*"
    
    # Create application user
    rabbitmqctl add_user stock_analysis stock_password
    rabbitmqctl set_permissions -p / stock_analysis ".*" ".*" ".*"
    
    # Enable and start RabbitMQ
    systemctl enable rabbitmq-server
    systemctl restart rabbitmq-server
    
    log "RabbitMQ installation completed"
}

# Create directory structure
create_directory_structure() {
    log "Creating directory structure..."
    
    # Create base directories
    directories=(
        "$BASE_DIR"
        "$BASE_DIR/venvs"
        "$BASE_DIR/scripts"
        "$BASE_DIR/config"
        "$BASE_DIR/logs"
        "$BASE_DIR/data"
        "$BASE_DIR/services"
        "/etc/stock-analysis"
        "/var/log/stock-analysis"
    )
    
    for dir in "${directories[@]}"; do
        mkdir -p "$dir"
        info "Created directory: $dir"
    done
    
    # Create service directories
    services=(
        "intelligent-core-service"
        "broker-gateway-service"
        "event-bus-service"
        "frontend-service"
        "monitoring-service"
    )
    
    for service in "${services[@]}"; do
        mkdir -p "$BASE_DIR/services/$service"
        mkdir -p "/var/log/stock-analysis/$service"
    done
    
    log "Directory structure created successfully"
}

# Create service user
create_service_user() {
    log "Creating service user..."
    
    # Check if user already exists
    if id "$SERVICE_USER" &>/dev/null; then
        warning "User $SERVICE_USER already exists"
    else
        # Create system user
        useradd --system --shell /bin/bash --home-dir "$BASE_DIR" \
            --create-home --comment "Stock Analysis Service User" "$SERVICE_USER"
        info "Created user: $SERVICE_USER"
    fi
    
    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$BASE_DIR"
    chown -R "$SERVICE_USER:$SERVICE_USER" "/var/log/stock-analysis"
    
    # Add user to necessary groups
    usermod -a -G redis,postgres "$SERVICE_USER"
    
    log "Service user configuration completed"
}

# Create systemd service template
create_systemd_templates() {
    log "Creating systemd service templates..."
    
    # Create generic Python service template
    cat > /etc/stock-analysis/python-service.template <<'EOF'
[Unit]
Description=Stock Analysis {SERVICE_NAME}
Documentation=https://github.com/MarcoFPO/aktienanalyse-ökosystem
After=network.target postgresql.service redis-server.service rabbitmq-server.service
Wants=postgresql.service redis-server.service rabbitmq-server.service

[Service]
Type=notify
User=stock-analysis
Group=stock-analysis
WorkingDirectory=/opt/stock-analysis/services/{SERVICE_DIR}
Environment="PATH=/opt/stock-analysis/venvs/{SERVICE_NAME}/bin:/usr/local/bin:/usr/bin:/bin"
Environment="PYTHONPATH=/opt/stock-analysis/services/{SERVICE_DIR}"
Environment="SERVICE_NAME={SERVICE_NAME}"
Environment="NODE_ENV=production"

# Python virtual environment
ExecStartPre=/opt/stock-analysis/venvs/{SERVICE_NAME}/bin/python -m pip install --upgrade pip
ExecStart=/opt/stock-analysis/venvs/{SERVICE_NAME}/bin/python -m {SERVICE_MODULE}

# Restart configuration
Restart=always
RestartSec=10
StartLimitInterval=200
StartLimitBurst=5

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/stock-analysis /var/log/stock-analysis

# Resource limits
LimitNOFILE=65536
LimitNPROC=4096
MemoryLimit=2G
CPUQuota=200%

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier={SERVICE_NAME}

[Install]
WantedBy=multi-user.target
EOF
    
    # Create health check script template
    cat > /etc/stock-analysis/health-check.template <<'EOF'
#!/bin/bash
# Health check for {SERVICE_NAME}

SERVICE_URL="http://localhost:{SERVICE_PORT}/health"
MAX_RETRIES=3
RETRY_DELAY=2

for i in $(seq 1 $MAX_RETRIES); do
    if curl -f -s "$SERVICE_URL" > /dev/null; then
        exit 0
    fi
    
    if [ $i -lt $MAX_RETRIES ]; then
        sleep $RETRY_DELAY
    fi
done

exit 1
EOF
    
    chmod +x /etc/stock-analysis/health-check.template
    
    log "systemd templates created successfully"
}

# Create environment configuration
create_environment_config() {
    log "Creating environment configuration..."
    
    cat > /etc/stock-analysis/environment <<EOF
# Stock Analysis Ecosystem Environment Configuration
# Generated on $(date)

# System Configuration
STOCK_ANALYSIS_HOME=$BASE_DIR
STOCK_ANALYSIS_USER=$SERVICE_USER
CONTAINER_IP=$CONTAINER_IP
CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME

# Database Configuration
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=aktienanalyse_event_store
POSTGRES_USER=stock_analysis
POSTGRES_PASSWORD=secure_password

# Redis Configuration
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_CLUSTER_NODES=localhost:6379

# RabbitMQ Configuration
RABBITMQ_HOST=localhost
RABBITMQ_PORT=5672
RABBITMQ_USER=stock_analysis
RABBITMQ_PASSWORD=stock_password
RABBITMQ_VHOST=/

# Service Ports
INTELLIGENT_CORE_PORT=8001
BROKER_GATEWAY_PORT=8002
EVENT_BUS_PORT=8003
MONITORING_PORT=8004
FRONTEND_PORT=8005

# API Configuration
API_GATEWAY_URL=https://$CONTAINER_IP
INTERNAL_API_URL=http://localhost

# Logging Configuration
LOG_LEVEL=info
LOG_FORMAT=json
LOG_DIR=/var/log/stock-analysis

# Development/Production Mode
NODE_ENV=production
PYTHON_ENV=production
EOF
    
    # Set permissions
    chmod 644 /etc/stock-analysis/environment
    
    log "Environment configuration created"
}

# Install Node.js 18+
install_nodejs() {
    log "Installing Node.js 18+..."
    
    # Add NodeSource repository
    curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
    
    # Install Node.js
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs
    
    # Verify installation
    node_version=$(node --version)
    npm_version=$(npm --version)
    info "Node.js $node_version and npm $npm_version installed"
    
    log "Node.js installation completed"
}

# Create setup completion marker
mark_setup_complete() {
    log "Marking setup as complete..."
    
    # Create completion marker with metadata
    cat > "$BASE_DIR/.setup-complete" <<EOF
# Stock Analysis LXC Setup Completion Marker
SETUP_DATE=$(date -Iseconds)
SETUP_VERSION=1.0.0
DEBIAN_VERSION=$DEBIAN_VERSION
CONTAINER_IP=$CONTAINER_IP
CONTAINER_HOSTNAME=$CONTAINER_HOSTNAME
PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
NODE_VERSION=$(node --version 2>&1)
POSTGRES_VERSION=$(psql --version 2>&1 | awk '{print $3}')
REDIS_VERSION=$(redis-server --version 2>&1 | awk '{print $3}' | cut -d'=' -f2)
EOF
    
    chmod 644 "$BASE_DIR/.setup-complete"
    
    log "Setup marked as complete"
}

# Main setup function
main() {
    log "Starting Stock Analysis Native LXC Setup..."
    
    # Check if running as root
    check_root
    
    # Detect environment
    if detect_environment; then
        # Inside container - run setup
        info "Running setup inside LXC container"
        
        configure_network
        install_base_packages
        install_python
        install_nodejs
        install_postgresql
        install_redis
        install_rabbitmq
        create_directory_structure
        create_service_user
        create_systemd_templates
        create_environment_config
        mark_setup_complete
        
        log "✅ LXC container setup completed successfully!"
        info "Next steps:"
        echo "  1. Copy application code to $BASE_DIR/services/"
        echo "  2. Create Python virtual environments with uv"
        echo "  3. Configure service-specific settings"
        echo "  4. Start services with systemctl"
        
    else
        # On host - create container first
        info "Running on LXC host"
        create_lxc_container
        
        warning "Container created. Please run this script inside the container:"
        echo "  lxc exec stock-analysis-lxc -- bash"
        echo "  cd /root && ./setup-lxc-native.sh"
    fi
}

# Run main function
main "$@"