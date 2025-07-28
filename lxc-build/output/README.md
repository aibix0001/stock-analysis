# Stock Analysis LXC Template

Version: 1.0.0
Build Date: 2025-07-28 20:27:47 UTC

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
   ```bash
   scp stock-analysis-lxc-template-latest.tar.gz root@proxmox:/var/lib/vz/template/cache/
   ```

2. Create a new container:
   ```bash
   pct create 100 /var/lib/vz/template/cache/stock-analysis-lxc-template-latest.tar.gz \
     --hostname stock-analysis \
     --memory 8192 \
     --cores 4 \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --storage local-lvm \
     --rootfs local-lvm:50 \
     --unprivileged 1 \
     --features nesting=1
   ```

3. Start the container:
   ```bash
   pct start 100
   ```

4. The first boot will automatically run the setup scripts.

### Post-Deployment

1. Enter the container:
   ```bash
   pct enter 100
   ```

2. Check setup status:
   ```bash
   systemctl status stock-analysis-first-boot
   ```

3. Run health checks:
   ```bash
   python3 /opt/stock-analysis/scripts/health-check.py
   ```

4. Start services:
   ```bash
   systemctl start stock-analysis-broker-gateway
   systemctl start stock-analysis-intelligent-core
   systemctl start stock-analysis-event-bus
   systemctl start stock-analysis-monitoring
   systemctl start stock-analysis-frontend
   ```

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
```bash
journalctl -u stock-analysis-first-boot
journalctl -u stock-analysis-*
```

## Build Information

- Build Host: CC
- Build User: aibix
- Build Directory: /home/aibix/others/stock-analysis/lxc-build
