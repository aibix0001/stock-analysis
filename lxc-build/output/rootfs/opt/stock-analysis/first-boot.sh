#!/bin/bash
# First boot setup script
set -euo pipefail

MARKER_FILE="/opt/stock-analysis/.first-boot-complete"

if [ -f "$MARKER_FILE" ]; then
    echo "First boot setup already completed"
    exit 0
fi

echo "Running first boot setup..."

# Run setup scripts in order
/opt/stock-analysis/scripts/setup-system.sh
/opt/stock-analysis/scripts/setup-python.sh
/opt/stock-analysis/scripts/setup-databases.sh
/opt/stock-analysis/scripts/setup-services.sh

# Initialize databases
sudo -u postgres psql < /opt/stock-analysis/config/postgresql/init.sql

# Create marker file
touch "$MARKER_FILE"

echo "First boot setup completed!"
echo "You can now start services with: systemctl start stock-analysis-*.service"
