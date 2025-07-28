#!/bin/bash
# Service setup script
set -euo pipefail

echo "Setting up systemd services..."

# Copy service files
cp /opt/stock-analysis/config/systemd/*.service /etc/systemd/system/

# Create environment files
for service in broker-gateway intelligent-core event-bus monitoring frontend; do
    cat > "/etc/stock-analysis/stock-analysis-${service}.env" << ENV
# Environment variables for ${service}
DATABASE_URL=postgresql://stock_analysis_user:changeme@localhost/stock_analysis_event_store
REDIS_URL=redis://:changeme@localhost:6379
RABBITMQ_URL=amqp://stock_analysis:changeme@localhost:5672//stock-analysis
SERVICE_PORT=$((8000 + $(echo $service | od -An -N1 -i)))
SERVICE_NAME=stock-analysis-${service}
ENV
done

# Reload systemd
systemctl daemon-reload

# Enable services
for service in broker-gateway intelligent-core event-bus monitoring frontend; do
    systemctl enable stock-analysis-${service}.service
done

echo "Service setup completed!"
echo "Services can be started with: systemctl start stock-analysis-*.service"
