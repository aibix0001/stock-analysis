# 🔒 Security-Framework - Private Single-User-Umgebung

## 🎯 **Vereinfachte Security-Anforderungen**

**Kontext**: Privates Projekt auf dediziertem LXC Container, Single-User (mdoehler), keine externen Zugriffe

### ✅ **NICHT ERFORDERLICH** (Enterprise-Features entfernt):
- ❌ Multi-User-Authentication & RBAC
- ❌ GDPR-Compliance (private Nutzung)
- ❌ Enterprise SIEM/IDS-Systeme
- ❌ Penetration-Testing & Red-Team-Exercises
- ❌ OAuth2/OpenID Connect-Integration
- ❌ Multi-Factor-Authentication
- ❌ Complex Audit-Trail-Systems
- ❌ Regulatory Compliance (MiFID II, etc.)
- ❌ Network-Segmentation für Multi-Tenant
- ❌ 24/7 Incident-Response-Team
- ❌ **Rate-Limiting** (nicht benötigt in privater Umgebung)
- ❌ **Additional Firewall-Functions** (LXC-Level-Security ausreichend)
- ❌ **Separate Monitoring-Stack** (Zabbix-Integration stattdessen)

### ✅ **ERFORDERLICH** (Minimale Security-Baseline):

---

## 🔐 **1. BASIC AUTHENTICATION (Vereinfacht)**

### 1.1 **Local User Authentication**
**Implementierungsaufwand**: ⚡ Niedrig (1-2 Tage)

- [ ] **Simple Session-Based Auth**
  ```python
  # Einfacher Login mit lokalem Linux-User
  import pwd
  import spwd
  import crypt
  
  def authenticate_local_user(username, password):
      if username == "mdoehler":
          return verify_linux_password(username, password)
      return False
  ```

- [ ] **Session-Management**
  - HTTP-Session-Cookies (Secure, HttpOnly)
  - Session-Timeout: 24h (lange Session für Convenience)
  - Automatischer Logout bei Browser-Close

- [ ] **API-Token für Services**
  - Einfacher statischer API-Key für Service-Zugriffe
  - In Environment-Variable oder Config-File
  ```bash
  # .env
  API_KEY=aktienanalyse_2025_private_key_mdoehler
  ```

### 1.2 **Frontend-Authentication**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Simple Login-Form**
  - Username: `mdoehler` (fest codiert)
  - Password: Linux-User-Password
  - "Remember Me" Checkbox (30 Tage Session)

- [ ] **Auto-Login Option**
  - Optional: Automatischer Login wenn allein im LXC
  - Konfigurierbar über Environment-Variable
  ```bash
  AUTO_LOGIN=true  # Für Development
  AUTO_LOGIN=false # Für Production-like
  ```

---

## 🛡️ **2. DATA PROTECTION (Minimal)**

### 2.1 **Encryption-at-Rest**
**Implementierungsaufwand**: ⚡ Niedrig (1-2 Tage)

- [ ] **SQLite-Encryption (Optional)**
  - SQLCipher für sensible Daten (API-Keys, Portfolio-Werte)
  - Oder einfach File-System-Level-Encryption im LXC
  ```python
  # Nur für wirklich sensible Daten
  DATABASE_URL = "sqlite+pysqlcipher://:password@/depot.db"
  ```

- [ ] **API-Key-Protection**
  - Bitpanda Pro API-Key verschlüsselt speichern
  - Environment-Variables oder verschlüsselte Config-Files
  ```python
  from cryptography.fernet import Fernet
  
  def encrypt_api_key(api_key, password):
      key = Fernet.generate_key()
      fernet = Fernet(key)
      encrypted = fernet.encrypt(api_key.encode())
      return encrypted
  ```

### 2.2 **Encryption-in-Transit**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **HTTPS für Frontend**
  - Self-signed Certificate für lokalen Zugriff
  - Oder Let's Encrypt wenn öffentliche Domain
  ```nginx
  server {
      listen 443 ssl;
      ssl_certificate /etc/ssl/certs/aktienanalyse.crt;
      ssl_certificate_key /etc/ssl/private/aktienanalyse.key;
  }
  ```

- [ ] **Externe API-Calls über HTTPS**
  - Bitpanda Pro API bereits HTTPS
  - Alpha Vantage, Yahoo Finance bereits HTTPS
  - Certificate-Verification aktiviert

---

## 📊 **3. MONITORING (Zabbix-Integration)**

### 3.1 **Zabbix-Agent-Integration**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Zabbix-Agent-Setup**
  - Zabbix-Agent auf LXC Container installieren
  - Connection zu Zabbix-Server (10.1.1.103)
  ```bash
  # Zabbix-Agent Installation
  apt install zabbix-agent2
  
  # /etc/zabbix/zabbix_agent2.conf
  Server=10.1.1.103
  ServerActive=10.1.1.103
  Hostname=aktienanalyse-lxc-120
  ```

- [ ] **Application-Logging (für Zabbix)**
  - Structured Logging (JSON-Format)
  - Log-Files die Zabbix lesen kann
  ```python
  import logging
  import json
  
  # Zabbix-kompatible Log-Files
  logging.basicConfig(
      level=logging.INFO,
      format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
      handlers=[
          logging.FileHandler('/var/log/aktienanalyse/app.log'),
          logging.FileHandler('/var/log/aktienanalyse/security.log')  # Für Zabbix
      ]
  )
  ```

### 3.2 **Zabbix-Custom-Metrics**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Application-Health-Metrics**
  - Service-Status für alle 7 Domain-Services
  - Database-Connection-Status
  - External-API-Availability (Bitpanda, Alpha Vantage)
  ```bash
  # Custom Zabbix User Parameters
  # /etc/zabbix/zabbix_agent2.d/aktienanalyse.conf
  UserParameter=aktienanalyse.service.status[*],systemctl is-active aktienanalyse-$1
  UserParameter=aktienanalyse.db.status,sqlite3 /data/depot.db "SELECT 1" 2>/dev/null && echo 1 || echo 0
  UserParameter=aktienanalyse.api.bitpanda,curl -s -o /dev/null -w "%{http_code}" https://api.exchange.bitpanda.com/public/v1/time
  ```

- [ ] **Business-Metrics**
  - Anzahl aktiver Trading-Orders
  - Portfolio-Gesamtwert
  - Erfolgreiche vs. fehlgeschlagene API-Calls
  ```python
  # Custom Metrics für Zabbix
  def write_zabbix_metrics():
      metrics = {
          "active_orders": count_active_orders(),
          "portfolio_value": get_total_portfolio_value(),
          "api_success_rate": calculate_api_success_rate(),
          "last_trade_timestamp": get_last_trade_time()
      }
      
      with open('/tmp/aktienanalyse_metrics.json', 'w') as f:
          json.dump(metrics, f)
  ```

### 3.3 **Zabbix-Alerting-Integration**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Critical-Alerts**
  - Service-Down-Alerts
  - Database-Connection-Loss
  - External-API-Failures
  - High-Error-Rate (>5% in 10min)

- [ ] **Business-Alerts**
  - Trading-Order-Failures
  - Significant-Portfolio-Value-Changes (>10%)
  - API-Rate-Limit-Approaching
  - Disk-Space-Low (Database-Growth)

---

## 🌐 **4. NETWORK SECURITY (Minimal)**

### 4.1 **Service-Binding**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Internal Service-Communication**
  - Services nur auf localhost binden (außer Frontend)
  - Keine externe Exposition unnötiger Ports
  ```python
  # Nur Frontend extern erreichbar
  frontend_app.run(host='0.0.0.0', port=443)
  
  # Services nur intern
  api_service.run(host='127.0.0.1', port=8001)
  data_ingestion.run(host='127.0.0.1', port=8002)
  # ... weitere Services
  ```

- [ ] **External API Access**
  - Bitpanda Pro API-Calls über HTTPS
  - Certificate-Verification aktiviert
  - Connection-Timeout-Management
  ```python
  import requests
  
  # Sichere externe API-Calls
  response = requests.get(
      "https://api.exchange.bitpanda.com/public/v1/time",
      timeout=30,
      verify=True  # Certificate-Verification
  )
  ```

---

## 🔧 **5. BACKUP & RECOVERY (Minimal)**

### 5.1 **Data-Backup**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Automated Database-Backup**
  ```bash
  #!/bin/bash
  # Daily backup script
  DATE=$(date +%Y%m%d)
  sqlite3 /data/depot.db ".backup /backup/depot_$DATE.db"
  find /backup -name "depot_*.db" -mtime +30 -delete
  ```

- [ ] **Configuration-Backup**
  - Environment-Files
  - SSL-Certificates
  - Service-Configurations

### 5.2 **Recovery-Testing**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Backup-Verification**
  - Monatliche Backup-Restore-Tests
  - Database-Integrity-Checks
  ```bash
  # Test backup integrity
  sqlite3 /backup/depot_latest.db "PRAGMA integrity_check;"
  ```

---

## 📋 **6. SECRET-MANAGEMENT (Vereinfacht)**

### 6.1 **Environment-based Secrets**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Environment-Variables**
  ```bash
  # /home/mdoehler/.env
  BITPANDA_API_KEY=your_encrypted_api_key
  ALPHA_VANTAGE_KEY=your_av_key
  DATABASE_PASSWORD=your_db_password
  SESSION_SECRET=your_session_secret
  ```

- [ ] **File-Permissions**
  ```bash
  chmod 600 /home/mdoehler/.env
  chown mdoehler:mdoehler /home/mdoehler/.env
  ```

### 6.2 **API-Key-Rotation**
**Implementierungsaufwand**: ⚡ Niedrig (1 Tag)

- [ ] **Quarterly Key-Rotation**
  - Bitpanda Pro API-Key alle 3 Monate erneuern
  - Dokumentierte Rotation-Prozedur
  - Backup der alten Keys für Recovery

---

## ✅ **IMPLEMENTIERUNGS-ROADMAP (Vereinfacht)**

### **Woche 1: Authentication & Basic Security**
- [x] Simple Linux-User-Authentication
- [x] Session-Management
- [x] HTTPS-Setup (Self-signed Certificate)
- [x] Environment-based Secret-Management

### **Woche 2: Data Protection & Zabbix-Integration**
- [x] API-Key-Encryption
- [x] Zabbix-Agent-Setup und -Configuration
- [x] Custom-Metrics für Business-Monitoring
- [x] Automated Database-Backup

**Gesamtaufwand**: 1-2 Wochen (statt 2-3 Wochen, weitere Vereinfachung)
**Benötigte Expertise**: Standard-Entwickler (kein Security-Spezialist nötig)

---

## 🎯 **SECURITY-CHECKLIST (Vereinfacht)**

### **KRITISCH (Muss implementiert werden):**
- [x] HTTPS für Frontend-Zugriff
- [x] Linux-User-Authentication (mdoehler)
- [x] API-Key-Verschlüsselung (Bitpanda Pro)
- [x] Zabbix-Agent-Integration (10.1.1.103)

### **WICHTIG (Sollte implementiert werden):**
- [x] Session-Management mit Timeout
- [x] Database-Backup-Automation
- [x] Zabbix-Custom-Metrics (Business + Technical)
- [x] Service-Port-Binding-Security (localhost only)

### **OPTIONAL (Nice-to-Have):**
- [x] SQLite-Database-Encryption
- [x] Structured Logging (JSON for Zabbix)
- [x] Quarterly API-Key-Rotation
- [x] Advanced Zabbix-Alerting-Rules

---

## 🔍 **SECURITY vs. CONVENIENCE-BALANCE**

**Maximale Convenience** (Development):
```bash
AUTO_LOGIN=true
SESSION_TIMEOUT=never
HTTPS_REQUIRED=false
```

**Balanced Security** (Empfohlen):
```bash
AUTO_LOGIN=false
SESSION_TIMEOUT=24h
HTTPS_REQUIRED=true
```

**Maximale Security** (Paranoid):
```bash
AUTO_LOGIN=false
SESSION_TIMEOUT=2h
HTTPS_REQUIRED=true
DATABASE_ENCRYPTION=true
```

Diese **vereinfachte Security-Spezifikation** fokussiert auf die **tatsächlichen Bedürfnisse** einer privaten Single-User-Umgebung und reduziert den Implementierungsaufwand von 4-6 Wochen auf **2-3 Wochen**.