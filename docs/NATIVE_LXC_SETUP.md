# 🚀 Native LXC Setup Guide

This guide explains how to set up the Stock Analysis Ecosystem using native LXC containers with systemd services (no Docker).

## 📋 Prerequisites

- Proxmox host or LXC-capable Linux system
- Root access to create containers
- Network bridge configured (e.g., lxdbr0)
- At least 6GB RAM and 4 CPU cores available

## 🏗️ Setup Process

### 1. Create LXC Container (On Proxmox Host)

```bash
# Create Debian 12 container
lxc launch images:debian/12 stock-analysis-lxc

# Configure resources
lxc config set stock-analysis-lxc limits.cpu 4
lxc config set stock-analysis-lxc limits.memory 6GB
lxc config device add stock-analysis-lxc eth0 nic nictype=bridged parent=lxdbr0 ipv4.address=10.1.1.120

# Enter container
lxc exec stock-analysis-lxc -- bash
```

### 2. Run Setup Script (Inside Container)

```bash
# Download repository
git clone https://github.com/yourusername/stock-analysis.git
cd stock-analysis

# Run native LXC setup
chmod +x scripts/setup-lxc-native.sh
./scripts/setup-lxc-native.sh

# The script will:
# - Configure network (10.1.1.120)
# - Install Python 3.11+, Node.js 18+
# - Set up PostgreSQL 15, Redis, RabbitMQ
# - Create directory structure
# - Configure systemd service templates
```

### 3. Verify Installation

```bash
# Run infrastructure tests
./tests/infrastructure/test-lxc-setup.sh

# Or use Python test suite for detailed validation
python3 ./tests/infrastructure/test_lxc_infrastructure.py
```

## 🛠️ Service Management

### Creating Services

Each microservice needs:
1. Python virtual environment
2. systemd service file
3. Configuration

Example for intelligent-core-service:

```bash
# Create virtual environment
cd /opt/stock-analysis
uv venv venvs/intelligent-core-service

# Activate and install dependencies
source venvs/intelligent-core-service/bin/activate
uv pip install fastapi uvicorn sqlalchemy psycopg2-binary redis pydantic

# Create service
./scripts/create-systemd-service.sh intelligent-core-service app.main 8001

# Start service
systemctl start stock-analysis-intelligent-core-service
systemctl enable stock-analysis-intelligent-core-service
```

### Service Commands

```bash
# Check service status
systemctl status stock-analysis-intelligent-core-service

# View logs
journalctl -u stock-analysis-intelligent-core-service -f

# Restart service
systemctl restart stock-analysis-intelligent-core-service

# Stop service
systemctl stop stock-analysis-intelligent-core-service
```

## 📁 Directory Structure

```
/opt/stock-analysis/
├── venvs/              # Python virtual environments
│   ├── intelligent-core-service/
│   ├── broker-gateway-service/
│   ├── event-bus-service/
│   ├── frontend-service/
│   └── monitoring-service/
├── services/           # Service code
├── scripts/            # Operational scripts
├── config/             # Configuration files
├── logs/               # Service logs
└── data/               # Persistent data

/etc/stock-analysis/
├── environment         # Global environment variables
├── python-service.template
└── health-check.template
```

## 🔧 Configuration

### Environment Variables

Edit `/etc/stock-analysis/environment`:

```bash
# Database connections
POSTGRES_HOST=localhost
POSTGRES_DB=aktienanalyse_event_store
POSTGRES_USER=stock_analysis
POSTGRES_PASSWORD=your_secure_password

# Redis configuration
REDIS_HOST=localhost
REDIS_PORT=6379

# Service ports
INTELLIGENT_CORE_PORT=8001
BROKER_GATEWAY_PORT=8002
EVENT_BUS_PORT=8003
MONITORING_PORT=8004
FRONTEND_PORT=8005
```

### Database Setup

```bash
# Apply event store schema
sudo -u postgres psql aktienanalyse_event_store < shared/database/event-store-schema.sql

# Verify database
sudo -u postgres psql -d aktienanalyse_event_store -c "\dt"
```

## 🚨 Troubleshooting

### Service Won't Start

1. Check logs: `journalctl -u stock-analysis-SERVICE_NAME -n 50`
2. Verify virtual environment: `/opt/stock-analysis/venvs/SERVICE_NAME/bin/python --version`
3. Test manually: `cd /opt/stock-analysis/services/SERVICE_NAME && /opt/stock-analysis/venvs/SERVICE_NAME/bin/python -m app.main`

### Database Connection Issues

1. Check PostgreSQL: `systemctl status postgresql`
2. Test connection: `psql -h localhost -U stock_analysis -d aktienanalyse_event_store`
3. Verify pg_hba.conf allows local connections

### Network Issues

1. Verify IP: `ip addr show | grep 10.1.1.120`
2. Check hostname: `hostname`
3. Test connectivity: `ping 10.1.1.1`

## 🎯 Next Steps

After basic setup:

1. Deploy service code to `/opt/stock-analysis/services/`
2. Create virtual environments for each service
3. Configure service-specific settings
4. Set up HTTPS with Caddy/Nginx
5. Configure monitoring with Zabbix

## 📚 Additional Resources

- [systemd Service Management](https://www.freedesktop.org/software/systemd/man/systemd.service.html)
- [PostgreSQL Event Store](https://www.postgresql.org/docs/15/index.html)
- [Redis Cluster](https://redis.io/topics/cluster-tutorial)
- [RabbitMQ Configuration](https://www.rabbitmq.com/configure.html)