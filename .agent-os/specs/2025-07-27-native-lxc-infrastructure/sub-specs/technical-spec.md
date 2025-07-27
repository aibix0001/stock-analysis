# Technical Specification

This is the technical specification for the spec detailed in @.agent-os/specs/2025-07-27-native-lxc-infrastructure/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Technical Requirements

### LXC Container Specifications
- **Base OS:** Debian 12 (Bookworm)
- **Container Type:** Unprivileged LXC
- **Resources:** 4 vCPUs, 8GB RAM, 50GB storage
- **Network:** Static IP 10.1.1.120/24
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

**Option A:** Manual Installation and Configuration
- Pros: Full control, learning experience, minimal abstraction
- Cons: Time-consuming, error-prone, harder to reproduce

**Option B:** Automated Setup Scripts (Selected)
- Pros: Reproducible, faster deployment, documented process, version controlled
- Cons: Initial script development time

**Rationale:** Automation ensures consistent deployments and serves as executable documentation for the infrastructure setup.

## External Dependencies

### System-Level Dependencies
- **Debian APT Repositories** - For base system packages
- **PostgreSQL APT Repository** - For PostgreSQL 15+
- **Redis Repository** - For latest Redis 7+
- **RabbitMQ Repository** - For RabbitMQ 3.12+

### Python Package Management
- **uv** - Fast Python package installer and virtual environment manager
- **Justification:** Superior performance compared to pip, native virtual environment support, developed by Ruff team

### Infrastructure Scripts
- **setup-lxc.sh** - Main installation script
- **configure-services.sh** - Service configuration
- **health-check.py** - Unified health check implementation

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