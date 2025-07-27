#!/bin/bash
# Test script for LXC container setup validation
# Tests the native LXC infrastructure setup for stock-analysis ecosystem

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
EXPECTED_DEBIAN_VERSION="12"
EXPECTED_IP="10.1.1.120"
EXPECTED_HOSTNAME="stock-analysis"
BASE_DIR="/opt/stock-analysis"
TESTS_PASSED=0
TESTS_FAILED=0

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

# Test 1: Debian version check
test_debian_version() {
    log_test "Checking Debian version..."
    
    if [ -f /etc/debian_version ]; then
        debian_version=$(cat /etc/debian_version | cut -d'.' -f1)
        if [ "$debian_version" = "$EXPECTED_DEBIAN_VERSION" ]; then
            log_pass "Debian $EXPECTED_DEBIAN_VERSION detected"
        else
            log_fail "Expected Debian $EXPECTED_DEBIAN_VERSION, found $debian_version"
        fi
    else
        log_fail "Not a Debian system"
    fi
}

# Test 2: Network configuration
test_network_config() {
    log_test "Checking network configuration..."
    
    # Check IP address
    current_ip=$(ip addr show | grep "inet " | grep -v "127.0.0.1" | awk '{print $2}' | cut -d'/' -f1 | head -1)
    if [ "$current_ip" = "$EXPECTED_IP" ]; then
        log_pass "IP address correctly set to $EXPECTED_IP"
    else
        log_fail "Expected IP $EXPECTED_IP, found $current_ip"
    fi
    
    # Check hostname
    current_hostname=$(hostname)
    if [ "$current_hostname" = "$EXPECTED_HOSTNAME" ]; then
        log_pass "Hostname correctly set to $EXPECTED_HOSTNAME"
    else
        log_fail "Expected hostname $EXPECTED_HOSTNAME, found $current_hostname"
    fi
}

# Test 3: Required system packages
test_system_packages() {
    log_test "Checking required system packages..."
    
    # Core packages
    packages=(
        "curl"
        "git"
        "build-essential"
        "python3"
        "python3-pip"
        "python3-venv"
        "systemd"
        "sudo"
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log_pass "Package $package is installed"
        else
            log_fail "Package $package is missing"
        fi
    done
}

# Test 4: Python version
test_python_version() {
    log_test "Checking Python version..."
    
    if command -v python3 >/dev/null 2>&1; then
        python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        python_major=$(echo $python_version | cut -d'.' -f1)
        python_minor=$(echo $python_version | cut -d'.' -f2)
        
        if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
            log_pass "Python $python_version meets requirements (>= 3.11)"
        else
            log_fail "Python $python_version does not meet requirements (need >= 3.11)"
        fi
    else
        log_fail "Python 3 is not installed"
    fi
}

# Test 5: Database services
test_database_services() {
    log_test "Checking database services..."
    
    # PostgreSQL
    if dpkg -l | grep -q "postgresql-15"; then
        log_pass "PostgreSQL 15 is installed"
        if systemctl is-active --quiet postgresql; then
            log_pass "PostgreSQL service is running"
        else
            log_fail "PostgreSQL service is not running"
        fi
    else
        log_fail "PostgreSQL 15 is not installed"
    fi
    
    # Redis
    if dpkg -l | grep -q "redis-server"; then
        log_pass "Redis is installed"
        if systemctl is-active --quiet redis-server; then
            log_pass "Redis service is running"
        else
            log_fail "Redis service is not running"
        fi
    else
        log_fail "Redis is not installed"
    fi
    
    # RabbitMQ
    if dpkg -l | grep -q "rabbitmq-server"; then
        log_pass "RabbitMQ is installed"
        if systemctl is-active --quiet rabbitmq-server; then
            log_pass "RabbitMQ service is running"
        else
            log_fail "RabbitMQ service is not running"
        fi
    else
        log_fail "RabbitMQ is not installed"
    fi
}

# Test 6: Directory structure
test_directory_structure() {
    log_test "Checking directory structure..."
    
    directories=(
        "$BASE_DIR"
        "$BASE_DIR/venvs"
        "$BASE_DIR/scripts"
        "$BASE_DIR/config"
        "$BASE_DIR/logs"
        "$BASE_DIR/data"
        "/etc/stock-analysis"
    )
    
    for dir in "${directories[@]}"; do
        if [ -d "$dir" ]; then
            log_pass "Directory $dir exists"
            
            # Check permissions
            if [ -w "$dir" ]; then
                log_pass "Directory $dir is writable"
            else
                log_fail "Directory $dir is not writable"
            fi
        else
            log_fail "Directory $dir does not exist"
        fi
    done
}

# Test 7: User and permissions
test_user_permissions() {
    log_test "Checking user and permissions..."
    
    # Check if stock-analysis user exists
    if id "stock-analysis" &>/dev/null; then
        log_pass "User 'stock-analysis' exists"
        
        # Check ownership of base directory
        dir_owner=$(stat -c '%U' "$BASE_DIR" 2>/dev/null || echo "unknown")
        if [ "$dir_owner" = "stock-analysis" ]; then
            log_pass "Base directory owned by stock-analysis user"
        else
            log_fail "Base directory not owned by stock-analysis user (owned by $dir_owner)"
        fi
    else
        log_fail "User 'stock-analysis' does not exist"
    fi
}

# Test 8: systemd readiness
test_systemd_ready() {
    log_test "Checking systemd readiness..."
    
    if command -v systemctl >/dev/null 2>&1; then
        log_pass "systemctl is available"
        
        # Check if systemd is running
        if systemctl is-system-running &>/dev/null; then
            log_pass "systemd is running"
        else
            system_state=$(systemctl is-system-running 2>&1 || echo "unknown")
            if [ "$system_state" = "running" ] || [ "$system_state" = "degraded" ]; then
                log_pass "systemd is running (state: $system_state)"
            else
                log_fail "systemd is not properly running (state: $system_state)"
            fi
        fi
    else
        log_fail "systemctl is not available"
    fi
}

# Test 9: Python package manager (uv)
test_uv_installation() {
    log_test "Checking uv (Python package manager)..."
    
    if command -v uv >/dev/null 2>&1; then
        uv_version=$(uv --version 2>&1 | cut -d' ' -f2)
        log_pass "uv is installed (version: $uv_version)"
    else
        log_fail "uv is not installed"
    fi
}

# Test 10: Environment readiness
test_environment_ready() {
    log_test "Checking overall environment readiness..."
    
    # Check for environment file
    if [ -f "/etc/stock-analysis/environment" ]; then
        log_pass "Environment configuration file exists"
    else
        log_fail "Environment configuration file missing"
    fi
    
    # Check for setup completion marker
    if [ -f "$BASE_DIR/.setup-complete" ]; then
        log_pass "Setup completion marker found"
    else
        log_fail "Setup completion marker missing"
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Stock Analysis LXC Infrastructure Tests"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_debian_version
    test_network_config
    test_system_packages
    test_python_version
    test_database_services
    test_directory_structure
    test_user_permissions
    test_systemd_ready
    test_uv_installation
    test_environment_ready
    
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"