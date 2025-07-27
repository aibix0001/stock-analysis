#!/bin/bash
# Install packages in all service virtual environments
# Uses uv for fast parallel installation

set -euo pipefail

# Configuration
BASE_DIR="/opt/stock-analysis"
VENV_DIR="$BASE_DIR/venvs"
SERVICE_USER="stock-analysis"

# Service list
SERVICES=(
    "intelligent-core-service"
    "broker-gateway-service"
    "event-bus-service"
    "frontend-service"
    "monitoring-service"
)

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Install packages for a service
install_service_packages() {
    local service=$1
    local venv_path="$VENV_DIR/$service"
    local req_file="$BASE_DIR/services/$service/requirements.txt"
    
    echo ""
    log "Installing packages for $service..."
    
    # Check if virtual environment exists
    if [ ! -d "$venv_path" ]; then
        error "Virtual environment not found for $service"
        return 1
    fi
    
    # Check if requirements.txt exists
    if [ ! -f "$req_file" ]; then
        warning "No requirements.txt found for $service"
        return 1
    fi
    
    # Count packages
    package_count=$(grep -v '^#' "$req_file" | grep -v '^$' | wc -l)
    info "Installing $package_count packages for $service"
    
    # Change to service directory
    cd "$BASE_DIR/services/$service"
    
    # Try to use uv first, fall back to pip
    if [ -f "$venv_path/bin/uv" ] && command -v uv >/dev/null 2>&1; then
        info "Using uv for fast installation..."
        
        # Use uv with the virtual environment
        UV_PYTHON="$venv_path/bin/python" uv pip install -r requirements.txt --python "$venv_path/bin/python"
        
        if [ $? -eq 0 ]; then
            log "✅ Successfully installed packages for $service with uv"
        else
            error "❌ Failed to install packages for $service with uv"
            return 1
        fi
    else
        info "Using pip for installation..."
        
        # Use standard pip
        "$venv_path/bin/pip" install -r requirements.txt
        
        if [ $? -eq 0 ]; then
            log "✅ Successfully installed packages for $service with pip"
        else
            error "❌ Failed to install packages for $service with pip"
            return 1
        fi
    fi
    
    # Show installed package count
    installed_count=$("$venv_path/bin/pip" list --format=freeze | wc -l)
    info "$service now has $installed_count packages installed"
    
    return 0
}

# Check disk space
check_disk_space() {
    log "Checking disk space..."
    
    available_space=$(df -BG "$BASE_DIR" | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_space" -lt 5 ]; then
        error "Insufficient disk space. At least 5GB recommended, only ${available_space}GB available"
        exit 1
    else
        info "Disk space available: ${available_space}GB"
    fi
}

# Pre-download common packages to cache
cache_common_packages() {
    log "Pre-downloading common packages to cache..."
    
    # Common packages used across services
    common_packages=(
        "fastapi==0.104.1"
        "uvicorn[standard]==0.24.0"
        "pydantic==2.5.0"
        "sqlalchemy==2.0.23"
        "psycopg2-binary==2.9.9"
        "redis==5.0.1"
        "httpx==0.25.2"
        "pytest==7.4.3"
    )
    
    # Create a temporary venv for caching
    temp_venv="/tmp/cache-venv"
    python3 -m venv "$temp_venv"
    
    # Download packages without installing
    for package in "${common_packages[@]}"; do
        "$temp_venv/bin/pip" download "$package" --dest /tmp/pip-cache >/dev/null 2>&1 || true
    done
    
    # Clean up
    rm -rf "$temp_venv"
    
    info "Common packages cached"
}

# Verify installations
verify_installations() {
    log "Verifying installations..."
    
    local success_count=0
    local fail_count=0
    
    for service in "${SERVICES[@]}"; do
        venv_path="$VENV_DIR/$service"
        
        if [ -d "$venv_path" ] && [ -f "$venv_path/bin/python" ]; then
            # Test importing key packages
            if "$venv_path/bin/python" -c "import fastapi, pydantic, sqlalchemy" 2>/dev/null; then
                log "✅ $service: Core packages verified"
                ((success_count++))
            else
                error "❌ $service: Failed to import core packages"
                ((fail_count++))
            fi
        else
            error "❌ $service: No valid virtual environment"
            ((fail_count++))
        fi
    done
    
    echo ""
    log "Verification Summary:"
    echo -e "${GREEN}Successful:${NC} $success_count services"
    echo -e "${RED}Failed:${NC} $fail_count services"
    
    return $fail_count
}

# Main installation function
main() {
    log "Starting package installation for all services..."
    
    # Check prerequisites
    if [ ! -d "$BASE_DIR" ]; then
        error "Base directory $BASE_DIR not found"
        exit 1
    fi
    
    if [ ! -d "$VENV_DIR" ]; then
        error "Virtual environment directory $VENV_DIR not found"
        error "Please run setup-python-env.sh first"
        exit 1
    fi
    
    # Check disk space
    check_disk_space
    
    # Optional: Cache common packages
    if command -v uv >/dev/null 2>&1; then
        cache_common_packages
    fi
    
    # Install packages for each service
    local failed_services=()
    
    for service in "${SERVICES[@]}"; do
        if ! install_service_packages "$service"; then
            failed_services+=("$service")
        fi
    done
    
    echo ""
    echo "=========================================="
    echo "Package Installation Summary"
    echo "=========================================="
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log "✅ All services successfully installed!"
    else
        error "❌ Failed services:"
        for service in "${failed_services[@]}"; do
            echo "  - $service"
        done
    fi
    
    # Verify installations
    echo ""
    verify_installations
    
    echo ""
    log "Package installation process completed"
    
    # Show next steps
    echo ""
    echo "Next steps:"
    echo "1. Test service imports: source scripts/activate-service.sh SERVICE_NAME"
    echo "2. Create service code in /opt/stock-analysis/services/SERVICE_NAME/"
    echo "3. Configure services with environment variables"
    echo "4. Start services with systemctl"
}

# Parse command line options
SKIP_CONFIRM=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -y|--yes)
            SKIP_CONFIRM=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  -y, --yes    Skip confirmation prompt"
            echo "  -h, --help   Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Confirmation prompt
if [ "$SKIP_CONFIRM" = false ]; then
    echo "This will install all packages defined in requirements.txt for all services."
    echo "This may take several minutes and will download ~1-2GB of packages."
    echo ""
    read -p "Continue? (y/N) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Installation cancelled"
        exit 0
    fi
fi

# Run main function
main "$@"