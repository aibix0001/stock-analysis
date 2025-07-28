#!/bin/bash
# Test script for LXC container setup
# Tests the LXC configuration and setup process

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0

# Test functions
log_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

log_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

log_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: Check if running in LXC container
test_lxc_environment() {
    log_test "Checking if running in LXC container"
    
    if [ -f /proc/1/environ ]; then
        if grep -q "container=lxc" /proc/1/environ 2>/dev/null || [ -f /run/systemd/container ]; then
            log_pass "Running in LXC container"
        else
            log_fail "Not running in LXC container"
        fi
    else
        log_fail "Cannot determine container environment"
    fi
}

# Test 2: Verify Debian version
test_debian_version() {
    log_test "Checking Debian version"
    
    if [ -f /etc/debian_version ]; then
        version=$(cat /etc/debian_version)
        if [[ "$version" =~ ^12\. ]]; then
            log_pass "Debian 12 (Bookworm) detected: $version"
        else
            log_fail "Expected Debian 12, got: $version"
        fi
    else
        log_fail "Cannot determine Debian version"
    fi
}

# Test 3: Network configuration
test_network_config() {
    log_test "Checking network configuration"
    
    # Check if IP is configured via DHCP
    ip_addr=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
    if [ -n "$ip_addr" ]; then
        log_pass "IP address assigned via DHCP: $ip_addr"
    else
        log_fail "No IP address assigned via DHCP"
    fi
    
    # Check if we have a default gateway
    gateway=$(ip route | grep default | awk '{print $3}')
    if [ -n "$gateway" ]; then
        log_pass "Default gateway configured: $gateway"
    else
        log_fail "No default gateway configured"
    fi
    
    # Check hostname
    if [ "$(hostname)" = "stock-analysis" ]; then
        log_pass "Hostname correctly set to stock-analysis"
    else
        log_fail "Expected hostname 'stock-analysis', got '$(hostname)'"
    fi
}

# Test 4: System resources
test_system_resources() {
    log_test "Checking system resources"
    
    # Check CPU count
    cpu_count=$(nproc)
    if [ "$cpu_count" -ge 4 ]; then
        log_pass "CPU count adequate: $cpu_count cores"
    else
        log_fail "Expected at least 4 CPUs, got: $cpu_count"
    fi
    
    # Check memory
    mem_gb=$(awk '/MemTotal/ {printf "%.1f", $2/1024/1024}' /proc/meminfo)
    if (( $(echo "$mem_gb >= 7.5" | bc -l) )); then
        log_pass "Memory adequate: ${mem_gb}GB"
    else
        log_fail "Expected at least 8GB RAM, got: ${mem_gb}GB"
    fi
    
    # Check disk space
    disk_gb=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [ "$disk_gb" -ge 20 ]; then
        log_pass "Disk space adequate: ${disk_gb}GB available"
    else
        log_fail "Expected at least 20GB free space, got: ${disk_gb}GB"
    fi
}

# Test 5: Required system packages
test_system_packages() {
    log_test "Checking required system packages"
    
    packages=(
        "python3"
        "python3-venv"
        "python3-pip"
        "postgresql"
        "redis-server"
        "rabbitmq-server"
        "systemd"
        "curl"
        "git"
        "build-essential"
        "libpq-dev"
    )
    
    for pkg in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $pkg"; then
            log_pass "Package installed: $pkg"
        else
            log_fail "Package missing: $pkg"
        fi
    done
}

# Test 6: Directory structure
test_directory_structure() {
    log_test "Checking directory structure"
    
    dirs=(
        "/opt/stock-analysis"
        "/opt/stock-analysis/venvs"
        "/opt/stock-analysis/services"
        "/opt/stock-analysis/config"
        "/opt/stock-analysis/logs"
        "/opt/stock-analysis/data"
        "/etc/stock-analysis"
    )
    
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            log_pass "Directory exists: $dir"
        else
            log_fail "Directory missing: $dir"
        fi
    done
}

# Test 7: PostgreSQL setup
test_postgresql_setup() {
    log_test "Checking PostgreSQL setup"
    
    # Check if PostgreSQL is running
    if systemctl is-active --quiet postgresql; then
        log_pass "PostgreSQL service is running"
    else
        log_fail "PostgreSQL service is not running"
        return
    fi
    
    # Check database existence
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw stock_analysis_event_store; then
        log_pass "Database 'stock_analysis_event_store' exists"
    else
        log_fail "Database 'stock_analysis_event_store' missing"
    fi
    
    # Check user existence
    if sudo -u postgres psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='stock_analysis_user'" | grep -q 1; then
        log_pass "PostgreSQL user 'stock_analysis_user' exists"
    else
        log_fail "PostgreSQL user 'stock_analysis_user' missing"
    fi
}

# Test 8: Redis setup
test_redis_setup() {
    log_test "Checking Redis setup"
    
    # Check Redis instances
    for port in 6379 6380 6381; do
        if nc -z localhost $port 2>/dev/null; then
            log_pass "Redis instance running on port $port"
        else
            log_fail "Redis instance not running on port $port"
        fi
    done
    
    # Check cluster configuration
    if [ -f /etc/redis/redis-6379.conf ] && grep -q "cluster-enabled yes" /etc/redis/redis-6379.conf; then
        log_pass "Redis cluster configuration found"
    else
        log_fail "Redis cluster configuration missing"
    fi
}

# Test 9: RabbitMQ setup
test_rabbitmq_setup() {
    log_test "Checking RabbitMQ setup"
    
    # Check if RabbitMQ is running
    if systemctl is-active --quiet rabbitmq-server; then
        log_pass "RabbitMQ service is running"
    else
        log_fail "RabbitMQ service is not running"
        return
    fi
    
    # Check management plugin
    if sudo rabbitmq-plugins list | grep -q "\[E\] rabbitmq_management"; then
        log_pass "RabbitMQ management plugin enabled"
    else
        log_fail "RabbitMQ management plugin not enabled"
    fi
    
    # Check virtual host
    if sudo rabbitmqctl list_vhosts | grep -q "/stock-analysis"; then
        log_pass "RabbitMQ virtual host '/stock-analysis' exists"
    else
        log_fail "RabbitMQ virtual host '/stock-analysis' missing"
    fi
}

# Test 10: Python and uv setup
test_python_setup() {
    log_test "Checking Python and uv setup"
    
    # Check Python version
    python_version=$(python3 --version | cut -d' ' -f2)
    if [[ "$python_version" =~ ^3\.1[1-9] ]]; then
        log_pass "Python version adequate: $python_version"
    else
        log_fail "Expected Python 3.11+, got: $python_version"
    fi
    
    # Check uv installation
    if command -v uv &> /dev/null; then
        uv_version=$(uv --version 2>/dev/null || echo "unknown")
        log_pass "uv is installed: $uv_version"
    else
        log_fail "uv is not installed"
    fi
}

# Test 11: Systemd service templates
test_systemd_templates() {
    log_test "Checking systemd service templates"
    
    services=(
        "stock-analysis-broker-gateway"
        "stock-analysis-intelligent-core"
        "stock-analysis-event-bus"
        "stock-analysis-monitoring"
        "stock-analysis-frontend"
    )
    
    for service in "${services[@]}"; do
        if [ -f "/etc/systemd/system/${service}.service" ]; then
            log_pass "Systemd service file exists: ${service}.service"
        else
            log_fail "Systemd service file missing: ${service}.service"
        fi
    done
}

# Test 12: Service environment files
test_environment_files() {
    log_test "Checking service environment files"
    
    env_files=(
        "broker-gateway.env"
        "intelligent-core.env"
        "event-bus.env"
        "monitoring.env"
        "frontend.env"
        "common.env"
    )
    
    for env_file in "${env_files[@]}"; do
        if [ -f "/etc/stock-analysis/${env_file}" ]; then
            log_pass "Environment file exists: ${env_file}"
        else
            log_fail "Environment file missing: ${env_file}"
        fi
    done
}

# Main test execution
main() {
    echo "========================================="
    echo "LXC Container Setup Test Suite"
    echo "========================================="
    echo
    
    # Run all tests
    test_lxc_environment
    test_debian_version
    test_network_config
    test_system_resources
    test_system_packages
    test_directory_structure
    test_postgresql_setup
    test_redis_setup
    test_rabbitmq_setup
    test_python_setup
    test_systemd_templates
    test_environment_files
    
    echo
    echo "========================================="
    echo "Test Summary"
    echo "========================================="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Allow sourcing for individual test functions
if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    main "$@"
fi