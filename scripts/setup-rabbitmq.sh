#!/bin/bash
# RabbitMQ Configuration Script for Stock Analysis Ecosystem
# Configures RabbitMQ for event-driven messaging

set -euo pipefail

# Configuration
RABBITMQ_USER="stock_analysis"
RABBITMQ_PASSWORD="${RABBITMQ_PASSWORD:-stock_password}"
RABBITMQ_ADMIN_USER="admin"
RABBITMQ_ADMIN_PASSWORD="${RABBITMQ_ADMIN_PASSWORD:-admin_password}"
CONTAINER_IP="10.1.1.120"

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

# Check if RabbitMQ is installed
check_rabbitmq() {
    if ! command -v rabbitmqctl >/dev/null 2>&1; then
        error "RabbitMQ is not installed. Please run setup-lxc-native.sh first"
        exit 1
    fi
    
    if ! systemctl is-active --quiet rabbitmq-server; then
        error "RabbitMQ service is not running"
        exit 1
    fi
}

# Configure RabbitMQ
configure_rabbitmq() {
    log "Configuring RabbitMQ for Stock Analysis Ecosystem..."
    
    # Enable required plugins
    log "Enabling RabbitMQ plugins..."
    rabbitmq-plugins enable rabbitmq_management
    rabbitmq-plugins enable rabbitmq_management_agent
    rabbitmq-plugins enable rabbitmq_prometheus
    rabbitmq-plugins enable rabbitmq_shovel
    rabbitmq-plugins enable rabbitmq_shovel_management
    
    # Wait for plugins to activate
    sleep 5
    
    # Create users if they don't exist
    log "Setting up RabbitMQ users..."
    
    # Admin user
    if ! rabbitmqctl list_users | grep -q "^$RABBITMQ_ADMIN_USER"; then
        rabbitmqctl add_user "$RABBITMQ_ADMIN_USER" "$RABBITMQ_ADMIN_PASSWORD"
        rabbitmqctl set_user_tags "$RABBITMQ_ADMIN_USER" administrator
        rabbitmqctl set_permissions -p / "$RABBITMQ_ADMIN_USER" ".*" ".*" ".*"
        log "Created admin user: $RABBITMQ_ADMIN_USER"
    else
        info "Admin user $RABBITMQ_ADMIN_USER already exists"
    fi
    
    # Application user
    if ! rabbitmqctl list_users | grep -q "^$RABBITMQ_USER"; then
        rabbitmqctl add_user "$RABBITMQ_USER" "$RABBITMQ_PASSWORD"
        rabbitmqctl set_permissions -p / "$RABBITMQ_USER" ".*" ".*" ".*"
        log "Created application user: $RABBITMQ_USER"
    else
        info "Application user $RABBITMQ_USER already exists"
        # Update password
        rabbitmqctl change_password "$RABBITMQ_USER" "$RABBITMQ_PASSWORD"
    fi
    
    # Remove default guest user for security
    if rabbitmqctl list_users | grep -q "^guest"; then
        rabbitmqctl delete_user guest
        log "Removed default guest user"
    fi
}

# Create RabbitMQ configuration
create_rabbitmq_config() {
    log "Creating RabbitMQ configuration..."
    
    # Create config directory
    mkdir -p /etc/rabbitmq
    
    # Create main configuration
    cat > /etc/rabbitmq/rabbitmq.conf <<EOF
# RabbitMQ Configuration for Stock Analysis Ecosystem
# Generated on $(date)

# Network Configuration
listeners.tcp.default = 5672
management.tcp.port = 15672
management.tcp.ip = 0.0.0.0

# Memory and Disk Limits
vm_memory_high_watermark.relative = 0.6
vm_memory_high_watermark_paging_ratio = 0.75
disk_free_limit.absolute = 2GB

# Message TTL and Size Limits
message_ttl = 3600000
max_message_size = 134217728

# Heartbeat timeout (60 seconds)
heartbeat = 60

# Frame max
frame_max = 131072

# Channel max
channel_max = 2047

# Connection max
connection_max = infinity

# Default vhost
default_vhost = /

# Default user (disabled)
default_user = none
default_pass = none

# Logging
log.dir = /var/log/rabbitmq
log.file = rabbit.log
log.file.level = info
log.console = false
log.console.level = info

# Clustering (prepared for future use)
cluster_formation.peer_discovery_backend = rabbit_peer_discovery_classic_config
cluster_formation.classic_config.nodes.1 = rabbit@$CONTAINER_HOSTNAME

# Performance tuning
collect_statistics_interval = 10000
management_agent.disable_metrics_collector = false

# Queue and Exchange defaults
default_queue_type = classic
EOF
    
    # Create advanced configuration
    cat > /etc/rabbitmq/advanced.config <<'EOF'
[
  {rabbit, [
    %% Networking
    {tcp_listeners, [5672]},
    {num_tcp_acceptors, 10},
    
    %% Resource limits
    {vm_memory_high_watermark, 0.6},
    {vm_memory_high_watermark_paging_ratio, 0.75},
    {memory_monitor_interval, 2500},
    {disk_free_limit, "2GB"},
    
    %% Message store
    {msg_store_index_module, rabbit_msg_store_ets_index},
    {backing_queue_module, rabbit_variable_queue},
    
    %% Queue settings
    {queue_index_max_journal_entries, 32768},
    {queue_index_embed_msgs_below, 4096},
    
    %% Garbage collection
    {lazy_queue_explicit_gc_run_operation_threshold, 1000},
    {queue_explicit_gc_run_operation_threshold, 1000}
  ]},
  
  {rabbitmq_management, [
    {listener, [{port, 15672}]},
    {load_definitions, "/etc/rabbitmq/definitions.json"}
  ]},
  
  {rabbitmq_prometheus, [
    {tcp_config, [{port, 15692}]}
  ]}
].
EOF
    
    # Create definitions file for exchanges and queues
    cat > /etc/rabbitmq/definitions.json <<EOF
{
  "rabbit_version": "3.12",
  "rabbitmq_version": "3.12",
  "users": [],
  "vhosts": [
    {"name": "/"}
  ],
  "permissions": [],
  "topic_permissions": [],
  "parameters": [],
  "policies": [
    {
      "vhost": "/",
      "name": "event-ttl",
      "pattern": "^event\\\\..*",
      "apply-to": "queues",
      "definition": {
        "message-ttl": 3600000,
        "max-length": 1000000,
        "overflow": "drop-head"
      },
      "priority": 1
    },
    {
      "vhost": "/",
      "name": "dlx-policy",
      "pattern": ".*",
      "apply-to": "queues",
      "definition": {
        "dead-letter-exchange": "dlx.events"
      },
      "priority": 0
    }
  ],
  "queues": [
    {
      "name": "events.analysis",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 3600000,
        "x-max-length": 1000000
      }
    },
    {
      "name": "events.trading",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 3600000,
        "x-max-length": 1000000
      }
    },
    {
      "name": "events.portfolio",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 3600000,
        "x-max-length": 1000000
      }
    },
    {
      "name": "events.system",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 3600000,
        "x-max-length": 1000000
      }
    },
    {
      "name": "dlq.events",
      "vhost": "/",
      "durable": true,
      "auto_delete": false,
      "arguments": {
        "x-message-ttl": 86400000
      }
    }
  ],
  "exchanges": [
    {
      "name": "events",
      "vhost": "/",
      "type": "topic",
      "durable": true,
      "auto_delete": false,
      "internal": false
    },
    {
      "name": "dlx.events",
      "vhost": "/",
      "type": "topic",
      "durable": true,
      "auto_delete": false,
      "internal": false
    }
  ],
  "bindings": [
    {
      "source": "events",
      "vhost": "/",
      "destination": "events.analysis",
      "destination_type": "queue",
      "routing_key": "analysis.*"
    },
    {
      "source": "events",
      "vhost": "/",
      "destination": "events.trading",
      "destination_type": "queue",
      "routing_key": "trading.*"
    },
    {
      "source": "events",
      "vhost": "/",
      "destination": "events.portfolio",
      "destination_type": "queue",
      "routing_key": "portfolio.*"
    },
    {
      "source": "events",
      "vhost": "/",
      "destination": "events.system",
      "destination_type": "queue",
      "routing_key": "system.*"
    },
    {
      "source": "dlx.events",
      "vhost": "/",
      "destination": "dlq.events",
      "destination_type": "queue",
      "routing_key": "#"
    }
  ]
}
EOF
    
    # Set permissions
    chown -R rabbitmq:rabbitmq /etc/rabbitmq
    chmod 644 /etc/rabbitmq/*.conf
    chmod 644 /etc/rabbitmq/*.config
    chmod 644 /etc/rabbitmq/definitions.json
    
    log "RabbitMQ configuration created"
}

# Configure RabbitMQ environment
configure_environment() {
    log "Configuring RabbitMQ environment..."
    
    # Create environment file
    cat > /etc/rabbitmq/rabbitmq-env.conf <<EOF
# RabbitMQ Environment Configuration
RABBITMQ_NODENAME=rabbit@stock-analysis
RABBITMQ_NODE_IP_ADDRESS=0.0.0.0
RABBITMQ_NODE_PORT=5672
RABBITMQ_DIST_PORT=25672
RABBITMQ_MANAGEMENT_PORT=15672

# Erlang VM settings
RABBITMQ_SERVER_ERL_ARGS="+K true +A 128 +P 1048576"

# Logs
RABBITMQ_LOG_BASE=/var/log/rabbitmq
RABBITMQ_LOGS=/var/log/rabbitmq/rabbit.log
RABBITMQ_SASL_LOGS=/var/log/rabbitmq/rabbit-sasl.log

# Memory
RABBITMQ_VM_MEMORY_HIGH_WATERMARK=0.6
EOF
    
    chown rabbitmq:rabbitmq /etc/rabbitmq/rabbitmq-env.conf
    
    log "RabbitMQ environment configured"
}

# Import definitions
import_definitions() {
    log "Importing RabbitMQ definitions..."
    
    # Restart RabbitMQ to apply configuration
    systemctl restart rabbitmq-server
    
    # Wait for RabbitMQ to start
    sleep 10
    
    # Import definitions
    rabbitmqctl import_definitions /etc/rabbitmq/definitions.json
    
    log "RabbitMQ definitions imported"
}

# Create monitoring script
create_monitoring_script() {
    log "Creating RabbitMQ monitoring script..."
    
    cat > /opt/stock-analysis/scripts/monitor-rabbitmq.sh <<'EOF'
#!/bin/bash
# Monitor RabbitMQ health and performance

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "RabbitMQ Status Monitor"
echo "======================="
echo ""

# Check service status
if systemctl is-active --quiet rabbitmq-server; then
    echo -e "${GREEN}✓${NC} RabbitMQ service is running"
else
    echo -e "${RED}✗${NC} RabbitMQ service is not running"
    exit 1
fi

# Get overview
echo ""
echo "Cluster Status:"
rabbitmqctl cluster_status

echo ""
echo "Queue Statistics:"
rabbitmqctl list_queues name messages consumers memory

echo ""
echo "Exchange Statistics:"
rabbitmqctl list_exchanges name type

echo ""
echo "Connection Statistics:"
rabbitmqctl list_connections name peer_host peer_port state

echo ""
echo "Memory Usage:"
rabbitmqctl status | grep -A5 "Memory"

echo ""
echo "Management UI: http://localhost:15672"
echo "Default login: admin / Use configured password"
EOF
    
    chmod +x /opt/stock-analysis/scripts/monitor-rabbitmq.sh
    
    log "RabbitMQ monitoring script created"
}

# Create connection test script
create_test_script() {
    log "Creating RabbitMQ connection test script..."
    
    cat > /opt/stock-analysis/scripts/test-rabbitmq.py <<'EOF'
#!/usr/bin/env python3
"""Test RabbitMQ connection and basic operations"""

import pika
import json
import sys
from datetime import datetime

def test_rabbitmq():
    """Test RabbitMQ connection and event publishing"""
    
    # Connection parameters
    credentials = pika.PlainCredentials('stock_analysis', 'stock_password')
    parameters = pika.ConnectionParameters(
        'localhost',
        5672,
        '/',
        credentials
    )
    
    try:
        # Connect
        connection = pika.BlockingConnection(parameters)
        channel = connection.channel()
        
        print("✓ Connected to RabbitMQ")
        
        # Declare exchange (idempotent)
        channel.exchange_declare(
            exchange='events',
            exchange_type='topic',
            durable=True
        )
        print("✓ Exchange 'events' verified")
        
        # Publish test event
        test_event = {
            'event_type': 'system.test',
            'timestamp': datetime.utcnow().isoformat(),
            'data': {
                'message': 'RabbitMQ test successful',
                'source': 'test-script'
            }
        }
        
        channel.basic_publish(
            exchange='events',
            routing_key='system.test',
            body=json.dumps(test_event),
            properties=pika.BasicProperties(
                delivery_mode=2,  # persistent
                content_type='application/json'
            )
        )
        
        print("✓ Test event published")
        
        # Check queue stats
        queue_stats = channel.queue_declare(
            queue='events.system',
            durable=True,
            passive=True
        )
        
        print(f"✓ Queue 'events.system' has {queue_stats.method.message_count} messages")
        
        # Close connection
        connection.close()
        
        print("\n✅ All RabbitMQ tests passed!")
        return 0
        
    except Exception as e:
        print(f"\n❌ RabbitMQ test failed: {e}")
        return 1

if __name__ == '__main__':
    sys.exit(test_rabbitmq())
EOF
    
    chmod +x /opt/stock-analysis/scripts/test-rabbitmq.py
    
    log "RabbitMQ test script created"
}

# Main setup function
main() {
    log "Starting RabbitMQ Configuration..."
    
    # Check prerequisites
    check_root
    check_rabbitmq
    
    # Configuration steps
    configure_rabbitmq
    create_rabbitmq_config
    configure_environment
    import_definitions
    create_monitoring_script
    create_test_script
    
    log "✅ RabbitMQ configuration completed successfully!"
    echo ""
    echo "RabbitMQ is configured with:"
    echo "- Management UI: http://$CONTAINER_IP:15672"
    echo "- AMQP Port: 5672"
    echo "- Users: admin, stock_analysis"
    echo "- Exchanges: events, dlx.events"
    echo "- Queues: events.analysis, events.trading, events.portfolio, events.system"
    echo ""
    echo "Next steps:"
    echo "1. Test connection: python3 /opt/stock-analysis/scripts/test-rabbitmq.py"
    echo "2. Monitor status: /opt/stock-analysis/scripts/monitor-rabbitmq.sh"
    echo "3. Access management UI: http://$CONTAINER_IP:15672"
}

# Run main function
main "$@"