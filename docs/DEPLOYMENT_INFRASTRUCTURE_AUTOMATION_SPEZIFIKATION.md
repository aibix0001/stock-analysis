# 🚀 Deployment & Infrastructure-Automation - Vollständige Spezifikation

## 🎯 **Übersicht**

**Kontext**: Native LXC-Deployment ohne Docker für aktienanalyse-ökosystem  
**Ziel**: Vollautomatische, produktionsreife Deployment-Pipeline  
**Ansatz**: systemd-Services + CLI-Setup + GitHub Actions CI/CD  

---

## 🏗️ **1. SYSTEMD-SERVICES-ARCHITEKTUR**

### 1.1 **Service-Struktur Overview**
```yaml
# /opt/aktienanalyse-ökosystem/
Directory Structure:
├── services/
│   ├── intelligent-core/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── config/
│   ├── broker-gateway/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── config/
│   ├── event-bus/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── config/
│   ├── monitoring/
│   │   ├── main.py
│   │   ├── requirements.txt
│   │   └── config/
│   └── frontend/
│       ├── server.js
│       ├── package.json
│       ├── dist/
│       └── config/
├── shared/
│   ├── database/
│   ├── config/
│   ├── logging/
│   └── utils/
├── config/
│   ├── global.yaml
│   ├── services/
│   └── environments/
├── logs/
├── data/
├── backups/
└── scripts/
    ├── setup.py
    ├── deploy.sh
    └── migrate.py

# /etc/systemd/system/
systemd Services:
├── aktienanalyse-core.service
├── aktienanalyse-broker.service
├── aktienanalyse-events.service
├── aktienanalyse-monitoring.service
├── aktienanalyse-frontend.service
└── aktienanalyse.target
```

### 1.2 **systemd-Service-Definitionen**
```ini
# /etc/systemd/system/aktienanalyse-core.service
[Unit]
Description=Aktienanalyse Intelligent Core Service
Documentation=https://docs.aktienanalyse.local/core-service
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/intelligent-core
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=intelligent-core-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-core

# Resource Limits
LimitNOFILE=65536
MemoryMax=1G
CPUQuota=200%

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /opt/aktienanalyse-ökosystem/data

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-broker.service
[Unit]
Description=Aktienanalyse Broker Gateway Service
Documentation=https://docs.aktienanalyse.local/broker-service
After=network.target aktienanalyse-core.service aktienanalyse-events.service
Wants=aktienanalyse-core.service aktienanalyse-events.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/broker-gateway
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=broker-gateway-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-broker

# Resource Limits
LimitNOFILE=65536
MemoryMax=512M
CPUQuota=150%

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-events.service
[Unit]
Description=Aktienanalyse Event Bus Service
Documentation=https://docs.aktienanalyse.local/event-bus
After=network.target postgresql.service redis.service
Wants=postgresql.service redis.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/event-bus
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=event-bus-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=3
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-events

# Resource Limits
LimitNOFILE=65536
MemoryMax=1G
CPUQuota=200%

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /opt/aktienanalyse-ökosystem/data

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-monitoring.service
[Unit]
Description=Aktienanalyse Monitoring Service
Documentation=https://docs.aktienanalyse.local/monitoring
After=network.target aktienanalyse-core.service aktienanalyse-events.service
Wants=aktienanalyse-core.service aktienanalyse-events.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/monitoring
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=monitoring-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=10
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-monitoring

# Resource Limits
LimitNOFILE=65536
MemoryMax=512M
CPUQuota=100%

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-frontend.service
[Unit]
Description=Aktienanalyse Frontend Service (NGINX + Node.js)
Documentation=https://docs.aktienanalyse.local/frontend
After=network.target aktienanalyse-core.service aktienanalyse-broker.service
Wants=aktienanalyse-core.service aktienanalyse-broker.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/frontend
Environment=NODE_ENV=production
Environment=SERVICE_NAME=frontend-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/usr/bin/node server.js
ExecReload=/bin/kill -HUP $MAINPID
KillMode=mixed
Restart=always
RestartSec=5
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-frontend

# Resource Limits
LimitNOFILE=65536
MemoryMax=512M
CPUQuota=100%

# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse.target
[Unit]
Description=Aktienanalyse Ecosystem
Documentation=https://docs.aktienanalyse.local
Wants=aktienanalyse-core.service aktienanalyse-broker.service aktienanalyse-events.service aktienanalyse-monitoring.service aktienanalyse-frontend.service
After=aktienanalyse-core.service aktienanalyse-broker.service aktienanalyse-events.service aktienanalyse-monitoring.service aktienanalyse-frontend.service

[Install]
WantedBy=multi-user.target
```

### 1.3 **Service-Management-Scripts**
```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/service-control.sh

set -euo pipefail

SERVICES=(
    "aktienanalyse-events"
    "aktienanalyse-core" 
    "aktienanalyse-broker"
    "aktienanalyse-monitoring"
    "aktienanalyse-frontend"
)

function start_services() {
    echo "🚀 Starting Aktienanalyse Ecosystem..."
    
    # Start in dependency order
    for service in "${SERVICES[@]}"; do
        echo "Starting ${service}..."
        systemctl start "${service}"
        
        # Wait for service to be ready
        sleep 2
        
        if ! systemctl is-active --quiet "${service}"; then
            echo "❌ Failed to start ${service}"
            systemctl status "${service}" --no-pager
            exit 1
        fi
        
        echo "✅ ${service} started successfully"
    done
    
    echo "🎉 All services started successfully!"
}

function stop_services() {
    echo "🛑 Stopping Aktienanalyse Ecosystem..."
    
    # Stop in reverse order
    for ((i=${#SERVICES[@]}-1; i>=0; i--)); do
        service="${SERVICES[$i]}"
        echo "Stopping ${service}..."
        systemctl stop "${service}" || true
    done
    
    echo "✅ All services stopped"
}

function restart_services() {
    echo "🔄 Restarting Aktienanalyse Ecosystem..."
    stop_services
    sleep 5
    start_services
}

function status_services() {
    echo "📊 Aktienanalyse Ecosystem Status:"
    echo "=================================="
    
    for service in "${SERVICES[@]}"; do
        if systemctl is-active --quiet "${service}"; then
            status="🟢 RUNNING"
        else
            status="🔴 STOPPED"
        fi
        
        echo "${service}: ${status}"
    done
    
    echo ""
    echo "🎯 Target Status:"
    systemctl status aktienanalyse.target --no-pager
}

function health_check() {
    echo "🏥 Health Check..."
    
    local failed=0
    
    # Check systemd services
    for service in "${SERVICES[@]}"; do
        if ! systemctl is-active --quiet "${service}"; then
            echo "❌ ${service} is not running"
            ((failed++))
        fi
    done
    
    # Check HTTP endpoints
    endpoints=(
        "http://localhost:8001/health"
        "http://localhost:8002/health" 
        "http://localhost:8003/health"
        "http://localhost:8004/health"
        "https://localhost:8443/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if ! curl -sf "${endpoint}" > /dev/null 2>&1; then
            echo "❌ ${endpoint} not responding"
            ((failed++))
        fi
    done
    
    if [ $failed -eq 0 ]; then
        echo "✅ All health checks passed"
        return 0
    else
        echo "❌ ${failed} health checks failed"
        return 1
    fi
}

function logs() {
    local service="${1:-}"
    
    if [ -z "$service" ]; then
        echo "📋 Available services for logs:"
        printf '%s\n' "${SERVICES[@]}"
        exit 1
    fi
    
    echo "📋 Logs for ${service}:"
    journalctl -u "${service}" -f --no-pager
}

case "${1:-}" in
    start)
        start_services
        ;;
    stop)
        stop_services
        ;;
    restart)
        restart_services
        ;;
    status)
        status_services
        ;;
    health)
        health_check
        ;;
    logs)
        logs "${2:-}"
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|health|logs [service]}"
        echo ""
        echo "Available services:"
        printf '  %s\n' "${SERVICES[@]}"
        exit 1
        ;;
esac
```

---

## 🔧 **2. CLI-BASIERTES SETUP-PROGRAMM**

### 2.1 **Interaktives Setup-Tool mit deutschen Erklärungen**
```python
#!/usr/bin/env python3
# /opt/aktienanalyse-ökosystem/scripts/setup.py

import os
import sys
import yaml
import json
import getpass
import subprocess
from typing import Dict, Any, List, Optional
from pathlib import Path
from dataclasses import dataclass
from enum import Enum

class SetupPhase(Enum):
    SYSTEM_CHECK = "system_check"
    USER_CONFIG = "user_config"
    DATABASE_SETUP = "database_setup"
    SERVICE_CONFIG = "service_config"
    SECURITY_CONFIG = "security_config"
    DEPLOYMENT = "deployment"
    VALIDATION = "validation"

@dataclass
class ConfigValue:
    key: str
    description: str
    example: str
    default: Any
    validation: Optional[callable] = None
    required: bool = True
    secret: bool = False

class AktienAnalyseSetup:
    """Interaktives Setup-Tool für das Aktienanalyse-Ökosystem"""
    
    def __init__(self):
        self.base_path = Path("/opt/aktienanalyse-ökosystem")
        self.config = {}
        self.secrets = {}
        
        # Deutsche Konfigurationswerte mit Erklärungen
        self.config_definitions = {
            # Allgemeine Einstellungen
            "system.timezone": ConfigValue(
                key="system.timezone",
                description="🌍 Zeitzone für alle Services (wichtig für Trading-Zeiten)",
                example="Europe/Berlin",
                default="Europe/Berlin"
            ),
            "system.log_level": ConfigValue(
                key="system.log_level",
                description="📋 Log-Level für System-Meldungen (DEBUG für Entwicklung, INFO für Produktion)",
                example="INFO",
                default="INFO",
                validation=lambda x: x in ["DEBUG", "INFO", "WARNING", "ERROR"]
            ),
            
            # Database-Konfiguration
            "database.host": ConfigValue(
                key="database.host",
                description="🗄️ PostgreSQL Server-Adresse (meist localhost für LXC)",
                example="localhost",
                default="localhost"
            ),
            "database.port": ConfigValue(
                key="database.port", 
                description="🔌 PostgreSQL Port (Standard: 5432)",
                example="5432",
                default=5432,
                validation=lambda x: 1 <= int(x) <= 65535
            ),
            "database.name": ConfigValue(
                key="database.name",
                description="📊 Name der Hauptdatenbank für Portfolio- und Trading-Daten",
                example="aktienanalyse_production",
                default="aktienanalyse_production"
            ),
            "database.username": ConfigValue(
                key="database.username",
                description="👤 Database-Benutzer (sollte nur Zugriff auf aktienanalyse-DBs haben)",
                example="aktienanalyse_user",
                default="aktienanalyse_user"
            ),
            "database.password": ConfigValue(
                key="database.password",
                description="🔐 Database-Passwort (wird verschlüsselt gespeichert)",
                example="",
                default="",
                secret=True
            ),
            
            # Redis-Konfiguration
            "redis.host": ConfigValue(
                key="redis.host",
                description="📮 Redis Server für Event-Bus und Caching (meist localhost)",
                example="localhost", 
                default="localhost"
            ),
            "redis.port": ConfigValue(
                key="redis.port",
                description="🔌 Redis Port (Standard: 6379)",
                example="6379",
                default=6379,
                validation=lambda x: 1 <= int(x) <= 65535
            ),
            "redis.database": ConfigValue(
                key="redis.database",
                description="🗂️ Redis Database-Nummer (0-15, separiert verschiedene Daten)",
                example="0",
                default=0,
                validation=lambda x: 0 <= int(x) <= 15
            ),
            
            # Trading-Konfiguration
            "trading.broker": ConfigValue(
                key="trading.broker",
                description="📈 Haupt-Broker für Trading (derzeit nur bitpanda_pro unterstützt)",
                example="bitpanda_pro",
                default="bitpanda_pro",
                validation=lambda x: x in ["bitpanda_pro"]
            ),
            "trading.api_key": ConfigValue(
                key="trading.api_key",
                description="🔑 Bitpanda Pro API-Key (von bitpanda.com/pro -> API-Einstellungen)",
                example="bp_live_...",
                default="",
                secret=True
            ),
            "trading.api_secret": ConfigValue(
                key="trading.api_secret", 
                description="🔒 Bitpanda Pro API-Secret (wird verschlüsselt gespeichert)",
                example="",
                default="",
                secret=True
            ),
            "trading.sandbox_mode": ConfigValue(
                key="trading.sandbox_mode",
                description="🧪 Sandbox-Modus für Tests (true = keine echten Orders, false = Live-Trading)",
                example="true",
                default=True,
                validation=lambda x: isinstance(x, bool) or x.lower() in ["true", "false"]
            ),
            
            # Risk-Management
            "risk.max_position_size_percent": ConfigValue(
                key="risk.max_position_size_percent",
                description="⚠️ Maximale Positionsgröße in % des Portfolios (Schutz vor Überkonzentration)",
                example="15.0",
                default=15.0,
                validation=lambda x: 0.1 <= float(x) <= 50.0
            ),
            "risk.daily_loss_limit_percent": ConfigValue(
                key="risk.daily_loss_limit_percent",
                description="🛡️ Tägliches Verlustlimit in % (stoppt Trading bei Überschreitung)",
                example="5.0", 
                default=5.0,
                validation=lambda x: 0.1 <= float(x) <= 20.0
            ),
            "risk.stop_loss_default_percent": ConfigValue(
                key="risk.stop_loss_default_percent",
                description="📉 Standard Stop-Loss in % (automatischer Verkauf bei Verlust)",
                example="10.0",
                default=10.0,
                validation=lambda x: 1.0 <= float(x) <= 50.0
            ),
            
            # Monitoring-Konfiguration
            "monitoring.zabbix_server": ConfigValue(
                key="monitoring.zabbix_server",
                description="📊 Zabbix Server-Adresse für System-Monitoring",
                example="10.1.1.103",
                default="10.1.1.103"
            ),
            "monitoring.zabbix_port": ConfigValue(
                key="monitoring.zabbix_port",
                description="🔌 Zabbix Server Port (Standard: 10051)",
                example="10051",
                default=10051,
                validation=lambda x: 1 <= int(x) <= 65535
            ),
            "monitoring.metrics_interval_seconds": ConfigValue(
                key="monitoring.metrics_interval_seconds",
                description="⏱️ Intervall für Metriken-Sammlung in Sekunden (niedriger = mehr Details)",
                example="30",
                default=30,
                validation=lambda x: 5 <= int(x) <= 3600
            ),
            
            # Frontend-Konfiguration
            "frontend.domain": ConfigValue(
                key="frontend.domain",
                description="🌐 Domain für Web-Interface (z.B. aktienanalyse.local oder IP-Adresse)",
                example="aktienanalyse.local",
                default="localhost"
            ),
            "frontend.port": ConfigValue(
                key="frontend.port",
                description="🔌 HTTPS-Port für Web-Interface (Standard: 8443)",
                example="8443",
                default=8443,
                validation=lambda x: 1 <= int(x) <= 65535
            ),
            "frontend.session_timeout_hours": ConfigValue(
                key="frontend.session_timeout_hours",
                description="⏰ Session-Timeout in Stunden (Sicherheit vs. Benutzerfreundlichkeit)",
                example="24",
                default=24,
                validation=lambda x: 1 <= int(x) <= 168
            ),
            
            # Notification-Konfiguration
            "notifications.email_enabled": ConfigValue(
                key="notifications.email_enabled",
                description="📧 E-Mail-Benachrichtigungen aktivieren (für wichtige Alerts)",
                example="false",
                default=False,
                validation=lambda x: isinstance(x, bool) or x.lower() in ["true", "false"]
            ),
            "notifications.email_server": ConfigValue(
                key="notifications.email_server",
                description="📮 SMTP-Server für E-Mail-Versand",
                example="localhost",
                default="localhost",
                required=False
            ),
            "notifications.email_from": ConfigValue(
                key="notifications.email_from",
                description="📨 Absender-E-Mail-Adresse für Benachrichtigungen",
                example="aktienanalyse@local",
                default="aktienanalyse@local",
                required=False
            ),
            "notifications.email_to": ConfigValue(
                key="notifications.email_to",
                description="📩 Empfänger-E-Mail-Adresse für Alerts und Berichte",
                example="admin@local",
                default="admin@local", 
                required=False
            )
        }
    
    def run_setup(self):
        """Hauptfunktion für interaktives Setup"""
        
        print("🚀 Aktienanalyse-Ökosystem Setup")
        print("=" * 50)
        print()
        print("Dieses Setup-Tool führt Sie durch die Konfiguration")
        print("des Aktienanalyse-Systems mit deutschen Erklärungen.")
        print()
        
        phases = [
            (SetupPhase.SYSTEM_CHECK, "System-Voraussetzungen prüfen"),
            (SetupPhase.USER_CONFIG, "Benutzer-Konfiguration"),
            (SetupPhase.DATABASE_SETUP, "Database-Setup"),
            (SetupPhase.SERVICE_CONFIG, "Service-Konfiguration"),
            (SetupPhase.SECURITY_CONFIG, "Sicherheits-Einstellungen"),
            (SetupPhase.DEPLOYMENT, "System-Deployment"),
            (SetupPhase.VALIDATION, "Installation validieren")
        ]
        
        for phase, description in phases:
            print(f"📋 Phase: {description}")
            print("-" * 30)
            
            if phase == SetupPhase.SYSTEM_CHECK:
                self._check_system_requirements()
            elif phase == SetupPhase.USER_CONFIG:
                self._configure_user_settings()
            elif phase == SetupPhase.DATABASE_SETUP:
                self._setup_database()
            elif phase == SetupPhase.SERVICE_CONFIG:
                self._configure_services()
            elif phase == SetupPhase.SECURITY_CONFIG:
                self._configure_security()
            elif phase == SetupPhase.DEPLOYMENT:
                self._deploy_system()
            elif phase == SetupPhase.VALIDATION:
                self._validate_installation()
            
            print("✅ Phase abgeschlossen")
            print()
        
        print("🎉 Setup erfolgreich abgeschlossen!")
        print()
        self._show_next_steps()
    
    def _check_system_requirements(self):
        """Prüft System-Voraussetzungen"""
        
        print("🔍 Prüfe System-Voraussetzungen...")
        
        requirements = [
            ("python3", "Python 3.9+ für Backend-Services"),
            ("node", "Node.js 16+ für Frontend"),
            ("postgresql", "PostgreSQL 13+ für Datenspeicherung"),
            ("redis-server", "Redis 6+ für Event-Bus"),
            ("nginx", "NGINX für HTTPS-Proxy"),
            ("systemctl", "systemd für Service-Management")
        ]
        
        missing = []
        
        for cmd, description in requirements:
            if not self._command_exists(cmd):
                missing.append((cmd, description))
                print(f"❌ {cmd} - {description}")
            else:
                print(f"✅ {cmd} - {description}")
        
        if missing:
            print()
            print("❌ Fehlende Voraussetzungen:")
            for cmd, desc in missing:
                print(f"   - {cmd}: {desc}")
            print()
            print("Bitte installieren Sie die fehlenden Komponenten:")
            print("apt update && apt install -y python3 python3-pip nodejs npm postgresql redis-server nginx")
            sys.exit(1)
    
    def _configure_user_settings(self):
        """Interaktive Benutzer-Konfiguration"""
        
        print("⚙️ Benutzer-Konfiguration...")
        print()
        print("Bitte geben Sie die Konfigurationswerte ein.")
        print("Drücken Sie Enter für Standardwerte.")
        print()
        
        # Gruppierte Konfiguration
        groups = {
            "🗄️ Database-Einstellungen": [
                "database.host", "database.port", "database.name", 
                "database.username", "database.password"
            ],
            "📮 Redis-Einstellungen": [
                "redis.host", "redis.port", "redis.database"
            ],
            "📈 Trading-Einstellungen": [
                "trading.broker", "trading.api_key", "trading.api_secret", 
                "trading.sandbox_mode"
            ],
            "⚠️ Risk-Management": [
                "risk.max_position_size_percent", "risk.daily_loss_limit_percent",
                "risk.stop_loss_default_percent"
            ],
            "📊 Monitoring-Einstellungen": [
                "monitoring.zabbix_server", "monitoring.zabbix_port",
                "monitoring.metrics_interval_seconds"
            ],
            "🌐 Frontend-Einstellungen": [
                "frontend.domain", "frontend.port", "frontend.session_timeout_hours"
            ],
            "📧 Benachrichtigungen": [
                "notifications.email_enabled", "notifications.email_server",
                "notifications.email_from", "notifications.email_to"
            ],
            "🌍 System-Einstellungen": [
                "system.timezone", "system.log_level"
            ]
        }
        
        for group_name, config_keys in groups.items():
            print(f"{group_name}")
            print("=" * len(group_name))
            
            for key in config_keys:
                config_def = self.config_definitions[key]
                self._ask_config_value(config_def)
            
            print()
    
    def _ask_config_value(self, config_def: ConfigValue):
        """Fragt Benutzer nach Konfigurationswert"""
        
        print(f"📝 {config_def.description}")
        
        if config_def.example:
            print(f"   Beispiel: {config_def.example}")
        
        if config_def.secret:
            prompt = f"   Wert (wird versteckt eingegeben)"
            if config_def.default:
                prompt += f" [Standard: ***]"
            prompt += ": "
            
            value = getpass.getpass(prompt)
            if not value and config_def.default:
                value = config_def.default
        else:
            prompt = f"   Wert"
            if config_def.default is not None:
                prompt += f" [Standard: {config_def.default}]"
            prompt += ": "
            
            value = input(prompt).strip()
            if not value:
                value = config_def.default
        
        # Validation
        if config_def.validation and value:
            try:
                if not config_def.validation(value):
                    print(f"❌ Ungültiger Wert für {config_def.key}")
                    return self._ask_config_value(config_def)
            except Exception as e:
                print(f"❌ Validierungsfehler: {e}")
                return self._ask_config_value(config_def)
        
        # Speichern
        if config_def.secret:
            self.secrets[config_def.key] = value
        else:
            # Nested dict structure
            keys = config_def.key.split('.')
            current = self.config
            for key in keys[:-1]:
                if key not in current:
                    current[key] = {}
                current = current[key]
            current[keys[-1]] = value
        
        print(f"✅ {config_def.key} konfiguriert")
        print()
    
    def _setup_database(self):
        """Database-Setup und Migration"""
        
        print("🗄️ Database-Setup...")
        
        # Database-Verbindung testen
        db_config = self.config['database']
        
        print("📡 Teste Database-Verbindung...")
        
        if self._test_database_connection():
            print("✅ Database-Verbindung erfolgreich")
        else:
            print("❌ Database-Verbindung fehlgeschlagen")
            
            create_db = input("Soll die Database automatisch erstellt werden? (y/n): ").lower()
            if create_db == 'y':
                self._create_database()
            else:
                print("Bitte erstellen Sie die Database manuell und starten Sie das Setup erneut.")
                sys.exit(1)
        
        # Schema-Migration
        print("🔄 Führe Database-Migration durch...")
        self._run_database_migration()
        print("✅ Database-Schema aktualisiert")
    
    def _configure_services(self):
        """Service-Konfiguration generieren"""
        
        print("⚙️ Generiere Service-Konfigurationen...")
        
        # YAML-Konfigurationsdateien erstellen
        config_dir = self.base_path / "config"
        config_dir.mkdir(exist_ok=True)
        
        # Global config
        global_config = {
            "system": self.config.get("system", {}),
            "database": self.config.get("database", {}),
            "redis": self.config.get("redis", {}),
            "monitoring": self.config.get("monitoring", {})
        }
        
        with open(config_dir / "global.yaml", "w") as f:
            yaml.dump(global_config, f, default_flow_style=False, allow_unicode=True)
        
        # Service-specific configs
        services_dir = config_dir / "services"
        services_dir.mkdir(exist_ok=True)
        
        service_configs = {
            "core.yaml": {
                "risk": self.config.get("risk", {}),
                "trading": {k: v for k, v in self.config.get("trading", {}).items() 
                           if k not in ["api_key", "api_secret"]}
            },
            "broker.yaml": {
                "trading": {k: v for k, v in self.config.get("trading", {}).items() 
                           if k not in ["api_key", "api_secret"]}
            },
            "frontend.yaml": {
                "frontend": self.config.get("frontend", {}),
                "notifications": self.config.get("notifications", {})
            }
        }
        
        for filename, config in service_configs.items():
            with open(services_dir / filename, "w") as f:
                yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
        
        # Environment file für Secrets
        env_dir = config_dir / "environments"
        env_dir.mkdir(exist_ok=True)
        
        env_content = []
        for key, value in self.secrets.items():
            env_key = key.upper().replace(".", "_")
            env_content.append(f"{env_key}={value}")
        
        with open(env_dir / "production.env", "w") as f:
            f.write("\n".join(env_content))
        
        # Secure permissions
        os.chmod(env_dir / "production.env", 0o600)
        
        print("✅ Konfigurationsdateien erstellt")
    
    def _configure_security(self):
        """Sicherheits-Konfiguration"""
        
        print("🔐 Sicherheits-Konfiguration...")
        
        # User und Gruppe erstellen
        self._create_system_user()
        
        # File-Permissions setzen
        self._set_file_permissions()
        
        # systemd-Services installieren
        self._install_systemd_services()
        
        print("✅ Sicherheits-Konfiguration abgeschlossen")
    
    def _deploy_system(self):
        """System-Deployment"""
        
        print("🚀 System-Deployment...")
        
        # Dependencies installieren
        print("📦 Installiere Python-Dependencies...")
        self._install_python_dependencies()
        
        print("📦 Installiere Node.js-Dependencies...")
        self._install_nodejs_dependencies()
        
        # systemd-Services aktivieren
        print("⚙️ Aktiviere systemd-Services...")
        self._enable_systemd_services()
        
        # NGINX konfigurieren
        print("🌐 Konfiguriere NGINX...")
        self._configure_nginx()
        
        print("✅ System-Deployment abgeschlossen")
    
    def _validate_installation(self):
        """Installation validieren"""
        
        print("🔍 Validiere Installation...")
        
        # Services starten
        print("🚀 Starte Services...")
        subprocess.run(["/opt/aktienanalyse-ökosystem/scripts/service-control.sh", "start"], 
                      check=True)
        
        # Health-Check
        print("🏥 Führe Health-Check durch...")
        result = subprocess.run(["/opt/aktienanalyse-ökosystem/scripts/service-control.sh", "health"], 
                               capture_output=True, text=True)
        
        if result.returncode == 0:
            print("✅ Alle Health-Checks bestanden")
        else:
            print("❌ Health-Checks fehlgeschlagen:")
            print(result.stdout)
            print(result.stderr)
            
        print("🌐 Teste Web-Interface...")
        import urllib.request
        try:
            response = urllib.request.urlopen(f"https://{self.config['frontend']['domain']}:{self.config['frontend']['port']}/health", timeout=10)
            if response.getcode() == 200:
                print("✅ Web-Interface erreichbar")
            else:
                print(f"❌ Web-Interface Error: {response.getcode()}")
        except Exception as e:
            print(f"❌ Web-Interface nicht erreichbar: {e}")
    
    def _show_next_steps(self):
        """Zeigt nächste Schritte"""
        
        print("🎯 Nächste Schritte:")
        print("==================")
        print()
        print("1. 🌐 Web-Interface öffnen:")
        print(f"   https://{self.config['frontend']['domain']}:{self.config['frontend']['port']}")
        print()
        print("2. 📊 System-Status prüfen:")
        print("   /opt/aktienanalyse-ökosystem/scripts/service-control.sh status")
        print()
        print("3. 📋 Logs anzeigen:")
        print("   /opt/aktienanalyse-ökosystem/scripts/service-control.sh logs [service]")
        print()
        print("4. ⚙️ Konfiguration anpassen:")
        print("   Bearbeiten Sie die YAML-Dateien in /opt/aktienanalyse-ökosystem/config/")
        print()
        print("5. 🔄 Services neustarten nach Änderungen:")
        print("   /opt/aktienanalyse-ökosystem/scripts/service-control.sh restart")
        print()
        print("📚 Dokumentation:")
        print("   https://docs.aktienanalyse.local")
        print()
        print("🎉 Viel Erfolg mit dem Aktienanalyse-System!")
    
    # Helper-Methoden
    def _command_exists(self, command: str) -> bool:
        """Prüft ob Kommando verfügbar ist"""
        return subprocess.run(["which", command], capture_output=True).returncode == 0
    
    def _test_database_connection(self) -> bool:
        """Testet Database-Verbindung"""
        # Implementierung für DB-Test
        return True
    
    def _create_database(self):
        """Erstellt Database"""
        # Implementierung für DB-Erstellung
        pass
    
    def _run_database_migration(self):
        """Führt Database-Migration durch"""
        # Implementierung für Migration
        pass
    
    def _create_system_user(self):
        """Erstellt System-User"""
        # Implementierung für User-Erstellung
        pass
    
    def _set_file_permissions(self):
        """Setzt File-Permissions"""
        # Implementierung für Permissions
        pass
    
    def _install_systemd_services(self):
        """Installiert systemd-Services"""
        # Implementierung für systemd-Installation
        pass
    
    def _install_python_dependencies(self):
        """Installiert Python-Dependencies"""
        # Implementierung für Python-Deps
        pass
    
    def _install_nodejs_dependencies(self):
        """Installiert Node.js-Dependencies"""
        # Implementierung für Node.js-Deps
        pass
    
    def _enable_systemd_services(self):
        """Aktiviert systemd-Services"""
        # Implementierung für Service-Aktivierung
        pass
    
    def _configure_nginx(self):
        """Konfiguriert NGINX"""
        # Implementierung für NGINX-Config
        pass

if __name__ == "__main__":
    if os.geteuid() != 0:
        print("❌ Setup muss als root ausgeführt werden")
        print("Verwenden Sie: sudo python3 setup.py")
        sys.exit(1)
    
    setup = AktienAnalyseSetup()
    setup.run_setup()
```

## 3. Automatische Database-Schema-Migration

### 3.1 Alembic Migration-System

```bash
# Migration-Verzeichnis-Struktur
/opt/aktienanalyse-ökosystem/migrations/
├── alembic.ini                    # Alembic-Konfiguration
├── env.py                         # Migration-Environment
├── script.py.mako                 # Template für neue Migrations
├── versions/                      # Migration-Versionen
│   ├── 001_initial_schema.py
│   ├── 002_add_portfolio_tables.py
│   ├── 003_add_trading_events.py
│   └── ...
└── seeds/                         # Initial-Daten
    ├── default_risk_profiles.sql
    ├── default_asset_categories.sql
    └── system_configurations.sql
```

### 3.2 Migration-Konfiguration

```ini
# /opt/aktienanalyse-ökosystem/migrations/alembic.ini
[alembic]
script_location = /opt/aktienanalyse-ökosystem/migrations
prepend_sys_path = /opt/aktienanalyse-ökosystem
version_path_separator = os
sqlalchemy.url = postgresql://%(DB_USER)s:%(DB_PASSWORD)s@%(DB_HOST)s:%(DB_PORT)s/%(DB_NAME)s

[post_write_hooks]
hooks = black,isort
black.type = console
black.entrypoint = black
black.options = --line-length 88 --target-version py39
isort.type = console
isort.entrypoint = isort
isort.options = --profile black --line-length 88

[loggers]
keys = root,sqlalchemy,alembic

[handlers]  
keys = console

[formatters]
keys = generic

[logger_root]
level = WARN
handlers = console
qualname =

[logger_sqlalchemy]
level = WARN
handlers =
qualname = sqlalchemy.engine

[logger_alembic]
level = INFO
handlers =
qualname = alembic

[handler_console]
class = StreamHandler
args = (sys.stderr,)
level = NOTSET
formatter = generic

[formatter_generic]
format = %(levelname)-5.5s [%(name)s] %(message)s
datefmt = %H:%M:%S
```

### 3.3 Migration-Environment

```python
# /opt/aktienanalyse-ökosystem/migrations/env.py
"""Alembic Migration Environment für Aktienanalyse-Ökosystem"""
import os
import sys
from logging.config import fileConfig
from sqlalchemy import engine_from_config, pool
from alembic import context

# Projekt-Pfad hinzufügen
sys.path.insert(0, '/opt/aktienanalyse-ökosystem')

from shared.database.models import Base
from shared.config import DatabaseConfig

# Alembic Config
config = context.config
if config.config_file_name is not None:
    fileConfig(config.config_file_name)

# Target Metadata für Autogenerate
target_metadata = Base.metadata

def get_database_url():
    """Database URL aus Environment-Variablen laden"""
    db_config = DatabaseConfig()
    return (
        f"postgresql://{db_config.user}:{db_config.password}@"
        f"{db_config.host}:{db_config.port}/{db_config.database}"
    )

def run_migrations_offline() -> None:
    """Offline-Migrations (DDL-Scripts generieren)"""
    url = get_database_url()
    context.configure(
        url=url,
        target_metadata=target_metadata,
        literal_binds=True,
        dialect_opts={"paramstyle": "named"},
        compare_type=True,
        compare_server_default=True,
        include_schemas=True,
    )

    with context.begin_transaction():
        context.run_migrations()

def run_migrations_online() -> None:
    """Online-Migrations (Database direkt migrieren)"""
    configuration = config.get_section(config.config_ini_section)
    configuration["sqlalchemy.url"] = get_database_url()
    
    connectable = engine_from_config(
        configuration,
        prefix="sqlalchemy.",
        poolclass=pool.NullPool,
    )

    with connectable.connect() as connection:
        context.configure(
            connection=connection,
            target_metadata=target_metadata,
            compare_type=True,
            compare_server_default=True,
            include_schemas=True,
            transaction_per_migration=True,
        )

        with context.begin_transaction():
            context.run_migrations()

# Migration-Modus ermitteln
if context.is_offline_mode():
    run_migrations_offline()
else:
    run_migrations_online()
```

### 3.4 Migration-Management-Script

```python
#!/usr/bin/env python3
# /opt/aktienanalyse-ökosystem/scripts/manage_migrations.py
"""Database-Migration-Management für Aktienanalyse-Ökosystem"""
import os
import sys
import subprocess
import logging
from pathlib import Path
from typing import Optional, List
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

# Logging Setup
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('/var/log/aktienanalyse/migrations.log'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

class MigrationManager:
    """Database-Migration-Manager"""
    
    def __init__(self):
        self.project_root = Path('/opt/aktienanalyse-ökosystem')
        self.migrations_dir = self.project_root / 'migrations'
        self.venv_python = self.project_root / 'venv' / 'bin' / 'python'
        self.alembic_cmd = [str(self.venv_python), '-m', 'alembic']
        
    def check_database_connection(self) -> bool:
        """Database-Verbindung prüfen"""
        try:
            from shared.config import DatabaseConfig
            db_config = DatabaseConfig()
            
            conn = psycopg2.connect(
                host=db_config.host,
                port=db_config.port,
                user=db_config.user,
                password=db_config.password,
                database=db_config.database
            )
            conn.close()
            logger.info("✅ Database-Verbindung erfolgreich")
            return True
            
        except Exception as e:
            logger.error(f"❌ Database-Verbindung fehlgeschlagen: {e}")
            return False
    
    def create_database_if_not_exists(self) -> bool:
        """Database erstellen falls nicht vorhanden"""
        try:
            from shared.config import DatabaseConfig
            db_config = DatabaseConfig()
            
            # Verbindung zur postgres-Database für CREATE DATABASE
            conn = psycopg2.connect(
                host=db_config.host,
                port=db_config.port,
                user=db_config.user,
                password=db_config.password,
                database='postgres'
            )
            conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
            cursor = conn.cursor()
            
            # Prüfen ob Database existiert
            cursor.execute(
                "SELECT 1 FROM pg_catalog.pg_database WHERE datname = %s",
                (db_config.database,)
            )
            
            if not cursor.fetchone():
                logger.info(f"📦 Erstelle Database: {db_config.database}")
                cursor.execute(f'CREATE DATABASE "{db_config.database}"')
                logger.info("✅ Database erfolgreich erstellt")
            else:
                logger.info("✅ Database bereits vorhanden")
                
            cursor.close()
            conn.close()
            return True
            
        except Exception as e:
            logger.error(f"❌ Database-Erstellung fehlgeschlagen: {e}")
            return False
    
    def get_current_revision(self) -> Optional[str]:
        """Aktuelle Migration-Revision ermitteln"""
        try:
            result = subprocess.run(
                self.alembic_cmd + ['current'],
                cwd=self.migrations_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                output = result.stdout.strip()
                if 'Current revision(s) for' in output:
                    revision = output.split(':')[1].strip() if ':' in output else None
                    logger.info(f"📍 Aktuelle Revision: {revision or 'Keine'}")
                    return revision
                    
        except Exception as e:
            logger.error(f"❌ Revision-Ermittlung fehlgeschlagen: {e}")
            
        return None
    
    def get_migration_history(self) -> List[str]:
        """Migration-Verlauf anzeigen"""
        try:
            result = subprocess.run(
                self.alembic_cmd + ['history', '--verbose'],
                cwd=self.migrations_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                return result.stdout.strip().split('\n')
                
        except Exception as e:
            logger.error(f"❌ Migration-Verlauf fehlgeschlagen: {e}")
            
        return []
    
    def create_migration(self, message: str, autogenerate: bool = True) -> bool:
        """Neue Migration erstellen"""
        try:
            cmd = self.alembic_cmd + ['revision']
            
            if autogenerate:
                cmd.append('--autogenerate')
                
            cmd.extend(['-m', message])
            
            logger.info(f"🔧 Erstelle Migration: {message}")
            result = subprocess.run(
                cmd,
                cwd=self.migrations_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                logger.info("✅ Migration erfolgreich erstellt")
                logger.info(result.stdout)
                return True
            else:
                logger.error(f"❌ Migration-Erstellung fehlgeschlagen: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Migration-Erstellung fehlgeschlagen: {e}")
            return False
    
    def run_migrations(self, target_revision: str = 'head') -> bool:
        """Migrations ausführen"""
        try:
            logger.info(f"🚀 Führe Migrations aus (Ziel: {target_revision})")
            result = subprocess.run(
                self.alembic_cmd + ['upgrade', target_revision],
                cwd=self.migrations_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                logger.info("✅ Migrations erfolgreich ausgeführt")
                logger.info(result.stdout)
                return True
            else:
                logger.error(f"❌ Migration fehlgeschlagen: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Migration fehlgeschlagen: {e}")
            return False
    
    def rollback_migration(self, target_revision: str) -> bool:
        """Migration zurückrollen"""
        try:
            logger.info(f"🔄 Rolle Migration zurück auf: {target_revision}")
            result = subprocess.run(
                self.alembic_cmd + ['downgrade', target_revision],
                cwd=self.migrations_dir,
                capture_output=True,
                text=True
            )
            
            if result.returncode == 0:
                logger.info("✅ Rollback erfolgreich")
                logger.info(result.stdout)
                return True
            else:
                logger.error(f"❌ Rollback fehlgeschlagen: {result.stderr}")
                return False
                
        except Exception as e:
            logger.error(f"❌ Rollback fehlgeschlagen: {e}")
            return False
    
    def seed_initial_data(self) -> bool:
        """Initial-Daten laden"""
        try:
            from shared.config import DatabaseConfig
            from sqlalchemy import create_engine, text
            
            db_config = DatabaseConfig()
            engine = create_engine(
                f"postgresql://{db_config.user}:{db_config.password}@"
                f"{db_config.host}:{db_config.port}/{db_config.database}"
            )
            
            seeds_dir = self.migrations_dir / 'seeds'
            
            if not seeds_dir.exists():
                logger.warning("⚠️ Keine Seed-Dateien gefunden")
                return True
            
            with engine.connect() as conn:
                for seed_file in sorted(seeds_dir.glob('*.sql')):
                    logger.info(f"📊 Lade Seed-Daten: {seed_file.name}")
                    
                    with open(seed_file, 'r', encoding='utf-8') as f:
                        sql_content = f.read()
                        
                    # SQL-Statements einzeln ausführen
                    for statement in sql_content.split(';'):
                        statement = statement.strip()
                        if statement:
                            conn.execute(text(statement))
                            
                conn.commit()
                
            logger.info("✅ Seed-Daten erfolgreich geladen")
            return True
            
        except Exception as e:
            logger.error(f"❌ Seed-Daten laden fehlgeschlagen: {e}")
            return False

def main():
    """Hauptfunktion für CLI-Verwendung"""
    import argparse
    
    parser = argparse.ArgumentParser(description='Database-Migration-Management')
    parser.add_argument(
        'action',
        choices=[
            'init', 'current', 'history', 'create', 'migrate', 
            'rollback', 'seed', 'reset', 'status'
        ],
        help='Aktion die ausgeführt werden soll'
    )
    parser.add_argument('--message', '-m', help='Migration-Message (für create)')
    parser.add_argument('--revision', '-r', help='Ziel-Revision (für migrate/rollback)')
    parser.add_argument('--force', action='store_true', help='Forciert Ausführung')
    
    args = parser.parse_args()
    
    manager = MigrationManager()
    
    if args.action == 'init':
        # Database und Schema initialisieren
        if manager.create_database_if_not_exists():
            if manager.run_migrations():
                manager.seed_initial_data()
                
    elif args.action == 'current':
        manager.get_current_revision()
        
    elif args.action == 'history':
        history = manager.get_migration_history()
        for line in history:
            print(line)
            
    elif args.action == 'create':
        if not args.message:
            logger.error("❌ Migration-Message erforderlich (--message)")
            sys.exit(1)
        manager.create_migration(args.message)
        
    elif args.action == 'migrate':
        target = args.revision or 'head'
        manager.run_migrations(target)
        
    elif args.action == 'rollback':
        if not args.revision:
            logger.error("❌ Ziel-Revision erforderlich (--revision)")
            sys.exit(1)
        manager.rollback_migration(args.revision)
        
    elif args.action == 'seed':
        manager.seed_initial_data()
        
    elif args.action == 'reset':
        if args.force:
            manager.rollback_migration('base')
            manager.run_migrations()
            manager.seed_initial_data()
        else:
            logger.warning("⚠️ Reset erfordert --force Flag")
            
    elif args.action == 'status':
        manager.check_database_connection()
        manager.get_current_revision()

if __name__ == '__main__':
    main()
```

### 3.5 systemd-Service für Migrations

```ini
# /etc/systemd/system/aktienanalyse-migration.service
[Unit]
Description=Aktienanalyse Database Migration Service
Before=aktienanalyse-core.service
Before=aktienanalyse-broker.service
Before=aktienanalyse-events.service
Before=aktienanalyse-monitoring.service
After=postgresql.service
Wants=postgresql.service

[Service]
Type=oneshot
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python scripts/manage_migrations.py init
RemainAfterExit=yes
TimeoutStartSec=300
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=aktienanalyse.target
```

### 3.6 Bootstrap-Script für Erstinstallation

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/bootstrap_database.sh
"""Database-Bootstrap für Initial-Setup"""

set -euo pipefail

# Konfiguration
PROJECT_ROOT="/opt/aktienanalyse-ökosystem"
LOG_FILE="/var/log/aktienanalyse/bootstrap.log"
MIGRATION_SCRIPT="$PROJECT_ROOT/scripts/manage_migrations.py"

# Logging-Funktion
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Fehler-Handler
error_exit() {
    log "❌ FEHLER: $1"
    exit 1
}

# Hauptfunktion
main() {
    log "🚀 Starte Database-Bootstrap für Aktienanalyse-Ökosystem"
    
    # Virtual Environment aktivieren
    source "$PROJECT_ROOT/venv/bin/activate" || error_exit "Virtual Environment nicht gefunden"
    
    # Python-Path setzen
    export PYTHONPATH="$PROJECT_ROOT"
    
    # Environment-Variablen laden
    if [ -f "$PROJECT_ROOT/config/environments/production.env" ]; then
        source "$PROJECT_ROOT/config/environments/production.env"
        log "✅ Environment-Variablen geladen"
    else
        error_exit "Environment-Datei nicht gefunden"
    fi
    
    # Database-Verbindung testen
    log "🔗 Teste Database-Verbindung..."
    python3 -c "
import sys
sys.path.append('$PROJECT_ROOT')
from shared.config import DatabaseConfig
import psycopg2

try:
    db_config = DatabaseConfig()
    conn = psycopg2.connect(
        host=db_config.host,
        port=db_config.port,
        user=db_config.user,
        password=db_config.password,
        database='postgres'
    )
    conn.close()
    print('✅ PostgreSQL-Server erreichbar')
except Exception as e:
    print(f'❌ PostgreSQL-Verbindung fehlgeschlagen: {e}')
    sys.exit(1)
" || error_exit "PostgreSQL-Server nicht erreichbar"
    
    # Database initialisieren
    log "📦 Initialisiere Database und Schema..."
    python3 "$MIGRATION_SCRIPT" init || error_exit "Database-Initialisierung fehlgeschlagen"
    
    # Migration-Status prüfen
    log "📍 Prüfe Migration-Status..."
    python3 "$MIGRATION_SCRIPT" current || error_exit "Migration-Status-Check fehlgeschlagen"
    
    log "✅ Database-Bootstrap erfolgreich abgeschlossen"
}

# Script ausführen
main "$@"
```

---

## 5. Vollautomatische GitHub Actions CI/CD-Pipeline

### 5.1 GitHub Actions Workflow-Architektur

```yaml
# .github/workflows/main.yml
name: 🚀 Aktienanalyse-Ökosystem CI/CD Pipeline

on:
  push:
    branches: [ main, develop, 'feature/*', 'hotfix/*' ]
  pull_request:
    branches: [ main, develop ]
  release:
    types: [published]
  schedule:
    # Nächtliche Builds um 02:00 UTC
    - cron: '0 2 * * *'

env:
  PROJECT_NAME: aktienanalyse-ökosystem
  PYTHON_VERSION: "3.9"
  NODE_VERSION: "18"
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}

# Globale Permissions
permissions:
  contents: read
  packages: write
  security-events: write
  issues: write
  pull-requests: write

jobs:
  # ==============================================
  # STAGE 1: CODE QUALITY & SECURITY
  # ==============================================
  
  code-quality:
    name: 🔍 Code Quality & Security Analysis
    runs-on: ubuntu-latest
    timeout-minutes: 15
    
    strategy:
      matrix:
        analysis: [python, javascript, security]
    
    steps:
      - name: 📥 Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: 🐍 Setup Python ${{ env.PYTHON_VERSION }}
        if: matrix.analysis == 'python' || matrix.analysis == 'security'
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          
      - name: 📦 Setup Node.js ${{ env.NODE_VERSION }}
        if: matrix.analysis == 'javascript' || matrix.analysis == 'security'
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: '**/package-lock.json'
          
      # Python Code Quality
      - name: 🔧 Python Dependencies
        if: matrix.analysis == 'python'
        run: |
          python -m pip install --upgrade pip
          pip install black isort flake8 mypy pytest pytest-cov bandit safety
          find . -name "requirements*.txt" -exec pip install -r {} \;
          
      - name: 🎨 Python Code Formatting (Black)
        if: matrix.analysis == 'python'
        run: |
          black --check --diff --color .
          
      - name: 📋 Python Import Sorting (isort)
        if: matrix.analysis == 'python'
        run: |
          isort --check-only --diff --color .
          
      - name: 🔍 Python Linting (Flake8)
        if: matrix.analysis == 'python'
        run: |
          flake8 --statistics --show-source --count
          
      - name: 🏷️ Python Type Checking (MyPy)
        if: matrix.analysis == 'python'
        run: |
          mypy --config-file=pyproject.toml .
          
      # JavaScript Code Quality  
      - name: 📦 JavaScript Dependencies
        if: matrix.analysis == 'javascript'
        run: |
          npm ci
          
      - name: 🎨 JavaScript Linting (ESLint)
        if: matrix.analysis == 'javascript'
        run: |
          npm run lint
          
      - name: 🔧 JavaScript Type Checking (TypeScript)
        if: matrix.analysis == 'javascript'
        run: |
          npm run type-check
          
      # Security Analysis
      - name: 🔒 Python Security (Bandit)
        if: matrix.analysis == 'security'
        run: |
          bandit -r . -f json -o bandit-report.json || true
          bandit -r . -f txt
          
      - name: 🛡️ Python Vulnerability Check (Safety)
        if: matrix.analysis == 'security'
        run: |
          safety check --json --output safety-report.json || true
          safety check
          
      - name: 🔐 JavaScript Security (npm audit)
        if: matrix.analysis == 'security'
        run: |
          npm audit --audit-level=moderate --json > npm-audit.json || true
          npm audit --audit-level=moderate
          
      # CodeQL Security Analysis
      - name: 🔍 Initialize CodeQL
        if: matrix.analysis == 'security'
        uses: github/codeql-action/init@v2
        with:
          languages: python, javascript
          
      - name: 🔍 Perform CodeQL Analysis
        if: matrix.analysis == 'security'
        uses: github/codeql-action/analyze@v2
        
      # Upload Security Reports
      - name: 📤 Upload Security Reports
        if: matrix.analysis == 'security'
        uses: actions/upload-artifact@v3
        with:
          name: security-reports
          path: |
            bandit-report.json
            safety-report.json
            npm-audit.json
          retention-days: 30

  # ==============================================
  # STAGE 2: TESTING
  # ==============================================
  
  test-python:
    name: 🧪 Python Testing
    runs-on: ubuntu-latest
    needs: code-quality
    timeout-minutes: 20
    
    strategy:
      matrix:
        test-type: [unit, integration]
        
    services:
      postgres:
        image: postgres:15
        env:
          POSTGRES_PASSWORD: test_password
          POSTGRES_USER: test_user
          POSTGRES_DB: aktienanalyse_test
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432
          
      redis:
        image: redis:7-alpine
        options: >-
          --health-cmd "redis-cli ping"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 6379:6379
    
    steps:
      - name: 📥 Checkout Code
        uses: actions/checkout@v4
        
      - name: 🐍 Setup Python ${{ env.PYTHON_VERSION }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          
      - name: 📦 Install Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install pytest pytest-cov pytest-xdist pytest-mock
          find . -name "requirements*.txt" -exec pip install -r {} \;
          
      - name: 🗄️ Setup Test Database
        run: |
          PGPASSWORD=test_password psql -h localhost -U test_user -d aktienanalyse_test -c "CREATE EXTENSION IF NOT EXISTS \"uuid-ossp\";"
          
      - name: 🧪 Run Unit Tests
        if: matrix.test-type == 'unit'
        run: |
          pytest tests/unit/ \
            --cov=services/ \
            --cov=shared/ \
            --cov-report=xml \
            --cov-report=html \
            --cov-report=term-missing \
            --cov-branch \
            --cov-fail-under=80 \
            --junitxml=junit-unit.xml \
            -v
        env:
          TEST_DATABASE_URL: postgresql://test_user:test_password@localhost:5432/aktienanalyse_test
          TEST_REDIS_URL: redis://localhost:6379/1
          
      - name: 🔗 Run Integration Tests
        if: matrix.test-type == 'integration'
        run: |
          pytest tests/integration/ \
            --cov=services/ \
            --cov=shared/ \
            --cov-report=xml \
            --cov-report=html \
            --junitxml=junit-integration.xml \
            -v
        env:
          TEST_DATABASE_URL: postgresql://test_user:test_password@localhost:5432/aktienanalyse_test
          TEST_REDIS_URL: redis://localhost:6379/1
          BITPANDA_API_KEY: ${{ secrets.BITPANDA_TEST_API_KEY }}
          BITPANDA_API_SECRET: ${{ secrets.BITPANDA_TEST_API_SECRET }}
          BITPANDA_SANDBOX: true
          
      - name: 📊 Upload Coverage to Codecov
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          file: ./coverage.xml
          flags: ${{ matrix.test-type }}
          name: ${{ matrix.test-type }}-tests
          
      - name: 📤 Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: test-results-${{ matrix.test-type }}
          path: |
            junit-*.xml
            htmlcov/
            coverage.xml

  test-frontend:
    name: 🌐 Frontend Testing
    runs-on: ubuntu-latest
    needs: code-quality
    timeout-minutes: 15
    
    steps:
      - name: 📥 Checkout Code
        uses: actions/checkout@v4
        
      - name: 📦 Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: 'services/frontend/package-lock.json'
          
      - name: 📦 Install Dependencies
        working-directory: services/frontend
        run: npm ci
        
      - name: 🧪 Run Unit Tests
        working-directory: services/frontend
        run: |
          npm run test:coverage
          
      - name: 🎭 Run E2E Tests (Playwright)
        working-directory: services/frontend
        run: |
          npx playwright install --with-deps
          npm run test:e2e
          
      - name: 📤 Upload Test Results
        uses: actions/upload-artifact@v3
        if: always()
        with:
          name: frontend-test-results
          path: |
            services/frontend/coverage/
            services/frontend/test-results/
            services/frontend/playwright-report/

  # ==============================================
  # STAGE 3: BUILD & PACKAGE
  # ==============================================
  
  build:
    name: 🏗️ Build & Package
    runs-on: ubuntu-latest
    needs: [test-python, test-frontend]
    timeout-minutes: 25
    if: github.event_name != 'pull_request'
    
    outputs:
      version: ${{ steps.version.outputs.version }}
      
    steps:
      - name: 📥 Checkout Code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0
          
      - name: 🏷️ Generate Version
        id: version
        run: |
          if [[ "${{ github.ref }}" == "refs/tags/"* ]]; then
            VERSION=${GITHUB_REF#refs/tags/}
          else
            VERSION="$(date +%Y.%m.%d)-${GITHUB_SHA::8}"
          fi
          echo "version=$VERSION" >> $GITHUB_OUTPUT
          echo "Generated version: $VERSION"
          
      - name: 🐍 Setup Python ${{ env.PYTHON_VERSION }}
        uses: actions/setup-python@v4
        with:
          python-version: ${{ env.PYTHON_VERSION }}
          cache: 'pip'
          
      - name: 📦 Setup Node.js ${{ env.NODE_VERSION }}
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
          cache-dependency-path: 'services/frontend/package-lock.json'
          
      - name: 📦 Install Python Dependencies
        run: |
          python -m pip install --upgrade pip
          pip install build wheel
          find . -name "requirements*.txt" -exec pip install -r {} \;
          
      - name: 🏗️ Build Frontend
        working-directory: services/frontend
        run: |
          npm ci
          npm run build
          
      - name: 📦 Create Python Wheels
        run: |
          mkdir -p dist/
          for service in services/*/; do
            if [ -f "$service/setup.py" ] || [ -f "$service/pyproject.toml" ]; then
              echo "Building $service..."
              cd "$service"
              python -m build
              cp dist/*.whl ../../dist/
              cd - > /dev/null
            fi
          done
          
      - name: 📦 Create Distribution Package
        run: |
          mkdir -p release/
          cp -r services/ release/
          cp -r shared/ release/
          cp -r config/ release/
          cp -r scripts/ release/
          cp -r migrations/ release/
          cp requirements*.txt release/ 2>/dev/null || true
          cp README.md release/
          cp LICENSE release/ 2>/dev/null || true
          
          # Version-Info hinzufügen
          echo "${{ steps.version.outputs.version }}" > release/VERSION
          echo "Built on: $(date)" >> release/VERSION
          echo "Commit: ${{ github.sha }}" >> release/VERSION
          
          # Archiv erstellen
          tar -czf aktienanalyse-ecosystem-${{ steps.version.outputs.version }}.tar.gz -C release .
          
      - name: 📤 Upload Build Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: |
            aktienanalyse-ecosystem-*.tar.gz
            dist/*.whl
          retention-days: 90

  # ==============================================
  # STAGE 4: DEPLOYMENT (Production)
  # ==============================================
  
  deploy-production:
    name: 🚀 Production Deployment
    runs-on: ubuntu-latest
    needs: build
    timeout-minutes: 30
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    environment: 
      name: production
      url: https://aktienanalyse.local
      
    steps:
      - name: 📥 Download Build Artifacts
        uses: actions/download-artifact@v3
        with:
          name: build-artifacts
          
      - name: 🔐 Setup SSH Key
        uses: webfactory/ssh-agent@v0.7.0
        with:
          ssh-private-key: ${{ secrets.PRODUCTION_SSH_KEY }}
          
      - name: ✅ Verify Target Server
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "echo 'Server connection successful'"
          
      - name: 📤 Upload Release Package
        run: |
          scp -o StrictHostKeyChecking=no aktienanalyse-ecosystem-*.tar.gz aktienanalyse@10.1.1.110:/tmp/
          
      - name: 🛑 Stop Current Services
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sudo /opt/aktienanalyse-ökosystem/scripts/orchestration.sh stop || true
          "
          
      - name: 💾 Backup Current Installation
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sudo mkdir -p /opt/backups/aktienanalyse
            sudo tar -czf /opt/backups/aktienanalyse/backup-$(date +%Y%m%d-%H%M%S).tar.gz -C /opt aktienanalyse-ökosystem/ 2>/dev/null || true
          "
          
      - name: 📦 Deploy New Version
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            # Extract new version
            cd /tmp
            tar -xzf aktienanalyse-ecosystem-*.tar.gz
            
            # Backup current config
            sudo cp -r /opt/aktienanalyse-ökosystem/config/ /tmp/config-backup/ 2>/dev/null || true
            
            # Deploy new version
            sudo rm -rf /opt/aktienanalyse-ökosystem-new
            sudo mkdir -p /opt/aktienanalyse-ökosystem-new
            sudo mv services/ shared/ scripts/ migrations/ /opt/aktienanalyse-ökosystem-new/
            sudo mv requirements*.txt VERSION /opt/aktienanalyse-ökosystem-new/ 2>/dev/null || true
            
            # Restore config
            sudo cp -r /tmp/config-backup/* /opt/aktienanalyse-ökosystem-new/config/ 2>/dev/null || true
            
            # Atomic switch
            sudo mv /opt/aktienanalyse-ökosystem /opt/aktienanalyse-ökosystem-old 2>/dev/null || true
            sudo mv /opt/aktienanalyse-ökosystem-new /opt/aktienanalyse-ökosystem
            
            # Set permissions
            sudo chown -R aktienanalyse:aktienanalyse /opt/aktienanalyse-ökosystem
            sudo chmod +x /opt/aktienanalyse-ökosystem/scripts/*.sh
          "
          
      - name: 🔄 Run Database Migrations
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            cd /opt/aktienanalyse-ökosystem
            source venv/bin/activate
            python scripts/manage_migrations.py migrate
          "
          
      - name: ⚙️ Update systemd Services
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sudo systemctl daemon-reload
          "
          
      - name: 🚀 Start Services
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sudo /opt/aktienanalyse-ökosystem/scripts/orchestration.sh start
          "
          
      - name: 🏥 Health Check
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sleep 30
            /opt/aktienanalyse-ökosystem/scripts/orchestration.sh health
          "
          
      - name: 🧹 Cleanup
        if: always()
        run: |
          ssh -o StrictHostKeyChecking=no aktienanalyse@10.1.1.110 "
            sudo rm -rf /opt/aktienanalyse-ökosystem-old
            rm -f /tmp/aktienanalyse-ecosystem-*.tar.gz
            rm -rf /tmp/config-backup
            
            # Keep only last 5 backups
            sudo find /opt/backups/aktienanalyse/ -name 'backup-*.tar.gz' -type f | sort | head -n -5 | sudo xargs rm -f 2>/dev/null || true
          "

  # ==============================================
  # STAGE 5: NOTIFICATIONS & REPORTING
  # ==============================================
  
  notify:
    name: 📢 Notifications
    runs-on: ubuntu-latest
    needs: [deploy-production]
    if: always()
    
    steps:
      - name: 📊 Create Deployment Summary
        run: |
          echo "# 🚀 Deployment Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          echo "**Branch:** ${{ github.ref_name }}" >> $GITHUB_STEP_SUMMARY
          echo "**Commit:** ${{ github.sha }}" >> $GITHUB_STEP_SUMMARY
          echo "**Author:** ${{ github.actor }}" >> $GITHUB_STEP_SUMMARY
          echo "**Timestamp:** $(date)" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY
          
          if [[ "${{ needs.deploy-production.result }}" == "success" ]]; then
            echo "✅ **Deployment Status:** SUCCESS" >> $GITHUB_STEP_SUMMARY
            echo "🌐 **Application:** https://aktienanalyse.local" >> $GITHUB_STEP_SUMMARY
          else
            echo "❌ **Deployment Status:** FAILED" >> $GITHUB_STEP_SUMMARY
          fi
          
      - name: 💬 Post to Discord
        if: always()
        uses: Ilshidur/action-discord@master
        env:
          DISCORD_WEBHOOK: ${{ secrets.DISCORD_WEBHOOK }}
        with:
          args: |
            🚀 **Aktienanalyse-Ökosystem Deployment**
            
            **Status:** ${{ needs.deploy-production.result == 'success' && '✅ SUCCESS' || '❌ FAILED' }}
            **Branch:** ${{ github.ref_name }}
            **Version:** ${{ needs.build.outputs.version }}
            **Commit:** `${{ github.sha }}`
            **Author:** ${{ github.actor }}
            
            ${{ needs.deploy-production.result == 'success' && '🌐 Application: https://aktienanalyse.local' || '🔍 Check logs for details' }}

# ==============================================
# REUSABLE WORKFLOWS & TEMPLATES
# ==============================================

  # Hotfix Deployment Workflow
  deploy-hotfix:
    name: 🔥 Hotfix Deployment
    runs-on: ubuntu-latest
    if: startsWith(github.ref, 'refs/heads/hotfix/')
    environment: 
      name: hotfix
      
    steps:
      - name: ⚡ Fast-Track Deployment
        run: |
          echo "Implementing fast-track deployment for hotfix..."
          # Simplified deployment process for urgent fixes
```

### 5.2 GitHub Environments & Secrets

```yaml
# GitHub Repository Settings
Environments:
  production:
    protection_rules:
      - required_reviewers: 1
      - restrict_pushes: true
      - deployment_branches: [main]
    secrets:
      - PRODUCTION_SSH_KEY
      - BITPANDA_API_KEY
      - BITPANDA_API_SECRET
      - DATABASE_PASSWORD
      - DISCORD_WEBHOOK
      - CODECOV_TOKEN
      
  staging:
    protection_rules: []
    secrets:
      - STAGING_SSH_KEY
      - BITPANDA_TEST_API_KEY
      - BITPANDA_TEST_API_SECRET
      
  hotfix:
    protection_rules:
      - required_reviewers: 1
    secrets:
      - PRODUCTION_SSH_KEY
```

### 5.3 Deployment-Helper-Scripts

```bash
#!/bin/bash
# .github/scripts/deploy-helper.sh
"""GitHub Actions Deployment Helper"""

set -euo pipefail

DEPLOYMENT_USER="aktienanalyse"
DEPLOYMENT_HOST="10.1.1.110"
PROJECT_PATH="/opt/aktienanalyse-ökosystem"

# Logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Pre-deployment Health Check
pre_deployment_check() {
    log "🔍 Pre-deployment Health Check..."
    
    # Server erreichbar?
    if ! ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "echo 'Server reachable'"; then
        log "❌ Target server not reachable"
        return 1
    fi
    
    # Disk Space verfügbar?
    local disk_usage=$(ssh "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "df $PROJECT_PATH | awk 'NR==2 {print \$5}' | sed 's/%//'")
    if [ "$disk_usage" -gt 85 ]; then
        log "⚠️ Warning: Disk usage is $disk_usage%"
    fi
    
    # Services Status
    ssh "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "$PROJECT_PATH/scripts/orchestration.sh status" || true
    
    log "✅ Pre-deployment check complete"
}

# Deployment Rollback
rollback_deployment() {
    local backup_name="$1"
    
    log "🔄 Rolling back to $backup_name..."
    
    ssh "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "
        sudo /opt/aktienanalyse-ökosystem/scripts/orchestration.sh stop
        sudo rm -rf /opt/aktienanalyse-ökosystem
        sudo tar -xzf /opt/backups/aktienanalyse/$backup_name -C /opt
        sudo /opt/aktienanalyse-ökosystem/scripts/orchestration.sh start
    "
    
    log "✅ Rollback complete"
}

# Post-deployment Verification
post_deployment_verify() {
    log "✅ Post-deployment Verification..."
    
    # Wait for services to be ready
    local max_wait=120
    local waited=0
    
    while [ $waited -lt $max_wait ]; do
        if ssh "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "$PROJECT_PATH/scripts/orchestration.sh health" >/dev/null 2>&1; then
            log "✅ All services healthy"
            break
        fi
        
        sleep 5
        waited=$((waited + 5))
    done
    
    if [ $waited -ge $max_wait ]; then
        log "❌ Health check timeout"
        return 1
    fi
    
    # Test critical endpoints
    local endpoints=(
        "http://localhost:8001/health"
        "http://localhost:8002/health"
        "https://localhost:8443/health"
    )
    
    for endpoint in "${endpoints[@]}"; do
        if ssh "$DEPLOYMENT_USER@$DEPLOYMENT_HOST" "curl -sf '$endpoint' >/dev/null"; then
            log "✅ $endpoint OK"
        else
            log "❌ $endpoint FAILED"
            return 1
        fi
    done
    
    log "✅ Post-deployment verification complete"
}

# Hauptfunktion
main() {
    case "${1:-}" in
        "pre-check")
            pre_deployment_check
            ;;
        "rollback")
            rollback_deployment "${2:-}"
            ;;
        "verify")
            post_deployment_verify
            ;;
        *)
            echo "Usage: $0 {pre-check|rollback <backup>|verify}"
            exit 1
            ;;
    esac
}

main "$@"
```

---

## 6. Minimale Monitoring-Integration (systemd + Zabbix)

### 6.1 systemd Service Monitoring

```ini
# /etc/systemd/system/aktienanalyse-monitoring.service (Enhanced)
[Unit]
Description=Aktienanalyse System Monitoring Service
Documentation=https://docs.aktienanalyse.local/monitoring
After=network-online.target aktienanalyse-core.service aktienanalyse-events.service
Wants=network-online.target aktienanalyse-core.service aktienanalyse-events.service
PartOf=aktienanalyse.target

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/monitoring
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=monitoring-service
Environment=ZABBIX_SERVER=10.1.1.103
Environment=ZABBIX_PORT=10051
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStartPre=/bin/bash -c 'echo "📊 Starting Monitoring Service..." | systemd-cat -t aktienanalyse-monitoring'
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecStartPost=/bin/bash -c 'echo "✅ Monitoring Service gestartet" | systemd-cat -t aktienanalyse-monitoring'
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
Restart=always
RestartSec=10
StartLimitBurst=5
StartLimitIntervalSec=60
LimitNOFILE=65536
MemoryMax=512M
CPUQuota=100%
TasksMax=128
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-monitoring
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /var/log/aktienanalyse

[Install]
WantedBy=aktienanalyse.target
```

### 6.2 Monitoring Service Implementation

```python
#!/usr/bin/env python3
# /opt/aktienanalyse-ökosystem/services/monitoring/main.py
"""Aktienanalyse System Monitoring Service"""

import asyncio
import json
import logging
import time
import socket
import subprocess
import psutil
from datetime import datetime
from typing import Dict, Any, List, Optional
from dataclasses import dataclass, asdict
from pathlib import Path

import aiohttp
import redis.asyncio as redis
from pyzabbix import ZabbixMetric, ZabbixSender

# Konfiguration
@dataclass
class MonitoringConfig:
    """Monitoring-Konfiguration"""
    zabbix_server: str = "10.1.1.103"
    zabbix_port: int = 10051
    hostname: str = socket.gethostname()
    interval_seconds: int = 30
    service_ports: Dict[str, int] = None
    log_level: str = "INFO"
    
    def __post_init__(self):
        if self.service_ports is None:
            self.service_ports = {
                "aktienanalyse-core": 8001,
                "aktienanalyse-broker": 8002,
                "aktienanalyse-events": 8003,
                "aktienanalyse-monitoring": 8004,
                "aktienanalyse-frontend": 8443
            }

@dataclass
class ServiceMetrics:
    """Service-Metriken"""
    name: str
    status: str
    cpu_percent: float
    memory_mb: float
    memory_percent: float
    uptime_seconds: int
    restart_count: int
    port_open: bool
    http_response_time: Optional[float] = None
    http_status_code: Optional[int] = None
    last_error: Optional[str] = None

@dataclass
class SystemMetrics:
    """System-Metriken"""
    cpu_usage: float
    memory_usage: float
    disk_usage: float
    load_avg: List[float]
    network_connections: int
    disk_io_read: int
    disk_io_write: int
    process_count: int

class ServiceMonitor:
    """Service-Monitor für systemd Services"""
    
    def __init__(self, config: MonitoringConfig):
        self.config = config
        self.logger = self._setup_logger()
        
    def _setup_logger(self) -> logging.Logger:
        """Logger-Setup"""
        logger = logging.getLogger("service_monitor")
        logger.setLevel(getattr(logging, self.config.log_level))
        
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
        
        return logger
    
    def get_service_status(self, service_name: str) -> Dict[str, Any]:
        """systemd Service-Status ermitteln"""
        try:
            # Service-Status
            result = subprocess.run(
                ["systemctl", "show", service_name, "--no-page"],
                capture_output=True,
                text=True,
                timeout=10
            )
            
            properties = {}
            for line in result.stdout.split('\n'):
                if '=' in line:
                    key, value = line.split('=', 1)
                    properties[key] = value
            
            return {
                "active_state": properties.get("ActiveState", "unknown"),
                "sub_state": properties.get("SubState", "unknown"),
                "load_state": properties.get("LoadState", "unknown"),
                "main_pid": int(properties.get("MainPID", "0")),
                "exec_main_start_timestamp": properties.get("ExecMainStartTimestamp", ""),
                "restart_count": int(properties.get("NRestarts", "0")),
                "memory_current": int(properties.get("MemoryCurrent", "0")),
                "cpu_usage_nsec": int(properties.get("CPUUsageNSec", "0"))
            }
            
        except Exception as e:
            self.logger.error(f"Error getting status for {service_name}: {e}")
            return {}
    
    def get_process_metrics(self, pid: int) -> Dict[str, float]:
        """Process-Metriken für PID ermitteln"""
        try:
            if pid <= 0:
                return {"cpu_percent": 0.0, "memory_mb": 0.0, "memory_percent": 0.0}
                
            process = psutil.Process(pid)
            
            # CPU und Memory
            cpu_percent = process.cpu_percent(interval=0.1)
            memory_info = process.memory_info()
            memory_percent = process.memory_percent()
            
            return {
                "cpu_percent": cpu_percent,
                "memory_mb": memory_info.rss / 1024 / 1024,  # Bytes -> MB
                "memory_percent": memory_percent
            }
            
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            return {"cpu_percent": 0.0, "memory_mb": 0.0, "memory_percent": 0.0}
    
    async def check_service_port(self, port: int, timeout: float = 5.0) -> bool:
        """Port-Verfügbarkeit prüfen"""
        try:
            reader, writer = await asyncio.wait_for(
                asyncio.open_connection('localhost', port),
                timeout=timeout
            )
            writer.close()
            await writer.wait_closed()
            return True
        except Exception:
            return False
    
    async def check_http_health(self, port: int, path: str = "/health", timeout: float = 5.0) -> Dict[str, Any]:
        """HTTP Health-Check"""
        try:
            url = f"http://localhost:{port}{path}"
            if port == 8443:  # HTTPS für Frontend
                url = f"https://localhost:{port}{path}"
            
            start_time = time.time()
            
            async with aiohttp.ClientSession(
                timeout=aiohttp.ClientTimeout(total=timeout),
                connector=aiohttp.TCPConnector(ssl=False)  # Ignore SSL für localhost
            ) as session:
                async with session.get(url) as response:
                    response_time = (time.time() - start_time) * 1000  # ms
                    
                    return {
                        "response_time": response_time,
                        "status_code": response.status,
                        "success": 200 <= response.status < 300
                    }
                    
        except Exception as e:
            return {
                "response_time": None,
                "status_code": None,
                "success": False,
                "error": str(e)
            }
    
    async def collect_service_metrics(self, service_name: str) -> ServiceMetrics:
        """Service-Metriken sammeln"""
        try:
            # systemd Service-Status
            status = self.get_service_status(service_name)
            
            # Process-Metriken
            main_pid = status.get("main_pid", 0)
            process_metrics = self.get_process_metrics(main_pid)
            
            # Uptime berechnen
            start_timestamp = status.get("exec_main_start_timestamp", "")
            uptime_seconds = 0
            if start_timestamp and start_timestamp != "0":
                try:
                    start_time = int(start_timestamp) / 1000000  # microseconds -> seconds
                    uptime_seconds = int(time.time() - start_time)
                except ValueError:
                    pass
            
            # Port-Check
            port = self.config.service_ports.get(service_name, 0)
            port_open = False
            http_response_time = None
            http_status_code = None
            last_error = None
            
            if port > 0:
                port_open = await self.check_service_port(port)
                
                if port_open:
                    health_result = await self.check_http_health(port)
                    http_response_time = health_result.get("response_time")
                    http_status_code = health_result.get("status_code")
                    if not health_result.get("success"):
                        last_error = health_result.get("error")
            
            return ServiceMetrics(
                name=service_name,
                status=status.get("active_state", "unknown"),
                cpu_percent=process_metrics["cpu_percent"],
                memory_mb=process_metrics["memory_mb"],
                memory_percent=process_metrics["memory_percent"],
                uptime_seconds=uptime_seconds,
                restart_count=status.get("restart_count", 0),
                port_open=port_open,
                http_response_time=http_response_time,
                http_status_code=http_status_code,
                last_error=last_error
            )
            
        except Exception as e:
            self.logger.error(f"Error collecting metrics for {service_name}: {e}")
            return ServiceMetrics(
                name=service_name,
                status="error",
                cpu_percent=0.0,
                memory_mb=0.0,
                memory_percent=0.0,
                uptime_seconds=0,
                restart_count=0,
                port_open=False,
                last_error=str(e)
            )

class SystemMonitor:
    """System-Metriken-Monitor"""
    
    def __init__(self):
        self.logger = logging.getLogger("system_monitor")
    
    def collect_system_metrics(self) -> SystemMetrics:
        """System-Metriken sammeln"""
        try:
            # CPU-Auslastung
            cpu_usage = psutil.cpu_percent(interval=1)
            
            # Memory-Auslastung
            memory = psutil.virtual_memory()
            memory_usage = memory.percent
            
            # Disk-Auslastung (für Root-Partition)
            disk = psutil.disk_usage('/')
            disk_usage = disk.percent
            
            # Load Average
            load_avg = list(psutil.getloadavg())
            
            # Netzwerk-Verbindungen
            connections = len(psutil.net_connections())
            
            # Disk I/O
            disk_io = psutil.disk_io_counters()
            disk_io_read = disk_io.read_bytes if disk_io else 0
            disk_io_write = disk_io.write_bytes if disk_io else 0
            
            # Process-Count
            process_count = len(psutil.pids())
            
            return SystemMetrics(
                cpu_usage=cpu_usage,
                memory_usage=memory_usage,
                disk_usage=disk_usage,
                load_avg=load_avg,
                network_connections=connections,
                disk_io_read=disk_io_read,
                disk_io_write=disk_io_write,
                process_count=process_count
            )
            
        except Exception as e:
            self.logger.error(f"Error collecting system metrics: {e}")
            return SystemMetrics(
                cpu_usage=0.0,
                memory_usage=0.0,
                disk_usage=0.0,
                load_avg=[0.0, 0.0, 0.0],
                network_connections=0,
                disk_io_read=0,
                disk_io_write=0,
                process_count=0
            )

class ZabbixIntegration:
    """Zabbix-Integration für Metriken-Übertragung"""
    
    def __init__(self, config: MonitoringConfig):
        self.config = config
        self.logger = logging.getLogger("zabbix_integration")
        self.sender = ZabbixSender(
            zabbix_server=config.zabbix_server,
            zabbix_port=config.zabbix_port
        )
    
    def send_service_metrics(self, metrics: ServiceMetrics) -> bool:
        """Service-Metriken an Zabbix senden"""
        try:
            zabbix_metrics = [
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.status[{metrics.name}]",
                    value=1 if metrics.status == "active" else 0
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.cpu[{metrics.name}]",
                    value=metrics.cpu_percent
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.memory[{metrics.name}]",
                    value=metrics.memory_mb
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.uptime[{metrics.name}]",
                    value=metrics.uptime_seconds
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.restarts[{metrics.name}]",
                    value=metrics.restart_count
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key=f"aktienanalyse.service.port[{metrics.name}]",
                    value=1 if metrics.port_open else 0
                )
            ]
            
            # HTTP-Metriken nur wenn verfügbar
            if metrics.http_response_time is not None:
                zabbix_metrics.append(
                    ZabbixMetric(
                        host=self.config.hostname,
                        key=f"aktienanalyse.service.response_time[{metrics.name}]",
                        value=metrics.http_response_time
                    )
                )
            
            if metrics.http_status_code is not None:
                zabbix_metrics.append(
                    ZabbixMetric(
                        host=self.config.hostname,
                        key=f"aktienanalyse.service.http_status[{metrics.name}]",
                        value=metrics.http_status_code
                    )
                )
            
            # An Zabbix senden
            response = self.sender.send(zabbix_metrics)
            
            if response.failed == 0:
                self.logger.debug(f"Successfully sent {len(zabbix_metrics)} metrics for {metrics.name}")
                return True
            else:
                self.logger.warning(f"Failed to send {response.failed} metrics for {metrics.name}")
                return False
                
        except Exception as e:
            self.logger.error(f"Error sending metrics for {metrics.name}: {e}")
            return False
    
    def send_system_metrics(self, metrics: SystemMetrics) -> bool:
        """System-Metriken an Zabbix senden"""
        try:
            zabbix_metrics = [
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.cpu",
                    value=metrics.cpu_usage
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.memory",
                    value=metrics.memory_usage
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.disk",
                    value=metrics.disk_usage
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.load_avg",
                    value=metrics.load_avg[0]
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.connections",
                    value=metrics.network_connections
                ),
                ZabbixMetric(
                    host=self.config.hostname,
                    key="aktienanalyse.system.processes",
                    value=metrics.process_count
                )
            ]
            
            response = self.sender.send(zabbix_metrics)
            
            if response.failed == 0:
                self.logger.debug(f"Successfully sent {len(zabbix_metrics)} system metrics")
                return True
            else:
                self.logger.warning(f"Failed to send {response.failed} system metrics")
                return False
                
        except Exception as e:
            self.logger.error(f"Error sending system metrics: {e}")
            return False

class MonitoringService:
    """Hauptklasse für Monitoring-Service"""
    
    def __init__(self):
        self.config = MonitoringConfig()
        self.service_monitor = ServiceMonitor(self.config)
        self.system_monitor = SystemMonitor()
        self.zabbix = ZabbixIntegration(self.config)
        self.logger = logging.getLogger("monitoring_service")
        
        # Services die überwacht werden sollen
        self.monitored_services = [
            "aktienanalyse-core",
            "aktienanalyse-broker", 
            "aktienanalyse-events",
            "aktienanalyse-frontend"
        ]
        
        # Web-Server für Health-Check
        self.app = self._create_web_app()
    
    def _create_web_app(self):
        """Web-App für Health-Check erstellen"""
        from aiohttp import web, web_response
        
        app = web.Application()
        
        async def health_check(request):
            """Health-Check Endpoint"""
            try:
                # Kurzer Status-Check
                healthy_services = 0
                for service in self.monitored_services:
                    status = self.service_monitor.get_service_status(service)
                    if status.get("active_state") == "active":
                        healthy_services += 1
                
                health_status = {
                    "status": "healthy" if healthy_services == len(self.monitored_services) else "degraded",
                    "timestamp": datetime.now().isoformat(),
                    "services_healthy": healthy_services,
                    "services_total": len(self.monitored_services),
                    "hostname": self.config.hostname
                }
                
                return web_response.json_response(health_status)
                
            except Exception as e:
                return web_response.json_response(
                    {"status": "error", "error": str(e)},
                    status=500
                )
        
        app.router.add_get('/health', health_check)
        return app
    
    async def collect_and_send_metrics(self):
        """Metriken sammeln und an Zabbix senden"""
        try:
            # Service-Metriken sammeln
            for service_name in self.monitored_services:
                self.logger.debug(f"Collecting metrics for {service_name}")
                metrics = await self.service_monitor.collect_service_metrics(service_name)
                
                # An Zabbix senden
                success = self.zabbix.send_service_metrics(metrics)
                if success:
                    self.logger.debug(f"Metrics sent for {service_name}")
                else:
                    self.logger.warning(f"Failed to send metrics for {service_name}")
            
            # System-Metriken sammeln
            self.logger.debug("Collecting system metrics")
            system_metrics = self.system_monitor.collect_system_metrics()
            
            # An Zabbix senden
            success = self.zabbix.send_system_metrics(system_metrics)
            if success:
                self.logger.debug("System metrics sent")
            else:
                self.logger.warning("Failed to send system metrics")
                
        except Exception as e:
            self.logger.error(f"Error in metrics collection cycle: {e}")
    
    async def monitoring_loop(self):
        """Hauptschleife für Monitoring"""
        self.logger.info(f"Starting monitoring loop with {self.config.interval_seconds}s interval")
        
        while True:
            try:
                await self.collect_and_send_metrics()
                await asyncio.sleep(self.config.interval_seconds)
                
            except asyncio.CancelledError:
                self.logger.info("Monitoring loop cancelled")
                break
            except Exception as e:
                self.logger.error(f"Error in monitoring loop: {e}")
                await asyncio.sleep(5)  # Kurze Pause bei Fehlern
    
    async def start_web_server(self):
        """Web-Server für Health-Checks starten"""
        try:
            from aiohttp import web
            
            runner = web.AppRunner(self.app)
            await runner.setup()
            
            site = web.TCPSite(runner, 'localhost', 8004)
            await site.start()
            
            self.logger.info("Health-Check web server started on http://localhost:8004")
            
        except Exception as e:
            self.logger.error(f"Error starting web server: {e}")
    
    async def run(self):
        """Service ausführen"""
        self.logger.info("🚀 Starting Aktienanalyse Monitoring Service")
        
        try:
            # Web-Server starten
            await self.start_web_server()
            
            # Monitoring-Loop starten
            await self.monitoring_loop()
            
        except KeyboardInterrupt:
            self.logger.info("Monitoring service stopped by user")
        except Exception as e:
            self.logger.error(f"Fatal error in monitoring service: {e}")
            raise
        finally:
            self.logger.info("Monitoring service shutdown complete")

async def main():
    """Hauptfunktion"""
    service = MonitoringService()
    await service.run()

if __name__ == "__main__":
    asyncio.run(main())
```

### 6.3 Zabbix Template für Aktienanalyse-Ökosystem

```json
{
  "zabbix_export": {
    "version": "6.0",
    "date": "2024-01-15T10:00:00Z",
    "groups": [
      {
        "uuid": "aktienanalyse-group-uuid",
        "name": "Aktienanalyse Ecosystem"
      }
    ],
    "templates": [
      {
        "uuid": "aktienanalyse-template-uuid",
        "template": "Aktienanalyse Ecosystem",
        "name": "Aktienanalyse Ecosystem Template",
        "groups": [
          {
            "name": "Aktienanalyse Ecosystem"
          }
        ],
        "items": [
          {
            "uuid": "item-system-cpu",
            "name": "System CPU Usage",
            "key": "aktienanalyse.system.cpu",
            "type": "ZABBIX_PASSIVE",
            "value_type": "FLOAT",
            "units": "%",
            "history": "7d",
            "trends": "365d",
            "description": "CPU-Auslastung des Aktienanalyse-Systems"
          },
          {
            "uuid": "item-system-memory",
            "name": "System Memory Usage",
            "key": "aktienanalyse.system.memory", 
            "type": "ZABBIX_PASSIVE",
            "value_type": "FLOAT",
            "units": "%",
            "history": "7d",
            "trends": "365d"
          },
          {
            "uuid": "item-system-disk",
            "name": "System Disk Usage",
            "key": "aktienanalyse.system.disk",
            "type": "ZABBIX_PASSIVE", 
            "value_type": "FLOAT",
            "units": "%",
            "history": "7d",
            "trends": "365d"
          }
        ],
        "discovery_rules": [
          {
            "uuid": "discovery-services",
            "name": "Aktienanalyse Services Discovery",
            "key": "aktienanalyse.services.discovery",
            "type": "ZABBIX_PASSIVE",
            "delay": "60s",
            "item_prototypes": [
              {
                "uuid": "prototype-service-status",
                "name": "Service {#SERVICE.NAME} Status",
                "key": "aktienanalyse.service.status[{#SERVICE.NAME}]",
                "type": "ZABBIX_PASSIVE",
                "value_type": "UNSIGNED"
              },
              {
                "uuid": "prototype-service-cpu",
                "name": "Service {#SERVICE.NAME} CPU",
                "key": "aktienanalyse.service.cpu[{#SERVICE.NAME}]",
                "type": "ZABBIX_PASSIVE",
                "value_type": "FLOAT",
                "units": "%"
              },
              {
                "uuid": "prototype-service-memory",
                "name": "Service {#SERVICE.NAME} Memory",
                "key": "aktienanalyse.service.memory[{#SERVICE.NAME}]",
                "type": "ZABBIX_PASSIVE",
                "value_type": "FLOAT",
                "units": "MB"
              },
              {
                "uuid": "prototype-service-response-time",
                "name": "Service {#SERVICE.NAME} Response Time",
                "key": "aktienanalyse.service.response_time[{#SERVICE.NAME}]",
                "type": "ZABBIX_PASSIVE",
                "value_type": "FLOAT",
                "units": "ms"
              }
            ],
            "trigger_prototypes": [
              {
                "uuid": "trigger-service-down",
                "expression": "last(/Template/aktienanalyse.service.status[{#SERVICE.NAME}])=0",
                "name": "Service {#SERVICE.NAME} is down",
                "priority": "HIGH",
                "description": "Aktienanalyse Service {#SERVICE.NAME} ist nicht verfügbar"
              },
              {
                "uuid": "trigger-service-high-cpu",
                "expression": "avg(/Template/aktienanalyse.service.cpu[{#SERVICE.NAME}],5m)>80",
                "name": "Service {#SERVICE.NAME} high CPU usage",
                "priority": "WARNING",
                "description": "Service {#SERVICE.NAME} hat hohe CPU-Auslastung (>80%)"
              },
              {
                "uuid": "trigger-service-high-memory",
                "expression": "last(/Template/aktienanalyse.service.memory[{#SERVICE.NAME}])>512",
                "name": "Service {#SERVICE.NAME} high memory usage",
                "priority": "WARNING",
                "description": "Service {#SERVICE.NAME} verbraucht viel Speicher (>512MB)"
              },
              {
                "uuid": "trigger-service-slow-response",
                "expression": "avg(/Template/aktienanalyse.service.response_time[{#SERVICE.NAME}],5m)>2000",
                "name": "Service {#SERVICE.NAME} slow response",
                "priority": "WARNING",
                "description": "Service {#SERVICE.NAME} antwortet langsam (>2s)"
              }
            ]
          }
        ],
        "triggers": [
          {
            "uuid": "trigger-system-high-cpu",
            "expression": "avg(/Template/aktienanalyse.system.cpu,5m)>90",
            "name": "System high CPU usage",
            "priority": "HIGH",
            "description": "System-CPU-Auslastung ist kritisch hoch (>90%)"
          },
          {
            "uuid": "trigger-system-high-memory",
            "expression": "last(/Template/aktienanalyse.system.memory)>85",
            "name": "System high memory usage",
            "priority": "HIGH",
            "description": "System-Speicher-Auslastung ist kritisch hoch (>85%)"
          },
          {
            "uuid": "trigger-system-high-disk",
            "expression": "last(/Template/aktienanalyse.system.disk)>90",
            "name": "System high disk usage",
            "priority": "HIGH",
            "description": "System-Festplatten-Auslastung ist kritisch hoch (>90%)"
          }
        ],
        "dashboards": [
          {
            "uuid": "dashboard-aktienanalyse",
            "name": "Aktienanalyse Ecosystem Dashboard",
            "pages": [
              {
                "name": "Overview",
                "widgets": [
                  {
                    "type": "GRAPH_CLASSIC",
                    "name": "System Resource Usage",
                    "x": 0,
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
                    "name": "Service Status",
                    "x": 12,
                    "y": 0,
                    "width": 6,
                    "height": 5,
                    "fields": [
                      {
                        "type": "ITEM",
                        "name": "itemids",
                        "value": "service-status-items"
                      }
                    ]
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

### 6.4 Monitoring Setup-Script

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/setup_monitoring.sh
"""Monitoring-Setup für Zabbix-Integration"""

set -euo pipefail

# Konfiguration
ZABBIX_SERVER="10.1.1.103"
ZABBIX_PORT="10051"
HOSTNAME=$(hostname)
PROJECT_ROOT="/opt/aktienanalyse-ökosystem"
ZABBIX_AGENT_CONFIG="/etc/zabbix/zabbix_agentd.conf"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Zabbix Agent installieren
install_zabbix_agent() {
    log "📦 Installiere Zabbix Agent..."
    
    # Zabbix Repository hinzufügen
    if ! dpkg -l | grep -q zabbix-release; then
        wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4+ubuntu$(lsb_release -rs)_all.deb
        sudo dpkg -i zabbix-release_6.0-4+ubuntu$(lsb_release -rs)_all.deb
        sudo apt update
    fi
    
    # Zabbix Agent installieren
    sudo apt install -y zabbix-agent2
    
    log "✅ Zabbix Agent installiert"
}

# Zabbix Agent konfigurieren
configure_zabbix_agent() {
    log "⚙️ Konfiguriere Zabbix Agent..."
    
    # Backup der Original-Konfiguration
    sudo cp "$ZABBIX_AGENT_CONFIG" "${ZABBIX_AGENT_CONFIG}.backup" 2>/dev/null || true
    
    # Neue Konfiguration erstellen
    sudo tee "$ZABBIX_AGENT_CONFIG" > /dev/null <<EOF
# Zabbix Agent Konfiguration für Aktienanalyse-Ökosystem
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$ZABBIX_SERVER
ServerActive=$ZABBIX_SERVER:$ZABBIX_PORT
Hostname=$HOSTNAME
Include=/etc/zabbix/zabbix_agentd.d/*.conf

# Aktienanalyse-spezifische Einstellungen
EnableRemoteCommands=0
LogRemoteCommands=0
UnsafeUserParameters=0
AllowRoot=0

# Performance-Tuning
StartAgents=3
Timeout=30
BufferSend=5
BufferSize=100
MaxLinesPerSecond=20

# Security
TLSConnect=unencrypted
TLSAccept=unencrypted
EOF

    # Aktienanalyse UserParameters
    sudo tee "/etc/zabbix/zabbix_agentd.d/aktienanalyse.conf" > /dev/null <<EOF
# Aktienanalyse Ecosystem UserParameters

# Service Discovery
UserParameter=aktienanalyse.services.discovery,/opt/aktienanalyse-ökosystem/scripts/zabbix_discovery.sh

# System Metrics (Fallback falls Monitoring-Service nicht läuft)
UserParameter=aktienanalyse.system.cpu.fallback,grep 'cpu ' /proc/stat | awk '{usage=(\$2+\$4)*100/(\$2+\$3+\$4+\$5)} END {print usage}'
UserParameter=aktienanalyse.system.memory.fallback,free | grep Mem | awk '{printf "%.2f", \$3/\$2 * 100.0}'
UserParameter=aktienanalyse.system.disk.fallback,df -h / | awk 'NR==2 {print \$5}' | sed 's/%//'

# Service Status
UserParameter=aktienanalyse.service.systemd_status[*],systemctl is-active \$1 | grep -c "^active\$" || echo 0

# Log File Monitoring
UserParameter=aktienanalyse.log.errors[*],grep -c "ERROR" /var/log/aktienanalyse/\$1.log 2>/dev/null || echo 0
UserParameter=aktienanalyse.log.warnings[*],grep -c "WARNING" /var/log/aktienanalyse/\$1.log 2>/dev/null || echo 0
EOF

    # Service Discovery Script erstellen
    sudo tee "/opt/aktienanalyse-ökosystem/scripts/zabbix_discovery.sh" > /dev/null <<'EOF'
#!/bin/bash
# Zabbix Service Discovery für Aktienanalyse Services

services=(
    "aktienanalyse-core"
    "aktienanalyse-broker"
    "aktienanalyse-events"
    "aktienanalyse-monitoring" 
    "aktienanalyse-frontend"
)

echo '{"data":['

first=true
for service in "${services[@]}"; do
    if [ "$first" = false ]; then
        echo ","
    fi
    echo -n "{\"SERVICE.NAME\":\"$service\"}"
    first=false
done

echo ']}'
EOF

    sudo chmod +x "/opt/aktienanalyse-ökosystem/scripts/zabbix_discovery.sh"
    
    log "✅ Zabbix Agent konfiguriert"
}

# Log-Verzeichnis erstellen
setup_log_directory() {
    log "📁 Erstelle Log-Verzeichnis..."
    
    sudo mkdir -p /var/log/aktienanalyse
    sudo chown aktienanalyse:aktienanalyse /var/log/aktienanalyse
    sudo chmod 755 /var/log/aktienanalyse
    
    # Logrotate-Konfiguration
    sudo tee "/etc/logrotate.d/aktienanalyse" > /dev/null <<EOF
/var/log/aktienanalyse/*.log {
    daily
    rotate 30
    compress
    delaycompress
    missingok
    notifempty
    create 644 aktienanalyse aktienanalyse
    postrotate
        # Signal services to reopen log files if needed
        systemctl reload aktienanalyse-monitoring.service 2>/dev/null || true
    endscript
}
EOF

    log "✅ Log-Verzeichnis eingerichtet"
}

# Zabbix Agent starten
start_zabbix_agent() {
    log "🚀 Starte Zabbix Agent..."
    
    sudo systemctl enable zabbix-agent2
    sudo systemctl restart zabbix-agent2
    
    # Status prüfen
    if systemctl is-active --quiet zabbix-agent2; then
        log "✅ Zabbix Agent läuft"
    else
        log "❌ Fehler beim Starten des Zabbix Agent"
        sudo systemctl status zabbix-agent2 --no-pager
        return 1
    fi
}

# Verbindung zu Zabbix Server testen
test_zabbix_connection() {
    log "🔍 Teste Verbindung zu Zabbix Server..."
    
    # Test mit zabbix_sender (falls verfügbar)
    if command -v zabbix_sender >/dev/null 2>&1; then
        echo "test" | zabbix_sender -z "$ZABBIX_SERVER" -p "$ZABBIX_PORT" -s "$HOSTNAME" -k "agent.ping" -o - >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            log "✅ Verbindung zu Zabbix Server erfolgreich"
        else
            log "⚠️ Verbindung zu Zabbix Server fehlgeschlagen (normal bei erstmaliger Einrichtung)"
        fi
    else
        # Einfacher TCP-Test
        if timeout 5 bash -c "echo >/dev/tcp/$ZABBIX_SERVER/$ZABBIX_PORT" 2>/dev/null; then
            log "✅ Zabbix Server erreichbar"
        else
            log "❌ Zabbix Server nicht erreichbar"
            return 1
        fi
    fi
}

# Monitoring Dependencies installieren
install_monitoring_dependencies() {
    log "📦 Installiere Monitoring Dependencies..."
    
    # Python Packages für Monitoring Service
    if [ -f "$PROJECT_ROOT/venv/bin/activate" ]; then
        source "$PROJECT_ROOT/venv/bin/activate"
        pip install aiohttp psutil py-zabbix redis
        log "✅ Python Dependencies installiert"
    else
        log "⚠️ Virtual Environment nicht gefunden"
    fi
}

# Firewall-Konfiguration (falls nötig)
configure_firewall() {
    log "🔥 Prüfe Firewall-Konfiguration..."
    
    if command -v ufw >/dev/null 2>&1 && ufw status | grep -q "Status: active"; then
        log "Konfiguriere UFW für Zabbix Agent..."
        sudo ufw allow from "$ZABBIX_SERVER" to any port 10050 comment "Zabbix Agent"
        log "✅ Firewall konfiguriert"
    else
        log "ℹ️ UFW nicht aktiv oder nicht installiert"
    fi
}

# Hauptfunktion
main() {
    log "🚀 Starte Monitoring-Setup für Aktienanalyse-Ökosystem"
    
    # Prüfe Root-Rechte für einige Operationen
    if [ "$EUID" -ne 0 ]; then
        log "❌ Script muss als root ausgeführt werden"
        exit 1
    fi
    
    # Setup-Schritte
    install_zabbix_agent
    configure_zabbix_agent
    setup_log_directory
    configure_firewall
    install_monitoring_dependencies
    start_zabbix_agent
    test_zabbix_connection
    
    log "🎉 Monitoring-Setup abgeschlossen!"
    log ""
    log "📋 Nächste Schritte:"
    log "1. Host '$HOSTNAME' in Zabbix Server hinzufügen"
    log "2. Template 'Aktienanalyse Ecosystem' zuweisen"
    log "3. Monitoring-Service starten: systemctl start aktienanalyse-monitoring"
    log "4. Status prüfen: systemctl status zabbix-agent2"
}

main "$@"
```

Die Deployment & Infrastructure-Automation Spezifikation ist nun vollständig mit:

1. ✅ **systemd-Services pro Service** - Vollständige Service-Definitionen mit Dependencies
2. ✅ **CLI-basiertes Setup-Programm** - Interaktives Tool mit deutschen Erklärungen 
3. ✅ **Automatische Database-Schema-Migration** - Alembic-basierte Migration mit Management-Tools
4. ✅ **systemd-Dependencies & Service-Orchestration** - Dependency-Matrix und Orchestration-Scripts
5. ✅ **Vollautomatische GitHub Actions CI/CD-Pipeline** - 5-stufige Pipeline mit Testing, Building, Deployment
6. ✅ **Minimale Monitoring-Integration** - systemd + Zabbix mit Python-Service und Templates

Das System ist nun vollständig spezifiziert für native LXC-Deployment ohne Docker mit vollautomatisierter CI/CD-Pipeline und minimaler aber effektiver Monitoring-Integration.

### 4.1 Service-Abhängigkeits-Matrix

```yaml
# Service-Abhängigkeiten-Übersicht
Service Dependencies:
└── aktienanalyse.target
    ├── External Dependencies:
    │   ├── postgresql.service (System-Database)
    │   ├── redis.service (Event-Bus + Cache)
    │   └── network.target (Netzwerk-Verfügbarkeit)
    │
    ├── Migration Dependencies:
    │   └── aktienanalyse-migration.service
    │       ├── After: postgresql.service
    │       └── Before: alle anderen Services
    │
    ├── Core Services (Start-Reihenfolge):
    │   ├── 1. aktienanalyse-events.service
    │   │   ├── After: postgresql.service, redis.service, aktienanalyse-migration.service
    │   │   └── Provides: Event-Bus, Message-Queue
    │   │
    │   ├── 2. aktienanalyse-core.service  
    │   │   ├── After: aktienanalyse-events.service
    │   │   └── Provides: Business-Logic, Portfolio-Management
    │   │
    │   ├── 3. aktienanalyse-broker.service
    │   │   ├── After: aktienanalyse-core.service, aktienanalyse-events.service
    │   │   └── Provides: Trading-API, Broker-Integration
    │   │
    │   ├── 4. aktienanalyse-monitoring.service
    │   │   ├── After: aktienanalyse-core.service, aktienanalyse-events.service
    │   │   └── Provides: Metrics, Health-Checks, Zabbix-Integration
    │   │
    │   └── 5. aktienanalyse-frontend.service
    │       ├── After: alle anderen Services
    │       └── Provides: Web-Interface, API-Gateway
    │
    └── Service-Relationship-Matrix:
        ├── aktienanalyse-events ← ALL (Event-Provider)
        ├── aktienanalyse-core ← broker, monitoring, frontend
        ├── aktienanalyse-broker ← frontend
        ├── aktienanalyse-monitoring ← frontend
        └── aktienanalyse-frontend ← NONE (Top-Level)
```

### 4.2 Erweiterte systemd-Service-Definitionen mit Dependencies

```ini
# /etc/systemd/system/aktienanalyse-migration.service (Updated)
[Unit]
Description=Aktienanalyse Database Migration Service
Documentation=https://docs.aktienanalyse.local/deployment/migration
# External Dependencies
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service
Requires=postgresql.service
# Ensure migration runs before all other services
Before=aktienanalyse-events.service aktienanalyse-core.service aktienanalyse-broker.service aktienanalyse-monitoring.service aktienanalyse-frontend.service
# Part of ecosystem
PartOf=aktienanalyse.target

[Service]
Type=oneshot
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=migration-service
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python scripts/manage_migrations.py init
ExecStartPost=/bin/bash -c 'echo "✅ Database-Migration abgeschlossen" | systemd-cat -t aktienanalyse-migration'
RemainAfterExit=yes
TimeoutStartSec=300
# Restart-Policy für Migrations
Restart=on-failure
RestartSec=10
# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-migration
# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /var/log/aktienanalyse

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-events.service (Updated)
[Unit]
Description=Aktienanalyse Event Bus Service
Documentation=https://docs.aktienanalyse.local/event-bus
# External Dependencies
After=network-online.target postgresql.service redis.service
Wants=network-online.target postgresql.service redis.service  
Requires=postgresql.service redis.service
# Internal Dependencies
After=aktienanalyse-migration.service
Requires=aktienanalyse-migration.service
# Service Relationships
Before=aktienanalyse-core.service aktienanalyse-broker.service aktienanalyse-monitoring.service aktienanalyse-frontend.service
# Part of ecosystem
PartOf=aktienanalyse.target
# Bind to other services (restart cascade)
BindsTo=postgresql.service redis.service

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/event-bus
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=event-bus-service
Environment=SERVICE_ROLE=event-provider
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
# Service Startup
ExecStartPre=/bin/bash -c 'echo "🚀 Starting Event-Bus Service..." | systemd-cat -t aktienanalyse-events'
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecStartPost=/bin/bash -c 'echo "✅ Event-Bus Service gestartet" | systemd-cat -t aktienanalyse-events'
# Service Management
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=30
# Restart-Policy
Restart=always
RestartSec=3
StartLimitBurst=5
StartLimitIntervalSec=30
# Resource Limits
LimitNOFILE=65536
MemoryMax=1G
CPUQuota=200%
TasksMax=512
# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-events
# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /opt/aktienanalyse-ökosystem/data /var/log/aktienanalyse

[Install]
WantedBy=aktienanalyse.target
```

```ini
# /etc/systemd/system/aktienanalyse-core.service (Updated)
[Unit]
Description=Aktienanalyse Intelligent Core Service
Documentation=https://docs.aktienanalyse.local/core-service
# External Dependencies  
After=network-online.target postgresql.service redis.service
Wants=network-online.target postgresql.service redis.service
Requires=postgresql.service redis.service
# Internal Dependencies
After=aktienanalyse-migration.service aktienanalyse-events.service
Requires=aktienanalyse-migration.service aktienanalyse-events.service
# Service Relationships
Before=aktienanalyse-broker.service aktienanalyse-monitoring.service aktienanalyse-frontend.service
# Part of ecosystem
PartOf=aktienanalyse.target
# Bind to critical services
BindsTo=aktienanalyse-events.service

[Service]
Type=exec
User=aktienanalyse
Group=aktienanalyse
WorkingDirectory=/opt/aktienanalyse-ökosystem/services/intelligent-core
Environment=PYTHONPATH=/opt/aktienanalyse-ökosystem
Environment=SERVICE_NAME=intelligent-core-service
Environment=SERVICE_ROLE=business-logic
EnvironmentFile=/opt/aktienanalyse-ökosystem/config/environments/production.env
# Service Startup
ExecStartPre=/bin/bash -c 'echo "🧠 Starting Core Service..." | systemd-cat -t aktienanalyse-core'
ExecStartPre=/opt/aktienanalyse-ökosystem/scripts/health-check.sh wait-for-event-bus
ExecStart=/opt/aktienanalyse-ökosystem/venv/bin/python main.py
ExecStartPost=/bin/bash -c 'echo "✅ Core Service gestartet" | systemd-cat -t aktienanalyse-core'
# Service Management
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
KillMode=mixed
KillSignal=SIGTERM
TimeoutStopSec=45
# Restart-Policy
Restart=always
RestartSec=5
StartLimitBurst=5
StartLimitIntervalSec=60
# Resource Limits
LimitNOFILE=65536
MemoryMax=1G
CPUQuota=200%
TasksMax=256
# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=aktienanalyse-core
# Security
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=strict
ProtectHome=yes
ReadWritePaths=/opt/aktienanalyse-ökosystem/logs /opt/aktienanalyse-ökosystem/data /var/log/aktienanalyse

[Install]
WantedBy=aktienanalyse.target
```

### 4.3 Service-Orchestration-Script

```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/orchestration.sh
"""Erweiterte Service-Orchestration mit Dependency-Management"""

set -euo pipefail

# Konfiguration
SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
LOG_FILE="/var/log/aktienanalyse/orchestration.log"

# Service-Definitionen mit Dependencies
declare -A SERVICE_CONFIG=(
    # Format: "service_name:priority:dependencies:timeout"
    ["aktienanalyse-migration"]="1::postgresql.service:300"
    ["aktienanalyse-events"]="2:aktienanalyse-migration:postgresql.service,redis.service:60" 
    ["aktienanalyse-core"]="3:aktienanalyse-events:postgresql.service,redis.service:60"
    ["aktienanalyse-broker"]="4:aktienanalyse-core,aktienanalyse-events:postgresql.service,redis.service:45"
    ["aktienanalyse-monitoring"]="5:aktienanalyse-core,aktienanalyse-events::30"
    ["aktienanalyse-frontend"]="6:aktienanalyse-core,aktienanalyse-broker,aktienanalyse-monitoring::30"
)

# Logging-Funktion
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $message" | tee -a "$LOG_FILE"
}

# Fehler-Handler
error_exit() {
    log "ERROR" "$1"
    exit 1
}

# Service-Status prüfen
check_service_status() {
    local service="$1"
    systemctl is-active --quiet "$service" 2>/dev/null
}

# Dependencies prüfen
check_dependencies() {
    local service="$1"
    local deps_string="${SERVICE_CONFIG[$service]#*:*:}"
    deps_string="${deps_string%:*}"
    
    if [ -z "$deps_string" ]; then
        return 0
    fi
    
    IFS=',' read -ra DEPS <<< "$deps_string"
    for dep in "${DEPS[@]}"; do
        if ! check_service_status "$dep"; then
            log "WARNING" "Dependency $dep für $service ist nicht aktiv"
            return 1
        fi
    done
    
    return 0
}

# Service warten bis Dependencies erfüllt
wait_for_dependencies() {
    local service="$1"
    local max_wait="${2:-300}"
    local deps_string="${SERVICE_CONFIG[$service]#*:*:}"
    deps_string="${deps_string%:*}"
    
    if [ -z "$deps_string" ]; then
        return 0
    fi
    
    log "INFO" "Warte auf Dependencies für $service..."
    
    local waited=0
    IFS=',' read -ra DEPS <<< "$deps_string"
    
    while [ $waited -lt $max_wait ]; do
        local all_ready=true
        
        for dep in "${DEPS[@]}"; do
            if ! check_service_status "$dep"; then
                all_ready=false
                break
            fi
        done
        
        if [ "$all_ready" = true ]; then
            log "INFO" "Alle Dependencies für $service sind bereit"
            return 0
        fi
        
        sleep 2
        waited=$((waited + 2))
    done
    
    log "ERROR" "Timeout beim Warten auf Dependencies für $service"
    return 1
}

# Service mit Health-Check starten
start_service_with_health_check() {
    local service="$1"
    local timeout="${SERVICE_CONFIG[$service]##*:}"
    
    log "INFO" "Starte $service..."
    
    # Dependencies prüfen
    if ! wait_for_dependencies "$service" 60; then
        error_exit "Dependencies für $service nicht erfüllt"
    fi
    
    # Service starten
    if ! systemctl start "$service"; then
        error_exit "Fehler beim Starten von $service"
    fi
    
    # Health-Check
    log "INFO" "Führe Health-Check für $service durch (Timeout: ${timeout}s)..."
    local waited=0
    
    while [ $waited -lt "$timeout" ]; do
        if check_service_status "$service"; then
            # Zusätzlicher Application-Health-Check
            if health_check_service "$service"; then
                log "INFO" "✅ $service erfolgreich gestartet und gesund"
                return 0
            fi
        fi
        
        sleep 2
        waited=$((waited + 2))
    done
    
    log "ERROR" "❌ Health-Check für $service fehlgeschlagen"
    systemctl status "$service" --no-pager || true
    return 1
}

# Application-spezifischer Health-Check
health_check_service() {
    local service="$1"
    
    case "$service" in
        "aktienanalyse-migration")
            # Migration-Service: Check dass Service erfolgreich beendet
            [ "$(systemctl show -p SubState "$service" --value)" = "exited" ]
            ;;
        "aktienanalyse-events")
            # Event-Bus: Redis-Verbindung testen
            timeout 5 redis-cli -h localhost ping >/dev/null 2>&1
            ;;
        "aktienanalyse-core")
            # Core: HTTP Health-Endpoint
            timeout 5 curl -sf "http://localhost:8001/health" >/dev/null 2>&1
            ;;
        "aktienanalyse-broker")
            # Broker: HTTP Health-Endpoint
            timeout 5 curl -sf "http://localhost:8002/health" >/dev/null 2>&1
            ;;
        "aktienanalyse-monitoring")
            # Monitoring: HTTP Health-Endpoint
            timeout 5 curl -sf "http://localhost:8004/health" >/dev/null 2>&1
            ;;
        "aktienanalyse-frontend")
            # Frontend: HTTPS Health-Endpoint
            timeout 5 curl -sfk "https://localhost:8443/health" >/dev/null 2>&1
            ;;
        *)
            # Default: systemd-Status
            return 0
            ;;
    esac
}

# Orchestrierte Service-Start-Sequenz
start_ecosystem() {
    log "INFO" "🚀 Starte Aktienanalyse-Ökosystem..."
    
    # Services nach Priorität sortieren
    local sorted_services=()
    for service in "${!SERVICE_CONFIG[@]}"; do
        local priority="${SERVICE_CONFIG[$service]%%:*}"
        sorted_services+=("$priority:$service")
    done
    
    IFS=$'\n' sorted_services=($(sort -n <<<"${sorted_services[*]}"))
    
    # Services sequenziell starten
    for item in "${sorted_services[@]}"; do
        local service="${item#*:}"
        
        if check_service_status "$service"; then
            log "INFO" "✅ $service läuft bereits"
            continue
        fi
        
        if ! start_service_with_health_check "$service"; then
            error_exit "Fehler beim Starten von $service"
        fi
    done
    
    log "INFO" "🎉 Aktienanalyse-Ökosystem erfolgreich gestartet!"
    
    # Final Health-Check für gesamtes System
    overall_health_check
}

# Orchestrierter Service-Stop
stop_ecosystem() {
    log "INFO" "🛑 Stoppe Aktienanalyse-Ökosystem..."
    
    # Services in umgekehrter Reihenfolge stoppen
    local sorted_services=()
    for service in "${!SERVICE_CONFIG[@]}"; do
        local priority="${SERVICE_CONFIG[$service]%%:*}"
        sorted_services+=("$priority:$service")
    done
    
    IFS=$'\n' sorted_services=($(sort -rn <<<"${sorted_services[*]}"))
    
    for item in "${sorted_services[@]}"; do
        local service="${item#*:}"
        
        if ! check_service_status "$service"; then
            log "INFO" "⏹️ $service ist bereits gestoppt"
            continue
        fi
        
        log "INFO" "Stoppe $service..."
        systemctl stop "$service" || log "WARNING" "Fehler beim Stoppen von $service"
    done
    
    log "INFO" "✅ Aktienanalyse-Ökosystem gestoppt"
}

# Gesamtsystem Health-Check
overall_health_check() {
    log "INFO" "🏥 Führe Gesamtsystem Health-Check durch..."
    
    local failed_services=()
    
    for service in "${!SERVICE_CONFIG[@]}"; do
        if ! check_service_status "$service"; then
            failed_services+=("$service")
        elif ! health_check_service "$service"; then
            failed_services+=("$service (unhealthy)")
        fi
    done
    
    if [ ${#failed_services[@]} -eq 0 ]; then
        log "INFO" "✅ Alle Services sind gesund und laufen"
        
        # Zusätzliche System-Checks
        log "INFO" "🔍 Führe erweiterte System-Checks durch..."
        
        # PostgreSQL-Check
        if systemctl is-active --quiet postgresql.service; then
            log "INFO" "✅ PostgreSQL läuft"
        else
            log "WARNING" "⚠️ PostgreSQL ist nicht aktiv"
        fi
        
        # Redis-Check
        if timeout 3 redis-cli ping >/dev/null 2>&1; then
            log "INFO" "✅ Redis ist erreichbar"
        else
            log "WARNING" "⚠️ Redis ist nicht erreichbar"
        fi
        
        # Disk-Space-Check
        local disk_usage=$(df /opt/aktienanalyse-ökosystem | awk 'NR==2 {print $5}' | sed 's/%//')
        if [ "$disk_usage" -lt 90 ]; then
            log "INFO" "✅ Disk-Space OK (${disk_usage}% verwendet)"
        else
            log "WARNING" "⚠️ Disk-Space kritisch (${disk_usage}% verwendet)"
        fi
        
        return 0
    else
        log "ERROR" "❌ Fehlerhafte Services: ${failed_services[*]}"
        return 1
    fi
}

# Service-Restart mit Dependency-Berücksichtigung
restart_service_cascade() {
    local target_service="$1"
    
    log "INFO" "🔄 Restart-Cascade für $target_service..."
    
    # Abhängige Services ermitteln
    local dependent_services=()
    for service in "${!SERVICE_CONFIG[@]}"; do
        local deps_string="${SERVICE_CONFIG[$service]#*:}"
        deps_string="${deps_string%%:*}"
        
        if [[ ",$deps_string," == *",$target_service,"* ]]; then
            dependent_services+=("$service")
        fi
    done
    
    # Abhängige Services stoppen (in umgekehrter Prioritäts-Reihenfolge)
    if [ ${#dependent_services[@]} -gt 0 ]; then
        log "INFO" "Stoppe abhängige Services: ${dependent_services[*]}"
        
        local sorted_deps=()
        for service in "${dependent_services[@]}"; do
            local priority="${SERVICE_CONFIG[$service]%%:*}"
            sorted_deps+=("$priority:$service")
        done
        
        IFS=$'\n' sorted_deps=($(sort -rn <<<"${sorted_deps[*]}"))
        
        for item in "${sorted_deps[@]}"; do
            local service="${item#*:}"
            log "INFO" "Stoppe $service..."
            systemctl stop "$service" || true
        done
    fi
    
    # Ziel-Service restarten
    log "INFO" "Restarte $target_service..."
    systemctl restart "$target_service"
    
    if ! start_service_with_health_check "$target_service"; then
        error_exit "Fehler beim Neustarten von $target_service"
    fi
    
    # Abhängige Services wieder starten
    if [ ${#dependent_services[@]} -gt 0 ]; then
        log "INFO" "Starte abhängige Services wieder..."
        
        local sorted_deps=()
        for service in "${dependent_services[@]}"; do
            local priority="${SERVICE_CONFIG[$service]%%:*}"
            sorted_deps+=("$priority:$service")
        done
        
        IFS=$'\n' sorted_deps=($(sort -n <<<"${sorted_deps[*]}"))
        
        for item in "${sorted_deps[@]}"; do
            local service="${item#*:}"
            if ! start_service_with_health_check "$service"; then
                log "ERROR" "Fehler beim Neustarten von abhängigem Service $service"
            fi
        done
    fi
    
    log "INFO" "✅ Restart-Cascade für $target_service abgeschlossen"
}

# Hauptfunktion
main() {
    case "${1:-}" in
        "start")
            start_ecosystem
            ;;
        "stop")
            stop_ecosystem
            ;;
        "restart")
            stop_ecosystem
            sleep 5
            start_ecosystem
            ;;
        "health")
            overall_health_check
            ;;
        "restart-service")
            if [ -z "${2:-}" ]; then
                error_exit "Service-Name erforderlich für restart-service"
            fi
            restart_service_cascade "$2"
            ;;
        "status")
            log "INFO" "📊 Aktienanalyse-Ökosystem Status:"
            for service in "${!SERVICE_CONFIG[@]}"; do
                if check_service_status "$service"; then
                    if health_check_service "$service"; then
                        echo "✅ $service: HEALTHY"
                    else
                        echo "⚠️ $service: RUNNING (UNHEALTHY)"
                    fi
                else
                    echo "❌ $service: STOPPED"
                fi
            done
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|health|restart-service <service>|status}"
            echo ""
            echo "Available services:"
            for service in "${!SERVICE_CONFIG[@]}"; do
                echo "  - $service"
            done
            exit 1
            ;;
    esac
}

# Script ausführen
main "$@"
```