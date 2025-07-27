#!/bin/bash
# Proxmox Container Toolkit (PCT) hooks for stock-analysis template

# Hook: pre-start
# Called before container starts
pre_start_hook() {
    local VMID=$1
    echo "Pre-start hook for stock-analysis container ${VMID}"
    
    # Ensure required kernel modules are loaded
    modprobe overlay
    modprobe br_netfilter
    
    # Set sysctl parameters for container
    sysctl -w net.bridge.bridge-nf-call-iptables=1
    sysctl -w net.bridge.bridge-nf-call-ip6tables=1
}

# Hook: post-start
# Called after container starts
post_start_hook() {
    local VMID=$1
    echo "Post-start hook for stock-analysis container ${VMID}"
    
    # Wait for container to be fully up
    sleep 5
    
    # Check if first boot service is running
    pct exec "${VMID}" -- systemctl is-active stock-analysis-firstboot || true
}

# Hook: pre-stop
# Called before container stops
pre_stop_hook() {
    local VMID=$1
    echo "Pre-stop hook for stock-analysis container ${VMID}"
    
    # Gracefully stop services
    pct exec "${VMID}" -- systemctl stop 'stock-analysis-*' || true
    
    # Wait for services to stop
    sleep 5
}

# Hook: post-stop
# Called after container stops
post_stop_hook() {
    local VMID=$1
    echo "Post-stop hook for stock-analysis container ${VMID}"
}

# Main hook dispatcher
case "$1" in
    pre-start)
        pre_start_hook "$2"
        ;;
    post-start)
        post_start_hook "$2"
        ;;
    pre-stop)
        pre_stop_hook "$2"
        ;;
    post-stop)
        post_stop_hook "$2"
        ;;
    *)
        echo "Unknown hook: $1"
        exit 1
        ;;
esac