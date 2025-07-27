# 🛡️ Error-Handling & Resilience-Patterns - Spezifikation

## 🎯 **Übersicht**

**Kontext**: Native LXC-Services mit robusten Error-Handling und Resilience-Patterns
**Ziel**: Systemstabilität, Data-Integrity und Graceful-Degradation
**Ansatz**: Multi-Layer-Error-Handling mit Event-Sourcing und Compensation-Patterns

---

## 🏗️ **1. EXCEPTION-HANDLING-STANDARDS**

### 1.1 **Error-Category-Hierarchie**
```python
# shared/errors/error_categories.py
from enum import Enum
from typing import Dict, Optional, Any
import traceback
from datetime import datetime

class ErrorSeverity(Enum):
    LOW = "low"           # Warnung, System funktioniert weiter
    MEDIUM = "medium"     # Teilfunktion beeinträchtigt
    HIGH = "high"         # Service-Degradation
    CRITICAL = "critical" # System-Ausfall oder Data-Corruption-Risiko

class ErrorCategory(Enum):
    # Business Logic Errors
    BUSINESS_RULE_VIOLATION = "business_rule_violation"
    INSUFFICIENT_FUNDS = "insufficient_funds"
    TRADING_LIMIT_EXCEEDED = "trading_limit_exceeded"
    ASSET_NOT_TRADEABLE = "asset_not_tradeable"
    MARKET_CLOSED = "market_closed"
    
    # Technical Errors
    DATABASE_CONNECTION = "database_connection"
    EXTERNAL_API_FAILURE = "external_api_failure"
    NETWORK_TIMEOUT = "network_timeout"
    AUTHENTICATION_FAILED = "authentication_failed"
    AUTHORIZATION_DENIED = "authorization_denied"
    
    # Data Errors
    DATA_VALIDATION_FAILED = "data_validation_failed"
    DATA_CORRUPTION = "data_corruption"
    SCHEMA_MISMATCH = "schema_mismatch"
    
    # System Errors
    RESOURCE_EXHAUSTED = "resource_exhausted"
    SERVICE_UNAVAILABLE = "service_unavailable"
    CONFIGURATION_ERROR = "configuration_error"
    
    # Integration Errors
    BROKER_API_ERROR = "broker_api_error"
    PRICE_FEED_ERROR = "price_feed_error"
    EVENT_BUS_ERROR = "event_bus_error"

class ErrorRecoveryStrategy(Enum):
    RETRY = "retry"                    # Mit Exponential Backoff
    CIRCUIT_BREAK = "circuit_break"    # Service temporär deaktivieren
    FALLBACK = "fallback"              # Alternative Datenquelle/Service
    COMPENSATE = "compensate"          # Rollback-Transaction
    ALERT_ONLY = "alert_only"          # Nur loggen und weiter
    FAIL_FAST = "fail_fast"            # Sofort abbrechen

class AktienAnalyseError(Exception):
    """Base-Exception für alle System-Fehler"""
    
    def __init__(
        self,
        message: str,
        category: ErrorCategory,
        severity: ErrorSeverity,
        recovery_strategy: ErrorRecoveryStrategy,
        context: Optional[Dict[str, Any]] = None,
        original_exception: Optional[Exception] = None
    ):
        super().__init__(message)
        self.message = message
        self.category = category
        self.severity = severity
        self.recovery_strategy = recovery_strategy
        self.context = context or {}
        self.original_exception = original_exception
        self.timestamp = datetime.utcnow()
        self.error_id = self._generate_error_id()
        self.traceback = traceback.format_exc() if original_exception else None
    
    def _generate_error_id(self) -> str:
        """Generiert eindeutige Error-ID für Tracking"""
        import uuid
        return f"ERR-{self.category.value.upper()}-{str(uuid.uuid4())[:8]}"
    
    def to_dict(self) -> Dict[str, Any]:
        """Serialisiert Error für Logging/Monitoring"""
        return {
            "error_id": self.error_id,
            "message": self.message,
            "category": self.category.value,
            "severity": self.severity.value,
            "recovery_strategy": self.recovery_strategy.value,
            "context": self.context,
            "timestamp": self.timestamp.isoformat(),
            "traceback": self.traceback,
            "original_exception": str(self.original_exception) if self.original_exception else None
        }

# Spezifische Error-Klassen
class BusinessRuleViolationError(AktienAnalyseError):
    def __init__(self, rule_name: str, violation_details: str, context: Dict[str, Any] = None):
        super().__init__(
            message=f"Business Rule '{rule_name}' violated: {violation_details}",
            category=ErrorCategory.BUSINESS_RULE_VIOLATION,
            severity=ErrorSeverity.MEDIUM,
            recovery_strategy=ErrorRecoveryStrategy.ALERT_ONLY,
            context={"rule_name": rule_name, "violation_details": violation_details, **(context or {})}
        )

class TradingLimitExceededError(AktienAnalyseError):
    def __init__(self, limit_type: str, current_value: float, limit_value: float, context: Dict[str, Any] = None):
        super().__init__(
            message=f"Trading limit exceeded: {limit_type} = {current_value} > {limit_value}",
            category=ErrorCategory.TRADING_LIMIT_EXCEEDED,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.FAIL_FAST,
            context={
                "limit_type": limit_type,
                "current_value": current_value,
                "limit_value": limit_value,
                **(context or {})
            }
        )

class ExternalAPIError(AktienAnalyseError):
    def __init__(self, api_name: str, status_code: int, response_body: str, context: Dict[str, Any] = None):
        super().__init__(
            message=f"External API '{api_name}' failed: HTTP {status_code}",
            category=ErrorCategory.EXTERNAL_API_FAILURE,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.RETRY,
            context={
                "api_name": api_name,
                "status_code": status_code,
                "response_body": response_body,
                **(context or {})
            }
        )

class DatabaseConnectionError(AktienAnalyseError):
    def __init__(self, database_name: str, connection_string: str, context: Dict[str, Any] = None):
        super().__init__(
            message=f"Database connection failed: {database_name}",
            category=ErrorCategory.DATABASE_CONNECTION,
            severity=ErrorSeverity.CRITICAL,
            recovery_strategy=ErrorRecoveryStrategy.CIRCUIT_BREAK,
            context={
                "database_name": database_name,
                "connection_string": connection_string,
                **(context or {})
            }
        )

class DataValidationError(AktienAnalyseError):
    def __init__(self, field_name: str, invalid_value: Any, validation_rule: str, context: Dict[str, Any] = None):
        super().__init__(
            message=f"Data validation failed: {field_name} = '{invalid_value}' violates rule '{validation_rule}'",
            category=ErrorCategory.DATA_VALIDATION_FAILED,
            severity=ErrorSeverity.MEDIUM,
            recovery_strategy=ErrorRecoveryStrategy.FAIL_FAST,
            context={
                "field_name": field_name,
                "invalid_value": str(invalid_value),
                "validation_rule": validation_rule,
                **(context or {})
            }
        )
```

### 1.2 **Error-Handler-Decorator**
```python
# shared/decorators/error_handling.py
from functools import wraps
from typing import Callable, Type, List, Optional
import asyncio
import logging
from shared.errors.error_categories import AktienAnalyseError, ErrorRecoveryStrategy
from shared.monitoring.metrics import increment_error_counter

logger = logging.getLogger(__name__)

def handle_errors(
    expected_errors: List[Type[Exception]] = None,
    retry_on: List[Type[Exception]] = None,
    max_retries: int = 3,
    backoff_factor: float = 2.0,
    circuit_breaker_threshold: int = 5,
    fallback_function: Optional[Callable] = None
):
    """
    Decorator für robustes Error-Handling mit automatischen Recovery-Strategien
    
    Args:
        expected_errors: Liste der erwarteten Exception-Typen
        retry_on: Exception-Typen, bei denen Retry versucht wird
        max_retries: Maximale Anzahl Retry-Versuche
        backoff_factor: Exponential-Backoff-Faktor
        circuit_breaker_threshold: Anzahl Fehler bis Circuit-Breaker aktiviert
        fallback_function: Alternative Funktion bei persistenten Fehlern
    """
    
    def decorator(func: Callable):
        # Circuit-Breaker-State pro Funktion
        func._circuit_breaker_failures = 0
        func._circuit_breaker_open = False
        func._circuit_breaker_last_failure = None
        
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            # Circuit-Breaker Check
            if func._circuit_breaker_open:
                if _should_reset_circuit_breaker(func):
                    func._circuit_breaker_open = False
                    func._circuit_breaker_failures = 0
                    logger.info(f"Circuit breaker reset for {func.__name__}")
                else:
                    error = AktienAnalyseError(
                        message=f"Circuit breaker open for {func.__name__}",
                        category=ErrorCategory.SERVICE_UNAVAILABLE,
                        severity=ErrorSeverity.HIGH,
                        recovery_strategy=ErrorRecoveryStrategy.CIRCUIT_BREAK,
                        context={"function_name": func.__name__}
                    )
                    if fallback_function:
                        logger.warning(f"Using fallback for {func.__name__}: {error.message}")
                        return await fallback_function(*args, **kwargs)
                    raise error
            
            last_exception = None
            retry_count = 0
            
            while retry_count <= max_retries:
                try:
                    result = await func(*args, **kwargs)
                    
                    # Erfolgreicher Call - Circuit-Breaker-Failures zurücksetzen
                    if func._circuit_breaker_failures > 0:
                        func._circuit_breaker_failures = 0
                        logger.info(f"Function {func.__name__} recovered, resetting failure count")
                    
                    return result
                    
                except Exception as e:
                    last_exception = e
                    
                    # Error-Kategorisierung
                    if isinstance(e, AktienAnalyseError):
                        aktien_error = e
                    else:
                        # Unbekannte Exception -> kategorisieren
                        aktien_error = _categorize_unknown_exception(e, func.__name__)
                    
                    # Logging und Monitoring
                    logger.error(f"Error in {func.__name__}: {aktien_error.to_dict()}")
                    increment_error_counter(
                        function_name=func.__name__,
                        error_category=aktien_error.category.value,
                        severity=aktien_error.severity.value
                    )
                    
                    # Recovery-Strategy anwenden
                    if aktien_error.recovery_strategy == ErrorRecoveryStrategy.RETRY:
                        if retry_count < max_retries and (not retry_on or type(e) in retry_on):
                            retry_count += 1
                            delay = _calculate_backoff_delay(retry_count, backoff_factor)
                            logger.info(f"Retrying {func.__name__} in {delay}s (attempt {retry_count}/{max_retries})")
                            await asyncio.sleep(delay)
                            continue
                        else:
                            logger.error(f"Max retries exceeded for {func.__name__}")
                            
                    elif aktien_error.recovery_strategy == ErrorRecoveryStrategy.CIRCUIT_BREAK:
                        func._circuit_breaker_failures += 1
                        func._circuit_breaker_last_failure = datetime.utcnow()
                        
                        if func._circuit_breaker_failures >= circuit_breaker_threshold:
                            func._circuit_breaker_open = True
                            logger.error(f"Circuit breaker opened for {func.__name__} after {func._circuit_breaker_failures} failures")
                            
                    elif aktien_error.recovery_strategy == ErrorRecoveryStrategy.FALLBACK:
                        if fallback_function:
                            logger.warning(f"Using fallback for {func.__name__}: {aktien_error.message}")
                            return await fallback_function(*args, **kwargs)
                    
                    # Wenn keine Recovery möglich ist, Exception weiterwerfen
                    raise aktien_error
            
            # Falls alle Retries fehlgeschlagen sind
            raise last_exception
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # Sync-Version des Wrappers (vereinfacht)
            try:
                return func(*args, **kwargs)
            except Exception as e:
                if isinstance(e, AktienAnalyseError):
                    aktien_error = e
                else:
                    aktien_error = _categorize_unknown_exception(e, func.__name__)
                
                logger.error(f"Error in {func.__name__}: {aktien_error.to_dict()}")
                increment_error_counter(
                    function_name=func.__name__,
                    error_category=aktien_error.category.value,
                    severity=aktien_error.severity.value
                )
                raise aktien_error
        
        # Async oder Sync basierend auf Funktion
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator

def _calculate_backoff_delay(retry_count: int, backoff_factor: float) -> float:
    """Berechnet Exponential-Backoff-Delay"""
    return min(60.0, (backoff_factor ** retry_count) + (random.uniform(0, 1)))

def _should_reset_circuit_breaker(func) -> bool:
    """Prüft ob Circuit-Breaker zurückgesetzt werden soll (nach 60s)"""
    if not func._circuit_breaker_last_failure:
        return True
    
    time_since_failure = (datetime.utcnow() - func._circuit_breaker_last_failure).total_seconds()
    return time_since_failure > 60  # Reset nach 60 Sekunden

def _categorize_unknown_exception(exception: Exception, function_name: str) -> AktienAnalyseError:
    """Kategorisiert unbekannte Exceptions"""
    exception_type = type(exception).__name__
    
    # Mapping bekannter Exception-Typen
    if "Connection" in exception_type or "timeout" in str(exception).lower():
        return AktienAnalyseError(
            message=f"Connection/Timeout error in {function_name}: {str(exception)}",
            category=ErrorCategory.NETWORK_TIMEOUT,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.RETRY,
            context={"function_name": function_name, "original_exception_type": exception_type},
            original_exception=exception
        )
    elif "Permission" in exception_type or "Auth" in exception_type:
        return AktienAnalyseError(
            message=f"Authentication/Authorization error in {function_name}: {str(exception)}",
            category=ErrorCategory.AUTHENTICATION_FAILED,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.ALERT_ONLY,
            context={"function_name": function_name, "original_exception_type": exception_type},
            original_exception=exception
        )
    else:
        return AktienAnalyseError(
            message=f"Unknown error in {function_name}: {str(exception)}",
            category=ErrorCategory.SERVICE_UNAVAILABLE,
            severity=ErrorSeverity.MEDIUM,
            recovery_strategy=ErrorRecoveryStrategy.ALERT_ONLY,
            context={"function_name": function_name, "original_exception_type": exception_type},
            original_exception=exception
        )

# Beispiel-Verwendung
@handle_errors(
    retry_on=[ExternalAPIError, DatabaseConnectionError],
    max_retries=3,
    backoff_factor=2.0,
    circuit_breaker_threshold=5
)
async def fetch_asset_price(asset_symbol: str) -> float:
    """Beispiel-Funktion mit Error-Handling"""
    # Implementation hier
    pass
```

---

## ⚙️ **2. RETRY-MECHANISMS & CIRCUIT-BREAKERS**

### 2.1 **Advanced Retry-Manager**
```python
# shared/resilience/retry_manager.py
import asyncio
import random
from datetime import datetime, timedelta
from typing import Callable, List, Optional, Dict, Any
from dataclasses import dataclass
from enum import Enum

class RetryPolicy(Enum):
    FIXED_DELAY = "fixed_delay"
    EXPONENTIAL_BACKOFF = "exponential_backoff"
    LINEAR_BACKOFF = "linear_backoff"
    FIBONACCI_BACKOFF = "fibonacci_backoff"

@dataclass
class RetryConfiguration:
    max_attempts: int = 3
    base_delay: float = 1.0  # Sekunden
    max_delay: float = 60.0  # Sekunden
    policy: RetryPolicy = RetryPolicy.EXPONENTIAL_BACKOFF
    backoff_multiplier: float = 2.0
    jitter: bool = True  # Zufälliger Jitter zur Vermeidung von Thundering Herd
    retry_on_exceptions: List[type] = None
    stop_on_exceptions: List[type] = None

class RetryManager:
    def __init__(self):
        self.retry_stats: Dict[str, Dict[str, Any]] = {}
    
    async def execute_with_retry(
        self,
        func: Callable,
        config: RetryConfiguration,
        *args,
        **kwargs
    ):
        """Führt Funktion mit konfigurierbarem Retry aus"""
        
        function_name = func.__name__
        self._init_stats(function_name)
        
        last_exception = None
        
        for attempt in range(1, config.max_attempts + 1):
            try:
                start_time = datetime.utcnow()
                result = await func(*args, **kwargs)
                
                # Erfolgreiche Ausführung
                execution_time = (datetime.utcnow() - start_time).total_seconds()
                self._record_success(function_name, attempt, execution_time)
                
                return result
                
            except Exception as e:
                last_exception = e
                
                # Prüfen ob Retry erlaubt ist
                if not self._should_retry(e, config, attempt):
                    self._record_failure(function_name, attempt, str(e))
                    raise e
                
                # Delay berechnen und warten (außer beim letzten Versuch)
                if attempt < config.max_attempts:
                    delay = self._calculate_delay(attempt, config)
                    self._record_retry(function_name, attempt, str(e), delay)
                    
                    logger.info(f"Retry {attempt}/{config.max_attempts} for {function_name} in {delay:.2f}s: {str(e)}")
                    await asyncio.sleep(delay)
        
        # Alle Versuche fehlgeschlagen
        self._record_failure(function_name, config.max_attempts, str(last_exception))
        raise last_exception
    
    def _should_retry(self, exception: Exception, config: RetryConfiguration, attempt: int) -> bool:
        """Prüft ob Retry durchgeführt werden soll"""
        
        # Max attempts erreicht
        if attempt >= config.max_attempts:
            return False
        
        # Stop-Exceptions prüfen
        if config.stop_on_exceptions:
            for stop_exception in config.stop_on_exceptions:
                if isinstance(exception, stop_exception):
                    return False
        
        # Retry-Exceptions prüfen
        if config.retry_on_exceptions:
            for retry_exception in config.retry_on_exceptions:
                if isinstance(exception, retry_exception):
                    return True
            return False  # Nicht in retry_on_exceptions Liste
        
        # Default: Retry bei allen Exceptions außer Stop-Exceptions
        return True
    
    def _calculate_delay(self, attempt: int, config: RetryConfiguration) -> float:
        """Berechnet Retry-Delay basierend auf Policy"""
        
        if config.policy == RetryPolicy.FIXED_DELAY:
            delay = config.base_delay
            
        elif config.policy == RetryPolicy.EXPONENTIAL_BACKOFF:
            delay = config.base_delay * (config.backoff_multiplier ** (attempt - 1))
            
        elif config.policy == RetryPolicy.LINEAR_BACKOFF:
            delay = config.base_delay * attempt
            
        elif config.policy == RetryPolicy.FIBONACCI_BACKOFF:
            delay = config.base_delay * self._fibonacci(attempt)
        
        # Max-Delay begrenzen
        delay = min(delay, config.max_delay)
        
        # Jitter hinzufügen
        if config.jitter:
            jitter_range = delay * 0.1  # 10% Jitter
            delay += random.uniform(-jitter_range, jitter_range)
        
        return max(0, delay)
    
    def _fibonacci(self, n: int) -> int:
        """Berechnet Fibonacci-Zahl"""
        if n <= 1:
            return 1
        a, b = 1, 1
        for _ in range(2, n + 1):
            a, b = b, a + b
        return b
    
    def _init_stats(self, function_name: str):
        """Initialisiert Statistiken für Funktion"""
        if function_name not in self.retry_stats:
            self.retry_stats[function_name] = {
                "total_calls": 0,
                "successful_calls": 0,
                "failed_calls": 0,
                "total_retries": 0,
                "avg_execution_time": 0.0,
                "last_success": None,
                "last_failure": None
            }
    
    def _record_success(self, function_name: str, attempts: int, execution_time: float):
        """Zeichnet erfolgreiche Ausführung auf"""
        stats = self.retry_stats[function_name]
        stats["total_calls"] += 1
        stats["successful_calls"] += 1
        stats["total_retries"] += (attempts - 1)
        stats["last_success"] = datetime.utcnow()
        
        # Rolling Average für Execution Time
        current_avg = stats["avg_execution_time"]
        stats["avg_execution_time"] = (current_avg + execution_time) / 2
    
    def _record_retry(self, function_name: str, attempt: int, error: str, delay: float):
        """Zeichnet Retry-Versuch auf"""
        logger.debug(f"Retry attempt {attempt} for {function_name}: {error} (waiting {delay:.2f}s)")
    
    def _record_failure(self, function_name: str, attempts: int, error: str):
        """Zeichnet fehlgeschlagene Ausführung auf"""
        stats = self.retry_stats[function_name]
        stats["total_calls"] += 1
        stats["failed_calls"] += 1
        stats["total_retries"] += (attempts - 1)
        stats["last_failure"] = datetime.utcnow()
    
    def get_stats(self, function_name: str = None) -> Dict[str, Any]:
        """Gibt Retry-Statistiken zurück"""
        if function_name:
            return self.retry_stats.get(function_name, {})
        return self.retry_stats

# Global Retry Manager Instance
retry_manager = RetryManager()
```

### 2.2 **Circuit-Breaker-Implementation**
```python
# shared/resilience/circuit_breaker.py
from datetime import datetime, timedelta
from typing import Callable, Optional, Dict, Any
from enum import Enum
import asyncio

class CircuitBreakerState(Enum):
    CLOSED = "closed"        # Normal operation
    OPEN = "open"           # Circuit open, calls fail fast
    HALF_OPEN = "half_open" # Testing if service recovered

@dataclass
class CircuitBreakerConfig:
    failure_threshold: int = 5           # Anzahl Fehler bis Circuit öffnet
    recovery_timeout: int = 60           # Sekunden bis Half-Open-Test
    success_threshold: int = 3           # Erfolge in Half-Open bis Close
    timeout: float = 30.0               # Call-Timeout in Sekunden
    expected_exception: type = Exception # Exception-Typ der Circuit auslöst

class CircuitBreaker:
    def __init__(self, name: str, config: CircuitBreakerConfig):
        self.name = name
        self.config = config
        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        self.last_failure_time: Optional[datetime] = None
        self.last_success_time: Optional[datetime] = None
        self.call_count = 0
        self.total_failures = 0
        
    async def __call__(self, func: Callable, *args, **kwargs):
        """Führt Funktion mit Circuit-Breaker-Protection aus"""
        
        # State-Check und ggf. State-Transition
        self._update_state()
        
        if self.state == CircuitBreakerState.OPEN:
            raise CircuitBreakerOpenError(
                f"Circuit breaker '{self.name}' is OPEN",
                circuit_breaker_name=self.name,
                failure_count=self.failure_count,
                last_failure_time=self.last_failure_time
            )
        
        # Call mit Timeout ausführen
        try:
            self.call_count += 1
            result = await asyncio.wait_for(
                func(*args, **kwargs),
                timeout=self.config.timeout
            )
            
            # Erfolgreicher Call
            self._record_success()
            return result
            
        except asyncio.TimeoutError:
            error = CircuitBreakerTimeoutError(
                f"Circuit breaker '{self.name}' timeout after {self.config.timeout}s",
                circuit_breaker_name=self.name,
                timeout=self.config.timeout
            )
            self._record_failure(error)
            raise error
            
        except self.config.expected_exception as e:
            self._record_failure(e)
            raise e
    
    def _update_state(self):
        """Aktualisiert Circuit-Breaker-State basierend auf aktueller Situation"""
        
        if self.state == CircuitBreakerState.OPEN:
            # Prüfen ob Recovery-Timeout abgelaufen ist
            if (self.last_failure_time and 
                datetime.utcnow() - self.last_failure_time > timedelta(seconds=self.config.recovery_timeout)):
                self.state = CircuitBreakerState.HALF_OPEN
                self.success_count = 0
                logger.info(f"Circuit breaker '{self.name}' transitioned to HALF_OPEN")
        
        elif self.state == CircuitBreakerState.HALF_OPEN:
            # Prüfen ob genug Erfolge für CLOSED
            if self.success_count >= self.config.success_threshold:
                self.state = CircuitBreakerState.CLOSED
                self.failure_count = 0
                logger.info(f"Circuit breaker '{self.name}' transitioned to CLOSED")
    
    def _record_success(self):
        """Zeichnet erfolgreichen Call auf"""
        self.last_success_time = datetime.utcnow()
        
        if self.state == CircuitBreakerState.HALF_OPEN:
            self.success_count += 1
        elif self.state == CircuitBreakerState.CLOSED:
            # Reset failure count bei Erfolg in CLOSED state
            self.failure_count = max(0, self.failure_count - 1)
    
    def _record_failure(self, exception: Exception):
        """Zeichnet fehlgeschlagenen Call auf"""
        self.failure_count += 1
        self.total_failures += 1
        self.last_failure_time = datetime.utcnow()
        
        # Prüfen ob Circuit geöffnet werden soll
        if (self.state == CircuitBreakerState.CLOSED and 
            self.failure_count >= self.config.failure_threshold):
            self.state = CircuitBreakerState.OPEN
            logger.error(f"Circuit breaker '{self.name}' OPENED after {self.failure_count} failures")
        
        elif self.state == CircuitBreakerState.HALF_OPEN:
            # Ein Fehler in Half-Open -> zurück zu Open
            self.state = CircuitBreakerState.OPEN
            logger.warning(f"Circuit breaker '{self.name}' returned to OPEN from HALF_OPEN")
    
    def get_stats(self) -> Dict[str, Any]:
        """Gibt Circuit-Breaker-Statistiken zurück"""
        return {
            "name": self.name,
            "state": self.state.value,
            "failure_count": self.failure_count,
            "success_count": self.success_count,
            "call_count": self.call_count,
            "total_failures": self.total_failures,
            "last_failure_time": self.last_failure_time.isoformat() if self.last_failure_time else None,
            "last_success_time": self.last_success_time.isoformat() if self.last_success_time else None,
            "failure_rate": self.total_failures / max(1, self.call_count),
            "config": {
                "failure_threshold": self.config.failure_threshold,
                "recovery_timeout": self.config.recovery_timeout,
                "success_threshold": self.config.success_threshold,
                "timeout": self.config.timeout
            }
        }
    
    def reset(self):
        """Manueller Reset des Circuit-Breakers"""
        self.state = CircuitBreakerState.CLOSED
        self.failure_count = 0
        self.success_count = 0
        logger.info(f"Circuit breaker '{self.name}' manually reset")

class CircuitBreakerOpenError(AktienAnalyseError):
    def __init__(self, message: str, circuit_breaker_name: str, failure_count: int, last_failure_time: datetime):
        super().__init__(
            message=message,
            category=ErrorCategory.SERVICE_UNAVAILABLE,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.CIRCUIT_BREAK,
            context={
                "circuit_breaker_name": circuit_breaker_name,
                "failure_count": failure_count,
                "last_failure_time": last_failure_time.isoformat() if last_failure_time else None
            }
        )

class CircuitBreakerTimeoutError(AktienAnalyseError):
    def __init__(self, message: str, circuit_breaker_name: str, timeout: float):
        super().__init__(
            message=message,
            category=ErrorCategory.NETWORK_TIMEOUT,
            severity=ErrorSeverity.HIGH,
            recovery_strategy=ErrorRecoveryStrategy.RETRY,
            context={
                "circuit_breaker_name": circuit_breaker_name,
                "timeout": timeout
            }
        )

# Global Circuit Breaker Manager
class CircuitBreakerManager:
    def __init__(self):
        self.circuit_breakers: Dict[str, CircuitBreaker] = {}
    
    def get_circuit_breaker(self, name: str, config: CircuitBreakerConfig = None) -> CircuitBreaker:
        """Gibt Circuit-Breaker zurück oder erstellt neuen"""
        if name not in self.circuit_breakers:
            if not config:
                config = CircuitBreakerConfig()  # Default-Config
            self.circuit_breakers[name] = CircuitBreaker(name, config)
        return self.circuit_breakers[name]
    
    def get_all_stats(self) -> Dict[str, Dict[str, Any]]:
        """Gibt Statistiken aller Circuit-Breakers zurück"""
        return {name: cb.get_stats() for name, cb in self.circuit_breakers.items()}
    
    def reset_all(self):
        """Resettet alle Circuit-Breakers"""
        for cb in self.circuit_breakers.values():
            cb.reset()

# Global Instance
circuit_breaker_manager = CircuitBreakerManager()
```

---

## 📬 **3. DEAD-LETTER-QUEUES & FAILED-EVENT-HANDLING**

### 3.1 **Dead-Letter-Queue-Architecture**
```python
# shared/messaging/dead_letter_queue.py
import json
import redis
from datetime import datetime, timedelta
from typing import Dict, Any, List, Optional
from enum import Enum
from dataclasses import dataclass, asdict

class DLQReason(Enum):
    MAX_RETRIES_EXCEEDED = "max_retries_exceeded"
    VALIDATION_FAILED = "validation_failed"
    PROCESSING_TIMEOUT = "processing_timeout"
    UNKNOWN_EVENT_TYPE = "unknown_event_type"
    BUSINESS_RULE_VIOLATION = "business_rule_violation"
    INFRASTRUCTURE_ERROR = "infrastructure_error"

@dataclass
class FailedEvent:
    event_id: str
    original_event: Dict[str, Any]
    failure_reason: DLQReason
    error_message: str
    retry_count: int
    first_failure_time: datetime
    last_failure_time: datetime
    source_service: str
    target_service: str
    original_queue: str
    stack_trace: Optional[str] = None
    context: Optional[Dict[str, Any]] = None

class DeadLetterQueueManager:
    def __init__(self, redis_client: redis.Redis):
        self.redis_client = redis_client
        self.dlq_key_prefix = "dlq"
        self.dlq_index_key = "dlq:index"
        self.dlq_stats_key = "dlq:stats"
        
    async def send_to_dlq(
        self, 
        event: Dict[str, Any], 
        failure_reason: DLQReason,
        error_message: str,
        retry_count: int,
        source_service: str,
        target_service: str,
        original_queue: str,
        stack_trace: Optional[str] = None,
        context: Optional[Dict[str, Any]] = None
    ):
        """Sendet fehlgeschlagenes Event an Dead-Letter-Queue"""
        
        event_id = event.get('event_id') or self._generate_event_id()
        now = datetime.utcnow()
        
        failed_event = FailedEvent(
            event_id=event_id,
            original_event=event,
            failure_reason=failure_reason,
            error_message=error_message,
            retry_count=retry_count,
            first_failure_time=now,
            last_failure_time=now,
            source_service=source_service,
            target_service=target_service,
            original_queue=original_queue,
            stack_trace=stack_trace,
            context=context or {}
        )
        
        # In DLQ speichern
        dlq_key = f"{self.dlq_key_prefix}:{event_id}"
        await self.redis_client.hset(
            dlq_key, 
            mapping={
                "data": json.dumps(asdict(failed_event), default=str),
                "created_at": now.isoformat(),
                "status": "pending_review"
            }
        )
        
        # TTL setzen (30 Tage)
        await self.redis_client.expire(dlq_key, 30 * 24 * 60 * 60)
        
        # Index aktualisieren
        await self.redis_client.zadd(
            self.dlq_index_key,
            {event_id: now.timestamp()}
        )
        
        # Statistiken aktualisieren
        await self._update_dlq_stats(failure_reason, source_service, target_service)
        
        logger.error(f"Event {event_id} sent to DLQ: {failure_reason.value} - {error_message}")
        
        return failed_event
    
    async def get_dlq_events(
        self,
        limit: int = 100,
        offset: int = 0,
        filter_reason: Optional[DLQReason] = None,
        filter_service: Optional[str] = None,
        since: Optional[datetime] = None
    ) -> List[FailedEvent]:
        """Ruft Events aus Dead-Letter-Queue ab"""
        
        # Zeitfilter anwenden
        min_score = since.timestamp() if since else 0
        max_score = datetime.utcnow().timestamp()
        
        # Event-IDs aus Index abrufen
        event_ids = await self.redis_client.zrevrangebyscore(
            self.dlq_index_key,
            max_score,
            min_score,
            start=offset,
            num=limit
        )
        
        failed_events = []
        for event_id in event_ids:
            dlq_key = f"{self.dlq_key_prefix}:{event_id}"
            event_data = await self.redis_client.hget(dlq_key, "data")
            
            if event_data:
                failed_event_dict = json.loads(event_data)
                failed_event = FailedEvent(**failed_event_dict)
                
                # Filter anwenden
                if filter_reason and failed_event.failure_reason != filter_reason:
                    continue
                if filter_service and filter_service not in [failed_event.source_service, failed_event.target_service]:
                    continue
                
                failed_events.append(failed_event)
        
        return failed_events
    
    async def retry_failed_event(self, event_id: str) -> bool:
        """Versucht erneut ein fehlgeschlagenes Event zu verarbeiten"""
        
        dlq_key = f"{self.dlq_key_prefix}:{event_id}"
        event_data = await self.redis_client.hget(dlq_key, "data")
        
        if not event_data:
            logger.warning(f"Failed event {event_id} not found in DLQ")
            return False
        
        failed_event_dict = json.loads(event_data)
        failed_event = FailedEvent(**failed_event_dict)
        
        try:
            # Event zurück in originale Queue senden
            await self._requeue_event(failed_event)
            
            # Status aktualisieren
            await self.redis_client.hset(dlq_key, "status", "retried")
            await self.redis_client.hset(dlq_key, "retried_at", datetime.utcnow().isoformat())
            
            logger.info(f"Failed event {event_id} successfully retried")
            return True
            
        except Exception as e:
            logger.error(f"Failed to retry event {event_id}: {str(e)}")
            await self.redis_client.hset(dlq_key, "retry_error", str(e))
            return False
    
    async def mark_event_resolved(self, event_id: str, resolution_note: str = None):
        """Markiert Event als manuell gelöst"""
        
        dlq_key = f"{self.dlq_key_prefix}:{event_id}"
        await self.redis_client.hset(dlq_key, "status", "resolved")
        await self.redis_client.hset(dlq_key, "resolved_at", datetime.utcnow().isoformat())
        
        if resolution_note:
            await self.redis_client.hset(dlq_key, "resolution_note", resolution_note)
        
        logger.info(f"Failed event {event_id} marked as resolved: {resolution_note}")
    
    async def get_dlq_stats(self) -> Dict[str, Any]:
        """Ruft DLQ-Statistiken ab"""
        
        stats_data = await self.redis_client.hgetall(self.dlq_stats_key)
        
        # Default-Stats falls noch keine vorhanden
        if not stats_data:
            return {
                "total_failed_events": 0,
                "events_by_reason": {},
                "events_by_service": {},
                "retry_success_rate": 0.0,
                "last_updated": datetime.utcnow().isoformat()
            }
        
        # Decode Redis-Daten
        stats = {}
        for key, value in stats_data.items():
            try:
                stats[key.decode()] = json.loads(value.decode())
            except:
                stats[key.decode()] = value.decode()
        
        return stats
    
    async def cleanup_old_events(self, older_than_days: int = 30):
        """Bereinigt alte Events aus DLQ"""
        
        cutoff_time = datetime.utcnow() - timedelta(days=older_than_days)
        cutoff_score = cutoff_time.timestamp()
        
        # Alte Event-IDs finden
        old_event_ids = await self.redis_client.zrangebyscore(
            self.dlq_index_key,
            0,
            cutoff_score
        )
        
        cleanup_count = 0
        for event_id in old_event_ids:
            dlq_key = f"{self.dlq_key_prefix}:{event_id}"
            
            # Event und Index-Entry löschen
            await self.redis_client.delete(dlq_key)
            await self.redis_client.zrem(self.dlq_index_key, event_id)
            cleanup_count += 1
        
        logger.info(f"Cleaned up {cleanup_count} old DLQ events older than {older_than_days} days")
        return cleanup_count
    
    def _generate_event_id(self) -> str:
        """Generiert eindeutige Event-ID"""
        import uuid
        return f"failed-{uuid.uuid4()}"
    
    async def _requeue_event(self, failed_event: FailedEvent):
        """Sendet Event zurück in originale Queue"""
        # Implementation abhängig von Message-Queue-System (Redis Pub/Sub, RabbitMQ, etc.)
        # Hier Beispiel für Redis Pub/Sub
        
        await self.redis_client.publish(
            failed_event.original_queue,
            json.dumps(failed_event.original_event)
        )
    
    async def _update_dlq_stats(self, failure_reason: DLQReason, source_service: str, target_service: str):
        """Aktualisiert DLQ-Statistiken"""
        
        # Atomische Stats-Updates mit Redis HINCRBY
        await self.redis_client.hincrby(self.dlq_stats_key, "total_failed_events", 1)
        await self.redis_client.hincrby(self.dlq_stats_key, f"reason:{failure_reason.value}", 1)
        await self.redis_client.hincrby(self.dlq_stats_key, f"source:{source_service}", 1)
        await self.redis_client.hincrby(self.dlq_stats_key, f"target:{target_service}", 1)
        await self.redis_client.hset(self.dlq_stats_key, "last_updated", datetime.utcnow().isoformat())
```

### 3.2 **DLQ-Monitoring & Alerting**
```python
# shared/monitoring/dlq_monitor.py
from typing import Dict, List
import asyncio
from datetime import datetime, timedelta

class DLQMonitor:
    def __init__(self, dlq_manager: DeadLetterQueueManager):
        self.dlq_manager = dlq_manager
        self.alert_thresholds = {
            "critical_failure_rate": 0.1,  # 10% der Events in DLQ
            "max_events_per_hour": 100,
            "critical_reasons": [DLQReason.BUSINESS_RULE_VIOLATION, DLQReason.INFRASTRUCTURE_ERROR]
        }
        
    async def check_dlq_health(self) -> Dict[str, Any]:
        """Prüft DLQ-Health und gibt Alerts zurück"""
        
        stats = await self.dlq_manager.get_dlq_stats()
        alerts = []
        
        # 1. Hohe Anzahl neuer Events in letzter Stunde
        recent_events = await self.dlq_manager.get_dlq_events(
            since=datetime.utcnow() - timedelta(hours=1),
            limit=1000
        )
        
        if len(recent_events) > self.alert_thresholds["max_events_per_hour"]:
            alerts.append({
                "severity": "high",
                "type": "high_dlq_volume",
                "message": f"{len(recent_events)} events failed in last hour (threshold: {self.alert_thresholds['max_events_per_hour']})",
                "count": len(recent_events)
            })
        
        # 2. Kritische Failure-Reasons
        for event in recent_events:
            if event.failure_reason in self.alert_thresholds["critical_reasons"]:
                alerts.append({
                    "severity": "critical",
                    "type": "critical_failure_reason",
                    "message": f"Critical failure: {event.failure_reason.value} in {event.source_service}",
                    "event_id": event.event_id,
                    "service": event.source_service,
                    "reason": event.failure_reason.value
                })
        
        # 3. Service-spezifische Patterns
        service_failures = {}
        for event in recent_events:
            service_failures.setdefault(event.source_service, 0)
            service_failures[event.source_service] += 1
        
        for service, count in service_failures.items():
            if count > 20:  # Mehr als 20 Failures pro Service pro Stunde
                alerts.append({
                    "severity": "medium",
                    "type": "service_degradation",
                    "message": f"Service {service} has {count} failed events in last hour",
                    "service": service,
                    "count": count
                })
        
        return {
            "timestamp": datetime.utcnow().isoformat(),
            "total_recent_failures": len(recent_events),
            "alerts": alerts,
            "stats": stats,
            "service_failures": service_failures
        }
    
    async def auto_retry_eligible_events(self) -> Dict[str, Any]:
        """Versucht automatisch Events zu retried die retry-fähig sind"""
        
        # Events der letzten 24h die retry-fähig sind
        retry_eligible_events = await self.dlq_manager.get_dlq_events(
            since=datetime.utcnow() - timedelta(hours=24),
            limit=1000
        )
        
        retry_results = {
            "attempted": 0,
            "successful": 0,
            "failed": 0,
            "details": []
        }
        
        for event in retry_eligible_events:
            # Nur Events retried die durch temporäre Probleme fehlgeschlagen sind
            if event.failure_reason in [
                DLQReason.PROCESSING_TIMEOUT,
                DLQReason.INFRASTRUCTURE_ERROR
            ] and event.retry_count < 3:  # Max 3 auto-retries
                
                retry_results["attempted"] += 1
                
                success = await self.dlq_manager.retry_failed_event(event.event_id)
                if success:
                    retry_results["successful"] += 1
                else:
                    retry_results["failed"] += 1
                
                retry_results["details"].append({
                    "event_id": event.event_id,
                    "success": success,
                    "reason": event.failure_reason.value
                })
        
        return retry_results

# DLQ-Integration in Event-Handler
class EventProcessor:
    def __init__(self, dlq_manager: DeadLetterQueueManager):
        self.dlq_manager = dlq_manager
        
    async def process_event(self, event: Dict[str, Any], source_queue: str):
        """Verarbeitet Event mit DLQ-Integration"""
        
        try:
            # Event-Verarbeitung
            await self._handle_event(event)
            
        except BusinessRuleViolationError as e:
            # Business-Rule-Violations gehen sofort in DLQ
            await self.dlq_manager.send_to_dlq(
                event=event,
                failure_reason=DLQReason.BUSINESS_RULE_VIOLATION,
                error_message=str(e),
                retry_count=0,
                source_service=event.get('source_service', 'unknown'),
                target_service=self.__class__.__name__,
                original_queue=source_queue,
                stack_trace=e.traceback
            )
            
        except DataValidationError as e:
            # Validierungsfehler gehen in DLQ
            await self.dlq_manager.send_to_dlq(
                event=event,
                failure_reason=DLQReason.VALIDATION_FAILED,
                error_message=str(e),
                retry_count=0,
                source_service=event.get('source_service', 'unknown'),
                target_service=self.__class__.__name__,
                original_queue=source_queue,
                stack_trace=e.traceback
            )
            
        except Exception as e:
            # Andere Fehler werden als Infrastructure-Error behandelt
            retry_count = event.get('retry_count', 0)
            
            if retry_count >= 3:  # Max retries erreicht
                await self.dlq_manager.send_to_dlq(
                    event=event,
                    failure_reason=DLQReason.MAX_RETRIES_EXCEEDED,
                    error_message=str(e),
                    retry_count=retry_count,
                    source_service=event.get('source_service', 'unknown'),
                    target_service=self.__class__.__name__,
                    original_queue=source_queue,
                    stack_trace=traceback.format_exc()
                )
            else:
                # Event für Retry markieren
                event['retry_count'] = retry_count + 1
                raise e  # Für Retry-Mechanism
    
    async def _handle_event(self, event: Dict[str, Any]):
        """Eigentliche Event-Verarbeitung"""
        # Implementation hier
        pass
```

---

## 🔄 **4. SAGA-PATTERN & DISTRIBUTED-TRANSACTIONS**

### 4.1 **Saga-Orchestrator**
```python
# shared/saga/saga_orchestrator.py
from typing import Dict, List, Optional, Any, Callable
from enum import Enum
from dataclasses import dataclass, field
from datetime import datetime
import json
import asyncio

class SagaStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    COMPENSATING = "compensating"
    COMPENSATED = "compensated"

class StepStatus(Enum):
    PENDING = "pending"
    RUNNING = "running"
    COMPLETED = "completed"
    FAILED = "failed"
    COMPENSATING = "compensating"
    COMPENSATED = "compensated"
    SKIPPED = "skipped"

@dataclass
class SagaStep:
    step_id: str
    name: str
    action: Callable[..., Any]
    compensation: Callable[..., Any]
    status: StepStatus = StepStatus.PENDING
    result: Optional[Any] = None
    error: Optional[str] = None
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    retry_count: int = 0
    max_retries: int = 3
    timeout_seconds: int = 30
    depends_on: List[str] = field(default_factory=list)
    context_updates: Dict[str, Any] = field(default_factory=dict)

@dataclass
class SagaDefinition:
    saga_id: str
    name: str
    steps: List[SagaStep]
    initial_context: Dict[str, Any] = field(default_factory=dict)
    timeout_seconds: int = 300  # 5 Minuten Default
    
class SagaOrchestrator:
    def __init__(self, event_bus, persistence_manager):
        self.event_bus = event_bus
        self.persistence = persistence_manager
        self.running_sagas: Dict[str, 'SagaExecution'] = {}
        
    async def start_saga(self, saga_definition: SagaDefinition) -> str:
        """Startet neue Saga-Ausführung"""
        
        execution_id = f"{saga_definition.saga_id}-{datetime.utcnow().strftime('%Y%m%d-%H%M%S')}-{id(saga_definition)}"
        
        saga_execution = SagaExecution(
            execution_id=execution_id,
            definition=saga_definition,
            orchestrator=self
        )
        
        self.running_sagas[execution_id] = saga_execution
        
        # Saga-Started Event senden
        await self.event_bus.publish({
            "event_type": "saga_started",
            "saga_execution_id": execution_id,
            "saga_id": saga_definition.saga_id,
            "saga_name": saga_definition.name,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Asynchrone Ausführung starten
        asyncio.create_task(saga_execution.execute())
        
        return execution_id
    
    async def get_saga_status(self, execution_id: str) -> Optional[Dict[str, Any]]:
        """Ruft Status einer Saga-Ausführung ab"""
        
        saga_execution = self.running_sagas.get(execution_id)
        if not saga_execution:
            # Aus Persistence laden
            saga_data = await self.persistence.load_saga(execution_id)
            return saga_data
        
        return saga_execution.get_status()
    
    async def abort_saga(self, execution_id: str, reason: str = None):
        """Bricht laufende Saga ab und startet Compensation"""
        
        saga_execution = self.running_sagas.get(execution_id)
        if saga_execution:
            await saga_execution.abort(reason)

class SagaExecution:
    def __init__(self, execution_id: str, definition: SagaDefinition, orchestrator: SagaOrchestrator):
        self.execution_id = execution_id
        self.definition = definition
        self.orchestrator = orchestrator
        self.status = SagaStatus.PENDING
        self.context = definition.initial_context.copy()
        self.started_at: Optional[datetime] = None
        self.completed_at: Optional[datetime] = None
        self.error: Optional[str] = None
        
    async def execute(self):
        """Führt Saga-Steps sequenziell aus"""
        
        try:
            self.status = SagaStatus.RUNNING
            self.started_at = datetime.utcnow()
            
            await self._persist_state()
            
            # Steps in Abhängigkeitsreihenfolge ausführen
            execution_order = self._calculate_execution_order()
            
            for step in execution_order:
                if self.status != SagaStatus.RUNNING:
                    break
                    
                await self._execute_step(step)
                
                if step.status == StepStatus.FAILED:
                    # Saga fehlgeschlagen -> Compensation starten
                    await self._start_compensation()
                    return
            
            # Alle Steps erfolgreich
            self.status = SagaStatus.COMPLETED
            self.completed_at = datetime.utcnow()
            
            await self._persist_state()
            
            # Success Event senden
            await self.orchestrator.event_bus.publish({
                "event_type": "saga_completed",
                "saga_execution_id": self.execution_id,
                "duration_seconds": (self.completed_at - self.started_at).total_seconds(),
                "timestamp": self.completed_at.isoformat()
            })
            
        except Exception as e:
            logger.error(f"Saga {self.execution_id} failed with unexpected error: {str(e)}")
            self.status = SagaStatus.FAILED
            self.error = str(e)
            await self._start_compensation()
        
        finally:
            # Aus running_sagas entfernen
            self.orchestrator.running_sagas.pop(self.execution_id, None)
    
    async def _execute_step(self, step: SagaStep):
        """Führt einzelnen Saga-Step aus"""
        
        step.status = StepStatus.RUNNING
        step.started_at = datetime.utcnow()
        
        await self._persist_state()
        
        # Step Event senden
        await self.orchestrator.event_bus.publish({
            "event_type": "saga_step_started",
            "saga_execution_id": self.execution_id,
            "step_id": step.step_id,
            "step_name": step.name,
            "timestamp": step.started_at.isoformat()
        })
        
        try:
            # Step mit Timeout ausführen
            result = await asyncio.wait_for(
                step.action(self.context),
                timeout=step.timeout_seconds
            )
            
            step.status = StepStatus.COMPLETED
            step.result = result
            step.completed_at = datetime.utcnow()
            
            # Context mit Step-Result aktualisieren
            if step.context_updates:
                self.context.update(step.context_updates)
            
            if result and isinstance(result, dict):
                self.context.update(result)
            
            await self._persist_state()
            
            # Success Event
            await self.orchestrator.event_bus.publish({
                "event_type": "saga_step_completed",
                "saga_execution_id": self.execution_id,
                "step_id": step.step_id,
                "result": result,
                "timestamp": step.completed_at.isoformat()
            })
            
        except asyncio.TimeoutError:
            step.status = StepStatus.FAILED
            step.error = f"Step timeout after {step.timeout_seconds} seconds"
            await self._handle_step_failure(step)
            
        except Exception as e:
            step.status = StepStatus.FAILED
            step.error = str(e)
            await self._handle_step_failure(step)
    
    async def _handle_step_failure(self, step: SagaStep):
        """Behandelt Step-Failure mit Retry-Logic"""
        
        if step.retry_count < step.max_retries:
            step.retry_count += 1
            step.status = StepStatus.PENDING
            
            logger.info(f"Retrying step {step.step_id} (attempt {step.retry_count}/{step.max_retries})")
            
            # Exponential backoff
            delay = min(60, 2 ** step.retry_count)
            await asyncio.sleep(delay)
            
            await self._execute_step(step)
        else:
            logger.error(f"Step {step.step_id} failed after {step.max_retries} retries: {step.error}")
            
            # Failure Event
            await self.orchestrator.event_bus.publish({
                "event_type": "saga_step_failed",
                "saga_execution_id": self.execution_id,
                "step_id": step.step_id,
                "error": step.error,
                "retry_count": step.retry_count,
                "timestamp": datetime.utcnow().isoformat()
            })
    
    async def _start_compensation(self):
        """Startet Compensation-Workflow (rollback)"""
        
        self.status = SagaStatus.COMPENSATING
        
        await self.orchestrator.event_bus.publish({
            "event_type": "saga_compensation_started",
            "saga_execution_id": self.execution_id,
            "timestamp": datetime.utcnow().isoformat()
        })
        
        # Nur completed Steps müssen kompensiert werden, in umgekehrter Reihenfolge
        completed_steps = [step for step in self.definition.steps if step.status == StepStatus.COMPLETED]
        compensation_order = list(reversed(completed_steps))
        
        for step in compensation_order:
            await self._compensate_step(step)
        
        self.status = SagaStatus.COMPENSATED
        self.completed_at = datetime.utcnow()
        
        await self._persist_state()
        
        await self.orchestrator.event_bus.publish({
            "event_type": "saga_compensated",
            "saga_execution_id": self.execution_id,
            "timestamp": self.completed_at.isoformat()
        })
    
    async def _compensate_step(self, step: SagaStep):
        """Führt Compensation für einzelnen Step aus"""
        
        step.status = StepStatus.COMPENSATING
        
        try:
            await step.compensation(self.context, step.result)
            step.status = StepStatus.COMPENSATED
            
            logger.info(f"Successfully compensated step {step.step_id}")
            
        except Exception as e:
            logger.error(f"Failed to compensate step {step.step_id}: {str(e)}")
            # Compensation-Failure wird geloggt, aber Saga-Compensation läuft weiter
    
    def _calculate_execution_order(self) -> List[SagaStep]:
        """Berechnet Ausführungsreihenfolge basierend auf Abhängigkeiten"""
        
        # Topological Sort für Abhängigkeiten
        ordered_steps = []
        remaining_steps = self.definition.steps.copy()
        
        while remaining_steps:
            # Steps finden die keine unerfüllten Abhängigkeiten haben
            ready_steps = []
            for step in remaining_steps:
                dependencies_satisfied = all(
                    any(s.step_id == dep_id and s.status == StepStatus.COMPLETED 
                        for s in ordered_steps)
                    for dep_id in step.depends_on
                ) if step.depends_on else True
                
                if dependencies_satisfied:
                    ready_steps.append(step)
            
            if not ready_steps:
                raise ValueError("Circular dependency detected in saga steps")
            
            # Ersten ready step zur Ausführung hinzufügen
            ordered_steps.append(ready_steps[0])
            remaining_steps.remove(ready_steps[0])
        
        return ordered_steps
    
    async def _persist_state(self):
        """Persistiert aktuellen Saga-State"""
        saga_state = {
            "execution_id": self.execution_id,
            "saga_id": self.definition.saga_id,
            "status": self.status.value,
            "context": self.context,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "error": self.error,
            "steps": [
                {
                    "step_id": step.step_id,
                    "name": step.name,
                    "status": step.status.value,
                    "result": step.result,
                    "error": step.error,
                    "started_at": step.started_at.isoformat() if step.started_at else None,
                    "completed_at": step.completed_at.isoformat() if step.completed_at else None,
                    "retry_count": step.retry_count
                }
                for step in self.definition.steps
            ]
        }
        
        await self.orchestrator.persistence.save_saga(self.execution_id, saga_state)
    
    def get_status(self) -> Dict[str, Any]:
        """Gibt aktuellen Status zurück"""
        return {
            "execution_id": self.execution_id,
            "saga_id": self.definition.saga_id,
            "status": self.status.value,
            "started_at": self.started_at.isoformat() if self.started_at else None,
            "completed_at": self.completed_at.isoformat() if self.completed_at else None,
            "error": self.error,
            "progress": {
                "total_steps": len(self.definition.steps),
                "completed_steps": len([s for s in self.definition.steps if s.status == StepStatus.COMPLETED]),
                "failed_steps": len([s for s in self.definition.steps if s.status == StepStatus.FAILED])
            },
            "steps": [
                {
                    "step_id": step.step_id,
                    "name": step.name,
                    "status": step.status.value,
                    "retry_count": step.retry_count
                }
                for step in self.definition.steps
            ]
        }
    
    async def abort(self, reason: str = None):
        """Bricht Saga ab"""
        if self.status == SagaStatus.RUNNING:
            self.status = SagaStatus.FAILED
            self.error = reason or "Saga aborted by user"
            await self._start_compensation()
```

---

## 🔁 **5. COMPENSATION-WORKFLOWS & ROLLBACK-STRATEGIEN**

### 5.1 **Trading-Specific Compensation Patterns**
```python
# services/trading/compensation_manager.py
from typing import Dict, Any, List, Optional
from enum import Enum
from dataclasses import dataclass
from datetime import datetime

class CompensationAction(Enum):
    CANCEL_ORDER = "cancel_order"
    REVERSE_TRADE = "reverse_trade"
    REFUND_AMOUNT = "refund_amount"
    UNLOCK_FUNDS = "unlock_funds"
    RESTORE_PORTFOLIO_STATE = "restore_portfolio_state"
    REVERT_POSITION_CHANGE = "revert_position_change"
    CANCEL_PENDING_TRANSACTIONS = "cancel_pending_transactions"

@dataclass
class CompensationStep:
    step_id: str
    action: CompensationAction
    target_entity: str  # order_id, position_id, portfolio_id, etc.
    original_data: Dict[str, Any]
    compensation_data: Dict[str, Any]
    priority: int = 0  # Höhere Priorität = früher ausführen
    is_critical: bool = False  # Kritische Steps müssen erfolgreich sein
    max_attempts: int = 5
    timeout_seconds: int = 30

class TradingCompensationManager:
    def __init__(self, order_service, portfolio_service, broker_service):
        self.order_service = order_service
        self.portfolio_service = portfolio_service
        self.broker_service = broker_service
        self.compensation_registry: Dict[str, List[CompensationStep]] = {}
    
    async def register_compensation_steps(self, transaction_id: str, steps: List[CompensationStep]):
        """Registriert Compensation-Steps für Transaction"""
        
        # Nach Priorität sortieren (höhere Priorität zuerst)
        sorted_steps = sorted(steps, key=lambda x: x.priority, reverse=True)
        self.compensation_registry[transaction_id] = sorted_steps
        
        logger.info(f"Registered {len(steps)} compensation steps for transaction {transaction_id}")
    
    async def execute_compensation(self, transaction_id: str, reason: str = None) -> Dict[str, Any]:
        """Führt alle Compensation-Steps für Transaction aus"""
        
        if transaction_id not in self.compensation_registry:
            logger.warning(f"No compensation steps registered for transaction {transaction_id}")
            return {"success": True, "steps_executed": 0, "errors": []}
        
        steps = self.compensation_registry[transaction_id]
        results = {
            "transaction_id": transaction_id,
            "reason": reason,
            "started_at": datetime.utcnow().isoformat(),
            "steps_executed": 0,
            "steps_failed": 0,
            "errors": [],
            "step_results": []
        }
        
        logger.info(f"Starting compensation for transaction {transaction_id}: {reason}")
        
        for step in steps:
            step_result = await self._execute_compensation_step(step)
            results["step_results"].append(step_result)
            
            if step_result["success"]:
                results["steps_executed"] += 1
            else:
                results["steps_failed"] += 1
                results["errors"].append(step_result["error"])
                
                # Bei kritischen Steps: Compensation abbrechen
                if step.is_critical:
                    logger.error(f"Critical compensation step {step.step_id} failed: {step_result['error']}")
                    break
        
        results["completed_at"] = datetime.utcnow().isoformat()
        results["success"] = results["steps_failed"] == 0
        
        # Registry-Entry entfernen
        del self.compensation_registry[transaction_id]
        
        logger.info(f"Compensation completed for {transaction_id}: {results['steps_executed']}/{len(steps)} steps successful")
        
        return results
    
    async def _execute_compensation_step(self, step: CompensationStep) -> Dict[str, Any]:
        """Führt einzelnen Compensation-Step aus"""
        
        step_result = {
            "step_id": step.step_id,
            "action": step.action.value,
            "target_entity": step.target_entity,
            "success": False,
            "error": None,
            "attempts": 0,
            "started_at": datetime.utcnow().isoformat()
        }
        
        for attempt in range(1, step.max_attempts + 1):
            step_result["attempts"] = attempt
            
            try:
                await asyncio.wait_for(
                    self._perform_compensation_action(step),
                    timeout=step.timeout_seconds
                )
                
                step_result["success"] = True
                step_result["completed_at"] = datetime.utcnow().isoformat()
                
                logger.info(f"Compensation step {step.step_id} successful on attempt {attempt}")
                break
                
            except asyncio.TimeoutError:
                error_msg = f"Timeout after {step.timeout_seconds}s on attempt {attempt}"
                logger.warning(f"Compensation step {step.step_id}: {error_msg}")
                
                if attempt == step.max_attempts:
                    step_result["error"] = error_msg
                    
            except Exception as e:
                error_msg = f"Error on attempt {attempt}: {str(e)}"
                logger.error(f"Compensation step {step.step_id}: {error_msg}")
                
                if attempt == step.max_attempts:
                    step_result["error"] = error_msg
                else:
                    # Exponential backoff between attempts
                    delay = min(30, 2 ** attempt)
                    await asyncio.sleep(delay)
        
        return step_result
    
    async def _perform_compensation_action(self, step: CompensationStep):
        """Führt spezifische Compensation-Action aus"""
        
        if step.action == CompensationAction.CANCEL_ORDER:
            await self._cancel_order(step)
            
        elif step.action == CompensationAction.REVERSE_TRADE:
            await self._reverse_trade(step)
            
        elif step.action == CompensationAction.REFUND_AMOUNT:
            await self._refund_amount(step)
            
        elif step.action == CompensationAction.UNLOCK_FUNDS:
            await self._unlock_funds(step)
            
        elif step.action == CompensationAction.RESTORE_PORTFOLIO_STATE:
            await self._restore_portfolio_state(step)
            
        elif step.action == CompensationAction.REVERT_POSITION_CHANGE:
            await self._revert_position_change(step)
            
        elif step.action == CompensationAction.CANCEL_PENDING_TRANSACTIONS:
            await self._cancel_pending_transactions(step)
            
        else:
            raise ValueError(f"Unknown compensation action: {step.action}")
    
    async def _cancel_order(self, step: CompensationStep):
        """Storniert Order"""
        order_id = step.target_entity
        
        # Bei Broker stornieren
        try:
            await self.broker_service.cancel_order(order_id)
        except Exception as e:
            logger.warning(f"Failed to cancel order {order_id} at broker: {str(e)}")
        
        # Lokalen Order-Status aktualisieren
        await self.order_service.update_order_status(order_id, "cancelled_by_compensation")
    
    async def _reverse_trade(self, step: CompensationStep):
        """Führt Reverse-Trade aus (Gegentrade)"""
        original_trade = step.original_data
        
        # Reverse-Order erstellen
        reverse_order = {
            "asset_symbol": original_trade["asset_symbol"],
            "order_type": "market",
            "side": "sell" if original_trade["side"] == "buy" else "buy",
            "quantity": original_trade["executed_quantity"],
            "reason": f"compensation_for_{original_trade['order_id']}"
        }
        
        await self.order_service.place_order(reverse_order)
    
    async def _refund_amount(self, step: CompensationStep):
        """Erstattet Betrag zurück"""
        refund_data = step.compensation_data
        
        await self.portfolio_service.add_cash(
            portfolio_id=refund_data["portfolio_id"],
            amount=refund_data["amount"],
            currency=refund_data["currency"],
            reason=f"compensation_refund_{step.step_id}"
        )
    
    async def _unlock_funds(self, step: CompensationStep):
        """Gibt gesperrte Funds frei"""
        unlock_data = step.compensation_data
        
        await self.portfolio_service.unlock_funds(
            portfolio_id=unlock_data["portfolio_id"],
            amount=unlock_data["amount"],
            asset_symbol=unlock_data.get("asset_symbol"),
            reason=f"compensation_unlock_{step.step_id}"
        )
    
    async def _restore_portfolio_state(self, step: CompensationStep):
        """Stellt Portfolio-Zustand wieder her"""
        original_state = step.original_data
        
        await self.portfolio_service.restore_state(
            portfolio_id=step.target_entity,
            state_snapshot=original_state,
            reason=f"compensation_restore_{step.step_id}"
        )
    
    async def _revert_position_change(self, step: CompensationStep):
        """Macht Position-Änderung rückgängig"""
        position_data = step.original_data
        
        await self.portfolio_service.revert_position_change(
            position_id=step.target_entity,
            original_quantity=position_data["original_quantity"],
            original_average_price=position_data["original_average_price"],
            reason=f"compensation_revert_{step.step_id}"
        )
    
    async def _cancel_pending_transactions(self, step: CompensationStep):
        """Storniert alle pending Transaktionen"""
        transaction_ids = step.compensation_data["transaction_ids"]
        
        for transaction_id in transaction_ids:
            try:
                await self.order_service.cancel_transaction(transaction_id)
            except Exception as e:
                logger.warning(f"Failed to cancel transaction {transaction_id}: {str(e)}")

# Trading-Saga mit Compensation
class TradingOrderSaga:
    def __init__(self, compensation_manager: TradingCompensationManager):
        self.compensation_manager = compensation_manager
    
    async def execute_buy_order_saga(self, order_data: Dict[str, Any]) -> str:
        """Saga für Buy-Order mit automatischer Compensation"""
        
        transaction_id = f"buy-order-{uuid.uuid4()}"
        
        # Compensation-Steps vordefinieren
        compensation_steps = []
        
        saga_definition = SagaDefinition(
            saga_id="buy_order_workflow",
            name="Buy Order Execution",
            steps=[
                SagaStep(
                    step_id="validate_order",
                    name="Validate Order Parameters",
                    action=self._validate_order,
                    compensation=self._no_compensation_needed
                ),
                SagaStep(
                    step_id="lock_funds",
                    name="Lock Required Funds",
                    action=self._lock_funds,
                    compensation=self._unlock_funds_compensation,
                    depends_on=["validate_order"]
                ),
                SagaStep(
                    step_id="place_broker_order",
                    name="Place Order at Broker",
                    action=self._place_broker_order,
                    compensation=self._cancel_broker_order_compensation,
                    depends_on=["lock_funds"]
                ),
                SagaStep(
                    step_id="update_portfolio",
                    name="Update Portfolio State",
                    action=self._update_portfolio,
                    compensation=self._revert_portfolio_compensation,
                    depends_on=["place_broker_order"]
                ),
                SagaStep(
                    step_id="finalize_order",
                    name="Finalize Order Record",
                    action=self._finalize_order,
                    compensation=self._revert_order_finalization,
                    depends_on=["update_portfolio"]
                )
            ],
            initial_context={"order_data": order_data, "transaction_id": transaction_id}
        )
        
        # Saga starten
        execution_id = await saga_orchestrator.start_saga(saga_definition)
        
        return execution_id
    
    async def _validate_order(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Validiert Order-Parameter"""
        order_data = context["order_data"]
        
        # Validierung hier
        if order_data["quantity"] <= 0:
            raise DataValidationError("quantity", order_data["quantity"], "must be positive")
        
        return {"validation_passed": True}
    
    async def _lock_funds(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Sperrt erforderliche Funds"""
        order_data = context["order_data"]
        required_amount = order_data["quantity"] * order_data["estimated_price"]
        
        lock_result = await self.portfolio_service.lock_funds(
            portfolio_id=order_data["portfolio_id"],
            amount=required_amount,
            currency="EUR"
        )
        
        # Compensation-Step registrieren
        await self.compensation_manager.register_compensation_steps(
            context["transaction_id"],
            [CompensationStep(
                step_id="unlock_funds_step",
                action=CompensationAction.UNLOCK_FUNDS,
                target_entity=order_data["portfolio_id"],
                original_data={},
                compensation_data={
                    "portfolio_id": order_data["portfolio_id"],
                    "amount": required_amount,
                    "currency": "EUR"
                },
                priority=100,
                is_critical=True
            )]
        )
        
        return {"locked_amount": required_amount, "lock_id": lock_result["lock_id"]}
    
    async def _no_compensation_needed(self, context: Dict[str, Any], result: Any):
        """Keine Compensation erforderlich"""
        pass
    
    async def _unlock_funds_compensation(self, context: Dict[str, Any], result: Any):
        """Gibt Funds wieder frei"""
        await self.compensation_manager.execute_compensation(context["transaction_id"])
```

### 5.2 **Business-Logic Compensation Patterns**
```python
# shared/compensation/business_compensation.py
from typing import Dict, Any, List, Optional, Callable
from datetime import datetime
import asyncio

class BusinessCompensationPattern:
    """Base-Klasse für Business-Logic-Compensation-Patterns"""
    
    def __init__(self, pattern_name: str):
        self.pattern_name = pattern_name
        self.compensation_actions: List[Callable] = []
    
    async def add_compensation_action(self, action: Callable, priority: int = 0, is_critical: bool = False):
        """Fügt Compensation-Action hinzu"""
        self.compensation_actions.append({
            "action": action,
            "priority": priority,
            "is_critical": is_critical,
            "added_at": datetime.utcnow()
        })
        
        # Nach Priorität sortieren
        self.compensation_actions.sort(key=lambda x: x["priority"], reverse=True)
    
    async def execute_compensations(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Führt alle Compensation-Actions aus"""
        
        results = {
            "pattern_name": self.pattern_name,
            "total_actions": len(self.compensation_actions),
            "successful_actions": 0,
            "failed_actions": 0,
            "errors": []
        }
        
        for compensation_action in self.compensation_actions:
            try:
                await compensation_action["action"](context)
                results["successful_actions"] += 1
                
                logger.info(f"Compensation action successful in pattern {self.pattern_name}")
                
            except Exception as e:
                error_msg = f"Compensation action failed: {str(e)}"
                results["errors"].append(error_msg)
                results["failed_actions"] += 1
                
                logger.error(f"Compensation action failed in pattern {self.pattern_name}: {error_msg}")
                
                # Bei kritischen Actions: Compensation abbrechen
                if compensation_action["is_critical"]:
                    logger.error(f"Critical compensation action failed in pattern {self.pattern_name}")
                    break
        
        return results

# Spezifische Compensation Patterns
class PortfolioRebalancingCompensation(BusinessCompensationPattern):
    def __init__(self, portfolio_service):
        super().__init__("portfolio_rebalancing")
        self.portfolio_service = portfolio_service
        self.original_allocations: Dict[str, float] = {}
    
    async def capture_original_state(self, portfolio_id: str):
        """Erfasst ursprünglichen Portfolio-Zustand"""
        portfolio_state = await self.portfolio_service.get_portfolio_allocations(portfolio_id)
        self.original_allocations = portfolio_state["allocations"]
        
        # Compensation-Action für Rollback registrieren
        await self.add_compensation_action(
            action=self._restore_original_allocations,
            priority=100,
            is_critical=True
        )
    
    async def _restore_original_allocations(self, context: Dict[str, Any]):
        """Stellt ursprüngliche Allokationen wieder her"""
        portfolio_id = context["portfolio_id"]
        
        await self.portfolio_service.restore_allocations(
            portfolio_id=portfolio_id,
            target_allocations=self.original_allocations,
            reason="rebalancing_compensation"
        )

class RiskLimitCompensation(BusinessCompensationPattern):
    def __init__(self, risk_service):
        super().__init__("risk_limit_enforcement")
        self.risk_service = risk_service
        self.violated_limits: List[Dict[str, Any]] = []
    
    async def capture_limit_violations(self, portfolio_id: str, violated_limits: List[Dict[str, Any]]):
        """Erfasst verletzte Risk-Limits"""
        self.violated_limits = violated_limits
        
        # Für jeden verletzten Limit eine Compensation-Action
        for limit_violation in violated_limits:
            await self.add_compensation_action(
                action=lambda ctx, lv=limit_violation: self._restore_risk_compliance(ctx, lv),
                priority=limit_violation.get("severity", 50),
                is_critical=limit_violation.get("is_critical", False)
            )
    
    async def _restore_risk_compliance(self, context: Dict[str, Any], limit_violation: Dict[str, Any]):
        """Stellt Risk-Compliance wieder her"""
        portfolio_id = context["portfolio_id"]
        
        if limit_violation["type"] == "position_size_exceeded":
            # Position reduzieren
            await self.risk_service.reduce_position_to_limit(
                portfolio_id=portfolio_id,
                asset_symbol=limit_violation["asset_symbol"],
                max_position_percent=limit_violation["limit_value"]
            )
        
        elif limit_violation["type"] == "sector_concentration_exceeded":
            # Sektor-Konzentration reduzieren
            await self.risk_service.reduce_sector_exposure(
                portfolio_id=portfolio_id,
                sector=limit_violation["sector"],
                max_sector_percent=limit_violation["limit_value"]
            )
        
        elif limit_violation["type"] == "daily_loss_exceeded":
            # Trading stoppen
            await self.risk_service.enable_emergency_mode(
                portfolio_id=portfolio_id,
                reason="daily_loss_limit_compensation"
            )

class TaxCalculationCompensation(BusinessCompensationPattern):
    def __init__(self, tax_service):
        super().__init__("tax_calculation")
        self.tax_service = tax_service
        self.tax_calculations: List[Dict[str, Any]] = []
    
    async def capture_tax_calculations(self, calculations: List[Dict[str, Any]]):
        """Erfasst durchgeführte Steuerberechnungen"""
        self.tax_calculations = calculations
        
        # Compensation für Steuer-Korrekturen
        await self.add_compensation_action(
            action=self._revert_tax_calculations,
            priority=80,
            is_critical=False
        )
    
    async def _revert_tax_calculations(self, context: Dict[str, Any]):
        """Macht Steuerberechnungen rückgängig"""
        for calculation in self.tax_calculations:
            await self.tax_service.revert_tax_calculation(
                calculation_id=calculation["calculation_id"],
                reason="tax_calculation_compensation"
            )

# Global Compensation Registry
class GlobalCompensationRegistry:
    def __init__(self):
        self.active_patterns: Dict[str, BusinessCompensationPattern] = {}
        self.compensation_history: List[Dict[str, Any]] = []
    
    async def register_pattern(self, transaction_id: str, pattern: BusinessCompensationPattern):
        """Registriert Compensation-Pattern für Transaction"""
        self.active_patterns[transaction_id] = pattern
        
        logger.info(f"Registered compensation pattern '{pattern.pattern_name}' for transaction {transaction_id}")
    
    async def execute_compensation(self, transaction_id: str, context: Dict[str, Any]) -> Dict[str, Any]:
        """Führt Compensation für Transaction aus"""
        
        if transaction_id not in self.active_patterns:
            logger.warning(f"No compensation pattern registered for transaction {transaction_id}")
            return {"success": False, "error": "No compensation pattern found"}
        
        pattern = self.active_patterns[transaction_id]
        
        compensation_result = await pattern.execute_compensations(context)
        compensation_result["transaction_id"] = transaction_id
        compensation_result["executed_at"] = datetime.utcnow().isoformat()
        
        # In History speichern
        self.compensation_history.append(compensation_result)
        
        # Pattern aus Registry entfernen
        del self.active_patterns[transaction_id]
        
        logger.info(f"Compensation executed for transaction {transaction_id}: {compensation_result['successful_actions']}/{compensation_result['total_actions']} actions successful")
        
        return compensation_result
    
    def get_compensation_history(self, limit: int = 100) -> List[Dict[str, Any]]:
        """Ruft Compensation-History ab"""
        return self.compensation_history[-limit:]
    
    def get_active_patterns(self) -> Dict[str, str]:
        """Ruft aktive Compensation-Patterns ab"""
        return {tid: pattern.pattern_name for tid, pattern in self.active_patterns.items()}

# Global Instance
global_compensation_registry = GlobalCompensationRegistry()
```

---

## ⏱️ **6. TIMEOUT-MANAGEMENT & SERVICE-CALL-TIMEOUTS**

### 6.1 **Adaptive Timeout-Manager**
```python
# shared/timeouts/timeout_manager.py
from typing import Dict, Optional, Callable, Any
from datetime import datetime, timedelta
from dataclasses import dataclass
from enum import Enum
import asyncio
import statistics

class TimeoutType(Enum):
    HTTP_REQUEST = "http_request"
    DATABASE_QUERY = "database_query"
    EXTERNAL_API = "external_api"
    INTERNAL_SERVICE = "internal_service"
    COMPUTATION = "computation"
    FILE_OPERATION = "file_operation"

@dataclass
class TimeoutConfig:
    default_timeout: float
    min_timeout: float
    max_timeout: float
    percentile: float = 95.0  # P95 für Timeout-Berechnung
    adaptive: bool = True
    circuit_breaker_threshold: int = 5

class ServiceTimeoutManager:
    def __init__(self):
        self.timeout_configs: Dict[str, TimeoutConfig] = {}
        self.call_history: Dict[str, List[float]] = {}  # Response times
        self.timeout_violations: Dict[str, int] = {}
        
        # Default-Timeout-Configs
        self._setup_default_configs()
    
    def _setup_default_configs(self):
        """Initialisiert Standard-Timeout-Konfigurationen"""
        
        self.timeout_configs = {
            TimeoutType.HTTP_REQUEST.value: TimeoutConfig(
                default_timeout=30.0,
                min_timeout=5.0,
                max_timeout=120.0,
                adaptive=True
            ),
            TimeoutType.DATABASE_QUERY.value: TimeoutConfig(
                default_timeout=10.0,
                min_timeout=1.0,
                max_timeout=60.0,
                adaptive=True
            ),
            TimeoutType.EXTERNAL_API.value: TimeoutConfig(
                default_timeout=45.0,
                min_timeout=10.0,
                max_timeout=180.0,
                adaptive=True
            ),
            TimeoutType.INTERNAL_SERVICE.value: TimeoutConfig(
                default_timeout=15.0,
                min_timeout=2.0,
                max_timeout=60.0,
                adaptive=True
            ),
            TimeoutType.COMPUTATION.value: TimeoutConfig(
                default_timeout=300.0,  # 5 Minuten für Berechnungen
                min_timeout=30.0,
                max_timeout=600.0,
                adaptive=False
            ),
            TimeoutType.FILE_OPERATION.value: TimeoutConfig(
                default_timeout=60.0,
                min_timeout=5.0,
                max_timeout=300.0,
                adaptive=True
            )
        }
    
    def get_timeout(self, service_name: str, timeout_type: TimeoutType) -> float:
        """Gibt aktuellen Timeout für Service zurück"""
        
        config_key = f"{service_name}:{timeout_type.value}"
        
        # Service-spezifische Konfiguration prüfen
        if config_key in self.timeout_configs:
            config = self.timeout_configs[config_key]
        else:
            # Fallback auf Typ-Default
            config = self.timeout_configs.get(timeout_type.value)
            if not config:
                return 30.0  # Ultimate fallback
        
        # Adaptive Timeout-Berechnung
        if config.adaptive and config_key in self.call_history:
            return self._calculate_adaptive_timeout(config_key, config)
        
        return config.default_timeout
    
    def _calculate_adaptive_timeout(self, config_key: str, config: TimeoutConfig) -> float:
        """Berechnet adaptiven Timeout basierend auf Historie"""
        
        history = self.call_history[config_key]
        
        if len(history) < 10:  # Zu wenig Daten für adaptive Berechnung
            return config.default_timeout
        
        # P95-Percentile der letzten 100 Calls
        recent_history = history[-100:]
        p95_time = statistics.quantiles(recent_history, n=20)[18]  # 95th percentile
        
        # Adaptive Timeout = P95 + 50% Buffer
        adaptive_timeout = p95_time * 1.5
        
        # Innerhalb Min/Max-Grenzen begrenzen
        return max(config.min_timeout, min(config.max_timeout, adaptive_timeout))
    
    def record_call_time(self, service_name: str, timeout_type: TimeoutType, duration: float):
        """Zeichnet Call-Zeit für adaptive Timeout-Berechnung auf"""
        
        config_key = f"{service_name}:{timeout_type.value}"
        
        if config_key not in self.call_history:
            self.call_history[config_key] = []
        
        self.call_history[config_key].append(duration)
        
        # History-Limit (max. 1000 Einträge)
        if len(self.call_history[config_key]) > 1000:
            self.call_history[config_key] = self.call_history[config_key][-500:]
    
    def record_timeout_violation(self, service_name: str, timeout_type: TimeoutType):
        """Zeichnet Timeout-Verletzung auf"""
        
        config_key = f"{service_name}:{timeout_type.value}"
        
        self.timeout_violations.setdefault(config_key, 0)
        self.timeout_violations[config_key] += 1
        
        logger.warning(f"Timeout violation for {config_key} (total: {self.timeout_violations[config_key]})")
    
    def configure_service_timeout(
        self, 
        service_name: str, 
        timeout_type: TimeoutType, 
        config: TimeoutConfig
    ):
        """Konfiguriert Service-spezifischen Timeout"""
        
        config_key = f"{service_name}:{timeout_type.value}"
        self.timeout_configs[config_key] = config
        
        logger.info(f"Configured timeout for {config_key}: {config.default_timeout}s (adaptive: {config.adaptive})")
    
    def get_timeout_stats(self) -> Dict[str, Any]:
        """Gibt Timeout-Statistiken zurück"""
        
        stats = {
            "total_services": len(self.call_history),
            "total_violations": sum(self.timeout_violations.values()),
            "services": {}
        }
        
        for config_key in self.call_history:
            history = self.call_history[config_key]
            violations = self.timeout_violations.get(config_key, 0)
            
            if history:
                stats["services"][config_key] = {
                    "total_calls": len(history),
                    "avg_response_time": statistics.mean(history),
                    "p95_response_time": statistics.quantiles(history, n=20)[18] if len(history) >= 20 else None,
                    "timeout_violations": violations,
                    "violation_rate": violations / len(history) if history else 0,
                    "current_timeout": self._calculate_adaptive_timeout(config_key, self.timeout_configs.get(config_key))
                }
        
        return stats

# Global Timeout Manager
timeout_manager = ServiceTimeoutManager()

# Timeout-Decorator
def with_timeout(
    service_name: str,
    timeout_type: TimeoutType,
    fallback_value: Any = None,
    raise_on_timeout: bool = True
):
    """Decorator für automatisches Timeout-Management"""
    
    def decorator(func: Callable):
        @wraps(func)
        async def async_wrapper(*args, **kwargs):
            timeout = timeout_manager.get_timeout(service_name, timeout_type)
            start_time = datetime.utcnow()
            
            try:
                result = await asyncio.wait_for(func(*args, **kwargs), timeout=timeout)
                
                # Erfolgreiche Call-Zeit aufzeichnen
                duration = (datetime.utcnow() - start_time).total_seconds()
                timeout_manager.record_call_time(service_name, timeout_type, duration)
                
                return result
                
            except asyncio.TimeoutError:
                # Timeout-Verletzung aufzeichnen
                timeout_manager.record_timeout_violation(service_name, timeout_type)
                
                if raise_on_timeout:
                    raise TimeoutError(f"Service {service_name} timed out after {timeout}s")
                else:
                    logger.warning(f"Service {service_name} timed out, returning fallback value")
                    return fallback_value
        
        @wraps(func)
        def sync_wrapper(*args, **kwargs):
            # Sync-Version ohne Timeout (falls nötig)
            return func(*args, **kwargs)
        
        if asyncio.iscoroutinefunction(func):
            return async_wrapper
        else:
            return sync_wrapper
    
    return decorator

# Beispiel-Verwendung
@with_timeout(
    service_name="bitpanda_api",
    timeout_type=TimeoutType.EXTERNAL_API,
    fallback_value=None,
    raise_on_timeout=False
)
async def fetch_asset_price(asset_symbol: str) -> Optional[float]:
    """Ruft Asset-Preis von Bitpanda API ab"""
    # Implementation hier
    pass

@with_timeout(
    service_name="portfolio_service",
    timeout_type=TimeoutType.DATABASE_QUERY
)
async def get_portfolio_positions(portfolio_id: str) -> List[Dict[str, Any]]:
    """Ruft Portfolio-Positionen aus DB ab"""
    # Implementation hier
    pass
```

---

## 📊 **7. MONITORING & ALERTING INTEGRATION**

### 7.1 **Error-Metrics für Zabbix**
```python
# shared/monitoring/error_metrics.py
import redis
from datetime import datetime, timedelta
from typing import Dict, Any
import json

class ErrorMetricsCollector:
    def __init__(self, redis_client: redis.Redis):
        self.redis_client = redis_client
        self.metrics_key_prefix = "error_metrics"
        
    async def record_error_metric(
        self,
        service_name: str,
        error_category: str,
        severity: str,
        function_name: str = None,
        additional_tags: Dict[str, str] = None
    ):
        """Zeichnet Error-Metric für Zabbix auf"""
        
        timestamp = datetime.utcnow()
        metric_key = f"{self.metrics_key_prefix}:counters"
        
        # Counter für verschiedene Dimensionen
        counters = [
            f"errors_total",
            f"errors_by_service:{service_name}",
            f"errors_by_category:{error_category}",
            f"errors_by_severity:{severity}",
            f"errors_by_service_category:{service_name}:{error_category}",
        ]
        
        if function_name:
            counters.append(f"errors_by_function:{service_name}:{function_name}")
        
        # Atomische Counter-Updates
        pipe = self.redis_client.pipeline()
        for counter in counters:
            pipe.hincrby(metric_key, counter, 1)
        await pipe.execute()
        
        # Zeitbasierte Metrics (für Rate-Berechnung)
        time_bucket = timestamp.strftime("%Y%m%d_%H%M")  # Minute-wise buckets
        time_metric_key = f"{self.metrics_key_prefix}:timeseries:{time_bucket}"
        
        await self.redis_client.hincrby(time_metric_key, f"errors_{service_name}", 1)
        await self.redis_client.expire(time_metric_key, 3600)  # 1 hour TTL
        
        # Additional tags
        if additional_tags:
            for tag_key, tag_value in additional_tags.items():
                await self.redis_client.hincrby(
                    metric_key, 
                    f"errors_by_{tag_key}:{tag_value}", 
                    1
                )
    
    async def get_error_metrics(self, time_range_minutes: int = 60) -> Dict[str, Any]:
        """Ruft aggregierte Error-Metrics für Zabbix ab"""
        
        # Counter-Metrics
        counters = await self.redis_client.hgetall(f"{self.metrics_key_prefix}:counters")
        
        # Zeitbasierte Metrics für Rate-Berechnung
        now = datetime.utcnow()
        error_rates = {}
        
        for minutes_ago in range(time_range_minutes):
            bucket_time = now - timedelta(minutes=minutes_ago)
            bucket_key = f"{self.metrics_key_prefix}:timeseries:{bucket_time.strftime('%Y%m%d_%H%M')}"
            
            bucket_data = await self.redis_client.hgetall(bucket_key)
            for key, count in bucket_data.items():
                if key.startswith("errors_"):
                    service_name = key.replace("errors_", "")
                    error_rates.setdefault(service_name, []).append(int(count))
        
        # Rate-Berechnung (Errors per minute)
        calculated_rates = {}
        for service_name, counts in error_rates.items():
            if counts:
                calculated_rates[f"error_rate_{service_name}"] = sum(counts) / len(counts)
        
        return {
            "counters": {k.decode(): int(v.decode()) for k, v in counters.items()},
            "error_rates": calculated_rates,
            "last_updated": now.isoformat()
        }

# Zabbix-Integration Script
#!/bin/bash
# /etc/zabbix/scripts/aktienanalyse_error_metrics.sh

METRIC_NAME=$1
REDIS_HOST="localhost"
REDIS_PORT="6379"

case $METRIC_NAME in
    "errors_total")
        redis-cli -h $REDIS_HOST -p $REDIS_PORT HGET error_metrics:counters errors_total || echo 0
        ;;
    "errors_by_service_"*)
        SERVICE_NAME=$(echo $METRIC_NAME | sed 's/errors_by_service_//')
        redis-cli -h $REDIS_HOST -p $REDIS_PORT HGET error_metrics:counters "errors_by_service:$SERVICE_NAME" || echo 0
        ;;
    "error_rate_"*)
        SERVICE_NAME=$(echo $METRIC_NAME | sed 's/error_rate_//')
        python3 /etc/zabbix/scripts/calculate_error_rate.py $SERVICE_NAME
        ;;
    "circuit_breaker_"*)
        BREAKER_NAME=$(echo $METRIC_NAME | sed 's/circuit_breaker_//')
        redis-cli -h $REDIS_HOST -p $REDIS_PORT HGET circuit_breakers:$BREAKER_NAME state || echo "unknown"
        ;;
    *)
        echo "Unknown metric: $METRIC_NAME"
        exit 1
        ;;
esac
```

---

✅ **Error-Handling & Resilience-Spezifikation ist vollständig!**

Die Spezifikation umfasst:

1. **Exception-Handling-Standards** mit kategorisierten Fehlern und Recovery-Strategien
2. **Retry-Mechanisms** mit Exponential Backoff und Circuit Breakers  
3. **Dead-Letter-Queues** für Failed-Event-Handling mit Monitoring
4. **Saga-Pattern** für Distributed-Transaction-Management
5. **Compensation-Workflows** für Trading-spezifische Rollback-Strategien
6. **Timeout-Management** mit adaptiven Timeouts basierend auf Performancehistorie
7. **Monitoring-Integration** für Zabbix mit Error-Metrics und Alerting

Das System ist jetzt robust gegen Ausfälle und kann graceful degradieren bei Problemen!