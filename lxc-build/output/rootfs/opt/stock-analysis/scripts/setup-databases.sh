#!/bin/bash
# Database setup script
set -euo pipefail

echo "Setting up databases..."

# PostgreSQL setup
echo "Installing PostgreSQL 15..."
sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -
apt-get update
apt-get install -y postgresql-15 postgresql-contrib-15

# Configure PostgreSQL
echo "Configuring PostgreSQL..."
systemctl stop postgresql
cat > /etc/postgresql/15/main/postgresql.conf << PGCONF
# PostgreSQL configuration for Stock Analysis
listen_addresses = 'localhost'
port = 5432
max_connections = 100
shared_buffers = 256MB
effective_cache_size = 1GB
maintenance_work_mem = 64MB
checkpoint_completion_target = 0.9
wal_buffers = 16MB
default_statistics_target = 100
random_page_cost = 1.1
effective_io_concurrency = 200
work_mem = 4MB
min_wal_size = 1GB
max_wal_size = 4GB
PGCONF

# Create database and user
systemctl start postgresql
sudo -u postgres psql << SQL
CREATE USER stock_analysis_user WITH PASSWORD 'changeme';
CREATE DATABASE stock_analysis_event_store OWNER stock_analysis_user;
GRANT ALL PRIVILEGES ON DATABASE stock_analysis_event_store TO stock_analysis_user;
SQL

# Redis setup
echo "Installing Redis..."
apt-get install -y redis-server

# Configure Redis cluster
echo "Configuring Redis..."
for port in 6379 6380 6381; do
    mkdir -p /etc/redis/cluster-$port
    cat > /etc/redis/cluster-$port/redis.conf << REDISCONF
port $port
cluster-enabled yes
cluster-config-file nodes-$port.conf
cluster-node-timeout 5000
appendonly yes
appendfilename "appendonly-$port.aof"
dir /var/lib/redis/cluster-$port
bind 127.0.0.1
protected-mode yes
requirepass changeme
masterauth changeme
REDISCONF
    
    mkdir -p /var/lib/redis/cluster-$port
    chown redis:redis /var/lib/redis/cluster-$port
done

# RabbitMQ setup
echo "Installing RabbitMQ..."
apt-get install -y rabbitmq-server

# Configure RabbitMQ
echo "Configuring RabbitMQ..."
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl add_user stock_analysis changeme
rabbitmqctl add_vhost /stock-analysis
rabbitmqctl set_permissions -p /stock-analysis stock_analysis ".*" ".*" ".*"
rabbitmqctl set_user_tags stock_analysis administrator

echo "Database setup completed!"
