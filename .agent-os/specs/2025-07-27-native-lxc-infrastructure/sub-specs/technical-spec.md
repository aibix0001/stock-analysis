# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-27-native-lxc-infrastructure/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Technical Requirements

### LXC Container Specifications
- **Base OS:** Debian 12 (Bookworm)
- **Container Type:** Unprivileged LXC
- **Resources:** 4 vCPUs, 8GB RAM, 50GB storage
- **Network:** DHCP (automatic IP assignment)
- **Hostname:** stock-analysis

### System Package Requirements
- Python 3.11+ (from Debian repos)
- PostgreSQL 15+
- Redis 7+
- RabbitMQ 3.12+
- systemd (for service management)
- curl, git, build-essential
- libpq-dev (for psycopg2)
- supervisor (optional fallback)

### Python Environment Management
- **Tool:** uv (Astral) - https://github.com/astral-sh/uv
- **Virtual Environment Location:** /opt/stock-analysis/venvs/[service-name]
- **Python Version:** 3.11+
- **Package Management:** uv pip for all dependencies

### Service Architecture
1. **Broker Gateway Service** - Port 8001
2. **Intelligent Core Service** - Port 8002
3. **Event Bus Service** - Port 8003
4. **Monitoring Service** - Port 8004
5. **Frontend Service** - Port 8005

### Systemd Service Template Structure
- Service files in /etc/systemd/system/
- Environment files in /etc/stock-analysis/
- Logs to systemd journal
- Restart policies with backoff
- Proper dependency ordering

## Approach Options

**Option A:** Build Inside Container on Proxmox
- Pros: Direct installation, immediate testing
- Cons: Requires Proxmox access, slower iteration, harder to version control

**Option B:** Build System on Development Machine (Selected)
- Pros: Version controlled, fast iteration, no Proxmox access needed, reproducible builds
- Cons: More complex build process, requires careful script organization

**Rationale:** A build system on the development machine allows for rapid iteration, version control of all components, and produces a distributable template that can be deployed anywhere.

## External Dependencies

### System-Level Dependencies
- **Debian APT Repositories** - For base system packages
- **PostgreSQL APT Repository** - For PostgreSQL 15+
- **Redis Repository** - For latest Redis 7+
- **RabbitMQ Repository** - For RabbitMQ 3.12+

### Python Package Management
- **uv** - Fast Python package installer and virtual environment manager
- **Justification:** Superior performance compared to pip, native virtual environment support, developed by Ruff team

### Build System Components
- **build-template.sh** - Main build script that runs on development machine
- **setup-system.sh** - Installation script included in template for base system setup
- **setup-services.sh** - Service installation and configuration script
- **setup-databases.sh** - Database installation and initialization script
- **health-check.py** - Unified health check implementation for all services

## Configuration Details

### PostgreSQL Configuration
- Database: stock_analysis_event_store
- User: stock_analysis_user
- Connection pooling: 100 connections
- Shared buffers: 25% of RAM
- Enable materialized view refresh

### Redis Cluster Configuration
- 3 nodes on ports: 6379, 6380, 6381
- Cluster mode enabled
- Persistence: RDB + AOF
- Memory policy: allkeys-lru
- Max memory: 2GB per node

### RabbitMQ Configuration
- Virtual host: /stock-analysis
- Exchange: stock-analysis-events (topic)
- Dead letter exchange: stock-analysis-dlx
- Management plugin enabled
- Default user with restricted permissions

### Network Configuration
- All services bind to 0.0.0.0 (container-internal)
- PostgreSQL: 5432
- Redis: 6379-6381
- RabbitMQ: 5672 (AMQP), 15672 (Management)
- Service ports: 8001-8005

## Security Considerations

### LXC Security
- Unprivileged container
- AppArmor profile enabled
- Restricted capabilities
- No container nesting

### Service Security
- Services run as non-root users
- Systemd DynamicUser where applicable
- Read-only root filesystem where possible
- Private tmp directories

### Database Security
- PostgreSQL password authentication
- Redis requirepass enabled
- RabbitMQ user permissions restricted
- No external network access (LXC internal only)

## Build Process Architecture

### Build System Structure
```
lxc-build/
├── build-template.sh           # Main build orchestrator
├── scripts/                    # Scripts to be included in template
│   ├── setup-system.sh        # Base system installation
│   ├── setup-python.sh        # Python and uv setup
│   ├── setup-databases.sh     # PostgreSQL, Redis, RabbitMQ
│   ├── setup-services.sh      # Systemd services setup
│   └── health-check.py        # Health check implementation
├── config/                     # Configuration templates
│   ├── systemd/               # Service unit files
│   ├── postgresql/            # Database configs
│   ├── redis/                 # Redis cluster configs
│   └── rabbitmq/              # Message queue configs
├── templates/                  # LXC metadata templates
│   └── metadata.yaml          # Container metadata
└── tests/                      # Build system tests
    └── test_build_process.py  # Build verification tests
```

### Build Workflow
1. **Preparation Phase**
   - Validate build environment
   - Create temporary build directory
   - Generate configuration files from templates

2. **Template Assembly**
   - Create rootfs directory structure
   - Copy installation scripts to template
   - Include all configuration files
   - Generate container metadata

3. **Packaging Phase**
   - Create tar.gz archive with proper permissions
   - Generate deployment documentation
   - Calculate checksums for verification

### Template Deployment Process
When the generated template is used on a Proxmox host:
1. Container creation from template
2. First boot runs setup-system.sh automatically
3. Subsequent scripts execute in order
4. Services start automatically via systemd
5. Health checks verify successful deployment