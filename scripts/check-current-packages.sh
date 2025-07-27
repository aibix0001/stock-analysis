#!/bin/bash
# Package Availability Check für aktuelle LXC-Umgebung

set -euo pipefail

echo "🔍 Checking Package Availability in Current LXC Environment"
echo "=========================================================="

# Current Environment Info
echo "📋 Current Environment:"
echo "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'=' -f2 | tr -d '\"')"
echo "Kernel: $(uname -r)"
echo "Architecture: $(uname -m)"
echo ""

# 1. ESSENTIAL RUNTIME VERSIONS CHECK
echo "🔧 Core Runtime Versions:"
echo "------------------------"

# Python Check
if command -v python3 >/dev/null 2>&1; then
    python_version=$(python3 --version 2>&1 | cut -d' ' -f2)
    echo "✅ Python: $python_version"
    if python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
        echo "   └─ ✅ Version >= 3.11 (Compatible)"
    else
        echo "   └─ ❌ Version < 3.11 (Upgrade required)"
    fi
else
    echo "❌ Python: Not installed"
fi

# Node.js Check
if command -v node >/dev/null 2>&1; then
    node_version=$(node --version 2>&1)
    echo "✅ Node.js: $node_version"
    if node -pe "process.exit(parseInt(process.version.slice(1)) >= 18 ? 0 : 1)" 2>/dev/null; then
        echo "   └─ ✅ Version >= 18 (Compatible)"
    else
        echo "   └─ ❌ Version < 18 (Upgrade required)"
    fi
else
    echo "❌ Node.js: Not installed"
fi

# Git Check
if command -v git >/dev/null 2>&1; then
    git_version=$(git --version | cut -d' ' -f3)
    echo "✅ Git: $git_version"
else
    echo "❌ Git: Not installed"
fi

# systemd Check
if command -v systemctl >/dev/null 2>&1; then
    systemd_version=$(systemctl --version | head -1 | awk '{print $2}')
    echo "✅ systemd: $systemd_version"
else
    echo "❌ systemd: Not available"
fi

echo ""

# 2. DATABASE SYSTEMS CHECK
echo "🗄️ Database Systems:"
echo "-------------------"

# PostgreSQL Check
if dpkg -l | grep -q postgresql-; then
    pg_version=$(dpkg -l | grep "^ii.*postgresql-[0-9]" | awk '{print $2}' | cut -d'-' -f2 | head -1)
    echo "✅ PostgreSQL: Version $pg_version installed"
    if systemctl is-active --quiet postgresql 2>/dev/null; then
        echo "   └─ ✅ Service running"
    else
        echo "   └─ ⚠️ Service not running"
    fi
else
    echo "❌ PostgreSQL: Not installed"
fi

# Redis Check
if dpkg -l | grep -q redis-server; then
    redis_version=$(redis-server --version 2>/dev/null | grep -o "v=[0-9.]*" | cut -d'=' -f2 || echo "unknown")
    echo "✅ Redis: Version $redis_version"
    if systemctl is-active --quiet redis-server 2>/dev/null; then
        echo "   └─ ✅ Service running"
    else
        echo "   └─ ⚠️ Service not running"
    fi
else
    echo "❌ Redis: Not installed"
fi

# RabbitMQ Check
if dpkg -l | grep -q rabbitmq-server; then
    echo "✅ RabbitMQ: Installed"
    if systemctl is-active --quiet rabbitmq-server 2>/dev/null; then
        echo "   └─ ✅ Service running"
    else
        echo "   └─ ⚠️ Service not running"
    fi
else
    echo "❌ RabbitMQ: Not installed"
fi

echo ""

# 3. WEB SERVERS CHECK
echo "🌐 Web Servers:"
echo "--------------"

# Caddy Check
if command -v caddy >/dev/null 2>&1; then
    caddy_version=$(caddy version 2>/dev/null | head -1 | awk '{print $1}' || echo "unknown")
    echo "✅ Caddy: $caddy_version"
else
    echo "❌ Caddy: Not installed"
fi

# NGINX Check
if command -v nginx >/dev/null 2>&1; then
    nginx_version=$(nginx -v 2>&1 | cut -d'/' -f2)
    echo "✅ NGINX: $nginx_version"
else
    echo "❌ NGINX: Not installed"
fi

echo ""

# 4. MONITORING TOOLS CHECK
echo "📊 Monitoring Tools:"
echo "------------------"

# Zabbix Agent Check
if command -v zabbix_agent2 >/dev/null 2>&1; then
    zabbix_version=$(zabbix_agent2 --version 2>/dev/null | head -1 | awk '{print $3}' || echo "unknown")
    echo "✅ Zabbix Agent 2: $zabbix_version"
else
    echo "❌ Zabbix Agent 2: Not installed"
fi

# System Monitoring Tools
for tool in htop iotop ps netstat ss curl wget; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✅ $tool: Available"
    else
        echo "❌ $tool: Not available"
    fi
done

echo ""

# 5. DEVELOPMENT TOOLS CHECK
echo "🔧 Development Tools:"
echo "-------------------"

# Build Tools
for tool in gcc g++ make cmake; do
    if command -v $tool >/dev/null 2>&1; then
        echo "✅ $tool: Available"
    else
        echo "❌ $tool: Not available"
    fi
done

# Python Development
if python3 -c "import pip" 2>/dev/null; then
    pip_version=$(python3 -m pip --version | awk '{print $2}')
    echo "✅ pip: $pip_version"
else
    echo "❌ pip: Not available"
fi

if python3 -c "import venv" 2>/dev/null; then
    echo "✅ Python venv: Available"
else
    echo "❌ Python venv: Not available"
fi

# Node.js Development
if command -v npm >/dev/null 2>&1; then
    npm_version=$(npm --version)
    echo "✅ npm: $npm_version"
else
    echo "❌ npm: Not available"
fi

echo ""

# 6. PACKAGE REPOSITORY CHECK
echo "📦 Package Repository Status:"
echo "----------------------------"

# APT Update Check
echo "Checking APT repository status..."
if apt update >/dev/null 2>&1; then
    echo "✅ APT repositories accessible"
    
    # Check specific package availability
    echo ""
    echo "Key Package Availability:"
    
    CRITICAL_PACKAGES=(
        "postgresql-15"
        "redis-server" 
        "rabbitmq-server"
        "python3-dev"
        "nodejs"
        "build-essential"
        "libpq-dev"
        "libssl-dev"
    )
    
    for package in "${CRITICAL_PACKAGES[@]}"; do
        if apt-cache show "$package" >/dev/null 2>&1; then
            echo "✅ $package: Available in repositories"
        else
            echo "❌ $package: Not found in repositories"
        fi
    done
    
else
    echo "❌ APT repositories not accessible"
fi

echo ""

# 7. MISSING PACKAGES SUMMARY
echo "📋 Installation Summary:"
echo "----------------------"

MISSING_CRITICAL=()
MISSING_OPTIONAL=()

# Check critical packages
if ! command -v python3 >/dev/null 2>&1 || ! python3 -c "import sys; exit(0 if sys.version_info >= (3, 11) else 1)" 2>/dev/null; then
    MISSING_CRITICAL+=("Python 3.11+")
fi

if ! command -v node >/dev/null 2>&1 || ! node -pe "process.exit(parseInt(process.version.slice(1)) >= 18 ? 0 : 1)" 2>/dev/null; then
    MISSING_CRITICAL+=("Node.js 18+")
fi

if ! dpkg -l | grep -q postgresql-; then
    MISSING_CRITICAL+=("PostgreSQL")
fi

if ! dpkg -l | grep -q redis-server; then
    MISSING_CRITICAL+=("Redis")
fi

if ! command -v systemctl >/dev/null 2>&1; then
    MISSING_CRITICAL+=("systemd")
fi

# Check optional packages
if ! dpkg -l | grep -q rabbitmq-server; then
    MISSING_OPTIONAL+=("RabbitMQ")
fi

if ! command -v caddy >/dev/null 2>&1 && ! command -v nginx >/dev/null 2>&1; then
    MISSING_OPTIONAL+=("Web Server (Caddy/NGINX)")
fi

if ! command -v zabbix_agent2 >/dev/null 2>&1; then
    MISSING_OPTIONAL+=("Zabbix Agent 2")
fi

# Results
if [ ${#MISSING_CRITICAL[@]} -eq 0 ]; then
    echo "✅ All critical packages are available/compatible"
else
    echo "❌ Missing critical packages:"
    printf '   - %s\n' "${MISSING_CRITICAL[@]}"
fi

if [ ${#MISSING_OPTIONAL[@]} -eq 0 ]; then
    echo "✅ All optional packages are available"
else
    echo "⚠️ Missing optional packages:"
    printf '   - %s\n' "${MISSING_OPTIONAL[@]}"
fi

echo ""

# 8. RECOMMENDATIONS
echo "🎯 Recommendations:"
echo "-----------------"

if [ ${#MISSING_CRITICAL[@]} -gt 0 ]; then
    echo "🚨 CRITICAL: Install missing packages before proceeding:"
    echo "   apt update && apt install -y python3 python3-dev nodejs postgresql redis-server"
fi

if [ ${#MISSING_OPTIONAL[@]} -gt 0 ]; then
    echo "💡 OPTIONAL: Consider installing for full functionality:"
    echo "   apt install -y rabbitmq-server caddy zabbix-agent2"
fi

echo ""
echo "📄 For complete installation guide, see:"
echo "   /home/mdoehler/aktienanalyse-ökosystem/docs/DEBIAN_PACKAGE_LISTE.md"
echo ""
echo "🚀 To install all packages automatically, run:"
echo "   /home/mdoehler/aktienanalyse-ökosystem/scripts/install-all-packages.sh"

echo ""
echo "✅ Package availability check completed!"