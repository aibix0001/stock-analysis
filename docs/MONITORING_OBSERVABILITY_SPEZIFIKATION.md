# 📊 Monitoring & Observability - Vollständige Spezifikation

## 🎯 **Übersicht**

**Kontext**: Umfassendes Monitoring & Observability für aktienanalyse-ökosystem  
**Ziel**: Vollständige Überwachung, Alerting und Performance-Analyse  
**Ansatz**: Zabbix + Custom Metrics + Business KPIs + SLA/SLO Management  

---

## 🏗️ **1. CUSTOM-METRICS-DEFINITIONEN**

### 1.1 Business-KPI-Metriken

```python
# /opt/aktienanalyse-ökosystem/shared/monitoring/business_metrics.py
"""Business-KPI-Metriken für Aktienanalyse-Ökosystem"""

from dataclasses import dataclass
from typing import Dict, List, Optional
from enum import Enum
import time

class MetricType(Enum):
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    SUMMARY = "summary"

class MetricCategory(Enum):
    BUSINESS = "business"
    TECHNICAL = "technical"
    SECURITY = "security"
    PERFORMANCE = "performance"

@dataclass
class CustomMetric:
    """Custom Metric Definition"""
    name: str
    description: str
    metric_type: MetricType
    category: MetricCategory
    unit: str
    labels: List[str]
    collection_interval: int  # seconds
    retention_days: int
    alert_thresholds: Dict[str, float]
    zabbix_key: str

# Business-KPI-Metriken
BUSINESS_METRICS = {
    # Trading-Performance-Metriken
    "aktienanalyse.trading.orders_total": CustomMetric(
        name="Trading Orders Total",
        description="Gesamtanzahl aller Trading-Orders",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.BUSINESS,
        unit="orders",
        labels=["order_type", "status", "broker"],
        collection_interval=60,
        retention_days=365,
        alert_thresholds={
            "daily_increase_threshold": 1000,
            "hourly_spike_threshold": 100
        },
        zabbix_key="aktienanalyse.business.orders.total"
    ),
    
    "aktienanalyse.trading.volume_eur": CustomMetric(
        name="Trading Volume EUR",
        description="Handelsvolumen in EUR",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="EUR",
        labels=["time_period", "asset_type"],
        collection_interval=300,
        retention_days=365,
        alert_thresholds={
            "daily_volume_min": 1000.0,
            "daily_volume_max": 100000.0
        },
        zabbix_key="aktienanalyse.business.volume.eur"
    ),
    
    "aktienanalyse.trading.success_rate": CustomMetric(
        name="Trading Success Rate",
        description="Erfolgsrate der Trading-Orders in %",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="percent",
        labels=["strategy", "asset_class"],
        collection_interval=300,
        retention_days=365,
        alert_thresholds={
            "success_rate_min": 60.0,
            "success_rate_critical": 40.0
        },
        zabbix_key="aktienanalyse.business.success_rate"
    ),
    
    "aktienanalyse.portfolio.total_value": CustomMetric(
        name="Portfolio Total Value",
        description="Gesamtwert aller Portfolios in EUR",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="EUR",
        labels=["portfolio_id", "currency"],
        collection_interval=300,
        retention_days=365,
        alert_thresholds={
            "value_drop_percent": 10.0,
            "value_spike_percent": 20.0
        },
        zabbix_key="aktienanalyse.business.portfolio.value"
    ),
    
    "aktienanalyse.portfolio.performance": CustomMetric(
        name="Portfolio Performance",
        description="Portfolio-Performance in % (Gewinn/Verlust)",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="percent",
        labels=["portfolio_id", "time_period"],
        collection_interval=600,
        retention_days=365,
        alert_thresholds={
            "performance_min": -5.0,
            "performance_critical": -15.0
        },
        zabbix_key="aktienanalyse.business.portfolio.performance"
    ),
    
    # Risk-Management-Metriken
    "aktienanalyse.risk.violations": CustomMetric(
        name="Risk Rule Violations",
        description="Anzahl Risk-Management-Regel-Verletzungen",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.BUSINESS,
        unit="violations",
        labels=["rule_type", "severity"],
        collection_interval=60,
        retention_days=365,
        alert_thresholds={
            "violations_per_hour": 5,
            "critical_violations": 1
        },
        zabbix_key="aktienanalyse.business.risk.violations"
    ),
    
    "aktienanalyse.risk.exposure": CustomMetric(
        name="Portfolio Risk Exposure",
        description="Risiko-Exposition des Portfolios",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="percent",
        labels=["portfolio_id", "risk_type"],
        collection_interval=300,
        retention_days=365,
        alert_thresholds={
            "exposure_max": 80.0,
            "exposure_critical": 95.0
        },
        zabbix_key="aktienanalyse.business.risk.exposure"
    ),
    
    # Tax-Calculation-Metriken
    "aktienanalyse.tax.calculations": CustomMetric(
        name="Tax Calculations",
        description="Anzahl durchgeführter Steuer-Berechnungen",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.BUSINESS,
        unit="calculations",
        labels=["tax_type", "status"],
        collection_interval=300,
        retention_days=365,
        alert_thresholds={
            "daily_calculations_min": 10,
            "error_rate_max": 5.0
        },
        zabbix_key="aktienanalyse.business.tax.calculations"
    ),
    
    "aktienanalyse.tax.amount_eur": CustomMetric(
        name="Tax Amount EUR",
        description="Berechnete Steuern in EUR",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.BUSINESS,
        unit="EUR",
        labels=["tax_type", "period"],
        collection_interval=600,
        retention_days=365,
        alert_thresholds={
            "monthly_tax_max": 10000.0
        },
        zabbix_key="aktienanalyse.business.tax.amount"
    ),
    
    # API-Integration-Metriken
    "aktienanalyse.api.bitpanda_calls": CustomMetric(
        name="Bitpanda API Calls",
        description="Anzahl Bitpanda API-Aufrufe",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.TECHNICAL,
        unit="calls",
        labels=["endpoint", "status_code"],
        collection_interval=60,
        retention_days=90,
        alert_thresholds={
            "hourly_calls_max": 500,
            "error_rate_max": 10.0
        },
        zabbix_key="aktienanalyse.technical.api.bitpanda.calls"
    ),
    
    "aktienanalyse.api.response_time": CustomMetric(
        name="API Response Time",
        description="API-Response-Zeit in Millisekunden",
        metric_type=MetricType.HISTOGRAM,
        category=MetricCategory.PERFORMANCE,
        unit="ms",
        labels=["service", "endpoint"],
        collection_interval=60,
        retention_days=30,
        alert_thresholds={
            "response_time_p95": 2000.0,
            "response_time_p99": 5000.0
        },
        zabbix_key="aktienanalyse.performance.api.response_time"
    )
}

# Technical-Performance-Metriken
TECHNICAL_METRICS = {
    "aktienanalyse.events.processed": CustomMetric(
        name="Events Processed",
        description="Anzahl verarbeiteter Events im Event-Bus",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.TECHNICAL,
        unit="events",
        labels=["event_type", "service"],
        collection_interval=60,
        retention_days=90,
        alert_thresholds={
            "events_per_minute_min": 10,
            "events_per_minute_max": 1000
        },
        zabbix_key="aktienanalyse.technical.events.processed"
    ),
    
    "aktienanalyse.events.lag": CustomMetric(
        name="Event Processing Lag",
        description="Verzögerung bei Event-Verarbeitung in Sekunden",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.PERFORMANCE,
        unit="seconds",
        labels=["queue", "consumer"],
        collection_interval=60,
        retention_days=30,
        alert_thresholds={
            "lag_warning": 10.0,
            "lag_critical": 60.0
        },
        zabbix_key="aktienanalyse.performance.events.lag"
    ),
    
    "aktienanalyse.database.connections": CustomMetric(
        name="Database Connections",
        description="Anzahl aktiver Database-Verbindungen",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.TECHNICAL,
        unit="connections",
        labels=["database", "service"],
        collection_interval=60,
        retention_days=30,
        alert_thresholds={
            "connections_warning": 80,
            "connections_critical": 95
        },
        zabbix_key="aktienanalyse.technical.database.connections"
    ),
    
    "aktienanalyse.database.query_time": CustomMetric(
        name="Database Query Time",
        description="Database-Query-Zeit in Millisekunden",
        metric_type=MetricType.HISTOGRAM,
        category=MetricCategory.PERFORMANCE,
        unit="ms",
        labels=["query_type", "table"],
        collection_interval=60,
        retention_days=30,
        alert_thresholds={
            "query_time_p95": 500.0,
            "query_time_p99": 2000.0
        },
        zabbix_key="aktienanalyse.performance.database.query_time"
    ),
    
    "aktienanalyse.cache.hit_rate": CustomMetric(
        name="Cache Hit Rate",
        description="Cache-Hit-Rate in %",
        metric_type=MetricType.GAUGE,
        category=MetricCategory.PERFORMANCE,
        unit="percent",
        labels=["cache_type", "service"],
        collection_interval=300,
        retention_days=30,
        alert_thresholds={
            "hit_rate_min": 80.0,
            "hit_rate_critical": 60.0
        },
        zabbix_key="aktienanalyse.performance.cache.hit_rate"
    )
}

# Security-Metriken
SECURITY_METRICS = {
    "aktienanalyse.security.auth_attempts": CustomMetric(
        name="Authentication Attempts",
        description="Anzahl Authentifizierungs-Versuche",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.SECURITY,
        unit="attempts",
        labels=["result", "user_agent"],
        collection_interval=60,
        retention_days=180,
        alert_thresholds={
            "failed_attempts_per_minute": 10,
            "brute_force_threshold": 50
        },
        zabbix_key="aktienanalyse.security.auth.attempts"
    ),
    
    "aktienanalyse.security.api_key_usage": CustomMetric(
        name="API Key Usage",
        description="API-Key-Verwendung",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.SECURITY,
        unit="requests",
        labels=["key_id", "service"],
        collection_interval=300,
        retention_days=180,
        alert_thresholds={
            "unusual_usage_spike": 1000
        },
        zabbix_key="aktienanalyse.security.api_key.usage"
    ),
    
    "aktienanalyse.security.errors": CustomMetric(
        name="Security Errors",
        description="Sicherheits-relevante Fehler",
        metric_type=MetricType.COUNTER,
        category=MetricCategory.SECURITY,
        unit="errors",
        labels=["error_type", "severity"],
        collection_interval=60,
        retention_days=365,
        alert_thresholds={
            "security_errors_per_hour": 5,
            "critical_security_errors": 1
        },
        zabbix_key="aktienanalyse.security.errors"
    )
}

# Alle Metriken kombinieren
ALL_CUSTOM_METRICS = {
    **BUSINESS_METRICS,
    **TECHNICAL_METRICS,
    **SECURITY_METRICS
}
```

### 1.2 Metrics Collection Service

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/metrics_collector.py
"""Custom Metrics Collection Service"""

import asyncio
import logging
from datetime import datetime, timedelta
from typing import Dict, Any, List
import json
from dataclasses import asdict

from shared.monitoring.business_metrics import ALL_CUSTOM_METRICS, CustomMetric
from shared.database.event_store import EventStoreReader
from shared.redis.client import RedisClient
from pyzabbix import ZabbixMetric, ZabbixSender

class BusinessMetricsCalculator:
    """Business-Metriken-Berechnungen"""
    
    def __init__(self, event_store: EventStoreReader, redis_client: RedisClient):
        self.event_store = event_store
        self.redis = redis_client
        self.logger = logging.getLogger("metrics_calculator")
    
    async def calculate_trading_metrics(self) -> Dict[str, float]:
        """Trading-bezogene Metriken berechnen"""
        try:
            # Orders Total (letzte 24h)
            orders_query = """
                SELECT COUNT(*) as total_orders,
                       COUNT(CASE WHEN status = 'completed' THEN 1 END) as completed_orders,
                       SUM(CASE WHEN status = 'completed' THEN amount_eur ELSE 0 END) as volume_eur
                FROM trading_orders 
                WHERE created_at >= NOW() - INTERVAL '24 hours'
            """
            
            result = await self.event_store.execute_query(orders_query)
            
            total_orders = result[0]['total_orders'] if result else 0
            completed_orders = result[0]['completed_orders'] if result else 0
            volume_eur = float(result[0]['volume_eur'] or 0) if result else 0.0
            
            success_rate = (completed_orders / total_orders * 100) if total_orders > 0 else 0.0
            
            return {
                "orders_total": total_orders,
                "volume_eur": volume_eur,
                "success_rate": success_rate
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating trading metrics: {e}")
            return {}
    
    async def calculate_portfolio_metrics(self) -> Dict[str, float]:
        """Portfolio-Metriken berechnen"""
        try:
            portfolio_query = """
                SELECT portfolio_id,
                       current_value_eur,
                       initial_value_eur,
                       (current_value_eur - initial_value_eur) / initial_value_eur * 100 as performance_percent
                FROM portfolio_snapshots 
                WHERE snapshot_date = CURRENT_DATE
            """
            
            results = await self.event_store.execute_query(portfolio_query)
            
            total_value = sum(float(r['current_value_eur'] or 0) for r in results)
            avg_performance = sum(float(r['performance_percent'] or 0) for r in results) / len(results) if results else 0.0
            
            return {
                "total_value": total_value,
                "performance": avg_performance
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating portfolio metrics: {e}")
            return {}
    
    async def calculate_risk_metrics(self) -> Dict[str, float]:
        """Risk-Management-Metriken berechnen"""
        try:
            risk_query = """
                SELECT rule_type,
                       COUNT(*) as violations
                FROM risk_violations 
                WHERE created_at >= NOW() - INTERVAL '1 hour'
                GROUP BY rule_type
            """
            
            results = await self.event_store.execute_query(risk_query)
            total_violations = sum(r['violations'] for r in results)
            
            # Risk Exposure von Redis Cache
            exposure_data = await self.redis.get("risk:exposure:current")
            risk_exposure = float(exposure_data) if exposure_data else 0.0
            
            return {
                "violations": total_violations,
                "exposure": risk_exposure
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating risk metrics: {e}")
            return {}
    
    async def calculate_api_metrics(self) -> Dict[str, float]:
        """API-Integration-Metriken berechnen"""
        try:
            # Bitpanda API Calls aus Redis
            api_calls_data = await self.redis.get("api:bitpanda:calls:hourly")
            api_calls = int(api_calls_data) if api_calls_data else 0
            
            # Response Times
            response_times_data = await self.redis.lrange("api:response_times", 0, -1)
            response_times = [float(t) for t in response_times_data] if response_times_data else []
            avg_response_time = sum(response_times) / len(response_times) if response_times else 0.0
            
            return {
                "api_calls": api_calls,
                "avg_response_time": avg_response_time
            }
            
        except Exception as e:
            self.logger.error(f"Error calculating API metrics: {e}")
            return {}

class CustomMetricsCollector:
    """Custom Metrics Collector Service"""
    
    def __init__(self, config):
        self.config = config
        self.calculator = BusinessMetricsCalculator(
            event_store=EventStoreReader(),
            redis_client=RedisClient()
        )
        self.zabbix_sender = ZabbixSender(
            zabbix_server=config.zabbix_server,
            zabbix_port=config.zabbix_port
        )
        self.logger = logging.getLogger("metrics_collector")
    
    async def collect_and_send_custom_metrics(self):
        """Custom Metrics sammeln und senden"""
        try:
            # Business Metrics berechnen
            trading_metrics = await self.calculator.calculate_trading_metrics()
            portfolio_metrics = await self.calculator.calculate_portfolio_metrics()
            risk_metrics = await self.calculator.calculate_risk_metrics()
            api_metrics = await self.calculator.calculate_api_metrics()
            
            # Zabbix Metrics erstellen
            zabbix_metrics = []
            
            # Trading Metrics
            if trading_metrics:
                zabbix_metrics.extend([
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.orders.total",
                        value=trading_metrics.get("orders_total", 0)
                    ),
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.volume.eur",
                        value=trading_metrics.get("volume_eur", 0.0)
                    ),
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.success_rate",
                        value=trading_metrics.get("success_rate", 0.0)
                    )
                ])
            
            # Portfolio Metrics
            if portfolio_metrics:
                zabbix_metrics.extend([
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.portfolio.value",
                        value=portfolio_metrics.get("total_value", 0.0)
                    ),
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.portfolio.performance",
                        value=portfolio_metrics.get("performance", 0.0)
                    )
                ])
            
            # Risk Metrics
            if risk_metrics:
                zabbix_metrics.extend([
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.risk.violations",
                        value=risk_metrics.get("violations", 0)
                    ),
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.business.risk.exposure",
                        value=risk_metrics.get("exposure", 0.0)
                    )
                ])
            
            # API Metrics
            if api_metrics:
                zabbix_metrics.extend([
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.technical.api.bitpanda.calls",
                        value=api_metrics.get("api_calls", 0)
                    ),
                    ZabbixMetric(
                        host=self.config.hostname,
                        key="aktienanalyse.performance.api.response_time",
                        value=api_metrics.get("avg_response_time", 0.0)
                    )
                ])
            
            # An Zabbix senden
            if zabbix_metrics:
                response = self.zabbix_sender.send(zabbix_metrics)
                if response.failed == 0:
                    self.logger.info(f"Successfully sent {len(zabbix_metrics)} custom metrics")
                else:
                    self.logger.warning(f"Failed to send {response.failed} custom metrics")
            
        except Exception as e:
            self.logger.error(f"Error collecting custom metrics: {e}")
```

---

## 🎯 **2. SLA/SLO-DEFINITIONEN**

### 2.1 Service Level Objectives (SLO)

```yaml
# /opt/aktienanalyse-ökosystem/config/sla_slo_definitions.yaml
"""Service Level Agreements & Objectives für Aktienanalyse-Ökosystem"""

slo_definitions:
  # Aktienanalyse Core Service
  aktienanalyse_core:
    service_name: "Aktienanalyse Intelligent Core Service"
    description: "Zentrale Business-Logic für Portfolio-Management und Asset-Analyse"
    
    availability:
      target: 99.5  # 99.5% Uptime
      measurement_window: "30d"
      error_budget: 0.5  # 0.5% erlaubte Downtime
      calculation: "uptime_seconds / total_seconds * 100"
      
    performance:
      response_time_p95: 500  # 95% der Requests < 500ms
      response_time_p99: 2000  # 99% der Requests < 2s
      throughput_minimum: 100  # Min. 100 req/min
      measurement_window: "24h"
      
    reliability:
      error_rate_max: 0.1  # Max. 0.1% Error Rate
      success_rate_min: 99.9  # Min. 99.9% Success Rate
      measurement_window: "24h"
      
    business_metrics:
      portfolio_calculation_time: 30  # Max. 30s für Portfolio-Berechnung
      risk_assessment_time: 10  # Max. 10s für Risk-Assessment
      
  # Broker Gateway Service  
  aktienanalyse_broker:
    service_name: "Broker Gateway Service"
    description: "Integration mit externen Broker-APIs"
    
    availability:
      target: 99.0  # 99.0% Uptime (abhängig von externen APIs)
      measurement_window: "30d"
      error_budget: 1.0
      
    performance:
      response_time_p95: 2000  # 95% der Requests < 2s (externe API-Calls)
      response_time_p99: 5000  # 99% der Requests < 5s
      throughput_minimum: 50   # Min. 50 req/min
      
    reliability:
      error_rate_max: 2.0  # Max. 2% Error Rate (externe Abhängigkeiten)
      success_rate_min: 98.0  # Min. 98% Success Rate
      retry_success_rate: 95.0  # 95% Success nach Retry
      
    business_metrics:
      order_execution_time: 10  # Max. 10s für Order-Ausführung
      market_data_freshness: 30  # Max. 30s alte Market-Data
      
  # Event Bus Service
  aktienanalyse_events:
    service_name: "Event Bus Service"
    description: "Event-Driven Communication Hub"
    
    availability:
      target: 99.8  # 99.8% Uptime (kritische Infrastruktur)
      measurement_window: "30d"
      error_budget: 0.2
      
    performance:
      event_processing_lag: 1  # Max. 1s Event-Processing-Lag
      throughput_minimum: 1000  # Min. 1000 events/min
      message_size_max: 1024  # Max. 1KB per Message
      
    reliability:
      message_loss_rate: 0.001  # Max. 0.001% Message Loss
      duplicate_rate: 0.01  # Max. 0.01% Duplicates
      
    business_metrics:
      critical_event_delay: 5  # Max. 5s für kritische Events
      
  # Monitoring Service
  aktienanalyse_monitoring:
    service_name: "System Monitoring Service"
    description: "Monitoring und Health-Checks"
    
    availability:
      target: 99.0  # 99.0% Uptime
      measurement_window: "30d"
      error_budget: 1.0
      
    performance:
      metrics_collection_interval: 30  # Max. 30s zwischen Collections
      alert_delivery_time: 60  # Max. 60s für Alert-Delivery
      
    reliability:
      metrics_accuracy: 99.5  # 99.5% korrekte Metriken
      false_positive_rate: 1.0  # Max. 1% False Positives
      
  # Frontend Service
  aktienanalyse_frontend:
    service_name: "Web Frontend Service"
    description: "React-basierte Benutzeroberfläche"
    
    availability:
      target: 99.0  # 99.0% Uptime
      measurement_window: "30d"
      error_budget: 1.0
      
    performance:
      page_load_time_p95: 3000  # 95% der Pages < 3s
      first_contentful_paint: 1500  # < 1.5s FCP
      time_to_interactive: 5000  # < 5s TTI
      
    reliability:
      javascript_error_rate: 0.5  # Max. 0.5% JS Errors
      api_integration_success: 99.0  # 99% API Integration Success

# Service Level Agreements (SLA)
sla_definitions:
  # Business-Critical Services
  business_critical:
    services: ["aktienanalyse_core", "aktienanalyse_events"]
    availability_commitment: 99.5
    performance_commitment:
      response_time_p95: 500
      error_rate_max: 0.1
    penalty_structure:
      availability_below_99: "5% monthly credit"
      availability_below_98: "10% monthly credit"
      availability_below_95: "25% monthly credit"
    
  # Integration Services
  integration_services:
    services: ["aktienanalyse_broker"]
    availability_commitment: 99.0
    performance_commitment:
      response_time_p95: 2000
      error_rate_max: 2.0
    notes: "Abhängig von externen Broker-API-Verfügbarkeit"
    
  # Supporting Services
  supporting_services:
    services: ["aktienanalyse_monitoring", "aktienanalyse_frontend"]
    availability_commitment: 99.0
    performance_commitment:
      response_time_p95: 3000
      error_rate_max: 1.0

# Alert-Thresholds basierend auf SLO
alert_thresholds:
  # Availability Alerts
  availability:
    warning_threshold: 0.8  # 80% des Error-Budgets verbraucht
    critical_threshold: 0.95  # 95% des Error-Budgets verbraucht
    
  # Performance Alerts  
  performance:
    response_time_warning: 0.8  # 80% des SLO-Targets
    response_time_critical: 1.0  # 100% des SLO-Targets überschritten
    
  # Error Rate Alerts
  error_rate:
    warning_multiplier: 0.5  # 50% des SLO-Targets
    critical_multiplier: 1.0  # 100% des SLO-Targets erreicht

# Measurement & Reporting
measurement:
  collection_interval: 60  # Alle 60 Sekunden
  aggregation_windows: ["1m", "5m", "1h", "24h", "7d", "30d"]
  retention:
    raw_data: "7d"
    aggregated_data: "365d"
  
reporting:
  slo_reports:
    frequency: "weekly"
    recipients: ["team@aktienanalyse.local"]
    format: "dashboard_link"
  
  sla_reports:
    frequency: "monthly"
    recipients: ["management@aktienanalyse.local"]
    format: "pdf_report"
    
  error_budget_alerts:
    thresholds: [50, 80, 95, 100]  # % des Error-Budgets
    escalation: ["team", "team_lead", "management"]
```

### 2.2 SLO Monitoring Implementation

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/slo_monitor.py
"""SLO Monitoring und Error Budget Tracking"""

import asyncio
import yaml
from datetime import datetime, timedelta
from typing import Dict, List
from dataclasses import dataclass

@dataclass
class SLOStatus:
    service_name: str
    metric_name: str
    current_value: float
    target_value: float
    error_budget_consumed: float
    status: str  # "healthy", "warning", "critical"
    measurement_window: str
    last_updated: datetime

class SLOMonitor:
    """SLO Monitoring Service"""
    
    def __init__(self, config_path: str):
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
        self.logger = logging.getLogger("slo_monitor")
    
    async def calculate_availability_slo(self, service_name: str, window: str) -> SLOStatus:
        """Availability SLO berechnen"""
        slo_config = self.config['slo_definitions'][service_name]
        target = slo_config['availability']['target']
        
        # Uptime aus Monitoring-Daten abrufen
        uptime_query = f"""
            SELECT 
                COUNT(*) as total_checks,
                COUNT(CASE WHEN status = 'healthy' THEN 1 END) as healthy_checks
            FROM service_health_checks 
            WHERE service_name = '{service_name}'
              AND timestamp >= NOW() - INTERVAL '{window}'
        """
        
        result = await self.event_store.execute_query(uptime_query)
        
        if result and result[0]['total_checks'] > 0:
            availability = (result[0]['healthy_checks'] / result[0]['total_checks']) * 100
            error_budget_consumed = max(0, (target - availability) / (100 - target) * 100)
            
            status = "healthy"
            if error_budget_consumed > 80:
                status = "critical"
            elif error_budget_consumed > 50:
                status = "warning"
            
            return SLOStatus(
                service_name=service_name,
                metric_name="availability",
                current_value=availability,
                target_value=target,
                error_budget_consumed=error_budget_consumed,
                status=status,
                measurement_window=window,
                last_updated=datetime.now()
            )
        
        return None
    
    async def calculate_performance_slo(self, service_name: str, window: str) -> List[SLOStatus]:
        """Performance SLOs berechnen"""
        slo_config = self.config['slo_definitions'][service_name]
        performance_config = slo_config['performance']
        
        slo_statuses = []
        
        # Response Time P95
        if 'response_time_p95' in performance_config:
            target = performance_config['response_time_p95']
            
            p95_query = f"""
                SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY response_time_ms) as p95_response_time
                FROM service_metrics 
                WHERE service_name = '{service_name}'
                  AND metric_name = 'response_time'
                  AND timestamp >= NOW() - INTERVAL '{window}'
            """
            
            result = await self.event_store.execute_query(p95_query)
            
            if result and result[0]['p95_response_time']:
                current_p95 = float(result[0]['p95_response_time'])
                error_budget_consumed = max(0, (current_p95 - target) / target * 100) if current_p95 > target else 0
                
                status = "healthy"
                if current_p95 > target * 1.2:
                    status = "critical"
                elif current_p95 > target:
                    status = "warning"
                
                slo_statuses.append(SLOStatus(
                    service_name=service_name,
                    metric_name="response_time_p95",
                    current_value=current_p95,
                    target_value=target,
                    error_budget_consumed=error_budget_consumed,
                    status=status,
                    measurement_window=window,
                    last_updated=datetime.now()
                ))
        
        return slo_statuses
    
    async def calculate_reliability_slo(self, service_name: str, window: str) -> List[SLOStatus]:
        """Reliability SLOs berechnen"""
        slo_config = self.config['slo_definitions'][service_name]
        reliability_config = slo_config['reliability']
        
        slo_statuses = []
        
        # Error Rate
        if 'error_rate_max' in reliability_config:
            target = reliability_config['error_rate_max']
            
            error_rate_query = f"""
                SELECT 
                    COUNT(*) as total_requests,
                    COUNT(CASE WHEN status_code >= 400 THEN 1 END) as error_requests
                FROM service_requests 
                WHERE service_name = '{service_name}'
                  AND timestamp >= NOW() - INTERVAL '{window}'
            """
            
            result = await self.event_store.execute_query(error_rate_query)
            
            if result and result[0]['total_requests'] > 0:
                error_rate = (result[0]['error_requests'] / result[0]['total_requests']) * 100
                error_budget_consumed = (error_rate / target * 100) if error_rate > 0 else 0
                
                status = "healthy"
                if error_rate > target * 2:
                    status = "critical"
                elif error_rate > target:
                    status = "warning"
                
                slo_statuses.append(SLOStatus(
                    service_name=service_name,
                    metric_name="error_rate",
                    current_value=error_rate,
                    target_value=target,
                    error_budget_consumed=error_budget_consumed,
                    status=status,
                    measurement_window=window,
                    last_updated=datetime.now()
                ))
        
        return slo_statuses
    
    async def generate_slo_report(self, time_period: str = "24h") -> Dict[str, List[SLOStatus]]:
        """SLO Report generieren"""
        report = {}
        
        for service_name in self.config['slo_definitions'].keys():
            service_slos = []
            
            # Availability SLO
            availability_slo = await self.calculate_availability_slo(service_name, time_period)
            if availability_slo:
                service_slos.append(availability_slo)
            
            # Performance SLOs
            performance_slos = await self.calculate_performance_slo(service_name, time_period)
            service_slos.extend(performance_slos)
            
            # Reliability SLOs
            reliability_slos = await self.calculate_reliability_slo(service_name, time_period)
            service_slos.extend(reliability_slos)
            
            report[service_name] = service_slos
        
        return report
```

---

## 📊 **3. ERWEITERTE DASHBOARD-SPEZIFIKATIONEN**

### 3.1 Zabbix Dashboard-Konfigurationen

```json
{
  "zabbix_export": {
    "version": "6.0",
    "date": "2024-01-15T10:00:00Z",
    "dashboards": [
      {
        "uuid": "dashboard-aktienanalyse-overview",
        "name": "Aktienanalyse Ecosystem - Overview",
        "pages": [
          {
            "name": "System Overview",
            "widgets": [
              {
                "type": "PLAIN_TEXT",
                "name": "System Status",
                "x": 0,
                "y": 0,
                "width": 6,
                "height": 3,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.system.status"
                  },
                  {
                    "type": "STRING",
                    "name": "show",
                    "value": "1"
                  }
                ]
              },
              {
                "type": "GRAPH_CLASSIC",
                "name": "System Resources",
                "x": 6,
                "y": 0,
                "width": 12,
                "height": 5,
                "fields": [
                  {
                    "type": "GRAPH",
                    "name": "graphid",
                    "value": "system-resources-graph"
                  }
                ]
              },
              {
                "type": "PLAIN_TEXT",
                "name": "Service Health",
                "x": 0,
                "y": 3,
                "width": 6,
                "height": 5,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.services.health.summary"
                  }
                ]
              }
            ]
          },
          {
            "name": "Business Metrics",
            "widgets": [
              {
                "type": "GRAPH_CLASSIC",
                "name": "Trading Volume (24h)",
                "x": 0,
                "y": 0,
                "width": 12,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.business.volume.eur"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Portfolio Performance",
                "x": 12,
                "y": 0,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.business.portfolio.performance"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "-20"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "20"
                  }
                ]
              },
              {
                "type": "PIE_CHART",
                "name": "Order Status Distribution",
                "x": 0,
                "y": 4,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.business.orders.by_status"
                  }
                ]
              },
              {
                "type": "PLAIN_TEXT",
                "name": "Risk Violations",
                "x": 6,
                "y": 4,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids", 
                    "value": "aktienanalyse.business.risk.violations"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Trading Success Rate",
                "x": 12,
                "y": 4,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.business.success_rate"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "0"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "100"
                  }
                ]
              }
            ]
          },
          {
            "name": "Performance Metrics",
            "widgets": [
              {
                "type": "GRAPH_CLASSIC",
                "name": "API Response Times",
                "x": 0,
                "y": 0,
                "width": 12,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.performance.api.response_time"
                  }
                ]
              },
              {
                "type": "GRAPH_CLASSIC",
                "name": "Database Query Performance",
                "x": 12,
                "y": 0,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.performance.database.query_time"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Cache Hit Rate",
                "x": 0,
                "y": 4,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.performance.cache.hit_rate"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "0"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "100"
                  }
                ]
              },
              {
                "type": "PLAIN_TEXT",
                "name": "Event Processing Lag",
                "x": 6,
                "y": 4,
                "width": 6,
                "height": 4,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.performance.events.lag"
                  }
                ]
              }
            ]
          },
          {
            "name": "SLO Dashboard",
            "widgets": [
              {
                "type": "PLAIN_TEXT",
                "name": "SLO Status Summary",
                "x": 0,
                "y": 0,
                "width": 18,
                "height": 2,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.slo.summary"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Core Service Availability",
                "x": 0,
                "y": 2,
                "width": 6,
                "height": 3,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.slo.core.availability"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "95"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "100"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Broker Service Availability",
                "x": 6,
                "y": 2,
                "width": 6,
                "height": 3,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.slo.broker.availability"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "95"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "100"
                  }
                ]
              },
              {
                "type": "GAUGE",
                "name": "Events Service Availability",
                "x": 12,
                "y": 2,
                "width": 6,
                "height": 3,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.slo.events.availability"
                  },
                  {
                    "type": "STRING",
                    "name": "min",
                    "value": "95"
                  },
                  {
                    "type": "STRING",
                    "name": "max",
                    "value": "100"
                  }
                ]
              },
              {
                "type": "GRAPH_CLASSIC",
                "name": "Error Budget Consumption",
                "x": 0,
                "y": 5,
                "width": 18,
                "height": 3,
                "fields": [
                  {
                    "type": "ITEM",
                    "name": "itemids",
                    "value": "aktienanalyse.slo.error_budget.consumption"
                  }
                ]
              }
            ]
          }
        ]
      }
    ]
  }
}
```

### 3.2 Custom Dashboard Service

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/dashboard_service.py
"""Custom Dashboard Service für erweiterte Visualisierungen"""

import asyncio
import json
from datetime import datetime, timedelta
from typing import Dict, List, Any
from aiohttp import web
import aiohttp_cors

class DashboardService:
    """Custom Dashboard Backend Service"""
    
    def __init__(self, config):
        self.config = config
        self.app = self._create_web_app()
        self.logger = logging.getLogger("dashboard_service")
    
    def _create_web_app(self):
        """Web-App für Dashboard-APIs erstellen"""
        app = web.Application()
        
        # CORS konfigurieren
        cors = aiohttp_cors.setup(app, defaults={
            "*": aiohttp_cors.ResourceOptions(
                allow_credentials=True,
                expose_headers="*",
                allow_headers="*",
                allow_methods="*"
            )
        })
        
        # Routes
        app.router.add_get('/api/dashboard/business-overview', self.business_overview)
        app.router.add_get('/api/dashboard/performance-metrics', self.performance_metrics)
        app.router.add_get('/api/dashboard/slo-status', self.slo_status)
        app.router.add_get('/api/dashboard/real-time-data', self.real_time_data)
        
        # CORS für alle Routes aktivieren
        for route in list(app.router.routes()):
            cors.add(route)
        
        return app
    
    async def business_overview(self, request):
        """Business-Overview-Daten"""
        try:
            # Portfolio-Daten
            portfolio_data = await self._get_portfolio_summary()
            
            # Trading-Daten
            trading_data = await self._get_trading_summary()
            
            # Risk-Daten
            risk_data = await self._get_risk_summary()
            
            overview = {
                "timestamp": datetime.now().isoformat(),
                "portfolio": portfolio_data,
                "trading": trading_data,
                "risk": risk_data
            }
            
            return web.json_response(overview)
            
        except Exception as e:
            self.logger.error(f"Error getting business overview: {e}")
            return web.json_response(
                {"error": "Internal server error"},
                status=500
            )
    
    async def performance_metrics(self, request):
        """Performance-Metriken-Daten"""
        try:
            time_range = request.query.get('range', '24h')
            
            # API Performance
            api_metrics = await self._get_api_performance(time_range)
            
            # Database Performance
            db_metrics = await self._get_database_performance(time_range)
            
            # System Performance
            system_metrics = await self._get_system_performance(time_range)
            
            performance = {
                "timestamp": datetime.now().isoformat(),
                "time_range": time_range,
                "api": api_metrics,
                "database": db_metrics,
                "system": system_metrics
            }
            
            return web.json_response(performance)
            
        except Exception as e:
            self.logger.error(f"Error getting performance metrics: {e}")
            return web.json_response(
                {"error": "Internal server error"},
                status=500
            )
    
    async def slo_status(self, request):
        """SLO-Status-Daten"""
        try:
            # SLO Monitor verwenden
            slo_monitor = SLOMonitor('/opt/aktienanalyse-ökosystem/config/sla_slo_definitions.yaml')
            
            time_period = request.query.get('period', '24h')
            slo_report = await slo_monitor.generate_slo_report(time_period)
            
            # Error Budget Consumption berechnen
            error_budget_data = await self._calculate_error_budget_status(slo_report)
            
            slo_status = {
                "timestamp": datetime.now().isoformat(),
                "period": time_period,
                "services": slo_report,
                "error_budget": error_budget_data,
                "overall_health": await self._calculate_overall_health(slo_report)
            }
            
            return web.json_response(slo_status)
            
        except Exception as e:
            self.logger.error(f"Error getting SLO status: {e}")
            return web.json_response(
                {"error": "Internal server error"},
                status=500
            )
    
    async def real_time_data(self, request):
        """Real-time Dashboard-Daten"""
        try:
            # WebSocket für Real-time Updates
            ws = web.WebSocketResponse()
            await ws.prepare(request)
            
            try:
                while True:
                    # Real-time Daten sammeln
                    real_time_data = {
                        "timestamp": datetime.now().isoformat(),
                        "active_users": await self._get_active_users(),
                        "current_orders": await self._get_current_orders(),
                        "system_load": await self._get_current_system_load(),
                        "alerts": await self._get_active_alerts()
                    }
                    
                    await ws.send_str(json.dumps(real_time_data))
                    await asyncio.sleep(5)  # Update alle 5 Sekunden
                    
            except Exception as e:
                self.logger.error(f"WebSocket error: {e}")
            finally:
                await ws.close()
            
            return ws
            
        except Exception as e:
            self.logger.error(f"Error in real-time data: {e}")
            return web.json_response(
                {"error": "WebSocket connection failed"},
                status=500
            )
    
    async def _get_portfolio_summary(self) -> Dict[str, Any]:
        """Portfolio-Zusammenfassung"""
        # Implementation für Portfolio-Daten
        return {
            "total_value": 50000.0,
            "daily_change": 2.5,
            "performance_30d": 8.2,
            "portfolio_count": 3,
            "top_performers": [
                {"symbol": "AAPL", "change": 3.2},
                {"symbol": "MSFT", "change": 2.8}
            ]
        }
    
    async def _get_trading_summary(self) -> Dict[str, Any]:
        """Trading-Zusammenfassung"""
        # Implementation für Trading-Daten
        return {
            "orders_today": 15,
            "volume_today": 5000.0,
            "success_rate": 85.5,
            "avg_execution_time": 2.3,
            "pending_orders": 3
        }
    
    async def _get_risk_summary(self) -> Dict[str, Any]:
        """Risk-Zusammenfassung"""
        # Implementation für Risk-Daten
        return {
            "current_exposure": 65.0,
            "violations_today": 0,
            "var_95": 2500.0,
            "risk_score": "LOW"
        }
    
    async def start_server(self, host: str = "localhost", port: int = 8005):
        """Dashboard Server starten"""
        try:
            runner = web.AppRunner(self.app)
            await runner.setup()
            
            site = web.TCPSite(runner, host, port)
            await site.start()
            
            self.logger.info(f"Dashboard service started on http://{host}:{port}")
            
        except Exception as e:
            self.logger.error(f"Error starting dashboard server: {e}")
```

---

## ⚠️ **4. ALERT-KONFIGURATIONEN**

### 4.1 Zabbix Alert-Rules

```yaml
# /opt/aktienanalyse-ökosystem/config/alert_rules.yaml
"""Alert-Rules-Konfiguration für Zabbix"""

alert_rules:
  # Business-Critical Alerts
  business_critical:
    trading_system_down:
      name: "Trading System Down"
      description: "Trading-Service ist nicht verfügbar"
      severity: "disaster"
      expression: "last(/aktienanalyse-core/aktienanalyse.services.trading.status)=0"
      recovery_expression: "last(/aktienanalyse-core/aktienanalyse.services.trading.status)=1"
      trigger_duration: "60s"
      escalation:
        - step: 1
          delay: "0s"
          action: "immediate_notification"
          recipients: ["team_lead", "sms_oncall"]
        - step: 2
          delay: "300s"
          action: "escalate_to_management"
          recipients: ["management", "phone_oncall"]
    
    portfolio_value_crash:
      name: "Portfolio Value Crash"
      description: "Portfolio-Wert fällt um mehr als 15% in 1 Stunde"
      severity: "high"
      expression: "(last(/aktienanalyse-core/aktienanalyse.business.portfolio.value)-avg(/aktienanalyse-core/aktienanalyse.business.portfolio.value,1h))/avg(/aktienanalyse-core/aktienanalyse.business.portfolio.value,1h)*100<-15"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "immediate_notification"
          recipients: ["team_lead", "email_urgent"]
    
    risk_violations_spike:
      name: "Risk Violations Spike"
      description: "Mehr als 10 Risk-Violations in 1 Stunde"
      severity: "warning"
      expression: "sum(/aktienanalyse-core/aktienanalyse.business.risk.violations,1h)>10"
      trigger_duration: "60s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
  
  # Performance Alerts
  performance:
    api_response_time_high:
      name: "API Response Time High"
      description: "API-Response-Zeit über 2 Sekunden"
      severity: "warning"
      expression: "avg(/aktienanalyse-core/aktienanalyse.performance.api.response_time,5m)>2000"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
    
    database_query_slow:
      name: "Database Query Slow"
      description: "Database-Queries dauern länger als 1 Sekunde"
      severity: "warning"
      expression: "avg(/aktienanalyse-core/aktienanalyse.performance.database.query_time,5m)>1000"
      trigger_duration: "600s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
    
    cache_hit_rate_low:
      name: "Cache Hit Rate Low"
      description: "Cache-Hit-Rate unter 80%"
      severity: "warning"
      expression: "avg(/aktienanalyse-core/aktienanalyse.performance.cache.hit_rate,10m)<80"
      trigger_duration: "600s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
    
    event_processing_lag:
      name: "Event Processing Lag"
      description: "Event-Processing-Lag über 30 Sekunden"
      severity: "warning"
      expression: "last(/aktienanalyse-events/aktienanalyse.performance.events.lag)>30"
      trigger_duration: "180s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
  
  # System Resource Alerts
  system:
    cpu_usage_high:
      name: "CPU Usage High"
      description: "CPU-Nutzung über 80% für 5 Minuten"
      severity: "warning"
      expression: "avg(/aktienanalyse-host/system.cpu.util,5m)>80"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
    
    memory_usage_critical:
      name: "Memory Usage Critical"
      description: "Memory-Nutzung über 90%"
      severity: "high"
      expression: "last(/aktienanalyse-host/vm.memory.util)>90"
      trigger_duration: "120s"
      escalation:
        - step: 1
          delay: "0s"
          action: "immediate_notification"
          recipients: ["team_lead", "sms_oncall"]
    
    disk_space_low:
      name: "Disk Space Low"
      description: "Freier Speicherplatz unter 10%"
      severity: "warning"
      expression: "last(/aktienanalyse-host/vfs.fs.pused[/])>90"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
    
    database_connections_high:
      name: "Database Connections High"
      description: "Database-Verbindungen über 80% der maximalen Anzahl"
      severity: "warning"
      expression: "last(/aktienanalyse-core/aktienanalyse.technical.database.connections)>80"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "team_notification"
          recipients: ["team_channel"]
  
  # Security Alerts
  security:
    authentication_failures:
      name: "Multiple Authentication Failures"
      description: "Mehr als 50 fehlgeschlagene Authentifizierungen in 10 Minuten"
      severity: "warning"
      expression: "sum(/aktienanalyse-core/aktienanalyse.security.auth.attempts[failed],10m)>50"
      trigger_duration: "60s"
      escalation:
        - step: 1
          delay: "0s"
          action: "security_notification"
          recipients: ["security_team"]
    
    unusual_api_usage:
      name: "Unusual API Usage"
      description: "API-Nutzung 300% über normalem Wert"
      severity: "warning"
      expression: "sum(/aktienanalyse-core/aktienanalyse.technical.api.bitpanda.calls,1h)>avg(/aktienanalyse-core/aktienanalyse.technical.api.bitpanda.calls,1d)*3"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "security_notification"
          recipients: ["security_team"]
    
    security_errors:
      name: "Security Errors"
      description: "Security-relevante Fehler aufgetreten"
      severity: "high"
      expression: "sum(/aktienanalyse-core/aktienanalyse.security.errors,1h)>0"
      trigger_duration: "60s"
      escalation:
        - step: 1
          delay: "0s"
          action: "immediate_notification"
          recipients: ["security_team", "team_lead"]
  
  # SLO Violation Alerts
  slo_violations:
    availability_slo_breach:
      name: "Availability SLO Breach"
      description: "Service-Verfügbarkeit unter SLO-Target"
      severity: "high"
      expression: "last(/aktienanalyse-core/aktienanalyse.slo.core.availability)<99.5"
      trigger_duration: "300s"
      escalation:
        - step: 1
          delay: "0s"
          action: "slo_notification"
          recipients: ["team_lead", "sre_team"]
    
    error_budget_exhausted:
      name: "Error Budget 80% Exhausted"
      description: "Error-Budget zu 80% aufgebraucht"
      severity: "warning"
      expression: "last(/aktienanalyse-core/aktienanalyse.slo.error_budget.consumption)>80"
      trigger_duration: "60s"
      escalation:
        - step: 1
          delay: "0s"
          action: "slo_notification"
          recipients: ["sre_team"]

# Notification Channels
notification_channels:
  team_channel:
    type: "slack"
    webhook_url: "${SLACK_WEBHOOK_URL}"
    channel: "#aktienanalyse-alerts"
    format: "detailed"
  
  team_lead:
    type: "email"
    recipients: ["teamlead@aktienanalyse.local"]
    format: "technical"
  
  management:
    type: "email"
    recipients: ["management@aktienanalyse.local"]
    format: "business"
  
  sms_oncall:
    type: "sms"
    recipients: ["+49123456789"]
    format: "minimal"
  
  phone_oncall:
    type: "phone"
    recipients: ["+49123456789"]
    format: "voice"
  
  security_team:
    type: "email"
    recipients: ["security@aktienanalyse.local"]
    format: "security"
  
  sre_team:
    type: "email"
    recipients: ["sre@aktienanalyse.local"]
    format: "slo"

# Alert Suppression Rules
suppression_rules:
  maintenance_windows:
    - name: "Weekly Maintenance"
      schedule: "0 2 * * SUN"  # Sonntag 2:00 AM
      duration: "2h"
      services: ["all"]
      severity: ["warning"]
  
  dependency_suppression:
    - name: "Database Down Suppression"
      trigger: "database_connection_failed"
      suppress_alerts: ["api_response_time_high", "event_processing_lag"]
      duration: "until_recovery"
```

### 4.2 Alert Manager Implementation

```python
# /opt/aktienanalyse-ökosystem/services/monitoring/alert_manager.py
"""Alert Manager für intelligente Alert-Behandlung"""

import asyncio
import yaml
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional
from dataclasses import dataclass
from enum import Enum

class AlertSeverity(Enum):
    INFO = "info"
    WARNING = "warning"
    HIGH = "high"
    DISASTER = "disaster"

class AlertStatus(Enum):
    TRIGGERED = "triggered"
    ACKNOWLEDGED = "acknowledged"
    RESOLVED = "resolved"
    SUPPRESSED = "suppressed"

@dataclass
class Alert:
    id: str
    name: str
    description: str
    severity: AlertSeverity
    status: AlertStatus
    triggered_at: datetime
    last_updated: datetime
    source_service: str
    metric_value: float
    threshold_value: float
    escalation_level: int
    suppressed_until: Optional[datetime] = None
    acknowledged_by: Optional[str] = None
    resolved_at: Optional[datetime] = None

class AlertManager:
    """Intelligenter Alert Manager"""
    
    def __init__(self, config_path: str):
        with open(config_path, 'r') as f:
            self.config = yaml.safe_load(f)
        
        self.active_alerts: Dict[str, Alert] = {}
        self.alert_history: List[Alert] = []
        self.suppression_rules = self.config.get('suppression_rules', {})
        self.notification_channels = self.config.get('notification_channels', {})
        self.logger = logging.getLogger("alert_manager")
    
    async def process_alert(self, alert_data: Dict) -> Alert:
        """Alert verarbeiten und entsprechende Aktionen ausführen"""
        alert_id = alert_data.get('alert_id')
        
        # Prüfen ob Alert bereits existiert
        if alert_id in self.active_alerts:
            return await self._update_existing_alert(alert_id, alert_data)
        else:
            return await self._create_new_alert(alert_data)
    
    async def _create_new_alert(self, alert_data: Dict) -> Alert:
        """Neuen Alert erstellen"""
        alert = Alert(
            id=alert_data['alert_id'],
            name=alert_data['name'],
            description=alert_data['description'],
            severity=AlertSeverity(alert_data['severity']),
            status=AlertStatus.TRIGGERED,
            triggered_at=datetime.now(),
            last_updated=datetime.now(),
            source_service=alert_data['source_service'],
            metric_value=alert_data['metric_value'],
            threshold_value=alert_data['threshold_value'],
            escalation_level=0
        )
        
        # Suppression Rules prüfen
        if await self._is_suppressed(alert):
            alert.status = AlertStatus.SUPPRESSED
            alert.suppressed_until = await self._calculate_suppression_end(alert)
            self.logger.info(f"Alert {alert.id} suppressed until {alert.suppressed_until}")
        else:
            # Alert-Notification senden
            await self._send_alert_notification(alert)
            
        self.active_alerts[alert.id] = alert
        self.alert_history.append(alert)
        
        return alert
    
    async def _update_existing_alert(self, alert_id: str, alert_data: Dict) -> Alert:
        """Existierenden Alert aktualisieren"""
        alert = self.active_alerts[alert_id]
        alert.last_updated = datetime.now()
        alert.metric_value = alert_data['metric_value']
        
        # Prüfen ob Alert sich verschlechtert hat
        if alert_data['severity'] != alert.severity.value:
            old_severity = alert.severity
            alert.severity = AlertSeverity(alert_data['severity'])
            
            if self._is_severity_escalation(old_severity, alert.severity):
                alert.escalation_level += 1
                await self._send_escalation_notification(alert)
                self.logger.warning(f"Alert {alert.id} escalated from {old_severity} to {alert.severity}")
        
        return alert
    
    async def acknowledge_alert(self, alert_id: str, acknowledged_by: str) -> bool:
        """Alert bestätigen"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.status = AlertStatus.ACKNOWLEDGED
            alert.acknowledged_by = acknowledged_by
            alert.last_updated = datetime.now()
            
            await self._send_acknowledgment_notification(alert)
            self.logger.info(f"Alert {alert_id} acknowledged by {acknowledged_by}")
            return True
        
        return False
    
    async def resolve_alert(self, alert_id: str) -> bool:
        """Alert als gelöst markieren"""
        if alert_id in self.active_alerts:
            alert = self.active_alerts[alert_id]
            alert.status = AlertStatus.RESOLVED
            alert.resolved_at = datetime.now()
            alert.last_updated = datetime.now()
            
            # Aus aktiven Alerts entfernen
            del self.active_alerts[alert_id]
            
            await self._send_resolution_notification(alert)
            self.logger.info(f"Alert {alert_id} resolved")
            return True
        
        return False
    
    async def _is_suppressed(self, alert: Alert) -> bool:
        """Prüfen ob Alert suppressed werden soll"""
        current_time = datetime.now()
        
        # Maintenance Windows prüfen
        for window in self.suppression_rules.get('maintenance_windows', []):
            if self._is_in_maintenance_window(current_time, window):
                if alert.severity.value in window.get('severity', []):
                    return True
        
        # Dependency Suppression prüfen
        for rule in self.suppression_rules.get('dependency_suppression', []):
            if self._check_dependency_suppression(alert, rule):
                return True
        
        return False
    
    async def _send_alert_notification(self, alert: Alert):
        """Alert-Notification senden"""
        alert_rule = self._get_alert_rule(alert.name)
        if not alert_rule:
            return
        
        escalation_steps = alert_rule.get('escalation', [])
        if escalation_steps and len(escalation_steps) > alert.escalation_level:
            step = escalation_steps[alert.escalation_level]
            
            for recipient in step.get('recipients', []):
                if recipient in self.notification_channels:
                    channel = self.notification_channels[recipient]
                    await self._send_notification(alert, channel)
    
    async def _send_notification(self, alert: Alert, channel: Dict):
        """Notification über spezifischen Channel senden"""
        try:
            if channel['type'] == 'slack':
                await self._send_slack_notification(alert, channel)
            elif channel['type'] == 'email':
                await self._send_email_notification(alert, channel)
            elif channel['type'] == 'sms':
                await self._send_sms_notification(alert, channel)
            elif channel['type'] == 'phone':
                await self._send_phone_notification(alert, channel)
                
        except Exception as e:
            self.logger.error(f"Failed to send notification via {channel['type']}: {e}")
    
    async def _send_slack_notification(self, alert: Alert, channel: Dict):
        """Slack-Notification senden"""
        import aiohttp
        
        color_map = {
            AlertSeverity.INFO: "good",
            AlertSeverity.WARNING: "warning", 
            AlertSeverity.HIGH: "danger",
            AlertSeverity.DISASTER: "danger"
        }
        
        message = {
            "channel": channel['channel'],
            "attachments": [{
                "color": color_map[alert.severity],
                "title": f"🚨 {alert.name}",
                "text": alert.description,
                "fields": [
                    {"title": "Severity", "value": alert.severity.value.upper(), "short": True},
                    {"title": "Service", "value": alert.source_service, "short": True},
                    {"title": "Current Value", "value": str(alert.metric_value), "short": True},
                    {"title": "Threshold", "value": str(alert.threshold_value), "short": True}
                ],
                "ts": int(alert.triggered_at.timestamp())
            }]
        }
        
        async with aiohttp.ClientSession() as session:
            async with session.post(channel['webhook_url'], json=message) as response:
                if response.status != 200:
                    self.logger.error(f"Failed to send Slack notification: {response.status}")
    
    async def get_active_alerts(self) -> List[Alert]:
        """Alle aktiven Alerts abrufen"""
        return list(self.active_alerts.values())
    
    async def get_alert_statistics(self, time_period: str = "24h") -> Dict:
        """Alert-Statistiken berechnen"""
        end_time = datetime.now()
        
        if time_period == "24h":
            start_time = end_time - timedelta(hours=24)
        elif time_period == "7d":
            start_time = end_time - timedelta(days=7)
        else:
            start_time = end_time - timedelta(hours=24)
        
        period_alerts = [
            alert for alert in self.alert_history
            if start_time <= alert.triggered_at <= end_time
        ]
        
        stats = {
            "total_alerts": len(period_alerts),
            "by_severity": {},
            "by_service": {},
            "avg_resolution_time": 0,
            "escalation_rate": 0
        }
        
        # Severity-Verteilung
        for severity in AlertSeverity:
            count = len([a for a in period_alerts if a.severity == severity])
            stats["by_severity"][severity.value] = count
        
        # Service-Verteilung
        service_counts = {}
        for alert in period_alerts:
            service = alert.source_service
            service_counts[service] = service_counts.get(service, 0) + 1
        stats["by_service"] = service_counts
        
        # Resolution Time
        resolved_alerts = [a for a in period_alerts if a.resolved_at]
        if resolved_alerts:
            total_resolution_time = sum(
                (a.resolved_at - a.triggered_at).total_seconds() 
                for a in resolved_alerts
            )
            stats["avg_resolution_time"] = total_resolution_time / len(resolved_alerts)
        
        # Escalation Rate
        escalated_alerts = [a for a in period_alerts if a.escalation_level > 0]
        if period_alerts:
            stats["escalation_rate"] = len(escalated_alerts) / len(period_alerts) * 100
        
        return stats
```

---

## 📋 **5. LOG-AGGREGATION & DISTRIBUTED TRACING**

### 5.1 Strukturiertes Logging

```python
# /opt/aktienanalyse-ökosystem/shared/logging/structured_logger.py
"""Strukturiertes Logging für alle Services"""

import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
import traceback
from contextvars import ContextVar

# Context Variables für Request Tracing
request_id_var: ContextVar[str] = ContextVar('request_id', default='')
user_id_var: ContextVar[str] = ContextVar('user_id', default='')
service_name_var: ContextVar[str] = ContextVar('service_name', default='')

class StructuredFormatter(logging.Formatter):
    """Custom Formatter für strukturierte Logs"""
    
    def format(self, record):
        # Basis Log-Struktur
        log_entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "level": record.levelname,
            "service": service_name_var.get(),
            "module": record.module,
            "function": record.funcName,
            "line": record.lineno,
            "message": record.getMessage(),
            "request_id": request_id_var.get(),
            "user_id": user_id_var.get()
        }
        
        # Exception-Details
        if record.exc_info:
            log_entry["exception"] = {
                "type": record.exc_info[0].__name__,
                "message": str(record.exc_info[1]),
                "traceback": traceback.format_exception(*record.exc_info)
            }
        
        # Custom Fields aus LogRecord
        for key, value in record.__dict__.items():
            if key.startswith('custom_'):
                log_entry[key[7:]] = value  # Remove 'custom_' prefix
        
        return json.dumps(log_entry, ensure_ascii=False)

class BusinessLogger:
    """Business-Event-Logger für fachliche Ereignisse"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.logger = logging.getLogger(f"{service_name}.business")
    
    def log_portfolio_update(self, portfolio_id: str, old_value: float, new_value: float, change_reason: str):
        """Portfolio-Update loggen"""
        self.logger.info(
            "Portfolio value updated",
            extra={
                "custom_event_type": "portfolio_update",
                "custom_portfolio_id": portfolio_id,
                "custom_old_value": old_value,
                "custom_new_value": new_value,
                "custom_change_percent": ((new_value - old_value) / old_value) * 100,
                "custom_change_reason": change_reason
            }
        )
    
    def log_trade_execution(self, order_id: str, symbol: str, quantity: float, price: float, order_type: str, execution_time: float):
        """Trade-Ausführung loggen"""
        self.logger.info(
            "Trade executed",
            extra={
                "custom_event_type": "trade_execution",
                "custom_order_id": order_id,
                "custom_symbol": symbol,
                "custom_quantity": quantity,
                "custom_price": price,
                "custom_order_type": order_type,
                "custom_execution_time_ms": execution_time,
                "custom_total_value": quantity * price
            }
        )
    
    def log_risk_violation(self, rule_name: str, current_value: float, threshold: float, portfolio_id: str, severity: str):
        """Risk-Regel-Verletzung loggen"""
        self.logger.warning(
            "Risk rule violation detected",
            extra={
                "custom_event_type": "risk_violation",
                "custom_rule_name": rule_name,
                "custom_current_value": current_value,
                "custom_threshold": threshold,
                "custom_violation_percent": ((current_value - threshold) / threshold) * 100,
                "custom_portfolio_id": portfolio_id,
                "custom_severity": severity
            }
        )
    
    def log_api_integration(self, provider: str, endpoint: str, response_time: float, status_code: int, error_message: Optional[str] = None):
        """API-Integration loggen"""
        level = logging.INFO if status_code < 400 else logging.ERROR
        message = f"API call to {provider} {endpoint}"
        
        extra_data = {
            "custom_event_type": "api_integration",
            "custom_provider": provider,
            "custom_endpoint": endpoint,
            "custom_response_time_ms": response_time,
            "custom_status_code": status_code
        }
        
        if error_message:
            extra_data["custom_error_message"] = error_message
        
        self.logger.log(level, message, extra=extra_data)

class PerformanceLogger:
    """Performance-Monitoring-Logger"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.logger = logging.getLogger(f"{service_name}.performance")
    
    def log_database_query(self, query_type: str, table: str, execution_time: float, rows_affected: int):
        """Database-Query-Performance loggen"""
        self.logger.info(
            "Database query executed",
            extra={
                "custom_event_type": "database_query",
                "custom_query_type": query_type,
                "custom_table": table,
                "custom_execution_time_ms": execution_time,
                "custom_rows_affected": rows_affected
            }
        )
    
    def log_cache_operation(self, operation: str, cache_type: str, key: str, hit: bool, execution_time: float):
        """Cache-Operation loggen"""
        self.logger.info(
            "Cache operation",
            extra={
                "custom_event_type": "cache_operation",
                "custom_operation": operation,
                "custom_cache_type": cache_type,
                "custom_key": key,
                "custom_hit": hit,
                "custom_execution_time_ms": execution_time
            }
        )
    
    def log_event_processing(self, event_type: str, processing_time: float, queue_lag: float, success: bool):
        """Event-Processing-Performance loggen"""
        self.logger.info(
            "Event processed",
            extra={
                "custom_event_type": "event_processing",
                "custom_processed_event_type": event_type,
                "custom_processing_time_ms": processing_time,
                "custom_queue_lag_ms": queue_lag,
                "custom_success": success
            }
        )

def setup_logging(service_name: str, log_level: str = "INFO") -> None:
    """Logging für Service konfigurieren"""
    service_name_var.set(service_name)
    
    # Root Logger
    root_logger = logging.getLogger()
    root_logger.setLevel(getattr(logging, log_level.upper()))
    
    # Console Handler mit strukturiertem Format
    console_handler = logging.StreamHandler()
    console_handler.setFormatter(StructuredFormatter())
    root_logger.addHandler(console_handler)
    
    # File Handler für Service-spezifische Logs
    file_handler = logging.FileHandler(f"/var/log/aktienanalyse/{service_name}.log")
    file_handler.setFormatter(StructuredFormatter())
    root_logger.addHandler(file_handler)
    
    # Error Handler für separate Error-Logs
    error_handler = logging.FileHandler(f"/var/log/aktienanalyse/{service_name}.error.log")
    error_handler.setLevel(logging.ERROR)
    error_handler.setFormatter(StructuredFormatter())
    root_logger.addHandler(error_handler)
```

### 5.2 Distributed Tracing Implementation

```python
# /opt/aktienanalyse-ökosystem/shared/tracing/tracer.py
"""Distributed Tracing für Request-Verfolgung"""

import uuid
import time
from typing import Dict, Optional, Any
from contextvars import ContextVar
from dataclasses import dataclass, field
from datetime import datetime
import json

# Context Variables
trace_id_var: ContextVar[str] = ContextVar('trace_id', default='')
span_id_var: ContextVar[str] = ContextVar('span_id', default='')
parent_span_id_var: ContextVar[str] = ContextVar('parent_span_id', default='')

@dataclass
class Span:
    """Tracing Span"""
    span_id: str
    trace_id: str
    parent_span_id: Optional[str]
    operation_name: str
    service_name: str
    start_time: datetime
    end_time: Optional[datetime] = None
    duration_ms: Optional[float] = None
    status: str = "ok"  # ok, error, timeout
    tags: Dict[str, Any] = field(default_factory=dict)
    logs: list = field(default_factory=list)
    
    def finish(self):
        """Span abschließen"""
        self.end_time = datetime.utcnow()
        self.duration_ms = (self.end_time - self.start_time).total_seconds() * 1000
    
    def set_tag(self, key: str, value: Any):
        """Tag hinzufügen"""
        self.tags[key] = value
    
    def log_event(self, event: str, **kwargs):
        """Event loggen"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "event": event,
            **kwargs
        }
        self.logs.append(log_entry)
    
    def set_error(self, error: Exception):
        """Fehler setzen"""
        self.status = "error"
        self.set_tag("error", True)
        self.set_tag("error.type", type(error).__name__)
        self.set_tag("error.message", str(error))
        self.log_event("error", error_type=type(error).__name__, error_message=str(error))

class Tracer:
    """Distributed Tracer"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.active_spans: Dict[str, Span] = {}
    
    def start_span(self, operation_name: str, parent_span_id: Optional[str] = None) -> Span:
        """Neuen Span starten"""
        span_id = str(uuid.uuid4())
        trace_id = trace_id_var.get() or str(uuid.uuid4())
        
        if not parent_span_id:
            parent_span_id = span_id_var.get() or None
        
        span = Span(
            span_id=span_id,
            trace_id=trace_id,
            parent_span_id=parent_span_id,
            operation_name=operation_name,
            service_name=self.service_name,
            start_time=datetime.utcnow()
        )
        
        # Context setzen
        trace_id_var.set(trace_id)
        span_id_var.set(span_id)
        if parent_span_id:
            parent_span_id_var.set(parent_span_id)
        
        self.active_spans[span_id] = span
        return span
    
    def finish_span(self, span: Span):
        """Span abschließen und speichern"""
        span.finish()
        
        # Span aus aktiven Spans entfernen
        if span.span_id in self.active_spans:
            del self.active_spans[span.span_id]
        
        # Span zur Verarbeitung senden
        self._send_span(span)
    
    def _send_span(self, span: Span):
        """Span an Tracing-Backend senden"""
        # Hier würde normalerweise an Jaeger/Zipkin gesendet
        # Für Zabbix-Integration verwenden wir Structured Logging
        
        span_data = {
            "span_id": span.span_id,
            "trace_id": span.trace_id,
            "parent_span_id": span.parent_span_id,
            "operation_name": span.operation_name,
            "service_name": span.service_name,
            "start_time": span.start_time.isoformat(),
            "end_time": span.end_time.isoformat() if span.end_time else None,
            "duration_ms": span.duration_ms,
            "status": span.status,
            "tags": span.tags,
            "logs": span.logs
        }
        
        # Als strukturiertes Log ausgeben
        import logging
        logger = logging.getLogger(f"{self.service_name}.tracing")
        logger.info(
            "Span completed",
            extra={
                "custom_event_type": "distributed_trace",
                "custom_span_data": json.dumps(span_data)
            }
        )

# Decorator für automatisches Tracing
def trace_function(operation_name: str = None):
    """Decorator für automatisches Function-Tracing"""
    def decorator(func):
        async def async_wrapper(*args, **kwargs):
            tracer = get_tracer()
            op_name = operation_name or f"{func.__module__}.{func.__name__}"
            
            span = tracer.start_span(op_name)
            span.set_tag("function.name", func.__name__)
            span.set_tag("function.module", func.__module__)
            
            try:
                result = await func(*args, **kwargs)
                span.set_tag("function.success", True)
                return result
            except Exception as e:
                span.set_error(e)
                raise
            finally:
                tracer.finish_span(span)
        
        def sync_wrapper(*args, **kwargs):
            tracer = get_tracer()
            op_name = operation_name or f"{func.__module__}.{func.__name__}"
            
            span = tracer.start_span(op_name)
            span.set_tag("function.name", func.__name__)
            span.set_tag("function.module", func.__module__)
            
            try:
                result = func(*args, **kwargs)
                span.set_tag("function.success", True)
                return result
            except Exception as e:
                span.set_error(e)
                raise
            finally:
                tracer.finish_span(span)
        
        import asyncio
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator

# Global Tracer Instance
_tracer_instance: Optional[Tracer] = None

def init_tracer(service_name: str):
    """Tracer initialisieren"""
    global _tracer_instance
    _tracer_instance = Tracer(service_name)

def get_tracer() -> Tracer:
    """Aktiven Tracer abrufen"""
    if _tracer_instance is None:
        raise RuntimeError("Tracer not initialized. Call init_tracer() first.")
    return _tracer_instance
```

### 5.3 Health Check System

```python
# /opt/aktienanalyse-ökosystem/shared/health/health_checks.py
"""Umfassendes Health Check System"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable
from dataclasses import dataclass
from enum import Enum
import json

class HealthStatus(Enum):
    HEALTHY = "healthy"
    DEGRADED = "degraded"
    UNHEALTHY = "unhealthy"
    UNKNOWN = "unknown"

@dataclass
class HealthCheckResult:
    """Health Check Ergebnis"""
    name: str
    status: HealthStatus
    message: str
    duration_ms: float
    timestamp: datetime
    details: Dict = None
    
    def to_dict(self) -> Dict:
        return {
            "name": self.name,
            "status": self.status.value,
            "message": self.message,
            "duration_ms": self.duration_ms,
            "timestamp": self.timestamp.isoformat(),
            "details": self.details or {}
        }

class HealthCheck:
    """Basis Health Check"""
    
    def __init__(self, name: str, timeout_seconds: float = 5.0):
        self.name = name
        self.timeout_seconds = timeout_seconds
    
    async def check(self) -> HealthCheckResult:
        """Health Check ausführen"""
        start_time = datetime.utcnow()
        
        try:
            # Timeout für Health Check
            result = await asyncio.wait_for(
                self._perform_check(),
                timeout=self.timeout_seconds
            )
            
            duration = (datetime.utcnow() - start_time).total_seconds() * 1000
            
            return HealthCheckResult(
                name=self.name,
                status=result.get('status', HealthStatus.UNKNOWN),
                message=result.get('message', ''),
                duration_ms=duration,
                timestamp=start_time,
                details=result.get('details', {})
            )
            
        except asyncio.TimeoutError:
            duration = (datetime.utcnow() - start_time).total_seconds() * 1000
            return HealthCheckResult(
                name=self.name,
                status=HealthStatus.UNHEALTHY,
                message=f"Health check timed out after {self.timeout_seconds}s",
                duration_ms=duration,
                timestamp=start_time
            )
        
        except Exception as e:
            duration = (datetime.utcnow() - start_time).total_seconds() * 1000
            return HealthCheckResult(
                name=self.name,
                status=HealthStatus.UNHEALTHY,
                message=f"Health check failed: {str(e)}",
                duration_ms=duration,
                timestamp=start_time
            )
    
    async def _perform_check(self) -> Dict:
        """Zu implementieren von spezifischen Health Checks"""
        raise NotImplementedError

class DatabaseHealthCheck(HealthCheck):
    """Database Health Check"""
    
    def __init__(self, name: str, db_connection):
        super().__init__(name)
        self.db_connection = db_connection
    
    async def _perform_check(self) -> Dict:
        try:
            # Einfache Query ausführen
            result = await self.db_connection.execute("SELECT 1")
            
            if result:
                return {
                    "status": HealthStatus.HEALTHY,
                    "message": "Database connection is healthy",
                    "details": {
                        "query_executed": "SELECT 1",
                        "connection_pool_size": self.db_connection.pool_size if hasattr(self.db_connection, 'pool_size') else "unknown"
                    }
                }
            else:
                return {
                    "status": HealthStatus.UNHEALTHY,
                    "message": "Database query returned no result"
                }
                
        except Exception as e:
            return {
                "status": HealthStatus.UNHEALTHY,
                "message": f"Database connection failed: {str(e)}"
            }

class RedisHealthCheck(HealthCheck):
    """Redis Health Check"""
    
    def __init__(self, name: str, redis_client):
        super().__init__(name)
        self.redis_client = redis_client
    
    async def _perform_check(self) -> Dict:
        try:
            # PING Command
            response = await self.redis_client.ping()
            
            if response:
                # Zusätzliche Infos abrufen
                info = await self.redis_client.info()
                
                return {
                    "status": HealthStatus.HEALTHY,
                    "message": "Redis connection is healthy",
                    "details": {
                        "ping_response": str(response),
                        "connected_clients": info.get('connected_clients', 'unknown'),
                        "used_memory_human": info.get('used_memory_human', 'unknown'),
                        "uptime_in_seconds": info.get('uptime_in_seconds', 'unknown')
                    }
                }
            else:
                return {
                    "status": HealthStatus.UNHEALTHY,
                    "message": "Redis PING failed"
                }
                
        except Exception as e:
            return {
                "status": HealthStatus.UNHEALTHY,
                "message": f"Redis connection failed: {str(e)}"
            }

class ExternalAPIHealthCheck(HealthCheck):
    """External API Health Check"""
    
    def __init__(self, name: str, api_url: str, expected_status: int = 200):
        super().__init__(name)
        self.api_url = api_url
        self.expected_status = expected_status
    
    async def _perform_check(self) -> Dict:
        import aiohttp
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(self.api_url) as response:
                    if response.status == self.expected_status:
                        return {
                            "status": HealthStatus.HEALTHY,
                            "message": f"External API {self.api_url} is healthy",
                            "details": {
                                "status_code": response.status,
                                "response_headers": dict(response.headers)
                            }
                        }
                    else:
                        return {
                            "status": HealthStatus.DEGRADED,
                            "message": f"External API returned status {response.status}, expected {self.expected_status}",
                            "details": {
                                "status_code": response.status,
                                "expected_status": self.expected_status
                            }
                        }
                        
        except Exception as e:
            return {
                "status": HealthStatus.UNHEALTHY,
                "message": f"External API check failed: {str(e)}",
                "details": {
                    "api_url": self.api_url,
                    "error": str(e)
                }
            }

class HealthChecker:
    """Central Health Checker"""
    
    def __init__(self, service_name: str):
        self.service_name = service_name
        self.health_checks: List[HealthCheck] = []
        self.last_results: Dict[str, HealthCheckResult] = {}
    
    def register_health_check(self, health_check: HealthCheck):
        """Health Check registrieren"""
        self.health_checks.append(health_check)
    
    async def check_all(self) -> Dict[str, HealthCheckResult]:
        """Alle Health Checks ausführen"""
        results = {}
        
        # Alle Health Checks parallel ausführen
        tasks = [check.check() for check in self.health_checks]
        check_results = await asyncio.gather(*tasks, return_exceptions=True)
        
        for i, result in enumerate(check_results):
            check_name = self.health_checks[i].name
            
            if isinstance(result, Exception):
                # Exception beim Health Check
                results[check_name] = HealthCheckResult(
                    name=check_name,
                    status=HealthStatus.UNHEALTHY,
                    message=f"Health check exception: {str(result)}",
                    duration_ms=0,
                    timestamp=datetime.utcnow()
                )
            else:
                results[check_name] = result
        
        self.last_results = results
        return results
    
    async def get_overall_health(self) -> HealthCheckResult:
        """Gesamten Service-Health-Status ermitteln"""
        if not self.last_results:
            await self.check_all()
        
        all_healthy = all(result.status == HealthStatus.HEALTHY for result in self.last_results.values())
        any_unhealthy = any(result.status == HealthStatus.UNHEALTHY for result in self.last_results.values())
        
        if all_healthy:
            status = HealthStatus.HEALTHY
            message = "All health checks passing"
        elif any_unhealthy:
            status = HealthStatus.UNHEALTHY
            unhealthy_checks = [name for name, result in self.last_results.items() if result.status == HealthStatus.UNHEALTHY]
            message = f"Unhealthy checks: {', '.join(unhealthy_checks)}"
        else:
            status = HealthStatus.DEGRADED
            degraded_checks = [name for name, result in self.last_results.items() if result.status == HealthStatus.DEGRADED]
            message = f"Degraded checks: {', '.join(degraded_checks)}"
        
        return HealthCheckResult(
            name="overall",
            status=status,
            message=message,
            duration_ms=0,
            timestamp=datetime.utcnow(),
            details={
                "individual_checks": {name: result.to_dict() for name, result in self.last_results.items()}
            }
        )
    
    async def get_health_report(self) -> Dict:
        """Vollständigen Health Report erstellen"""
        overall_health = await self.get_overall_health()
        
        return {
            "service": self.service_name,
            "timestamp": datetime.utcnow().isoformat(),
            "overall_status": overall_health.status.value,
            "overall_message": overall_health.message,
            "checks": {name: result.to_dict() for name, result in self.last_results.items()}
        }
```