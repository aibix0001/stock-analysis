# 📚 Stock Analysis Ecosystem - Operations Guide

## 🎯 Overview

This guide provides operational procedures for managing the Stock Analysis Ecosystem in a production environment.

## 🏗️ Infrastructure Overview

### Architecture
- **5 Microservices** running as systemd services
- **PostgreSQL 15** Event Store with materialized views
- **Redis** for event bus and caching
- **RabbitMQ** for reliable message queuing
- **Native LXC** container deployment

### Service Ports
| Service | Port | Description |
|---------|------|-------------|
| Intelligent Core | 8001 | Analysis and ML engine |
| Broker Gateway | 8002 | Trading integration |
| Event Bus | 8003 | Event routing |
| Monitoring | 8004 | System monitoring |
| Frontend | 8005 | Web API backend |
| PostgreSQL | 5432 | Event store database |
| Redis | 6379 | Cache and pub/sub |
| RabbitMQ | 5672 | Message queue |
| RabbitMQ Mgmt | 15672 | Management UI |

## 🚀 Startup Procedures

### 1. System Startup Order

```bash
# 1. Verify infrastructure services
systemctl status postgresql
systemctl status redis-server
systemctl status rabbitmq-server

# 2. Start infrastructure if needed
systemctl start postgresql redis-server rabbitmq-server

# 3. Initialize databases (first time only)
/opt/stock-analysis/scripts/init-databases.sh

# 4. Start microservices in order
systemctl start stock-analysis-event-bus-service
systemctl start stock-analysis-intelligent-core-service
systemctl start stock-analysis-broker-gateway-service
systemctl start stock-analysis-monitoring-service
systemctl start stock-analysis-frontend-service

# 5. Verify all services
systemctl status 'stock-analysis-*'
```

### 2. Health Verification

```bash
# Run health check tests
/opt/stock-analysis/scripts/test-all-health-checks.sh

# Check service logs
journalctl -u stock-analysis-intelligent-core-service -n 50
```

## 🛑 Shutdown Procedures

### Graceful Shutdown

```bash
# 1. Stop services in reverse order
systemctl stop stock-analysis-frontend-service
systemctl stop stock-analysis-monitoring-service
systemctl stop stock-analysis-broker-gateway-service
systemctl stop stock-analysis-intelligent-core-service
systemctl stop stock-analysis-event-bus-service

# 2. Wait for graceful termination
sleep 10

# 3. Stop infrastructure (if needed)
systemctl stop rabbitmq-server redis-server postgresql
```

### Emergency Shutdown

```bash
# Force stop all services
systemctl stop 'stock-analysis-*'

# Kill any remaining processes
pkill -f "stock-analysis"
```

## 📊 Monitoring

### Service Health

```bash
# Check all service health endpoints
for port in 8001 8002 8003 8004 8005; do
    echo "Service on port $port:"
    curl -s "http://localhost:$port/health" | jq .
done
```

### Database Monitoring

```bash
# PostgreSQL status
sudo -u postgres psql -c "SELECT count(*) FROM events;"
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('aktienanalyse_event_store'));"

# Redis status
redis-cli info stats
redis-cli info memory

# RabbitMQ status
rabbitmqctl list_queues name messages consumers
/opt/stock-analysis/scripts/monitor-rabbitmq.sh
```

### Performance Metrics

```bash
# Check query performance
sudo -u postgres psql aktienanalyse_event_store -c "
SELECT query, mean_exec_time, calls 
FROM pg_stat_statements 
WHERE mean_exec_time > 100 
ORDER BY mean_exec_time DESC 
LIMIT 10;"

# System resources
htop
iotop -o
```

## 🔧 Maintenance Tasks

### Daily Tasks

1. **Check Service Health**
   ```bash
   systemctl status 'stock-analysis-*' --no-pager
   ```

2. **Review Logs**
   ```bash
   journalctl --since "1 day ago" -u 'stock-analysis-*' | grep -E "ERROR|CRITICAL"
   ```

3. **Check Disk Space**
   ```bash
   df -h /opt/stock-analysis
   du -sh /var/log/stock-analysis/*
   ```

### Weekly Tasks

1. **Database Maintenance**
   ```bash
   # Vacuum and analyze
   sudo -u postgres vacuumdb -z aktienanalyse_event_store
   
   # Refresh materialized views
   sudo -u postgres psql aktienanalyse_event_store -c "
   REFRESH MATERIALIZED VIEW CONCURRENTLY stock_analysis_unified;
   REFRESH MATERIALIZED VIEW CONCURRENTLY portfolio_unified;
   REFRESH MATERIALIZED VIEW CONCURRENTLY trading_activity_unified;
   REFRESH MATERIALIZED VIEW CONCURRENTLY system_health_unified;"
   ```

2. **Backup Databases**
   ```bash
   /opt/stock-analysis/scripts/backup-databases.sh
   ```

3. **Log Rotation**
   ```bash
   logrotate -f /etc/logrotate.d/stock-analysis
   ```

### Monthly Tasks

1. **Update Dependencies**
   ```bash
   # Update Python packages
   cd /opt/stock-analysis
   for service in venvs/*; do
       $service/bin/pip list --outdated
   done
   ```

2. **Security Updates**
   ```bash
   apt update && apt list --upgradable
   ```

3. **Performance Review**
   - Analyze slow queries
   - Review system metrics trends
   - Optimize indexes if needed

## 🚨 Troubleshooting

### Service Won't Start

1. **Check Logs**
   ```bash
   journalctl -xe -u stock-analysis-SERVICE_NAME
   ```

2. **Verify Dependencies**
   ```bash
   systemctl is-active postgresql redis-server rabbitmq-server
   ```

3. **Check Port Conflicts**
   ```bash
   netstat -tlnp | grep -E "8001|8002|8003|8004|8005"
   ```

4. **Test Manually**
   ```bash
   cd /opt/stock-analysis/services/SERVICE_NAME
   /opt/stock-analysis/venvs/SERVICE_NAME/bin/python -m main
   ```

### Database Issues

1. **Connection Failed**
   ```bash
   # Test connection
   psql -h localhost -U stock_analysis -d aktienanalyse_event_store
   
   # Check pg_hba.conf
   cat /etc/postgresql/15/main/pg_hba.conf | grep stock_analysis
   ```

2. **Slow Queries**
   ```bash
   # Enable query logging
   sudo -u postgres psql -c "SET log_min_duration_statement = 100;"
   
   # Check slow queries
   tail -f /var/log/postgresql/postgresql-15-main.log | grep duration
   ```

### Message Queue Issues

1. **RabbitMQ Not Processing**
   ```bash
   # Check queue status
   rabbitmqctl list_queues name messages_ready messages_unacknowledged
   
   # Purge queue if needed
   rabbitmqctl purge_queue QUEUE_NAME
   ```

2. **Redis Connection Issues**
   ```bash
   # Test connection
   redis-cli ping
   
   # Check memory usage
   redis-cli info memory | grep used_memory_human
   ```

## 📈 Performance Tuning

### PostgreSQL Optimization

```bash
# Analyze query performance
sudo -u postgres psql aktienanalyse_event_store -c "EXPLAIN ANALYZE SELECT ...;"

# Update statistics
sudo -u postgres psql aktienanalyse_event_store -c "ANALYZE;"

# Check index usage
sudo -u postgres psql aktienanalyse_event_store -c "
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
ORDER BY idx_scan;"
```

### Service Optimization

1. **Increase Worker Processes**
   - Edit service files in `/etc/systemd/system/`
   - Adjust `Environment="WORKERS=4"`

2. **Memory Limits**
   - Update `MemoryLimit=2G` in service files
   - Monitor with `systemctl status SERVICE --no-pager`

## 🔒 Security Procedures

### Regular Security Tasks

1. **Update Passwords**
   ```bash
   # PostgreSQL
   sudo -u postgres psql -c "ALTER USER stock_analysis PASSWORD 'new_password';"
   
   # RabbitMQ
   rabbitmqctl change_password stock_analysis new_password
   ```

2. **Review Access Logs**
   ```bash
   grep "authentication" /var/log/postgresql/*.log
   tail -f /var/log/nginx/access.log
   ```

3. **Certificate Management**
   ```bash
   # Check certificate expiry
   openssl x509 -in /etc/ssl/certs/stock-analysis.crt -noout -dates
   ```

## 📝 Backup and Recovery

### Backup Procedures

```bash
# Full system backup
/opt/stock-analysis/scripts/backup-databases.sh

# Service configuration backup
tar -czf /backup/stock-analysis-config-$(date +%Y%m%d).tar.gz \
    /etc/systemd/system/stock-analysis-* \
    /etc/stock-analysis/ \
    /opt/stock-analysis/config/
```

### Recovery Procedures

1. **Database Recovery**
   ```bash
   # Stop services
   systemctl stop 'stock-analysis-*'
   
   # Restore PostgreSQL
   psql -U postgres -c "DROP DATABASE IF EXISTS aktienanalyse_event_store;"
   psql -U postgres -c "CREATE DATABASE aktienanalyse_event_store OWNER stock_analysis;"
   psql -U stock_analysis aktienanalyse_event_store < backup.sql
   
   # Restore Redis
   systemctl stop redis-server
   cp backup/dump.rdb /var/lib/redis/
   systemctl start redis-server
   ```

2. **Service Recovery**
   ```bash
   # Restore configuration
   tar -xzf stock-analysis-config-backup.tar.gz -C /
   
   # Reload systemd
   systemctl daemon-reload
   
   # Start services
   systemctl start 'stock-analysis-*'
   ```

## 📞 Support Information

### Log Locations
- Service logs: `journalctl -u stock-analysis-*`
- PostgreSQL: `/var/log/postgresql/`
- Redis: `/var/log/redis/`
- RabbitMQ: `/var/log/rabbitmq/`
- Application: `/var/log/stock-analysis/`

### Configuration Files
- Services: `/etc/systemd/system/stock-analysis-*.service`
- Environment: `/etc/stock-analysis/environment`
- Database: `/etc/postgresql/15/main/`
- Redis: `/etc/redis/redis.conf`
- RabbitMQ: `/etc/rabbitmq/`

### Useful Commands
```bash
# Show all stock-analysis processes
ps aux | grep stock-analysis

# Show service dependencies
systemctl list-dependencies stock-analysis-intelligent-core-service

# Export service logs
journalctl -u 'stock-analysis-*' --since "2024-01-01" > service-logs.txt

# Database connection pool stats
sudo -u postgres psql aktienanalyse_event_store -c "SELECT * FROM pg_stat_activity WHERE application_name LIKE 'stock%';"
```