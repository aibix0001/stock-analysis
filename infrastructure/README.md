# Stock Analysis Infrastructure

This directory contains the infrastructure setup scripts for the Stock Analysis ecosystem, designed for deployment in LXC containers on Proxmox.

## Overview

The infrastructure consists of:
- Debian 12 (Bookworm) LXC container
- PostgreSQL 15+ with Event Store schema
- Redis 3-node cluster for event bus
- RabbitMQ for message queuing
- Python 3.11+ with uv package manager
- Systemd service templates for 5 microservices

## Quick Start

1. Create a Debian 12 LXC container in Proxmox with:
   - 4 vCPUs
   - 8GB RAM
   - 50GB disk
   - Network: DHCP (automatic IP assignment)

2. Copy the infrastructure directory to the container:
   ```bash
   # From Proxmox host
   pct push <container-id> infrastructure/lxc-setup/setup-lxc.sh /root/setup-lxc.sh
   ```

3. Enter the container and run setup:
   ```bash
   # Enter container
   pct enter <container-id>
   
   # Run setup
   chmod +x /root/setup-lxc.sh
   /root/setup-lxc.sh
   ```

4. Run tests to verify setup:
   ```bash
   /infrastructure/lxc-setup/tests/test_lxc_setup.sh
   ```

## Directory Structure

```
infrastructure/
├── lxc-setup/
│   ├── setup-lxc.sh           # Main setup script
│   ├── configure-network.sh   # Network configuration
│   ├── init-databases.sh      # Database initialization
│   └── tests/
│       └── test_lxc_setup.sh  # Test suite
└── README.md
```

## Scripts

### setup-lxc.sh
Main installation script that:
- Configures network settings
- Installs all system packages
- Sets up PostgreSQL, Redis, and RabbitMQ
- Creates Python virtual environments
- Configures systemd services
- Sets up security (firewall, users)

### configure-network.sh
Standalone network configuration for:
- DHCP automatic IP assignment
- Hostname: stock-analysis
- DNS: Provided by DHCP server

### init-databases.sh
Database initialization that:
- Creates PostgreSQL event store
- Sets up Redis cluster
- Configures RabbitMQ exchanges/queues
- Creates initial test data

### test_lxc_setup.sh
Comprehensive test suite that verifies:
- LXC environment
- Network configuration
- System resources
- Package installations
- Service configurations
- Database connectivity

## Services

After setup, the following services are available:

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Event store database |
| Redis | 6379-6381 | 3-node cluster |
| RabbitMQ | 5672/15672 | AMQP/Management |
| Broker Gateway | 8001 | Trading API gateway |
| Intelligent Core | 8002 | Analysis engine |
| Event Bus | 8003 | WebSocket events |
| Monitoring | 8004 | Health monitoring |
| Frontend | 8005 | Web interface |

## Configuration

### Environment Files
Located in `/etc/stock-analysis/`:
- `common.env` - Shared configuration
- `broker-gateway.env` - Broker service config
- `intelligent-core.env` - Analysis service config
- `event-bus.env` - Event bus config
- `monitoring.env` - Monitoring config
- `frontend.env` - Frontend config

### Passwords
Default passwords are set to `CHANGE_THIS_PASSWORD`. Update these in:
- PostgreSQL: `/etc/stock-analysis/common.env`
- Redis: `/etc/stock-analysis/common.env`
- RabbitMQ: `/etc/stock-analysis/common.env`

### API Keys
Add your API keys to the respective service environment files:
- Alpha Vantage: `intelligent-core.env`
- EODHD: `intelligent-core.env`
- Bitpanda: `broker-gateway.env`

## Service Management

```bash
# Start a service
systemctl start stock-analysis-broker-gateway

# Check service status
systemctl status stock-analysis-broker-gateway

# View service logs
journalctl -u stock-analysis-broker-gateway -f

# Check all services
/opt/stock-analysis/scripts/status.sh
```

## Health Checks

Each service exposes a health endpoint:
```bash
curl http://localhost:8001/health
```

The health check verifies:
- PostgreSQL connectivity
- Redis connectivity
- RabbitMQ connectivity
- Service-specific checks

## Security

The setup includes:
- UFW firewall configuration
- Non-root service user
- Systemd security hardening
- Internal-only database access
- Password-protected services

## Troubleshooting

### Network Issues
```bash
# Verify network configuration
ip addr show
ip route
ping 10.1.1.1

# Reconfigure network
/infrastructure/lxc-setup/configure-network.sh
```

### Database Connection
```bash
# Test PostgreSQL
sudo -u postgres psql -d stock_analysis_event_store

# Test Redis
redis-cli -p 6379 -a <password> ping

# Test RabbitMQ
rabbitmqctl status
```

### Service Failures
```bash
# Check service logs
journalctl -u stock-analysis-<service> -n 100

# Verify environment files
cat /etc/stock-analysis/<service>.env

# Test health endpoint
curl -v http://localhost:<port>/health
```

## Next Steps

1. Update all passwords in environment files
2. Configure API keys for external services
3. Deploy application code to `/opt/stock-analysis/services/`
4. Start services and verify health checks
5. Configure Caddy reverse proxy for HTTPS access