#!/bin/bash
# System setup script for Stock Analysis
set -euo pipefail

echo "Starting Stock Analysis system setup..."

# Update system
echo "Updating system packages..."
apt-get update
apt-get upgrade -y

# Install base packages
echo "Installing base system packages..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-dev \
    libpq-dev \
    postgresql-client \
    redis-tools \
    systemd \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release

# Create stock-analysis user
if ! id -u stock-analysis >/dev/null 2>&1; then
    echo "Creating stock-analysis user..."
    useradd -m -s /bin/bash -d /opt/stock-analysis stock-analysis
fi

# Set up directories
echo "Setting up directories..."
chown -R stock-analysis:stock-analysis /opt/stock-analysis
chmod 755 /opt/stock-analysis

echo "System setup completed successfully!"
