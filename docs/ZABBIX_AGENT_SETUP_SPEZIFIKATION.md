# 📊 Zabbix-Agent-Setup-Spezifikation - LXC Container Integration

## 🎯 **Übersicht**

**Kontext**: LXC Container (10.1.1.120) mit Zabbix-Server (10.1.1.103) Integration
**Ziel**: Comprehensive Monitoring für Aktienanalyse-Ökosystem ohne separate Monitoring-Stack
**Ansatz**: Native Zabbix-Agent mit Custom-Metrics für Business-Monitoring

---

## 🏗️ **1. ZABBIX-AGENT-INSTALLATION**

### 1.1 **Native Zabbix-Agent2-Installation**
```bash
#!/bin/bash
# scripts/setup-zabbix-agent.sh

set -euo pipefail

ZABBIX_SERVER="10.1.1.103"
HOSTNAME="aktienanalyse-lxc-120"

echo "📊 Installing Zabbix Agent 2 for LXC container..."

# Zabbix Repository hinzufügen
wget -q https://repo.zabbix.com/zabbix/6.4/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo dpkg -i zabbix-release_6.4-1+ubuntu22.04_all.deb
sudo apt update

# Zabbix Agent 2 installieren
sudo apt install -y zabbix-agent2 zabbix-agent2-plugin-*

# Agent-Konfiguration
sudo tee /etc/zabbix/zabbix_agent2.conf <<EOF
# Zabbix Agent 2 Configuration for Aktienanalyse-Ökosystem

# Server-Konfiguration
Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER
Hostname=$HOSTNAME

# Network-Konfiguration
ListenPort=10050
ListenIP=0.0.0.0

# Logging
LogFile=/var/log/zabbix/zabbix_agent2.log
LogFileSize=10
DebugLevel=3

# Performance
Timeout=30
Include=/etc/zabbix/zabbix_agent2.d/*.conf

# Plugins
Plugins.SystemRun.LogRemoteCommands=1
Plugins.Redis.Uri=tcp://localhost:6379
Plugins.Postgres.Uri=postgresql://mdoehler:secure_password@localhost:5432/aktienanalyse_event_store

# Buffer
BufferSend=5
BufferSize=100

# Auto-Registration
ServerActive=$ZABBIX_SERVER
HostMetadata=aktienanalyse,lxc,linux
HostMetadataItem=system.uname
RefreshActiveChecks=60
EOF

# Permissions
sudo chown zabbix:zabbix /etc/zabbix/zabbix_agent2.conf
sudo chmod 644 /etc/zabbix/zabbix_agent2.conf

# Log-Directory
sudo mkdir -p /var/log/zabbix
sudo chown zabbix:zabbix /var/log/zabbix

# Service aktivieren
sudo systemctl enable zabbix-agent2
sudo systemctl start zabbix-agent2

echo "✅ Zabbix Agent 2 installed and configured"
echo "🔗 Server: $ZABBIX_SERVER"
echo "🏷️ Hostname: $HOSTNAME"
```

### 1.2 **Agent-Connectivity-Test**
```bash
#!/bin/bash
# scripts/test-zabbix-connectivity.sh

set -euo pipefail

ZABBIX_SERVER="10.1.1.103"

echo "🔍 Testing Zabbix connectivity..."

# 1. Port-Connectivity zu Zabbix-Server
echo "Testing connection to Zabbix Server..."
if nc -z $ZABBIX_SERVER 10051; then
    echo "✅ Zabbix Server port 10051 reachable"
else
    echo "❌ Zabbix Server port 10051 NOT reachable"
    exit 1
fi

# 2. Zabbix-Agent-Status
echo "Checking Zabbix Agent status..."
if systemctl is-active --quiet zabbix-agent2; then
    echo "✅ Zabbix Agent 2 is running"
else
    echo "❌ Zabbix Agent 2 is NOT running"
    sudo systemctl status zabbix-agent2
    exit 1
fi

# 3. Agent-Port-Test
echo "Testing Zabbix Agent port..."
if nc -z localhost 10050; then
    echo "✅ Zabbix Agent port 10050 listening"
else
    echo "❌ Zabbix Agent port 10050 NOT listening"
    exit 1
fi

# 4. Test-Item von Server abrufen
echo "Testing item retrieval from Zabbix Server..."
response=$(zabbix_get -s localhost -k system.uname 2>/dev/null || echo "FAIL")
if [ "$response" != "FAIL" ]; then
    echo "✅ Test item retrieved: $response"
else
    echo "❌ Failed to retrieve test item"
fi

# 5. Log-Check
echo "Checking agent logs for errors..."
error_count=$(sudo grep -c "ERROR" /var/log/zabbix/zabbix_agent2.log 2>/dev/null || echo "0")
if [ "$error_count" -eq 0 ]; then
    echo "✅ No errors in agent logs"
else
    echo "⚠️ Found $error_count errors in agent logs"
    sudo tail -10 /var/log/zabbix/zabbix_agent2.log
fi

echo "✅ Zabbix connectivity test completed"
```

---

## 📊 **2. BUSINESS-METRICS-INTEGRATION**

### 2.1 **Custom User Parameters für Aktienanalyse**
```conf
# /etc/zabbix/zabbix_agent2.d/aktienanalyse.conf

# System-Services
UserParameter=aktienanalyse.service.status[*],systemctl is-active aktienanalyse-$1 >/dev/null 2>&1 && echo 1 || echo 0
UserParameter=aktienanalyse.service.memory[*],systemctl show aktienanalyse-$1 --property=MemoryCurrent --value 2>/dev/null | awk '{print int($1/1024/1024)}'
UserParameter=aktienanalyse.service.cpu[*],systemctl show aktienanalyse-$1 --property=CPUUsageNSec --value 2>/dev/null

# Port-Monitoring
UserParameter=aktienanalyse.port.listening[*],ss -tlnp | grep ":$1 " >/dev/null 2>&1 && echo 1 || echo 0

# Database-Health
UserParameter=aktienanalyse.db.connection,pg_isready -h localhost -p 5432 -U mdoehler >/dev/null 2>&1 && echo 1 || echo 0
UserParameter=aktienanalyse.db.size,psql -h localhost -U mdoehler -d aktienanalyse_event_store -t -c "SELECT pg_database_size('aktienanalyse_event_store')" 2>/dev/null | tr -d ' '

# Redis-Health
UserParameter=aktienanalyse.redis.ping,redis-cli ping 2>/dev/null | grep PONG >/dev/null && echo 1 || echo 0
UserParameter=aktienanalyse.redis.memory,redis-cli info memory | grep used_memory: | cut -d: -f2 | tr -d '\r'

# Business-Metrics (from Redis)
UserParameter=aktienanalyse.portfolio.value,redis-cli HGET aktienanalyse:metrics portfolio_total_value 2>/dev/null || echo 0
UserParameter=aktienanalyse.trading.orders.active,redis-cli HGET aktienanalyse:metrics active_trading_orders 2>/dev/null || echo 0
UserParameter=aktienanalyse.trading.orders.today,redis-cli HGET aktienanalyse:metrics orders_today 2>/dev/null || echo 0
UserParameter=aktienanalyse.api.calls.bitpanda[*],redis-cli HGET aktienanalyse:api_metrics api_calls_$1_bitpanda_pro 2>/dev/null || echo 0
UserParameter=aktienanalyse.api.success.rate[*],redis-cli HGET aktienanalyse:api_metrics api_success_rate_$1 2>/dev/null || echo 100

# SSL-Certificate-Monitoring
UserParameter=aktienanalyse.ssl.cert.expiry[*],/etc/zabbix/scripts/check_cert_expiry.sh $1
UserParameter=aktienanalyse.ssl.connection[*],/etc/zabbix/scripts/check_ssl_connection.sh $1 $2

# Performance-Metrics
UserParameter=aktienanalyse.performance.query.time,redis-cli HGET aktienanalyse:performance avg_query_time_ms 2>/dev/null || echo 0
UserParameter=aktienanalyse.performance.event.processing,redis-cli HGET aktienanalyse:performance avg_event_processing_ms 2>/dev/null || echo 0

# Log-Analysis
UserParameter=aktienanalyse.logs.errors[*],grep -c "ERROR" /var/log/aktienanalyse/$1.log 2>/dev/null || echo 0
UserParameter=aktienanalyse.logs.warnings[*],grep -c "WARNING" /var/log/aktienanalyse/$1.log 2>/dev/null || echo 0
```

### 2.2 **Custom Monitoring-Scripts**
```bash
#!/bin/bash
# /etc/zabbix/scripts/check_cert_expiry.sh

CERT_PATH=$1
if [ -z "$CERT_PATH" ]; then
    echo "-1"
    exit 1
fi

if [ ! -f "$CERT_PATH" ]; then
    echo "-1"
    exit 1
fi

# Certificate-Ablaufdatum extrahieren
expiry_date=$(openssl x509 -in "$CERT_PATH" -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -z "$expiry_date" ]; then
    echo "-1"
    exit 1
fi

# Tage bis Ablauf berechnen
expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null)
current_epoch=$(date +%s)
days_remaining=$(( (expiry_epoch - current_epoch) / 86400 ))

echo "$days_remaining"
```

```bash
#!/bin/bash
# /etc/zabbix/scripts/check_ssl_connection.sh

HOST=${1:-"localhost"}
PORT=${2:-"443"}

# SSL-Connection-Test
timeout 10 openssl s_client -connect "$HOST:$PORT" -verify_return_error </dev/null >/dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "1"
else
    echo "0"
fi
```

```bash
#!/bin/bash
# /etc/zabbix/scripts/business_metrics_collector.sh

set -euo pipefail

echo "📊 Collecting business metrics for Zabbix..."

# Python-Script für Business-Metrics ausführen
cd /home/mdoehler/aktienanalyse-ökosystem
python3 -c "
import sys
sys.path.append('/home/mdoehler/aktienanalyse-ökosystem')

from shared.monitoring.business_metrics import BusinessMetricsCollector
from shared.monitoring.zabbix_integration import ZabbixMetricsWriter

# Metrics sammeln
collector = BusinessMetricsCollector()
metrics = collector.collect_all_metrics()

# Für Zabbix in Redis schreiben
writer = ZabbixMetricsWriter()
writer.write_metrics(metrics)

print(f'Updated {len(metrics)} business metrics for Zabbix')
"
```

### 2.3 **Business-Metrics-Collector**
```python
# shared/monitoring/business_metrics.py
import redis
import psycopg2
from datetime import datetime, timedelta
from typing import Dict, Any
import json

class BusinessMetricsCollector:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        self.postgres_conn = psycopg2.connect(
            host="localhost",
            database="aktienanalyse_event_store",
            user="mdoehler",
            password="secure_password"
        )
    
    def collect_portfolio_metrics(self) -> Dict[str, Any]:
        """Sammelt Portfolio-relevante Metrics"""
        metrics = {}
        
        try:
            with self.postgres_conn.cursor() as cursor:
                # Gesamtwert Portfolio
                cursor.execute("""
                    SELECT COALESCE(SUM(market_value_eur), 0) as total_value
                    FROM portfolio_holdings_view 
                    WHERE is_active = true
                """)
                total_value = cursor.fetchone()[0]
                metrics['portfolio_total_value'] = float(total_value)
                
                # Anzahl aktive Positionen
                cursor.execute("""
                    SELECT COUNT(*) as active_positions
                    FROM portfolio_holdings_view 
                    WHERE is_active = true AND quantity > 0
                """)
                active_positions = cursor.fetchone()[0]
                metrics['portfolio_active_positions'] = int(active_positions)
                
                # Tagesgewinn/Verlust
                cursor.execute("""
                    SELECT COALESCE(SUM(daily_pnl_eur), 0) as daily_pnl
                    FROM portfolio_performance_view 
                    WHERE date = CURRENT_DATE
                """)
                daily_pnl = cursor.fetchone()[0]
                metrics['portfolio_daily_pnl'] = float(daily_pnl or 0)
                
        except Exception as e:
            logger.error(f"Portfolio metrics collection failed: {str(e)}")
            metrics.update({
                'portfolio_total_value': 0,
                'portfolio_active_positions': 0,
                'portfolio_daily_pnl': 0
            })
        
        return metrics
    
    def collect_trading_metrics(self) -> Dict[str, Any]:
        """Sammelt Trading-relevante Metrics"""
        metrics = {}
        
        try:
            with self.postgres_conn.cursor() as cursor:
                # Aktive Trading-Orders
                cursor.execute("""
                    SELECT COUNT(*) as active_orders
                    FROM trading_orders_view 
                    WHERE status IN ('pending', 'partially_filled')
                """)
                active_orders = cursor.fetchone()[0]
                metrics['active_trading_orders'] = int(active_orders)
                
                # Orders heute
                cursor.execute("""
                    SELECT COUNT(*) as orders_today
                    FROM trading_orders_view 
                    WHERE DATE(created_at) = CURRENT_DATE
                """)
                orders_today = cursor.fetchone()[0]
                metrics['orders_today'] = int(orders_today)
                
                # Erfolgreiche Orders heute
                cursor.execute("""
                    SELECT COUNT(*) as successful_orders
                    FROM trading_orders_view 
                    WHERE DATE(created_at) = CURRENT_DATE 
                    AND status = 'filled'
                """)
                successful_orders = cursor.fetchone()[0]
                metrics['successful_orders_today'] = int(successful_orders)
                
                # Trading-Volumen heute
                cursor.execute("""
                    SELECT COALESCE(SUM(executed_value_eur), 0) as volume_today
                    FROM trading_orders_view 
                    WHERE DATE(created_at) = CURRENT_DATE 
                    AND status = 'filled'
                """)
                volume_today = cursor.fetchone()[0]
                metrics['trading_volume_today'] = float(volume_today or 0)
                
        except Exception as e:
            logger.error(f"Trading metrics collection failed: {str(e)}")
            metrics.update({
                'active_trading_orders': 0,
                'orders_today': 0,
                'successful_orders_today': 0,
                'trading_volume_today': 0
            })
        
        return metrics
    
    def collect_api_metrics(self) -> Dict[str, Any]:
        """Sammelt API-Usage-Metrics"""
        metrics = {}
        
        try:
            # API-Calls heute (aus Redis)
            api_services = ['bitpanda_pro', 'alpha_vantage', 'twelve_data']
            
            for service in api_services:
                # Total Calls
                total_calls = self.redis_client.hget(f'api_metrics:{service}', 'total_calls') or 0
                metrics[f'api_calls_total_{service}'] = int(total_calls)
                
                # Success Rate
                successful_calls = self.redis_client.hget(f'api_metrics:{service}', 'successful_calls') or 0
                total = int(total_calls)
                success_rate = (int(successful_calls) / total * 100) if total > 0 else 100
                metrics[f'api_success_rate_{service}'] = round(success_rate, 2)
                
                # Response Time
                total_response_time = self.redis_client.hget(f'api_metrics:{service}', 'total_response_time') or 0
                avg_response_time = (float(total_response_time) / total * 1000) if total > 0 else 0
                metrics[f'api_response_time_ms_{service}'] = round(avg_response_time, 2)
            
        except Exception as e:
            logger.error(f"API metrics collection failed: {str(e)}")
            for service in ['bitpanda_pro', 'alpha_vantage', 'twelve_data']:
                metrics.update({
                    f'api_calls_total_{service}': 0,
                    f'api_success_rate_{service}': 100,
                    f'api_response_time_ms_{service}': 0
                })
        
        return metrics
    
    def collect_performance_metrics(self) -> Dict[str, Any]:
        """Sammelt Performance-Metrics"""
        metrics = {}
        
        try:
            with self.postgres_conn.cursor() as cursor:
                # Durchschnittliche Query-Zeit (letzte Stunde)
                cursor.execute("""
                    SELECT AVG(EXTRACT(milliseconds FROM duration)) as avg_query_time
                    FROM query_performance_log 
                    WHERE created_at >= NOW() - INTERVAL '1 hour'
                """)
                result = cursor.fetchone()
                avg_query_time = result[0] if result and result[0] else 0
                metrics['avg_query_time_ms'] = round(float(avg_query_time), 2)
                
                # Event-Processing-Zeit
                events_processed = self.redis_client.hget('aktienanalyse:performance', 'events_processed_last_hour') or 0
                processing_time = self.redis_client.hget('aktienanalyse:performance', 'total_processing_time_ms') or 0
                
                avg_event_time = (float(processing_time) / int(events_processed)) if int(events_processed) > 0 else 0
                metrics['avg_event_processing_ms'] = round(avg_event_time, 2)
                
                # Database-Size
                cursor.execute("""
                    SELECT pg_database_size('aktienanalyse_event_store') as db_size
                """)
                db_size = cursor.fetchone()[0]
                metrics['database_size_mb'] = round(int(db_size) / 1024 / 1024, 2)
                
        except Exception as e:
            logger.error(f"Performance metrics collection failed: {str(e)}")
            metrics.update({
                'avg_query_time_ms': 0,
                'avg_event_processing_ms': 0,
                'database_size_mb': 0
            })
        
        return metrics
    
    def collect_system_health_metrics(self) -> Dict[str, Any]:
        """Sammelt System-Health-Metrics"""
        metrics = {}
        
        try:
            # Redis-Memory-Usage
            redis_info = self.redis_client.info('memory')
            redis_memory_mb = redis_info['used_memory'] / 1024 / 1024
            metrics['redis_memory_mb'] = round(redis_memory_mb, 2)
            
            # Redis-Connected-Clients
            redis_clients = redis_info.get('connected_clients', 0)
            metrics['redis_connected_clients'] = int(redis_clients)
            
            # Event-Queue-Size
            queue_size = self.redis_client.llen('event_bus:processing_queue') or 0
            metrics['event_queue_size'] = int(queue_size)
            
            # Error-Count (letzte Stunde)
            error_count = self.redis_client.hget('aktienanalyse:errors', 'last_hour') or 0
            metrics['error_count_last_hour'] = int(error_count)
            
        except Exception as e:
            logger.error(f"System health metrics collection failed: {str(e)}")
            metrics.update({
                'redis_memory_mb': 0,
                'redis_connected_clients': 0,
                'event_queue_size': 0,
                'error_count_last_hour': 0
            })
        
        return metrics
    
    def collect_all_metrics(self) -> Dict[str, Any]:
        """Sammelt alle Business-Metrics"""
        all_metrics = {}
        
        # Alle Metric-Kategorien sammeln
        all_metrics.update(self.collect_portfolio_metrics())
        all_metrics.update(self.collect_trading_metrics())
        all_metrics.update(self.collect_api_metrics())
        all_metrics.update(self.collect_performance_metrics())
        all_metrics.update(self.collect_system_health_metrics())
        
        # Timestamp hinzufügen
        all_metrics['last_updated'] = datetime.utcnow().isoformat()
        all_metrics['collection_timestamp'] = int(datetime.utcnow().timestamp())
        
        return all_metrics

# Zabbix-Metrics-Writer
class ZabbixMetricsWriter:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        self.metrics_key = 'aktienanalyse:metrics'
    
    def write_metrics(self, metrics: Dict[str, Any]):
        """Schreibt Metrics für Zabbix-Abfrage in Redis"""
        
        # Alle Metrics in Redis-Hash schreiben
        for metric_name, value in metrics.items():
            self.redis_client.hset(self.metrics_key, metric_name, value)
        
        # TTL setzen (5 Minuten)
        self.redis_client.expire(self.metrics_key, 300)
        
        logger.info(f"Updated {len(metrics)} metrics for Zabbix in Redis")
```

---

## ⏰ **3. AUTOMATED METRICS-COLLECTION**

### 3.1 **Cron-Job für Metrics-Collection**
```bash
# /etc/cron.d/aktienanalyse-metrics
# Sammelt Business-Metrics alle 5 Minuten für Zabbix

*/5 * * * * mdoehler /etc/zabbix/scripts/business_metrics_collector.sh >/dev/null 2>&1

# SSL-Certificate-Check täglich um 06:00
0 6 * * * mdoehler /etc/zabbix/scripts/check_all_certificates.sh >/dev/null 2>&1

# Log-Cleanup wöchentlich
0 2 * * 0 root find /var/log/aktienanalyse -name "*.log" -mtime +30 -delete
```

### 3.2 **systemd-Timer für Metrics (Alternative)**
```ini
# /etc/systemd/system/aktienanalyse-metrics.timer
[Unit]
Description=Aktienanalyse Business Metrics Collection Timer
Requires=aktienanalyse-metrics.service

[Timer]
OnCalendar=*:0/5  # Alle 5 Minuten
Persistent=true

[Install]
WantedBy=timers.target
```

```ini
# /etc/systemd/system/aktienanalyse-metrics.service
[Unit]
Description=Aktienanalyse Business Metrics Collection
After=network.target redis.service postgresql.service

[Service]
Type=oneshot
User=mdoehler
Group=mdoehler
WorkingDirectory=/home/mdoehler/aktienanalyse-ökosystem
Environment=PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem
ExecStart=/usr/bin/python3 -c "from shared.monitoring.business_metrics import BusinessMetricsCollector, ZabbixMetricsWriter; collector = BusinessMetricsCollector(); metrics = collector.collect_all_metrics(); writer = ZabbixMetricsWriter(); writer.write_metrics(metrics)"

# Security
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/mdoehler/aktienanalyse-ökosystem
```

---

## 🚨 **4. ALERTING-KONFIGURATION**

### 4.1 **Critical Business-Alerts**
```python
# shared/monitoring/alert_thresholds.py

ALERT_THRESHOLDS = {
    # Portfolio-Alerts
    'portfolio_daily_loss_critical': -1000.0,  # €1000 Tagesverlust
    'portfolio_daily_loss_warning': -500.0,   # €500 Tagesverlust
    'portfolio_total_value_drop': 0.05,       # 5% Portfoliowert-Rückgang
    
    # Trading-Alerts
    'trading_order_failure_rate': 0.10,       # >10% fehlgeschlagene Orders
    'trading_volume_anomaly': 10000.0,        # >€10k ungewöhnliches Volumen
    'active_orders_threshold': 50,            # >50 aktive Orders
    
    # API-Alerts
    'api_success_rate_critical': 50.0,        # <50% Success-Rate
    'api_success_rate_warning': 80.0,         # <80% Success-Rate
    'api_response_time_critical': 5000.0,     # >5s Response-Time
    'api_calls_quota_warning': 0.90,          # 90% Quota erreicht
    
    # Performance-Alerts
    'query_time_critical': 1000.0,            # >1s Query-Time
    'event_processing_critical': 500.0,       # >500ms Event-Processing
    'database_size_warning': 10240.0,         # >10GB Database-Size
    
    # System-Health-Alerts
    'redis_memory_critical': 1024.0,          # >1GB Redis-Memory
    'event_queue_size_critical': 1000,        # >1000 Events in Queue
    'error_count_critical': 50,               # >50 Errors/Stunde
    
    # Security-Alerts
    'ssl_cert_expiry_critical': 7,            # <7 Tage bis Ablauf
    'ssl_cert_expiry_warning': 30,            # <30 Tage bis Ablauf
    'service_down_critical': 0,               # Service nicht erreichbar
}

class AlertManager:
    def __init__(self):
        self.redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
        self.thresholds = ALERT_THRESHOLDS
    
    def check_all_thresholds(self) -> List[dict]:
        """Prüft alle Alert-Thresholds und gibt Alerts zurück"""
        alerts = []
        
        # Aktuelle Metrics laden
        current_metrics = self.redis_client.hgetall('aktienanalyse:metrics')
        
        # Portfolio-Alerts
        daily_pnl = float(current_metrics.get('portfolio_daily_pnl', 0))
        if daily_pnl <= self.thresholds['portfolio_daily_loss_critical']:
            alerts.append({
                'severity': 'critical',
                'type': 'portfolio',
                'message': f'Critical daily loss: €{daily_pnl:,.2f}',
                'value': daily_pnl,
                'threshold': self.thresholds['portfolio_daily_loss_critical']
            })
        elif daily_pnl <= self.thresholds['portfolio_daily_loss_warning']:
            alerts.append({
                'severity': 'warning',
                'type': 'portfolio',
                'message': f'Daily loss warning: €{daily_pnl:,.2f}',
                'value': daily_pnl,
                'threshold': self.thresholds['portfolio_daily_loss_warning']
            })
        
        # API-Success-Rate-Alerts
        for service in ['bitpanda_pro', 'alpha_vantage']:
            success_rate = float(current_metrics.get(f'api_success_rate_{service}', 100))
            if success_rate <= self.thresholds['api_success_rate_critical']:
                alerts.append({
                    'severity': 'critical',
                    'type': 'api',
                    'message': f'{service} API success rate critical: {success_rate}%',
                    'value': success_rate,
                    'threshold': self.thresholds['api_success_rate_critical']
                })
        
        # Performance-Alerts
        query_time = float(current_metrics.get('avg_query_time_ms', 0))
        if query_time >= self.thresholds['query_time_critical']:
            alerts.append({
                'severity': 'critical',
                'type': 'performance',
                'message': f'Query time critical: {query_time}ms',
                'value': query_time,
                'threshold': self.thresholds['query_time_critical']
            })
        
        return alerts
    
    def send_alerts_to_zabbix(self, alerts: List[dict]):
        """Sendet Alerts an Zabbix"""
        for alert in alerts:
            alert_key = f"alert:{alert['type']}:{alert['severity']}"
            alert_data = {
                'timestamp': datetime.utcnow().isoformat(),
                'message': alert['message'],
                'value': alert['value'],
                'threshold': alert['threshold']
            }
            
            # Alert in Redis für Zabbix speichern
            self.redis_client.hset('aktienanalyse:alerts', alert_key, json.dumps(alert_data))
            self.redis_client.expire('aktienanalyse:alerts', 3600)  # 1 Stunde TTL
```

### 4.2 **Zabbix-Alert-Integration**
```conf
# /etc/zabbix/zabbix_agent2.d/aktienanalyse_alerts.conf

# Business-Alerts
UserParameter=aktienanalyse.alert.portfolio.critical,redis-cli HGET aktienanalyse:alerts "alert:portfolio:critical" 2>/dev/null | jq -r '.value // 0' 2>/dev/null || echo 0
UserParameter=aktienanalyse.alert.api.critical,redis-cli HGET aktienanalyse:alerts "alert:api:critical" 2>/dev/null | jq -r '.value // 0' 2>/dev/null || echo 0
UserParameter=aktienanalyse.alert.performance.critical,redis-cli HGET aktienanalyse:alerts "alert:performance:critical" 2>/dev/null | jq -r '.value // 0' 2>/dev/null || echo 0

# Service-Health
UserParameter=aktienanalyse.health.overall,/etc/zabbix/scripts/overall_health_check.sh
```

```bash
#!/bin/bash
# /etc/zabbix/scripts/overall_health_check.sh

# Overall Health-Score (0-100)
score=100

# Service-Checks
services=("aktienanalyse-frontend" "aktienanalyse-core" "aktienanalyse-broker")
for service in "${services[@]}"; do
    if ! systemctl is-active --quiet "$service"; then
        score=$((score - 20))
    fi
done

# Database-Check
if ! pg_isready -h localhost -p 5432 -U mdoehler >/dev/null 2>&1; then
    score=$((score - 15))
fi

# Redis-Check
if ! redis-cli ping >/dev/null 2>&1; then
    score=$((score - 15))
fi

# Portfolio-Value-Check (kritischer Verlust)
daily_pnl=$(redis-cli HGET aktienanalyse:metrics portfolio_daily_pnl 2>/dev/null || echo 0)
if (( $(echo "$daily_pnl < -1000" | bc -l) )); then
    score=$((score - 20))
fi

echo "$score"
```

---

## ✅ **5. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Zabbix-Agent-Installation (1 Tag)**
- [ ] Zabbix-Agent2 auf LXC Container installieren
- [ ] Agent-Konfiguration für Zabbix-Server (10.1.1.103)
- [ ] Connectivity-Tests durchführen
- [ ] Basic System-Monitoring verifizieren

### **Phase 2: Business-Metrics-Integration (2 Tage)**
- [ ] Custom User Parameters für Aktienanalyse konfigurieren
- [ ] Business-Metrics-Collector implementieren
- [ ] Automated Metrics-Collection-Jobs einrichten
- [ ] Redis-Integration für Metric-Storage

### **Phase 3: Custom-Scripts und Monitoring (1 Tag)**
- [ ] SSL-Certificate-Monitoring-Scripts erstellen
- [ ] Service-Health-Check-Scripts entwickeln
- [ ] Performance-Monitoring-Integration
- [ ] Log-Analysis-Tools implementieren

### **Phase 4: Alerting und Fine-Tuning (1 Tag)**
- [ ] Alert-Thresholds definieren und konfigurieren
- [ ] Critical Business-Alerts einrichten
- [ ] Overall Health-Score-System implementieren
- [ ] Monitoring-Dashboard-Integration testen

**Gesamtaufwand**: 5 Tage
**Abhängigkeiten**: Zabbix-Server (10.1.1.103), Redis, PostgreSQL

Diese Spezifikation bietet **comprehensive Business-Monitoring** mit Zabbix-Integration für das Aktienanalyse-Ökosystem ohne separaten Monitoring-Stack.