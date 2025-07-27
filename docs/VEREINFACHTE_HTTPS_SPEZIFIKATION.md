# 🔒 Vereinfachte HTTPS-Spezifikation - Native LXC-Services

## 🎯 **Übersicht**

**Kontext**: Private Single-User-Umgebung ohne Docker, native Services auf LXC
**Ziel**: Einfaches HTTPS für Frontend-Service ohne Certificate-Overhead
**Ansatz**: Minimal SSL-Setup mit systemd-Services

---

## 🚫 **WICHTIGE ARCHITEKTUR-REGEL**

**KEIN DOCKER VERWENDEN** - Alle Services laufen nativ auf dem LXC-Container

---

## 🏗️ **1. EINFACHE SSL-KONFIGURATION**

### 1.1 **Minimal SSL-Setup**
```bash
#!/bin/bash
# scripts/setup-simple-ssl.sh

set -euo pipefail

echo "🔒 Setting up simple SSL for LXC-native services..."

# Einfaches Self-signed Certificate für localhost
SSL_DIR="/home/mdoehler/aktienanalyse-ökosystem/ssl"
mkdir -p "$SSL_DIR"

# Simple Self-signed Certificate (gültig für 1 Jahr)
openssl req -x509 -newkey rsa:2048 -keyout "$SSL_DIR/server.key" -out "$SSL_DIR/server.crt" \
    -days 365 -nodes \
    -subj "/C=DE/ST=NRW/L=Local/O=Aktienanalyse/CN=localhost" \
    -addext "subjectAltName=DNS:localhost,DNS:aktienanalyse.local,IP:127.0.0.1,IP:10.1.1.120"

# Permissions setzen
chmod 600 "$SSL_DIR/server.key"
chmod 644 "$SSL_DIR/server.crt"

echo "✅ SSL certificates created:"
echo "  Certificate: $SSL_DIR/server.crt"
echo "  Private Key: $SSL_DIR/server.key"
```

### 1.2 **Frontend-Service mit einfachem HTTPS**
```python
# services/frontend-service/src/app.py
from flask import Flask, request, jsonify
import ssl
import os

app = Flask(__name__)

# SSL-Kontext für HTTPS
def create_ssl_context():
    """Erstellt SSL-Context für HTTPS"""
    ssl_dir = "/home/mdoehler/aktienanalyse-ökosystem/ssl"
    cert_file = os.path.join(ssl_dir, "server.crt")
    key_file = os.path.join(ssl_dir, "server.key")
    
    if os.path.exists(cert_file) and os.path.exists(key_file):
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
        context.load_cert_chain(cert_file, key_file)
        return context
    else:
        print("SSL certificates not found - running HTTP only")
        return None

@app.route('/')
def index():
    return {'message': 'Aktienanalyse-Ökosystem Frontend', 'version': '1.0.0'}

@app.route('/health')
def health():
    return {'status': 'healthy', 'timestamp': datetime.utcnow().isoformat()}

if __name__ == '__main__':
    # SSL-Context erstellen
    ssl_context = create_ssl_context()
    
    if ssl_context:
        print("🔒 Starting HTTPS server on port 443...")
        app.run(host='0.0.0.0', port=443, ssl_context=ssl_context, debug=False)
    else:
        print("⚠️ Starting HTTP server on port 3000...")
        app.run(host='0.0.0.0', port=3000, debug=False)
```

---

## ⚙️ **2. SYSTEMD-SERVICE-KONFIGURATION**

### 2.1 **Native systemd-Services (ohne Docker)**
```ini
# /etc/systemd/system/aktienanalyse-frontend.service
[Unit]
Description=Aktienanalyse Frontend Service
After=network.target
Wants=network.target

[Service]
Type=simple
User=mdoehler
Group=mdoehler
WorkingDirectory=/home/mdoehler/aktienanalyse-ökosystem/services/frontend-service
Environment=NODE_ENV=production
Environment=PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem
Environment=SSL_CERT_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt
Environment=SSL_KEY_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.key
ExecStart=/usr/bin/python3 src/app.py
Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/mdoehler/aktienanalyse-ökosystem
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/aktienanalyse-core.service  
[Unit]
Description=Aktienanalyse Intelligent Core Service
After=network.target redis.service postgresql.service
Wants=network.target
Requires=redis.service postgresql.service

[Service]
Type=simple
User=mdoehler
Group=mdoehler
WorkingDirectory=/home/mdoehler/aktienanalyse-ökosystem/services/intelligent-core-service
Environment=PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem
Environment=REDIS_HOST=localhost
Environment=POSTGRES_HOST=localhost
ExecStart=/usr/bin/python3 src/main.py
Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/mdoehler/aktienanalyse-ökosystem

[Install]
WantedBy=multi-user.target
```

```ini
# /etc/systemd/system/aktienanalyse-broker.service
[Unit]
Description=Aktienanalyse Broker Gateway Service
After=network.target aktienanalyse-core.service
Wants=aktienanalyse-core.service

[Service]
Type=simple
User=mdoehler
Group=mdoehler
WorkingDirectory=/home/mdoehler/aktienanalyse-ökosystem/services/broker-gateway-service
Environment=PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem
ExecStart=/usr/bin/python3 src/main.py
Restart=always
RestartSec=10

# Security
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=false
ReadWritePaths=/home/mdoehler/aktienanalyse-ökosystem

[Install]
WantedBy=multi-user.target
```

### 2.2 **Service-Management-Scripts**
```bash
#!/bin/bash
# scripts/manage-services.sh

set -euo pipefail

SERVICES=(
    "aktienanalyse-frontend"
    "aktienanalyse-core" 
    "aktienanalyse-broker"
    "aktienanalyse-monitoring"
    "aktienanalyse-event-bus"
)

ACTION=${1:-"status"}

case $ACTION in
    "start")
        echo "🚀 Starting all Aktienanalyse services..."
        for service in "${SERVICES[@]}"; do
            echo "Starting $service..."
            sudo systemctl start "$service"
        done
        ;;
    
    "stop")
        echo "🛑 Stopping all Aktienanalyse services..."
        for service in "${SERVICES[@]}"; do
            echo "Stopping $service..."
            sudo systemctl stop "$service"
        done
        ;;
    
    "restart")
        echo "🔄 Restarting all Aktienanalyse services..."
        for service in "${SERVICES[@]}"; do
            echo "Restarting $service..."
            sudo systemctl restart "$service"
        done
        ;;
    
    "status")
        echo "📊 Service status:"
        for service in "${SERVICES[@]}"; do
            status=$(systemctl is-active "$service" 2>/dev/null || echo "inactive")
            echo "  $service: $status"
        done
        ;;
    
    "enable")
        echo "🔧 Enabling all services for autostart..."
        for service in "${SERVICES[@]}"; do
            sudo systemctl enable "$service"
        done
        ;;
    
    "logs")
        service=${2:-"aktienanalyse-frontend"}
        echo "📝 Showing logs for $service..."
        sudo journalctl -f -u "$service"
        ;;
    
    *)
        echo "Usage: $0 {start|stop|restart|status|enable|logs [service]}"
        exit 1
        ;;
esac
```

---

## 🌐 **3. NGINX-REVERSE-PROXY (OHNE DOCKER)**

### 3.1 **Native NGINX-Installation**
```bash
#!/bin/bash
# scripts/setup-nginx.sh

set -euo pipefail

echo "🌐 Setting up native NGINX reverse proxy..."

# NGINX installieren
sudo apt update
sudo apt install -y nginx

# NGINX-Konfiguration für Aktienanalyse
sudo tee /etc/nginx/sites-available/aktienanalyse <<EOF
# HTTP zu HTTPS Redirect
server {
    listen 80;
    server_name localhost 10.1.1.120 aktienanalyse.local;
    return 301 https://\$server_name\$request_uri;
}

# HTTPS-Frontend-Proxy
server {
    listen 443 ssl http2;
    server_name localhost 10.1.1.120 aktienanalyse.local;
    
    # SSL-Konfiguration (einfach)
    ssl_certificate /home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt;
    ssl_certificate_key /home/mdoehler/aktienanalyse-ökosystem/ssl/server.key;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    
    # Frontend-Service Proxy
    location / {
        proxy_pass https://localhost:8443;  # Frontend-Service auf Port 8443
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # SSL-Verification für Backend deaktivieren (Self-signed)
        proxy_ssl_verify off;
    }
    
    # API-Proxy
    location /api/ {
        proxy_pass http://localhost:8001;  # Core-Service HTTP-only
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
    
    # Health-Check
    location /health {
        access_log off;
        return 200 "healthy";
        add_header Content-Type text/plain;
    }
}
EOF

# Site aktivieren
sudo ln -sf /etc/nginx/sites-available/aktienanalyse /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# NGINX-Konfiguration testen
sudo nginx -t

# NGINX starten
sudo systemctl enable nginx
sudo systemctl restart nginx

echo "✅ NGINX reverse proxy configured"
```

### 3.2 **Service-Port-Mapping**
```yaml
# config/service-ports.yaml
services:
  nginx-proxy:
    ports:
      - "80:80"    # HTTP (redirect to HTTPS)
      - "443:443"  # HTTPS (external access)
  
  frontend-service:
    ports:
      - "8443:8443"  # HTTPS (internal, nur für NGINX)
  
  intelligent-core-service:
    ports:
      - "8001:8001"  # HTTP (internal, nur für NGINX)
  
  broker-gateway-service:
    ports:
      - "8002:8002"  # HTTP (internal only)
  
  event-bus-service:
    ports:
      - "8003:8003"  # HTTP (internal only)
  
  monitoring-service:
    ports:
      - "127.0.0.1:8004:8004"  # HTTP (localhost only)

# Nur Frontend extern über NGINX erreichbar
# Alle anderen Services nur intern (localhost/LAN)
```

---

## 🔧 **4. VEREINFACHTE DEPLOYMENT-ARCHITEKTUR**

### 4.1 **Native LXC-Service-Architektur**
```
LXC Container (10.1.1.120)
├── NGINX Reverse Proxy (Port 80/443)
│   └── → Frontend Service (Port 8443, HTTPS)
│   └── → API Gateway (Port 8001, HTTP)
│
├── Native systemd Services:
│   ├── aktienanalyse-frontend.service (Port 8443)
│   ├── aktienanalyse-core.service (Port 8001)
│   ├── aktienanalyse-broker.service (Port 8002)
│   ├── aktienanalyse-event-bus.service (Port 8003)
│   └── aktienanalyse-monitoring.service (Port 8004)
│
├── Database Services:
│   ├── PostgreSQL (Port 5432, localhost only)
│   └── Redis (Port 6379, localhost only)
│
└── SSL Certificates:
    ├── /home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt
    └── /home/mdoehler/aktienanalyse-ökosystem/ssl/server.key
```

### 4.2 **Environment-Konfiguration**
```bash
# .env (ohne Docker-Variablen)
NODE_ENV=production

# Service-Binding (keine Docker-Ports)
FRONTEND_PORT=8443
CORE_SERVICE_PORT=8001
BROKER_SERVICE_PORT=8002
EVENT_BUS_PORT=8003
MONITORING_PORT=8004

# SSL-Konfiguration
SSL_ENABLED=true
SSL_CERT_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt
SSL_KEY_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.key

# Database-Connection (localhost)
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=aktienanalyse_event_store
POSTGRES_USER=mdoehler
POSTGRES_PASSWORD=secure_password

# Redis-Connection (localhost)
REDIS_HOST=localhost
REDIS_PORT=6379

# API-Keys (verschlüsselt)
MASTER_PASSWORD=your_master_password_here
API_KEY_DB_PATH=/home/mdoehler/aktienanalyse-ökosystem/data/secure/api_keys.db

# Zabbix-Integration
ZABBIX_SERVER=10.1.1.103
ZABBIX_HOSTNAME=aktienanalyse-lxc-120
```

### 4.3 **Setup-Script für native Services**
```bash
#!/bin/bash
# scripts/setup-native-deployment.sh

set -euo pipefail

echo "🚀 Setting up native LXC deployment (NO DOCKER)..."

# 1. SSL-Certificates erstellen
./scripts/setup-simple-ssl.sh

# 2. Python-Dependencies installieren
cd /home/mdoehler/aktienanalyse-ökosystem
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt

# 3. Database-Setup
sudo -u postgres createdb aktienanalyse_event_store
sudo -u postgres psql -d aktienanalyse_event_store -f shared/database/event-store-schema.sql

# 4. systemd-Services installieren
sudo cp config/systemd/*.service /etc/systemd/system/
sudo systemctl daemon-reload

# 5. NGINX-Setup
./scripts/setup-nginx.sh

# 6. Services aktivieren
./scripts/manage-services.sh enable

# 7. Services starten
./scripts/manage-services.sh start

# 8. Status prüfen
sleep 5
./scripts/manage-services.sh status

echo "✅ Native LXC deployment completed!"
echo ""
echo "🌐 Access points:"
echo "  - HTTPS Frontend: https://10.1.1.120"
echo "  - HTTPS Frontend: https://localhost"
echo "  - API: https://10.1.1.120/api/"
echo ""
echo "🛠️ Management:"
echo "  - Service status: ./scripts/manage-services.sh status"
echo "  - Service logs: ./scripts/manage-services.sh logs [service]"
echo "  - Restart all: ./scripts/manage-services.sh restart"
```

---

## 📊 **5. MONITORING OHNE DOCKER**

### 5.1 **Native Service-Monitoring**
```python
# shared/monitoring/native_service_monitor.py
import subprocess
import json
from typing import Dict, List

class NativeServiceMonitor:
    def __init__(self):
        self.services = [
            "aktienanalyse-frontend",
            "aktienanalyse-core",
            "aktienanalyse-broker",
            "aktienanalyse-event-bus",
            "aktienanalyse-monitoring"
        ]
    
    def check_service_status(self, service_name: str) -> dict:
        """Prüft systemd-Service-Status"""
        try:
            # systemctl status
            result = subprocess.run(
                ["systemctl", "is-active", service_name],
                capture_output=True, text=True
            )
            
            is_active = result.stdout.strip() == "active"
            
            # Memory-Usage
            if is_active:
                memory_result = subprocess.run(
                    ["systemctl", "show", service_name, "--property=MemoryCurrent"],
                    capture_output=True, text=True
                )
                memory_line = memory_result.stdout.strip()
                memory_bytes = int(memory_line.split("=")[1]) if "=" in memory_line else 0
                memory_mb = memory_bytes / 1024 / 1024
            else:
                memory_mb = 0
            
            return {
                "service": service_name,
                "active": is_active,
                "status": result.stdout.strip(),
                "memory_mb": memory_mb
            }
            
        except Exception as e:
            return {
                "service": service_name,
                "active": False,
                "status": "error",
                "error": str(e),
                "memory_mb": 0
            }
    
    def check_all_services(self) -> List[dict]:
        """Prüft alle Services"""
        results = []
        for service in self.services:
            status = self.check_service_status(service)
            results.append(status)
        return results
    
    def check_port_binding(self, port: int) -> bool:
        """Prüft ob Port belegt ist"""
        try:
            result = subprocess.run(
                ["netstat", "-tlnp"],
                capture_output=True, text=True
            )
            return f":{port} " in result.stdout
        except:
            return False
    
    def get_system_metrics(self) -> dict:
        """System-Metrics für Zabbix"""
        service_statuses = self.check_all_services()
        
        metrics = {}
        for status in service_statuses:
            service_name = status["service"].replace("-", "_")
            metrics[f"service_active_{service_name}"] = 1 if status["active"] else 0
            metrics[f"service_memory_{service_name}"] = status["memory_mb"]
        
        # Port-Checks
        ports = [80, 443, 8001, 8002, 8003, 8004, 8443]
        for port in ports:
            metrics[f"port_listening_{port}"] = 1 if self.check_port_binding(port) else 0
        
        return metrics

# Zabbix-Script für native Services
def write_zabbix_metrics():
    """Schreibt Metrics für Zabbix"""
    monitor = NativeServiceMonitor()
    metrics = monitor.get_system_metrics()
    
    # In Redis schreiben (für Zabbix-Abfrage)
    import redis
    redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
    
    metrics_key = "zabbix:native_services"
    for metric_name, value in metrics.items():
        redis_client.hset(metrics_key, metric_name, value)
    
    redis_client.expire(metrics_key, 300)  # 5 Minuten TTL
    
    print(f"✅ Updated {len(metrics)} native service metrics for Zabbix")

if __name__ == "__main__":
    write_zabbix_metrics()
```

### 5.2 **Zabbix-Integration für native Services**
```bash
#!/bin/bash
# /etc/zabbix/scripts/native_service_metrics.sh

METRIC_NAME=$1

case $METRIC_NAME in
    "service_active_"*)
        redis-cli -h localhost HGET zabbix:native_services $METRIC_NAME || echo 0
        ;;
    "service_memory_"*)
        redis-cli -h localhost HGET zabbix:native_services $METRIC_NAME || echo 0
        ;;
    "port_listening_"*)
        redis-cli -h localhost HGET zabbix:native_services $METRIC_NAME || echo 0
        ;;
    *)
        echo "Usage: $0 {service_active_*|service_memory_*|port_listening_*}"
        exit 1
        ;;
esac
```

```conf
# /etc/zabbix/zabbix_agent2.d/native_services.conf
UserParameter=aktienanalyse.service.active[*],/etc/zabbix/scripts/native_service_metrics.sh service_active_$1
UserParameter=aktienanalyse.service.memory[*],/etc/zabbix/scripts/native_service_metrics.sh service_memory_$1
UserParameter=aktienanalyse.port.listening[*],/etc/zabbix/scripts/native_service_metrics.sh port_listening_$1
```

---

## ✅ **6. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Native Service-Setup (1-2 Tage)**
- [ ] SSL-Certificate-Generierung (einfach, ohne CA)
- [ ] systemd-Service-Definitionen erstellen
- [ ] Python-Services für native Ausführung anpassen
- [ ] Service-Management-Scripts entwickeln

### **Phase 2: NGINX-Reverse-Proxy (1 Tag)**
- [ ] Native NGINX-Installation und -Konfiguration
- [ ] HTTPS-Proxy für Frontend-Service
- [ ] HTTP-API-Proxy für Backend-Services
- [ ] Service-Port-Mapping definieren

### **Phase 3: Monitoring-Integration (1 Tag)**
- [ ] Native Service-Monitoring entwickeln
- [ ] Zabbix-Integration für systemd-Services
- [ ] Health-Check-Endpoints implementieren
- [ ] System-Metrics-Collection

### **Phase 4: Deployment-Automation (1 Tag)**
- [ ] Setup-Scripts für native Deployment
- [ ] Environment-Konfiguration anpassen
- [ ] Service-Dependencies und -Reihenfolge definieren
- [ ] Testing und Dokumentation

**Gesamtaufwand**: 4-5 Tage
**Abhängigkeiten**: PostgreSQL, Redis, NGINX (alle nativ installiert)

Diese **vereinfachte Spezifikation** eliminiert Docker-Komplexität und fokussiert auf **native LXC-Services** mit einfachem HTTPS-Setup für die private Umgebung.