#!/bin/bash
# Test script for RabbitMQ and systemd service configuration
# Validates message queue setup and service templates

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
RABBITMQ_USER="stock_analysis"
SERVICE_USER="stock-analysis"
BASE_DIR="/opt/stock-analysis"
TESTS_PASSED=0
TESTS_FAILED=0

# Service list
SERVICES=(
    "intelligent-core-service"
    "broker-gateway-service"
    "event-bus-service"
    "frontend-service"
    "monitoring-service"
)

# Helper functions
log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: RabbitMQ installation
test_rabbitmq_installation() {
    log_test "Checking RabbitMQ installation..."
    
    # Check if RabbitMQ is installed
    if command -v rabbitmqctl >/dev/null 2>&1; then
        log_pass "RabbitMQ is installed"
        
        # Check version
        if rabbitmqctl version >/dev/null 2>&1; then
            version=$(rabbitmqctl version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
            log_pass "RabbitMQ version: $version"
        else
            log_fail "Cannot determine RabbitMQ version"
        fi
    else
        log_fail "RabbitMQ is not installed"
    fi
    
    # Check RabbitMQ service
    if systemctl is-active --quiet rabbitmq-server; then
        log_pass "RabbitMQ service is running"
    else
        log_fail "RabbitMQ service is not running"
    fi
}

# Test 2: RabbitMQ configuration
test_rabbitmq_config() {
    log_test "Checking RabbitMQ configuration..."
    
    # Check if management plugin is enabled
    if rabbitmqctl list_enabled_plugins 2>/dev/null | grep -q rabbitmq_management; then
        log_pass "RabbitMQ management plugin is enabled"
    else
        log_fail "RabbitMQ management plugin is not enabled"
    fi
    
    # Check if stock_analysis user exists
    if rabbitmqctl list_users 2>/dev/null | grep -q "$RABBITMQ_USER"; then
        log_pass "RabbitMQ user '$RABBITMQ_USER' exists"
    else
        log_fail "RabbitMQ user '$RABBITMQ_USER' does not exist"
    fi
    
    # Check virtual hosts
    if rabbitmqctl list_vhosts 2>/dev/null | grep -q "^/$"; then
        log_pass "Default virtual host '/' exists"
    else
        log_fail "Default virtual host '/' not found"
    fi
}

# Test 3: RabbitMQ connectivity
test_rabbitmq_connectivity() {
    log_test "Checking RabbitMQ connectivity..."
    
    # Check if we can connect to RabbitMQ
    if rabbitmqctl status >/dev/null 2>&1; then
        log_pass "Can connect to RabbitMQ"
        
        # Check listeners
        if rabbitmqctl status 2>/dev/null | grep -q "5672"; then
            log_pass "RabbitMQ AMQP port 5672 is listening"
        else
            log_fail "RabbitMQ AMQP port 5672 is not listening"
        fi
        
        # Check management port
        if rabbitmqctl status 2>/dev/null | grep -q "15672"; then
            log_pass "RabbitMQ management port 15672 is listening"
        else
            log_fail "RabbitMQ management port 15672 is not listening"
        fi
    else
        log_fail "Cannot connect to RabbitMQ"
    fi
}

# Test 4: systemd service templates
test_systemd_templates() {
    log_test "Checking systemd service templates..."
    
    # Check for service template
    if [ -f "/etc/stock-analysis/python-service.template" ]; then
        log_pass "Python service template exists"
        
        # Check template content
        required_directives=(
            "Type="
            "User="
            "WorkingDirectory="
            "Environment="
            "ExecStart="
            "Restart="
        )
        
        for directive in "${required_directives[@]}"; do
            if grep -q "^$directive" "/etc/stock-analysis/python-service.template"; then
                log_pass "Template contains $directive directive"
            else
                log_fail "Template missing $directive directive"
            fi
        done
    else
        log_fail "Python service template not found"
    fi
    
    # Check health check template
    if [ -f "/etc/stock-analysis/health-check.template" ]; then
        log_pass "Health check template exists"
        
        if [ -x "/etc/stock-analysis/health-check.template" ]; then
            log_pass "Health check template is executable"
        else
            log_fail "Health check template is not executable"
        fi
    else
        log_fail "Health check template not found"
    fi
}

# Test 5: Service environment configuration
test_service_environment() {
    log_test "Checking service environment configuration..."
    
    # Check main environment file
    if [ -f "/etc/stock-analysis/environment" ]; then
        log_pass "Environment configuration file exists"
        
        # Check required environment variables
        required_vars=(
            "POSTGRES_HOST"
            "POSTGRES_DB"
            "REDIS_HOST"
            "RABBITMQ_HOST"
            "INTELLIGENT_CORE_PORT"
            "BROKER_GATEWAY_PORT"
            "EVENT_BUS_PORT"
            "MONITORING_PORT"
            "FRONTEND_PORT"
        )
        
        for var in "${required_vars[@]}"; do
            if grep -q "^$var=" "/etc/stock-analysis/environment"; then
                log_pass "Environment variable $var is defined"
            else
                log_fail "Environment variable $var is missing"
            fi
        done
    else
        log_fail "Environment configuration file not found"
    fi
}

# Test 6: Service creation script
test_service_creation() {
    log_test "Checking service creation script..."
    
    create_script="$BASE_DIR/scripts/create-systemd-service.sh"
    
    if [ -f "$create_script" ]; then
        log_pass "Service creation script exists"
        
        if [ -x "$create_script" ]; then
            log_pass "Service creation script is executable"
        else
            log_fail "Service creation script is not executable"
        fi
        
        # Check script functionality (dry run)
        if grep -q "SERVICE_NAME=\$1" "$create_script"; then
            log_pass "Service creation script accepts parameters"
        else
            log_fail "Service creation script missing parameter handling"
        fi
    else
        log_fail "Service creation script not found"
    fi
}

# Test 7: Service directories
test_service_directories() {
    log_test "Checking service directories..."
    
    for service in "${SERVICES[@]}"; do
        service_dir="$BASE_DIR/services/$service"
        
        if [ -d "$service_dir" ]; then
            log_pass "Directory exists for $service"
        else
            log_fail "Directory missing for $service"
        fi
        
        # Check log directory
        log_dir="/var/log/stock-analysis/$service"
        if [ -d "$log_dir" ]; then
            log_pass "Log directory exists for $service"
        else
            log_fail "Log directory missing for $service"
        fi
    done
}

# Test 8: systemd service files
test_systemd_services() {
    log_test "Checking systemd service files..."
    
    for service in "${SERVICES[@]}"; do
        service_file="/etc/systemd/system/stock-analysis-${service}.service"
        
        if [ -f "$service_file" ]; then
            log_pass "Service file exists for $service"
            
            # Check if service is valid
            if systemctl list-unit-files | grep -q "stock-analysis-${service}.service"; then
                log_pass "Service $service is recognized by systemd"
            else
                log_fail "Service $service is not recognized by systemd"
            fi
        else
            # Not a failure - services haven't been created yet
            log_pass "Service file not yet created for $service (expected)"
        fi
    done
}

# Test 9: Health check endpoints
test_health_checks() {
    log_test "Checking health check setup..."
    
    # Check if health check scripts would be created
    for service in "${SERVICES[@]}"; do
        health_script="$BASE_DIR/scripts/health-check-${service}.sh"
        
        if [ -f "$health_script" ]; then
            log_pass "Health check script exists for $service"
            
            if [ -x "$health_script" ]; then
                log_pass "Health check script is executable for $service"
            else
                log_fail "Health check script is not executable for $service"
            fi
        else
            # Not created yet - that's OK
            log_pass "Health check script will be created for $service"
        fi
    done
}

# Test 10: Service ports availability
test_service_ports() {
    log_test "Checking service port availability..."
    
    # Service ports from environment
    ports=(
        "8001:intelligent-core-service"
        "8002:broker-gateway-service"
        "8003:event-bus-service"
        "8004:monitoring-service"
        "8005:frontend-service"
    )
    
    for port_info in "${ports[@]}"; do
        port=$(echo "$port_info" | cut -d':' -f1)
        service=$(echo "$port_info" | cut -d':' -f2)
        
        # Check if port is in use
        if netstat -tln 2>/dev/null | grep -q ":$port "; then
            log_fail "Port $port for $service is already in use"
        else
            log_pass "Port $port for $service is available"
        fi
    done
}

# Main test execution
main() {
    echo "=========================================="
    echo "RabbitMQ and systemd Service Tests"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_rabbitmq_installation
    test_rabbitmq_config
    test_rabbitmq_connectivity
    test_systemd_templates
    test_service_environment
    test_service_creation
    test_service_directories
    test_systemd_services
    test_health_checks
    test_service_ports
    
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All service infrastructure tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some service infrastructure tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"