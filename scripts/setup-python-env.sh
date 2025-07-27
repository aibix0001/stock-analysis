#!/bin/bash
# Python Environment Setup Script for Stock Analysis Ecosystem
# Sets up Python 3.11+, uv, and virtual environments for all services

set -euo pipefail

# Configuration
BASE_DIR="/opt/stock-analysis"
VENV_DIR="$BASE_DIR/venvs"
SERVICE_USER="stock-analysis"
PYTHON_VERSION="3.11"

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

# Check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        error "This script must be run as root"
        exit 1
    fi
}

# Ensure Python 3.11+ is installed
ensure_python() {
    log "Checking Python installation..."
    
    # Check if Python 3 is installed
    if ! command -v python3 >/dev/null 2>&1; then
        error "Python 3 is not installed. Please run setup-lxc-native.sh first"
        exit 1
    fi
    
    # Check Python version
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    python_major=$(echo $python_version | cut -d'.' -f1)
    python_minor=$(echo $python_version | cut -d'.' -f2)
    
    if [ "$python_major" -eq 3 ] && [ "$python_minor" -ge 11 ]; then
        info "Python $python_version is installed"
    else
        error "Python $python_version does not meet requirements (need >= 3.11)"
        exit 1
    fi
    
    # Ensure development packages
    log "Installing Python development packages..."
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
        python3-pip \
        python3-venv \
        python3-dev \
        python3-setuptools \
        python3-wheel \
        libpython3-dev \
        libffi-dev \
        libssl-dev \
        libpq-dev \
        libyaml-dev \
        python3-psycopg2 \
        python3-redis \
        python3-aiofiles
    
    log "Python environment prepared"
}

# Install uv package manager
install_uv() {
    log "Installing uv package manager..."
    
    # Check if uv is already installed
    if command -v uv >/dev/null 2>&1; then
        uv_version=$(uv --version 2>&1 | cut -d' ' -f2)
        info "uv $uv_version is already installed"
        return 0
    fi
    
    # Install uv
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    # Add uv to system-wide PATH
    if [ -f "$HOME/.cargo/bin/uv" ]; then
        ln -sf "$HOME/.cargo/bin/uv" /usr/local/bin/uv
        info "uv symlinked to /usr/local/bin/uv"
    elif [ -f "/root/.cargo/bin/uv" ]; then
        ln -sf "/root/.cargo/bin/uv" /usr/local/bin/uv
        info "uv symlinked to /usr/local/bin/uv"
    fi
    
    # Verify installation
    if command -v uv >/dev/null 2>&1; then
        uv_version=$(uv --version 2>&1 | cut -d' ' -f2)
        log "uv $uv_version installed successfully"
    else
        error "Failed to install uv"
        exit 1
    fi
}

# Create virtual environment directory
create_venv_directory() {
    log "Creating virtual environment directory..."
    
    mkdir -p "$VENV_DIR"
    chown "$SERVICE_USER:$SERVICE_USER" "$VENV_DIR"
    chmod 755 "$VENV_DIR"
    
    log "Virtual environment directory created: $VENV_DIR"
}

# Create virtual environment for a service
create_service_venv() {
    local service=$1
    local venv_path="$VENV_DIR/$service"
    
    log "Creating virtual environment for $service..."
    
    # Create venv using uv
    if command -v uv >/dev/null 2>&1; then
        # Use uv to create venv
        cd "$BASE_DIR"
        uv venv "$venv_path" --python python$PYTHON_VERSION
        info "Created venv with uv for $service"
    else
        # Fallback to standard venv
        python3 -m venv "$venv_path"
        info "Created venv with python3 -m venv for $service"
    fi
    
    # Set ownership
    chown -R "$SERVICE_USER:$SERVICE_USER" "$venv_path"
    
    # Upgrade pip, setuptools, wheel
    log "Upgrading core packages for $service..."
    "$venv_path/bin/python" -m pip install --upgrade pip setuptools wheel
    
    # Install uv in the venv if available
    if command -v uv >/dev/null 2>&1; then
        "$venv_path/bin/pip" install uv
    fi
    
    log "Virtual environment ready for $service"
}

# Create requirements.txt template for a service
create_requirements_template() {
    local service=$1
    local service_dir="$BASE_DIR/services/$service"
    local req_file="$service_dir/requirements.txt"
    
    log "Creating requirements.txt for $service..."
    
    # Create service directory if it doesn't exist
    mkdir -p "$service_dir"
    
    # Create service-specific requirements
    case $service in
        "intelligent-core-service")
            cat > "$req_file" <<EOF
# Intelligent Core Service Requirements
# Core analysis and intelligence engine

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
pydantic-settings==2.1.0

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
alembic==1.12.1

# Redis & Caching
redis==5.0.1
hiredis==2.2.3

# Event Processing
aiokafka==0.10.0
confluent-kafka==2.3.0

# Data Analysis
numpy==1.26.2
pandas==2.1.3
scipy==1.11.4
scikit-learn==1.3.2

# Machine Learning
xgboost==2.0.2
lightgbm==4.1.0
torch==2.1.1
transformers==4.35.2

# Technical Indicators
ta==0.11.0
pandas-ta==0.3.14b0

# API Clients
httpx==0.25.2
aiohttp==3.9.1

# Utilities
python-dotenv==1.0.0
structlog==23.2.0
tenacity==8.2.3
croniter==2.0.1

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
pytest-cov==4.1.0
black==23.11.0
ruff==0.1.6
mypy==1.7.1
EOF
            ;;
            
        "broker-gateway-service")
            cat > "$req_file" <<EOF
# Broker Gateway Service Requirements
# Trading and broker integration service

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9

# Redis
redis==5.0.1

# Broker APIs
ccxt==4.1.22  # Cryptocurrency exchange library
alpaca-py==0.13.3  # Alpaca trading
yfinance==0.2.33  # Yahoo Finance

# WebSocket
websockets==12.0
python-socketio==5.10.0

# Message Queue
pika==1.3.2  # RabbitMQ
kombu==5.3.4

# Security
cryptography==41.0.7
pyjwt==2.8.0

# Utilities
httpx==0.25.2
python-dotenv==1.0.0
structlog==23.2.0
tenacity==8.2.3

# Rate Limiting
slowapi==0.1.9

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
ruff==0.1.6
EOF
            ;;
            
        "event-bus-service")
            cat > "$req_file" <<EOF
# Event Bus Service Requirements
# Central event routing and processing

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0

# Redis (Primary Event Store)
redis==5.0.1
redis-py-cluster==2.1.6
hiredis==2.2.3

# Message Queue
pika==1.3.2  # RabbitMQ
kombu==5.3.4
celery==5.3.4

# Event Streaming
aiokafka==0.10.0
confluent-kafka==2.3.0

# Database
psycopg2-binary==2.9.9
sqlalchemy==2.0.23

# Monitoring
prometheus-client==0.19.0
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0

# Utilities
python-dotenv==1.0.0
structlog==23.2.0
orjson==3.9.10  # Fast JSON

# Schema Registry
jsonschema==4.20.0
python-json-logger==2.0.7

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
EOF
            ;;
            
        "frontend-service")
            cat > "$req_file" <<EOF
# Frontend Service Requirements
# API backend for React frontend

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0
python-multipart==0.0.6

# WebSocket
python-socketio==5.10.0
websockets==12.0

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9

# Redis
redis==5.0.1

# Authentication
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4
python-multipart==0.0.6

# CORS
fastapi-cors==0.0.6

# Static Files
aiofiles==23.2.1

# Session Management
itsdangerous==2.1.2

# Utilities
python-dotenv==1.0.0
structlog==23.2.0
httpx==0.25.2

# GraphQL (optional)
strawberry-graphql[fastapi]==0.215.1

# Development
pytest==7.4.3
pytest-asyncio==0.21.1
black==23.11.0
EOF
            ;;
            
        "monitoring-service")
            cat > "$req_file" <<EOF
# Monitoring Service Requirements
# System monitoring and alerting

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9
influxdb-client==1.38.0

# Redis
redis==5.0.1

# Monitoring & Metrics
prometheus-client==0.19.0
psutil==5.9.6
py-cpuinfo==9.0.0

# Tracing
opentelemetry-api==1.21.0
opentelemetry-sdk==1.21.0
opentelemetry-instrumentation-fastapi==0.42b0

# Alerting
requests==2.31.0
slack-sdk==3.26.1
sendgrid==6.11.0

# Time Series
pandas==2.1.3
numpy==1.26.2

# Visualization Data
plotly==5.18.0

# Health Checks
healthcheck==1.3.3

# Utilities
python-dotenv==1.0.0
structlog==23.2.0
apscheduler==3.10.4

# Development
pytest==7.4.3
black==23.11.0
EOF
            ;;
            
        *)
            cat > "$req_file" <<EOF
# $service Requirements
# Auto-generated template

# Web Framework
fastapi==0.104.1
uvicorn[standard]==0.24.0
pydantic==2.5.0

# Database
sqlalchemy==2.0.23
psycopg2-binary==2.9.9

# Redis
redis==5.0.1

# Utilities
python-dotenv==1.0.0
structlog==23.2.0

# Development
pytest==7.4.3
black==23.11.0
ruff==0.1.6
EOF
            ;;
    esac
    
    # Set ownership
    chown "$SERVICE_USER:$SERVICE_USER" "$req_file"
    
    log "Created requirements.txt for $service"
}

# Create activation helper script
create_activation_script() {
    log "Creating activation helper script..."
    
    cat > "$BASE_DIR/scripts/activate-service.sh" <<'EOF'
#!/bin/bash
# Helper script to activate service virtual environments

if [ $# -ne 1 ]; then
    echo "Usage: $0 <service-name>"
    echo "Available services:"
    echo "  - intelligent-core-service"
    echo "  - broker-gateway-service"
    echo "  - event-bus-service"
    echo "  - frontend-service"
    echo "  - monitoring-service"
    exit 1
fi

SERVICE=$1
VENV_PATH="/opt/stock-analysis/venvs/$SERVICE"

if [ ! -d "$VENV_PATH" ]; then
    echo "Error: Virtual environment not found for $SERVICE"
    exit 1
fi

# Activate virtual environment
source "$VENV_PATH/bin/activate"

echo "Activated virtual environment for $SERVICE"
echo "Python: $(which python)"
echo "Version: $(python --version)"

# Change to service directory
cd "/opt/stock-analysis/services/$SERVICE" 2>/dev/null || echo "Service directory not found"
EOF
    
    chmod +x "$BASE_DIR/scripts/activate-service.sh"
    chown "$SERVICE_USER:$SERVICE_USER" "$BASE_DIR/scripts/activate-service.sh"
    
    log "Created activation helper script"
}

# Create Python version file
create_python_version_file() {
    log "Creating Python version file..."
    
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2 | cut -d'.' -f1,2)
    echo "$python_version" > "$BASE_DIR/.python-version"
    chown "$SERVICE_USER:$SERVICE_USER" "$BASE_DIR/.python-version"
    
    log "Created .python-version file: $python_version"
}

# Create pyproject.toml template
create_pyproject_toml() {
    log "Creating pyproject.toml template..."
    
    cat > "$BASE_DIR/pyproject.toml" <<EOF
[project]
name = "stock-analysis-ecosystem"
version = "1.0.0"
description = "Event-driven stock analysis and trading ecosystem"
requires-python = ">=${PYTHON_VERSION}"

[tool.uv]
dev-dependencies = [
    "pytest>=7.4.3",
    "pytest-asyncio>=0.21.1",
    "pytest-cov>=4.1.0",
    "black>=23.11.0",
    "ruff>=0.1.6",
    "mypy>=1.7.1",
    "pre-commit>=3.5.0",
]

[tool.black]
line-length = 88
target-version = ["py311"]
include = '\.pyi?$'

[tool.ruff]
line-length = 88
target-version = "py311"
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C90", # mccabe complexity
]
ignore = ["E501", "B008"]

[tool.mypy]
python_version = "${PYTHON_VERSION}"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
ignore_missing_imports = true

[tool.pytest.ini_options]
minversion = "7.0"
testpaths = ["tests"]
python_files = ["test_*.py", "*_test.py"]
python_functions = ["test_*"]
python_classes = ["Test*"]
addopts = [
    "--verbose",
    "--strict-markers",
    "--cov=services",
    "--cov-report=term-missing",
    "--cov-report=html",
]
asyncio_mode = "auto"
EOF
    
    chown "$SERVICE_USER:$SERVICE_USER" "$BASE_DIR/pyproject.toml"
    
    log "Created pyproject.toml template"
}

# Install packages in virtual environments
install_venv_packages() {
    local service=$1
    local venv_path="$VENV_DIR/$service"
    local req_file="$BASE_DIR/services/$service/requirements.txt"
    
    log "Installing packages for $service..."
    
    if [ ! -f "$req_file" ]; then
        warning "No requirements.txt found for $service, skipping package installation"
        return 0
    fi
    
    # Install packages using uv if available, otherwise pip
    if [ -f "$venv_path/bin/uv" ] && command -v uv >/dev/null 2>&1; then
        log "Installing with uv for $service..."
        cd "$BASE_DIR/services/$service"
        "$venv_path/bin/uv" pip install -r requirements.txt
    else
        log "Installing with pip for $service..."
        "$venv_path/bin/pip" install -r "$req_file"
    fi
    
    log "Package installation completed for $service"
}

# Main setup function
main() {
    log "Starting Python Environment Setup..."
    
    # Check if running as root
    check_root
    
    # Ensure base directory exists
    if [ ! -d "$BASE_DIR" ]; then
        error "Base directory $BASE_DIR does not exist. Please run setup-lxc-native.sh first"
        exit 1
    fi
    
    # Setup steps
    ensure_python
    install_uv
    create_venv_directory
    create_python_version_file
    create_pyproject_toml
    
    # Create virtual environments and requirements for each service
    for service in "${SERVICES[@]}"; do
        create_service_venv "$service"
        create_requirements_template "$service"
        # Optionally install packages (comment out if you want to do this manually)
        # install_venv_packages "$service"
    done
    
    # Create helper scripts
    create_activation_script
    
    log "✅ Python environment setup completed successfully!"
    info "Virtual environments created for all services"
    info "Requirements templates created in services/*/requirements.txt"
    echo ""
    echo "Next steps:"
    echo "1. Review and customize requirements.txt files for each service"
    echo "2. Install packages: cd /opt/stock-analysis && uv pip install -r services/SERVICE_NAME/requirements.txt"
    echo "3. Or use: source scripts/activate-service.sh SERVICE_NAME"
}

# Run main function
main "$@"