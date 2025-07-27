# Stock Analysis LXC Template

This directory contains the LXC container template for the Stock Analysis Ecosystem, designed for deployment on Proxmox VE.

## 📋 Overview

The LXC template packages the entire Stock Analysis Ecosystem into a ready-to-deploy container image that includes:

- **Debian 12 (Bookworm)** base system
- **PostgreSQL 15** with Event Store schema
- **Redis** for caching and pub/sub
- **RabbitMQ** for message queuing
- **Python 3.11** with uv package manager
- **5 Microservices** pre-configured
- **Automatic first-boot configuration**

## 🚀 Quick Start

### Building the Template

```bash
# Requires root access and debootstrap
sudo ./build-lxc-template.sh
```

This creates: `stock-analysis-debian12-1.0.0-YYYYMMDD.tar.gz`

### Deploying on Proxmox

1. **Copy template to Proxmox storage:**
   ```bash
   scp stock-analysis-debian12-*.tar.gz root@proxmox:/var/lib/vz/template/cache/
   ```

2. **Create container using the script:**
   ```bash
   # On Proxmox host
   ./create-proxmox-container.sh 120 /var/lib/vz/template/cache/stock-analysis-debian12-*.tar.gz
   ```

3. **Or create manually:**
   ```bash
   pct create 120 /var/lib/vz/template/cache/stock-analysis-debian12-*.tar.gz \
     --hostname stock-analysis \
     --memory 4096 \
     --cores 2 \
     --rootfs local-lvm:20 \
     --net0 name=eth0,bridge=vmbr0,ip=dhcp \
     --features nesting=1 \
     --unprivileged 1
   ```

## 📁 Directory Structure

```
lxc-template/
├── build-lxc-template.sh        # Main build script
├── create-proxmox-container.sh  # Container creation helper
├── validate-template.sh         # Template validation script
├── template-config/             # Template configuration files
│   ├── container.conf          # LXC container configuration
│   ├── pct-hooks.sh           # Proxmox CT hooks
│   └── template.dat           # Template metadata
└── README.md                   # This file
```

## 🔧 Template Features

### Resource Requirements

- **Minimum RAM:** 4 GB
- **Minimum CPU:** 2 cores
- **Minimum Disk:** 20 GB
- **Network:** 1 interface (DHCP or static)

### Included Services

| Service | Port | Description |
|---------|------|-------------|
| SSH | 22 | Remote access |
| PostgreSQL | 5432 | Event store database |
| Redis | 6379 | Cache and pub/sub |
| RabbitMQ | 5672, 15672 | Message queue and management |
| Intelligent Core | 8001 | Analysis engine |
| Broker Gateway | 8002 | Trading integration |
| Event Bus | 8003 | Event routing |
| Monitoring | 8004 | System monitoring |
| Frontend API | 8005 | Web backend |

### First Boot Process

On first boot, the container automatically:

1. Initializes PostgreSQL with event store schema
2. Configures Redis for clustering
3. Sets up RabbitMQ users and exchanges
4. Creates Python virtual environments
5. Installs all Python dependencies
6. Generates systemd service files
7. Starts all microservices

Monitor first boot progress:
```bash
pct exec <vmid> -- journalctl -u stock-analysis-firstboot -f
```

## 🛠️ Customization

### Build Options

Edit `build-lxc-template.sh` to customize:

- Base packages
- Service configurations
- Default passwords
- Network settings

### Template Configuration

Modify files in `template-config/`:

- `container.conf` - LXC container settings
- `template.dat` - Template metadata
- `pct-hooks.sh` - Container lifecycle hooks

### Post-Deployment

After deployment, you can:

1. **Change default password:**
   ```bash
   pct exec <vmid> -- passwd stock-analysis
   ```

2. **Configure static IP:**
   ```bash
   pct set <vmid> --net0 name=eth0,bridge=vmbr0,ip=10.1.1.120/24,gw=10.1.1.1
   ```

3. **Add data volumes:**
   ```bash
   # PostgreSQL data
   pct set <vmid> --mp0 local-lvm:10,mp=/var/lib/postgresql,backup=1
   
   # Redis data
   pct set <vmid> --mp1 local-lvm:5,mp=/var/lib/redis,backup=1
   ```

## 🔍 Validation

Run the validation script to check template integrity:

```bash
./validate-template.sh stock-analysis-debian12-*.tar.gz
```

This verifies:
- File structure
- Required binaries
- Configuration files
- Service definitions
- Network settings

## 📊 Performance Tuning

### Container Settings

For production workloads:

```bash
# Increase resources
pct set <vmid> --memory 8192 --cores 4

# Enable additional features
pct set <vmid> --features nesting=1,keyctl=1,fuse=1

# Set CPU units (priority)
pct set <vmid> --cpuunits 2000
```

### Service Optimization

Inside the container:

```bash
# Tune PostgreSQL
vi /etc/postgresql/15/main/postgresql.conf

# Adjust Redis memory
vi /etc/redis/redis.conf

# Configure RabbitMQ
vi /etc/rabbitmq/rabbitmq.conf
```

## 🔐 Security

### Default Credentials

- **System user:** stock-analysis / changeme
- **PostgreSQL:** stock_analysis / secure_password  
- **RabbitMQ:** stock_analysis / stock_password

**⚠️ Change all default passwords after deployment!**

### Hardening

1. **Disable root SSH:**
   ```bash
   pct exec <vmid> -- sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
   ```

2. **Configure firewall:**
   ```bash
   pct exec <vmid> -- ufw allow 22/tcp
   pct exec <vmid> -- ufw allow 8001:8005/tcp
   pct exec <vmid> -- ufw enable
   ```

3. **Limit container capabilities:**
   ```bash
   pct set <vmid> --features nesting=0
   ```

## 🐛 Troubleshooting

### Build Issues

- **debootstrap fails:** Ensure you have internet connectivity
- **Mount errors:** Run as root or with proper permissions
- **Package errors:** Check Debian mirror availability

### Deployment Issues

- **Container won't start:** Check Proxmox logs: `journalctl -xe`
- **Network issues:** Verify bridge configuration
- **Service failures:** Check first boot logs

### Common Commands

```bash
# Check container status
pct status <vmid>

# View container configuration
pct config <vmid>

# Enter container
pct enter <vmid>

# Execute command
pct exec <vmid> -- <command>

# View logs
pct exec <vmid> -- journalctl -u stock-analysis-*
```

## 📝 License

This template is part of the Stock Analysis Ecosystem and follows the same license terms.