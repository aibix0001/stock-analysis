# 📦 Debian Package-Liste - Aktienanalyse-Ökosystem LXC

## 🎯 **Übersicht**

**Ziel**: Vollständige Software-Liste für frisch installiertes Debian LXC  
**Basis**: Debian 12 (Bookworm) minimal installation  
**Architektur**: Native systemd Services ohne Container-Virtualisierung

---

## 🔧 **1. SYSTEM-BASE-PAKETE**

### **1.1 Essential System Tools**
```bash
# Basis-Systemtools
apt update && apt install -y \
    curl \
    wget \
    git \
    vim \
    nano \
    htop \
    systemd \
    systemctl \
    sudo \
    ca-certificates \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https
```

### **1.2 Development Essentials**
```bash
# Build-Tools und Compiler
apt install -y \
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    pkg-config \
    autoconf \
    automake \
    libtool \
    unzip \
    zip
```

### **1.3 Network und Security**
```bash
# Netzwerk-Tools
apt install -y \
    net-tools \
    iputils-ping \
    dnsutils \
    netcat-openbsd \
    ss \
    ufw \
    fail2ban \
    openssl \
    ssl-cert
```

---

## 🐍 **2. PYTHON-UMGEBUNG**

### **2.1 Python Runtime**
```bash
# Python 3.11+ (Debian 12 Standard)
apt install -y \
    python3 \
    python3-dev \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-wheel \
    python3-distutils
```

### **2.2 Python Development Libraries**
```bash
# Header-Files für native Extensions
apt install -y \
    libpython3-dev \
    python3-dev \
    libffi-dev \
    libssl-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg-dev \
    libpng-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libncurses5-dev \
    libncursesw5-dev \
    tk-dev \
    libgdbm-dev \
    libc6-dev \
    liblzma-dev
```

### **2.3 Python Scientific Libraries (System-Level)**
```bash
# NumPy/SciPy Dependencies
apt install -y \
    libblas-dev \
    liblapack-dev \
    libatlas-base-dev \
    gfortran \
    libopenblas-dev
```

---

## 🟢 **3. NODE.JS-UMGEBUNG**

### **3.1 Node.js Installation**
```bash
# NodeSource Repository hinzufügen
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Node.js 18 LTS installieren
apt install -y \
    nodejs \
    npm
```

### **3.2 Node.js Build-Dependencies**
```bash
# Native Module Compilation
apt install -y \
    node-gyp \
    libnode-dev
```

---

## 🗄️ **4. DATABASE-SYSTEME**

### **4.1 PostgreSQL**
```bash
# PostgreSQL 15 (Debian 12 Standard)
apt install -y \
    postgresql \
    postgresql-client \
    postgresql-contrib \
    postgresql-server-dev-15 \
    libpq-dev
```

### **4.2 Redis**
```bash
# Redis 7.x
apt install -y \
    redis-server \
    redis-tools
```

---

## 🔄 **5. MESSAGE-QUEUE-SYSTEME**

### **5.1 RabbitMQ**
```bash
# RabbitMQ Installation
apt install -y \
    rabbitmq-server
```

---

## 🌐 **6. WEB-SERVER & PROXY**

### **6.1 Caddy (Empfohlen)**
```bash
# Caddy Repository
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list

apt update && apt install -y caddy
```

### **6.2 NGINX (Alternative)**
```bash
# NGINX (falls Caddy nicht gewünscht)
apt install -y \
    nginx \
    nginx-extras
```

---

## 📊 **7. MONITORING-SYSTEME**

### **7.1 Zabbix Agent**
```bash
# Zabbix Repository
wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian12_all.deb
dpkg -i zabbix-release_6.4-1+debian12_all.deb
apt update

# Zabbix Agent 2
apt install -y \
    zabbix-agent2 \
    zabbix-agent2-plugin-*
```

### **7.2 System Monitoring Tools**
```bash
# Process und Performance Monitoring
apt install -y \
    psutil \
    iotop \
    iftop \
    nload \
    ncdu \
    tree
```

---

## 🔒 **8. SECURITY-PAKETE**

### **8.1 SSL/TLS Tools**
```bash
# SSL Certificate Management
apt install -y \
    certbot \
    python3-certbot-nginx \
    python3-certbot-dns-cloudflare
```

### **8.2 Security Monitoring**
```bash
# Security Tools
apt install -y \
    logwatch \
    chkrootkit \
    rkhunter \
    clamav \
    clamav-daemon
```

---

## 📋 **9. PYTHON-DEPENDENCIES (pip install)**

### **9.1 Core Application Dependencies**
```bash
# Python Virtual Environment erstellen
python3 -m venv /opt/aktienanalyse-ökosystem/venv
source /opt/aktienanalyse-ökosystem/venv/bin/activate

# Core Framework Dependencies
pip install \
    fastapi==0.104.1 \
    uvicorn[standard]==0.24.0 \
    sqlalchemy==2.0.23 \
    alembic==1.12.1 \
    pydantic==2.5.0 \
    pydantic-settings==2.1.0
```

### **9.2 Database Drivers**
```bash
# Database Connectivity
pip install \
    psycopg2-binary==2.9.9 \
    redis==5.0.1 \
    celery==5.3.4 \
    kombu==5.3.4
```

### **9.3 Data Science & Analytics**
```bash
# Scientific Computing
pip install \
    numpy==1.24.4 \
    pandas==2.1.4 \
    scipy==1.11.4 \
    scikit-learn==1.3.2 \
    ta-lib==0.4.28 \
    yfinance==0.2.28
```

### **9.4 Trading & Financial APIs**
```bash
# Trading APIs
pip install \
    ccxt==4.1.45 \
    python-binance==1.0.19 \
    alpha-vantage==2.3.1 \
    requests==2.31.0 \
    websockets==12.0
```

### **9.5 Monitoring & Logging**
```bash
# Monitoring
pip install \
    prometheus-client==0.19.0 \
    py-zabbix==1.1.7 \
    structlog==23.2.0 \
    python-json-logger==2.0.7
```

---

## 📋 **10. NODE.JS-DEPENDENCIES (npm install)**

### **10.1 Frontend Framework**
```bash
# Global Tools
npm install -g \
    pm2 \
    @angular/cli \
    create-react-app \
    typescript \
    ts-node

# Project Dependencies (in /opt/aktienanalyse-ökosystem/frontend/)
npm install \
    react@18.2.0 \
    react-dom@18.2.0 \
    @types/react@18.2.45 \
    @types/react-dom@18.2.18 \
    typescript@5.3.3
```

### **10.2 Build & Development Tools**
```bash
# Build Tools
npm install \
    vite@5.0.8 \
    @vitejs/plugin-react@4.2.1 \
    @types/node@20.10.5 \
    eslint@8.56.0 \
    prettier@3.1.1
```

### **10.3 UI & Chart Libraries**
```bash
# UI Components
npm install \
    @mui/material@5.15.2 \
    @emotion/react@11.11.1 \
    @emotion/styled@11.11.0 \
    lightweight-charts@4.1.3 \
    recharts@2.8.0
```

---

## 🔧 **11. SYSTEM-KONFIGURATION**

### **11.1 User & Permissions Setup**
```bash
# Aktienanalyse User erstellen
useradd -m -s /bin/bash aktienanalyse
usermod -aG sudo aktienanalyse

# Directories erstellen
mkdir -p /opt/aktienanalyse-ökosystem
chown -R aktienanalyse:aktienanalyse /opt/aktienanalyse-ökosystem

# Permissions setzen
chmod 755 /opt/aktienanalyse-ökosystem
chmod 750 /opt/aktienanalyse-ökosystem/config
```

### **11.2 systemd Service-Setup**
```bash
# Service-Files kopieren
cp /opt/aktienanalyse-ökosystem/deployment/systemd/*.service /etc/systemd/system/
cp /opt/aktienanalyse-ökosystem/deployment/systemd/*.target /etc/systemd/system/

# systemd reload
systemctl daemon-reload
systemctl enable aktienanalyse.target
```

### **11.3 Database-Initialisierung**
```bash
# PostgreSQL Setup
sudo -u postgres createuser aktienanalyse
sudo -u postgres createdb aktienanalyse_events
sudo -u postgres psql -c "ALTER USER aktienanalyse PASSWORD 'secure_password';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE aktienanalyse_events TO aktienanalyse;"

# Redis Configuration
systemctl enable redis-server
systemctl start redis-server

# RabbitMQ Setup
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmqctl add_user aktienanalyse secure_password
rabbitmqctl set_user_tags aktienanalyse administrator
rabbitmqctl add_vhost aktienanalyse
rabbitmqctl set_permissions -p aktienanalyse aktienanalyse ".*" ".*" ".*"
```

---

## ✅ **12. PACKAGE-VERFÜGBARKEITS-CHECK**

### **12.1 Check-Script erstellen**
```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/check-packages.sh

echo "🔍 Checking Debian Package Availability..."

# APT Packages Check
REQUIRED_APT_PACKAGES=(
    "python3" "python3-pip" "python3-venv" "nodejs" "npm"
    "postgresql" "redis-server" "rabbitmq-server"
    "caddy" "git" "curl" "wget" "systemd"
    "build-essential" "libpq-dev" "libssl-dev"
    "zabbix-agent2"
)

MISSING_PACKAGES=()

for package in "${REQUIRED_APT_PACKAGES[@]}"; do
    if ! dpkg -l | grep -q "^ii  $package "; then
        MISSING_PACKAGES+=("$package")
    fi
done

if [ ${#MISSING_PACKAGES[@]} -eq 0 ]; then
    echo "✅ All required APT packages are installed"
else
    echo "❌ Missing APT packages:"
    printf '%s\n' "${MISSING_PACKAGES[@]}"
fi

# Python Packages Check
echo -e "\n🐍 Checking Python Environment..."
source /opt/aktienanalyse-ökosystem/venv/bin/activate

REQUIRED_PIP_PACKAGES=(
    "fastapi" "uvicorn" "sqlalchemy" "psycopg2-binary"
    "redis" "pandas" "numpy" "requests"
)

for package in "${REQUIRED_PIP_PACKAGES[@]}"; do
    if ! pip show "$package" >/dev/null 2>&1; then
        echo "❌ Missing Python package: $package"
    else
        echo "✅ Python package installed: $package"
    fi
done

# Node.js Packages Check
echo -e "\n🟢 Checking Node.js Environment..."
cd /opt/aktienanalyse-ökosystem/frontend/

REQUIRED_NPM_PACKAGES=(
    "react" "typescript" "vite" "@mui/material" "lightweight-charts"
)

for package in "${REQUIRED_NPM_PACKAGES[@]}"; do
    if ! npm list "$package" >/dev/null 2>&1; then
        echo "❌ Missing Node.js package: $package"
    else
        echo "✅ Node.js package installed: $package"
    fi
done

# Service Status Check
echo -e "\n🔧 Checking Service Status..."
REQUIRED_SERVICES=(
    "postgresql" "redis-server" "rabbitmq-server" "caddy" "zabbix-agent2"
)

for service in "${REQUIRED_SERVICES[@]}"; do
    if systemctl is-active --quiet "$service"; then
        echo "✅ Service running: $service"
    else
        echo "❌ Service not running: $service"
    fi
done

echo -e "\n📊 Package Check Complete!"
```

### **12.2 Automated Installation Script**
```bash
#!/bin/bash
# /opt/aktienanalyse-ökosystem/scripts/install-all-packages.sh

set -euo pipefail

echo "🚀 Installing all required packages for aktienanalyse-ökosystem..."

# Update Package Lists
apt update

# Install System Base Packages
echo "📦 Installing system base packages..."
apt install -y curl wget git vim nano htop systemd sudo ca-certificates gnupg lsb-release

# Install Development Tools
echo "🔧 Installing development tools..."
apt install -y build-essential gcc g++ make cmake pkg-config python3-dev libpq-dev libssl-dev

# Install Python Environment
echo "🐍 Installing Python environment..."
apt install -y python3 python3-pip python3-venv python3-setuptools python3-wheel

# Install Node.js
echo "🟢 Installing Node.js..."
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
apt install -y nodejs npm

# Install Databases
echo "🗄️ Installing databases..."
apt install -y postgresql postgresql-client postgresql-contrib redis-server

# Install Message Queue
echo "🔄 Installing RabbitMQ..."
apt install -y rabbitmq-server

# Install Web Server
echo "🌐 Installing Caddy..."
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
apt update && apt install -y caddy

# Install Monitoring
echo "📊 Installing Zabbix Agent..."
wget https://repo.zabbix.com/zabbix/6.4/debian/pool/main/z/zabbix-release/zabbix-release_6.4-1+debian12_all.deb
dpkg -i zabbix-release_6.4-1+debian12_all.deb
apt update && apt install -y zabbix-agent2

# Setup Python Virtual Environment
echo "🐍 Setting up Python virtual environment..."
python3 -m venv /opt/aktienanalyse-ökosystem/venv
source /opt/aktienanalyse-ökosystem/venv/bin/activate

# Install Python Dependencies
pip install --upgrade pip
pip install fastapi uvicorn sqlalchemy psycopg2-binary redis pandas numpy requests

# Setup Services
echo "🔧 Setting up services..."
systemctl enable postgresql redis-server rabbitmq-server caddy zabbix-agent2
systemctl start postgresql redis-server rabbitmq-server caddy zabbix-agent2

echo "✅ All packages installed successfully!"
echo "📋 Run /opt/aktienanalyse-ökosystem/scripts/check-packages.sh to verify installation"
```

---

## 📊 **13. PACKAGE-ÜBERSICHT**

### **13.1 Paket-Kategorien**

| Kategorie | Anzahl Pakete | Kritisch | Beschreibung |
|-----------|---------------|----------|--------------|
| **System Base** | 15 | ✅ | Essential tools, systemd, networking |
| **Development** | 20 | ✅ | Compiler, build tools, headers |
| **Python** | 25 | ✅ | Runtime, libraries, scientific stack |
| **Node.js** | 15 | ✅ | Runtime, npm, build tools |
| **Databases** | 8 | ✅ | PostgreSQL, Redis |
| **Message Queue** | 3 | ✅ | RabbitMQ |
| **Web Server** | 5 | ✅ | Caddy/NGINX |
| **Monitoring** | 10 | 🟡 | Zabbix, system tools |
| **Security** | 12 | 🟡 | SSL, security tools |

### **13.2 Disk-Space-Anforderungen**

| Komponente | Disk Space | Beschreibung |
|------------|------------|--------------|
| **APT Packages** | 2.5 GB | System packages, compilers, libraries |
| **Python venv** | 800 MB | Virtual environment + dependencies |
| **Node.js Dependencies** | 400 MB | npm packages for frontend |
| **Database Data** | 100 MB | Initial database setup |
| **Total Installation** | **3.8 GB** | Complete package installation |

---

## ✅ **14. INSTALLATION-CHECKLIST**

### **Phase 1: System Preparation**
- [ ] Fresh Debian 12 LXC Container
- [ ] Network connectivity verified
- [ ] Root/sudo access available
- [ ] Disk space >= 20 GB

### **Phase 2: Package Installation**
- [ ] System base packages installed
- [ ] Development tools installed
- [ ] Python 3.11+ environment ready
- [ ] Node.js 18 LTS installed
- [ ] PostgreSQL + Redis + RabbitMQ running
- [ ] Caddy web server configured

### **Phase 3: Application Setup**
- [ ] aktienanalyse user created
- [ ] Directory structure established
- [ ] Python virtual environment activated
- [ ] Application dependencies installed
- [ ] Database schemas initialized

### **Phase 4: Service Configuration**
- [ ] systemd services configured
- [ ] Service dependencies verified
- [ ] All services start successfully
- [ ] Health checks passing

**Status**: 🟢 **Package-Liste vollständig und installation-ready**