# 🔐 Environment-Variables-Spezifikation - Sichere Konfiguration

## 🎯 **Übersicht**

**Kontext**: Sichere Verwaltung von Environment-Variablen für native LXC-Services
**Ziel**: Sensitive Daten (API-Keys, Passwords) sicher verwalten ohne Container-Overhead
**Ansatz**: File-basierte Environment-Konfiguration mit strikten Permissions

---

## 🏗️ **1. ENVIRONMENT-STRUKTUR**

### 1.1 **Konfigurations-Hierarchie**
```
/home/mdoehler/aktienanalyse-ökosystem/
├── .env                          # Haupt-Environment (600 permissions)
├── .env.example                  # Template ohne sensible Daten (644)
├── config/
│   ├── env/
│   │   ├── production.env        # Production-spezifische Variablen
│   │   ├── development.env       # Development-spezifische Variablen
│   │   └── local.env            # Lokale Overrides
│   └── secrets/
│       ├── api-keys.env         # Verschlüsselte API-Keys (600)
│       ├── database.env         # Database-Credentials (600)
│       └── certificates.env     # SSL-Certificate-Pfade (600)
└── services/
    └── {service-name}/
        └── .env.service         # Service-spezifische Variablen
```

### 1.2 **Environment-Variable-Kategorien**
```python
# shared/config/environment_categories.py
from enum import Enum
from dataclasses import dataclass
from typing import List, Optional

class VariableCategory(Enum):
    PUBLIC = "public"           # Keine sensiblen Daten
    INTERNAL = "internal"       # Interne Konfiguration
    SENSITIVE = "sensitive"     # API-Keys, Passwords
    CRITICAL = "critical"       # Master-Passwords, Encryption-Keys

class VariableScope(Enum):
    GLOBAL = "global"           # Alle Services
    SERVICE = "service"         # Service-spezifisch
    ENVIRONMENT = "environment" # Environment-spezifisch (dev/prod)

@dataclass
class EnvironmentVariable:
    name: str
    category: VariableCategory
    scope: VariableScope
    description: str
    required: bool
    default_value: Optional[str] = None
    validation_pattern: Optional[str] = None
    example_value: Optional[str] = None

# Environment-Variable-Registry
ENVIRONMENT_VARIABLES = {
    # System-Konfiguration (PUBLIC)
    "NODE_ENV": EnvironmentVariable(
        name="NODE_ENV",
        category=VariableCategory.PUBLIC,
        scope=VariableScope.GLOBAL,
        description="Application environment",
        required=True,
        default_value="production",
        validation_pattern="^(development|production|test)$",
        example_value="production"
    ),
    
    "LOG_LEVEL": EnvironmentVariable(
        name="LOG_LEVEL",
        category=VariableCategory.PUBLIC,
        scope=VariableScope.GLOBAL,
        description="Logging level",
        required=False,
        default_value="info",
        validation_pattern="^(debug|info|warn|error)$",
        example_value="info"
    ),
    
    # Service-Ports (INTERNAL)
    "FRONTEND_PORT": EnvironmentVariable(
        name="FRONTEND_PORT",
        category=VariableCategory.INTERNAL,
        scope=VariableScope.SERVICE,
        description="Frontend service port",
        required=True,
        default_value="8443",
        validation_pattern="^[0-9]{4,5}$",
        example_value="8443"
    ),
    
    "CORE_SERVICE_PORT": EnvironmentVariable(
        name="CORE_SERVICE_PORT",
        category=VariableCategory.INTERNAL,
        scope=VariableScope.SERVICE,
        description="Core service port",
        required=True,
        default_value="8001",
        validation_pattern="^[0-9]{4,5}$",
        example_value="8001"
    ),
    
    # Database-Konfiguration (SENSITIVE)
    "POSTGRES_PASSWORD": EnvironmentVariable(
        name="POSTGRES_PASSWORD",
        category=VariableCategory.SENSITIVE,
        scope=VariableScope.GLOBAL,
        description="PostgreSQL password",
        required=True,
        validation_pattern="^.{12,}$",  # Mindestens 12 Zeichen
        example_value="secure_database_password_2025"
    ),
    
    "REDIS_PASSWORD": EnvironmentVariable(
        name="REDIS_PASSWORD",
        category=VariableCategory.SENSITIVE,
        scope=VariableScope.GLOBAL,
        description="Redis password",
        required=False,
        validation_pattern="^.{8,}$",
        example_value="redis_secure_password"
    ),
    
    # API-Keys (CRITICAL)
    "MASTER_PASSWORD": EnvironmentVariable(
        name="MASTER_PASSWORD",
        category=VariableCategory.CRITICAL,
        scope=VariableScope.GLOBAL,
        description="Master password for API key encryption",
        required=True,
        validation_pattern="^.{16,}$",  # Mindestens 16 Zeichen
        example_value="master_encryption_password_very_secure_2025"
    ),
    
    "SESSION_SECRET": EnvironmentVariable(
        name="SESSION_SECRET",
        category=VariableCategory.CRITICAL,
        scope=VariableScope.GLOBAL,
        description="Session encryption secret",
        required=True,
        validation_pattern="^[a-fA-F0-9]{64}$",  # 64-char hex
        example_value="a1b2c3d4e5f6..."
    ),
    
    # Zabbix-Integration (INTERNAL)
    "ZABBIX_SERVER": EnvironmentVariable(
        name="ZABBIX_SERVER",
        category=VariableCategory.INTERNAL,
        scope=VariableScope.GLOBAL,
        description="Zabbix server IP address",
        required=True,
        default_value="10.1.1.103",
        validation_pattern="^[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}$",
        example_value="10.1.1.103"
    )
}
```

---

## 🔒 **2. SICHERE ENVIRONMENT-DATEI-VERWALTUNG**

### 2.1 **Environment-File-Manager**
```python
# shared/config/environment_manager.py
import os
import re
import stat
from pathlib import Path
from typing import Dict, List, Optional, Tuple
import secrets
import hashlib

class EnvironmentFileManager:
    def __init__(self, base_path: str = "/home/mdoehler/aktienanalyse-ökosystem"):
        self.base_path = Path(base_path)
        self.env_file = self.base_path / ".env"
        self.secrets_dir = self.base_path / "config" / "secrets"
        self.env_dir = self.base_path / "config" / "env"
        
        # Verzeichnisse erstellen
        self.secrets_dir.mkdir(parents=True, exist_ok=True)
        self.env_dir.mkdir(parents=True, exist_ok=True)
    
    def set_secure_permissions(self, file_path: Path, category: VariableCategory):
        """Setzt sichere File-Permissions basierend auf Variable-Category"""
        
        if category in [VariableCategory.SENSITIVE, VariableCategory.CRITICAL]:
            # Nur Owner kann lesen/schreiben (600)
            os.chmod(file_path, stat.S_IRUSR | stat.S_IWUSR)
        elif category == VariableCategory.INTERNAL:
            # Owner lesen/schreiben, Group lesen (640)
            os.chmod(file_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP)
        else:
            # Standard-Permissions für Public (644)
            os.chmod(file_path, stat.S_IRUSR | stat.S_IWUSR | stat.S_IRGRP | stat.S_IROTH)
        
        # Owner auf mdoehler setzen
        import pwd
        try:
            mdoehler_uid = pwd.getpwnam("mdoehler").pw_uid
            mdoehler_gid = pwd.getpwnam("mdoehler").pw_gid
            os.chown(file_path, mdoehler_uid, mdoehler_gid)
        except KeyError:
            pass  # User nicht gefunden
    
    def validate_variable(self, name: str, value: str) -> Tuple[bool, str]:
        """Validiert Environment-Variable gegen Registry"""
        
        if name not in ENVIRONMENT_VARIABLES:
            return True, "Variable not in registry (allowed)"
        
        var_def = ENVIRONMENT_VARIABLES[name]
        
        # Required-Check
        if var_def.required and not value:
            return False, f"Required variable {name} is empty"
        
        # Pattern-Validation
        if var_def.validation_pattern and value:
            if not re.match(var_def.validation_pattern, value):
                return False, f"Variable {name} does not match pattern {var_def.validation_pattern}"
        
        return True, "Valid"
    
    def generate_secure_value(self, var_name: str) -> str:
        """Generiert sichere Werte für spezielle Variablen"""
        
        if var_name == "SESSION_SECRET":
            return secrets.token_hex(32)  # 64-char hex string
        elif var_name == "MASTER_PASSWORD":
            return secrets.token_urlsafe(32)  # URL-safe 32-byte string
        elif var_name.endswith("_PASSWORD"):
            return secrets.token_urlsafe(16)  # 16-byte password
        elif var_name.endswith("_KEY"):
            return secrets.token_hex(16)      # 32-char hex key
        else:
            return secrets.token_urlsafe(12)  # Default secure value
    
    def create_env_template(self) -> str:
        """Erstellt .env.example Template"""
        
        template_content = """# Aktienanalyse-Ökosystem Environment Configuration
# Copy this file to .env and configure with your actual values

# =================================================================
# SYSTEM CONFIGURATION
# =================================================================
NODE_ENV=production
LOG_LEVEL=info
PYTHONPATH=/home/mdoehler/aktienanalyse-ökosystem

# =================================================================
# SERVICE PORTS (Internal Binding)
# =================================================================
FRONTEND_PORT=8443
CORE_SERVICE_PORT=8001
BROKER_SERVICE_PORT=8002
EVENT_BUS_PORT=8003
MONITORING_PORT=8004

# =================================================================
# DATABASE CONFIGURATION
# =================================================================
POSTGRES_HOST=localhost
POSTGRES_PORT=5432
POSTGRES_DB=aktienanalyse_event_store
POSTGRES_USER=mdoehler
POSTGRES_PASSWORD=your_secure_database_password_here

REDIS_HOST=localhost
REDIS_PORT=6379
# REDIS_PASSWORD=optional_redis_password

# =================================================================
# SECURITY CONFIGURATION
# =================================================================
# Master password for API key encryption (16+ characters)
MASTER_PASSWORD=your_master_password_for_encryption_here

# Session secret for authentication (64-char hex)
SESSION_SECRET=generate_with_openssl_rand_hex_32

# SSL Configuration
SSL_ENABLED=true
SSL_CERT_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.crt
SSL_KEY_PATH=/home/mdoehler/aktienanalyse-ökosystem/ssl/server.key

# =================================================================
# API CONFIGURATION
# =================================================================
# API keys are stored encrypted - configure via setup script
API_KEY_DB_PATH=/home/mdoehler/aktienanalyse-ökosystem/data/secure/api_keys.db
API_KEY_ROTATION_ENABLED=true

# =================================================================
# MONITORING CONFIGURATION
# =================================================================
ZABBIX_SERVER=10.1.1.103
ZABBIX_HOSTNAME=aktienanalyse-lxc-120

# =================================================================
# DEVELOPMENT CONFIGURATION (disable in production)
# =================================================================
# AUTO_LOGIN=false
# DEBUG_MODE=false
# DEVELOPMENT_API_DELAY=false
"""
        
        return template_content
    
    def write_environment_file(self, variables: Dict[str, str], file_path: Path, category: VariableCategory):
        """Schreibt Environment-File mit sicheren Permissions"""
        
        # Validierung aller Variablen
        for name, value in variables.items():
            is_valid, message = self.validate_variable(name, value)
            if not is_valid:
                raise ValueError(f"Invalid environment variable: {message}")
        
        # File schreiben
        content = ""
        for name, value in variables.items():
            content += f"{name}={value}\n"
        
        file_path.write_text(content)
        
        # Sichere Permissions setzen
        self.set_secure_permissions(file_path, category)
        
        print(f"✅ Written {len(variables)} variables to {file_path} with {category.value} permissions")
    
    def load_environment_file(self, file_path: Path) -> Dict[str, str]:
        """Lädt Environment-Variablen aus File"""
        
        if not file_path.exists():
            return {}
        
        variables = {}
        content = file_path.read_text()
        
        for line in content.split('\n'):
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                variables[key.strip()] = value.strip()
        
        return variables
    
    def merge_environment_files(self) -> Dict[str, str]:
        """Merged alle Environment-Files in korrekter Reihenfolge"""
        
        merged_env = {}
        
        # 1. Basis .env
        if self.env_file.exists():
            merged_env.update(self.load_environment_file(self.env_file))
        
        # 2. Environment-spezifische Files
        env_mode = merged_env.get('NODE_ENV', 'production')
        env_specific_file = self.env_dir / f"{env_mode}.env"
        if env_specific_file.exists():
            merged_env.update(self.load_environment_file(env_specific_file))
        
        # 3. Secrets-Files
        for secrets_file in self.secrets_dir.glob("*.env"):
            merged_env.update(self.load_environment_file(secrets_file))
        
        # 4. Local overrides
        local_env = self.env_dir / "local.env"
        if local_env.exists():
            merged_env.update(self.load_environment_file(local_env))
        
        return merged_env

# Environment-Setup-Utilities
class EnvironmentSetup:
    def __init__(self):
        self.manager = EnvironmentFileManager()
    
    def initialize_environment(self):
        """Initialisiert Environment-Struktur"""
        
        print("🔐 Initializing secure environment configuration...")
        
        # 1. .env.example erstellen
        example_content = self.manager.create_env_template()
        example_file = self.manager.base_path / ".env.example"
        example_file.write_text(example_content)
        self.manager.set_secure_permissions(example_file, VariableCategory.PUBLIC)
        
        # 2. Secrets-Files erstellen (falls nicht vorhanden)
        self._create_secrets_files()
        
        # 3. Production Environment erstellen
        self._create_production_environment()
        
        # 4. Permissions-Check
        self._verify_permissions()
        
        print("✅ Environment configuration initialized")
    
    def _create_secrets_files(self):
        """Erstellt Secrets-Files mit generierten Werten"""
        
        # API-Keys-File (wird über API-Key-Manager verwaltet)
        api_keys_env = {
            "API_KEY_DB_PATH": "/home/mdoehler/aktienanalyse-ökosystem/data/secure/api_keys.db",
            "API_KEY_ROTATION_ENABLED": "true"
        }
        
        api_keys_file = self.manager.secrets_dir / "api-keys.env"
        if not api_keys_file.exists():
            self.manager.write_environment_file(api_keys_env, api_keys_file, VariableCategory.SENSITIVE)
        
        # Database-Credentials
        db_password = self.manager.generate_secure_value("POSTGRES_PASSWORD")
        database_env = {
            "POSTGRES_PASSWORD": db_password,
            "REDIS_PASSWORD": self.manager.generate_secure_value("REDIS_PASSWORD")
        }
        
        database_file = self.manager.secrets_dir / "database.env"
        if not database_file.exists():
            self.manager.write_environment_file(database_env, database_file, VariableCategory.SENSITIVE)
        
        # Master-Secrets
        master_env = {
            "MASTER_PASSWORD": self.manager.generate_secure_value("MASTER_PASSWORD"),
            "SESSION_SECRET": self.manager.generate_secure_value("SESSION_SECRET")
        }
        
        master_file = self.manager.secrets_dir / "master.env"
        if not master_file.exists():
            self.manager.write_environment_file(master_env, master_file, VariableCategory.CRITICAL)
    
    def _create_production_environment(self):
        """Erstellt Production-Environment-File"""
        
        production_env = {
            "NODE_ENV": "production",
            "LOG_LEVEL": "info",
            "SSL_ENABLED": "true",
            "API_KEY_ROTATION_ENABLED": "true",
            "ZABBIX_SERVER": "10.1.1.103",
            "ZABBIX_HOSTNAME": "aktienanalyse-lxc-120"
        }
        
        production_file = self.manager.env_dir / "production.env"
        self.manager.write_environment_file(production_env, production_file, VariableCategory.INTERNAL)
    
    def _verify_permissions(self):
        """Verifiziert File-Permissions"""
        
        files_to_check = [
            (self.manager.secrets_dir / "master.env", 0o600),
            (self.manager.secrets_dir / "database.env", 0o600),
            (self.manager.secrets_dir / "api-keys.env", 0o600),
            (self.manager.env_dir / "production.env", 0o640),
            (self.manager.base_path / ".env.example", 0o644)
        ]
        
        for file_path, expected_mode in files_to_check:
            if file_path.exists():
                actual_mode = oct(file_path.stat().st_mode)[-3:]
                expected_mode_str = oct(expected_mode)[-3:]
                
                if actual_mode == expected_mode_str:
                    print(f"✅ {file_path.name}: {actual_mode} (correct)")
                else:
                    print(f"⚠️ {file_path.name}: {actual_mode} (expected {expected_mode_str})")
```

---

## ⚙️ **3. SYSTEMD-SERVICE-INTEGRATION**

### 3.1 **Environment-File-Loading für systemd**
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

# Environment-Files in korrekter Reihenfolge laden
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/.env
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/config/env/production.env
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/config/secrets/database.env
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/config/secrets/master.env
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/config/secrets/api-keys.env
EnvironmentFile=-/home/mdoehler/aktienanalyse-ökosystem/config/env/local.env

# Service-spezifische Overrides
Environment=SERVICE_NAME=intelligent-core-service
Environment=SERVICE_PORT=8001
Environment=BIND_ADDRESS=127.0.0.1

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

### 3.2 **Environment-Loader für Python-Services**
```python
# shared/config/environment_loader.py
import os
from typing import Dict, Optional
from pathlib import Path
from shared.config.environment_manager import EnvironmentFileManager

class ServiceEnvironmentLoader:
    def __init__(self, service_name: str = None):
        self.service_name = service_name
        self.manager = EnvironmentFileManager()
        self._loaded_env = None
    
    def load_environment(self) -> Dict[str, str]:
        """Lädt Environment-Variablen für Service"""
        
        if self._loaded_env is not None:
            return self._loaded_env
        
        # Merged Environment laden
        merged_env = self.manager.merge_environment_files()
        
        # Service-spezifische .env.service laden
        if self.service_name:
            service_env_file = Path(f"services/{self.service_name}/.env.service")
            if service_env_file.exists():
                service_env = self.manager.load_environment_file(service_env_file)
                merged_env.update(service_env)
        
        # In os.environ setzen
        for key, value in merged_env.items():
            os.environ[key] = value
        
        self._loaded_env = merged_env
        return merged_env
    
    def get_variable(self, name: str, default: Optional[str] = None, required: bool = False) -> str:
        """Holt einzelne Environment-Variable"""
        
        # Environment laden falls nicht bereits geschehen
        if self._loaded_env is None:
            self.load_environment()
        
        value = os.environ.get(name, default)
        
        if required and value is None:
            raise ValueError(f"Required environment variable {name} not found")
        
        return value
    
    def get_service_config(self) -> Dict[str, str]:
        """Holt Service-spezifische Konfiguration"""
        
        env = self.load_environment()
        
        return {
            "service_name": self.service_name,
            "bind_address": env.get("BIND_ADDRESS", "127.0.0.1"),
            "service_port": int(env.get("SERVICE_PORT", "8000")),
            "log_level": env.get("LOG_LEVEL", "info"),
            "node_env": env.get("NODE_ENV", "production"),
            "ssl_enabled": env.get("SSL_ENABLED", "false").lower() == "true"
        }

# Usage in Service
def create_service_loader(service_name: str = None) -> ServiceEnvironmentLoader:
    """Factory für ServiceEnvironmentLoader"""
    
    # Service-Name automatisch erkennen falls nicht angegeben
    if service_name is None:
        service_name = os.environ.get("SERVICE_NAME")
        if not service_name:
            # Aus Verzeichnis-Name ableiten
            current_dir = Path.cwd().name
            if current_dir.endswith("-service"):
                service_name = current_dir
    
    return ServiceEnvironmentLoader(service_name)

# Service-Start-Helper
def initialize_service_environment(service_name: str = None) -> Dict[str, str]:
    """Initialisiert Environment für Service-Start"""
    
    loader = create_service_loader(service_name)
    env = loader.load_environment()
    
    # Validation
    required_vars = ["POSTGRES_PASSWORD", "MASTER_PASSWORD", "SESSION_SECRET"]
    for var in required_vars:
        if var not in env or not env[var]:
            raise ValueError(f"Required environment variable {var} not configured")
    
    print(f"✅ Environment loaded for service: {service_name or 'unknown'}")
    print(f"📊 Loaded {len(env)} environment variables")
    
    return env
```

---

## 🔍 **4. ENVIRONMENT-MONITORING**

### 4.1 **Environment-Security-Checker**
```python
# shared/monitoring/environment_security.py
import os
import stat
from pathlib import Path
from typing import Dict, List, Tuple
import re

class EnvironmentSecurityChecker:
    def __init__(self):
        self.base_path = Path("/home/mdoehler/aktienanalyse-ökosystem")
        self.critical_files = [
            "config/secrets/master.env",
            "config/secrets/database.env", 
            "config/secrets/api-keys.env"
        ]
        self.sensitive_patterns = [
            r"password",
            r"secret",
            r"key",
            r"token",
            r"credential"
        ]
    
    def check_file_permissions(self) -> List[Dict[str, any]]:
        """Prüft File-Permissions für Environment-Files"""
        
        results = []
        
        for file_rel_path in self.critical_files:
            file_path = self.base_path / file_rel_path
            
            if not file_path.exists():
                results.append({
                    "file": file_rel_path,
                    "status": "missing",
                    "risk_level": "high",
                    "message": "Critical environment file missing"
                })
                continue
            
            # Permission-Check
            file_stat = file_path.stat()
            file_mode = oct(file_stat.st_mode)[-3:]
            
            if file_mode == "600":
                results.append({
                    "file": file_rel_path,
                    "status": "secure",
                    "permissions": file_mode,
                    "risk_level": "none"
                })
            else:
                results.append({
                    "file": file_rel_path,
                    "status": "insecure",
                    "permissions": file_mode,
                    "expected": "600",
                    "risk_level": "critical",
                    "message": f"Permissions too open: {file_mode} (should be 600)"
                })
        
        return results
    
    def check_environment_variables(self) -> List[Dict[str, any]]:
        """Prüft Environment-Variablen auf Security-Issues"""
        
        results = []
        
        # Alle Environment-Variablen durchgehen
        for key, value in os.environ.items():
            
            # Sensitive Variable-Namen erkennen
            is_sensitive = any(
                re.search(pattern, key.lower()) 
                for pattern in self.sensitive_patterns
            )
            
            if is_sensitive:
                # Weak Password-Check
                if value and len(value) < 12:
                    results.append({
                        "variable": key,
                        "status": "weak",
                        "risk_level": "medium",
                        "message": f"Weak value: only {len(value)} characters"
                    })
                
                # Default/Example-Values erkennen
                weak_values = [
                    "password", "secret", "changeme", "admin", "test",
                    "your_password_here", "your_secret_here"
                ]
                
                if value and value.lower() in weak_values:
                    results.append({
                        "variable": key,
                        "status": "default",
                        "risk_level": "critical",
                        "message": "Using default/example value"
                    })
                
                # Empty sensitive variables
                if not value:
                    results.append({
                        "variable": key,
                        "status": "empty",
                        "risk_level": "high",
                        "message": "Sensitive variable is empty"
                    })
        
        return results
    
    def get_security_score(self) -> int:
        """Berechnet Environment-Security-Score (0-100)"""
        
        permission_results = self.check_file_permissions()
        variable_results = self.check_environment_variables()
        
        score = 100
        
        # Permission-Probleme
        for result in permission_results:
            if result["risk_level"] == "critical":
                score -= 25
            elif result["risk_level"] == "high":
                score -= 15
            elif result["risk_level"] == "medium":
                score -= 10
        
        # Variable-Probleme
        for result in variable_results:
            if result["risk_level"] == "critical":
                score -= 20
            elif result["risk_level"] == "high":
                score -= 10
            elif result["risk_level"] == "medium":
                score -= 5
        
        return max(0, score)
    
    def generate_security_report(self) -> Dict[str, any]:
        """Generiert Security-Report für Environment"""
        
        permission_results = self.check_file_permissions()
        variable_results = self.check_environment_variables()
        security_score = self.get_security_score()
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "security_score": security_score,
            "file_permissions": permission_results,
            "environment_variables": variable_results,
            "summary": {
                "total_files_checked": len(permission_results),
                "secure_files": len([r for r in permission_results if r["status"] == "secure"]),
                "insecure_files": len([r for r in permission_results if r["status"] == "insecure"]),
                "total_variables_checked": len(variable_results),
                "critical_issues": len([r for r in permission_results + variable_results if r["risk_level"] == "critical"]),
                "high_issues": len([r for r in permission_results + variable_results if r["risk_level"] == "high"]),
                "medium_issues": len([r for r in permission_results + variable_results if r["risk_level"] == "medium"])
            }
        }

# Zabbix-Integration
def write_environment_security_metrics():
    """Schreibt Environment-Security-Metrics für Zabbix"""
    
    checker = EnvironmentSecurityChecker()
    report = checker.generate_security_report()
    
    import redis
    redis_client = redis.Redis(host='localhost', port=6379, decode_responses=True)
    
    metrics = {
        "env_security_score": report["security_score"],
        "env_files_secure": report["summary"]["secure_files"],
        "env_files_insecure": report["summary"]["insecure_files"],
        "env_critical_issues": report["summary"]["critical_issues"],
        "env_high_issues": report["summary"]["high_issues"],
        "env_medium_issues": report["summary"]["medium_issues"]
    }
    
    metrics_key = "zabbix:environment_security"
    for metric_name, value in metrics.items():
        redis_client.hset(metrics_key, metric_name, value)
    
    redis_client.expire(metrics_key, 300)
    
    print(f"✅ Updated environment security metrics (Score: {report['security_score']}/100)")

if __name__ == "__main__":
    write_environment_security_metrics()
```

### 4.2 **Setup-Scripts**
```bash
#!/bin/bash
# scripts/setup-environment.sh

set -euo pipefail

echo "🔐 Setting up secure environment configuration..."

# Python-Environment-Setup ausführen
cd /home/mdoehler/aktienanalyse-ökosystem
python3 -c "
from shared.config.environment_manager import EnvironmentSetup
setup = EnvironmentSetup()
setup.initialize_environment()
"

# Permissions final prüfen
echo "🔍 Verifying file permissions..."
find config/secrets -name "*.env" -exec ls -la {} \;

# Environment laden und validieren
echo "✅ Testing environment loading..."
python3 -c "
from shared.config.environment_loader import initialize_service_environment
env = initialize_service_environment('test-service')
print(f'Loaded {len(env)} environment variables successfully')
"

echo "✅ Environment setup completed!"
echo ""
echo "📋 Next steps:"
echo "  1. Review generated passwords in config/secrets/"
echo "  2. Configure API keys via: python3 scripts/setup-api-keys.py"
echo "  3. Test service startup: ./scripts/manage-services.sh start"
```

---

## ✅ **5. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Environment-Structure-Setup (1 Tag)**
- [ ] Environment-File-Manager implementieren
- [ ] Sichere File-Permissions und -Struktur erstellen
- [ ] Variable-Registry und -Validation entwickeln
- [ ] .env.example-Template generieren

### **Phase 2: Service-Integration (1 Tag)**
- [ ] ServiceEnvironmentLoader für Python-Services implementieren
- [ ] systemd-Service-Integration mit EnvironmentFile
- [ ] Service-spezifische Environment-Loading
- [ ] Auto-Generated Secure-Values implementieren

### **Phase 3: Security-Monitoring (1 Tag)**
- [ ] Environment-Security-Checker entwickeln
- [ ] File-Permission-Monitoring implementieren
- [ ] Variable-Validation und Weak-Value-Detection
- [ ] Zabbix-Integration für Environment-Security-Score

### **Phase 4: Setup-Automation (1 Tag)**
- [ ] Environment-Setup-Scripts erstellen
- [ ] Automated Permission-Setting implementieren
- [ ] Testing und Validation-Tools
- [ ] Dokumentation und Troubleshooting-Guides

**Gesamtaufwand**: 4 Tage
**Abhängigkeiten**: Keine

Diese Spezifikation bietet **comprehensive Environment-Security** mit strikten File-Permissions und automatisierter Validation für die private LXC-Umgebung.