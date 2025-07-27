# 🚀 Performance & Scaling-Strategien - Vollständige Spezifikation

## 🎯 **Übersicht**

**Kontext**: Performance-Optimierung und Scaling-Strategien für aktienanalyse-ökosystem  
**Ziel**: Hochperformante, skalierbare Architektur für alle Service-Komponenten  
**Ansatz**: Native systemd-Services + Redis-Caching + Database-Tuning + Auto-Scaling  

---

## 📊 **1. PERFORMANCE-BENCHMARKS & BASELINE-MEASUREMENTS**

### 1.1 Service Performance Baselines

```yaml
# /opt/aktienanalyse-ökosystem/config/performance_baselines.yaml
"""Performance Baseline-Definitionen für alle Services"""

performance_baselines:
  # Aktienanalyse Core Service
  aktienanalyse_core:
    service_name: "Aktienanalyse Intelligent Core Service"
    baseline_date: "2024-01-15"
    
    response_times:
      portfolio_calculation:
        target_p50: 150    # 50% der Requests < 150ms
        target_p95: 500    # 95% der Requests < 500ms
        target_p99: 2000   # 99% der Requests < 2s
        current_p50: 120
        current_p95: 450
        current_p99: 1800
      
      risk_assessment:
        target_p50: 100
        target_p95: 300
        target_p99: 1000
        current_p50: 85
        current_p95: 280
        current_p99: 950
      
      api_endpoints:
        "/api/portfolios":
          target_p95: 200
          current_p95: 180
        "/api/assets":
          target_p95: 100
          current_p95: 85
        "/api/trades":
          target_p95: 300
          current_p95: 250
    
    throughput:
      requests_per_second:
        target_sustained: 500
        target_peak: 1000
        current_sustained: 420
        current_peak: 850
      
      concurrent_users:
        target_max: 100
        current_max: 75
    
    resource_utilization:
      cpu_usage:
        target_avg: 40      # % CPU average
        target_peak: 80     # % CPU peak
        current_avg: 35
        current_peak: 70
      
      memory_usage:
        target_avg: 512     # MB average
        target_peak: 1024   # MB peak
        current_avg: 450
        current_peak: 900
      
      database_connections:
        target_avg: 10
        target_peak: 25
        current_avg: 8
        current_peak: 20

  # Broker Gateway Service
  aktienanalyse_broker:
    service_name: "Broker Gateway Service"
    baseline_date: "2024-01-15"
    
    response_times:
      order_execution:
        target_p50: 1000   # Externe API-Abhängigkeit
        target_p95: 3000
        target_p99: 8000
        current_p50: 900
        current_p95: 2800
        current_p99: 7500
      
      market_data_fetch:
        target_p50: 500
        target_p95: 1500
        target_p99: 4000
        current_p50: 450
        current_p95: 1400
        current_p99: 3800
    
    throughput:
      api_calls_per_minute:
        target_sustained: 300
        target_peak: 600
        current_sustained: 280
        current_peak: 550
      
      order_processing:
        target_orders_per_hour: 1000
        current_orders_per_hour: 850
    
    reliability:
      success_rate:
        target: 98.5        # % (externe API-Abhängigkeiten)
        current: 97.8
      
      retry_success_rate:
        target: 95.0
        current: 94.2

  # Event Bus Service
  aktienanalyse_events:
    service_name: "Event Bus Service"
    baseline_date: "2024-01-15"
    
    event_processing:
      processing_latency:
        target_p50: 10     # ms
        target_p95: 50
        target_p99: 200
        current_p50: 8
        current_p95: 45
        current_p99: 180
      
      queue_lag:
        target_avg: 100    # ms
        target_peak: 1000
        current_avg: 85
        current_peak: 900
      
      throughput:
        events_per_second:
          target_sustained: 1000
          target_peak: 5000
          current_sustained: 850
          current_peak: 4200
        
        message_size:
          target_avg: 512    # bytes
          target_max: 1024
          current_avg: 480
          current_max: 950

  # Database Performance
  database_performance:
    connection_pool:
      min_connections: 5
      max_connections: 50
      target_avg_usage: 15
      current_avg_usage: 12
    
    query_performance:
      portfolio_queries:
        target_p95: 50     # ms
        current_p95: 45
      
      event_store_reads:
        target_p95: 25
        current_p95: 22
      
      materialized_view_refresh:
        target_duration: 30000  # ms
        current_duration: 28000
    
    storage:
      database_size:
        current_gb: 2.5
        projected_6m_gb: 15
        projected_1y_gb: 30
      
      index_efficiency:
        target_hit_ratio: 99.0  # %
        current_hit_ratio: 98.5

  # Redis Cache Performance
  redis_performance:
    cache_hit_ratios:
      portfolio_data:
        target: 85         # %
        current: 82
      
      market_data:
        target: 95
        current: 93
      
      user_sessions:
        target: 98
        current: 97
    
    memory_usage:
      target_utilization: 70  # %
      current_utilization: 65
      
      eviction_rate:
        target_per_hour: 100
        current_per_hour: 85
    
    response_times:
      get_operations:
        target_p95: 1      # ms
        current_p95: 0.8
      
      set_operations:
        target_p95: 2
        current_p95: 1.8

# Load Testing Configurations
load_testing:
  scenarios:
    normal_load:
      duration: "10m"
      virtual_users: 50
      ramp_up: "2m"
      requests_per_second: 100
      
    peak_load:
      duration: "5m"
      virtual_users: 200
      ramp_up: "1m"
      requests_per_second: 500
      
    stress_test:
      duration: "15m"
      virtual_users: 500
      ramp_up: "3m"
      requests_per_second: 1000
      
    endurance_test:
      duration: "2h"
      virtual_users: 100
      ramp_up: "5m"
      requests_per_second: 200

  test_data:
    portfolios: 1000
    assets: 500
    trades_per_portfolio: 100
    users: 100
    
  monitoring_during_tests:
    metrics_interval: 5     # seconds
    cpu_threshold: 90       # %
    memory_threshold: 90    # %
    response_time_threshold: 5000  # ms
```

### 1.2 Performance Monitoring Service

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/performance_monitor.py
"""Performance Monitoring und Baseline-Tracking"""

import asyncio
import json
import statistics
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass
import aiohttp
import psutil

@dataclass
class PerformanceMetric:
    """Performance Metric Definition"""
    name: str
    value: float
    unit: str
    timestamp: datetime
    service: str
    baseline_value: Optional[float] = None
    threshold_warning: Optional[float] = None
    threshold_critical: Optional[float] = None
    
    @property
    def baseline_deviation(self) -> Optional[float]:
        if self.baseline_value:
            return ((self.value - self.baseline_value) / self.baseline_value) * 100
        return None
    
    @property
    def status(self) -> str:
        if self.threshold_critical and self.value > self.threshold_critical:
            return "critical"
        elif self.threshold_warning and self.value > self.threshold_warning:
            return "warning"
        return "ok"

class PerformanceCollector:
    """Performance Metrics Collector"""
    
    def __init__(self, config):
        self.config = config
        self.baseline_config = config.performance_baselines
        self.metrics_history: List[PerformanceMetric] = []
        self.logger = logging.getLogger("performance_collector")
    
    async def collect_system_metrics(self) -> List[PerformanceMetric]:
        """System-Performance-Metriken sammeln"""
        timestamp = datetime.utcnow()
        metrics = []
        
        # CPU Metrics
        cpu_percent = psutil.cpu_percent(interval=1)
        cpu_cores = psutil.cpu_count()
        
        metrics.append(PerformanceMetric(
            name="system.cpu.utilization",
            value=cpu_percent,
            unit="percent",
            timestamp=timestamp,
            service="system",
            baseline_value=self.baseline_config.get("system", {}).get("cpu_avg", 40),
            threshold_warning=80,
            threshold_critical=95
        ))
        
        # Memory Metrics
        memory = psutil.virtual_memory()
        metrics.append(PerformanceMetric(
            name="system.memory.utilization",
            value=memory.percent,
            unit="percent",
            timestamp=timestamp,
            service="system",
            baseline_value=50,
            threshold_warning=80,
            threshold_critical=95
        ))
        
        # Disk I/O Metrics
        disk_io = psutil.disk_io_counters()
        if disk_io:
            metrics.extend([
                PerformanceMetric(
                    name="system.disk.read_bytes_per_sec",
                    value=disk_io.read_bytes / 1024 / 1024,  # MB/s
                    unit="MB/s",
                    timestamp=timestamp,
                    service="system"
                ),
                PerformanceMetric(
                    name="system.disk.write_bytes_per_sec",
                    value=disk_io.write_bytes / 1024 / 1024,  # MB/s
                    unit="MB/s",
                    timestamp=timestamp,
                    service="system"
                )
            ])
        
        # Network I/O Metrics
        network_io = psutil.net_io_counters()
        if network_io:
            metrics.extend([
                PerformanceMetric(
                    name="system.network.bytes_sent_per_sec",
                    value=network_io.bytes_sent / 1024 / 1024,  # MB/s
                    unit="MB/s",
                    timestamp=timestamp,
                    service="system"
                ),
                PerformanceMetric(
                    name="system.network.bytes_recv_per_sec",
                    value=network_io.bytes_recv / 1024 / 1024,  # MB/s
                    unit="MB/s",
                    timestamp=timestamp,
                    service="system"
                )
            ])
        
        return metrics
    
    async def collect_service_metrics(self, service_name: str) -> List[PerformanceMetric]:
        """Service-spezifische Performance-Metriken sammeln"""
        timestamp = datetime.utcnow()
        metrics = []
        
        try:
            # Service Health Endpoint aufrufen
            async with aiohttp.ClientSession() as session:
                health_url = f"http://localhost:{self.config.services[service_name].port}/health"
                
                start_time = datetime.utcnow()
                async with session.get(health_url, timeout=aiohttp.ClientTimeout(total=5)) as response:
                    response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
                    
                    metrics.append(PerformanceMetric(
                        name=f"{service_name}.health_check.response_time",
                        value=response_time,
                        unit="ms",
                        timestamp=timestamp,
                        service=service_name,
                        baseline_value=self.baseline_config.get(service_name, {}).get("health_check_baseline", 50),
                        threshold_warning=200,
                        threshold_critical=1000
                    ))
                    
                    if response.status == 200:
                        health_data = await response.json()
                        
                        # Service-spezifische Metriken aus Health Response extrahieren
                        for metric_name, value in health_data.get("metrics", {}).items():
                            metrics.append(PerformanceMetric(
                                name=f"{service_name}.{metric_name}",
                                value=value,
                                unit="",
                                timestamp=timestamp,
                                service=service_name
                            ))
        
        except Exception as e:
            self.logger.error(f"Error collecting metrics for {service_name}: {e}")
            
            # Service als nicht erreichbar markieren
            metrics.append(PerformanceMetric(
                name=f"{service_name}.availability",
                value=0,
                unit="boolean",
                timestamp=timestamp,
                service=service_name,
                threshold_critical=0.5
            ))
        
        return metrics
    
    async def collect_database_metrics(self) -> List[PerformanceMetric]:
        """Database-Performance-Metriken sammeln"""
        timestamp = datetime.utcnow()
        metrics = []
        
        try:
            from shared.database.event_store import EventStoreReader
            event_store = EventStoreReader()
            
            # Connection Pool Metrics
            pool_stats_query = """
                SELECT 
                    numbackends as active_connections,
                    (SELECT setting::int FROM pg_settings WHERE name = 'max_connections') as max_connections
                FROM pg_stat_database 
                WHERE datname = current_database()
            """
            
            start_time = datetime.utcnow()
            result = await event_store.execute_query(pool_stats_query)
            query_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            if result:
                active_connections = result[0]['active_connections']
                max_connections = result[0]['max_connections']
                connection_utilization = (active_connections / max_connections) * 100
                
                metrics.extend([
                    PerformanceMetric(
                        name="database.connections.active",
                        value=active_connections,
                        unit="connections",
                        timestamp=timestamp,
                        service="database",
                        baseline_value=15,
                        threshold_warning=40,
                        threshold_critical=45
                    ),
                    PerformanceMetric(
                        name="database.connections.utilization",
                        value=connection_utilization,
                        unit="percent",
                        timestamp=timestamp,
                        service="database",
                        baseline_value=30,
                        threshold_warning=80,
                        threshold_critical=95
                    ),
                    PerformanceMetric(
                        name="database.query.response_time",
                        value=query_time,
                        unit="ms",
                        timestamp=timestamp,
                        service="database",
                        baseline_value=25,
                        threshold_warning=100,
                        threshold_critical=500
                    )
                ])
            
            # Slow Query Metrics
            slow_query_stats = """
                SELECT 
                    calls,
                    total_time,
                    mean_time,
                    query
                FROM pg_stat_statements 
                WHERE mean_time > 100 
                ORDER BY mean_time DESC 
                LIMIT 5
            """
            
            slow_queries = await event_store.execute_query(slow_query_stats)
            if slow_queries:
                avg_slow_query_time = statistics.mean([q['mean_time'] for q in slow_queries])
                
                metrics.append(PerformanceMetric(
                    name="database.slow_queries.avg_time",
                    value=avg_slow_query_time,
                    unit="ms",
                    timestamp=timestamp,
                    service="database",
                    baseline_value=150,
                    threshold_warning=500,
                    threshold_critical=2000
                ))
            
            # Database Size Metrics
            size_query = """
                SELECT 
                    pg_size_pretty(pg_database_size(current_database())) as db_size,
                    pg_database_size(current_database()) as db_size_bytes
            """
            
            size_result = await event_store.execute_query(size_query)
            if size_result:
                db_size_mb = size_result[0]['db_size_bytes'] / 1024 / 1024
                
                metrics.append(PerformanceMetric(
                    name="database.size",
                    value=db_size_mb,
                    unit="MB",
                    timestamp=timestamp,
                    service="database",
                    baseline_value=2500,  # 2.5 GB
                    threshold_warning=10000,  # 10 GB
                    threshold_critical=20000  # 20 GB
                ))
        
        except Exception as e:
            self.logger.error(f"Error collecting database metrics: {e}")
        
        return metrics
    
    async def collect_redis_metrics(self) -> List[PerformanceMetric]:
        """Redis-Performance-Metriken sammeln"""
        timestamp = datetime.utcnow()
        metrics = []
        
        try:
            from shared.redis.client import RedisClient
            redis_client = RedisClient()
            
            # Redis INFO Command
            info = await redis_client.info()
            
            # Memory Metrics
            used_memory_mb = info.get('used_memory', 0) / 1024 / 1024
            max_memory_mb = info.get('maxmemory', 0) / 1024 / 1024 if info.get('maxmemory', 0) > 0 else 1024
            memory_utilization = (used_memory_mb / max_memory_mb) * 100
            
            metrics.extend([
                PerformanceMetric(
                    name="redis.memory.used",
                    value=used_memory_mb,
                    unit="MB",
                    timestamp=timestamp,
                    service="redis",
                    baseline_value=128,
                    threshold_warning=512,
                    threshold_critical=800
                ),
                PerformanceMetric(
                    name="redis.memory.utilization",
                    value=memory_utilization,
                    unit="percent",
                    timestamp=timestamp,
                    service="redis",
                    baseline_value=65,
                    threshold_warning=80,
                    threshold_critical=95
                )
            ])
            
            # Connection Metrics
            connected_clients = info.get('connected_clients', 0)
            metrics.append(PerformanceMetric(
                name="redis.connections.clients",
                value=connected_clients,
                unit="connections",
                timestamp=timestamp,
                service="redis",
                baseline_value=10,
                threshold_warning=50,
                threshold_critical=100
            ))
            
            # Hit Rate Metrics (approximation)
            keyspace_hits = info.get('keyspace_hits', 0)
            keyspace_misses = info.get('keyspace_misses', 0)
            total_requests = keyspace_hits + keyspace_misses
            
            if total_requests > 0:
                hit_rate = (keyspace_hits / total_requests) * 100
                metrics.append(PerformanceMetric(
                    name="redis.cache.hit_rate",
                    value=hit_rate,
                    unit="percent",
                    timestamp=timestamp,
                    service="redis",
                    baseline_value=85,
                    threshold_warning=70,  # Warning wenn unter 70%
                    threshold_critical=50  # Critical wenn unter 50%
                ))
            
            # Operations per Second
            instantaneous_ops_per_sec = info.get('instantaneous_ops_per_sec', 0)
            metrics.append(PerformanceMetric(
                name="redis.operations.per_second",
                value=instantaneous_ops_per_sec,
                unit="ops/sec",
                timestamp=timestamp,
                service="redis",
                baseline_value=100,
                threshold_warning=1000,
                threshold_critical=5000
            ))
        
        except Exception as e:
            self.logger.error(f"Error collecting Redis metrics: {e}")
        
        return metrics
    
    async def generate_performance_report(self, time_period: str = "1h") -> Dict:
        """Performance-Report generieren"""
        end_time = datetime.utcnow()
        
        if time_period == "1h":
            start_time = end_time - timedelta(hours=1)
        elif time_period == "24h":
            start_time = end_time - timedelta(hours=24)
        elif time_period == "7d":
            start_time = end_time - timedelta(days=7)
        else:
            start_time = end_time - timedelta(hours=1)
        
        # Metriken aus dem Zeitraum filtern
        period_metrics = [
            metric for metric in self.metrics_history
            if start_time <= metric.timestamp <= end_time
        ]
        
        # Report zusammenstellen
        report = {
            "report_period": time_period,
            "start_time": start_time.isoformat(),
            "end_time": end_time.isoformat(),
            "total_metrics": len(period_metrics),
            "services": {},
            "summary": {
                "critical_issues": 0,
                "warnings": 0,
                "baseline_deviations": []
            }
        }
        
        # Metriken nach Service gruppieren
        services_metrics = {}
        for metric in period_metrics:
            if metric.service not in services_metrics:
                services_metrics[metric.service] = []
            services_metrics[metric.service].append(metric)
        
        # Service-Reports erstellen
        for service_name, metrics in services_metrics.items():
            service_report = {
                "metric_count": len(metrics),
                "metrics": {},
                "status_summary": {"ok": 0, "warning": 0, "critical": 0}
            }
            
            # Metriken nach Name gruppieren
            metrics_by_name = {}
            for metric in metrics:
                if metric.name not in metrics_by_name:
                    metrics_by_name[metric.name] = []
                metrics_by_name[metric.name].append(metric)
            
            # Statistiken für jede Metrik berechnen
            for metric_name, metric_list in metrics_by_name.items():
                values = [m.value for m in metric_list]
                statuses = [m.status for m in metric_list]
                
                latest_metric = max(metric_list, key=lambda m: m.timestamp)
                
                metric_stats = {
                    "latest_value": latest_metric.value,
                    "latest_status": latest_metric.status,
                    "unit": latest_metric.unit,
                    "baseline_value": latest_metric.baseline_value,
                    "baseline_deviation": latest_metric.baseline_deviation,
                    "avg_value": statistics.mean(values),
                    "min_value": min(values),
                    "max_value": max(values),
                    "p95_value": statistics.quantiles(values, n=20)[18] if len(values) > 5 else max(values),
                    "data_points": len(values)
                }
                
                service_report["metrics"][metric_name] = metric_stats
                
                # Status-Zusammenfassung aktualisieren
                for status in statuses:
                    service_report["status_summary"][status] += 1
                
                # Global Summary aktualisieren
                if latest_metric.status == "critical":
                    report["summary"]["critical_issues"] += 1
                elif latest_metric.status == "warning":
                    report["summary"]["warnings"] += 1
                
                # Baseline-Abweichungen sammeln
                if latest_metric.baseline_deviation and abs(latest_metric.baseline_deviation) > 20:
                    report["summary"]["baseline_deviations"].append({
                        "service": service_name,
                        "metric": metric_name,
                        "deviation_percent": latest_metric.baseline_deviation,
                        "current_value": latest_metric.value,
                        "baseline_value": latest_metric.baseline_value
                    })
            
            report["services"][service_name] = service_report
        
        return report
```

---

## ⚡ **2. AUTO-SCALING-POLICIES FÜR SYSTEMD-SERVICES**

### 2.1 systemd Auto-Scaling Configuration

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/auto_scaling_manager.sh
"""Auto-Scaling Manager für systemd-Services"""

set -euo pipefail

# Configuration
SCALING_CONFIG="/opt/aktienanalyse-ökosystem/config/auto_scaling_config.yaml"
LOG_FILE="/var/log/aktienanalyse/auto_scaling.log"
METRICS_ENDPOINT="http://localhost:8004/api/metrics"
SCALE_COOLDOWN=300  # 5 Minuten zwischen Scaling-Operationen

# Logging Function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [AUTO-SCALING] $1" | tee -a "$LOG_FILE"
}

# Funktion zum Abrufen aktueller Metriken
get_service_metrics() {
    local service_name="$1"
    
    # Metriken von Monitoring-Service abrufen
    curl -s "${METRICS_ENDPOINT}/service/${service_name}" | jq -r '.'
}

# Funktion zum Überprüfen der CPU-Auslastung
check_cpu_usage() {
    local service_name="$1"
    
    # Service-spezifische CPU-Usage ermitteln
    local pid=$(systemctl show --property MainPID --value "$service_name")
    
    if [[ "$pid" != "0" ]]; then
        ps -p "$pid" -o %cpu --no-headers | awk '{print $1}'
    else
        echo "0"
    fi
}

# Funktion zum Überprüfen der Memory-Auslastung
check_memory_usage() {
    local service_name="$1"
    
    local pid=$(systemctl show --property MainPID --value "$service_name")
    
    if [[ "$pid" != "0" ]]; then
        ps -p "$pid" -o %mem --no-headers | awk '{print $1}'
    else
        echo "0"
    fi
}

# Funktion zum Skalieren eines Service
scale_service() {
    local service_name="$1"
    local action="$2"  # "up" oder "down"
    local current_instances="$3"
    
    case "$action" in
        "up")
            local new_instances=$((current_instances + 1))
            log "Scaling UP service $service_name from $current_instances to $new_instances instances"
            
            # Neuen Service-Instance starten
            local new_service_name="${service_name}@${new_instances}"
            systemctl start "$new_service_name"
            systemctl enable "$new_service_name"
            
            # Load Balancer Configuration aktualisieren
            update_load_balancer_config "$service_name" "$new_instances"
            ;;
            
        "down")
            if [[ $current_instances -gt 1 ]]; then
                local new_instances=$((current_instances - 1))
                log "Scaling DOWN service $service_name from $current_instances to $new_instances instances"
                
                # Höchste Instance-Nummer stoppen
                local target_service="${service_name}@${current_instances}"
                systemctl stop "$target_service"
                systemctl disable "$target_service"
                
                # Load Balancer Configuration aktualisieren
                update_load_balancer_config "$service_name" "$new_instances"
            else
                log "Cannot scale down $service_name: minimum instances (1) reached"
            fi
            ;;
    esac
}

# Funktion zum Aktualisieren der Load Balancer Configuration
update_load_balancer_config() {
    local service_name="$1"
    local instance_count="$2"
    
    # HAProxy Configuration für Service-Instances generieren
    local haproxy_config="/etc/haproxy/conf.d/${service_name}.cfg"
    
    cat > "$haproxy_config" << EOF
backend ${service_name}_backend
    balance roundrobin
EOF
    
    # Server-Entries für alle Instances hinzufügen
    for i in $(seq 1 "$instance_count"); do
        local port=$((8000 + i))
        echo "    server ${service_name}_${i} 127.0.0.1:${port} check" >> "$haproxy_config"
    done
    
    # HAProxy neu laden
    systemctl reload haproxy
    log "Updated load balancer configuration for $service_name with $instance_count instances"
}

# Funktion zum Ermitteln der aktuellen Instance-Anzahl
get_current_instances() {
    local service_name="$1"
    
    # Aktive Service-Instances zählen
    systemctl list-units --type=service --state=active "${service_name}@*" | \
        grep -c "${service_name}@" || echo "1"
}

# Hauptfunktion für Auto-Scaling-Entscheidungen
auto_scale_service() {
    local service_name="$1"
    local config="$2"
    
    # Aktuelle Metriken abrufen
    local cpu_usage=$(check_cpu_usage "$service_name")
    local memory_usage=$(check_memory_usage "$service_name")
    local current_instances=$(get_current_instances "$service_name")
    
    # Schwellwerte aus Konfiguration lesen
    local cpu_scale_up_threshold=$(echo "$config" | jq -r '.cpu_scale_up_threshold')
    local cpu_scale_down_threshold=$(echo "$config" | jq -r '.cpu_scale_down_threshold')
    local memory_scale_up_threshold=$(echo "$config" | jq -r '.memory_scale_up_threshold')
    local max_instances=$(echo "$config" | jq -r '.max_instances')
    local min_instances=$(echo "$config" | jq -r '.min_instances')
    
    log "Service: $service_name | CPU: ${cpu_usage}% | Memory: ${memory_usage}% | Instances: $current_instances"
    
    # Scaling-Entscheidung treffen
    local should_scale_up=false
    local should_scale_down=false
    
    # Scale Up Conditions
    if (( $(echo "$cpu_usage > $cpu_scale_up_threshold" | bc -l) )) || \
       (( $(echo "$memory_usage > $memory_scale_up_threshold" | bc -l) )); then
        
        if [[ $current_instances -lt $max_instances ]]; then
            should_scale_up=true
        else
            log "Service $service_name at maximum instances ($max_instances)"
        fi
    fi
    
    # Scale Down Conditions
    if (( $(echo "$cpu_usage < $cpu_scale_down_threshold" | bc -l) )) && \
       (( $(echo "$memory_usage < 50" | bc -l) )); then  # Memory unter 50%
        
        if [[ $current_instances -gt $min_instances ]]; then
            should_scale_down=true
        fi
    fi
    
    # Cooldown-Check
    local last_scaling_file="/tmp/${service_name}_last_scaling"
    local current_time=$(date +%s)
    
    if [[ -f "$last_scaling_file" ]]; then
        local last_scaling_time=$(cat "$last_scaling_file")
        local time_diff=$((current_time - last_scaling_time))
        
        if [[ $time_diff -lt $SCALE_COOLDOWN ]]; then
            log "Service $service_name in cooldown period (${time_diff}s < ${SCALE_COOLDOWN}s)"
            return
        fi
    fi
    
    # Scaling durchführen
    if [[ "$should_scale_up" == "true" ]]; then
        scale_service "$service_name" "up" "$current_instances"
        echo "$current_time" > "$last_scaling_file"
        
        # Alert senden
        send_scaling_alert "$service_name" "scaled_up" "$current_instances" $((current_instances + 1))
        
    elif [[ "$should_scale_down" == "true" ]]; then
        scale_service "$service_name" "down" "$current_instances"
        echo "$current_time" > "$last_scaling_file"
        
        # Alert senden
        send_scaling_alert "$service_name" "scaled_down" "$current_instances" $((current_instances - 1))
    fi
}

# Funktion zum Senden von Scaling-Alerts
send_scaling_alert() {
    local service_name="$1"
    local action="$2"
    local old_instances="$3"
    local new_instances="$4"
    
    local webhook_url=$(yq eval '.notifications.slack_webhook' "$SCALING_CONFIG")
    
    if [[ "$webhook_url" != "null" ]]; then
        local message="🔄 *Auto-Scaling Alert*\n"
        message+="Service: \`$service_name\`\n"
        message+="Action: $action\n"
        message+="Instances: $old_instances → $new_instances\n"
        message+="Time: $(date '+%Y-%m-%d %H:%M:%S')"
        
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"$message\"}" \
            "$webhook_url" || true
    fi
}

# Hauptschleife
main() {
    log "Starting Auto-Scaling Manager"
    
    # Konfiguration laden
    if [[ ! -f "$SCALING_CONFIG" ]]; then
        log "ERROR: Scaling configuration file not found: $SCALING_CONFIG"
        exit 1
    fi
    
    while true; do
        # Alle konfigurierten Services durchgehen
        local services=$(yq eval '.services | keys | .[]' "$SCALING_CONFIG")
        
        while IFS= read -r service_name; do
            local service_config=$(yq eval ".services.$service_name" "$SCALING_CONFIG")
            
            # Prüfen ob Auto-Scaling für Service aktiviert ist
            local enabled=$(echo "$service_config" | jq -r '.enabled')
            
            if [[ "$enabled" == "true" ]]; then
                auto_scale_service "$service_name" "$service_config"
            fi
            
        done <<< "$services"
        
        # Warten bis zum nächsten Check
        sleep 60  # Check alle 60 Sekunden
    done
}

# Cleanup bei Script-Ende
cleanup() {
    log "Auto-Scaling Manager stopped"
}

trap cleanup EXIT

# Script starten wenn direkt ausgeführt
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
```

### 2.2 Auto-Scaling Configuration

```yaml
# /opt/aktienanalyse-ökosystem/config/auto_scaling_config.yaml
"""Auto-Scaling-Konfiguration für alle Services"""

# Global Auto-Scaling Settings
global_settings:
  enabled: true
  check_interval: 60              # Sekunden zwischen Checks
  cooldown_period: 300            # Sekunden zwischen Scaling-Operationen
  metrics_retention: 3600         # Sekunden für Metrics-History
  
notifications:
  slack_webhook: "${SLACK_WEBHOOK_URL}"
  email_alerts: true
  email_recipients: ["ops@aktienanalyse.local"]

# Service-spezifische Auto-Scaling-Konfigurationen
services:
  aktienanalyse-core:
    enabled: true
    min_instances: 2
    max_instances: 8
    
    # CPU-basierte Scaling-Regeln
    cpu_scale_up_threshold: 70      # % CPU-Auslastung
    cpu_scale_down_threshold: 30    # % CPU-Auslastung
    cpu_evaluation_period: 300     # Sekunden über die der Schwellwert erreicht sein muss
    
    # Memory-basierte Scaling-Regeln
    memory_scale_up_threshold: 80   # % Memory-Auslastung
    memory_scale_down_threshold: 40 # % Memory-Auslastung
    
    # Request-basierte Scaling-Regeln
    requests_per_second_threshold: 500
    response_time_threshold: 2000   # ms
    error_rate_threshold: 5.0       # %
    
    # Custom Business Metrics
    business_metrics:
      portfolio_calculation_queue_length: 100
      active_trading_sessions: 50
    
    # Scaling-Verhalten
    scale_up:
      instances_to_add: 1
      cooldown_period: 300
    
    scale_down:
      instances_to_remove: 1
      cooldown_period: 600          # Längerer Cooldown für Scale-Down
    
    # Health Check für neue Instances
    health_check:
      initial_delay: 30             # Sekunden bis erste Health-Check
      timeout: 10                   # Timeout für Health-Check
      retries: 3
      endpoint: "/health"
    
    # Load Balancer Integration
    load_balancer:
      type: "haproxy"
      backend_name: "aktienanalyse_core_backend"
      health_check_interval: 5
      
  aktienanalyse-broker:
    enabled: true
    min_instances: 1
    max_instances: 4
    
    cpu_scale_up_threshold: 60      # Niedriger wegen externer API-Calls
    cpu_scale_down_threshold: 20
    memory_scale_up_threshold: 75
    memory_scale_down_threshold: 35
    
    # Broker-spezifische Metriken
    broker_metrics:
      api_calls_per_minute_threshold: 400
      order_execution_time_threshold: 5000  # ms
      api_error_rate_threshold: 10.0        # % (höher wegen externer Abhängigkeiten)
    
    scale_up:
      instances_to_add: 1
      cooldown_period: 600          # Länger wegen externer API-Limits
    
    scale_down:
      instances_to_remove: 1
      cooldown_period: 900
    
    load_balancer:
      type: "haproxy"
      backend_name: "aktienanalyse_broker_backend"
      
  aktienanalyse-events:
    enabled: true
    min_instances: 2                # Immer mindestens 2 für Hochverfügbarkeit
    max_instances: 6
    
    cpu_scale_up_threshold: 65
    cpu_scale_down_threshold: 25
    memory_scale_up_threshold: 70
    memory_scale_down_threshold: 30
    
    # Event-spezifische Metriken
    event_metrics:
      events_per_second_threshold: 800
      queue_lag_threshold: 1000     # ms
      message_processing_time_threshold: 100  # ms
    
    scale_up:
      instances_to_add: 1
      cooldown_period: 180          # Schneller wegen Event-Verarbeitung
    
    scale_down:
      instances_to_remove: 1
      cooldown_period: 600
    
    load_balancer:
      type: "haproxy"
      backend_name: "aktienanalyse_events_backend"
      
  aktienanalyse-frontend:
    enabled: true
    min_instances: 2
    max_instances: 6
    
    cpu_scale_up_threshold: 60
    cpu_scale_down_threshold: 20
    memory_scale_up_threshold: 70
    memory_scale_down_threshold: 30
    
    # Frontend-spezifische Metriken
    frontend_metrics:
      concurrent_users_threshold: 80
      page_load_time_threshold: 3000  # ms
      javascript_error_rate_threshold: 2.0  # %
    
    scale_up:
      instances_to_add: 1
      cooldown_period: 240
    
    scale_down:
      instances_to_remove: 1
      cooldown_period: 480
    
    load_balancer:
      type: "nginx"
      upstream_name: "aktienanalyse_frontend_upstream"
      
  aktienanalyse-monitoring:
    enabled: false               # Monitoring-Service nicht auto-skalieren
    min_instances: 1
    max_instances: 1

# Predictive Scaling Configuration
predictive_scaling:
  enabled: true
  
  # Machine Learning basierte Vorhersagen
  models:
    daily_pattern:
      enabled: true
      lookback_days: 14
      prediction_horizon: 60     # Minuten
      confidence_threshold: 0.8
      
    weekly_pattern:
      enabled: true
      lookback_weeks: 8
      prediction_horizon: 240    # Minuten
      confidence_threshold: 0.75
      
    business_events:
      enabled: true
      # Vorhersagen basierend auf Business-Events
      market_open_scale_up: true
      earnings_season_scale_up: true
      
  # Proactive Scaling Rules
  proactive_scaling:
    enable_pre_scaling: true
    pre_scale_minutes: 15        # Minuten vor vorhergesagtem Bedarf
    pre_scale_confidence: 0.8
    
# Emergency Scaling
emergency_scaling:
  enabled: true
  
  # Aggressive Scaling bei kritischen Situationen
  triggers:
    error_rate_critical: 15.0    # % Error Rate
    response_time_critical: 10000  # ms
    queue_backlog_critical: 1000
    
  actions:
    scale_up_factor: 2           # Verdopplung der Instances
    max_emergency_instances: 16
    emergency_cooldown: 60       # Kürzerer Cooldown in Notfällen
    
  notifications:
    immediate_alert: true
    escalation_after: 300        # Sekunden

# Resource Limits
resource_limits:
  # Globale Limits für alle Services
  max_total_instances: 32
  max_cpu_cores: 16
  max_memory_gb: 32
  
  # Per-Service Memory Limits
  per_instance_memory_mb:
    aktienanalyse-core: 512
    aktienanalyse-broker: 256
    aktienanalyse-events: 384
    aktienanalyse-frontend: 256
    aktienanalyse-monitoring: 512

# Monitoring Integration
monitoring:
  zabbix_integration:
    enabled: true
    host_template: "Aktienanalyse Auto Scaling"
    metrics_interval: 30
    
  custom_metrics:
    - name: "auto_scaling.decisions_per_hour"
      type: "counter"
    - name: "auto_scaling.active_instances_total"
      type: "gauge"
    - name: "auto_scaling.resource_utilization"
      type: "gauge"
      
  alerts:
    scaling_failure:
      severity: "high"
      notification: "immediate"
    resource_limit_reached:
      severity: "warning"
      notification: "team"
    
# Cost Optimization
cost_optimization:
  enabled: true
  
  # Zeitbasierte Scaling-Regeln
  schedule_based_scaling:
    business_hours:
      start_time: "08:00"
      end_time: "18:00"
      timezone: "Europe/Berlin"
      min_instances_multiplier: 1.0
      
    off_hours:
      min_instances_multiplier: 0.5  # Reduzierte Min-Instances außerhalb der Geschäftszeiten
      
    weekends:
      min_instances_multiplier: 0.3
      
  # Idle Instance Detection
  idle_detection:
    enabled: true
    cpu_idle_threshold: 5         # % CPU für 'idle'
    memory_idle_threshold: 30     # % Memory für 'idle'
    idle_duration_threshold: 1800 # Sekunden
    
# Integration mit External Services
external_integrations:
  prometheus:
    enabled: false
    endpoint: "http://localhost:9090"
    
  grafana:
    enabled: false
    dashboard_id: "auto-scaling-dashboard"
    
  kubernetes:
    enabled: false   # Nicht relevant für systemd-basierte Services
```

---

## 💾 **3. CACHING-STRATEGIES MIT REDIS-CONFIGURATION**

### 3.1 Redis Caching Architecture

```yaml
# /opt/aktienanalyse-ökosystem/config/redis_caching_config.yaml
"""Redis Caching-Strategien und -Konfiguration"""

# Redis Cluster Configuration
redis_cluster:
  enabled: true
  nodes:
    - host: "localhost"
      port: 6379
      role: "master"
      memory_limit: "1GB"
    - host: "localhost"
      port: 6380
      role: "replica"
      memory_limit: "1GB"
  
  # Cluster Settings
  cluster_settings:
    cluster_enabled: false  # Verwende Sentinel für HA statt Cluster
    sentinel_enabled: true
    sentinel_master_name: "aktienanalyse-redis"
    sentinel_quorum: 1
    
# Cache Strategies per Domain
cache_strategies:
  # Portfolio Data Caching
  portfolio_cache:
    key_pattern: "portfolio:{portfolio_id}:{data_type}"
    ttl_seconds: 300        # 5 Minuten
    strategy: "write_through"
    eviction_policy: "allkeys-lru"
    compression: true
    serialization: "json"
    
    # Cache Layers
    layers:
      l1_portfolio_summary:
        ttl: 60            # 1 Minute für Summary
        max_memory: "50MB"
        key_pattern: "portfolio:{id}:summary"
        
      l2_portfolio_details:
        ttl: 300           # 5 Minuten für Details
        max_memory: "200MB"
        key_pattern: "portfolio:{id}:details"
        
      l3_portfolio_history:
        ttl: 3600          # 1 Stunde für History
        max_memory: "500MB"
        key_pattern: "portfolio:{id}:history:{period}"
    
    # Cache Warming
    warming:
      enabled: true
      schedule: "0 */15 * * * *"  # Alle 15 Minuten
      priority_portfolios: ["user_favorites", "high_value"]
      
  # Market Data Caching
  market_data_cache:
    key_pattern: "market:{symbol}:{data_type}:{timeframe}"
    ttl_seconds: 30         # 30 Sekunden für Market Data
    strategy: "write_behind"
    refresh_ahead: true
    refresh_threshold: 0.8  # Bei 80% der TTL refreshen
    
    layers:
      l1_real_time_prices:
        ttl: 5             # 5 Sekunden für Real-time
        max_memory: "100MB"
        key_pattern: "market:{symbol}:price"
        
      l2_intraday_data:
        ttl: 300           # 5 Minuten für Intraday
        max_memory: "300MB"
        key_pattern: "market:{symbol}:intraday:{interval}"
        
      l3_historical_data:
        ttl: 86400         # 24 Stunden für Historical
        max_memory: "1GB"
        key_pattern: "market:{symbol}:history:{period}"
    
    # External API Integration
    external_api:
      rate_limit_cache:
        key_pattern: "ratelimit:{provider}:{endpoint}"
        ttl: 3600
        sliding_window: true
        
  # User Session Caching
  session_cache:
    key_pattern: "session:{user_id}:{session_id}"
    ttl_seconds: 1800       # 30 Minuten
    strategy: "write_through"
    encryption: true
    
    data_types:
      user_preferences:
        ttl: 3600          # 1 Stunde
        key_pattern: "user:{id}:prefs"
        
      ui_state:
        ttl: 1800          # 30 Minuten
        key_pattern: "user:{id}:ui_state"
        
      recent_actions:
        ttl: 300           # 5 Minuten
        key_pattern: "user:{id}:actions"
        
  # Calculation Results Caching
  calculation_cache:
    key_pattern: "calc:{calculation_type}:{input_hash}"
    ttl_seconds: 3600       # 1 Stunde
    strategy: "lazy_loading"
    
    calculation_types:
      risk_assessment:
        ttl: 1800          # 30 Minuten
        max_memory: "200MB"
        
      performance_analytics:
        ttl: 3600          # 1 Stunde
        max_memory: "300MB"
        
      tax_calculations:
        ttl: 86400         # 24 Stunden (selten ändernd)
        max_memory: "100MB"
        
  # API Response Caching
  api_response_cache:
    key_pattern: "api:{service}:{endpoint}:{params_hash}"
    ttl_seconds: 60         # 1 Minute
    strategy: "cache_aside"
    
    endpoints:
      "/api/portfolios":
        ttl: 300
        vary_by: ["user_id", "date_range"]
        
      "/api/assets":
        ttl: 600
        vary_by: ["symbol", "data_type"]
        
      "/api/market-data":
        ttl: 30
        vary_by: ["symbol", "timeframe"]

# Cache Performance Optimization
performance_optimization:
  # Connection Pooling
  connection_pool:
    min_connections: 5
    max_connections: 50
    connection_timeout: 5
    socket_keepalive: true
    socket_keepalive_options:
      TCP_KEEPIDLE: 600
      TCP_KEEPINTVL: 30
      TCP_KEEPCNT: 3
      
  # Memory Management
  memory_management:
    maxmemory_policy: "allkeys-lru"
    maxmemory_samples: 5
    
    # Memory Thresholds
    memory_thresholds:
      warning: 80          # % Memory usage warning
      critical: 95         # % Memory usage critical
      eviction_start: 85   # % Memory usage when eviction starts
      
  # Persistence Configuration
  persistence:
    rdb_enabled: true
    rdb_save_intervals:
      - "900 1"            # Save if at least 1 key changed in 900 seconds
      - "300 10"           # Save if at least 10 keys changed in 300 seconds
      - "60 10000"         # Save if at least 10000 keys changed in 60 seconds
      
    aof_enabled: false    # AOF für bessere Performance deaktiviert
    
  # Compression
  compression:
    enabled: true
    algorithm: "lz4"      # Schnelle Kompression
    min_size_bytes: 1024  # Nur Objekte > 1KB komprimieren
    
# Cache Invalidation Strategies
invalidation_strategies:
  # Event-Driven Invalidation
  event_driven:
    enabled: true
    
    events:
      portfolio_updated:
        invalidate_patterns:
          - "portfolio:{portfolio_id}:*"
          - "user:{user_id}:portfolios"
          
      market_data_updated:
        invalidate_patterns:
          - "market:{symbol}:*"
          - "portfolio:*:summary"  # Portfolio Summary depends on market data
          
      user_preferences_changed:
        invalidate_patterns:
          - "user:{user_id}:*"
          
  # Time-Based Invalidation
  time_based:
    enabled: true
    
    schedules:
      market_close_cleanup:
        cron: "0 22 * * 1-5"  # Werktags um 22:00
        patterns:
          - "market:*:intraday:*"
          
      weekly_cache_refresh:
        cron: "0 2 * * 0"     # Sonntags um 02:00
        patterns:
          - "calc:*"
          - "api:*"
          
  # Manual Invalidation API
  manual_invalidation:
    enabled: true
    api_endpoint: "/admin/cache/invalidate"
    auth_required: true
    
# Monitoring & Analytics
monitoring:
  metrics:
    hit_rate_tracking:
      enabled: true
      granularity: "per_cache_layer"
      alert_threshold: 70   # % Hit Rate minimum
      
    performance_tracking:
      enabled: true
      response_time_buckets: [0.1, 0.5, 1.0, 2.0, 5.0]  # ms
      
    memory_tracking:
      enabled: true
      memory_usage_buckets: [10, 25, 50, 75, 90, 95]     # %
      
  alerts:
    cache_miss_spike:
      threshold: 50       # % Miss Rate
      duration: 300       # Sekunden
      severity: "warning"
      
    memory_pressure:
      threshold: 90       # % Memory usage
      duration: 60        # Sekunden
      severity: "critical"
      
    slow_operations:
      threshold: 5        # ms average operation time
      duration: 300       # Sekunden
      severity: "warning"
      
# Cache Warming Strategies
cache_warming:
  # Application Startup
  startup_warming:
    enabled: true
    timeout: 300          # Sekunden
    parallel_workers: 4
    
    tasks:
      - name: "warm_popular_portfolios"
        query: "SELECT portfolio_id FROM portfolios WHERE last_accessed > NOW() - INTERVAL '7 days'"
        cache_pattern: "portfolio:{portfolio_id}:summary"
        
      - name: "warm_market_data"
        symbols: ["AAPL", "MSFT", "GOOGL", "AMZN", "TSLA"]
        cache_pattern: "market:{symbol}:price"
        
  # Predictive Warming
  predictive_warming:
    enabled: true
    ml_model: "cache_prediction_model"
    confidence_threshold: 0.7
    
    prediction_triggers:
      - name: "market_open_preparation"
        time: "08:30"
        timezone: "Europe/Berlin"
        warm_patterns:
          - "market:*:price"
          - "portfolio:*:summary"
          
      - name: "user_login_prediction"
        trigger: "user_activity_pattern"
        warm_patterns:
          - "user:{predicted_user_id}:*"
          
# Redis Configuration Templates
redis_configurations:
  master_config:
    # Basis Redis Configuration
    port: 6379
    bind: "127.0.0.1"
    protected_mode: true
    timeout: 300
    
    # Memory
    maxmemory: "1gb"
    maxmemory_policy: "allkeys-lru"
    
    # Persistence
    save:
      - "900 1"
      - "300 10"
      - "60 10000"
    
    # Logging
    loglevel: "notice"
    logfile: "/var/log/redis/redis-server.log"
    
    # Performance
    tcp_keepalive: 300
    tcp_backlog: 511
    
  sentinel_config:
    port: 26379
    bind: "127.0.0.1"
    
    # Master Monitoring
    sentinel_monitor: "aktienanalyse-redis 127.0.0.1 6379 1"
    sentinel_down_after_milliseconds: 5000
    sentinel_failover_timeout: 10000
    sentinel_parallel_syncs: 1
    
    # Logging
    loglevel: "notice"
    logfile: "/var/log/redis/sentinel.log"
```

### 3.2 Cache Implementation Service

```python
# /opt/aktienanalyse-ökosystem/shared/cache/cache_manager.py
"""Intelligent Cache Manager mit Multi-Layer-Strategien"""

import asyncio
import json
import hashlib
import pickle
import lz4.frame
from datetime import datetime, timedelta
from typing import Any, Dict, List, Optional, Union, Callable
from dataclasses import dataclass
from enum import Enum
import logging
from contextvars import ContextVar

class CacheStrategy(Enum):
    WRITE_THROUGH = "write_through"
    WRITE_BEHIND = "write_behind"
    CACHE_ASIDE = "cache_aside"
    LAZY_LOADING = "lazy_loading"
    REFRESH_AHEAD = "refresh_ahead"

@dataclass
class CacheConfig:
    """Cache Layer Configuration"""
    layer_name: str
    ttl_seconds: int
    max_memory_mb: int
    strategy: CacheStrategy
    key_pattern: str
    compression: bool = True
    encryption: bool = False
    eviction_policy: str = "allkeys-lru"
    refresh_threshold: float = 0.8

@dataclass
class CacheMetrics:
    """Cache Performance Metrics"""
    hits: int = 0
    misses: int = 0
    sets: int = 0
    deletes: int = 0
    evictions: int = 0
    total_response_time: float = 0.0
    
    @property
    def hit_rate(self) -> float:
        total = self.hits + self.misses
        return (self.hits / total * 100) if total > 0 else 0.0
    
    @property
    def avg_response_time(self) -> float:
        total_ops = self.hits + self.misses + self.sets
        return (self.total_response_time / total_ops) if total_ops > 0 else 0.0

class CacheLayer:
    """Single Cache Layer Implementation"""
    
    def __init__(self, config: CacheConfig, redis_client):
        self.config = config
        self.redis = redis_client
        self.metrics = CacheMetrics()
        self.logger = logging.getLogger(f"cache.{config.layer_name}")
        
        # Background Tasks
        self._refresh_tasks: Dict[str, asyncio.Task] = {}
        
    async def get(self, key: str) -> Optional[Any]:
        """Value aus Cache abrufen"""
        start_time = datetime.utcnow()
        
        try:
            # Vollständigen Cache-Key erstellen
            cache_key = self._build_cache_key(key)
            
            # Value aus Redis abrufen
            raw_value = await self.redis.get(cache_key)
            
            if raw_value:
                # Cache Hit
                self.metrics.hits += 1
                
                # Value deserializieren
                value = await self._deserialize_value(raw_value)
                
                # Refresh-Ahead prüfen
                if self.config.strategy == CacheStrategy.REFRESH_AHEAD:
                    await self._check_refresh_ahead(cache_key, key)
                
                return value
            else:
                # Cache Miss
                self.metrics.misses += 1
                return None
                
        except Exception as e:
            self.logger.error(f"Cache get error for key {key}: {e}")
            self.metrics.misses += 1
            return None
            
        finally:
            response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            self.metrics.total_response_time += response_time
    
    async def set(self, key: str, value: Any, ttl: Optional[int] = None) -> bool:
        """Value in Cache speichern"""
        start_time = datetime.utcnow()
        
        try:
            # TTL bestimmen
            effective_ttl = ttl or self.config.ttl_seconds
            
            # Cache-Key erstellen
            cache_key = self._build_cache_key(key)
            
            # Value serialisieren
            serialized_value = await self._serialize_value(value)
            
            # In Redis speichern
            success = await self.redis.setex(cache_key, effective_ttl, serialized_value)
            
            if success:
                self.metrics.sets += 1
                return True
            else:
                return False
                
        except Exception as e:
            self.logger.error(f"Cache set error for key {key}: {e}")
            return False
            
        finally:
            response_time = (datetime.utcnow() - start_time).total_seconds() * 1000
            self.metrics.total_response_time += response_time
    
    def _build_cache_key(self, key: str) -> str:
        """Cache-Key mit Layer-Prefix erstellen"""
        return f"{self.config.layer_name}:{key}"
    
    async def _serialize_value(self, value: Any) -> bytes:
        """Value für Cache serialisieren"""
        # JSON Serialization
        json_data = json.dumps(value, default=str).encode('utf-8')
        
        # Compression wenn aktiviert
        if self.config.compression:
            json_data = lz4.frame.compress(json_data)
        
        return json_data
    
    async def _deserialize_value(self, raw_value: bytes) -> Any:
        """Value aus Cache deserialisieren"""
        data = raw_value
        
        # Decompression wenn aktiviert
        if self.config.compression:
            data = lz4.frame.decompress(data)
        
        # JSON Deserialization
        return json.loads(data.decode('utf-8'))

class MultiLayerCacheManager:
    """Multi-Layer Cache Manager"""
    
    def __init__(self, redis_client):
        self.redis = redis_client
        self.layers: Dict[str, CacheLayer] = {}
        self.logger = logging.getLogger("cache_manager")
        
    def register_layer(self, config: CacheConfig) -> CacheLayer:
        """Cache Layer registrieren"""
        layer = CacheLayer(config, self.redis)
        self.layers[config.layer_name] = layer
        
        self.logger.info(f"Registered cache layer: {config.layer_name}")
        return layer
    
    async def get_cached_or_compute(self, 
                                   layer_name: str, 
                                   key: str, 
                                   compute_func: Callable, 
                                   *args, 
                                   ttl: Optional[int] = None,
                                   **kwargs) -> Any:
        """Cache-aside Pattern Implementation"""
        layer = self.layers.get(layer_name)
        if not layer:
            self.logger.error(f"Cache layer {layer_name} not found")
            return await compute_func(*args, **kwargs)
        
        # Erst im Cache schauen
        cached_value = await layer.get(key)
        if cached_value is not None:
            return cached_value
        
        # Bei Cache Miss: Wert berechnen
        computed_value = await compute_func(*args, **kwargs)
        
        # Wert in Cache speichern
        await layer.set(key, computed_value, ttl)
        
        return computed_value
```

---

## 🗃️ **4. DATABASE-PERFORMANCE-TUNING SPEZIFIKATION**

### 4.1 PostgreSQL Performance Configuration

```sql
-- /opt/aktienanalyse-ökosystem/database/performance_tuning.sql
-- PostgreSQL Performance Tuning für Event-Store

-- Memory Configuration
SET shared_buffers = '256MB';                    -- 25% der verfügbaren RAM
SET effective_cache_size = '1GB';                -- 75% der verfügbaren RAM
SET work_mem = '16MB';                           -- Für Sorting/Hashing Operations
SET maintenance_work_mem = '128MB';              -- Für VACUUM, CREATE INDEX
SET wal_buffers = '16MB';                        -- Write-Ahead-Log Buffer

-- Connection Settings
SET max_connections = 100;                       -- Maximum concurrent connections
SET shared_preload_libraries = 'pg_stat_statements';

-- Query Optimization
SET random_page_cost = 1.1;                     -- SSD-optimiert
SET seq_page_cost = 1.0;                        -- Sequential scan cost
SET cpu_tuple_cost = 0.01;                      -- CPU cost per tuple
SET cpu_index_tuple_cost = 0.005;               -- CPU cost per index tuple
SET cpu_operator_cost = 0.0025;                 -- CPU cost per operator

-- Checkpoint Configuration
SET checkpoint_completion_target = 0.9;         -- Checkpoint spread over 90% of interval
SET checkpoint_timeout = '15min';               -- Checkpoint every 15 minutes
SET max_wal_size = '2GB';                       -- Maximum WAL size
SET min_wal_size = '512MB';                     -- Minimum WAL size

-- Auto Vacuum Configuration
SET autovacuum = on;
SET autovacuum_max_workers = 3;
SET autovacuum_naptime = '1min';
SET autovacuum_vacuum_threshold = 50;
SET autovacuum_vacuum_scale_factor = 0.2;

-- Event Store Optimized Indexes
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_aggregate_id_version 
    ON events(aggregate_id, version);
    
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_event_type_timestamp 
    ON events(event_type, timestamp);
    
CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_events_timestamp_desc 
    ON events(timestamp DESC);

-- Materialized Views für Performance
CREATE MATERIALIZED VIEW mv_portfolio_performance_summary AS
SELECT 
    p.portfolio_id,
    p.user_id,
    ps.current_value_eur,
    ps.initial_value_eur,
    (ps.current_value_eur - ps.initial_value_eur) / ps.initial_value_eur * 100 as performance_percent,
    ps.snapshot_date
FROM portfolios p
JOIN portfolio_snapshots ps ON p.portfolio_id = ps.portfolio_id
WHERE ps.snapshot_date = CURRENT_DATE;
```

### 4.2 Database Performance Monitoring

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/database_monitor.py
"""Database Performance Monitoring und Optimization"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass
import asyncpg
import logging

@dataclass
class DatabaseMetrics:
    """Database Performance Metrics"""
    timestamp: datetime
    active_connections: int
    idle_connections: int
    slow_queries_count: int
    avg_query_time: float
    cache_hit_ratio: float
    table_sizes: Dict[str, int]

class DatabasePerformanceMonitor:
    """Database Performance Monitor"""
    
    def __init__(self, connection_pool):
        self.pool = connection_pool
        self.logger = logging.getLogger("database_monitor")
        self.metrics_history: List[DatabaseMetrics] = []
        
    async def collect_metrics(self) -> DatabaseMetrics:
        """Database-Metriken sammeln"""
        async with self.pool.acquire() as conn:
            timestamp = datetime.utcnow()
            
            # Connection Metrics
            connection_stats = await self._get_connection_stats(conn)
            
            # Query Performance Metrics
            query_stats = await self._get_query_stats(conn)
            
            # Cache Performance
            cache_stats = await self._get_cache_stats(conn)
            
            # Table Stats
            table_stats = await self._get_table_stats(conn)
            
            metrics = DatabaseMetrics(
                timestamp=timestamp,
                active_connections=connection_stats['active'],
                idle_connections=connection_stats['idle'],
                slow_queries_count=query_stats['slow_queries'],
                avg_query_time=query_stats['avg_time'],
                cache_hit_ratio=cache_stats['hit_ratio'],
                table_sizes=table_stats
            )
            
            self.metrics_history.append(metrics)
            return metrics
    
    async def _get_connection_stats(self, conn) -> Dict:
        """Connection Statistics"""
        query = """
        SELECT 
            state,
            COUNT(*) as count
        FROM pg_stat_activity 
        WHERE datname = current_database()
        GROUP BY state
        """
        
        results = await conn.fetch(query)
        stats = {'active': 0, 'idle': 0}
        
        for row in results:
            if row['state'] == 'active':
                stats['active'] = row['count']
            elif row['state'] == 'idle':
                stats['idle'] = row['count']
        
        return stats
    
    async def _get_query_stats(self, conn) -> Dict:
        """Query Performance Statistics"""
        query = """
        SELECT 
            COUNT(*) as total_queries,
            COUNT(CASE WHEN mean_time > 1000 THEN 1 END) as slow_queries,
            AVG(mean_time) as avg_time
        FROM pg_stat_statements
        WHERE dbid = (SELECT oid FROM pg_database WHERE datname = current_database())
        """
        
        try:
            result = await conn.fetchrow(query)
            return {
                'total_queries': result['total_queries'] or 0,
                'slow_queries': result['slow_queries'] or 0,
                'avg_time': float(result['avg_time'] or 0)
            }
        except Exception:
            return {'total_queries': 0, 'slow_queries': 0, 'avg_time': 0}
    
    async def _get_cache_stats(self, conn) -> Dict:
        """Cache Hit Ratio Statistics"""
        query = """
        SELECT 
            SUM(heap_blks_read) as heap_read,
            SUM(heap_blks_hit) as heap_hit
        FROM pg_statio_user_tables
        """
        
        result = await conn.fetchrow(query)
        
        total_read = result['heap_read'] or 0
        total_hit = result['heap_hit'] or 0
        total_access = total_read + total_hit
        
        hit_ratio = (total_hit / total_access * 100) if total_access > 0 else 0
        
        return {'hit_ratio': hit_ratio}
    
    async def _get_table_stats(self, conn) -> Dict[str, int]:
        """Table Size Statistics"""
        query = """
        SELECT 
            tablename,
            pg_total_relation_size(schemaname||'.'||tablename) as size_bytes
        FROM pg_tables 
        WHERE schemaname = 'public'
        """
        
        results = await conn.fetch(query)
        
        return {
            row['tablename']: row['size_bytes']
            for row in results
        }
```

Die Performance & Scaling-Strategien Spezifikation ist vollständig.
```