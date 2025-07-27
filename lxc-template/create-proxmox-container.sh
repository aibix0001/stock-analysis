#!/bin/bash
# Create Proxmox container from stock-analysis template

set -euo pipefail

# Configuration
VMID="${1:-}"
TEMPLATE_PATH="${2:-}"
STORAGE="${3:-local-lvm}"
HOSTNAME="${4:-stock-analysis}"
MEMORY="${5:-4096}"
CORES="${6:-2}"
DISK_SIZE="${7:-20}"
BRIDGE="${8:-vmbr0}"
IP="${9:-dhcp}"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Usage function
usage() {
    echo "Usage: $0 <vmid> <template-path> [storage] [hostname] [memory] [cores] [disk] [bridge] [ip]"
    echo ""
    echo "Parameters:"
    echo "  vmid         - Container ID (required)"
    echo "  template     - Path to template file (required)"
    echo "  storage      - Storage location (default: local-lvm)"
    echo "  hostname     - Container hostname (default: stock-analysis)"
    echo "  memory       - RAM in MB (default: 4096)"
    echo "  cores        - CPU cores (default: 2)"
    echo "  disk         - Disk size in GB (default: 20)"
    echo "  bridge       - Network bridge (default: vmbr0)"
    echo "  ip           - IP address or 'dhcp' (default: dhcp)"
    echo ""
    echo "Example:"
    echo "  $0 120 /var/lib/vz/template/cache/stock-analysis.tar.gz"
    echo "  $0 120 /var/lib/vz/template/cache/stock-analysis.tar.gz local-lvm stock-analysis 8192 4 50 vmbr0 10.1.1.120/24"
    exit 1
}

# Check parameters
if [ -z "${VMID}" ] || [ -z "${TEMPLATE_PATH}" ]; then
    usage
fi

# Check if running on Proxmox
if ! command -v pct >/dev/null 2>&1; then
    echo -e "${RED}Error: This script must be run on a Proxmox host${NC}"
    exit 1
fi

# Check if template exists
if [ ! -f "${TEMPLATE_PATH}" ]; then
    echo -e "${RED}Error: Template file not found: ${TEMPLATE_PATH}${NC}"
    exit 1
fi

# Check if VMID already exists
if pct status "${VMID}" >/dev/null 2>&1; then
    echo -e "${RED}Error: Container ${VMID} already exists${NC}"
    exit 1
fi

echo -e "${BLUE}Creating Stock Analysis Container${NC}"
echo "=================================="
echo "VMID:       ${VMID}"
echo "Template:   ${TEMPLATE_PATH}"
echo "Storage:    ${STORAGE}"
echo "Hostname:   ${HOSTNAME}"
echo "Memory:     ${MEMORY} MB"
echo "Cores:      ${CORES}"
echo "Disk:       ${DISK_SIZE} GB"
echo "Network:    ${BRIDGE} (${IP})"
echo ""

# Create container
echo -e "${BLUE}Creating container...${NC}"

# Build pct create command
CREATE_CMD="pct create ${VMID} ${TEMPLATE_PATH}"
CREATE_CMD="${CREATE_CMD} --hostname ${HOSTNAME}"
CREATE_CMD="${CREATE_CMD} --memory ${MEMORY}"
CREATE_CMD="${CREATE_CMD} --cores ${CORES}"
CREATE_CMD="${CREATE_CMD} --rootfs ${STORAGE}:${DISK_SIZE}"
CREATE_CMD="${CREATE_CMD} --features nesting=1"
CREATE_CMD="${CREATE_CMD} --unprivileged 1"

# Network configuration
if [ "${IP}" = "dhcp" ]; then
    CREATE_CMD="${CREATE_CMD} --net0 name=eth0,bridge=${BRIDGE},ip=dhcp"
else
    CREATE_CMD="${CREATE_CMD} --net0 name=eth0,bridge=${BRIDGE},ip=${IP},gw=${BRIDGE%br*}.1.1"
fi

# Execute creation
if ${CREATE_CMD}; then
    echo -e "${GREEN}✓ Container created successfully${NC}"
else
    echo -e "${RED}✗ Failed to create container${NC}"
    exit 1
fi

# Configure container
echo -e "${BLUE}Configuring container...${NC}"

# Set startup order and delay
pct set "${VMID}" --startup order=50,up=30

# Add description
pct set "${VMID}" --description "Stock Analysis Ecosystem - Event-driven trading intelligence platform
Services: PostgreSQL, Redis, RabbitMQ, 5 microservices
Default user: stock-analysis / changeme
First boot will auto-configure all services"

# Create mount points for data persistence (optional)
echo -e "${BLUE}Creating data mount points...${NC}"

# PostgreSQL data
if pvesm alloc "${STORAGE}" "${VMID}" vm-${VMID}-disk-1 10G >/dev/null 2>&1; then
    pct set "${VMID}" --mp0 ${STORAGE}:vm-${VMID}-disk-1,mp=/var/lib/postgresql,backup=1
    echo -e "${GREEN}✓ PostgreSQL data volume created${NC}"
fi

# Redis data
if pvesm alloc "${STORAGE}" "${VMID}" vm-${VMID}-disk-2 5G >/dev/null 2>&1; then
    pct set "${VMID}" --mp1 ${STORAGE}:vm-${VMID}-disk-2,mp=/var/lib/redis,backup=1
    echo -e "${GREEN}✓ Redis data volume created${NC}"
fi

# Application logs
if pvesm alloc "${STORAGE}" "${VMID}" vm-${VMID}-disk-3 5G >/dev/null 2>&1; then
    pct set "${VMID}" --mp2 ${STORAGE}:vm-${VMID}-disk-3,mp=/var/log/stock-analysis,backup=1
    echo -e "${GREEN}✓ Application logs volume created${NC}"
fi

# Start container
echo -e "${BLUE}Starting container...${NC}"
if pct start "${VMID}"; then
    echo -e "${GREEN}✓ Container started${NC}"
else
    echo -e "${YELLOW}⚠ Container created but not started${NC}"
fi

# Wait for container to be ready
echo -e "${BLUE}Waiting for container to initialize...${NC}"
sleep 10

# Get container IP
if [ "${IP}" = "dhcp" ]; then
    # Try to get DHCP IP
    CONTAINER_IP=$(pct exec "${VMID}" -- ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+\.\d+\.\d+\.\d+' | head -1)
    if [ -n "${CONTAINER_IP}" ]; then
        echo -e "${GREEN}✓ Container IP: ${CONTAINER_IP}${NC}"
    fi
else
    CONTAINER_IP=$(echo "${IP}" | cut -d'/' -f1)
fi

# Display summary
echo ""
echo -e "${GREEN}✅ Stock Analysis Container Created Successfully!${NC}"
echo ""
echo "Container ID: ${VMID}"
echo "Hostname:     ${HOSTNAME}"
if [ -n "${CONTAINER_IP:-}" ]; then
    echo "IP Address:   ${CONTAINER_IP}"
fi
echo ""
echo "First boot will automatically:"
echo "- Initialize PostgreSQL database"
echo "- Configure Redis clustering"
echo "- Set up RabbitMQ users and exchanges"
echo "- Create Python virtual environments"
echo "- Install systemd services"
echo ""
echo "To access the container:"
echo "  pct enter ${VMID}"
echo "  ssh stock-analysis@${CONTAINER_IP:-<container-ip>}"
echo ""
echo "To monitor first boot:"
echo "  pct exec ${VMID} -- journalctl -u stock-analysis-firstboot -f"
echo ""
echo "Service URLs (after first boot):"
if [ -n "${CONTAINER_IP:-}" ]; then
    echo "  - Intelligent Core: http://${CONTAINER_IP}:8001/health"
    echo "  - Broker Gateway:   http://${CONTAINER_IP}:8002/health"
    echo "  - Event Bus:        http://${CONTAINER_IP}:8003/health"
    echo "  - Monitoring:       http://${CONTAINER_IP}:8004/health"
    echo "  - Frontend API:     http://${CONTAINER_IP}:8005/health"
    echo "  - RabbitMQ Mgmt:    http://${CONTAINER_IP}:15672"
fi