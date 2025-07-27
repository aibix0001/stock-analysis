#!/bin/bash
# Test script for database infrastructure
# Validates PostgreSQL 15+, Redis cluster, and event store setup

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
POSTGRES_VERSION="15"
POSTGRES_DB="aktienanalyse_event_store"
POSTGRES_USER="stock_analysis"
REDIS_NODES=3
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

# Test 1: PostgreSQL installation
test_postgresql_installation() {
    log_test "Checking PostgreSQL installation..."
    
    # Check if PostgreSQL is installed
    if command -v psql >/dev/null 2>&1; then
        pg_version=$(psql --version | awk '{print $3}' | cut -d'.' -f1)
        if [ "$pg_version" -ge "$POSTGRES_VERSION" ]; then
            log_pass "PostgreSQL $pg_version installed (>= $POSTGRES_VERSION required)"
        else
            log_fail "PostgreSQL $pg_version does not meet requirements (need >= $POSTGRES_VERSION)"
        fi
    else
        log_fail "PostgreSQL is not installed"
    fi
    
    # Check PostgreSQL service
    if systemctl is-active --quiet postgresql; then
        log_pass "PostgreSQL service is running"
    else
        log_fail "PostgreSQL service is not running"
    fi
    
    # Check PostgreSQL cluster
    if pg_lsclusters >/dev/null 2>&1; then
        cluster_info=$(pg_lsclusters -h | grep -E "^$POSTGRES_VERSION")
        if [ -n "$cluster_info" ]; then
            log_pass "PostgreSQL $POSTGRES_VERSION cluster exists"
        else
            log_fail "PostgreSQL $POSTGRES_VERSION cluster not found"
        fi
    fi
}

# Test 2: PostgreSQL configuration
test_postgresql_config() {
    log_test "Checking PostgreSQL configuration..."
    
    # Check if we can connect locally
    if sudo -u postgres psql -c "SELECT 1;" >/dev/null 2>&1; then
        log_pass "Can connect to PostgreSQL as postgres user"
    else
        log_fail "Cannot connect to PostgreSQL as postgres user"
    fi
    
    # Check listen addresses
    pg_config="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    if [ -f "$pg_config" ]; then
        if grep -q "^listen_addresses = '\*'" "$pg_config" || grep -q "^listen_addresses = 'localhost" "$pg_config"; then
            log_pass "PostgreSQL listen_addresses configured"
        else
            log_fail "PostgreSQL listen_addresses not properly configured"
        fi
    else
        log_fail "PostgreSQL configuration file not found"
    fi
    
    # Check pg_hba.conf
    pg_hba="/etc/postgresql/$POSTGRES_VERSION/main/pg_hba.conf"
    if [ -f "$pg_hba" ]; then
        if grep -q "host.*stock_analysis" "$pg_hba"; then
            log_pass "PostgreSQL authentication configured for stock_analysis user"
        else
            log_fail "PostgreSQL authentication not configured for stock_analysis user"
        fi
    fi
}

# Test 3: Event store database
test_event_store_database() {
    log_test "Checking event store database..."
    
    # Check if database exists
    if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw "$POSTGRES_DB"; then
        log_pass "Database '$POSTGRES_DB' exists"
        
        # Check if user exists
        if sudo -u postgres psql -c "\du" | grep -q "$POSTGRES_USER"; then
            log_pass "User '$POSTGRES_USER' exists"
        else
            log_fail "User '$POSTGRES_USER' does not exist"
        fi
        
        # Check user permissions
        if sudo -u postgres psql -d "$POSTGRES_DB" -c "\dp" >/dev/null 2>&1; then
            log_pass "Can query database permissions"
        else
            log_fail "Cannot query database permissions"
        fi
    else
        log_fail "Database '$POSTGRES_DB' does not exist"
    fi
}

# Test 4: Event store schema
test_event_store_schema() {
    log_test "Checking event store schema..."
    
    # Check for events table
    if sudo -u postgres psql -d "$POSTGRES_DB" -c "\dt events" 2>/dev/null | grep -q "events"; then
        log_pass "Event store 'events' table exists"
        
        # Check table structure
        columns=$(sudo -u postgres psql -d "$POSTGRES_DB" -c "\d events" 2>/dev/null | grep -E "id|stream_id|event_type|event_data" | wc -l)
        if [ "$columns" -ge 4 ]; then
            log_pass "Event store table has required columns"
        else
            log_fail "Event store table missing required columns"
        fi
    else
        log_fail "Event store 'events' table does not exist"
    fi
    
    # Check for materialized views
    views=("stock_analysis_unified" "portfolio_unified" "trading_activity_unified" "system_health_unified")
    for view in "${views[@]}"; do
        if sudo -u postgres psql -d "$POSTGRES_DB" -c "\dm $view" 2>/dev/null | grep -q "$view"; then
            log_pass "Materialized view '$view' exists"
        else
            log_fail "Materialized view '$view' does not exist"
        fi
    done
}

# Test 5: Redis installation
test_redis_installation() {
    log_test "Checking Redis installation..."
    
    # Check if Redis is installed
    if command -v redis-server >/dev/null 2>&1; then
        redis_version=$(redis-server --version | grep -o 'v=[0-9.]*' | cut -d'=' -f2)
        log_pass "Redis $redis_version is installed"
    else
        log_fail "Redis is not installed"
    fi
    
    # Check Redis service
    if systemctl is-active --quiet redis-server; then
        log_pass "Redis service is running"
    else
        log_fail "Redis service is not running"
    fi
    
    # Check Redis connectivity
    if redis-cli ping >/dev/null 2>&1; then
        log_pass "Redis is responding to ping"
    else
        log_fail "Redis is not responding"
    fi
}

# Test 6: Redis configuration
test_redis_config() {
    log_test "Checking Redis configuration..."
    
    redis_config="/etc/redis/redis.conf"
    if [ -f "$redis_config" ]; then
        # Check bind address
        if grep -q "^bind 127.0.0.1" "$redis_config"; then
            log_pass "Redis bind address configured"
        else
            log_fail "Redis bind address not properly configured"
        fi
        
        # Check persistence
        if grep -q "^appendonly yes" "$redis_config"; then
            log_pass "Redis AOF persistence enabled"
        else
            log_fail "Redis AOF persistence not enabled"
        fi
        
        # Check maxmemory
        if grep -q "^maxmemory" "$redis_config"; then
            log_pass "Redis maxmemory configured"
        else
            log_fail "Redis maxmemory not configured"
        fi
    else
        log_fail "Redis configuration file not found"
    fi
}

# Test 7: Redis cluster readiness
test_redis_cluster() {
    log_test "Checking Redis cluster configuration..."
    
    # Check for cluster config in main Redis
    if grep -q "^# cluster-enabled yes" "/etc/redis/redis.conf" 2>/dev/null; then
        log_pass "Redis cluster configuration present (commented out for single node)"
    else
        log_fail "Redis cluster configuration missing"
    fi
    
    # Check for additional Redis instances (for cluster)
    redis_instances=$(ps aux | grep -E "redis-server.*:63[78][0-9]" | grep -v grep | wc -l)
    if [ "$redis_instances" -eq 0 ]; then
        log_pass "Single Redis instance (cluster not yet enabled)"
    elif [ "$redis_instances" -ge 2 ]; then
        log_pass "Multiple Redis instances found for clustering"
    else
        log_fail "Incomplete Redis cluster setup"
    fi
}

# Test 8: Database initialization scripts
test_init_scripts() {
    log_test "Checking database initialization scripts..."
    
    # Check for event store schema SQL
    if [ -f "shared/database/event-store-schema.sql" ]; then
        log_pass "Event store schema SQL file exists"
        
        # Check if it contains required objects
        if grep -q "CREATE TABLE.*events" "shared/database/event-store-schema.sql"; then
            log_pass "Schema SQL contains events table definition"
        else
            log_fail "Schema SQL missing events table definition"
        fi
    else
        log_fail "Event store schema SQL file not found"
    fi
    
    # Check for initialization script
    if [ -f "scripts/init-databases.sh" ]; then
        log_pass "Database initialization script exists"
        
        if [ -x "scripts/init-databases.sh" ]; then
            log_pass "Database initialization script is executable"
        else
            log_fail "Database initialization script is not executable"
        fi
    else
        log_fail "Database initialization script not found"
    fi
}

# Test 9: Connection testing
test_database_connections() {
    log_test "Testing database connections..."
    
    # Test PostgreSQL connection with stock_analysis user
    export PGPASSWORD="${POSTGRES_PASSWORD:-secure_password}"
    if psql -h localhost -U "$POSTGRES_USER" -d "$POSTGRES_DB" -c "SELECT 1;" >/dev/null 2>&1; then
        log_pass "Can connect to PostgreSQL as $POSTGRES_USER"
    else
        log_fail "Cannot connect to PostgreSQL as $POSTGRES_USER"
    fi
    unset PGPASSWORD
    
    # Test Redis connection with authentication (if configured)
    if redis-cli -h localhost INFO server >/dev/null 2>&1; then
        log_pass "Can connect to Redis"
    else
        log_fail "Cannot connect to Redis"
    fi
}

# Test 10: Performance settings
test_performance_settings() {
    log_test "Checking database performance settings..."
    
    # PostgreSQL performance settings
    pg_config="/etc/postgresql/$POSTGRES_VERSION/main/postgresql.conf"
    if [ -f "$pg_config" ]; then
        settings=("shared_buffers" "effective_cache_size" "work_mem" "maintenance_work_mem")
        for setting in "${settings[@]}"; do
            if grep -q "^$setting" "$pg_config"; then
                value=$(grep "^$setting" "$pg_config" | awk '{print $3}')
                log_pass "PostgreSQL $setting configured: $value"
            else
                log_fail "PostgreSQL $setting not configured"
            fi
        done
    fi
    
    # Redis performance settings
    redis_config="/etc/redis/redis.conf"
    if [ -f "$redis_config" ]; then
        if grep -q "^maxmemory-policy" "$redis_config"; then
            policy=$(grep "^maxmemory-policy" "$redis_config" | awk '{print $2}')
            log_pass "Redis eviction policy configured: $policy"
        else
            log_fail "Redis eviction policy not configured"
        fi
    fi
}

# Main test execution
main() {
    echo "=========================================="
    echo "Database Infrastructure Tests"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_postgresql_installation
    test_postgresql_config
    test_event_store_database
    test_event_store_schema
    test_redis_installation
    test_redis_config
    test_redis_cluster
    test_init_scripts
    test_database_connections
    test_performance_settings
    
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All database tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some database tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"