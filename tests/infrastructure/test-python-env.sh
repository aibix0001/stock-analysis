#!/bin/bash
# Test script for Python environment and package management
# Validates Python 3.11+, uv, and virtual environments

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test configuration
PYTHON_MIN_VERSION="3.11"
BASE_DIR="/opt/stock-analysis"
VENV_DIR="$BASE_DIR/venvs"
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

# Test 1: Python version
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

# Test 2: Python development packages
test_python_dev_packages() {
    log_test "Checking Python development packages..."
    
    packages=(
        "python3-pip"
        "python3-venv"
        "python3-dev"
        "python3-setuptools"
        "python3-wheel"
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii.*$package"; then
            log_pass "Package $package is installed"
        else
            log_fail "Package $package is missing"
        fi
    done
    
    # Check if pip works
    if python3 -m pip --version >/dev/null 2>&1; then
        pip_version=$(python3 -m pip --version | awk '{print $2}')
        log_pass "pip $pip_version is functional"
    else
        log_fail "pip is not functional"
    fi
}

# Test 3: uv installation
test_uv_installation() {
    log_test "Checking uv package manager..."
    
    # Check if uv is in PATH
    if command -v uv >/dev/null 2>&1; then
        uv_version=$(uv --version 2>&1 | cut -d' ' -f2)
        log_pass "uv $uv_version is installed and in PATH"
        
        # Check uv functionality
        if uv pip --version >/dev/null 2>&1; then
            log_pass "uv pip command is functional"
        else
            log_fail "uv pip command is not functional"
        fi
    else
        # Check common installation paths
        if [ -f "$HOME/.cargo/bin/uv" ]; then
            log_fail "uv is installed but not in PATH (found in ~/.cargo/bin/)"
        elif [ -f "/root/.cargo/bin/uv" ]; then
            log_fail "uv is installed but not in PATH (found in /root/.cargo/bin/)"
        else
            log_fail "uv is not installed"
        fi
    fi
}

# Test 4: Virtual environment directory
test_venv_directory() {
    log_test "Checking virtual environment directory..."
    
    if [ -d "$VENV_DIR" ]; then
        log_pass "Virtual environment directory exists: $VENV_DIR"
        
        # Check permissions
        if [ -w "$VENV_DIR" ]; then
            log_pass "Virtual environment directory is writable"
        else
            log_fail "Virtual environment directory is not writable"
        fi
        
        # Check ownership
        dir_owner=$(stat -c '%U' "$VENV_DIR" 2>/dev/null || echo "unknown")
        if [ "$dir_owner" = "stock-analysis" ]; then
            log_pass "Virtual environment directory owned by stock-analysis user"
        else
            log_fail "Virtual environment directory not owned by stock-analysis (owned by $dir_owner)"
        fi
    else
        log_fail "Virtual environment directory does not exist: $VENV_DIR"
    fi
}

# Test 5: Service virtual environments
test_service_venvs() {
    log_test "Checking service virtual environments..."
    
    for service in "${SERVICES[@]}"; do
        venv_path="$VENV_DIR/$service"
        
        if [ -d "$venv_path" ]; then
            log_pass "Virtual environment exists for $service"
            
            # Check if it's a valid venv
            if [ -f "$venv_path/bin/python" ] && [ -f "$venv_path/bin/activate" ]; then
                log_pass "Virtual environment for $service is valid"
                
                # Check Python version in venv
                venv_python_version=$("$venv_path/bin/python" --version 2>&1 | cut -d' ' -f2)
                log_pass "$service venv uses Python $venv_python_version"
            else
                log_fail "Virtual environment for $service is invalid or corrupted"
            fi
        else
            log_fail "Virtual environment missing for $service"
        fi
    done
}

# Test 6: Requirements files
test_requirements_files() {
    log_test "Checking requirements.txt templates..."
    
    for service in "${SERVICES[@]}"; do
        req_file="$BASE_DIR/services/$service/requirements.txt"
        
        if [ -f "$req_file" ]; then
            log_pass "requirements.txt exists for $service"
            
            # Check if file is not empty
            if [ -s "$req_file" ]; then
                line_count=$(wc -l < "$req_file")
                log_pass "$service requirements.txt has $line_count dependencies"
            else
                log_fail "$service requirements.txt is empty"
            fi
        else
            log_fail "requirements.txt missing for $service"
        fi
    done
}

# Test 7: Python package installation in venvs
test_venv_packages() {
    log_test "Checking installed packages in virtual environments..."
    
    for service in "${SERVICES[@]}"; do
        venv_path="$VENV_DIR/$service"
        
        if [ -d "$venv_path" ] && [ -f "$venv_path/bin/pip" ]; then
            # Check for core packages
            core_packages=("pip" "setuptools" "wheel")
            
            for package in "${core_packages[@]}"; do
                if "$venv_path/bin/pip" show "$package" >/dev/null 2>&1; then
                    version=$("$venv_path/bin/pip" show "$package" | grep Version | awk '{print $2}')
                    log_pass "$service has $package==$version"
                else
                    log_fail "$service missing core package: $package"
                fi
            done
            
            # Check if service-specific packages are installed
            if [ -f "$BASE_DIR/services/$service/requirements.txt" ]; then
                # Check if any packages from requirements are installed
                installed_count=$("$venv_path/bin/pip" list --format=freeze | wc -l)
                if [ "$installed_count" -gt 3 ]; then
                    log_pass "$service has $installed_count packages installed"
                else
                    log_fail "$service has only core packages installed"
                fi
            fi
        else
            log_fail "Cannot check packages for $service (no valid venv)"
        fi
    done
}

# Test 8: uv configuration
test_uv_config() {
    log_test "Checking uv configuration..."
    
    # Check if uv is configured for the project
    if [ -f "$BASE_DIR/.python-version" ]; then
        python_version=$(cat "$BASE_DIR/.python-version")
        log_pass "Python version pinned: $python_version"
    else
        log_fail "No .python-version file found"
    fi
    
    # Check for uv.toml or pyproject.toml
    if [ -f "$BASE_DIR/uv.toml" ]; then
        log_pass "uv.toml configuration found"
    elif [ -f "$BASE_DIR/pyproject.toml" ]; then
        log_pass "pyproject.toml found"
    else
        log_fail "No uv configuration file found"
    fi
}

# Test 9: Environment activation scripts
test_activation_scripts() {
    log_test "Checking environment activation scripts..."
    
    # Check for activation helper script
    activate_script="$BASE_DIR/scripts/activate-service.sh"
    if [ -f "$activate_script" ]; then
        log_pass "Service activation helper script exists"
        
        if [ -x "$activate_script" ]; then
            log_pass "Activation script is executable"
        else
            log_fail "Activation script is not executable"
        fi
    else
        log_fail "Service activation helper script missing"
    fi
    
    # Check for environment sourcing in systemd templates
    if grep -q "Environment=\"PATH=" /etc/stock-analysis/python-service.template 2>/dev/null; then
        log_pass "systemd template includes virtual environment PATH"
    else
        log_fail "systemd template missing virtual environment PATH configuration"
    fi
}

# Test 10: Python compilation dependencies
test_compilation_deps() {
    log_test "Checking Python compilation dependencies..."
    
    compile_deps=(
        "build-essential"
        "libpython3-dev"
        "libffi-dev"
        "libssl-dev"
        "libpq-dev"  # For psycopg2
        "libyaml-dev"  # For PyYAML
    )
    
    for dep in "${compile_deps[@]}"; do
        if dpkg -l | grep -q "^ii.*$dep"; then
            log_pass "Compilation dependency $dep is installed"
        else
            log_fail "Compilation dependency $dep is missing"
        fi
    done
}

# Main test execution
main() {
    echo "=========================================="
    echo "Python Environment and Package Tests"
    echo "=========================================="
    echo ""
    
    # Run all tests
    test_python_version
    test_python_dev_packages
    test_uv_installation
    test_venv_directory
    test_service_venvs
    test_requirements_files
    test_venv_packages
    test_uv_config
    test_activation_scripts
    test_compilation_deps
    
    echo ""
    echo "=========================================="
    echo "Test Summary"
    echo "=========================================="
    echo -e "${GREEN}Passed:${NC} $TESTS_PASSED"
    echo -e "${RED}Failed:${NC} $TESTS_FAILED"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        echo -e "${GREEN}All Python environment tests passed!${NC}"
        exit 0
    else
        echo -e "${RED}Some Python environment tests failed!${NC}"
        exit 1
    fi
}

# Run main function
main "$@"