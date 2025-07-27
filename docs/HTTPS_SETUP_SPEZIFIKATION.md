# 🔒 HTTPS-Setup-Spezifikation - SSL/TLS für Private Umgebung

## 🎯 **Übersicht**

**Kontext**: Private Single-User-Umgebung (LXC Container 10.1.1.120)
**Ziel**: Sichere HTTPS-Kommunikation für Frontend und interne Services
**Ansatz**: Self-signed Certificate für lokalen Zugriff, optional Let's Encrypt für externe Domain

---

## 🏗️ **1. CERTIFICATE-STRATEGIEN**

### 1.1 **Deployment-Szenarien**
```python
from enum import Enum
from dataclasses import dataclass
from typing import Optional, List

class CertificateType(Enum):
    SELF_SIGNED = "self_signed"
    LETS_ENCRYPT = "lets_encrypt"
    CUSTOM_CA = "custom_ca"

class DeploymentMode(Enum):
    LOCAL_ONLY = "local_only"          # Nur LXC-interne Zugriffe
    LAN_ACCESS = "lan_access"          # Zugriff im lokalen Netzwerk
    EXTERNAL_DOMAIN = "external_domain" # Öffentliche Domain verfügbar

@dataclass
class SSLConfiguration:
    deployment_mode: DeploymentMode
    certificate_type: CertificateType
    domains: List[str]
    certificate_path: str
    private_key_path: str
    ca_bundle_path: Optional[str]
    auto_renewal: bool
    hsts_enabled: bool
    tls_version_min: str
    cipher_suites: List[str]

# Konfigurationen für verschiedene Szenarien
SSL_CONFIGURATIONS = {
    DeploymentMode.LOCAL_ONLY: SSLConfiguration(
        deployment_mode=DeploymentMode.LOCAL_ONLY,
        certificate_type=CertificateType.SELF_SIGNED,
        domains=["localhost", "127.0.0.1", "aktienanalyse.local"],
        certificate_path="/etc/ssl/certs/aktienanalyse-local.crt",
        private_key_path="/etc/ssl/private/aktienanalyse-local.key",
        ca_bundle_path="/etc/ssl/certs/aktienanalyse-ca.crt",
        auto_renewal=False,
        hsts_enabled=False,  # Nicht für localhost
        tls_version_min="TLSv1.2",
        cipher_suites=[
            "ECDHE-RSA-AES256-GCM-SHA384",
            "ECDHE-RSA-AES128-GCM-SHA256",
            "ECDHE-RSA-AES256-SHA384",
            "ECDHE-RSA-AES128-SHA256"
        ]
    ),
    
    DeploymentMode.LAN_ACCESS: SSLConfiguration(
        deployment_mode=DeploymentMode.LAN_ACCESS,
        certificate_type=CertificateType.SELF_SIGNED,
        domains=["aktienanalyse.local", "10.1.1.120", "aktienanalyse-lxc-120.local"],
        certificate_path="/etc/ssl/certs/aktienanalyse-lan.crt",
        private_key_path="/etc/ssl/private/aktienanalyse-lan.key",
        ca_bundle_path="/etc/ssl/certs/aktienanalyse-ca.crt",
        auto_renewal=False,
        hsts_enabled=True,   # HSTS für LAN-Zugriff
        tls_version_min="TLSv1.2",
        cipher_suites=[
            "ECDHE-RSA-AES256-GCM-SHA384",
            "ECDHE-RSA-AES128-GCM-SHA256"
        ]
    ),
    
    DeploymentMode.EXTERNAL_DOMAIN: SSLConfiguration(
        deployment_mode=DeploymentMode.EXTERNAL_DOMAIN,
        certificate_type=CertificateType.LETS_ENCRYPT,
        domains=["aktienanalyse.example.com"],  # User-spezifische Domain
        certificate_path="/etc/letsencrypt/live/aktienanalyse.example.com/fullchain.pem",
        private_key_path="/etc/letsencrypt/live/aktienanalyse.example.com/privkey.pem",
        ca_bundle_path=None,  # Let's Encrypt CA ist öffentlich trusted
        auto_renewal=True,
        hsts_enabled=True,
        tls_version_min="TLSv1.3",  # Höhere Security für öffentliche Domains
        cipher_suites=[
            "TLS_AES_256_GCM_SHA384",
            "TLS_AES_128_GCM_SHA256",
            "ECDHE-RSA-AES256-GCM-SHA384"
        ]
    )
}
```

### 1.2 **Certificate-Authority-Setup (für Self-signed)**
```bash
#!/bin/bash
# scripts/setup-custom-ca.sh

set -euo pipefail

# Certificate-Authority für aktienanalyse-ökosystem
CA_NAME="Aktienanalyse Private CA"
CA_DIR="/etc/ssl/aktienanalyse-ca"
CERT_DIR="/etc/ssl/certs"
PRIVATE_DIR="/etc/ssl/private"

echo "🔐 Setting up Custom CA for Aktienanalyse-Ökosystem..."

# Verzeichnisse erstellen
mkdir -p "$CA_DIR"/{certs,crl,newcerts,private}
chmod 700 "$CA_DIR/private"

# CA-Index-Dateien
touch "$CA_DIR/index.txt"
echo 1000 > "$CA_DIR/serial"

# OpenSSL-Konfiguration für CA
cat > "$CA_DIR/openssl.cnf" <<EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
dir               = $CA_DIR
certs             = \$dir/certs
crl_dir           = \$dir/crl
new_certs_dir     = \$dir/newcerts
database          = \$dir/index.txt
serial            = \$dir/serial
RANDFILE          = \$dir/private/.rand

private_key       = \$dir/private/ca.key.pem
certificate       = \$dir/certs/ca.cert.pem

crlnumber         = \$dir/crlnumber
crl               = \$dir/crl/ca.crl.pem
crl_extensions    = crl_ext
default_crl_days  = 30

default_md        = sha256
name_opt          = ca_default
cert_opt          = ca_default
default_days      = 375
preserve          = no
policy            = policy_strict

[ policy_strict ]
countryName             = match
stateOrProvinceName     = match
organizationName        = match
organizationalUnitName  = optional
commonName              = supplied
emailAddress            = optional

[ req ]
default_bits        = 4096
distinguished_name  = req_distinguished_name
string_mask         = utf8only
default_md          = sha256
x509_extensions     = v3_ca

[ req_distinguished_name ]
countryName                     = Country Name (2 letter code)
stateOrProvinceName             = State or Province Name
localityName                    = Locality Name
0.organizationName              = Organization Name
organizationalUnitName          = Organizational Unit Name
commonName                      = Common Name
emailAddress                    = Email Address

[ v3_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ v3_intermediate_ca ]
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true, pathlen:0
keyUsage = critical, digitalSignature, cRLSign, keyCertSign

[ server_cert ]
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = localhost
DNS.2 = aktienanalyse.local
DNS.3 = aktienanalyse-lxc-120.local
IP.1 = 127.0.0.1
IP.2 = 10.1.1.120
EOF

# CA-Private-Key generieren
openssl genrsa -aes256 -out "$CA_DIR/private/ca.key.pem" 4096
chmod 400 "$CA_DIR/private/ca.key.pem"

# CA-Certificate erstellen
openssl req -config "$CA_DIR/openssl.cnf" \
    -key "$CA_DIR/private/ca.key.pem" \
    -new -x509 -days 7300 -sha256 -extensions v3_ca \
    -out "$CA_DIR/certs/ca.cert.pem" \
    -subj "/C=DE/ST=NRW/L=Düsseldorf/O=Aktienanalyse Private/OU=IT Department/CN=Aktienanalyse Private CA"

chmod 444 "$CA_DIR/certs/ca.cert.pem"

# CA-Certificate in System-Trust-Store kopieren
cp "$CA_DIR/certs/ca.cert.pem" "$CERT_DIR/aktienanalyse-ca.crt"
update-ca-certificates

echo "✅ Custom CA setup completed"
echo "CA Certificate: $CA_DIR/certs/ca.cert.pem"
echo "CA Private Key: $CA_DIR/private/ca.key.pem"
```

---

## 🔐 **2. SELF-SIGNED CERTIFICATE-GENERIERUNG**

### 2.1 **Automated Certificate Generation**
```python
import subprocess
import os
from pathlib import Path
from datetime import datetime, timedelta
import tempfile

class SelfSignedCertificateManager:
    def __init__(self, ca_dir: str = "/etc/ssl/aktienanalyse-ca"):
        self.ca_dir = Path(ca_dir)
        self.cert_dir = Path("/etc/ssl/certs")
        self.private_dir = Path("/etc/ssl/private")
        
    def generate_server_certificate(self, domains: List[str], cert_name: str = "aktienanalyse") -> tuple:
        """Generiert Server-Certificate mit Custom CA"""
        
        private_key_path = self.private_dir / f"{cert_name}.key"
        cert_path = self.cert_dir / f"{cert_name}.crt"
        csr_path = self.private_dir / f"{cert_name}.csr"
        
        try:
            # 1. Private Key generieren
            self._generate_private_key(private_key_path)
            
            # 2. Certificate Signing Request (CSR) erstellen
            self._generate_csr(private_key_path, csr_path, domains, cert_name)
            
            # 3. Certificate von CA signieren lassen
            self._sign_certificate_with_ca(csr_path, cert_path, domains)
            
            # 4. Permissions setzen
            os.chmod(private_key_path, 0o600)
            os.chmod(cert_path, 0o644)
            
            # 5. CSR löschen (nicht mehr benötigt)
            csr_path.unlink()
            
            return str(cert_path), str(private_key_path)
            
        except Exception as e:
            logger.error(f"Certificate generation failed: {str(e)}")
            raise
    
    def _generate_private_key(self, key_path: Path, key_size: int = 4096):
        """Generiert RSA-Private-Key"""
        cmd = [
            "openssl", "genrsa",
            "-out", str(key_path),
            str(key_size)
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"Private key generation failed: {result.stderr}")
    
    def _generate_csr(self, key_path: Path, csr_path: Path, domains: List[str], common_name: str):
        """Generiert Certificate Signing Request"""
        
        # Subject für Certificate
        subject = f"/C=DE/ST=NRW/L=Düsseldorf/O=Aktienanalyse Private/OU=Services/CN={common_name}"
        
        # OpenSSL-Config für SAN (Subject Alternative Names)
        config_content = f"""
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no

[req_distinguished_name]
C=DE
ST=NRW
L=Düsseldorf
O=Aktienanalyse Private
OU=Services
CN={common_name}

[v3_req]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
"""
        
        # SAN-Einträge hinzufügen
        for i, domain in enumerate(domains, 1):
            if domain.replace(".", "").replace(":", "").isdigit() or ":" in domain:
                # IP-Adresse
                config_content += f"IP.{i} = {domain}\n"
            else:
                # DNS-Name
                config_content += f"DNS.{i} = {domain}\n"
        
        # Config in temporäre Datei schreiben
        with tempfile.NamedTemporaryFile(mode='w', suffix='.cnf', delete=False) as f:
            f.write(config_content)
            config_file = f.name
        
        try:
            cmd = [
                "openssl", "req",
                "-new",
                "-key", str(key_path),
                "-out", str(csr_path),
                "-config", config_file
            ]
            
            result = subprocess.run(cmd, capture_output=True, text=True)
            if result.returncode != 0:
                raise Exception(f"CSR generation failed: {result.stderr}")
                
        finally:
            os.unlink(config_file)
    
    def _sign_certificate_with_ca(self, csr_path: Path, cert_path: Path, domains: List[str]):
        """Signiert Certificate mit Custom CA"""
        
        ca_cert = self.ca_dir / "certs" / "ca.cert.pem"
        ca_key = self.ca_dir / "private" / "ca.key.pem"
        ca_config = self.ca_dir / "openssl.cnf"
        
        # Extensions-File für SAN erstellen
        ext_content = f"""
basicConstraints = CA:FALSE
nsCertType = server
nsComment = "Aktienanalyse Server Certificate"
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer:always
keyUsage = critical, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
"""
        
        for i, domain in enumerate(domains, 1):
            if domain.replace(".", "").replace(":", "").isdigit() or ":" in domain:
                ext_content += f"IP.{i} = {domain}\n"
            else:
                ext_content += f"DNS.{i} = {domain}\n"
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.ext', delete=False) as f:
            f.write(ext_content)
            ext_file = f.name
        
        try:
            cmd = [
                "openssl", "x509",
                "-req",
                "-in", str(csr_path),
                "-CA", str(ca_cert),
                "-CAkey", str(ca_key),
                "-CAcreateserial",
                "-out", str(cert_path),
                "-days", "365",
                "-sha256",
                "-extensions", "v3_req",
                "-extfile", ext_file
            ]
            
            # CA-Key-Passwort eingeben (falls verschlüsselt)
            ca_password = os.environ.get("CA_PRIVATE_KEY_PASSWORD", "")
            
            result = subprocess.run(
                cmd, 
                input=ca_password, 
                capture_output=True, 
                text=True
            )
            
            if result.returncode != 0:
                raise Exception(f"Certificate signing failed: {result.stderr}")
                
        finally:
            os.unlink(ext_file)
    
    def verify_certificate(self, cert_path: str) -> dict:
        """Verifiziert Certificate-Details"""
        cmd = [
            "openssl", "x509",
            "-in", cert_path,
            "-text",
            "-noout"
        ]
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"Certificate verification failed: {result.stderr}")
        
        # Certificate-Details extrahieren
        cert_info = self._parse_certificate_info(result.stdout)
        return cert_info
    
    def _parse_certificate_info(self, cert_text: str) -> dict:
        """Parsed Certificate-Informationen"""
        info = {
            "subject": None,
            "issuer": None,
            "serial_number": None,
            "not_before": None,
            "not_after": None,
            "subject_alt_names": []
        }
        
        for line in cert_text.split('\n'):
            line = line.strip()
            
            if line.startswith('Subject:'):
                info["subject"] = line.replace('Subject: ', '')
            elif line.startswith('Issuer:'):
                info["issuer"] = line.replace('Issuer: ', '')
            elif line.startswith('Serial Number:'):
                info["serial_number"] = line.replace('Serial Number: ', '')
            elif line.startswith('Not Before:'):
                info["not_before"] = line.replace('Not Before: ', '')
            elif line.startswith('Not After :'):
                info["not_after"] = line.replace('Not After : ', '')
            elif 'DNS:' in line or 'IP Address:' in line:
                # SAN-Einträge extrahieren
                san_entries = line.replace('DNS:', '').replace('IP Address:', '').split(', ')
                info["subject_alt_names"].extend([entry.strip() for entry in san_entries if entry.strip()])
        
        return info

# High-Level Certificate-Setup
class CertificateSetupManager:
    def __init__(self):
        self.cert_manager = SelfSignedCertificateManager()
        
    def setup_certificates_for_deployment(self, deployment_mode: DeploymentMode, custom_domains: List[str] = None) -> dict:
        """Setup von Certificates basierend auf Deployment-Modus"""
        
        config = SSL_CONFIGURATIONS[deployment_mode]
        domains = custom_domains or config.domains
        
        if config.certificate_type == CertificateType.SELF_SIGNED:
            return self._setup_self_signed_certificates(config, domains)
        elif config.certificate_type == CertificateType.LETS_ENCRYPT:
            return self._setup_lets_encrypt_certificates(config, domains)
        else:
            raise ValueError(f"Unsupported certificate type: {config.certificate_type}")
    
    def _setup_self_signed_certificates(self, config: SSLConfiguration, domains: List[str]) -> dict:
        """Setup Self-signed Certificates"""
        
        cert_name = "aktienanalyse-" + config.deployment_mode.value.replace("_", "-")
        
        cert_path, key_path = self.cert_manager.generate_server_certificate(domains, cert_name)
        
        # Certificate-Info für Logging
        cert_info = self.cert_manager.verify_certificate(cert_path)
        
        logger.info(f"Self-signed certificate generated: {cert_path}")
        logger.info(f"Certificate valid until: {cert_info['not_after']}")
        logger.info(f"Subject Alternative Names: {cert_info['subject_alt_names']}")
        
        return {
            "certificate_path": cert_path,
            "private_key_path": key_path,
            "ca_bundle_path": config.ca_bundle_path,
            "certificate_type": "self_signed",
            "domains": domains,
            "expires_at": cert_info["not_after"]
        }
    
    def _setup_lets_encrypt_certificates(self, config: SSLConfiguration, domains: List[str]) -> dict:
        """Setup Let's Encrypt Certificates"""
        # Let's Encrypt Setup (für zukünftige externe Domain-Nutzung)
        
        domain = domains[0]  # Haupt-Domain
        
        # Certbot-Command
        cmd = [
            "certbot", "certonly",
            "--standalone",
            "--email", "admin@aktienanalyse.local",
            "--agree-tos",
            "--non-interactive",
            "-d", domain
        ]
        
        # Zusätzliche Domains
        for additional_domain in domains[1:]:
            cmd.extend(["-d", additional_domain])
        
        result = subprocess.run(cmd, capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"Let's Encrypt certificate generation failed: {result.stderr}")
        
        cert_path = f"/etc/letsencrypt/live/{domain}/fullchain.pem"
        key_path = f"/etc/letsencrypt/live/{domain}/privkey.pem"
        
        logger.info(f"Let's Encrypt certificate generated: {cert_path}")
        
        return {
            "certificate_path": cert_path,
            "private_key_path": key_path,
            "ca_bundle_path": None,
            "certificate_type": "lets_encrypt",
            "domains": domains,
            "auto_renewal": True
        }
```

### 2.2 **Certificate-Setup-Script**
```bash
#!/bin/bash
# scripts/setup-ssl-certificates.sh

set -euo pipefail

DEPLOYMENT_MODE=${1:-"local_only"}
CUSTOM_DOMAINS=${2:-""}

echo "🔒 Setting up SSL certificates for deployment mode: $DEPLOYMENT_MODE"

# Python-Script für Certificate-Generation aufrufen
python3 << EOF
import sys
import os
sys.path.append('/home/mdoehler/aktienanalyse-ökosystem/shared/utils')

from certificate_manager import CertificateSetupManager, DeploymentMode

# Deployment-Mode parsen
deployment_mode = DeploymentMode("$DEPLOYMENT_MODE")

# Custom-Domains parsen
custom_domains = []
if "$CUSTOM_DOMAINS":
    custom_domains = "$CUSTOM_DOMAINS".split(",")

# Certificate-Setup
setup_manager = CertificateSetupManager()
result = setup_manager.setup_certificates_for_deployment(deployment_mode, custom_domains)

print(f"✅ Certificate setup completed:")
print(f"  Certificate: {result['certificate_path']}")
print(f"  Private Key: {result['private_key_path']}")
print(f"  Domains: {', '.join(result['domains'])}")
print(f"  Type: {result['certificate_type']}")

# Environment-File aktualisieren
with open('.env', 'a') as f:
    f.write(f"\n# SSL Certificate Configuration\n")
    f.write(f"SSL_CERTIFICATE_PATH={result['certificate_path']}\n")
    f.write(f"SSL_PRIVATE_KEY_PATH={result['private_key_path']}\n")
    f.write(f"SSL_CA_BUNDLE_PATH={result.get('ca_bundle_path', '')}\n")
    f.write(f"SSL_DOMAINS={','.join(result['domains'])}\n")

EOF

echo "✅ SSL certificate setup completed"
echo "Certificate paths have been added to .env file"
```

---

## 🌐 **3. NGINX/REVERSE-PROXY-KONFIGURATION**

### 3.1 **NGINX SSL-Konfiguration**
```nginx
# /etc/nginx/sites-available/aktienanalyse-ssl
server {
    listen 80;
    server_name localhost aktienanalyse.local 10.1.1.120;
    
    # HTTP zu HTTPS Redirect
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name localhost aktienanalyse.local 10.1.1.120;
    
    # SSL-Zertifikat-Konfiguration
    ssl_certificate     /etc/ssl/certs/aktienanalyse-local-only.crt;
    ssl_certificate_key /etc/ssl/private/aktienanalyse-local-only.key;
    
    # SSL-Security-Konfiguration
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256;
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security-Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; font-src 'self'; img-src 'self' data:; connect-src 'self' wss:;" always;
    
    # Frontend-Service Proxy
    location / {
        proxy_pass http://frontend-service:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
        
        # WebSocket-Support für Real-time-Updates
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }
    
    # API-Gateway-Proxy (Intelligent-Core-Service)
    location /api/ {
        proxy_pass http://intelligent-core-service:8001;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # API-spezifische Headers
        proxy_set_header X-API-Gateway "nginx";
        proxy_read_timeout 60s;
        proxy_connect_timeout 60s;
    }
    
    # Health-Check-Endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }
    
    # Static-Assets-Optimierung
    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        access_log off;
    }
    
    # Logging
    access_log /var/log/nginx/aktienanalyse-access.log;
    error_log /var/log/nginx/aktienanalyse-error.log;
}

# Monitoring-Service (nur intern)
server {
    listen 8443 ssl;
    server_name localhost 127.0.0.1;
    
    ssl_certificate     /etc/ssl/certs/aktienanalyse-local-only.crt;
    ssl_certificate_key /etc/ssl/private/aktienanalyse-local-only.key;
    
    # Nur lokale Zugriffe erlauben
    allow 127.0.0.1;
    allow 10.1.1.0/24;
    deny all;
    
    location / {
        proxy_pass http://monitoring-service:8004;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

### 3.2 **Docker-Compose-Integration**
```yaml
# docker-compose.yml (NGINX-Service)
version: '3.8'

services:
  nginx-proxy:
    image: nginx:1.24-alpine
    container_name: aktienanalyse-nginx
    ports:
      - "80:80"
      - "443:443"
      - "8443:8443"  # Monitoring-Interface
    volumes:
      - ./config/nginx/aktienanalyse-ssl.conf:/etc/nginx/conf.d/default.conf
      - ./ssl/certs:/etc/ssl/certs:ro
      - ./ssl/private:/etc/ssl/private:ro
      - ./logs/nginx:/var/log/nginx
    depends_on:
      - frontend-service
      - intelligent-core-service
      - monitoring-service
    networks:
      - frontend
      - internal
    environment:
      - NGINX_ENVSUBST_TEMPLATE_SUFFIX=.template
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "https://localhost/health"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend-service:
    build: ./services/frontend-service
    container_name: aktienanalyse-frontend
    environment:
      - NODE_ENV=production
      - HTTPS_PROXY=true
      - TRUST_PROXY=true
    networks:
      - frontend
      - internal
    restart: unless-stopped

networks:
  frontend:
    driver: bridge
  internal:
    driver: bridge
    internal: true  # Keine externen Zugriffe auf interne Services
```

### 3.3 **Automated NGINX-Setup**
```python
class NGINXSSLSetup:
    def __init__(self, ssl_config: SSLConfiguration):
        self.ssl_config = ssl_config
        self.nginx_dir = Path("/etc/nginx")
        self.sites_available = self.nginx_dir / "sites-available"
        self.sites_enabled = self.nginx_dir / "sites-enabled"
        
    def generate_nginx_config(self) -> str:
        """Generiert NGINX-Konfiguration basierend auf SSL-Setup"""
        
        template = """
# Aktienanalyse-Ökosystem SSL Configuration
server {
    listen 80;
    server_name {{ domains }};
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name {{ domains }};
    
    # SSL Certificate Configuration
    ssl_certificate     {{ cert_path }};
    ssl_certificate_key {{ key_path }};
    {% if ca_bundle_path %}
    ssl_trusted_certificate {{ ca_bundle_path }};
    {% endif %}
    
    # SSL Security Configuration  
    ssl_protocols {{ tls_min_version }} TLSv1.3;
    ssl_ciphers {{ cipher_suites }};
    ssl_prefer_server_ciphers on;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    {% if hsts_enabled %}
    # HSTS (HTTP Strict Transport Security)
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    {% endif %}
    
    # Security Headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    
    # Frontend Proxy
    location / {
        proxy_pass http://frontend-service:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # API Gateway
    location /api/ {
        proxy_pass http://intelligent-core-service:8001;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Health Check
    location /health {
        access_log off;
        return 200 "healthy";
        add_header Content-Type text/plain;
    }
}
"""
        
        from jinja2 import Template
        template_obj = Template(template)
        
        return template_obj.render(
            domains=" ".join(self.ssl_config.domains),
            cert_path=self.ssl_config.certificate_path,
            key_path=self.ssl_config.private_key_path,
            ca_bundle_path=self.ssl_config.ca_bundle_path,
            tls_min_version=self.ssl_config.tls_version_min,
            cipher_suites=":".join(self.ssl_config.cipher_suites),
            hsts_enabled=self.ssl_config.hsts_enabled
        )
    
    def deploy_nginx_config(self):
        """Deployed NGINX-Konfiguration"""
        
        config_content = self.generate_nginx_config()
        
        # Konfiguration schreiben
        config_file = self.sites_available / "aktienanalyse-ssl"
        config_file.write_text(config_content)
        
        # Symlink für sites-enabled erstellen
        enabled_link = self.sites_enabled / "aktienanalyse-ssl"
        if enabled_link.exists():
            enabled_link.unlink()
        enabled_link.symlink_to(config_file)
        
        # Default-Site deaktivieren
        default_enabled = self.sites_enabled / "default"
        if default_enabled.exists():
            default_enabled.unlink()
        
        # NGINX-Konfiguration testen
        result = subprocess.run(["nginx", "-t"], capture_output=True, text=True)
        if result.returncode != 0:
            raise Exception(f"NGINX configuration test failed: {result.stderr}")
        
        # NGINX neu laden
        subprocess.run(["systemctl", "reload", "nginx"], check=True)
        
        logger.info("NGINX SSL configuration deployed and reloaded")
```

---

## 🔍 **4. CERTIFICATE-MONITORING**

### 4.1 **Certificate-Expiry-Monitoring**
```python
import ssl
import socket
from datetime import datetime, timedelta
from cryptography import x509
from cryptography.hazmat.backends import default_backend

class CertificateMonitor:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.alert_thresholds = {
            "warning_days": 30,   # Warnung 30 Tage vor Ablauf
            "critical_days": 7    # Kritischer Alert 7 Tage vor Ablauf
        }
    
    def check_certificate_expiry(self, cert_path: str) -> dict:
        """Prüft Certificate-Ablaufdatum"""
        
        try:
            with open(cert_path, 'rb') as cert_file:
                cert_data = cert_file.read()
                certificate = x509.load_pem_x509_certificate(cert_data, default_backend())
            
            # Ablaufdatum extrahieren
            not_after = certificate.not_valid_after
            now = datetime.utcnow()
            days_until_expiry = (not_after - now).days
            
            # Subject und SAN extrahieren
            subject = certificate.subject.rfc4514_string()
            
            san_extension = None
            try:
                san_extension = certificate.extensions.get_extension_for_oid(
                    x509.oid.ExtensionOID.SUBJECT_ALTERNATIVE_NAME
                ).value
                san_names = [name.value for name in san_extension]
            except x509.ExtensionNotFound:
                san_names = []
            
            return {
                "certificate_path": cert_path,
                "subject": subject,
                "san_names": san_names,
                "not_after": not_after.isoformat(),
                "days_until_expiry": days_until_expiry,
                "status": self._get_expiry_status(days_until_expiry)
            }
            
        except Exception as e:
            logger.error(f"Certificate check failed for {cert_path}: {str(e)}")
            return {
                "certificate_path": cert_path,
                "error": str(e),
                "status": "error"
            }
    
    def _get_expiry_status(self, days_until_expiry: int) -> str:
        """Bestimmt Expiry-Status basierend auf verbleibenden Tagen"""
        
        if days_until_expiry < 0:
            return "expired"
        elif days_until_expiry <= self.alert_thresholds["critical_days"]:
            return "critical"
        elif days_until_expiry <= self.alert_thresholds["warning_days"]:
            return "warning"
        else:
            return "valid"
    
    def check_ssl_connection(self, hostname: str, port: int = 443) -> dict:
        """Prüft SSL-Connection zu Service"""
        
        try:
            # SSL-Context erstellen
            context = ssl.create_default_context()
            
            # Für Self-signed Certificates: Verification deaktivieren
            context.check_hostname = False
            context.verify_mode = ssl.CERT_NONE
            
            # SSL-Connection
            with socket.create_connection((hostname, port), timeout=10) as sock:
                with context.wrap_socket(sock, server_hostname=hostname) as ssock:
                    cert_der = ssock.getpeercert_der()
                    certificate = x509.load_der_x509_certificate(cert_der, default_backend())
                    
                    # Certificate-Details
                    not_after = certificate.not_valid_after
                    now = datetime.utcnow()
                    days_until_expiry = (not_after - now).days
                    
                    return {
                        "hostname": hostname,
                        "port": port,
                        "ssl_version": ssock.version(),
                        "cipher": ssock.cipher(),
                        "not_after": not_after.isoformat(),
                        "days_until_expiry": days_until_expiry,
                        "status": self._get_expiry_status(days_until_expiry),
                        "connection_successful": True
                    }
                    
        except Exception as e:
            logger.error(f"SSL connection check failed for {hostname}:{port}: {str(e)}")
            return {
                "hostname": hostname,
                "port": port,
                "error": str(e),
                "connection_successful": False,
                "status": "error"
            }
    
    def monitor_all_certificates(self) -> List[dict]:
        """Monitort alle konfigurierten Certificates"""
        
        results = []
        
        # File-basierte Certificates prüfen
        cert_paths = [
            "/etc/ssl/certs/aktienanalyse-local-only.crt",
            "/etc/ssl/certs/aktienanalyse-lan.crt",
            "/etc/letsencrypt/live/aktienanalyse.example.com/fullchain.pem"
        ]
        
        for cert_path in cert_paths:
            if os.path.exists(cert_path):
                result = self.check_certificate_expiry(cert_path)
                results.append(result)
        
        # Live SSL-Connections prüfen
        ssl_endpoints = [
            ("localhost", 443),
            ("10.1.1.120", 443),
            ("aktienanalyse.local", 443)
        ]
        
        for hostname, port in ssl_endpoints:
            result = self.check_ssl_connection(hostname, port)
            results.append(result)
        
        # Ergebnisse in Redis für Zabbix speichern
        self._store_monitoring_results(results)
        
        return results
    
    def _store_monitoring_results(self, results: List[dict]):
        """Speichert Monitoring-Ergebnisse für Zabbix"""
        
        metrics = {}
        
        for result in results:
            if "certificate_path" in result:
                # File-basierte Certificate
                cert_name = os.path.basename(result["certificate_path"]).replace(".crt", "")
                metrics[f"cert_days_until_expiry_{cert_name}"] = result.get("days_until_expiry", -1)
                metrics[f"cert_status_{cert_name}"] = 1 if result.get("status") == "valid" else 0
            
            elif "hostname" in result:
                # SSL-Connection
                hostname = result["hostname"].replace(".", "_")
                metrics[f"ssl_connection_{hostname}"] = 1 if result.get("connection_successful") else 0
                metrics[f"ssl_days_until_expiry_{hostname}"] = result.get("days_until_expiry", -1)
        
        # In Redis speichern
        metrics_key = "zabbix:ssl_monitoring"
        for metric_name, value in metrics.items():
            self.redis.hset(metrics_key, metric_name, value)
        
        self.redis.expire(metrics_key, 300)  # 5 Minuten TTL

# Automated Monitoring-Job
def setup_certificate_monitoring():
    """Einrichtung automatisches Certificate-Monitoring"""
    
    monitor = CertificateMonitor(redis_client)
    
    # Tägliche Certificate-Prüfung
    schedule.every().day.at("06:00").do(monitor.monitor_all_certificates)
    
    # Wöchentlicher Report
    schedule.every().monday.at("09:00").do(generate_certificate_report)
    
    logger.info("Certificate monitoring scheduled")

def generate_certificate_report():
    """Generiert wöchentlichen Certificate-Report"""
    
    monitor = CertificateMonitor(redis_client)
    results = monitor.monitor_all_certificates()
    
    report = {
        "report_date": datetime.utcnow().isoformat(),
        "certificates": []
    }
    
    for result in results:
        if result.get("status") in ["warning", "critical", "expired"]:
            report["certificates"].append({
                "identifier": result.get("certificate_path", result.get("hostname")),
                "status": result["status"],
                "days_until_expiry": result.get("days_until_expiry"),
                "action_required": result["status"] in ["critical", "expired"]
            })
    
    if report["certificates"]:
        logger.warning(f"Certificate report: {json.dumps(report, indent=2)}")
        
        # Alert für kritische Certificates
        for cert in report["certificates"]:
            if cert["action_required"]:
                alert_data = {
                    "service": "ssl_certificates",
                    "message": f"Certificate action required: {cert['identifier']} ({cert['status']})",
                    "severity": "critical" if cert["status"] == "expired" else "warning",
                    "timestamp": datetime.utcnow().isoformat()
                }
                
                redis_client.publish("monitoring:alerts", json.dumps(alert_data))
```

### 4.2 **Zabbix-Integration für SSL-Monitoring**
```bash
#!/bin/bash
# /etc/zabbix/scripts/ssl_monitoring.sh

METRIC_NAME=$1

case $METRIC_NAME in
    "cert_days_until_expiry_"*)
        redis-cli -h redis-master HGET zabbix:ssl_monitoring $METRIC_NAME || echo -1
        ;;
    "cert_status_"*)
        redis-cli -h redis-master HGET zabbix:ssl_monitoring $METRIC_NAME || echo 0
        ;;
    "ssl_connection_"*)
        redis-cli -h redis-master HGET zabbix:ssl_monitoring $METRIC_NAME || echo 0
        ;;
    *)
        echo "Usage: $0 {cert_days_until_expiry_*|cert_status_*|ssl_connection_*}"
        exit 1
        ;;
esac
```

```conf
# /etc/zabbix/zabbix_agent2.d/ssl_monitoring.conf
UserParameter=aktienanalyse.ssl.cert.expiry[*],/etc/zabbix/scripts/ssl_monitoring.sh cert_days_until_expiry_$1
UserParameter=aktienanalyse.ssl.cert.status[*],/etc/zabbix/scripts/ssl_monitoring.sh cert_status_$1
UserParameter=aktienanalyse.ssl.connection[*],/etc/zabbix/scripts/ssl_monitoring.sh ssl_connection_$1
```

---

## ✅ **5. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: CA-Setup und Certificate-Generierung (1-2 Tage)**
- [ ] Custom-CA für Self-signed Certificates einrichten
- [ ] Certificate-Generation-System implementieren
- [ ] Self-signed Certificates für alle Deployment-Modi generieren
- [ ] Certificate-Verification-Tools entwickeln

### **Phase 2: NGINX-SSL-Konfiguration (1-2 Tage)**
- [ ] NGINX-SSL-Konfiguration mit Security-Headers erstellen
- [ ] Docker-Compose-Integration für SSL-Proxy
- [ ] Automated NGINX-Config-Generation implementieren
- [ ] HTTP-zu-HTTPS-Redirects konfigurieren

### **Phase 3: Certificate-Monitoring (1 Tag)**
- [ ] Certificate-Expiry-Monitoring entwickeln
- [ ] SSL-Connection-Health-Checks implementieren
- [ ] Zabbix-Integration für SSL-Metrics
- [ ] Automated Certificate-Reports

### **Phase 4: Testing und Deployment (1 Tag)**
- [ ] SSL-Setup-Scripts erstellen und testen
- [ ] End-to-End-SSL-Tests durchführen
- [ ] Certificate-Rotation-Prozeduren dokumentieren
- [ ] Monitoring-Dashboards konfigurieren

**Gesamtaufwand**: 4-6 Tage
**Abhängigkeiten**: NGINX, Redis-Cluster, Zabbix-Integration

Diese Spezifikation bietet **production-ready HTTPS-Setup** mit automatischer Certificate-Generierung, Security-Headers und umfassendem Monitoring für die private Umgebung.