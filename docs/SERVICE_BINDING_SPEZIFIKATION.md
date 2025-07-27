# 🔒 Service-Binding-Spezifikation - Localhost-Only Security

## 🎯 **Übersicht**

**Kontext**: Native LXC-Services mit sicherer Port-Bindung für private Umgebung
**Ziel**: Nur Frontend extern erreichbar, alle anderen Services localhost-only
**Ansatz**: Granulare Port-Bindung ohne zusätzliche Firewall-Funktionen

---

## 🏗️ **1. SERVICE-PORT-ARCHITEKTUR**

### 1.1 **Port-Binding-Matrix**
```yaml
# config/service-bindings.yaml

external_access:
  # Extern über NGINX erreichbar
  nginx_proxy:
    http_port: "0.0.0.0:80"     # HTTP Redirect zu HTTPS
    https_port: "0.0.0.0:443"   # HTTPS Frontend-Zugriff
    description: "Public HTTPS access via NGINX reverse proxy"

internal_services:
  # Frontend-Service (nur für NGINX)
  frontend_service:
    bind_address: "127.0.0.1:8443"
    protocol: "HTTPS"
    access: "nginx_only"
    description: "Frontend-Service für NGINX-Proxy"
  
  # API-Services (localhost-only)
  intelligent_core_service:
    bind_address: "127.0.0.1:8001"
    protocol: "HTTP"
    access: "localhost_only"
    description: "Core-API für interne Service-Kommunikation"
  
  broker_gateway_service:
    bind_address: "127.0.0.1:8002" 
    protocol: "HTTP"
    access: "localhost_only"
    description: "Broker-Gateway für Trading-Operationen"
  
  event_bus_service:
    bind_address: "127.0.0.1:8003"
    protocol: "HTTP"
    access: "localhost_only"
    description: "Event-Bus für Service-Kommunikation"
  
  monitoring_service:
    bind_address: "127.0.0.1:8004"
    protocol: "HTTP"
    access: "localhost_only"
    description: "Monitoring-Dashboard (internal only)"

database_services:
  # Database-Services (localhost-only)
  postgresql:
    bind_address: "127.0.0.1:5432"
    protocol: "TCP"
    access: "localhost_only"
    description: "PostgreSQL Event-Store"
  
  redis:
    bind_address: "127.0.0.1:6379"
    protocol: "TCP"
    access: "localhost_only"
    description: "Redis Event-Bus und Cache"

# Zabbix-Integration
monitoring_integration:
  zabbix_agent:
    bind_address: "0.0.0.0:10050"
    protocol: "TCP"
    access: "zabbix_server_only"
    allowed_hosts: ["10.1.1.103"]
    description: "Zabbix-Agent für Remote-Monitoring"
```

### 1.2 **Service-Binding-Implementation**
```python
# shared/network/service_binding.py
import socket
import ipaddress
from typing import Tuple, List, Optional
from enum import Enum

class BindingType(Enum):
    LOCALHOST_ONLY = "localhost_only"
    LAN_ACCESS = "lan_access" 
    EXTERNAL_ACCESS = "external_access"
    NGINX_ONLY = "nginx_only"
    ZABBIX_ONLY = "zabbix_only"

class ServiceBinding:
    def __init__(self, service_name: str, port: int, binding_type: BindingType):
        self.service_name = service_name
        self.port = port
        self.binding_type = binding_type
        self.allowed_hosts = []
        
    def get_bind_address(self) -> str:
        """Gibt Bind-Adresse basierend auf Binding-Type zurück"""
        
        if self.binding_type == BindingType.LOCALHOST_ONLY:
            return "127.0.0.1"
        elif self.binding_type == BindingType.NGINX_ONLY:
            return "127.0.0.1"  # Nur localhost für NGINX-Proxy
        elif self.binding_type == BindingType.LAN_ACCESS:
            return "10.1.1.120"  # LXC-IP-Adresse
        elif self.binding_type == BindingType.EXTERNAL_ACCESS:
            return "0.0.0.0"     # Alle Interfaces
        elif self.binding_type == BindingType.ZABBIX_ONLY:
            return "0.0.0.0"     # Für Zabbix-Server-Zugriff
        else:
            return "127.0.0.1"   # Default: localhost-only
    
    def get_full_bind_address(self) -> str:
        """Gibt vollständige Bind-Adresse mit Port zurück"""
        return f"{self.get_bind_address()}:{self.port}"
    
    def is_access_allowed(self, client_ip: str) -> bool:
        """Prüft ob Client-IP Zugriff erlaubt ist"""
        
        if self.binding_type == BindingType.LOCALHOST_ONLY:
            return client_ip in ["127.0.0.1", "::1", "localhost"]
        
        elif self.binding_type == BindingType.NGINX_ONLY:
            # Nur localhost (NGINX läuft lokal)
            return client_ip in ["127.0.0.1", "::1"]
        
        elif self.binding_type == BindingType.ZABBIX_ONLY:
            # Nur Zabbix-Server
            return client_ip == "10.1.1.103"
        
        elif self.binding_type == BindingType.LAN_ACCESS:
            # LAN-Netzwerk 10.1.1.0/24
            try:
                client_network = ipaddress.ip_address(client_ip)
                lan_network = ipaddress.ip_network("10.1.1.0/24")
                return client_network in lan_network
            except:
                return False
        
        elif self.binding_type == BindingType.EXTERNAL_ACCESS:
            # Alle IPs erlaubt
            return True
        
        return False

# Service-Binding-Konfiguration
SERVICE_BINDINGS = {
    "frontend": ServiceBinding("aktienanalyse-frontend", 8443, BindingType.NGINX_ONLY),
    "core": ServiceBinding("aktienanalyse-core", 8001, BindingType.LOCALHOST_ONLY),
    "broker": ServiceBinding("aktienanalyse-broker", 8002, BindingType.LOCALHOST_ONLY),
    "event_bus": ServiceBinding("aktienanalyse-event-bus", 8003, BindingType.LOCALHOST_ONLY),
    "monitoring": ServiceBinding("aktienanalyse-monitoring", 8004, BindingType.LOCALHOST_ONLY),
    "nginx": ServiceBinding("nginx", 443, BindingType.EXTERNAL_ACCESS),
    "zabbix_agent": ServiceBinding("zabbix-agent", 10050, BindingType.ZABBIX_ONLY)
}

class NetworkSecurityManager:
    def __init__(self):
        self.bindings = SERVICE_BINDINGS
    
    def get_service_binding(self, service_name: str) -> Optional[ServiceBinding]:
        """Gibt Service-Binding für Service zurück"""
        return self.bindings.get(service_name)
    
    def validate_service_binding(self, service_name: str, client_ip: str) -> bool:
        """Validiert Service-Zugriff für Client-IP"""
        binding = self.get_service_binding(service_name)
        if not binding:
            return False
        
        return binding.is_access_allowed(client_ip)
    
    def get_all_bindings(self) -> dict:
        """Gibt alle Service-Bindings zurück"""
        return {
            name: {
                "bind_address": binding.get_full_bind_address(),
                "binding_type": binding.binding_type.value,
                "service_name": binding.service_name
            }
            for name, binding in self.bindings.items()
        }
```

---

## ⚙️ **2. FLASK/FASTAPI-SERVICE-KONFIGURATION**

### 2.1 **Flask-Service mit sicherer Bindung**
```python
# services/intelligent-core-service/src/app.py
from flask import Flask, request, jsonify, abort
from shared.network.service_binding import NetworkSecurityManager, SERVICE_BINDINGS
import os

app = Flask(__name__)
security_manager = NetworkSecurityManager()

# Service-Binding laden
SERVICE_NAME = "core"
binding = SERVICE_BINDINGS[SERVICE_NAME]

@app.before_request
def validate_client_access():
    """Validiert Client-Zugriff vor jedem Request"""
    
    # Client-IP ermitteln
    client_ip = request.environ.get('HTTP_X_FORWARDED_FOR', 
                                  request.environ.get('HTTP_X_REAL_IP',
                                  request.remote_addr))
    
    # Bei NGINX-Proxy: X-Forwarded-For Header verwenden
    if 'X-Forwarded-For' in request.headers:
        # Letzter Eintrag ist der ursprüngliche Client
        forwarded_ips = request.headers['X-Forwarded-For'].split(',')
        client_ip = forwarded_ips[0].strip()
    
    # Access-Validation
    if not security_manager.validate_service_binding(SERVICE_NAME, client_ip):
        app.logger.warning(f"Access denied for {client_ip} to service {SERVICE_NAME}")
        abort(403, description="Access denied - invalid client IP")

@app.route('/health')
def health():
    return {'status': 'healthy', 'service': 'intelligent-core-service'}

@app.route('/api/portfolio')
def get_portfolio():
    # Business-Logic hier
    return {'portfolio': 'data'}

@app.route('/internal/metrics')
def internal_metrics():
    """Interne Metrics nur für localhost"""
    client_ip = request.remote_addr
    
    if client_ip not in ['127.0.0.1', '::1']:
        abort(403, description="Internal endpoint - localhost only")
    
    return {'metrics': 'internal_data'}

if __name__ == '__main__':
    # Sichere Service-Bindung
    bind_address = binding.get_bind_address()
    port = binding.port
    
    print(f"🔒 Starting {SERVICE_NAME} service on {bind_address}:{port}")
    print(f"🔐 Binding type: {binding.binding_type.value}")
    
    app.run(
        host=bind_address,
        port=port,
        debug=False,
        threaded=True
    )
```

### 2.2 **Frontend-Service mit NGINX-Only-Bindung**
```python
# services/frontend-service/src/app.py
from flask import Flask, request, jsonify
from shared.network.service_binding import SERVICE_BINDINGS
import ssl
import os

app = Flask(__name__)

# Frontend-Service-Binding (nur für NGINX)
SERVICE_NAME = "frontend"
binding = SERVICE_BINDINGS[SERVICE_NAME]

@app.before_request
def nginx_only_access():
    """Nur NGINX-Proxy-Zugriffe erlauben"""
    
    client_ip = request.remote_addr
    
    # Nur localhost-Zugriffe erlauben (NGINX läuft lokal)
    if client_ip not in ['127.0.0.1', '::1']:
        app.logger.warning(f"Non-NGINX access attempt from {client_ip}")
        return jsonify({'error': 'Direct access not allowed'}), 403

@app.route('/')
def index():
    return app.send_static_file('index.html')

@app.route('/api/proxy/<path:endpoint>')
def api_proxy(endpoint):
    """Proxy für Backend-APIs"""
    import requests
    
    # Interne API-Calls zu localhost-Services
    backend_url = f"http://127.0.0.1:8001/api/{endpoint}"
    
    try:
        response = requests.get(backend_url, timeout=30)
        return jsonify(response.json())
    except Exception as e:
        return jsonify({'error': 'Backend service unavailable'}), 503

if __name__ == '__main__':
    # SSL-Context für HTTPS
    ssl_context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    ssl_context.load_cert_chain(
        '/home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt',
        '/home/mdoehler/aktienanalyse-ökosystem/ssl/server.key'
    )
    
    bind_address = binding.get_bind_address()
    port = binding.port
    
    print(f"🔒 Starting frontend service on {bind_address}:{port} (HTTPS)")
    print(f"🔐 NGINX-only access mode")
    
    app.run(
        host=bind_address,
        port=port,
        ssl_context=ssl_context,
        debug=False,
        threaded=True
    )
```

### 2.3 **systemd-Service-Konfiguration mit sicherer Bindung**
```ini
# /etc/systemd/system/aktienanalyse-core.service
[Unit]
Description=Aktienanalyse Intelligent Core Service (Localhost-Only)
After=network.target redis.service postgresql.service
Wants=network.target
Requires=redis.service postgresql.service

[Service]
Type=simple
User=mdoehler
Group=mdoehler
WorkingDirectory=/home/mdoehler/aktienanalyse-ökosystem/services/intelligent-core-service

# Environment
Environment=PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem
Environment=SERVICE_BINDING_TYPE=localhost_only
Environment=BIND_ADDRESS=127.0.0.1
Environment=SERVICE_PORT=8001

# Service-Start
ExecStart=/usr/bin/python3 src/app.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
RestartSec=10

# Security (zusätzliche Härtung)
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/mdoehler/aktienanalyse-ökosystem
PrivateTmp=true
PrivateDevices=true
ProtectKernelTunables=true
ProtectControlGroups=true

# Network-Security
IPAddressDeny=any
IPAddressAllow=localhost
IPAddressAllow=127.0.0.1/8
IPAddressAllow=::1/128

[Install]
WantedBy=multi-user.target
```

---

## 🌐 **3. NGINX-KONFIGURATION FÜR SICHERE PROXYING**

### 3.1 **NGINX-Reverse-Proxy mit localhost-Backend**
```nginx
# /etc/nginx/sites-available/aktienanalyse-secure
server {
    listen 80;
    server_name localhost 10.1.1.120 aktienanalyse.local;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name localhost 10.1.1.120 aktienanalyse.local;
    
    # SSL-Konfiguration
    ssl_certificate /home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt;
    ssl_certificate_key /home/mdoehler/aktienanalyse-ökosystem/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    # Security-Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    
    # Frontend-Service (localhost-only Backend)
    location / {
        # Nur localhost-Backend erlauben
        proxy_pass https://127.0.0.1:8443;
        
        # Sichere Proxy-Headers
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Backend-SSL-Verification deaktivieren (Self-signed)
        proxy_ssl_verify off;
        proxy_ssl_session_reuse on;
        
        # Timeouts
        proxy_connect_timeout 5s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }
    
    # API-Gateway (localhost-only)
    location /api/ {
        # Direkter Zugriff auf Core-Service
        proxy_pass http://127.0.0.1:8001;
        
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # API-spezifische Security
        proxy_set_header X-API-Gateway "nginx-proxy";
        
        # Nur GET/POST/PUT/DELETE erlauben
        limit_except GET POST PUT DELETE {
            deny all;
        }
    }
    
    # Monitoring-Interface (zusätzliche Sicherheit)
    location /monitoring {
        # Nur LAN-Zugriffe
        allow 10.1.1.0/24;
        allow 127.0.0.1;
        deny all;
        
        proxy_pass http://127.0.0.1:8004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Interne Service-Endpoints blockieren
    location ~ ^/(internal|admin|debug)/ {
        # Komplett blockieren
        deny all;
        return 404;
    }
    
    # Health-Check (ohne Logging)
    location /health {
        access_log off;
        return 200 "healthy";
        add_header Content-Type text/plain;
    }
}

# Monitoring für Zabbix-Server (separater Server-Block)
server {
    listen 8080;
    server_name 10.1.1.120;
    
    # Nur Zabbix-Server-Zugriff
    allow 10.1.1.103;
    deny all;
    
    location /nginx-status {
        stub_status on;
        access_log off;
    }
    
    location /health-detailed {
        proxy_pass http://127.0.0.1:8004/health;
    }
}
```

### 3.2 **NGINX-Security-Konfiguration**
```nginx
# /etc/nginx/conf.d/security.conf

# Rate-Limiting für API-Endpoints
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=auth:10m rate=1r/s;

# Connection-Limiting
limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:10m;

server {
    # Rate-Limits anwenden
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        limit_conn conn_limit_per_ip 10;
    }
    
    location /auth/ {
        limit_req zone=auth burst=5 nodelay;
        limit_conn conn_limit_per_ip 5;
    }
    
    # Request-Size-Limits
    client_max_body_size 10M;
    client_body_timeout 60s;
    client_header_timeout 60s;
    
    # Hide NGINX-Version
    server_tokens off;
    
    # Disable unneeded HTTP methods
    if ($request_method !~ ^(GET|HEAD|POST|PUT|DELETE)$ ) {
        return 405;
    }
}
```

---

## 🔍 **4. SERVICE-BINDING-MONITORING**

### 4.1 **Port-Binding-Validator**
```python
# shared/monitoring/port_binding_monitor.py
import socket
import subprocess
from typing import Dict, List, Tuple
import json

class PortBindingMonitor:
    def __init__(self):
        self.expected_bindings = {
            443: ("0.0.0.0", "nginx"),
            8443: ("127.0.0.1", "frontend-service"),
            8001: ("127.0.0.1", "core-service"),
            8002: ("127.0.0.1", "broker-service"),
            8003: ("127.0.0.1", "event-bus-service"),
            8004: ("127.0.0.1", "monitoring-service"),
            5432: ("127.0.0.1", "postgresql"),
            6379: ("127.0.0.1", "redis"),
            10050: ("0.0.0.0", "zabbix-agent")
        }
    
    def get_actual_bindings(self) -> Dict[int, Tuple[str, str]]:
        """Ermittelt tatsächliche Port-Bindings"""
        actual_bindings = {}
        
        try:
            # netstat-Ausgabe parsen
            result = subprocess.run(
                ["netstat", "-tlnp"],
                capture_output=True, text=True
            )
            
            for line in result.stdout.split('\n'):
                if 'LISTEN' in line:
                    parts = line.split()
                    if len(parts) >= 4:
                        address_port = parts[3]
                        process_info = parts[6] if len(parts) > 6 else "unknown"
                        
                        # Port extrahieren
                        if ':' in address_port:
                            address, port_str = address_port.rsplit(':', 1)
                            try:
                                port = int(port_str)
                                # IPv6-Adressen bereinigen
                                if address.startswith('::'):
                                    address = '0.0.0.0'
                                elif address == '::1':
                                    address = '127.0.0.1'
                                
                                actual_bindings[port] = (address, process_info)
                            except ValueError:
                                continue
                                
        except Exception as e:
            print(f"Error getting port bindings: {e}")
        
        return actual_bindings
    
    def validate_bindings(self) -> Dict[str, any]:
        """Validiert alle Service-Bindings"""
        actual = self.get_actual_bindings()
        validation_results = {
            "timestamp": datetime.utcnow().isoformat(),
            "valid_bindings": [],
            "invalid_bindings": [],
            "missing_bindings": [],
            "unexpected_bindings": []
        }
        
        # Erwartete Bindings prüfen
        for port, (expected_address, service_name) in self.expected_bindings.items():
            if port in actual:
                actual_address, actual_process = actual[port]
                
                if actual_address == expected_address:
                    validation_results["valid_bindings"].append({
                        "port": port,
                        "address": actual_address,
                        "service": service_name,
                        "process": actual_process
                    })
                else:
                    validation_results["invalid_bindings"].append({
                        "port": port,
                        "expected_address": expected_address,
                        "actual_address": actual_address,
                        "service": service_name,
                        "security_risk": actual_address == "0.0.0.0" and expected_address == "127.0.0.1"
                    })
            else:
                validation_results["missing_bindings"].append({
                    "port": port,
                    "expected_address": expected_address,
                    "service": service_name
                })
        
        # Unerwartete Bindings finden
        for port, (address, process) in actual.items():
            if port not in self.expected_bindings:
                validation_results["unexpected_bindings"].append({
                    "port": port,
                    "address": address,
                    "process": process
                })
        
        return validation_results
    
    def get_security_score(self) -> int:
        """Berechnet Security-Score basierend auf Bindings (0-100)"""
        validation = self.validate_bindings()
        
        total_expected = len(self.expected_bindings)
        valid_count = len(validation["valid_bindings"])
        invalid_count = len(validation["invalid_bindings"])
        
        # Basis-Score
        score = (valid_count / total_expected) * 100
        
        # Abzüge für Security-Risiken
        for invalid in validation["invalid_bindings"]:
            if invalid.get("security_risk", False):
                score -= 20  # Großer Abzug für externe Exposition
            else:
                score -= 10  # Kleinerer Abzug für andere Probleme
        
        # Abzüge für unerwartete externe Bindings
        for unexpected in validation["unexpected_bindings"]:
            if unexpected["address"] == "0.0.0.0":
                score -= 15
        
        return max(0, min(100, int(score)))

# Zabbix-Integration
def write_binding_metrics():
    """Schreibt Port-Binding-Metrics für Zabbix"""
    monitor = PortBindingMonitor()
    validation = monitor.validate_bindings()
    security_score = monitor.get_security_score()
    
    import redis
    redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
    
    # Metrics für Zabbix
    metrics = {
        "port_bindings_valid": len(validation["valid_bindings"]),
        "port_bindings_invalid": len(validation["invalid_bindings"]),
        "port_bindings_missing": len(validation["missing_bindings"]),
        "port_bindings_unexpected": len(validation["unexpected_bindings"]),
        "port_binding_security_score": security_score
    }
    
    # Spezifische Service-Bindings
    for port, (expected_address, service) in monitor.expected_bindings.items():
        service_name = service.replace("-", "_")
        is_bound_correctly = any(
            binding["port"] == port 
            for binding in validation["valid_bindings"]
        )
        metrics[f"service_binding_correct_{service_name}"] = 1 if is_bound_correctly else 0
    
    # In Redis schreiben
    metrics_key = "zabbix:port_bindings"
    for metric_name, value in metrics.items():
        redis_client.hset(metrics_key, metric_name, value)
    
    redis_client.expire(metrics_key, 300)
    
    print(f"✅ Updated {len(metrics)} port binding metrics (Score: {security_score}/100)")

if __name__ == "__main__":
    write_binding_metrics()
```

### 4.2 **Zabbix-Integration für Service-Binding**
```bash
#!/bin/bash
# /etc/zabbix/scripts/port_binding_metrics.sh

METRIC_NAME=$1

case $METRIC_NAME in
    "port_bindings_"*)
        redis-cli -h localhost HGET zabbix:port_bindings $METRIC_NAME || echo 0
        ;;
    "service_binding_correct_"*)
        redis-cli -h localhost HGET zabbix:port_bindings $METRIC_NAME || echo 0
        ;;
    "port_binding_security_score")
        redis-cli -h localhost HGET zabbix:port_bindings $METRIC_NAME || echo 0
        ;;
    *)
        echo "Usage: $0 {port_bindings_*|service_binding_correct_*|port_binding_security_score}"
        exit 1
        ;;
esac
```

```conf
# /etc/zabbix/zabbix_agent2.d/port_bindings.conf
UserParameter=aktienanalyse.port.bindings[*],/etc/zabbix/scripts/port_binding_metrics.sh $1
UserParameter=aktienanalyse.service.binding[*],/etc/zabbix/scripts/port_binding_metrics.sh service_binding_correct_$1
UserParameter=aktienanalyse.binding.security.score,/etc/zabbix/scripts/port_binding_metrics.sh port_binding_security_score
```

---

## ✅ **5. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Service-Binding-Framework (1 Tag)**
- [ ] Service-Binding-Klassen und -Konfiguration implementieren
- [ ] NetworkSecurityManager für Access-Validation entwickeln
- [ ] Service-spezifische Binding-Konfigurationen definieren

### **Phase 2: Flask/FastAPI-Integration (1 Tag)**
- [ ] Flask-Services mit sicherer Bindung aktualisieren
- [ ] Access-Validation-Middleware implementieren
- [ ] systemd-Service-Konfigurationen mit IP-Restrictions

### **Phase 3: NGINX-Security-Konfiguration (1 Tag)**
- [ ] NGINX-Reverse-Proxy für localhost-Backend konfigurieren
- [ ] Rate-Limiting und Security-Headers implementieren
- [ ] Monitoring-Interface mit LAN-Restriction

### **Phase 4: Binding-Monitoring (1 Tag)**
- [ ] Port-Binding-Monitor entwickeln
- [ ] Security-Score-Berechnung implementieren
- [ ] Zabbix-Integration für Binding-Validation
- [ ] Automated Binding-Checks einrichten

**Gesamtaufwand**: 4 Tage
**Abhängigkeiten**: NGINX, Native Services, Zabbix-Agent

Diese Spezifikation bietet **granulare Service-Binding-Security** ohne zusätzliche Firewall-Komplexität für die private LXC-Umgebung.