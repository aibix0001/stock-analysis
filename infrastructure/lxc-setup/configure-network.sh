#!/bin/bash
# Network configuration script for Stock Analysis LXC container
# This script configures the container with static IP 10.1.1.120/24

set -euo pipefail

# Configuration
CONTAINER_IP="10.1.1.120"
CONTAINER_NETMASK="255.255.255.0"
CONTAINER_GATEWAY="10.1.1.1"
CONTAINER_DNS1="8.8.8.8"
CONTAINER_DNS2="8.8.4.4"
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
iface eth0 inet static
    address $CONTAINER_IP
    netmask $CONTAINER_NETMASK
    gateway $CONTAINER_GATEWAY
    dns-nameservers $CONTAINER_DNS1 $CONTAINER_DNS2
    dns-search $CONTAINER_DOMAIN
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

# Configure DNS resolution
cat > /etc/resolv.conf << EOF
search $CONTAINER_DOMAIN
nameserver $CONTAINER_DNS1
nameserver $CONTAINER_DNS2
EOF

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

# Wait for network to come up
sleep 3

# Verify configuration
echo -e "\n${GREEN}Network configuration applied:${NC}"
echo "Hostname: $(hostname)"
echo "IP Address: $(ip addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')"
echo "Gateway: $(ip route | grep default | awk '{print $3}')"
echo "DNS Servers: $(grep nameserver /etc/resolv.conf | awk '{print $2}' | tr '\n' ' ')"

# Test connectivity
echo -e "\nTesting network connectivity..."
if ping -c 1 -W 2 $CONTAINER_GATEWAY &>/dev/null; then
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