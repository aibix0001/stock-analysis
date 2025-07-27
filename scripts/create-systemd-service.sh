#!/bin/bash
# Helper script to create systemd service files from template
# Usage: ./create-systemd-service.sh <service-name> <service-module> <port>

set -euo pipefail

# Check arguments
if [ $# -ne 3 ]; then
    echo "Usage: $0 <service-name> <service-module> <port>"
    echo "Example: $0 intelligent-core-service app.main 8001"
    exit 1
fi

SERVICE_NAME=$1
SERVICE_MODULE=$2
SERVICE_PORT=$3

# Configuration
TEMPLATE_FILE="/etc/stock-analysis/python-service.template"
SERVICE_FILE="/etc/systemd/system/stock-analysis-${SERVICE_NAME}.service"
SERVICE_DIR="${SERVICE_NAME}"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if template exists
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: Template file not found: $TEMPLATE_FILE${NC}"
    echo "Please run setup-lxc-native.sh first"
    exit 1
fi

# Create service file from template
echo "Creating systemd service for $SERVICE_NAME..."

# Copy template and replace placeholders
cp "$TEMPLATE_FILE" "$SERVICE_FILE"

# Replace placeholders
sed -i "s/{SERVICE_NAME}/$SERVICE_NAME/g" "$SERVICE_FILE"
sed -i "s/{SERVICE_DIR}/$SERVICE_DIR/g" "$SERVICE_FILE"
sed -i "s/{SERVICE_MODULE}/$SERVICE_MODULE/g" "$SERVICE_FILE"
sed -i "s/{SERVICE_PORT}/$SERVICE_PORT/g" "$SERVICE_FILE"

# Add port to environment
sed -i "/Environment=\"SERVICE_NAME=/a Environment=\"SERVICE_PORT=$SERVICE_PORT\"" "$SERVICE_FILE"

# Create health check script
HEALTH_CHECK_SCRIPT="/opt/stock-analysis/scripts/health-check-${SERVICE_NAME}.sh"
cp /etc/stock-analysis/health-check.template "$HEALTH_CHECK_SCRIPT"
sed -i "s/{SERVICE_NAME}/$SERVICE_NAME/g" "$HEALTH_CHECK_SCRIPT"
sed -i "s/{SERVICE_PORT}/$SERVICE_PORT/g" "$HEALTH_CHECK_SCRIPT"
chmod +x "$HEALTH_CHECK_SCRIPT"

# Add health check to service
sed -i "/ExecStart=/a ExecStartPost=$HEALTH_CHECK_SCRIPT" "$SERVICE_FILE"

echo -e "${GREEN}✓ Created service file: $SERVICE_FILE${NC}"
echo -e "${GREEN}✓ Created health check: $HEALTH_CHECK_SCRIPT${NC}"

# Reload systemd
systemctl daemon-reload

echo ""
echo "Service created successfully!"
echo ""
echo "Next steps:"
echo "1. Create virtual environment:"
echo "   cd /opt/stock-analysis && uv venv venvs/$SERVICE_NAME"
echo ""
echo "2. Install dependencies:"
echo "   uv pip install -r services/$SERVICE_DIR/requirements.txt"
echo ""
echo "3. Enable and start service:"
echo "   systemctl enable stock-analysis-${SERVICE_NAME}"
echo "   systemctl start stock-analysis-${SERVICE_NAME}"
echo ""
echo "4. Check service status:"
echo "   systemctl status stock-analysis-${SERVICE_NAME}"
echo "   journalctl -u stock-analysis-${SERVICE_NAME} -f"