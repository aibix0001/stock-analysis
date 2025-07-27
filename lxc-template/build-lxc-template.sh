#!/bin/bash
# Build LXC template for Stock Analysis Ecosystem
# Creates a Proxmox-compatible container template

set -euo pipefail

# Configuration
TEMPLATE_NAME="stock-analysis-debian12"
TEMPLATE_VERSION="1.0.0"
BUILD_DATE=$(date +%Y%m%d)
TEMPLATE_FILE="${TEMPLATE_NAME}-${TEMPLATE_VERSION}-${BUILD_DATE}.tar.gz"
WORK_DIR="/tmp/lxc-template-build"
ROOTFS_DIR="${WORK_DIR}/rootfs"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}Building LXC Template: ${TEMPLATE_NAME} v${TEMPLATE_VERSION}${NC}"
echo "=================================================="

# Cleanup function
cleanup() {
    echo -e "${YELLOW}Cleaning up...${NC}"
    umount "${ROOTFS_DIR}/proc" 2>/dev/null || true
    umount "${ROOTFS_DIR}/sys" 2>/dev/null || true
    umount "${ROOTFS_DIR}/dev" 2>/dev/null || true
    rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

# Create work directory
mkdir -p "${ROOTFS_DIR}"

# Step 1: Bootstrap Debian 12
echo -e "${BLUE}Step 1: Bootstrapping Debian 12...${NC}"
debootstrap --variant=minbase --arch=amd64 bookworm "${ROOTFS_DIR}" http://deb.debian.org/debian/

# Step 2: Configure base system
echo -e "${BLUE}Step 2: Configuring base system...${NC}"

# Set hostname
echo "stock-analysis" > "${ROOTFS_DIR}/etc/hostname"

# Configure hosts
cat > "${ROOTFS_DIR}/etc/hosts" <<EOF
127.0.0.1   localhost
127.0.1.1   stock-analysis

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# Configure network interfaces
cat > "${ROOTFS_DIR}/etc/network/interfaces" <<EOF
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF

# Configure apt sources
cat > "${ROOTFS_DIR}/etc/apt/sources.list" <<EOF
deb http://deb.debian.org/debian bookworm main contrib non-free non-free-firmware
deb http://deb.debian.org/debian bookworm-updates main contrib non-free non-free-firmware
deb http://security.debian.org/debian-security bookworm-security main contrib non-free non-free-firmware
EOF

# Mount necessary filesystems for chroot
mount -t proc proc "${ROOTFS_DIR}/proc"
mount -t sysfs sys "${ROOTFS_DIR}/sys"
mount -o bind /dev "${ROOTFS_DIR}/dev"

# Step 3: Install base packages
echo -e "${BLUE}Step 3: Installing base packages...${NC}"

# Create package installation script
cat > "${ROOTFS_DIR}/tmp/install-base.sh" <<'SCRIPT'
#!/bin/bash
set -e

# Update package list
apt-get update

# Install essential packages
DEBIAN_FRONTEND=noninteractive apt-get install -y \
    systemd \
    systemd-sysv \
    init \
    openssh-server \
    sudo \
    curl \
    wget \
    gnupg \
    lsb-release \
    ca-certificates \
    locales \
    tzdata \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    build-essential \
    git \
    vim \
    htop \
    net-tools \
    iputils-ping \
    dnsutils \
    postgresql-15 \
    postgresql-client-15 \
    postgresql-contrib-15 \
    redis-server \
    redis-tools \
    rabbitmq-server \
    nginx \
    supervisor \
    jq \
    ripgrep \
    fd-find \
    ncdu \
    tree \
    tmux

# Configure locales
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
update-locale LANG=en_US.UTF-8

# Configure timezone
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
echo "UTC" > /etc/timezone

# Clean up
apt-get clean
rm -rf /var/lib/apt/lists/*
SCRIPT

chmod +x "${ROOTFS_DIR}/tmp/install-base.sh"
chroot "${ROOTFS_DIR}" /tmp/install-base.sh
rm "${ROOTFS_DIR}/tmp/install-base.sh"

# Step 4: Create stock-analysis user
echo -e "${BLUE}Step 4: Creating stock-analysis user...${NC}"

chroot "${ROOTFS_DIR}" useradd -m -s /bin/bash -G sudo stock-analysis
echo "stock-analysis:changeme" | chroot "${ROOTFS_DIR}" chpasswd
echo "stock-analysis ALL=(ALL) NOPASSWD:ALL" > "${ROOTFS_DIR}/etc/sudoers.d/stock-analysis"

# Step 5: Copy stock-analysis application
echo -e "${BLUE}Step 5: Installing stock-analysis application...${NC}"

# Create directory structure
mkdir -p "${ROOTFS_DIR}/opt/stock-analysis"
mkdir -p "${ROOTFS_DIR}/etc/stock-analysis"
mkdir -p "${ROOTFS_DIR}/var/log/stock-analysis"

# Copy application files (excluding .git and other unnecessary files)
rsync -av --exclude='.git' \
          --exclude='*.pyc' \
          --exclude='__pycache__' \
          --exclude='.venv' \
          --exclude='venvs' \
          --exclude='node_modules' \
          --exclude='.agent-os' \
          --exclude='lxc-template' \
          . "${ROOTFS_DIR}/opt/stock-analysis/"

# Set ownership
chroot "${ROOTFS_DIR}" chown -R stock-analysis:stock-analysis /opt/stock-analysis
chroot "${ROOTFS_DIR}" chown -R stock-analysis:stock-analysis /var/log/stock-analysis

# Step 6: Configure services
echo -e "${BLUE}Step 6: Configuring services...${NC}"

# PostgreSQL configuration
cat > "${ROOTFS_DIR}/tmp/configure-postgres.sh" <<'SCRIPT'
#!/bin/bash
# Initialize PostgreSQL
su - postgres -c "initdb -D /var/lib/postgresql/15/main"

# Start PostgreSQL temporarily
su - postgres -c "pg_ctl -D /var/lib/postgresql/15/main -l /var/log/postgresql/postgresql-15-main.log start"
sleep 5

# Create database and user
su - postgres -c "createuser -s stock_analysis"
su - postgres -c "createdb -O stock_analysis aktienanalyse_event_store"
su - postgres -c "psql -c \"ALTER USER stock_analysis PASSWORD 'secure_password';\""

# Stop PostgreSQL
su - postgres -c "pg_ctl -D /var/lib/postgresql/15/main stop"

# Configure PostgreSQL for systemd
systemctl enable postgresql
SCRIPT

chmod +x "${ROOTFS_DIR}/tmp/configure-postgres.sh"
chroot "${ROOTFS_DIR}" /tmp/configure-postgres.sh || true
rm "${ROOTFS_DIR}/tmp/configure-postgres.sh"

# Redis configuration
cat >> "${ROOTFS_DIR}/etc/redis/redis.conf" <<EOF

# Stock Analysis custom configuration
bind 127.0.0.1 ::1
protected-mode yes
port 6379
tcp-backlog 511
timeout 0
tcp-keepalive 300
daemonize no
supervised systemd
pidfile /var/run/redis/redis-server.pid
loglevel notice
logfile /var/log/redis/redis-server.log
databases 16
save 900 1
save 300 10
save 60 10000
stop-writes-on-bgsave-error yes
rdbcompression yes
rdbchecksum yes
dbfilename dump.rdb
dir /var/lib/redis
maxmemory 1gb
maxmemory-policy allkeys-lru
EOF

chroot "${ROOTFS_DIR}" systemctl enable redis-server

# RabbitMQ configuration
chroot "${ROOTFS_DIR}" systemctl enable rabbitmq-server

# Create first-boot script
cat > "${ROOTFS_DIR}/opt/stock-analysis/scripts/first-boot.sh" <<'SCRIPT'
#!/bin/bash
# First boot configuration script

set -euo pipefail

FIRST_BOOT_FLAG="/etc/stock-analysis/.first-boot-complete"

if [ -f "${FIRST_BOOT_FLAG}" ]; then
    echo "First boot already completed"
    exit 0
fi

echo "Running first boot configuration..."

# Start services
systemctl start postgresql redis-server rabbitmq-server

# Wait for services
sleep 10

# Initialize database schema
cd /opt/stock-analysis
if [ -f "shared/database/event-store-schema.sql" ]; then
    sudo -u postgres psql aktienanalyse_event_store < shared/database/event-store-schema.sql
fi

# Configure RabbitMQ
rabbitmqctl add_user stock_analysis stock_password 2>/dev/null || true
rabbitmqctl set_user_tags stock_analysis administrator
rabbitmqctl set_permissions -p / stock_analysis ".*" ".*" ".*"

# Initialize Python environments
/opt/stock-analysis/scripts/setup-python-env.sh

# Create systemd services
/opt/stock-analysis/scripts/create-systemd-service.sh all

# Mark first boot complete
mkdir -p /etc/stock-analysis
touch "${FIRST_BOOT_FLAG}"

echo "First boot configuration completed!"
SCRIPT

chmod +x "${ROOTFS_DIR}/opt/stock-analysis/scripts/first-boot.sh"

# Create systemd service for first boot
cat > "${ROOTFS_DIR}/etc/systemd/system/stock-analysis-firstboot.service" <<EOF
[Unit]
Description=Stock Analysis First Boot Configuration
After=network.target postgresql.service redis-server.service rabbitmq-server.service
ConditionPathExists=!/etc/stock-analysis/.first-boot-complete

[Service]
Type=oneshot
ExecStart=/opt/stock-analysis/scripts/first-boot.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

chroot "${ROOTFS_DIR}" systemctl enable stock-analysis-firstboot.service

# Step 7: Create template metadata
echo -e "${BLUE}Step 7: Creating template metadata...${NC}"

# Create template info
cat > "${WORK_DIR}/template-info" <<EOF
NAME: ${TEMPLATE_NAME}
VERSION: ${TEMPLATE_VERSION}
OS: Debian 12 (Bookworm)
ARCH: amd64
BUILD_DATE: ${BUILD_DATE}
DESCRIPTION: Stock Analysis Ecosystem - Event-driven trading intelligence platform
AUTHOR: Stock Analysis Team
MIN_RAM: 4096
MIN_DISK: 20G
MIN_CPU: 2
FEATURES:
  - PostgreSQL 15 with Event Store
  - Redis for caching and pub/sub
  - RabbitMQ for message queuing
  - Python 3.11 with uv package manager
  - 5 microservices architecture
  - systemd service management
  - Health check endpoints
  - Auto-configuration on first boot
DEFAULT_USER: stock-analysis
DEFAULT_PASS: changeme
NETWORK: DHCP (eth0)
SERVICES:
  - ssh (port 22)
  - postgresql (port 5432)
  - redis (port 6379)
  - rabbitmq (port 5672, 15672)
  - intelligent-core (port 8001)
  - broker-gateway (port 8002)
  - event-bus (port 8003)
  - monitoring (port 8004)
  - frontend (port 8005)
EOF

# Step 8: Clean up rootfs
echo -e "${BLUE}Step 8: Cleaning up rootfs...${NC}"

# Remove unnecessary files
rm -rf "${ROOTFS_DIR}/tmp/*"
rm -rf "${ROOTFS_DIR}/var/cache/apt/*"
rm -rf "${ROOTFS_DIR}/var/lib/apt/lists/*"
rm -rf "${ROOTFS_DIR}/root/.bash_history"

# Clear logs
find "${ROOTFS_DIR}/var/log" -type f -exec truncate -s 0 {} \;

# Step 9: Create tarball
echo -e "${BLUE}Step 9: Creating template tarball...${NC}"

cd "${WORK_DIR}"
tar czf "${TEMPLATE_FILE}" rootfs template-info

# Move to output location
mv "${TEMPLATE_FILE}" /home/aibix/others/stock-analysis/lxc-template/

# Calculate size
TEMPLATE_SIZE=$(du -h "/home/aibix/others/stock-analysis/lxc-template/${TEMPLATE_FILE}" | cut -f1)

echo ""
echo -e "${GREEN}✅ LXC Template created successfully!${NC}"
echo ""
echo "Template: /home/aibix/others/stock-analysis/lxc-template/${TEMPLATE_FILE}"
echo "Size: ${TEMPLATE_SIZE}"
echo ""
echo "To use in Proxmox:"
echo "1. Copy template to Proxmox storage: /var/lib/vz/template/cache/"
echo "2. Create container: pct create <vmid> ${TEMPLATE_FILE} --hostname stock-analysis --memory 4096 --cores 2 --net0 name=eth0,bridge=vmbr0,ip=dhcp"
echo "3. Start container: pct start <vmid>"
echo "4. First boot will automatically configure all services"