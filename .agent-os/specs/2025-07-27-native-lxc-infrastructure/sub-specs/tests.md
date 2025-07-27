# Tests Specification

This is the tests coverage details for the spec detailed in @.agent-os/specs/2025-07-27-native-lxc-infrastructure/spec.md

> Created: 2025-07-27
> Version: 1.0.0

## Test Coverage

### Infrastructure Tests

**LXC Container Setup**
- Verify Debian 12 is installed and updated
- Check network configuration (IP: 10.1.1.120)
- Validate all required system packages are installed
- Ensure systemd is functioning correctly

**System Package Installation**
- Test PostgreSQL 15+ is installed and running
- Verify Redis cluster nodes are operational
- Check RabbitMQ service status and management UI
- Validate Python 3.11+ installation

### Service Configuration Tests

**Systemd Service Templates**
- Verify service files exist in /etc/systemd/system/
- Test service start/stop/restart functionality
- Validate service dependencies are correct
- Check automatic restart on failure

**Python Virtual Environments**
- Test uv installation and functionality
- Verify virtual environments created at correct paths
- Check Python version in each venv
- Validate package isolation between environments

### Database Tests

**PostgreSQL Event Store**
- Connect to database as stock_analysis_user
- Verify event_store schema exists
- Test event insertion and retrieval
- Validate materialized view creation and refresh
- Check performance of indexed queries

**Redis Cluster**
- Test connection to all three nodes
- Verify cluster formation
- Test pub/sub functionality
- Validate data replication between nodes
- Check persistence (RDB/AOF) is working

**RabbitMQ**
- Connect to AMQP port (5672)
- Verify virtual host creation
- Test exchange and queue creation
- Validate message publishing and consumption
- Check management UI accessibility

### Integration Tests

**Service Communication**
- Test service can connect to PostgreSQL
- Verify Redis pub/sub between services
- Check RabbitMQ message flow
- Validate event store write and read operations

**Health Check Endpoints**
- Test /health endpoint on each service port (8001-8005)
- Verify database connectivity checks
- Validate Redis connection status
- Check RabbitMQ availability

### Performance Tests

**Database Performance**
- Measure event insertion rate (target: >1000 events/sec)
- Test materialized view query time (target: <0.2s)
- Validate concurrent connection handling

**Message Queue Performance**
- Test Redis pub/sub latency (target: <5ms)
- Measure RabbitMQ throughput
- Validate message delivery under load

## Test Implementation

### Shell Script Tests

```bash
#!/bin/bash
# test-infrastructure.sh

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test functions
test_system_packages() {
    echo "Testing system packages..."
    
    # Check PostgreSQL
    if systemctl is-active --quiet postgresql; then
        echo -e "${GREEN}✓ PostgreSQL is running${NC}"
    else
        echo -e "${RED}✗ PostgreSQL is not running${NC}"
        return 1
    fi
    
    # Check Redis
    if redis-cli ping > /dev/null 2>&1; then
        echo -e "${GREEN}✓ Redis is responding${NC}"
    else
        echo -e "${RED}✗ Redis is not responding${NC}"
        return 1
    fi
    
    # Check RabbitMQ
    if systemctl is-active --quiet rabbitmq-server; then
        echo -e "${GREEN}✓ RabbitMQ is running${NC}"
    else
        echo -e "${RED}✗ RabbitMQ is not running${NC}"
        return 1
    fi
}

test_python_environments() {
    echo "Testing Python environments..."
    
    # Check uv installation
    if command -v uv &> /dev/null; then
        echo -e "${GREEN}✓ uv is installed${NC}"
    else
        echo -e "${RED}✗ uv is not installed${NC}"
        return 1
    fi
    
    # Check virtual environments
    for service in broker-gateway intelligent-core event-bus monitoring frontend; do
        if [ -d "/opt/stock-analysis/venvs/$service" ]; then
            echo -e "${GREEN}✓ Virtual environment for $service exists${NC}"
        else
            echo -e "${RED}✗ Virtual environment for $service missing${NC}"
            return 1
        fi
    done
}

# Run all tests
test_system_packages
test_python_environments
```

### Python Health Check Tests

```python
# test_health_checks.py
import requests
import sys

def test_service_health(port, service_name):
    """Test health endpoint for a service."""
    try:
        response = requests.get(f"http://localhost:{port}/health", timeout=5)
        if response.status_code == 200:
            print(f"✓ {service_name} health check passed")
            return True
        else:
            print(f"✗ {service_name} health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"✗ {service_name} health check error: {e}")
        return False

# Test all services
services = [
    (8001, "Broker Gateway"),
    (8002, "Intelligent Core"),
    (8003, "Event Bus"),
    (8004, "Monitoring"),
    (8005, "Frontend")
]

all_healthy = all(test_service_health(port, name) for port, name in services)
sys.exit(0 if all_healthy else 1)
```

## Mocking Requirements

### External Service Mocks
- **PostgreSQL:** Use test database or pg_tmp for isolation
- **Redis:** Use separate Redis instance or fakeredis for unit tests
- **RabbitMQ:** Use rabbitmq-test container or pika testing utilities

### Configuration Mocks
- **Environment Variables:** Use test-specific .env files
- **Service URLs:** Mock endpoints for health checks during setup
- **Credentials:** Use test credentials, never production

## Test Execution Strategy

1. **Infrastructure Setup Tests** - Run immediately after LXC creation
2. **Service Configuration Tests** - Run after systemd templates are installed
3. **Integration Tests** - Run after all services are configured
4. **Performance Tests** - Run after system is fully operational

## Success Criteria

- All system packages installed and running
- All virtual environments created with correct Python version
- All services respond to health checks
- Database queries complete in <0.2s
- Message delivery latency <5ms
- No failed tests in any category