# 🔐 Authentication-Spezifikation - Simple Session-Based Auth

## 🎯 **Übersicht**

**Kontext**: Private Single-User-Umgebung (LXC Container, Benutzer: mdoehler)
**Ziel**: Einfache, sichere Authentication ohne Enterprise-Overhead
**Ansatz**: Linux-User-basierte Authentication mit Session-Management

---

## 🏗️ **1. LINUX-USER-AUTHENTICATION**

### 1.1 **Authentication-Mechanismus**
```python
# Kernel: Linux-User-Verification über PAM
import pwd
import spwd
import crypt
from pam import pam

class LinuxUserAuthenticator:
    def __init__(self):
        self.allowed_user = "mdoehler"
        self.use_pam = True  # Preferred method
        
    def authenticate(self, username: str, password: str) -> AuthResult:
        """
        Authentifiziert gegen Linux-System-User
        
        Returns:
            AuthResult mit success/failure und user_info
        """
        if username != self.allowed_user:
            return AuthResult(success=False, reason="user_not_allowed")
            
        if self.use_pam:
            return self._authenticate_via_pam(username, password)
        else:
            return self._authenticate_via_shadow(username, password)
    
    def _authenticate_via_pam(self, username: str, password: str) -> AuthResult:
        """PAM-basierte Authentication (empfohlen)"""
        try:
            pam_auth = pam()
            if pam_auth.authenticate(username, password):
                user_info = self._get_user_info(username)
                return AuthResult(success=True, user=user_info)
            else:
                return AuthResult(success=False, reason="invalid_credentials")
        except Exception as e:
            return AuthResult(success=False, reason="pam_error", error=str(e))
    
    def _authenticate_via_shadow(self, username: str, password: str) -> AuthResult:
        """Shadow-File-basierte Authentication (Fallback)"""
        try:
            shadow_entry = spwd.getspnam(username)
            encrypted_password = shadow_entry.sp_pwdp
            
            # Verify password
            if crypt.crypt(password, encrypted_password) == encrypted_password:
                user_info = self._get_user_info(username)
                return AuthResult(success=True, user=user_info)
            else:
                return AuthResult(success=False, reason="invalid_credentials")
        except KeyError:
            return AuthResult(success=False, reason="user_not_found")
        except Exception as e:
            return AuthResult(success=False, reason="shadow_error", error=str(e))
    
    def _get_user_info(self, username: str) -> UserInfo:
        """Sammelt Linux-User-Informationen"""
        pwd_entry = pwd.getpwnam(username)
        return UserInfo(
            username=username,
            uid=pwd_entry.pw_uid,
            gid=pwd_entry.pw_gid,
            home_dir=pwd_entry.pw_dir,
            shell=pwd_entry.pw_shell,
            full_name=pwd_entry.pw_gecos.split(',')[0] if pwd_entry.pw_gecos else username
        )

@dataclass
class AuthResult:
    success: bool
    user: Optional[UserInfo] = None
    reason: Optional[str] = None
    error: Optional[str] = None

@dataclass
class UserInfo:
    username: str
    uid: int
    gid: int
    home_dir: str
    shell: str
    full_name: str
```

### 1.2 **Security-Überlegungen**
- **Privilege-Escalation**: Keine sudo-Rechte erforderlich für Authentication
- **Password-Policy**: Verwendet Linux-System-Password-Policy
- **Account-Lockout**: Linux-System-basierte Lockout-Mechanismen
- **Audit-Trail**: PAM-Logs in `/var/log/auth.log`

---

## 🍪 **2. SESSION-MANAGEMENT**

### 2.1 **Session-Konfiguration**
```python
from flask import Flask, session, request
from datetime import datetime, timedelta
import secrets
import redis

class SessionManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis = redis_client
        self.session_timeout = timedelta(hours=24)  # 24h für Convenience
        self.session_prefix = "aktienanalyse:session:"
        
    def create_session(self, user_info: UserInfo) -> SessionData:
        """Erstellt neue User-Session"""
        session_id = secrets.token_urlsafe(32)
        session_data = SessionData(
            session_id=session_id,
            user=user_info,
            created_at=datetime.utcnow(),
            last_activity=datetime.utcnow(),
            expires_at=datetime.utcnow() + self.session_timeout,
            ip_address=request.remote_addr,
            user_agent=request.headers.get('User-Agent', 'Unknown')
        )
        
        # Session in Redis speichern
        session_key = f"{self.session_prefix}{session_id}"
        session_json = session_data.to_json()
        self.redis.setex(
            session_key, 
            int(self.session_timeout.total_seconds()), 
            session_json
        )
        
        return session_data
    
    def validate_session(self, session_id: str) -> Optional[SessionData]:
        """Validiert und erneuert Session"""
        session_key = f"{self.session_prefix}{session_id}"
        session_json = self.redis.get(session_key)
        
        if not session_json:
            return None
            
        session_data = SessionData.from_json(session_json)
        
        # Session-Timeout prüfen
        if datetime.utcnow() > session_data.expires_at:
            self.invalidate_session(session_id)
            return None
        
        # Session-Aktivität aktualisieren
        session_data.last_activity = datetime.utcnow()
        session_data.expires_at = datetime.utcnow() + self.session_timeout
        
        # Aktualisierte Session speichern
        self.redis.setex(
            session_key,
            int(self.session_timeout.total_seconds()),
            session_data.to_json()
        )
        
        return session_data
    
    def invalidate_session(self, session_id: str) -> None:
        """Löscht Session (Logout)"""
        session_key = f"{self.session_prefix}{session_id}"
        self.redis.delete(session_key)
    
    def cleanup_expired_sessions(self) -> int:
        """Cleanup-Job für abgelaufene Sessions"""
        pattern = f"{self.session_prefix}*"
        expired_count = 0
        
        for key in self.redis.scan_iter(match=pattern):
            session_json = self.redis.get(key)
            if session_json:
                session_data = SessionData.from_json(session_json)
                if datetime.utcnow() > session_data.expires_at:
                    self.redis.delete(key)
                    expired_count += 1
        
        return expired_count

@dataclass
class SessionData:
    session_id: str
    user: UserInfo
    created_at: datetime
    last_activity: datetime
    expires_at: datetime
    ip_address: str
    user_agent: str
    
    def to_json(self) -> str:
        return json.dumps({
            'session_id': self.session_id,
            'user': asdict(self.user),
            'created_at': self.created_at.isoformat(),
            'last_activity': self.last_activity.isoformat(),
            'expires_at': self.expires_at.isoformat(),
            'ip_address': self.ip_address,
            'user_agent': self.user_agent
        })
    
    @classmethod
    def from_json(cls, json_str: str) -> 'SessionData':
        data = json.loads(json_str)
        return cls(
            session_id=data['session_id'],
            user=UserInfo(**data['user']),
            created_at=datetime.fromisoformat(data['created_at']),
            last_activity=datetime.fromisoformat(data['last_activity']),
            expires_at=datetime.fromisoformat(data['expires_at']),
            ip_address=data['ip_address'],
            user_agent=data['user_agent']
        )
```

### 2.2 **Cookie-Konfiguration**
```python
# Flask Session-Cookie-Konfiguration
app.config.update(
    SECRET_KEY=os.environ.get('SESSION_SECRET', secrets.token_hex(32)),
    SESSION_COOKIE_NAME='aktienanalyse_session',
    SESSION_COOKIE_HTTPONLY=True,  # XSS-Schutz
    SESSION_COOKIE_SECURE=True,    # Nur über HTTPS (außer Development)
    SESSION_COOKIE_SAMESITE='Lax', # CSRF-Schutz
    SESSION_COOKIE_DOMAIN=None,    # Nur diese Domain
    PERMANENT_SESSION_LIFETIME=timedelta(hours=24)
)

# Remember-Me-Funktion
def set_remember_me_cookie(response, user_id: str, remember: bool = False):
    """Setzt längerfristige Remember-Me-Cookie (30 Tage)"""
    if remember:
        remember_token = secrets.token_urlsafe(32)
        # Token in Redis speichern
        redis_client.setex(
            f"remember:{remember_token}",
            int(timedelta(days=30).total_seconds()),
            user_id
        )
        
        response.set_cookie(
            'remember_token',
            remember_token,
            max_age=int(timedelta(days=30).total_seconds()),
            httponly=True,
            secure=True,
            samesite='Lax'
        )
```

---

## 🔑 **3. API-TOKEN-SYSTEM**

### 3.1 **Service-zu-Service-Authentication**
```python
class APITokenManager:
    def __init__(self):
        self.static_api_key = os.environ.get('API_KEY', 'aktienanalyse_2025_private_key_mdoehler')
        self.token_header = 'X-API-Key'
        
    def generate_service_token(self, service_name: str) -> str:
        """Generiert Service-spezifische Tokens"""
        timestamp = int(datetime.utcnow().timestamp())
        payload = f"{service_name}:{timestamp}"
        
        # HMAC-basierte Token-Generierung
        import hmac
        import hashlib
        
        signature = hmac.new(
            self.static_api_key.encode(),
            payload.encode(),
            hashlib.sha256
        ).hexdigest()
        
        return f"{payload}:{signature}"
    
    def validate_service_token(self, token: str) -> Optional[str]:
        """Validiert Service-Token"""
        try:
            parts = token.split(':')
            if len(parts) != 3:
                return None
                
            service_name, timestamp_str, signature = parts
            timestamp = int(timestamp_str)
            
            # Token-Alter prüfen (max 1 Stunde)
            current_time = int(datetime.utcnow().timestamp())
            if current_time - timestamp > 3600:
                return None
            
            # Signature validieren
            payload = f"{service_name}:{timestamp_str}"
            expected_signature = hmac.new(
                self.static_api_key.encode(),
                payload.encode(),
                hashlib.sha256
            ).hexdigest()
            
            if signature == expected_signature:
                return service_name
            else:
                return None
                
        except (ValueError, AttributeError):
            return None

# Environment-Konfiguration
"""
# .env
API_KEY=aktienanalyse_2025_private_key_mdoehler_$(openssl rand -hex 16)
SESSION_SECRET=$(openssl rand -hex 32)

# Für Development
AUTO_LOGIN=false
REQUIRE_HTTPS=true
"""
```

---

## 🎨 **4. FRONTEND-INTEGRATION**

### 4.1 **Login-UI-Spezifikation**
```typescript
// React Login-Komponente
interface LoginFormProps {
  onLogin: (credentials: LoginCredentials) => Promise<void>;
  autoLoginEnabled?: boolean;
}

interface LoginCredentials {
  username: string;  // Fest: "mdoehler"
  password: string;
  rememberMe: boolean;
}

const LoginForm: React.FC<LoginFormProps> = ({ onLogin, autoLoginEnabled = false }) => {
  const [credentials, setCredentials] = useState<LoginCredentials>({
    username: 'mdoehler',  // Fest codiert
    password: '',
    rememberMe: false
  });
  
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Auto-Login für Development
  useEffect(() => {
    if (autoLoginEnabled && process.env.NODE_ENV === 'development') {
      // Prüft ob bereits eingeloggt via Session-Cookie
      checkExistingSession();
    }
  }, [autoLoginEnabled]);
  
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError(null);
    
    try {
      await onLogin(credentials);
    } catch (err) {
      setError(err.message || 'Login fehlgeschlagen');
    } finally {
      setLoading(false);
    }
  };
  
  return (
    <form onSubmit={handleSubmit} className="login-form">
      <div className="form-group">
        <label>Benutzer:</label>
        <input 
          type="text" 
          value={credentials.username}
          disabled  // Fest codiert auf mdoehler
          className="form-control"
        />
      </div>
      
      <div className="form-group">
        <label>Passwort:</label>
        <input 
          type="password"
          value={credentials.password}
          onChange={(e) => setCredentials({...credentials, password: e.target.value})}
          required
          className="form-control"
        />
      </div>
      
      <div className="form-group">
        <label>
          <input 
            type="checkbox"
            checked={credentials.rememberMe}
            onChange={(e) => setCredentials({...credentials, rememberMe: e.target.checked})}
          />
          30 Tage angemeldet bleiben
        </label>
      </div>
      
      {error && <div className="error-message">{error}</div>}
      
      <button type="submit" disabled={loading} className="btn-primary">
        {loading ? 'Anmelden...' : 'Anmelden'}
      </button>
    </form>
  );
};
```

### 4.2 **Session-State-Management**
```typescript
// React Session-Context
interface SessionContextType {
  user: UserInfo | null;
  isAuthenticated: boolean;
  login: (credentials: LoginCredentials) => Promise<void>;
  logout: () => Promise<void>;
  refreshSession: () => Promise<void>;
}

const SessionContext = createContext<SessionContextType | null>(null);

export const SessionProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserInfo | null>(null);
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  
  const login = async (credentials: LoginCredentials) => {
    const response = await fetch('/api/auth/login', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(credentials),
      credentials: 'include'  // Session-Cookies senden
    });
    
    if (!response.ok) {
      throw new Error('Login fehlgeschlagen');
    }
    
    const { user: userInfo } = await response.json();
    setUser(userInfo);
    setIsAuthenticated(true);
  };
  
  const logout = async () => {
    await fetch('/api/auth/logout', {
      method: 'POST',
      credentials: 'include'
    });
    
    setUser(null);
    setIsAuthenticated(false);
  };
  
  const refreshSession = async () => {
    try {
      const response = await fetch('/api/auth/session', {
        credentials: 'include'
      });
      
      if (response.ok) {
        const { user: userInfo } = await response.json();
        setUser(userInfo);
        setIsAuthenticated(true);
      } else {
        setUser(null);
        setIsAuthenticated(false);
      }
    } catch (err) {
      setUser(null);
      setIsAuthenticated(false);
    }
  };
  
  // Session-Check beim App-Start
  useEffect(() => {
    refreshSession();
  }, []);
  
  return (
    <SessionContext.Provider value={{ user, isAuthenticated, login, logout, refreshSession }}>
      {children}
    </SessionContext.Provider>
  );
};
```

---

## 🔧 **5. API-ENDPUNKTE**

### 5.1 **Authentication-API**
```python
from flask import Blueprint, request, jsonify, session
from werkzeug.exceptions import BadRequest, Unauthorized

auth_bp = Blueprint('auth', __name__, url_prefix='/api/auth')

@auth_bp.route('/login', methods=['POST'])
def login():
    """Login-Endpoint für Frontend"""
    data = request.get_json()
    
    if not data or 'username' not in data or 'password' not in data:
        raise BadRequest('Username und Password erforderlich')
    
    # Linux-User-Authentication
    authenticator = LinuxUserAuthenticator()
    auth_result = authenticator.authenticate(data['username'], data['password'])
    
    if not auth_result.success:
        # Security-Event loggen
        logger.warning(f"Failed login attempt for user {data['username']} from {request.remote_addr}")
        raise Unauthorized('Ungültige Anmeldedaten')
    
    # Session erstellen
    session_manager = SessionManager(redis_client)
    session_data = session_manager.create_session(auth_result.user)
    
    # Session-Cookie setzen
    response = jsonify({
        'success': True,
        'user': {
            'username': auth_result.user.username,
            'full_name': auth_result.user.full_name,
            'uid': auth_result.user.uid
        }
    })
    
    response.set_cookie(
        'session_id',
        session_data.session_id,
        max_age=int(timedelta(hours=24).total_seconds()),
        httponly=True,
        secure=request.is_secure,
        samesite='Lax'
    )
    
    # Remember-Me-Cookie falls gewünscht
    if data.get('rememberMe', False):
        set_remember_me_cookie(response, auth_result.user.username, True)
    
    # Success-Event loggen
    logger.info(f"Successful login for user {auth_result.user.username} from {request.remote_addr}")
    
    return response

@auth_bp.route('/logout', methods=['POST'])
def logout():
    """Logout-Endpoint"""
    session_id = request.cookies.get('session_id')
    
    if session_id:
        session_manager = SessionManager(redis_client)
        session_manager.invalidate_session(session_id)
    
    response = jsonify({'success': True})
    response.set_cookie('session_id', '', expires=0)
    response.set_cookie('remember_token', '', expires=0)
    
    logger.info(f"User logged out from {request.remote_addr}")
    
    return response

@auth_bp.route('/session', methods=['GET'])
def check_session():
    """Session-Validierung für Frontend"""
    session_id = request.cookies.get('session_id')
    
    if not session_id:
        raise Unauthorized('Keine Session gefunden')
    
    session_manager = SessionManager(redis_client)
    session_data = session_manager.validate_session(session_id)
    
    if not session_data:
        raise Unauthorized('Ungültige oder abgelaufene Session')
    
    return jsonify({
        'user': {
            'username': session_data.user.username,
            'full_name': session_data.user.full_name,
            'uid': session_data.user.uid
        },
        'session': {
            'created_at': session_data.created_at.isoformat(),
            'expires_at': session_data.expires_at.isoformat()
        }
    })
```

### 5.2 **Session-Middleware**
```python
from functools import wraps

def require_authentication(f):
    """Decorator für geschützte Endpoints"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        session_id = request.cookies.get('session_id')
        
        if not session_id:
            raise Unauthorized('Authentication erforderlich')
        
        session_manager = SessionManager(redis_client)
        session_data = session_manager.validate_session(session_id)
        
        if not session_data:
            raise Unauthorized('Ungültige Session')
        
        # User-Kontext für Request verfügbar machen
        g.current_user = session_data.user
        g.session_data = session_data
        
        return f(*args, **kwargs)
    
    return decorated_function

def require_api_key(f):
    """Decorator für Service-zu-Service-APIs"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        api_key = request.headers.get('X-API-Key')
        
        if not api_key:
            raise Unauthorized('API-Key erforderlich')
        
        token_manager = APITokenManager()
        service_name = token_manager.validate_service_token(api_key)
        
        if not service_name:
            raise Unauthorized('Ungültiger API-Key')
        
        g.service_name = service_name
        
        return f(*args, **kwargs)
    
    return decorated_function

# Beispiel-Nutzung
@app.route('/api/portfolio')
@require_authentication
def get_portfolio():
    """Geschützter Endpoint - nur für eingeloggte User"""
    user = g.current_user
    return jsonify({'portfolio': f'Portfolio für {user.username}'})

@app.route('/api/internal/health')
@require_api_key
def internal_health():
    """Service-zu-Service-Endpoint"""
    service = g.service_name
    return jsonify({'status': 'healthy', 'caller': service})
```

---

## 📋 **6. DEPLOYMENT-KONFIGURATION**

### 6.1 **Environment-Variablen**
```bash
# .env (Production)
NODE_ENV=production
SESSION_SECRET=$(openssl rand -hex 32)
API_KEY=aktienanalyse_2025_private_key_mdoehler_$(openssl rand -hex 16)
REDIS_CLUSTER_NODES=redis-master:6379,redis-slave1:6380,redis-slave2:6381

# Security-Settings
REQUIRE_HTTPS=true
AUTO_LOGIN=false
SESSION_TIMEOUT_HOURS=24
REMEMBER_ME_DAYS=30

# Logging
LOG_LEVEL=info
AUTH_LOG_FILE=/var/log/aktienanalyse/auth.log

# .env (Development)
NODE_ENV=development
AUTO_LOGIN=true  # Convenience für Development
REQUIRE_HTTPS=false
LOG_LEVEL=debug
```

### 6.2 **Docker-Service-Integration**
```yaml
# docker-compose.yml (Auth-relevante Teile)
version: '3.8'

services:
  frontend-service:
    build: ./services/frontend-service
    environment:
      - NODE_ENV=${NODE_ENV}
      - SESSION_SECRET=${SESSION_SECRET}
      - API_KEY=${API_KEY}
      - REQUIRE_HTTPS=${REQUIRE_HTTPS}
      - AUTO_LOGIN=${AUTO_LOGIN}
    volumes:
      - ./logs:/var/log/aktienanalyse
      - /etc/passwd:/etc/passwd:ro  # Für Linux-User-Lookup
      - /etc/shadow:/etc/shadow:ro  # Für Password-Verification
    depends_on:
      - redis-master
      - event-bus-service
    ports:
      - "3000:3000"

  redis-master:
    image: redis:7-alpine
    command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD}
    volumes:
      - redis_data:/data
```

---

## 🧪 **7. TESTING-STRATEGIE**

### 7.1 **Unit-Tests**
```python
import unittest
from unittest.mock import patch, MagicMock

class TestLinuxUserAuthenticator(unittest.TestCase):
    def setUp(self):
        self.auth = LinuxUserAuthenticator()
    
    @patch('pwd.getpwnam')
    @patch('spwd.getspnam')
    @patch('crypt.crypt')
    def test_successful_authentication(self, mock_crypt, mock_spwd, mock_pwd):
        # Test erfolgreiche Authentication
        mock_pwd.return_value = MagicMock(
            pw_uid=1000, pw_gid=1000, pw_dir='/home/mdoehler',
            pw_shell='/bin/bash', pw_gecos='Marco Doehler'
        )
        mock_spwd.return_value = MagicMock(sp_pwdp='$6$encrypted$hash')
        mock_crypt.return_value = '$6$encrypted$hash'
        
        result = self.auth.authenticate('mdoehler', 'correct_password')
        
        self.assertTrue(result.success)
        self.assertEqual(result.user.username, 'mdoehler')
        self.assertEqual(result.user.uid, 1000)
    
    def test_wrong_username(self):
        # Test falscher Username
        result = self.auth.authenticate('wrong_user', 'password')
        
        self.assertFalse(result.success)
        self.assertEqual(result.reason, 'user_not_allowed')
    
    @patch('spwd.getspnam')
    @patch('crypt.crypt')
    def test_wrong_password(self, mock_crypt, mock_spwd):
        # Test falsches Passwort
        mock_spwd.return_value = MagicMock(sp_pwdp='$6$encrypted$hash')
        mock_crypt.return_value = '$6$different$hash'
        
        result = self.auth.authenticate('mdoehler', 'wrong_password')
        
        self.assertFalse(result.success)
        self.assertEqual(result.reason, 'invalid_credentials')

class TestSessionManager(unittest.TestCase):
    def setUp(self):
        self.redis_mock = MagicMock()
        self.session_manager = SessionManager(self.redis_mock)
        self.user_info = UserInfo(
            username='mdoehler', uid=1000, gid=1000,
            home_dir='/home/mdoehler', shell='/bin/bash',
            full_name='Marco Doehler'
        )
    
    def test_create_session(self):
        # Test Session-Erstellung
        session_data = self.session_manager.create_session(self.user_info)
        
        self.assertIsNotNone(session_data.session_id)
        self.assertEqual(session_data.user.username, 'mdoehler')
        self.redis_mock.setex.assert_called_once()
    
    def test_validate_valid_session(self):
        # Test gültige Session-Validierung
        session_id = 'valid_session_id'
        session_json = '{"session_id": "valid_session_id", ...}'
        self.redis_mock.get.return_value = session_json
        
        # Mock SessionData.from_json
        with patch.object(SessionData, 'from_json') as mock_from_json:
            mock_session = MagicMock()
            mock_session.expires_at = datetime.utcnow() + timedelta(hours=1)
            mock_from_json.return_value = mock_session
            
            result = self.session_manager.validate_session(session_id)
            
            self.assertIsNotNone(result)
    
    def test_validate_expired_session(self):
        # Test abgelaufene Session
        session_id = 'expired_session_id'
        self.redis_mock.get.return_value = None
        
        result = self.session_manager.validate_session(session_id)
        
        self.assertIsNone(result)
```

### 7.2 **Integration-Tests**
```python
import pytest
from flask import Flask
from flask.testing import FlaskClient

@pytest.fixture
def app():
    app = Flask(__name__)
    app.config['TESTING'] = True
    app.config['SECRET_KEY'] = 'test_secret'
    # Registriere auth_bp
    app.register_blueprint(auth_bp)
    return app

@pytest.fixture
def client(app):
    return app.test_client()

def test_login_endpoint(client: FlaskClient):
    """Test Login-API-Endpoint"""
    # Erfolgreicher Login
    with patch('your_app.auth.LinuxUserAuthenticator') as mock_auth:
        mock_auth.return_value.authenticate.return_value = AuthResult(
            success=True,
            user=UserInfo(username='mdoehler', uid=1000, ...)
        )
        
        response = client.post('/api/auth/login', json={
            'username': 'mdoehler',
            'password': 'correct_password'
        })
        
        assert response.status_code == 200
        assert response.json['success'] is True
        assert 'session_id' in response.headers.get('Set-Cookie', '')

def test_protected_endpoint(client: FlaskClient):
    """Test geschützter Endpoint"""
    # Ohne Session
    response = client.get('/api/portfolio')
    assert response.status_code == 401
    
    # Mit gültiger Session
    with client.session_transaction() as sess:
        sess['user_id'] = 'mdoehler'
    
    response = client.get('/api/portfolio')
    assert response.status_code == 200
```

---

## 📊 **8. MONITORING & LOGGING**

### 8.1 **Security-Logging**
```python
import logging
import json
from datetime import datetime

class SecurityLogger:
    def __init__(self):
        self.logger = logging.getLogger('security')
        self.logger.setLevel(logging.INFO)
        
        # File-Handler für Security-Events
        handler = logging.FileHandler('/var/log/aktienanalyse/security.log')
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)
    
    def log_login_attempt(self, username: str, success: bool, ip_address: str, user_agent: str):
        """Loggt Login-Versuche"""
        event = {
            'event_type': 'login_attempt',
            'username': username,
            'success': success,
            'ip_address': ip_address,
            'user_agent': user_agent,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        level = logging.INFO if success else logging.WARNING
        self.logger.log(level, f"Login attempt: {json.dumps(event)}")
    
    def log_session_event(self, event_type: str, session_id: str, username: str, details: dict = None):
        """Loggt Session-Events"""
        event = {
            'event_type': event_type,
            'session_id': session_id[:8] + '...',  # Gekürzt für Privacy
            'username': username,
            'timestamp': datetime.utcnow().isoformat(),
            'details': details or {}
        }
        
        self.logger.info(f"Session event: {json.dumps(event)}")
    
    def log_api_access(self, endpoint: str, method: str, user: str, success: bool):
        """Loggt API-Zugriffe"""
        event = {
            'event_type': 'api_access',
            'endpoint': endpoint,
            'method': method,
            'user': user,
            'success': success,
            'timestamp': datetime.utcnow().isoformat()
        }
        
        self.logger.info(f"API access: {json.dumps(event)}")

# Usage
security_logger = SecurityLogger()

# In login endpoint:
security_logger.log_login_attempt(
    username=data['username'],
    success=auth_result.success,
    ip_address=request.remote_addr,
    user_agent=request.headers.get('User-Agent', 'Unknown')
)
```

### 8.2 **Zabbix-Integration**
```python
# Zabbix-Metrics für Authentication
class AuthMetrics:
    def __init__(self, redis_client):
        self.redis = redis_client
        self.metrics_key = "aktienanalyse:auth:metrics"
    
    def increment_login_attempts(self, success: bool):
        """Zählt Login-Versuche"""
        metric = "successful_logins" if success else "failed_logins"
        self.redis.hincrby(self.metrics_key, metric, 1)
    
    def update_active_sessions(self, count: int):
        """Aktualisiert Anzahl aktiver Sessions"""
        self.redis.hset(self.metrics_key, "active_sessions", count)
    
    def get_metrics_for_zabbix(self) -> dict:
        """Gibt Metrics für Zabbix zurück"""
        metrics = self.redis.hgetall(self.metrics_key)
        return {
            'successful_logins': int(metrics.get('successful_logins', 0)),
            'failed_logins': int(metrics.get('failed_logins', 0)),
            'active_sessions': int(metrics.get('active_sessions', 0)),
            'last_updated': datetime.utcnow().isoformat()
        }

# Zabbix User Parameter Script
"""
#!/bin/bash
# /etc/zabbix/scripts/auth_metrics.sh

case $1 in
    "successful_logins")
        redis-cli -h redis-master HGET aktienanalyse:auth:metrics successful_logins || echo 0
        ;;
    "failed_logins")
        redis-cli -h redis-master HGET aktienanalyse:auth:metrics failed_logins || echo 0
        ;;
    "active_sessions")
        redis-cli -h redis-master HGET aktienanalyse:auth:metrics active_sessions || echo 0
        ;;
    *)
        echo "Usage: $0 {successful_logins|failed_logins|active_sessions}"
        exit 1
        ;;
esac
"""
```

---

## ✅ **Implementierungs-Checklist**

### **Phase 1: Basis-Authentication (3-4 Tage)**
- [ ] Linux-User-Authenticator implementieren
- [ ] PAM-Integration testen
- [ ] Session-Manager mit Redis entwickeln
- [ ] Basis-Cookie-Handling implementieren

### **Phase 2: API-Integration (2-3 Tage)**
- [ ] Login/Logout-Endpoints erstellen
- [ ] Session-Middleware implementieren
- [ ] API-Token-System für Services
- [ ] Frontend-Integration entwickeln

### **Phase 3: Security & Monitoring (1-2 Tage)**
- [ ] Security-Logging implementieren
- [ ] Zabbix-Metrics-Integration
- [ ] Unit- und Integration-Tests
- [ ] Deployment-Konfiguration

**Gesamtaufwand**: 6-9 Tage
**Abhängigkeiten**: Redis-Cluster, Frontend-Service-Framework

Diese Spezifikation stellt eine **vollständige, implementierungsreife Authentication-Lösung** für die private Single-User-Umgebung bereit.