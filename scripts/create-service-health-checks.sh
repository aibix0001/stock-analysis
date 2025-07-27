#!/bin/bash
# Create health check modules for all services

set -euo pipefail

BASE_DIR="/opt/stock-analysis"
SERVICES=(
    "intelligent-core-service:8001:Intelligent analysis and ML engine"
    "broker-gateway-service:8002:Trading and broker integration"
    "event-bus-service:8003:Central event routing"
    "frontend-service:8005:Web API backend"
    "monitoring-service:8004:System monitoring and alerts"
)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "Creating health check modules for all services..."

for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service port description <<< "$service_info"
    
    echo -e "${BLUE}Creating health check for $service...${NC}"
    
    # Create __init__.py
    mkdir -p "$BASE_DIR/services/$service"
    touch "$BASE_DIR/services/$service/__init__.py"
    
    # Create main.py with health check
    cat > "$BASE_DIR/services/$service/main.py" <<EOF
#!/usr/bin/env python3
"""Main module for $service"""

import sys
import os

# Add shared modules to path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '../../shared'))

from health_check import create_service_health_app
from fastapi import FastAPI
import uvicorn

# Service configuration
SERVICE_NAME = "$service"
SERVICE_VERSION = "1.0.0"
SERVICE_PORT = int(os.getenv("SERVICE_PORT", $port))
SERVICE_DESCRIPTION = "$description"

# Create main app
app = FastAPI(
    title=SERVICE_NAME,
    version=SERVICE_VERSION,
    description=SERVICE_DESCRIPTION
)

# Create health checker
health_app = create_service_health_app(SERVICE_NAME, SERVICE_VERSION)

# Mount health check endpoints
app.mount("/", health_app)

# Add service-specific endpoints here
@app.get("/api/v1/info")
async def service_info():
    """Service-specific information"""
    return {
        "service": SERVICE_NAME,
        "version": SERVICE_VERSION,
        "description": SERVICE_DESCRIPTION,
        "status": "operational"
    }

# Service-specific initialization
@app.on_event("startup")
async def startup_event():
    """Initialize service-specific components"""
    print(f"Starting {SERVICE_NAME} on port {SERVICE_PORT}")
    # Add service-specific initialization here

@app.on_event("shutdown")
async def shutdown_event():
    """Cleanup on shutdown"""
    print(f"Shutting down {SERVICE_NAME}")
    # Add cleanup code here

if __name__ == "__main__":
    uvicorn.run(
        app,
        host="0.0.0.0",
        port=SERVICE_PORT,
        log_level="info",
        access_log=True
    )
EOF
    
    # Create __main__.py for module execution
    cat > "$BASE_DIR/services/$service/__main__.py" <<EOF
#!/usr/bin/env python3
"""Entry point for $service"""

from .main import app
import uvicorn
import os

if __name__ == "__main__":
    port = int(os.getenv("SERVICE_PORT", $port))
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=port,
        reload=os.getenv("NODE_ENV") == "development"
    )
EOF
    
    # Make files executable
    chmod +x "$BASE_DIR/services/$service/main.py"
    chmod +x "$BASE_DIR/services/$service/__main__.py"
    
    echo -e "${GREEN}✓ Created health check for $service${NC}"
done

# Create a test script for all health endpoints
cat > "$BASE_DIR/scripts/test-all-health-checks.sh" <<'EOF'
#!/bin/bash
# Test all service health endpoints

set -euo pipefail

SERVICES=(
    "intelligent-core-service:8001"
    "broker-gateway-service:8002"
    "event-bus-service:8003"
    "monitoring-service:8004"
    "frontend-service:8005"
)

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "Testing health endpoints for all services..."
echo "=========================================="

for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r service port <<< "$service_info"
    
    echo ""
    echo "Testing $service on port $port..."
    
    # Test if service is running
    if curl -sf "http://localhost:$port/health" > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $service health check passed${NC}"
        
        # Get health details
        health_data=$(curl -s "http://localhost:$port/health")
        echo "  Status: $(echo "$health_data" | jq -r .status)"
        echo "  Uptime: $(echo "$health_data" | jq -r .uptime_seconds)s"
    else
        echo -e "${RED}✗ $service health check failed${NC}"
    fi
done

echo ""
echo "=========================================="
echo "Health check tests completed"
EOF

chmod +x "$BASE_DIR/scripts/test-all-health-checks.sh"

echo ""
echo -e "${GREEN}✅ All health check modules created successfully!${NC}"
echo ""
echo "Each service now has:"
echo "- main.py with health endpoints"
echo "- Standardized health checks at /health, /health/live, /health/ready"
echo "- Service info at /api/v1/info"
echo ""
echo "To test: $BASE_DIR/scripts/test-all-health-checks.sh"