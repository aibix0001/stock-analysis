#!/bin/bash
# Network configuration script for Stock Analysis LXC container
# This script configures the container with DHCP networking

set -euo pipefail

# Configuration
CONTAINER_HOSTNAME="stock-analysis"
CONTAINER_DOMAIN="local"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}This script must be run as root${NC}"
    exit 1
fi

echo "Configuring network for Stock Analysis LXC container..."

# Backup existing network configuration
if [ -f /etc/network/interfaces ]; then
    cp /etc/network/interfaces /etc/network/interfaces.backup.$(date +%Y%m%d%H%M%S)
fi

# Configure /etc/network/interfaces
cat > /etc/network/interfaces << EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto eth0
iface eth0 inet dhcp
EOF

# Set hostname
echo "$CONTAINER_HOSTNAME" > /etc/hostname
hostnamectl set-hostname "$CONTAINER_HOSTNAME" 2>/dev/null || hostname "$CONTAINER_HOSTNAME"

# Update /etc/hosts
cat > /etc/hosts << EOF
127.0.0.1       localhost
127.0.1.1       $CONTAINER_HOSTNAME.$CONTAINER_DOMAIN $CONTAINER_HOSTNAME

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# DNS will be configured by DHCP
# Remove any static DNS configuration if needed
if [ -f /etc/resolv.conf ] && grep -q "# Static DNS" /etc/resolv.conf; then
    log_info "Removing static DNS configuration..."
    > /etc/resolv.conf
fi

# Disable cloud-init network configuration if present
if [ -d /etc/cloud ]; then
    echo "network: {config: disabled}" > /etc/cloud/cloud.cfg.d/99-disable-network-config.cfg
fi

# Apply network configuration
echo "Applying network configuration..."
if systemctl is-active --quiet networking; then
    systemctl restart networking
else
    ifdown eth0 2>/dev/null || true
    ifup eth0
fi

# Wait for network to come up and DHCP to assign IP
sleep 5

# Verify configuration
echo -e "\n${GREEN}Network configuration applied:${NC}"
echo "Hostname: $(hostname)"

# Get IP address assigned by DHCP
IP_ADDR=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
if [ -n "$IP_ADDR" ]; then
    echo "IP Address (DHCP): $IP_ADDR"
else
    echo -e "${RED}No IP address assigned yet${NC}"
fi

# Get gateway from DHCP
GATEWAY=$(ip route | grep default | awk '{print $3}')
if [ -n "$GATEWAY" ]; then
    echo "Gateway: $GATEWAY"
else
    echo -e "${RED}No gateway configured${NC}"
fi

# Get DNS servers from DHCP
DNS_SERVERS=$(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | tr '\n' ' ')
if [ -n "$DNS_SERVERS" ]; then
    echo "DNS Servers: $DNS_SERVERS"
else
    echo -e "${RED}No DNS servers configured${NC}"
fi

# Test connectivity
echo -e "\nTesting network connectivity..."
if [ -n "$GATEWAY" ] && ping -c 1 -W 2 "$GATEWAY" &>/dev/null; then
    echo -e "${GREEN}✓ Gateway reachable${NC}"
else
    echo -e "${RED}✗ Gateway unreachable${NC}"
fi

if ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
    echo -e "${GREEN}✓ Internet connectivity OK${NC}"
else
    echo -e "${RED}✗ No internet connectivity${NC}"
fi

echo -e "\n${GREEN}Network configuration completed!${NC}"