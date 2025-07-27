# 🔐 API-Key-Protection-Spezifikation - Externe API-Sicherheit

## 🎯 **Übersicht**

**Kontext**: Sichere Speicherung und Verwaltung von API-Keys für externe Services
**Scope**: Bitpanda Pro API, Alpha Vantage, Yahoo Finance, andere Trading-APIs
**Ziel**: Verschlüsselte Speicherung, sichere Übertragung, Key-Rotation-Management

---

## 🔑 **1. API-KEY-INVENTAR**

### 1.1 **Externe API-Services**
```python
from enum import Enum
from dataclasses import dataclass
from typing import Dict, Optional, List

class APIServiceType(Enum):
    BITPANDA_PRO = "bitpanda_pro"
    ALPHA_VANTAGE = "alpha_vantage"
    YAHOO_FINANCE = "yahoo_finance"
    TWELVE_DATA = "twelve_data"
    FINNHUB = "finnhub"
    POLYGON = "polygon"
    IEX_CLOUD = "iex_cloud"

@dataclass
class APIKeyMetadata:
    service_type: APIServiceType
    key_name: str
    description: str
    permissions: List[str]
    rate_limits: Dict[str, int]
    cost_per_request: Optional[float]
    monthly_quota: Optional[int]
    requires_secret: bool
    supports_rotation: bool
    created_at: str
    expires_at: Optional[str]

# API-Service-Definitionen
API_SERVICES = {
    APIServiceType.BITPANDA_PRO: APIKeyMetadata(
        service_type=APIServiceType.BITPANDA_PRO,
        key_name="Bitpanda Pro Trading API",
        description="Vollzugriff für Trading, Portfolio-Management, Market-Data",
        permissions=["trading", "portfolio", "market_data", "websocket"],
        rate_limits={"requests_per_minute": 300, "orders_per_day": 1000},
        cost_per_request=0.0,  # Kostenlos für Kunden
        monthly_quota=None,
        requires_secret=True,  # API-Key + Secret
        supports_rotation=True,
        created_at="2025-01-01",
        expires_at=None  # Kein Ablauf
    ),
    
    APIServiceType.ALPHA_VANTAGE: APIKeyMetadata(
        service_type=APIServiceType.ALPHA_VANTAGE,
        key_name="Alpha Vantage Market Data API",
        description="Aktienpreise, Fundamentaldaten, technische Indikatoren",
        permissions=["market_data", "fundamentals", "technical_indicators"],
        rate_limits={"requests_per_minute": 5, "requests_per_day": 500},
        cost_per_request=0.0,  # Free Tier
        monthly_quota=500,
        requires_secret=False,  # Nur API-Key
        supports_rotation=True,
        created_at="2025-01-01",
        expires_at=None
    ),
    
    APIServiceType.TWELVE_DATA: APIKeyMetadata(
        service_type=APIServiceType.TWELVE_DATA,
        key_name="Twelve Data Market API",
        description="Real-time und historische Marktdaten",
        permissions=["real_time", "historical", "fundamentals"],
        rate_limits={"requests_per_minute": 8, "requests_per_day": 800},
        cost_per_request=0.0,  # Basic Plan
        monthly_quota=800,
        requires_secret=False,
        supports_rotation=True,
        created_at="2025-01-01",
        expires_at=None
    )
}
```

### 1.2 **Sensitivitäts-Klassifizierung**
```python
from enum import Enum

class SensitivityLevel(Enum):
    CRITICAL = "critical"    # Trading-APIs mit Geld-Zugriff
    HIGH = "high"           # Portfolio-Daten, persönliche Finanzen
    MEDIUM = "medium"       # Market-Data mit Quotas
    LOW = "low"            # Öffentliche Market-Data

# Sensitivitäts-Mapping
API_SENSITIVITY = {
    APIServiceType.BITPANDA_PRO: SensitivityLevel.CRITICAL,  # Trading-Zugriff
    APIServiceType.ALPHA_VANTAGE: SensitivityLevel.MEDIUM,   # Quota-limitiert
    APIServiceType.TWELVE_DATA: SensitivityLevel.MEDIUM,     # Quota-limitiert
    APIServiceType.YAHOO_FINANCE: SensitivityLevel.LOW      # Öffentliche Daten
}

# Security-Requirements basierend auf Sensitivität
SECURITY_REQUIREMENTS = {
    SensitivityLevel.CRITICAL: {
        "encryption": "AES-256-GCM",
        "key_rotation_days": 90,
        "audit_logging": True,
        "access_restriction": True,
        "backup_encryption": True,
        "monitoring_alerts": True
    },
    SensitivityLevel.HIGH: {
        "encryption": "AES-256-CBC", 
        "key_rotation_days": 180,
        "audit_logging": True,
        "access_restriction": True,
        "backup_encryption": True,
        "monitoring_alerts": False
    },
    SensitivityLevel.MEDIUM: {
        "encryption": "AES-128-CBC",
        "key_rotation_days": 365,
        "audit_logging": False,
        "access_restriction": False,
        "backup_encryption": False,
        "monitoring_alerts": False
    },
    SensitivityLevel.LOW: {
        "encryption": None,  # Keine Verschlüsselung erforderlich
        "key_rotation_days": None,
        "audit_logging": False,
        "access_restriction": False,
        "backup_encryption": False,
        "monitoring_alerts": False
    }
}
```

---

## 🔒 **2. ENCRYPTION-SYSTEM**

### 2.1 **Multi-Layer-Encryption-Architektur**
```python
import os
import base64
import json
from cryptography.fernet import Fernet
from cryptography.hazmat.primitives import hashes
from cryptography.hazmat.primitives.kdf.pbkdf2 import PBKDF2HMAC
from cryptography.hazmat.primitives.ciphers import Cipher, algorithms, modes
from cryptography.hazmat.backends import default_backend
import secrets

class APIKeyEncryptionManager:
    def __init__(self, master_password: str):
        self.master_password = master_password
        self.backend = default_backend()
        
        # Layer 1: Master-Key-Ableitung
        self.master_key = self._derive_master_key(master_password)
        
        # Layer 2: Service-spezifische Keys
        self.service_keys = {}
        
        # Layer 3: Individual-Key-Encryption
        self.fernet_keys = {}
    
    def _derive_master_key(self, password: str, salt: bytes = None) -> bytes:
        """Ableitung des Master-Keys via PBKDF2"""
        if salt is None:
            salt = os.environ.get('ENCRYPTION_SALT', 'aktienanalyse_salt_2025').encode()
        
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
            backend=self.backend
        )
        return kdf.derive(password.encode())
    
    def _derive_service_key(self, service_type: APIServiceType) -> bytes:
        """Service-spezifische Key-Ableitung"""
        service_salt = f"service_{service_type.value}_salt".encode()
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=service_salt,
            iterations=50000,
            backend=self.backend
        )
        return kdf.derive(self.master_key)
    
    def encrypt_api_key(self, service_type: APIServiceType, api_key: str, api_secret: str = None) -> dict:
        """Verschlüsselt API-Key mit mehrstufiger Encryption"""
        
        # Service-Key ableiten
        service_key = self._derive_service_key(service_type)
        
        # Fernet-Instanz für symmetrische Verschlüsselung
        fernet = Fernet(base64.urlsafe_b64encode(service_key))
        
        # API-Key verschlüsseln
        encrypted_key = fernet.encrypt(api_key.encode())
        
        # API-Secret verschlüsseln (falls vorhanden)
        encrypted_secret = None
        if api_secret:
            encrypted_secret = fernet.encrypt(api_secret.encode())
        
        # Metadata
        encryption_metadata = {
            "service_type": service_type.value,
            "encrypted_key": base64.b64encode(encrypted_key).decode(),
            "encrypted_secret": base64.b64encode(encrypted_secret).decode() if encrypted_secret else None,
            "encryption_algorithm": "AES-256-CBC + PBKDF2",
            "created_at": datetime.utcnow().isoformat(),
            "key_version": 1
        }
        
        return encryption_metadata
    
    def decrypt_api_key(self, encrypted_data: dict) -> tuple:
        """Entschlüsselt API-Key"""
        service_type = APIServiceType(encrypted_data["service_type"])
        
        # Service-Key ableiten
        service_key = self._derive_service_key(service_type)
        fernet = Fernet(base64.urlsafe_b64encode(service_key))
        
        # API-Key entschlüsseln
        encrypted_key = base64.b64decode(encrypted_data["encrypted_key"])
        api_key = fernet.decrypt(encrypted_key).decode()
        
        # API-Secret entschlüsseln (falls vorhanden)
        api_secret = None
        if encrypted_data.get("encrypted_secret"):
            encrypted_secret = base64.b64decode(encrypted_data["encrypted_secret"])
            api_secret = fernet.decrypt(encrypted_secret).decode()
        
        return api_key, api_secret
    
    def rotate_encryption_key(self, service_type: APIServiceType) -> None:
        """Rotiert Encryption-Keys für Service"""
        # Alte verschlüsselte Daten lesen
        old_encrypted_data = self.load_encrypted_api_key(service_type)
        
        if old_encrypted_data:
            # Entschlüsseln mit altem Key
            api_key, api_secret = self.decrypt_api_key(old_encrypted_data)
            
            # Neu verschlüsseln mit rotiertem Master-Key
            # (Master-Key-Rotation würde neues Passwort erfordern)
            new_encrypted_data = self.encrypt_api_key(service_type, api_key, api_secret)
            new_encrypted_data["key_version"] += 1
            
            # Speichern
            self.save_encrypted_api_key(service_type, new_encrypted_data)
            
            # Logging
            logger.info(f"Encryption key rotated for service {service_type.value}")

# Advanced Encryption für CRITICAL APIs
class AdvancedAPIKeyEncryption:
    """Erweiterte Verschlüsselung für kritische APIs (Bitpanda Pro)"""
    
    def __init__(self, master_password: str):
        self.master_password = master_password
        
    def encrypt_critical_api_key(self, api_key: str, api_secret: str) -> dict:
        """AES-256-GCM mit zusätzlicher Authentifizierung"""
        
        # Zufällige IV generieren
        iv = secrets.token_bytes(12)  # 96-bit IV für GCM
        
        # Master-Key ableiten
        salt = secrets.token_bytes(16)
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
            backend=default_backend()
        )
        key = kdf.derive(self.master_password.encode())
        
        # AES-256-GCM Cipher
        cipher = Cipher(
            algorithms.AES(key),
            modes.GCM(iv),
            backend=default_backend()
        )
        encryptor = cipher.encryptor()
        
        # Payload vorbereiten
        payload = json.dumps({
            "api_key": api_key,
            "api_secret": api_secret,
            "timestamp": datetime.utcnow().isoformat()
        }).encode()
        
        # Verschlüsselung
        ciphertext = encryptor.update(payload) + encryptor.finalize()
        
        return {
            "ciphertext": base64.b64encode(ciphertext).decode(),
            "iv": base64.b64encode(iv).decode(),
            "salt": base64.b64encode(salt).decode(),
            "tag": base64.b64encode(encryptor.tag).decode(),
            "algorithm": "AES-256-GCM",
            "kdf": "PBKDF2-SHA256-100k",
            "encrypted_at": datetime.utcnow().isoformat()
        }
    
    def decrypt_critical_api_key(self, encrypted_data: dict) -> tuple:
        """Entschlüsselung von AES-256-GCM-Daten"""
        
        # Parameter extrahieren
        ciphertext = base64.b64decode(encrypted_data["ciphertext"])
        iv = base64.b64decode(encrypted_data["iv"])
        salt = base64.b64decode(encrypted_data["salt"])
        tag = base64.b64decode(encrypted_data["tag"])
        
        # Key ableiten
        kdf = PBKDF2HMAC(
            algorithm=hashes.SHA256(),
            length=32,
            salt=salt,
            iterations=100000,
            backend=default_backend()
        )
        key = kdf.derive(self.master_password.encode())
        
        # Entschlüsselung
        cipher = Cipher(
            algorithms.AES(key),
            modes.GCM(iv, tag),
            backend=default_backend()
        )
        decryptor = cipher.decryptor()
        
        payload = decryptor.update(ciphertext) + decryptor.finalize()
        data = json.loads(payload.decode())
        
        return data["api_key"], data["api_secret"]
```

### 2.2 **Sichere Speicherung**
```python
import sqlite3
import os
from pathlib import Path

class SecureAPIKeyStore:
    def __init__(self, db_path: str = "/data/secure/api_keys.db"):
        self.db_path = db_path
        self.ensure_secure_directory()
        self.init_database()
    
    def ensure_secure_directory(self):
        """Sichere Verzeichnis-Permissions"""
        db_dir = Path(self.db_path).parent
        db_dir.mkdir(parents=True, exist_ok=True)
        
        # Nur Owner-Zugriff (700)
        os.chmod(db_dir, 0o700)
    
    def init_database(self):
        """Initialisiert sichere SQLite-Datenbank"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS api_keys (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    service_type TEXT NOT NULL UNIQUE,
                    encrypted_data TEXT NOT NULL,
                    encryption_version INTEGER DEFAULT 1,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    last_used_at TIMESTAMP,
                    usage_count INTEGER DEFAULT 0,
                    status TEXT DEFAULT 'active'
                )
            """)
            
            conn.execute("""
                CREATE TABLE IF NOT EXISTS key_rotation_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    service_type TEXT NOT NULL,
                    action TEXT NOT NULL,
                    old_version INTEGER,
                    new_version INTEGER,
                    rotated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                    rotated_by TEXT DEFAULT 'system'
                )
            """)
            
            # Sichere File-Permissions
            os.chmod(self.db_path, 0o600)
    
    def store_encrypted_key(self, service_type: APIServiceType, encrypted_data: dict):
        """Speichert verschlüsselte API-Keys"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO api_keys 
                (service_type, encrypted_data, encryption_version, updated_at)
                VALUES (?, ?, ?, CURRENT_TIMESTAMP)
            """, (
                service_type.value,
                json.dumps(encrypted_data),
                encrypted_data.get("key_version", 1)
            ))
    
    def load_encrypted_key(self, service_type: APIServiceType) -> Optional[dict]:
        """Lädt verschlüsselte API-Keys"""
        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute("""
                SELECT encrypted_data, encryption_version 
                FROM api_keys 
                WHERE service_type = ? AND status = 'active'
            """, (service_type.value,))
            
            row = cursor.fetchone()
            if row:
                return json.loads(row[0])
            return None
    
    def update_usage_stats(self, service_type: APIServiceType):
        """Aktualisiert Usage-Statistiken"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                UPDATE api_keys 
                SET usage_count = usage_count + 1,
                    last_used_at = CURRENT_TIMESTAMP
                WHERE service_type = ?
            """, (service_type.value,))
    
    def log_key_rotation(self, service_type: APIServiceType, old_version: int, new_version: int):
        """Loggt Key-Rotation-Events"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT INTO key_rotation_log 
                (service_type, action, old_version, new_version)
                VALUES (?, 'rotation', ?, ?)
            """, (service_type.value, old_version, new_version))
```

---

## 🔄 **3. KEY-ROTATION-SYSTEM**

### 3.1 **Automatische Key-Rotation**
```python
import schedule
import time
from datetime import datetime, timedelta

class APIKeyRotationManager:
    def __init__(self, encryption_manager: APIKeyEncryptionManager, key_store: SecureAPIKeyStore):
        self.encryption_manager = encryption_manager
        self.key_store = key_store
        self.rotation_policies = self._load_rotation_policies()
    
    def _load_rotation_policies(self) -> dict:
        """Lädt Rotation-Policies basierend auf Sensitivität"""
        policies = {}
        
        for service_type, metadata in API_SERVICES.items():
            sensitivity = API_SENSITIVITY[service_type]
            requirements = SECURITY_REQUIREMENTS[sensitivity]
            
            policies[service_type] = {
                "rotation_days": requirements.get("key_rotation_days"),
                "auto_rotation": metadata.supports_rotation,
                "notification_days": 7  # Warnung 7 Tage vor Ablauf
            }
        
        return policies
    
    def check_rotation_due(self) -> List[APIServiceType]:
        """Prüft welche Keys rotiert werden müssen"""
        due_for_rotation = []
        
        for service_type, policy in self.rotation_policies.items():
            if not policy["auto_rotation"] or not policy["rotation_days"]:
                continue
            
            # Letztes Update-Datum prüfen
            encrypted_data = self.key_store.load_encrypted_key(service_type)
            if encrypted_data:
                created_at = datetime.fromisoformat(encrypted_data["created_at"])
                rotation_due = created_at + timedelta(days=policy["rotation_days"])
                
                if datetime.utcnow() >= rotation_due:
                    due_for_rotation.append(service_type)
        
        return due_for_rotation
    
    def rotate_api_key(self, service_type: APIServiceType, new_api_key: str, new_api_secret: str = None):
        """Rotiert API-Key für Service"""
        try:
            # Alte Key-Version laden
            old_encrypted_data = self.key_store.load_encrypted_key(service_type)
            old_version = old_encrypted_data.get("key_version", 1) if old_encrypted_data else 0
            
            # Neue Key verschlüsseln
            if API_SENSITIVITY[service_type] == SensitivityLevel.CRITICAL:
                # Advanced Encryption für kritische APIs
                advanced_encryption = AdvancedAPIKeyEncryption(self.encryption_manager.master_password)
                new_encrypted_data = advanced_encryption.encrypt_critical_api_key(new_api_key, new_api_secret)
            else:
                # Standard Encryption
                new_encrypted_data = self.encryption_manager.encrypt_api_key(service_type, new_api_key, new_api_secret)
            
            new_encrypted_data["key_version"] = old_version + 1
            
            # Speichern
            self.key_store.store_encrypted_key(service_type, new_encrypted_data)
            
            # Rotation loggen
            self.key_store.log_key_rotation(service_type, old_version, new_encrypted_data["key_version"])
            
            # Security-Event loggen
            logger.info(f"API key rotated for service {service_type.value}")
            
            return True
            
        except Exception as e:
            logger.error(f"API key rotation failed for {service_type.value}: {str(e)}")
            return False
    
    def setup_automated_rotation(self):
        """Einrichtung automatischer Rotation-Jobs"""
        
        # Tägliche Prüfung auf fällige Rotationen
        schedule.every().day.at("02:00").do(self.daily_rotation_check)
        
        # Wöchentliche Rotation-Reports
        schedule.every().monday.at("09:00").do(self.weekly_rotation_report)
        
        logger.info("Automated API key rotation scheduled")
    
    def daily_rotation_check(self):
        """Tägliche Rotation-Prüfung"""
        due_services = self.check_rotation_due()
        
        if due_services:
            logger.warning(f"API keys due for rotation: {[s.value for s in due_services]}")
            
            # Notifications senden (Zabbix-Alerts)
            for service in due_services:
                self.send_rotation_alert(service)
    
    def send_rotation_alert(self, service_type: APIServiceType):
        """Sendet Rotation-Alert an Monitoring"""
        alert_data = {
            "service": service_type.value,
            "message": f"API key rotation required for {service_type.value}",
            "severity": "warning",
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Zabbix-Alert via Redis
        redis_client.publish("monitoring:alerts", json.dumps(alert_data))
    
    def weekly_rotation_report(self):
        """Wöchentlicher Rotation-Status-Report"""
        report = {
            "report_date": datetime.utcnow().isoformat(),
            "services": {}
        }
        
        for service_type in API_SERVICES.keys():
            encrypted_data = self.key_store.load_encrypted_key(service_type)
            if encrypted_data:
                created_at = datetime.fromisoformat(encrypted_data["created_at"])
                policy = self.rotation_policies[service_type]
                
                if policy["rotation_days"]:
                    next_rotation = created_at + timedelta(days=policy["rotation_days"])
                    days_until_rotation = (next_rotation - datetime.utcnow()).days
                else:
                    days_until_rotation = None
                
                report["services"][service_type.value] = {
                    "key_version": encrypted_data.get("key_version", 1),
                    "created_at": created_at.isoformat(),
                    "days_until_rotation": days_until_rotation,
                    "auto_rotation": policy["auto_rotation"]
                }
        
        logger.info(f"Weekly rotation report: {json.dumps(report, indent=2)}")
```

### 3.2 **Manuelle Rotation-Tools**
```python
class ManualRotationTool:
    def __init__(self, rotation_manager: APIKeyRotationManager):
        self.rotation_manager = rotation_manager
    
    def rotate_bitpanda_key(self, new_api_key: str, new_api_secret: str) -> bool:
        """Manuelle Bitpanda Pro Key-Rotation"""
        print("🔄 Bitpanda Pro API-Key-Rotation...")
        
        # Validierung der neuen Keys
        if not self.validate_bitpanda_keys(new_api_key, new_api_secret):
            print("❌ Ungültige Bitpanda-API-Keys")
            return False
        
        # Rotation durchführen
        success = self.rotation_manager.rotate_api_key(
            APIServiceType.BITPANDA_PRO, 
            new_api_key, 
            new_api_secret
        )
        
        if success:
            print("✅ Bitpanda Pro API-Key erfolgreich rotiert")
            return True
        else:
            print("❌ Bitpanda Pro API-Key-Rotation fehlgeschlagen")
            return False
    
    def validate_bitpanda_keys(self, api_key: str, api_secret: str) -> bool:
        """Validiert Bitpanda-API-Keys durch Test-Request"""
        try:
            import requests
            import hmac
            import hashlib
            import time
            
            # Test-Request an Bitpanda API
            timestamp = str(int(time.time() * 1000))
            method = "GET"
            path = "/account/balances"
            
            # Signature erstellen
            string_to_sign = f"{timestamp}{method}{path}"
            signature = hmac.new(
                api_secret.encode(),
                string_to_sign.encode(),
                hashlib.sha256
            ).hexdigest()
            
            headers = {
                "X-API-KEY": api_key,
                "X-API-SIGN": signature,
                "X-API-TIMESTAMP": timestamp
            }
            
            response = requests.get(
                "https://api.exchange.bitpanda.com/account/balances",
                headers=headers,
                timeout=10
            )
            
            return response.status_code == 200
            
        except Exception as e:
            logger.error(f"Bitpanda key validation failed: {str(e)}")
            return False
    
    def emergency_key_revocation(self, service_type: APIServiceType) -> bool:
        """Notfall-Key-Sperrung bei Kompromittierung"""
        try:
            # Key als "revoked" markieren
            with sqlite3.connect(self.rotation_manager.key_store.db_path) as conn:
                conn.execute("""
                    UPDATE api_keys 
                    SET status = 'revoked', updated_at = CURRENT_TIMESTAMP
                    WHERE service_type = ?
                """, (service_type.value,))
            
            # Emergency-Alert senden
            alert_data = {
                "service": service_type.value,
                "message": f"EMERGENCY: API key revoked for {service_type.value}",
                "severity": "critical",
                "timestamp": datetime.utcnow().isoformat()
            }
            
            redis_client.publish("monitoring:alerts", json.dumps(alert_data))
            
            logger.critical(f"EMERGENCY: API key revoked for {service_type.value}")
            return True
            
        except Exception as e:
            logger.error(f"Emergency revocation failed: {str(e)}")
            return False

# CLI-Tool für manuelle Rotationen
def rotation_cli():
    """Command-Line-Interface für Key-Rotation"""
    import argparse
    
    parser = argparse.ArgumentParser(description="API Key Rotation Tool")
    parser.add_argument("--service", required=True, choices=[s.value for s in APIServiceType])
    parser.add_argument("--api-key", required=True, help="New API Key")
    parser.add_argument("--api-secret", help="New API Secret (if required)")
    parser.add_argument("--emergency", action="store_true", help="Emergency revocation")
    
    args = parser.parse_args()
    
    # Tool initialisieren
    encryption_manager = APIKeyEncryptionManager(os.environ["MASTER_PASSWORD"])
    key_store = SecureAPIKeyStore()
    rotation_manager = APIKeyRotationManager(encryption_manager, key_store)
    manual_tool = ManualRotationTool(rotation_manager)
    
    service_type = APIServiceType(args.service)
    
    if args.emergency:
        success = manual_tool.emergency_key_revocation(service_type)
    else:
        success = rotation_manager.rotate_api_key(service_type, args.api_key, args.api_secret)
    
    if success:
        print(f"✅ Operation successful for {service_type.value}")
    else:
        print(f"❌ Operation failed for {service_type.value}")

if __name__ == "__main__":
    rotation_cli()
```

---

## 🔒 **4. RUNTIME-ACCESS-CONTROL**

### 4.1 **Secure API-Key-Access**
```python
from contextlib import contextmanager
import threading
from typing import Tuple, Optional

class SecureAPIKeyAccess:
    def __init__(self, encryption_manager: APIKeyEncryptionManager, key_store: SecureAPIKeyStore):
        self.encryption_manager = encryption_manager
        self.key_store = key_store
        self.access_lock = threading.Lock()
        self.active_sessions = {}
    
    @contextmanager
    def get_api_credentials(self, service_type: APIServiceType, request_id: str = None):
        """Secure Context-Manager für API-Key-Zugriff"""
        session_id = f"{service_type.value}_{request_id or secrets.token_hex(8)}"
        
        try:
            with self.access_lock:
                # Verschlüsselte Daten laden
                encrypted_data = self.key_store.load_encrypted_key(service_type)
                if not encrypted_data:
                    raise ValueError(f"No API key found for service {service_type.value}")
                
                # Entschlüsselung
                if API_SENSITIVITY[service_type] == SensitivityLevel.CRITICAL:
                    advanced_encryption = AdvancedAPIKeyEncryption(self.encryption_manager.master_password)
                    api_key, api_secret = advanced_encryption.decrypt_critical_api_key(encrypted_data)
                else:
                    api_key, api_secret = self.encryption_manager.decrypt_api_key(encrypted_data)
                
                # Session-Tracking
                self.active_sessions[session_id] = {
                    "service_type": service_type,
                    "started_at": datetime.utcnow(),
                    "request_id": request_id
                }
                
                # Usage-Stats aktualisieren
                self.key_store.update_usage_stats(service_type)
                
                logger.debug(f"API credentials accessed for {service_type.value} (session: {session_id})")
            
            # Credentials als Tuple zurückgeben
            yield (api_key, api_secret)
            
        except Exception as e:
            logger.error(f"Failed to access API credentials for {service_type.value}: {str(e)}")
            raise
        
        finally:
            # Cleanup: Session entfernen
            with self.access_lock:
                if session_id in self.active_sessions:
                    session_duration = datetime.utcnow() - self.active_sessions[session_id]["started_at"]
                    logger.debug(f"API session closed for {service_type.value} (duration: {session_duration})")
                    del self.active_sessions[session_id]
    
    def get_active_sessions(self) -> dict:
        """Gibt aktive API-Access-Sessions zurück"""
        with self.access_lock:
            return {
                session_id: {
                    "service_type": session["service_type"].value,
                    "started_at": session["started_at"].isoformat(),
                    "duration_seconds": (datetime.utcnow() - session["started_at"]).total_seconds()
                }
                for session_id, session in self.active_sessions.items()
            }

# Usage-Beispiel
class BitpandaAPIClient:
    def __init__(self, api_access: SecureAPIKeyAccess):
        self.api_access = api_access
    
    def get_account_balance(self) -> dict:
        """Sichere API-Calls mit automatischer Key-Verwaltung"""
        with self.api_access.get_api_credentials(APIServiceType.BITPANDA_PRO) as (api_key, api_secret):
            
            # API-Request mit sicheren Credentials
            import requests
            import hmac
            import hashlib
            import time
            
            timestamp = str(int(time.time() * 1000))
            method = "GET"
            path = "/account/balances"
            
            string_to_sign = f"{timestamp}{method}{path}"
            signature = hmac.new(
                api_secret.encode(),
                string_to_sign.encode(),
                hashlib.sha256
            ).hexdigest()
            
            headers = {
                "X-API-KEY": api_key,
                "X-API-SIGN": signature,
                "X-API-TIMESTAMP": timestamp
            }
            
            response = requests.get(
                "https://api.exchange.bitpanda.com/account/balances",
                headers=headers,
                timeout=30
            )
            
            if response.status_code == 200:
                return response.json()
            else:
                raise Exception(f"Bitpanda API error: {response.status_code} - {response.text}")
```

### 4.2 **Access-Monitoring und Rate-Limiting**
```python
from collections import defaultdict
import time

class APIAccessMonitor:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.rate_limits = self._load_rate_limits()
        
    def _load_rate_limits(self) -> dict:
        """Lädt Rate-Limits für alle Services"""
        limits = {}
        for service_type, metadata in API_SERVICES.items():
            limits[service_type] = metadata.rate_limits
        return limits
    
    def check_rate_limit(self, service_type: APIServiceType, request_type: str = "default") -> bool:
        """Prüft Rate-Limit vor API-Call"""
        
        limits = self.rate_limits.get(service_type, {})
        if not limits:
            return True  # Keine Limits definiert
        
        current_time = int(time.time())
        
        # Requests per minute prüfen
        rpm_limit = limits.get("requests_per_minute")
        if rpm_limit:
            minute_key = f"rate_limit:{service_type.value}:minute:{current_time // 60}"
            current_minute_requests = self.redis.incr(minute_key)
            self.redis.expire(minute_key, 60)
            
            if current_minute_requests > rpm_limit:
                logger.warning(f"Rate limit exceeded for {service_type.value}: {current_minute_requests}/{rpm_limit} per minute")
                return False
        
        # Requests per day prüfen
        rpd_limit = limits.get("requests_per_day")
        if rpd_limit:
            day_key = f"rate_limit:{service_type.value}:day:{current_time // 86400}"
            current_day_requests = self.redis.incr(day_key)
            self.redis.expire(day_key, 86400)
            
            if current_day_requests > rpd_limit:
                logger.warning(f"Daily rate limit exceeded for {service_type.value}: {current_day_requests}/{rpd_limit} per day")
                return False
        
        return True
    
    def log_api_call(self, service_type: APIServiceType, endpoint: str, success: bool, response_time: float):
        """Loggt API-Calls für Monitoring"""
        
        call_data = {
            "service_type": service_type.value,
            "endpoint": endpoint,
            "success": success,
            "response_time_ms": response_time * 1000,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        # Redis-Metrics aktualisieren
        metrics_key = f"api_metrics:{service_type.value}"
        self.redis.hincrby(metrics_key, "total_calls", 1)
        
        if success:
            self.redis.hincrby(metrics_key, "successful_calls", 1)
        else:
            self.redis.hincrby(metrics_key, "failed_calls", 1)
        
        # Durchschnittliche Response-Time aktualisieren
        self.redis.hincrbyfloat(metrics_key, "total_response_time", response_time)
        
        # Detailliertes Logging
        logger.info(f"API call logged: {json.dumps(call_data)}")
    
    def get_api_metrics(self, service_type: APIServiceType) -> dict:
        """Gibt API-Metrics für Service zurück"""
        metrics_key = f"api_metrics:{service_type.value}"
        raw_metrics = self.redis.hgetall(metrics_key)
        
        total_calls = int(raw_metrics.get("total_calls", 0))
        successful_calls = int(raw_metrics.get("successful_calls", 0))
        failed_calls = int(raw_metrics.get("failed_calls", 0))
        total_response_time = float(raw_metrics.get("total_response_time", 0))
        
        return {
            "service_type": service_type.value,
            "total_calls": total_calls,
            "successful_calls": successful_calls,
            "failed_calls": failed_calls,
            "success_rate": (successful_calls / total_calls * 100) if total_calls > 0 else 0,
            "average_response_time_ms": (total_response_time / total_calls * 1000) if total_calls > 0 else 0
        }
```

---

## 🔧 **5. ENVIRONMENT-INTEGRATION**

### 5.1 **Environment-Konfiguration**
```bash
# .env (Production)
# Master-Password für API-Key-Encryption
MASTER_PASSWORD=$(openssl rand -base64 32)
ENCRYPTION_SALT=aktienanalyse_encryption_salt_2025

# API-Key-Storage
API_KEY_DB_PATH=/data/secure/api_keys.db
API_KEY_BACKUP_PATH=/backup/secure/api_keys_backup.db

# Bitpanda Pro API (Verschlüsselt gespeichert)
BITPANDA_API_KEY_ENCRYPTED=true
BITPANDA_API_SECRET_ENCRYPTED=true

# Other API Services
ALPHA_VANTAGE_API_KEY_ENCRYPTED=true
TWELVE_DATA_API_KEY_ENCRYPTED=true

# Security-Settings
API_KEY_ROTATION_ENABLED=true
CRITICAL_KEY_MONITORING=true
ACCESS_LOGGING_ENABLED=true

# Rate-Limiting
RATE_LIMIT_REDIS_PREFIX=aktienanalyse:rate_limit
API_METRICS_REDIS_PREFIX=aktienanalyse:api_metrics

# .env (Development)
# Vereinfachte Settings für Development
MASTER_PASSWORD=development_master_password_not_secure
API_KEY_ROTATION_ENABLED=false
ACCESS_LOGGING_ENABLED=true
```

### 5.2 **Docker-Integration**
```yaml
# docker-compose.yml (API-Key-relevante Services)
version: '3.8'

services:
  broker-gateway-service:
    build: ./services/broker-gateway-service
    environment:
      - MASTER_PASSWORD=${MASTER_PASSWORD}
      - API_KEY_DB_PATH=/data/secure/api_keys.db
      - RATE_LIMIT_REDIS_PREFIX=${RATE_LIMIT_REDIS_PREFIX}
    volumes:
      - api_key_storage:/data/secure
      - ./logs:/var/log/aktienanalyse
    depends_on:
      - redis-master
      - postgres
    networks:
      - internal

  intelligent-core-service:
    build: ./services/intelligent-core-service
    environment:
      - MASTER_PASSWORD=${MASTER_PASSWORD}
      - API_KEY_DB_PATH=/data/secure/api_keys.db
    volumes:
      - api_key_storage:/data/secure
    depends_on:
      - redis-master
    networks:
      - internal

volumes:
  api_key_storage:
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/mdoehler/aktienanalyse-data/secure

networks:
  internal:
    driver: bridge
```

### 5.3 **Service-Integration**
```python
# services/broker-gateway-service/src/api_client_factory.py

class APIClientFactory:
    def __init__(self):
        # Encryption-System initialisieren
        master_password = os.environ["MASTER_PASSWORD"]
        self.encryption_manager = APIKeyEncryptionManager(master_password)
        self.key_store = SecureAPIKeyStore()
        self.api_access = SecureAPIKeyAccess(self.encryption_manager, self.key_store)
        self.access_monitor = APIAccessMonitor(redis_client)
        
        # Clients-Cache
        self.clients = {}
    
    def get_bitpanda_client(self) -> BitpandaAPIClient:
        """Factory für Bitpanda-API-Client"""
        if "bitpanda" not in self.clients:
            self.clients["bitpanda"] = BitpandaAPIClient(self.api_access)
        return self.clients["bitpanda"]
    
    def get_alpha_vantage_client(self) -> AlphaVantageAPIClient:
        """Factory für Alpha Vantage-API-Client"""
        if "alpha_vantage" not in self.clients:
            self.clients["alpha_vantage"] = AlphaVantageAPIClient(self.api_access)
        return self.clients["alpha_vantage"]

# services/intelligent-core-service/src/market_data_service.py

class MarketDataService:
    def __init__(self, api_factory: APIClientFactory):
        self.api_factory = api_factory
        self.cache = redis_client
    
    async def get_stock_quote(self, symbol: str) -> dict:
        """Sichere Market-Data-Abfrage mit API-Key-Protection"""
        
        # Rate-Limit prüfen
        if not self.api_factory.access_monitor.check_rate_limit(APIServiceType.ALPHA_VANTAGE):
            raise Exception("Rate limit exceeded for Alpha Vantage API")
        
        # Cache prüfen
        cache_key = f"stock_quote:{symbol}"
        cached_data = self.cache.get(cache_key)
        if cached_data:
            return json.loads(cached_data)
        
        # API-Call mit sicheren Credentials
        start_time = time.time()
        try:
            alpha_vantage = self.api_factory.get_alpha_vantage_client()
            quote_data = alpha_vantage.get_quote(symbol)
            
            # Cache für 5 Minuten
            self.cache.setex(cache_key, 300, json.dumps(quote_data))
            
            # Erfolgreichen API-Call loggen
            self.api_factory.access_monitor.log_api_call(
                APIServiceType.ALPHA_VANTAGE,
                f"/query?function=GLOBAL_QUOTE&symbol={symbol}",
                True,
                time.time() - start_time
            )
            
            return quote_data
            
        except Exception as e:
            # Fehlgeschlagenen API-Call loggen
            self.api_factory.access_monitor.log_api_call(
                APIServiceType.ALPHA_VANTAGE,
                f"/query?function=GLOBAL_QUOTE&symbol={symbol}",
                False,
                time.time() - start_time
            )
            raise
```

---

## 📊 **6. MONITORING & ALERTING**

### 6.1 **Zabbix-Integration**
```python
# Zabbix-Metrics für API-Key-Management
class APIKeyZabbixMetrics:
    def __init__(self, key_store: SecureAPIKeyStore, redis_client):
        self.key_store = key_store
        self.redis = redis_client
    
    def get_key_status_metrics(self) -> dict:
        """Zabbix-Metrics für Key-Status"""
        metrics = {}
        
        for service_type in API_SERVICES.keys():
            encrypted_data = self.key_store.load_encrypted_key(service_type)
            
            if encrypted_data:
                created_at = datetime.fromisoformat(encrypted_data["created_at"])
                age_days = (datetime.utcnow() - created_at).days
                
                # Rotation-Status
                policy = rotation_manager.rotation_policies.get(service_type, {})
                rotation_days = policy.get("rotation_days")
                
                if rotation_days:
                    rotation_due_days = rotation_days - age_days
                    metrics[f"key_rotation_due_days_{service_type.value}"] = rotation_due_days
                    metrics[f"key_rotation_overdue_{service_type.value}"] = 1 if rotation_due_days < 0 else 0
                
                metrics[f"key_age_days_{service_type.value}"] = age_days
                metrics[f"key_version_{service_type.value}"] = encrypted_data.get("key_version", 1)
                metrics[f"key_status_{service_type.value}"] = 1  # Active
            else:
                metrics[f"key_status_{service_type.value}"] = 0  # Missing
        
        return metrics
    
    def get_api_usage_metrics(self) -> dict:
        """Zabbix-Metrics für API-Usage"""
        metrics = {}
        
        for service_type in API_SERVICES.keys():
            api_metrics = access_monitor.get_api_metrics(service_type)
            
            metrics[f"api_calls_total_{service_type.value}"] = api_metrics["total_calls"]
            metrics[f"api_calls_successful_{service_type.value}"] = api_metrics["successful_calls"]
            metrics[f"api_calls_failed_{service_type.value}"] = api_metrics["failed_calls"]
            metrics[f"api_success_rate_{service_type.value}"] = api_metrics["success_rate"]
            metrics[f"api_response_time_{service_type.value}"] = api_metrics["average_response_time_ms"]
        
        return metrics
    
    def write_metrics_for_zabbix(self):
        """Schreibt Metrics für Zabbix-Abfrage"""
        all_metrics = {}
        all_metrics.update(self.get_key_status_metrics())
        all_metrics.update(self.get_api_usage_metrics())
        
        # In Redis für Zabbix speichern
        metrics_key = "zabbix:api_key_metrics"
        for metric_name, value in all_metrics.items():
            self.redis.hset(metrics_key, metric_name, value)
        
        self.redis.expire(metrics_key, 300)  # 5 Minuten TTL

# Zabbix User Parameter Scripts
"""
#!/bin/bash
# /etc/zabbix/scripts/api_key_metrics.sh

METRIC_NAME=$1
redis-cli -h redis-master HGET zabbix:api_key_metrics $METRIC_NAME || echo 0
"""

# /etc/zabbix/zabbix_agent2.d/api_keys.conf
"""
UserParameter=aktienanalyse.api.key.status[*],/etc/zabbix/scripts/api_key_metrics.sh key_status_$1
UserParameter=aktienanalyse.api.key.age[*],/etc/zabbix/scripts/api_key_metrics.sh key_age_days_$1
UserParameter=aktienanalyse.api.rotation.due[*],/etc/zabbix/scripts/api_key_metrics.sh key_rotation_due_days_$1
UserParameter=aktienanalyse.api.calls.total[*],/etc/zabbix/scripts/api_key_metrics.sh api_calls_total_$1
UserParameter=aktienanalyse.api.success.rate[*],/etc/zabbix/scripts/api_key_metrics.sh api_success_rate_$1
"""
```

### 6.2 **Critical-Alerts**
```python
class APIKeyAlertManager:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.alert_thresholds = {
            "key_rotation_overdue": 0,  # Sofortiger Alert bei Überfälligkeit
            "api_success_rate_critical": 50,  # Alert bei <50% Success-Rate
            "api_calls_failed_threshold": 10,  # Alert bei >10 fehlgeschlagenen Calls/Stunde
            "key_access_anomaly": 5  # Alert bei >5 Access-Versuchen ohne Success
        }
    
    def check_critical_alerts(self):
        """Prüft kritische Alert-Bedingungen"""
        alerts = []
        
        # Key-Rotation-Alerts
        for service_type in API_SERVICES.keys():
            if API_SENSITIVITY[service_type] == SensitivityLevel.CRITICAL:
                rotation_due_days = self.redis.hget("zabbix:api_key_metrics", f"key_rotation_due_days_{service_type.value}")
                
                if rotation_due_days and int(rotation_due_days) < 0:
                    alerts.append({
                        "severity": "critical",
                        "service": service_type.value,
                        "message": f"CRITICAL: API key rotation overdue by {abs(int(rotation_due_days))} days",
                        "alert_type": "key_rotation_overdue"
                    })
        
        # API-Success-Rate-Alerts
        for service_type in API_SERVICES.keys():
            success_rate = self.redis.hget("zabbix:api_key_metrics", f"api_success_rate_{service_type.value}")
            
            if success_rate and float(success_rate) < self.alert_thresholds["api_success_rate_critical"]:
                alerts.append({
                    "severity": "warning",
                    "service": service_type.value,
                    "message": f"Low API success rate: {success_rate}%",
                    "alert_type": "api_success_rate_low"
                })
        
        # Alerts senden
        for alert in alerts:
            self.send_alert(alert)
        
        return alerts
    
    def send_alert(self, alert_data: dict):
        """Sendet Alert an Monitoring-System"""
        
        # Zabbix-Alert
        zabbix_alert = {
            "timestamp": datetime.utcnow().isoformat(),
            "host": "aktienanalyse-lxc-120",
            "alert_type": "api_key_management",
            **alert_data
        }
        
        self.redis.publish("monitoring:alerts", json.dumps(zabbix_alert))
        
        # Critical-Logging
        if alert_data["severity"] == "critical":
            logger.critical(f"CRITICAL API KEY ALERT: {alert_data['message']}")
        else:
            logger.warning(f"API KEY ALERT: {alert_data['message']}")
```

---

## ✅ **7. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Encryption-System (2-3 Tage)**
- [ ] Multi-Layer-Encryption-Manager implementieren
- [ ] Secure API-Key-Store mit SQLite entwickeln
- [ ] Advanced-Encryption für kritische APIs (Bitpanda Pro)
- [ ] Environment-Integration testen

### **Phase 2: Key-Rotation-System (2-3 Tage)**
- [ ] Automatisches Rotation-Management entwickeln
- [ ] Manuelle Rotation-Tools erstellen
- [ ] Emergency-Revocation-Funktionen implementieren
- [ ] Rotation-Logging und -Monitoring

### **Phase 3: Runtime-Access-Control (2-3 Tage)**
- [ ] Secure Context-Manager für API-Access
- [ ] Rate-Limiting und Access-Monitoring
- [ ] API-Client-Factory mit sicherer Integration
- [ ] Service-übergreifende API-Metrics

### **Phase 4: Monitoring & Alerting (1-2 Tage)**
- [ ] Zabbix-Metrics-Integration entwickeln
- [ ] Critical-Alert-System implementieren
- [ ] Dashboard-Integration für API-Key-Status
- [ ] Dokumentation und Deployment-Scripts

**Gesamtaufwand**: 7-11 Tage
**Abhängigkeiten**: Redis-Cluster, PostgreSQL, Zabbix-Integration

Diese Spezifikation bietet **Enterprise-grade API-Key-Security** für die private Umgebung mit automatischer Rotation, verschlüsselter Speicherung und umfassendem Monitoring.