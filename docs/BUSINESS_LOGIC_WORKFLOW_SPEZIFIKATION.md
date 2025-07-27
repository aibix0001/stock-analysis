# 🔄 Business-Logic & Workflow-Spezifikation

## 🎯 **Übersicht**

**Kontext**: Detaillierte Business-Logic-Workflows für das Event-driven Aktienanalyse-Ökosystem
**Ziel**: Vollständige Definition aller Geschäftsprozesse mit State-Machines und Event-Choreography
**Ansatz**: Domain-driven Design mit Event-Sourcing und Saga-Pattern für komplexe Workflows

---

## 🏗️ **1. TRADING-RULES-ENGINE**

### 1.1 **Risk-Management-Rules-Framework**
```python
# shared/business/trading_rules_engine.py
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any, Callable
from decimal import Decimal
from enum import Enum
from datetime import datetime, timedelta
import logging
import json
import yaml
from pathlib import Path
import threading
from typing import Union

class RuleType(Enum):
    PRE_TRADE = "pre_trade"           # Vor Order-Placement
    POST_TRADE = "post_trade"         # Nach Trade-Execution
    POSITION_MANAGEMENT = "position"  # Position-Überwachung
    PORTFOLIO_RISK = "portfolio"      # Portfolio-Level-Risk
    MARKET_CONDITIONS = "market"      # Market-Condition-Rules

class RuleSeverity(Enum):
    INFO = "info"                     # Information only
    WARNING = "warning"               # Warnung, erlaubt aber weiter
    ERROR = "error"                   # Blockiert Action
    CRITICAL = "critical"             # Sofortige Intervention erforderlich

@dataclass
class RuleResult:
    """Ergebnis einer Business-Rule-Prüfung"""
    rule_id: str
    rule_name: str
    passed: bool
    severity: RuleSeverity
    message: str
    recommendation: Optional[str] = None
    metrics: Dict[str, Any] = field(default_factory=dict)
    triggered_at: datetime = field(default_factory=datetime.utcnow)
    
    @property
    def blocks_action(self) -> bool:
        """Rule blockiert die Action"""
        return not self.passed and self.severity in [RuleSeverity.ERROR, RuleSeverity.CRITICAL]

@dataclass
class TradingRule:
    """Definition einer Trading-Rule"""
    rule_id: str
    name: str
    description: str
    rule_type: RuleType
    severity: RuleSeverity
    is_active: bool = True
    
    # Rule-Configuration
    parameters: Dict[str, Any] = field(default_factory=dict)
    conditions: List[str] = field(default_factory=list)
    
    # Rule-Function
    evaluate_function: Callable = None
    
    # Metadata
    created_at: datetime = field(default_factory=datetime.utcnow)
    last_modified: datetime = field(default_factory=datetime.utcnow)
    
    def evaluate(self, context: Dict[str, Any]) -> RuleResult:
        """Rule evaluieren"""
        if not self.is_active:
            return RuleResult(
                rule_id=self.rule_id,
                rule_name=self.name,
                passed=True,
                severity=RuleSeverity.INFO,
                message="Rule is inactive"
            )
        
        if self.evaluate_function:
            try:
                return self.evaluate_function(context, self.parameters)
            except Exception as e:
                logging.error(f"Rule {self.rule_id} evaluation failed: {str(e)}")
                return RuleResult(
                    rule_id=self.rule_id,
                    rule_name=self.name,
                    passed=False,
                    severity=RuleSeverity.ERROR,
                    message=f"Rule evaluation failed: {str(e)}"
                )
        
        return RuleResult(
            rule_id=self.rule_id,
            rule_name=self.name,
            passed=True,
            severity=RuleSeverity.INFO,
            message="No evaluation function defined"
        )

class RulesConfigurationManager:
    """Configuration-Manager für Trading-Rules und Business-Logic-Parameter"""
    
    def __init__(self, config_path: str = None):
        self.config_path = config_path or "/home/mdoehler/aktienanalyse-ökosystem/config/business_rules.yaml"
        self.config_lock = threading.RLock()
        self._config_cache = None
        self._last_modified = None
        
        # Config-Directory erstellen falls nicht vorhanden
        Path(self.config_path).parent.mkdir(parents=True, exist_ok=True)
        
        # Default-Config erstellen falls nicht vorhanden
        if not Path(self.config_path).exists():
            self._create_default_config()
    
    def _create_default_config(self):
        """Default-Konfiguration erstellen"""
        default_config = {
            "version": "1.0",
            "description": "Trading Rules und Business-Logic-Parameter für Aktienanalyse-Ökosystem",
            "last_updated": datetime.utcnow().isoformat(),
            
            "global_settings": {
                "enable_hot_reload": True,
                "validation_timeout_seconds": 30,
                "max_concurrent_orders": 50,
                "emergency_stop_enabled": True
            },
            
            "trading_rules": [
                {
                    "rule_id": "max_position_size",
                    "name": "Maximum Position Size",
                    "description": "Limitiert Positionsgröße auf max. % des Portfolios",
                    "rule_type": "pre_trade",
                    "severity": "error",
                    "is_active": True,
                    "parameters": {
                        "max_position_percent": 10,
                        "exclude_etfs": False,
                        "emergency_max_percent": 5
                    }
                },
                {
                    "rule_id": "sufficient_cash",
                    "name": "Sufficient Cash Balance",
                    "description": "Prüft ausreichende Cash-Balance für Order",
                    "rule_type": "pre_trade",
                    "severity": "error",
                    "is_active": True,
                    "parameters": {
                        "min_cash_buffer_percent": 5,
                        "emergency_cash_percent": 10,
                        "margin_enabled": False
                    }
                },
                {
                    "rule_id": "sector_concentration",
                    "name": "Sector Concentration Limit",
                    "description": "Limitiert Konzentration pro Sektor",
                    "rule_type": "pre_trade",
                    "severity": "warning",
                    "is_active": True,
                    "parameters": {
                        "max_sector_percent": 25,
                        "technology_max_percent": 30,
                        "finance_max_percent": 20,
                        "exclude_diversified_etfs": True
                    }
                },
                {
                    "rule_id": "daily_loss_limit",
                    "name": "Daily Loss Limit",
                    "description": "Stoppt Trading bei Tagesverlust-Limit",
                    "rule_type": "portfolio_risk",
                    "severity": "critical",
                    "is_active": True,
                    "parameters": {
                        "max_daily_loss_percent": 5,
                        "max_weekly_loss_percent": 10,
                        "stop_trading_on_limit": True,
                        "notification_at_percent": 3
                    }
                },
                {
                    "rule_id": "market_hours",
                    "name": "Market Hours Check",
                    "description": "Prüft ob Markt geöffnet ist",
                    "rule_type": "pre_trade",
                    "severity": "warning",
                    "is_active": True,
                    "parameters": {
                        "allow_after_hours": False,
                        "allow_weekend_crypto": True,
                        "market_schedules": {
                            "XETRA": {"open": "09:00", "close": "17:30", "timezone": "Europe/Berlin"},
                            "NYSE": {"open": "09:30", "close": "16:00", "timezone": "America/New_York"}
                        }
                    }
                },
                {
                    "rule_id": "high_volatility_warning",
                    "name": "High Volatility Warning",
                    "description": "Warnt bei hoher Marktvolatilität",
                    "rule_type": "pre_trade",
                    "severity": "warning",
                    "is_active": True,
                    "parameters": {
                        "volatility_threshold": 30,
                        "vix_threshold": 25,
                        "reduce_position_size": True,
                        "max_position_during_volatility": 5
                    }
                },
                {
                    "rule_id": "correlation_limit",
                    "name": "Portfolio Correlation Limit",
                    "description": "Limitiert hoch-korrelierte Positionen",
                    "rule_type": "pre_trade",
                    "severity": "warning",
                    "is_active": True,
                    "parameters": {
                        "max_correlation": 0.8,
                        "lookback_days": 60,
                        "min_positions_for_check": 3
                    }
                },
                {
                    "rule_id": "liquidity_check",
                    "name": "Liquidity Check",
                    "description": "Prüft Liquidität vor Order-Placement",
                    "rule_type": "pre_trade",
                    "severity": "warning",
                    "is_active": True,
                    "parameters": {
                        "min_daily_volume": 100000,
                        "max_spread_percent": 2,
                        "min_market_cap": 1000000000
                    }
                }
            ],
            
            "risk_scoring": {
                "benchmarks": {
                    "portfolio_concentration": 20,
                    "sector_concentration": 25,
                    "daily_volatility": 2,
                    "portfolio_beta": 1.2,
                    "var_95": 5,
                    "max_drawdown": 10,
                    "cash_ratio": 5,
                    "liquidity_score": 80
                },
                "weights": {
                    "concentration_risk": 0.25,
                    "market_risk": 0.30,
                    "liquidity_risk": 0.15,
                    "sector_risk": 0.20,
                    "volatility_risk": 0.10
                },
                "risk_levels": {
                    "low": {"max_score": 25, "color": "green"},
                    "medium": {"max_score": 50, "color": "yellow"},
                    "high": {"max_score": 75, "color": "orange"},
                    "critical": {"max_score": 100, "color": "red"}
                }
            },
            
            "rebalancing": {
                "rules": {
                    "max_drift_threshold": 5,
                    "min_trade_amount": 100,
                    "max_turnover_percent": 20,
                    "cost_threshold_percent": 0.5
                },
                "strategies": {
                    "threshold": {"enabled": True, "default_threshold": 5},
                    "periodic": {"enabled": True, "default_frequency_days": 90},
                    "smart_beta": {"enabled": False, "factors": ["momentum", "quality"]},
                    "risk_parity": {"enabled": False, "target_risk": 15}
                }
            }
        }
        
        self._save_config(default_config)
        print(f"✅ Created default configuration at {self.config_path}")
    
    def get_config(self) -> Dict[str, Any]:
        """Vollständige Konfiguration laden"""
        with self.config_lock:
            if self._should_reload_config():
                self._load_config()
            return self._config_cache.copy() if self._config_cache else {}
    
    def get_rules_config(self) -> Dict[str, Any]:
        """Trading-Rules-Konfiguration laden"""
        config = self.get_config()
        return {
            "trading_rules": config.get("trading_rules", []),
            "global_settings": config.get("global_settings", {})
        }
    
    def get_risk_scoring_config(self) -> Dict[str, Any]:
        """Risk-Scoring-Konfiguration laden"""
        return self.get_config().get("risk_scoring", {})
    
    def get_rebalancing_config(self) -> Dict[str, Any]:
        """Rebalancing-Konfiguration laden"""
        return self.get_config().get("rebalancing", {})
    
    def update_rule_parameters(self, rule_id: str, new_parameters: Dict[str, Any]) -> bool:
        """Rule-Parameter aktualisieren und persistieren"""
        with self.config_lock:
            config = self.get_config()
            
            # Rule finden und Parameter aktualisieren
            for rule in config.get("trading_rules", []):
                if rule.get("rule_id") == rule_id:
                    rule["parameters"].update(new_parameters)
                    config["last_updated"] = datetime.utcnow().isoformat()
                    
                    self._save_config(config)
                    self._config_cache = None  # Cache invalidieren
                    return True
            
            return False
    
    def update_risk_benchmarks(self, new_benchmarks: Dict[str, Any]) -> bool:
        """Risk-Benchmarks aktualisieren"""
        with self.config_lock:
            config = self.get_config()
            
            if "risk_scoring" not in config:
                config["risk_scoring"] = {}
            if "benchmarks" not in config["risk_scoring"]:
                config["risk_scoring"]["benchmarks"] = {}
            
            config["risk_scoring"]["benchmarks"].update(new_benchmarks)
            config["last_updated"] = datetime.utcnow().isoformat()
            
            self._save_config(config)
            self._config_cache = None
            return True
    
    def update_rebalancing_rules(self, new_rules: Dict[str, Any]) -> bool:
        """Rebalancing-Rules aktualisieren"""
        with self.config_lock:
            config = self.get_config()
            
            if "rebalancing" not in config:
                config["rebalancing"] = {}
            if "rules" not in config["rebalancing"]:
                config["rebalancing"]["rules"] = {}
            
            config["rebalancing"]["rules"].update(new_rules)
            config["last_updated"] = datetime.utcnow().isoformat()
            
            self._save_config(config)
            self._config_cache = None
            return True
    
    def toggle_rule(self, rule_id: str, is_active: bool) -> bool:
        """Rule aktivieren/deaktivieren"""
        with self.config_lock:
            config = self.get_config()
            
            for rule in config.get("trading_rules", []):
                if rule.get("rule_id") == rule_id:
                    rule["is_active"] = is_active
                    config["last_updated"] = datetime.utcnow().isoformat()
                    
                    self._save_config(config)
                    self._config_cache = None
                    return True
            
            return False
    
    def add_custom_rule(self, rule_config: Dict[str, Any]) -> bool:
        """Custom-Rule hinzufügen"""
        with self.config_lock:
            config = self.get_config()
            
            # Prüfen ob Rule-ID bereits existiert
            existing_ids = [rule.get("rule_id") for rule in config.get("trading_rules", [])]
            if rule_config.get("rule_id") in existing_ids:
                return False
            
            config["trading_rules"].append(rule_config)
            config["last_updated"] = datetime.utcnow().isoformat()
            
            self._save_config(config)
            self._config_cache = None
            return True
    
    def remove_rule(self, rule_id: str) -> bool:
        """Rule entfernen"""
        with self.config_lock:
            config = self.get_config()
            
            original_count = len(config.get("trading_rules", []))
            config["trading_rules"] = [
                rule for rule in config.get("trading_rules", [])
                if rule.get("rule_id") != rule_id
            ]
            
            if len(config["trading_rules"]) < original_count:
                config["last_updated"] = datetime.utcnow().isoformat()
                self._save_config(config)
                self._config_cache = None
                return True
            
            return False
    
    def reload_config(self):
        """Konfiguration neu laden (Hot-Reload)"""
        with self.config_lock:
            self._config_cache = None
            self._load_config()
    
    def validate_config(self) -> List[str]:
        """Konfiguration validieren"""
        errors = []
        config = self.get_config()
        
        # Trading-Rules validieren
        for rule in config.get("trading_rules", []):
            if not rule.get("rule_id"):
                errors.append("Rule missing rule_id")
            if not rule.get("name"):
                errors.append(f"Rule {rule.get('rule_id', 'unknown')} missing name")
            if rule.get("rule_type") not in [rt.value for rt in RuleType]:
                errors.append(f"Rule {rule.get('rule_id', 'unknown')} has invalid rule_type")
            if rule.get("severity") not in [rs.value for rs in RuleSeverity]:
                errors.append(f"Rule {rule.get('rule_id', 'unknown')} has invalid severity")
        
        # Risk-Scoring validieren
        risk_config = config.get("risk_scoring", {})
        benchmarks = risk_config.get("benchmarks", {})
        weights = risk_config.get("weights", {})
        
        if weights:
            total_weight = sum(weights.values())
            if abs(total_weight - 1.0) > 0.01:
                errors.append(f"Risk weights sum to {total_weight}, should be 1.0")
        
        return errors
    
    def export_config(self, export_path: str) -> bool:
        """Konfiguration exportieren"""
        try:
            config = self.get_config()
            export_config = config.copy()
            export_config["exported_at"] = datetime.utcnow().isoformat()
            export_config["source_path"] = str(self.config_path)
            
            self._save_config_to_file(export_config, export_path)
            return True
        except Exception:
            return False
    
    def import_config(self, import_path: str, merge: bool = False) -> bool:
        """Konfiguration importieren"""
        try:
            imported_config = self._load_config_from_file(import_path)
            
            if merge:
                current_config = self.get_config()
                # Merge-Logic hier implementieren
                merged_config = self._merge_configs(current_config, imported_config)
                self._save_config(merged_config)
            else:
                self._save_config(imported_config)
            
            self._config_cache = None
            return True
        except Exception:
            return False
    
    def _should_reload_config(self) -> bool:
        """Prüft ob Config neu geladen werden muss"""
        if not self._config_cache:
            return True
        
        try:
            current_modified = Path(self.config_path).stat().st_mtime
            return current_modified != self._last_modified
        except:
            return True
    
    def _load_config(self):
        """Konfiguration aus Datei laden"""
        try:
            self._config_cache = self._load_config_from_file(self.config_path)
            self._last_modified = Path(self.config_path).stat().st_mtime
        except Exception as e:
            print(f"Failed to load config from {self.config_path}: {str(e)}")
            self._config_cache = {}
    
    def _load_config_from_file(self, file_path: str) -> Dict[str, Any]:
        """Konfiguration aus spezifischer Datei laden"""
        path = Path(file_path)
        
        if not path.exists():
            return {}
        
        with open(path, 'r', encoding='utf-8') as f:
            if path.suffix.lower() == '.json':
                return json.load(f)
            else:  # YAML
                return yaml.safe_load(f) or {}
    
    def _save_config(self, config: Dict[str, Any]):
        """Konfiguration speichern"""
        self._save_config_to_file(config, self.config_path)
    
    def _save_config_to_file(self, config: Dict[str, Any], file_path: str):
        """Konfiguration in spezifische Datei speichern"""
        path = Path(file_path)
        
        with open(path, 'w', encoding='utf-8') as f:
            if path.suffix.lower() == '.json':
                json.dump(config, f, indent=2, ensure_ascii=False)
            else:  # YAML
                yaml.dump(config, f, default_flow_style=False, allow_unicode=True, indent=2)
    
    def _merge_configs(self, base_config: Dict[str, Any], new_config: Dict[str, Any]) -> Dict[str, Any]:
        """Zwei Konfigurationen mergen"""
        merged = base_config.copy()
        
        # Trading-Rules mergen (by rule_id)
        base_rules = {rule.get("rule_id"): rule for rule in merged.get("trading_rules", [])}
        new_rules = {rule.get("rule_id"): rule for rule in new_config.get("trading_rules", [])}
        
        base_rules.update(new_rules)
        merged["trading_rules"] = list(base_rules.values())
        
        # Andere Sections mergen
        for section in ["risk_scoring", "rebalancing", "global_settings"]:
            if section in new_config:
                if section in merged:
                    merged[section].update(new_config[section])
                else:
                    merged[section] = new_config[section]
        
        merged["last_updated"] = datetime.utcnow().isoformat()
        return merged

class TradingRulesEngine:
    """Central Trading-Rules-Engine"""
    
    def __init__(self, config_path: str = None):
        self.rules: Dict[str, TradingRule] = {}
        self.rule_groups: Dict[RuleType, List[str]] = {
            rule_type: [] for rule_type in RuleType
        }
        self.logger = logging.getLogger(__name__)
        self.config_manager = RulesConfigurationManager(config_path)
        
        # Load rules from configuration
        self._load_rules_from_config()
    
    def register_rule(self, rule: TradingRule):
        """Rule registrieren"""
        self.rules[rule.rule_id] = rule
        self.rule_groups[rule.rule_type].append(rule.rule_id)
        self.logger.info(f"Registered trading rule: {rule.rule_id}")
    
    def evaluate_rules(self, rule_type: RuleType, context: Dict[str, Any]) -> List[RuleResult]:
        """Alle Rules eines Types evaluieren"""
        results = []
        
        for rule_id in self.rule_groups[rule_type]:
            if rule_id in self.rules:
                rule = self.rules[rule_id]
                result = rule.evaluate(context)
                results.append(result)
        
        return results
    
    def check_order_placement(self, order_context: Dict[str, Any]) -> List[RuleResult]:
        """Pre-Trade-Rules für Order-Placement prüfen"""
        return self.evaluate_rules(RuleType.PRE_TRADE, order_context)
    
    def check_trade_execution(self, trade_context: Dict[str, Any]) -> List[RuleResult]:
        """Post-Trade-Rules für Trade-Execution prüfen"""
        return self.evaluate_rules(RuleType.POST_TRADE, trade_context)
    
    def check_position_risk(self, position_context: Dict[str, Any]) -> List[RuleResult]:
        """Position-Management-Rules prüfen"""
        return self.evaluate_rules(RuleType.POSITION_MANAGEMENT, position_context)
    
    def check_portfolio_risk(self, portfolio_context: Dict[str, Any]) -> List[RuleResult]:
        """Portfolio-Risk-Rules prüfen"""
        return self.evaluate_rules(RuleType.PORTFOLIO_RISK, portfolio_context)
    
    def _load_rules_from_config(self):
        """Rules aus Konfiguration laden"""
        config = self.config_manager.get_rules_config()
        
        for rule_config in config.get("trading_rules", []):
            if not rule_config.get("is_active", True):
                continue
                
            rule = self._create_rule_from_config(rule_config)
            if rule:
                self.register_rule(rule)
    
    def _create_rule_from_config(self, rule_config: Dict[str, Any]) -> Optional[TradingRule]:
        """Rule aus Config-Definition erstellen"""
        try:
            rule_id = rule_config["rule_id"]
            
            # Evaluation-Function aus Registry holen
            eval_function = self._get_evaluation_function(rule_id)
            if not eval_function:
                self.logger.warning(f"No evaluation function found for rule {rule_id}")
                return None
            
            return TradingRule(
                rule_id=rule_id,
                name=rule_config["name"],
                description=rule_config["description"],
                rule_type=RuleType(rule_config["rule_type"]),
                severity=RuleSeverity(rule_config["severity"]),
                parameters=rule_config.get("parameters", {}),
                is_active=rule_config.get("is_active", True),
                evaluate_function=eval_function
            )
        except Exception as e:
            self.logger.error(f"Failed to create rule from config: {str(e)}")
            return None
    
    def _get_evaluation_function(self, rule_id: str) -> Optional[Callable]:
        """Evaluation-Function für Rule-ID zurückgeben"""
        function_map = {
            "max_position_size": self._evaluate_max_position_size,
            "sufficient_cash": self._evaluate_sufficient_cash,
            "sector_concentration": self._evaluate_sector_concentration,
            "daily_loss_limit": self._evaluate_daily_loss_limit,
            "market_hours": self._evaluate_market_hours,
            "high_volatility_warning": self._evaluate_volatility,
            "max_portfolio_turnover": self._evaluate_portfolio_turnover,
            "correlation_limit": self._evaluate_correlation_limit,
            "liquidity_check": self._evaluate_liquidity_check
        }
        return function_map.get(rule_id)
    
    def reload_configuration(self):
        """Konfiguration neu laden (Hot-Reload)"""
        self.logger.info("Reloading trading rules configuration...")
        
        # Alte Rules löschen
        self.rules.clear()
        for rule_type in RuleType:
            self.rule_groups[rule_type].clear()
        
        # Config neu laden
        self.config_manager.reload_config()
        self._load_rules_from_config()
        
        self.logger.info(f"Reloaded {len(self.rules)} trading rules")
    
    def get_rule_configuration(self, rule_id: str) -> Optional[Dict[str, Any]]:
        """Aktuelle Rule-Konfiguration abrufen"""
        if rule_id not in self.rules:
            return None
        
        rule = self.rules[rule_id]
        return {
            "rule_id": rule.rule_id,
            "name": rule.name,
            "description": rule.description,
            "rule_type": rule.rule_type.value,
            "severity": rule.severity.value,
            "is_active": rule.is_active,
            "parameters": rule.parameters
        }
    
    def update_rule_parameters(self, rule_id: str, new_parameters: Dict[str, Any]) -> bool:
        """Rule-Parameter zur Laufzeit aktualisieren"""
        if rule_id not in self.rules:
            return False
        
        self.rules[rule_id].parameters.update(new_parameters)
        self.rules[rule_id].last_modified = datetime.utcnow()
        
        # Konfiguration persistieren
        self.config_manager.update_rule_parameters(rule_id, new_parameters)
        
        self.logger.info(f"Updated parameters for rule {rule_id}: {new_parameters}")
        return True
    
    # Rule-Evaluation-Functions
    def _evaluate_max_position_size(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Maximale Positionsgröße prüfen"""
        order_value = context.get('order_value', Decimal('0'))
        portfolio_value = context.get('portfolio_value', Decimal('0'))
        max_percent = params.get('max_position_percent', 10)
        
        if portfolio_value > 0:
            position_percent = (order_value / portfolio_value) * 100
            
            if position_percent > max_percent:
                return RuleResult(
                    rule_id="max_position_size",
                    rule_name="Maximum Position Size",
                    passed=False,
                    severity=RuleSeverity.ERROR,
                    message=f"Position size {position_percent:.1f}% exceeds limit of {max_percent}%",
                    recommendation=f"Reduce order size to max €{(portfolio_value * max_percent / 100):.2f}",
                    metrics={"position_percent": position_percent, "limit_percent": max_percent}
                )
        
        return RuleResult(
            rule_id="max_position_size",
            rule_name="Maximum Position Size",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Position size within limits"
        )
    
    def _evaluate_sufficient_cash(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Ausreichende Cash-Balance prüfen"""
        order_value = context.get('order_value', Decimal('0'))
        cash_balance = context.get('cash_balance', Decimal('0'))
        estimated_fees = context.get('estimated_fees', Decimal('0'))
        buffer_percent = params.get('min_cash_buffer_percent', 5)
        
        total_cost = order_value + estimated_fees
        required_cash = total_cost * (1 + buffer_percent / 100)
        
        if cash_balance < required_cash:
            return RuleResult(
                rule_id="sufficient_cash",
                rule_name="Sufficient Cash Balance",
                passed=False,
                severity=RuleSeverity.ERROR,
                message=f"Insufficient cash: €{cash_balance:.2f} available, €{required_cash:.2f} required",
                recommendation=f"Reduce order size or add €{(required_cash - cash_balance):.2f} to portfolio",
                metrics={"available_cash": cash_balance, "required_cash": required_cash}
            )
        
        return RuleResult(
            rule_id="sufficient_cash",
            rule_name="Sufficient Cash Balance",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Sufficient cash available"
        )
    
    def _evaluate_sector_concentration(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Sektor-Konzentration prüfen"""
        asset_sector = context.get('asset_sector', '')
        portfolio_value = context.get('portfolio_value', Decimal('0'))
        order_value = context.get('order_value', Decimal('0'))
        sector_positions = context.get('sector_positions', {})
        max_sector_percent = params.get('max_sector_percent', 25)
        
        if asset_sector and portfolio_value > 0:
            current_sector_value = sector_positions.get(asset_sector, Decimal('0'))
            new_sector_value = current_sector_value + order_value
            new_sector_percent = (new_sector_value / portfolio_value) * 100
            
            if new_sector_percent > max_sector_percent:
                return RuleResult(
                    rule_id="sector_concentration",
                    rule_name="Sector Concentration Limit",
                    passed=False,
                    severity=RuleSeverity.WARNING,
                    message=f"Sector '{asset_sector}' concentration {new_sector_percent:.1f}% exceeds recommended {max_sector_percent}%",
                    recommendation=f"Consider diversification across sectors",
                    metrics={"sector": asset_sector, "concentration_percent": new_sector_percent}
                )
        
        return RuleResult(
            rule_id="sector_concentration",
            rule_name="Sector Concentration Limit",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Sector concentration within limits"
        )
    
    def _evaluate_daily_loss_limit(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Tagesverlust-Limit prüfen"""
        daily_pnl = context.get('daily_pnl', Decimal('0'))
        portfolio_value = context.get('portfolio_value', Decimal('0'))
        max_loss_percent = params.get('max_daily_loss_percent', 5)
        
        if portfolio_value > 0:
            daily_loss_percent = abs(daily_pnl / portfolio_value) * 100
            
            if daily_pnl < 0 and daily_loss_percent > max_loss_percent:
                return RuleResult(
                    rule_id="daily_loss_limit",
                    rule_name="Daily Loss Limit",
                    passed=False,
                    severity=RuleSeverity.CRITICAL,
                    message=f"Daily loss {daily_loss_percent:.1f}% exceeds limit of {max_loss_percent}%",
                    recommendation="Stop trading for today and review risk management",
                    metrics={"daily_loss_percent": daily_loss_percent, "daily_pnl": daily_pnl}
                )
        
        return RuleResult(
            rule_id="daily_loss_limit",
            rule_name="Daily Loss Limit",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Daily loss within acceptable limits"
        )
    
    def _evaluate_market_hours(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Marktzeiten prüfen"""
        current_time = datetime.now()
        exchange = context.get('exchange', 'XETRA')
        allow_after_hours = params.get('allow_after_hours', False)
        
        # Vereinfachte Marktzeiten (XETRA: 9:00-17:30 MEZ)
        if exchange == 'XETRA':
            market_open = current_time.replace(hour=9, minute=0, second=0, microsecond=0)
            market_close = current_time.replace(hour=17, minute=30, second=0, microsecond=0)
            
            is_weekend = current_time.weekday() >= 5
            is_market_hours = market_open <= current_time <= market_close
            
            if is_weekend or (not is_market_hours and not allow_after_hours):
                return RuleResult(
                    rule_id="market_hours",
                    rule_name="Market Hours Check",
                    passed=False,
                    severity=RuleSeverity.WARNING,
                    message=f"Market {exchange} is closed",
                    recommendation="Consider waiting for market open or enabling after-hours trading",
                    metrics={"current_time": current_time.isoformat(), "exchange": exchange}
                )
        
        return RuleResult(
            rule_id="market_hours",
            rule_name="Market Hours Check",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Market is open"
        )
    
    def _evaluate_volatility(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Volatilität prüfen"""
        asset_volatility = context.get('asset_volatility', 0)
        volatility_threshold = params.get('volatility_threshold', 30)
        
        if asset_volatility > volatility_threshold:
            return RuleResult(
                rule_id="high_volatility_warning",
                rule_name="High Volatility Warning",
                passed=False,
                severity=RuleSeverity.WARNING,
                message=f"High volatility detected: {asset_volatility:.1f}% (threshold: {volatility_threshold}%)",
                recommendation="Consider reducing position size or using limit orders",
                metrics={"volatility": asset_volatility, "threshold": volatility_threshold}
            )
        
        return RuleResult(
            rule_id="high_volatility_warning",
            rule_name="High Volatility Warning",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Volatility within normal range"
        )
    
    def _evaluate_correlation_limit(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Portfolio-Korrelations-Limit prüfen"""
        asset_correlations = context.get('asset_correlations', {})
        max_correlation = params.get('max_correlation', 0.8)
        
        if asset_correlations:
            highest_correlation = max(asset_correlations.values())
            
            if highest_correlation > max_correlation:
                return RuleResult(
                    rule_id="correlation_limit",
                    rule_name="Portfolio Correlation Limit",
                    passed=False,
                    severity=RuleSeverity.WARNING,
                    message=f"High correlation detected: {highest_correlation:.2f} (limit: {max_correlation})",
                    recommendation="Consider diversification to reduce correlation risk",
                    metrics={"max_correlation": highest_correlation, "limit": max_correlation}
                )
        
        return RuleResult(
            rule_id="correlation_limit",
            rule_name="Portfolio Correlation Limit",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Portfolio correlations within limits"
        )
    
    def _evaluate_liquidity_check(self, context: Dict[str, Any], params: Dict[str, Any]) -> RuleResult:
        """Liquiditäts-Check für Asset"""
        daily_volume = context.get('daily_volume', 0)
        spread_percent = context.get('spread_percent', 0)
        market_cap = context.get('market_cap', 0)
        
        min_volume = params.get('min_daily_volume', 100000)
        max_spread = params.get('max_spread_percent', 2)
        min_market_cap = params.get('min_market_cap', 1000000000)
        
        issues = []
        
        if daily_volume < min_volume:
            issues.append(f"Low volume: €{daily_volume:,.0f} < €{min_volume:,.0f}")
        
        if spread_percent > max_spread:
            issues.append(f"Wide spread: {spread_percent:.2f}% > {max_spread}%")
        
        if market_cap < min_market_cap:
            issues.append(f"Small market cap: €{market_cap:,.0f} < €{min_market_cap:,.0f}")
        
        if issues:
            return RuleResult(
                rule_id="liquidity_check",
                rule_name="Liquidity Check",
                passed=False,
                severity=RuleSeverity.WARNING,
                message=f"Liquidity concerns: {'; '.join(issues)}",
                recommendation="Consider impact on execution and position sizing",
                metrics={"volume": daily_volume, "spread": spread_percent, "market_cap": market_cap}
            )
        
        return RuleResult(
            rule_id="liquidity_check",
            rule_name="Liquidity Check",
            passed=True,
            severity=RuleSeverity.INFO,
            message="Asset liquidity satisfactory"
        )

# Global Rules-Engine-Instance
trading_rules_engine = TradingRulesEngine()

# Configuration-Management-API
def update_trading_rule_parameter(rule_id: str, parameter_name: str, new_value: Any) -> bool:
    """Helper-Function für Runtime-Parameter-Updates"""
    return trading_rules_engine.update_rule_parameters(rule_id, {parameter_name: new_value})

def reload_trading_rules_configuration():
    """Helper-Function für Configuration-Reload"""
    trading_rules_engine.reload_configuration()

def get_active_trading_rules() -> Dict[str, Dict[str, Any]]:
    """Helper-Function für aktive Rules-Overview"""
    return {
        rule_id: trading_rules_engine.get_rule_configuration(rule_id)
        for rule_id in trading_rules_engine.rules.keys()
    }
```

### 1.2 **Beispiel-Konfigurationsdatei und Hot-Reload-Usage**
```yaml
# /home/mdoehler/aktienanalyse-ökosystem/config/business_rules.yaml
# Beispiel für vollständige Business-Rules-Konfiguration

version: "1.0"
description: "Trading Rules und Business-Logic-Parameter für Aktienanalyse-Ökosystem"
last_updated: "2025-07-26T12:00:00Z"

global_settings:
  enable_hot_reload: true
  validation_timeout_seconds: 30
  max_concurrent_orders: 50
  emergency_stop_enabled: true

trading_rules:
  - rule_id: "max_position_size"
    name: "Maximum Position Size"
    description: "Limitiert Positionsgröße auf max. % des Portfolios"
    rule_type: "pre_trade"
    severity: "error"
    is_active: true
    parameters:
      max_position_percent: 10        # Kann zur Laufzeit geändert werden
      exclude_etfs: false
      emergency_max_percent: 5

  - rule_id: "sufficient_cash"
    name: "Sufficient Cash Balance"
    description: "Prüft ausreichende Cash-Balance für Order"
    rule_type: "pre_trade"
    severity: "error"
    is_active: true
    parameters:
      min_cash_buffer_percent: 5      # Kann zur Laufzeit angepasst werden
      emergency_cash_percent: 10
      margin_enabled: false

  - rule_id: "daily_loss_limit"
    name: "Daily Loss Limit"
    description: "Stoppt Trading bei Tagesverlust-Limit"
    rule_type: "portfolio_risk"
    severity: "critical"
    is_active: true
    parameters:
      max_daily_loss_percent: 5       # Benutzer kann dies nach Risikotoleranz anpassen
      max_weekly_loss_percent: 10
      stop_trading_on_limit: true
      notification_at_percent: 3

risk_scoring:
  benchmarks:
    portfolio_concentration: 20       # User-editierbar via Config-File
    sector_concentration: 25
    daily_volatility: 2
    portfolio_beta: 1.2
    var_95: 5
    max_drawdown: 10
    cash_ratio: 5
    liquidity_score: 80
  weights:
    concentration_risk: 0.25          # Gewichtungen anpassbar
    market_risk: 0.30
    liquidity_risk: 0.15
    sector_risk: 0.20
    volatility_risk: 0.10

rebalancing:
  rules:
    max_drift_threshold: 5            # User kann Rebalancing-Schwellen anpassen
    min_trade_amount: 100
    max_turnover_percent: 20
    cost_threshold_percent: 0.5
  strategies:
    threshold:
      enabled: true
      default_threshold: 5
    periodic:
      enabled: true
      default_frequency_days: 90      # User-konfigurierbar
    smart_beta:
      enabled: false
      factors: ["momentum", "quality"]
    risk_parity:
      enabled: false
      target_risk: 15
```

```python
# shared/business/configuration_usage_examples.py
"""Beispiele für Runtime-Configuration-Management"""

from shared.business.trading_rules_engine import (
    trading_rules_engine, 
    update_trading_rule_parameter,
    reload_trading_rules_configuration,
    get_active_trading_rules
)

def example_runtime_configuration_updates():
    """Beispiele für Runtime-Konfigurationsänderungen"""
    
    # 1. Einzelnen Parameter zur Laufzeit ändern
    print("🔧 Updating max position size parameter...")
    success = update_trading_rule_parameter(
        rule_id="max_position_size", 
        parameter_name="max_position_percent", 
        new_value=15  # Von 10% auf 15% erhöhen
    )
    print(f"✅ Parameter update {'successful' if success else 'failed'}")
    
    # 2. Risk-Limits für volatilie Marktphasen anpassen
    print("🔧 Adjusting risk limits for volatile market...")
    trading_rules_engine.config_manager.update_risk_benchmarks({
        "daily_volatility": 1.5,      # Strenger: von 2% auf 1.5%
        "max_drawdown": 8,            # Strenger: von 10% auf 8%
        "var_95": 4                   # Strenger: von 5% auf 4%
    })
    
    # 3. Rebalancing-Parameter für bessere Performance anpassen
    print("🔧 Updating rebalancing parameters...")
    trading_rules_engine.config_manager.update_rebalancing_rules({
        "max_drift_threshold": 3,     # Häufigeres Rebalancing: von 5% auf 3%
        "default_frequency_days": 60  # Öfteres periodisches Rebalancing
    })
    
    # 4. Hot-Reload nach externen Config-Änderungen
    print("🔄 Performing hot reload...")
    reload_trading_rules_configuration()
    
    # 5. Aktuelle Konfiguration anzeigen
    print("📋 Current active rules:")
    active_rules = get_active_trading_rules()
    for rule_id, config in active_rules.items():
        print(f"  - {rule_id}: {config['name']} ({'active' if config['is_active'] else 'inactive'})")

def example_emergency_risk_adjustments():
    """Beispiel für Notfall-Risikoanpassungen"""
    
    print("🚨 Emergency: Implementing conservative risk settings...")
    
    # Alle Limits drastisch reduzieren
    emergency_updates = [
        ("max_position_size", "max_position_percent", 5),      # Halbiert
        ("daily_loss_limit", "max_daily_loss_percent", 2),     # Strenger
        ("sufficient_cash", "min_cash_buffer_percent", 15),    # Mehr Cash
        ("high_volatility_warning", "volatility_threshold", 20) # Niedrigere Schwelle
    ]
    
    for rule_id, param_name, new_value in emergency_updates:
        success = update_trading_rule_parameter(rule_id, param_name, new_value)
        print(f"  ✅ {rule_id}.{param_name} = {new_value}")
    
    # Global emergency stop aktivieren
    trading_rules_engine.config_manager.get_config()["global_settings"]["emergency_stop_enabled"] = True
    
    print("🔒 Emergency risk settings applied")

def example_strategy_optimization():
    """Beispiel für Strategie-Optimierung basierend auf Performance"""
    
    print("📈 Optimizing strategy based on performance feedback...")
    
    # Basierend auf Portfolio-Performance Anpassungen vornehmen
    performance_context = {
        "portfolio_performance": -3.2,    # -3.2% Performance
        "market_performance": -1.8,       # Market: -1.8%
        "risk_score": 68                  # Hohes Risiko
    }
    
    if performance_context["portfolio_performance"] < performance_context["market_performance"]:
        print("📉 Underperforming market - tightening risk controls...")
        
        # Strengere Risk-Controls
        trading_rules_engine.config_manager.update_risk_benchmarks({
            "portfolio_concentration": 15,  # Weniger Konzentration
            "sector_concentration": 20,     # Mehr Diversifikation
            "portfolio_beta": 1.0           # Weniger Market-Risk
        })
        
        # Häufigeres Rebalancing
        trading_rules_engine.config_manager.update_rebalancing_rules({
            "max_drift_threshold": 2,       # Engere Kontrolle
            "default_frequency_days": 30    # Monatlich statt quarterly
        })
    
    if performance_context["risk_score"] > 65:
        print("⚠️ High risk score - implementing defensive measures...")
        
        # Defensive Parameter
        update_trading_rule_parameter("max_position_size", "max_position_percent", 7)
        update_trading_rule_parameter("daily_loss_limit", "max_daily_loss_percent", 3)
        
    print("✅ Strategy optimization completed")

# Hot-Reload-Event-Handler für File-Watching
import os
from datetime import datetime

class ConfigurationWatcher:
    """File-Watcher für automatisches Hot-Reload bei Config-Änderungen"""
    
    def __init__(self, config_path: str):
        self.config_path = config_path
        self.last_modified = None
        self.update_last_modified()
    
    def update_last_modified(self):
        """Last-Modified-Timestamp aktualisieren"""
        try:
            self.last_modified = os.path.getmtime(self.config_path)
        except OSError:
            self.last_modified = None
    
    def check_for_changes(self) -> bool:
        """Prüfen ob Konfigurationsdatei geändert wurde"""
        try:
            current_modified = os.path.getmtime(self.config_path)
            if current_modified != self.last_modified:
                self.last_modified = current_modified
                return True
        except OSError:
            pass
        return False
    
    def auto_reload_if_changed(self):
        """Automatisches Reload bei Änderungen"""
        if self.check_for_changes():
            print(f"🔄 Configuration file changed, performing hot reload...")
            reload_trading_rules_configuration()
            print(f"✅ Hot reload completed at {datetime.utcnow().isoformat()}")

# Global Configuration-Watcher
config_watcher = ConfigurationWatcher("/home/mdoehler/aktienanalyse-ökosystem/config/business_rules.yaml")
```

### 1.3 **Frontend-Configuration-Interface**

Das Konfigurationssystem wird durch ein benutzerfreundliches Web-Interface erweitert, das es dem Benutzer ermöglicht, alle Business-Rules und Parameter grafisch zu verwalten, ohne direkt mit YAML/JSON-Dateien arbeiten zu müssen.

#### 1.3.1 **Configuration-Management-API**
```python
# services/intelligent-core-service/src/api/configuration_api.py
from flask import Blueprint, jsonify, request
from typing import Dict, List, Any
from shared.business.trading_rules_engine import trading_rules_engine
from dataclasses import dataclass
from decimal import Decimal
import logging

configuration_bp = Blueprint('configuration', __name__, url_prefix='/api/configuration')
logger = logging.getLogger(__name__)

@dataclass
class ConfigurationField:
    """Definition eines konfigurierbaren Feldes für das Frontend"""
    field_id: str
    display_name: str
    description: str
    field_type: str  # "number", "percentage", "boolean", "select", "text"
    current_value: Any
    default_value: Any
    min_value: Any = None
    max_value: Any = None
    step: Any = None
    options: List[Dict[str, Any]] = None
    unit: str = ""
    category: str = ""
    risk_level: str = "medium"  # "low", "medium", "high", "critical"
    affects_trading: bool = True
    example_explanation: str = ""

class ConfigurationMetadata:
    """Metadata und deutsche Beschreibungen für alle konfigurierbaren Parameter"""
    
    @staticmethod
    def get_trading_rules_metadata() -> Dict[str, List[ConfigurationField]]:
        """Trading Rules Metadaten mit deutschen Beschreibungen"""
        return {
            "Positionsgrößen-Management": [
                ConfigurationField(
                    field_id="max_position_size.max_position_percent",
                    display_name="Maximale Positionsgröße",
                    description="Begrenzt die Größe einer einzelnen Position als Prozentsatz des Gesamtportfolios. Eine niedrigere Einstellung reduziert das Konzentrationsrisiko, kann aber die Renditen bei erfolgreichen Positionen begrenzen.",
                    field_type="percentage",
                    current_value=10,
                    default_value=10,
                    min_value=1,
                    max_value=50,
                    step=1,
                    unit="%",
                    category="Risikomanagement",
                    risk_level="high",
                    affects_trading=True,
                    example_explanation="Bei einem Portfolio von €100.000 und 10% Limit darf eine Position maximal €10.000 betragen."
                ),
                ConfigurationField(
                    field_id="max_position_size.emergency_max_percent",
                    display_name="Notfall-Positionslimit",
                    description="Maximale Positionsgröße in Notfallsituationen oder bei hoher Marktvolatilität. Dieser Wert sollte deutlich unter dem normalen Limit liegen.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=1,
                    max_value=25,
                    step=1,
                    unit="%",
                    category="Notfall-Einstellungen",
                    risk_level="critical",
                    affects_trading=True,
                    example_explanation="In volatilen Marktphasen wird automatisch auf 5% reduziert, um das Risiko zu minimieren."
                )
            ],
            
            "Liquiditäts-Management": [
                ConfigurationField(
                    field_id="sufficient_cash.min_cash_buffer_percent",
                    display_name="Mindest-Cash-Puffer",
                    description="Mindestanteil an liquiden Mitteln, der im Portfolio verbleiben muss. Ein höherer Puffer bietet mehr Flexibilität für Gelegenheiten, reduziert aber die Marktexposition.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=0,
                    max_value=30,
                    step=1,
                    unit="%",
                    category="Liquidität",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Bei 5% Cash-Puffer bleiben von €100.000 mindestens €5.000 in liquiden Mitteln."
                ),
                ConfigurationField(
                    field_id="sufficient_cash.emergency_cash_percent",
                    display_name="Notfall-Cash-Reserve",
                    description="Erhöhte Cash-Reserve in Notfallsituationen. Bietet zusätzliche Sicherheit bei Marktturbulenzen oder unerwarteten Ereignissen.",
                    field_type="percentage",
                    current_value=10,
                    default_value=10,
                    min_value=5,
                    max_value=50,
                    step=1,
                    unit="%",
                    category="Notfall-Einstellungen",
                    risk_level="high",
                    affects_trading=True,
                    example_explanation="In Krisenzeiten wird automatisch 10% des Portfolios in Cash gehalten."
                )
            ],
            
            "Verlust-Limits": [
                ConfigurationField(
                    field_id="daily_loss_limit.max_daily_loss_percent",
                    display_name="Tägliches Verlustlimit",
                    description="Maximaler akzeptabler Tagesverlust als Prozentsatz des Portfoliowerts. Bei Erreichen werden automatisch alle Handelstätigkeiten gestoppt.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=1,
                    max_value=20,
                    step=0.5,
                    unit="%",
                    category="Verlustbegrenzung",
                    risk_level="critical",
                    affects_trading=True,
                    example_explanation="Bei €100.000 Portfolio wird bei €5.000 Tagesverlust automatisch gestoppt."
                ),
                ConfigurationField(
                    field_id="daily_loss_limit.max_weekly_loss_percent",
                    display_name="Wöchentliches Verlustlimit",
                    description="Maximaler akzeptabler Wochenverlust. Hilft dabei, Verlustserien frühzeitig zu erkennen und zu begrenzen.",
                    field_type="percentage",
                    current_value=10,
                    default_value=10,
                    min_value=2,
                    max_value=30,
                    step=1,
                    unit="%",
                    category="Verlustbegrenzung",
                    risk_level="high",
                    affects_trading=True,
                    example_explanation="Wöchentliche Verluste werden auf €10.000 bei €100.000 Portfolio begrenzt."
                ),
                ConfigurationField(
                    field_id="daily_loss_limit.notification_at_percent",
                    display_name="Vorwarnung bei Verlust",
                    description="Schwellenwert für Benachrichtigungen bei Verlusten, bevor das Handelslimit erreicht wird. Ermöglicht manuelle Intervention.",
                    field_type="percentage",
                    current_value=3,
                    default_value=3,
                    min_value=1,
                    max_value=15,
                    step=0.5,
                    unit="%",
                    category="Benachrichtigungen",
                    risk_level="medium",
                    affects_trading=False,
                    example_explanation="Bei 3% Verlust (€3.000) erhalten Sie eine Warnung, bevor bei 5% gestoppt wird."
                )
            ],
            
            "Diversifikation": [
                ConfigurationField(
                    field_id="sector_concentration.max_sector_percent",
                    display_name="Maximale Sektor-Konzentration",
                    description="Maximaler Anteil des Portfolios, der in einen einzelnen Wirtschaftssektor investiert werden darf. Höhere Diversifikation reduziert sektorspezifische Risiken.",
                    field_type="percentage",
                    current_value=25,
                    default_value=25,
                    min_value=10,
                    max_value=60,
                    step=5,
                    unit="%",
                    category="Diversifikation",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Maximal 25% des Portfolios dürfen in Technologie-Aktien investiert werden."
                ),
                ConfigurationField(
                    field_id="sector_concentration.technology_max_percent",
                    display_name="Technologie-Sektor Limit",
                    description="Spezifisches Limit für den Technologie-Sektor aufgrund seiner typisch höheren Volatilität.",
                    field_type="percentage",
                    current_value=30,
                    default_value=30,
                    min_value=10,
                    max_value=70,
                    step=5,
                    unit="%",
                    category="Sektor-spezifisch",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Technologie-Aktien haben ein eigenes Limit von 30% des Portfolios."
                )
            ],
            
            "Markt-Timing": [
                ConfigurationField(
                    field_id="market_hours.allow_after_hours",
                    display_name="Handel außerhalb der Marktzeiten",
                    description="Erlaubt den Handel außerhalb der regulären Börsenzeiten. After-Hours-Trading kann höhere Spreads und geringere Liquidität haben.",
                    field_type="boolean",
                    current_value=False,
                    default_value=False,
                    category="Markt-Timing",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Wenn aktiviert, können Orders auch nach 17:30 Uhr (XETRA) platziert werden."
                ),
                ConfigurationField(
                    field_id="market_hours.allow_weekend_crypto",
                    display_name="Krypto-Handel am Wochenende",
                    description="Ermöglicht den Handel mit Kryptowährungen auch an Wochenenden, da diese Märkte 24/7 geöffnet sind.",
                    field_type="boolean",
                    current_value=True,
                    default_value=True,
                    category="Kryptowährungen",
                    risk_level="low",
                    affects_trading=True,
                    example_explanation="Bitcoin und andere Kryptos können auch samstags und sonntags gehandelt werden."
                )
            ],
            
            "Volatilitäts-Management": [
                ConfigurationField(
                    field_id="high_volatility_warning.volatility_threshold",
                    display_name="Volatilitäts-Warnschwelle",
                    description="Schwellenwert für die Tagesvolatilität eines Assets, ab dem Warnungen ausgegeben werden. Hilft dabei, besonders riskante Investments zu identifizieren.",
                    field_type="percentage",
                    current_value=30,
                    default_value=30,
                    min_value=10,
                    max_value=100,
                    step=5,
                    unit="%",
                    category="Volatilität",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Assets mit über 30% Tagesvolatilität lösen eine Warnung aus."
                ),
                ConfigurationField(
                    field_id="high_volatility_warning.vix_threshold",
                    display_name="VIX-Warnschwelle",
                    display_name="VIX-Warnschwelle",
                    description="Schwellenwert für den VIX (Volatilitätsindex), ab dem der Markt als volatil eingestuft wird. Der VIX misst die erwartete Marktvolatilität.",
                    field_type="number",
                    current_value=25,
                    default_value=25,
                    min_value=10,
                    max_value=60,
                    step=1,
                    unit="VIX",
                    category="Markt-Indikatoren",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="VIX über 25 signalisiert erhöhte Marktangst und Vorsicht bei neuen Positionen."
                ),
                ConfigurationField(
                    field_id="high_volatility_warning.max_position_during_volatility",
                    display_name="Positionsgröße bei hoher Volatilität",
                    description="Reduzierte maximale Positionsgröße während Phasen hoher Marktvolatilität als zusätzliche Risikominderung.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=1,
                    max_value=20,
                    step=1,
                    unit="%",
                    category="Volatilitäts-Anpassung",
                    risk_level="high",
                    affects_trading=True,
                    example_explanation="Bei hoher Volatilität werden Positionen automatisch auf 5% des Portfolios begrenzt."
                )
            ]
        }
    
    @staticmethod
    def get_risk_scoring_metadata() -> Dict[str, List[ConfigurationField]]:
        """Risk Scoring Metadaten mit deutschen Beschreibungen"""
        return {
            "Risiko-Benchmarks": [
                ConfigurationField(
                    field_id="risk_scoring.benchmarks.portfolio_concentration",
                    display_name="Portfolio-Konzentrations-Benchmark",
                    description="Referenzwert für die maximale Konzentration in einer Position. Werte darüber gelten als riskant und erhöhen den Risk-Score.",
                    field_type="percentage",
                    current_value=20,
                    default_value=20,
                    min_value=5,
                    max_value=50,
                    step=5,
                    unit="%",
                    category="Konzentrations-Risiko",
                    risk_level="high",
                    affects_trading=False,
                    example_explanation="Positionen über 20% des Portfolios werden als konzentriert und riskant bewertet."
                ),
                ConfigurationField(
                    field_id="risk_scoring.benchmarks.daily_volatility",
                    display_name="Tagesvolatilitäts-Benchmark",
                    description="Referenzwert für akzeptable Tagesvolatilität des Portfolios. Höhere Volatilität führt zu höheren Risk-Scores.",
                    field_type="percentage",
                    current_value=2,
                    default_value=2,
                    min_value=0.5,
                    max_value=10,
                    step=0.5,
                    unit="%",
                    category="Volatilitäts-Risiko",
                    risk_level="medium",
                    affects_trading=False,
                    example_explanation="Portfolios mit über 2% täglicher Volatilität gelten als volatil."
                ),
                ConfigurationField(
                    field_id="risk_scoring.benchmarks.portfolio_beta",
                    display_name="Portfolio-Beta-Benchmark",
                    description="Referenzwert für die Marktkorrelation (Beta). Beta > 1 bedeutet höhere Schwankungen als der Markt.",
                    field_type="number",
                    current_value=1.2,
                    default_value=1.2,
                    min_value=0.5,
                    max_value=3.0,
                    step=0.1,
                    unit="β",
                    category="Markt-Risiko",
                    risk_level="medium",
                    affects_trading=False,
                    example_explanation="Beta 1.2 bedeutet 20% höhere Schwankungen als der Gesamtmarkt."
                ),
                ConfigurationField(
                    field_id="risk_scoring.benchmarks.max_drawdown",
                    display_name="Maximum-Drawdown-Benchmark",
                    description="Referenzwert für den maximalen Portfoliorückgang vom Höchststand. Misst die Widerstandsfähigkeit in schwierigen Marktphasen.",
                    field_type="percentage",
                    current_value=10,
                    default_value=10,
                    min_value=3,
                    max_value=30,
                    step=1,
                    unit="%",
                    category="Verlust-Risiko",
                    risk_level="high",
                    affects_trading=False,
                    example_explanation="Drawdowns über 10% gelten als signifikant und erhöhen den Risk-Score."
                )
            ],
            
            "Risiko-Gewichtungen": [
                ConfigurationField(
                    field_id="risk_scoring.weights.concentration_risk",
                    display_name="Gewichtung: Konzentrationsrisiko",
                    description="Einfluss des Konzentrationsrisikos auf den Gesamt-Risk-Score. Höhere Gewichtung bedeutet stärkere Betonung der Diversifikation.",
                    field_type="percentage",
                    current_value=25,
                    default_value=25,
                    min_value=0,
                    max_value=50,
                    step=5,
                    unit="%",
                    category="Risiko-Gewichtungen",
                    risk_level="medium",
                    affects_trading=False,
                    example_explanation="25% des Risk-Scores basiert auf der Portfolio-Konzentration."
                ),
                ConfigurationField(
                    field_id="risk_scoring.weights.market_risk",
                    display_name="Gewichtung: Marktrisiko",
                    description="Einfluss des allgemeinen Marktrisikos (Beta, Volatilität) auf den Gesamt-Risk-Score.",
                    field_type="percentage",
                    current_value=30,
                    default_value=30,
                    min_value=10,
                    max_value=60,
                    step=5,
                    unit="%",
                    category="Risiko-Gewichtungen",
                    risk_level="medium",
                    affects_trading=False,
                    example_explanation="30% des Risk-Scores basiert auf der Marktvolatilität und Beta."
                ),
                ConfigurationField(
                    field_id="risk_scoring.weights.liquidity_risk",
                    display_name="Gewichtung: Liquiditätsrisiko",
                    description="Einfluss der Asset-Liquidität auf den Risk-Score. Wichtiger bei kleineren oder exotischen Investments.",
                    field_type="percentage",
                    current_value=15,
                    default_value=15,
                    min_value=0,
                    max_value=40,
                    step=5,
                    unit="%",
                    category="Risiko-Gewichtungen",
                    risk_level="low",
                    affects_trading=False,
                    example_explanation="15% des Risk-Scores basiert auf der Handelbarkeit der Assets."
                )
            ]
        }
    
    @staticmethod
    def get_rebalancing_metadata() -> Dict[str, List[ConfigurationField]]:
        """Rebalancing Metadaten mit deutschen Beschreibungen"""
        return {
            "Rebalancing-Regeln": [
                ConfigurationField(
                    field_id="rebalancing.rules.max_drift_threshold",
                    display_name="Maximale Abweichung für Rebalancing",
                    description="Prozentuale Abweichung der aktuellen von der Ziel-Allokation, die ein Rebalancing auslöst. Niedrigere Werte führen zu häufigerem Rebalancing.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=1,
                    max_value=15,
                    step=1,
                    unit="%",
                    category="Rebalancing-Trigger",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Bei 5% Abweichung (z.B. 45% statt 50% Aktien) wird automatisch rebalanciert."
                ),
                ConfigurationField(
                    field_id="rebalancing.rules.min_trade_amount",
                    display_name="Mindest-Handelsbetrag",
                    description="Mindestbetrag für einzelne Rebalancing-Trades. Verhindert zu kleine Transaktionen mit unverhältnismäßig hohen Kosten.",
                    field_type="number",
                    current_value=100,
                    default_value=100,
                    min_value=25,
                    max_value=1000,
                    step=25,
                    unit="€",
                    category="Handels-Effizienz",
                    risk_level="low",
                    affects_trading=True,
                    example_explanation="Rebalancing-Trades unter €100 werden vermieden, um Kosten zu sparen."
                ),
                ConfigurationField(
                    field_id="rebalancing.rules.cost_threshold_percent",
                    display_name="Maximale Rebalancing-Kosten",
                    description="Maximale Kosten für Rebalancing als Prozentsatz des Portfoliowerts. Verhindert kostspieliges Rebalancing bei kleinen Portfolios.",
                    field_type="percentage",
                    current_value=0.5,
                    default_value=0.5,
                    min_value=0.1,
                    max_value=2.0,
                    step=0.1,
                    unit="%",
                    category="Kosten-Kontrolle",
                    risk_level="low",
                    affects_trading=True,
                    example_explanation="Rebalancing wird nur durchgeführt wenn Kosten unter 0.5% des Portfolios liegen."
                )
            ],
            
            "Rebalancing-Strategien": [
                ConfigurationField(
                    field_id="rebalancing.strategies.periodic.default_frequency_days",
                    display_name="Periodisches Rebalancing-Intervall",
                    description="Zeitintervall in Tagen für regelmäßiges Rebalancing, unabhängig von der Drift. Längere Intervalle reduzieren Kosten, können aber Abweichungen verstärken.",
                    field_type="number",
                    current_value=90,
                    default_value=90,
                    min_value=7,
                    max_value=365,
                    step=7,
                    unit="Tage",
                    category="Periodisches Rebalancing",
                    risk_level="low",
                    affects_trading=True,
                    example_explanation="Alle 90 Tage (quarterly) wird das Portfolio automatisch rebalanciert."
                ),
                ConfigurationField(
                    field_id="rebalancing.strategies.threshold.default_threshold",
                    display_name="Schwellen-basiertes Rebalancing",
                    description="Abweichungschwelle für schwellen-basiertes Rebalancing. Ergänzt die globale Drift-Schwelle mit strategiespezifischen Einstellungen.",
                    field_type="percentage",
                    current_value=5,
                    default_value=5,
                    min_value=2,
                    max_value=20,
                    step=1,
                    unit="%",
                    category="Schwellen-Rebalancing",
                    risk_level="medium",
                    affects_trading=True,
                    example_explanation="Rebalancing wird bei 5% Abweichung von der Ziel-Allokation ausgelöst."
                )
            ]
        }

@configuration_bp.route('/metadata', methods=['GET'])
def get_configuration_metadata():
    """Vollständige Metadaten für alle konfigurierbaren Parameter"""
    try:
        metadata = {
            "trading_rules": ConfigurationMetadata.get_trading_rules_metadata(),
            "risk_scoring": ConfigurationMetadata.get_risk_scoring_metadata(),
            "rebalancing": ConfigurationMetadata.get_rebalancing_metadata()
        }
        
        return jsonify({
            "success": True,
            "metadata": metadata,
            "categories": _get_unique_categories(metadata)
        })
    
    except Exception as e:
        logger.error(f"Error getting configuration metadata: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

def _get_unique_categories(metadata: Dict[str, Any]) -> List[str]:
    """Extrahiert alle eindeutigen Kategorien aus den Metadaten"""
    categories = set()
    for section in metadata.values():
        for category_fields in section.values():
            for field in category_fields:
                categories.add(field.category)
    return sorted(list(categories))

@configuration_bp.route('/current', methods=['GET'])
def get_current_configuration():
    """Aktuelle Konfigurationswerte abrufen"""
    try:
        config = trading_rules_engine.config_manager.get_config()
        
        # Flache Struktur für Frontend erstellen
        flat_config = _flatten_configuration(config)
        
        return jsonify({
            "success": True,
            "configuration": flat_config,
            "last_updated": config.get("last_updated"),
            "version": config.get("version")
        })
    
    except Exception as e:
        logger.error(f"Error getting current configuration: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

def _flatten_configuration(config: Dict[str, Any]) -> Dict[str, Any]:
    """Konvertiert hierarchische Config in flache Struktur für Frontend"""
    flat = {}
    
    # Trading Rules
    for rule in config.get("trading_rules", []):
        rule_id = rule.get("rule_id")
        for param_name, param_value in rule.get("parameters", {}).items():
            flat[f"{rule_id}.{param_name}"] = param_value
        
        # Rule-level settings
        flat[f"{rule_id}.is_active"] = rule.get("is_active", True)
    
    # Risk Scoring
    risk_scoring = config.get("risk_scoring", {})
    for benchmark_name, benchmark_value in risk_scoring.get("benchmarks", {}).items():
        flat[f"risk_scoring.benchmarks.{benchmark_name}"] = benchmark_value
    
    for weight_name, weight_value in risk_scoring.get("weights", {}).items():
        flat[f"risk_scoring.weights.{weight_name}"] = weight_value
    
    # Rebalancing
    rebalancing = config.get("rebalancing", {})
    for rule_name, rule_value in rebalancing.get("rules", {}).items():
        flat[f"rebalancing.rules.{rule_name}"] = rule_value
    
    for strategy_name, strategy_config in rebalancing.get("strategies", {}).items():
        if isinstance(strategy_config, dict):
            for setting_name, setting_value in strategy_config.items():
                flat[f"rebalancing.strategies.{strategy_name}.{setting_name}"] = setting_value
    
    return flat

@configuration_bp.route('/update', methods=['POST'])
def update_configuration():
    """Konfigurationswerte aktualisieren"""
    try:
        data = request.get_json()
        field_id = data.get('field_id')
        new_value = data.get('value')
        
        if not field_id:
            return jsonify({"success": False, "error": "field_id is required"}), 400
        
        # Validation der neuen Werte
        validation_result = _validate_configuration_value(field_id, new_value)
        if not validation_result["valid"]:
            return jsonify({
                "success": False, 
                "error": f"Ungültiger Wert: {validation_result['error']}"
            }), 400
        
        # Update durchführen
        success = _update_configuration_value(field_id, new_value)
        
        if success:
            # Hot-Reload der Rules-Engine
            trading_rules_engine.reload_configuration()
            
            return jsonify({
                "success": True,
                "message": f"Konfiguration '{field_id}' erfolgreich aktualisiert",
                "new_value": new_value
            })
        else:
            return jsonify({
                "success": False,
                "error": "Konfigurationswert konnte nicht aktualisiert werden"
            }), 500
    
    except Exception as e:
        logger.error(f"Error updating configuration: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

def _validate_configuration_value(field_id: str, value: Any) -> Dict[str, Any]:
    """Validiert einen Konfigurationswert"""
    try:
        # Metadata für Validation abrufen
        all_metadata = {
            **ConfigurationMetadata.get_trading_rules_metadata(),
            **ConfigurationMetadata.get_risk_scoring_metadata(),
            **ConfigurationMetadata.get_rebalancing_metadata()
        }
        
        # Field-Metadata finden
        field_metadata = None
        for category_fields in all_metadata.values():
            for field in category_fields:
                if field.field_id == field_id:
                    field_metadata = field
                    break
        
        if not field_metadata:
            return {"valid": False, "error": f"Unbekannter Parameter: {field_id}"}
        
        # Type-spezifische Validation
        if field_metadata.field_type in ["number", "percentage"]:
            try:
                numeric_value = float(value)
                if field_metadata.min_value is not None and numeric_value < field_metadata.min_value:
                    return {"valid": False, "error": f"Wert muss mindestens {field_metadata.min_value} sein"}
                if field_metadata.max_value is not None and numeric_value > field_metadata.max_value:
                    return {"valid": False, "error": f"Wert darf maximal {field_metadata.max_value} sein"}
            except (ValueError, TypeError):
                return {"valid": False, "error": "Numerischer Wert erwartet"}
        
        elif field_metadata.field_type == "boolean":
            if not isinstance(value, bool):
                return {"valid": False, "error": "Boolean-Wert erwartet"}
        
        elif field_metadata.field_type == "select":
            if field_metadata.options:
                valid_options = [opt.get("value") for opt in field_metadata.options]
                if value not in valid_options:
                    return {"valid": False, "error": f"Wert muss einer von {valid_options} sein"}
        
        return {"valid": True}
    
    except Exception as e:
        return {"valid": False, "error": f"Validierungsfehler: {str(e)}"}

def _update_configuration_value(field_id: str, value: Any) -> bool:
    """Aktualisiert einen spezifischen Konfigurationswert"""
    try:
        parts = field_id.split('.')
        
        if len(parts) >= 2 and parts[0] in ['max_position_size', 'sufficient_cash', 'daily_loss_limit', 'sector_concentration', 'market_hours', 'high_volatility_warning', 'correlation_limit', 'liquidity_check']:
            # Trading Rule Parameter
            rule_id = parts[0]
            param_name = parts[1]
            return trading_rules_engine.config_manager.update_rule_parameters(rule_id, {param_name: value})
        
        elif parts[0] == "risk_scoring":
            if parts[1] == "benchmarks":
                return trading_rules_engine.config_manager.update_risk_benchmarks({parts[2]: value})
            elif parts[1] == "weights":
                # Gewichtungen müssen in Summe 1.0 ergeben
                current_config = trading_rules_engine.config_manager.get_risk_scoring_config()
                weights = current_config.get("weights", {}).copy()
                weights[parts[2]] = value / 100  # Frontend sendet Prozent, intern als Dezimal
                
                total_weight = sum(weights.values())
                if abs(total_weight - 1.0) > 0.01:
                    logger.warning(f"Weight sum is {total_weight}, normalizing to 1.0")
                    # Normalisierung der Gewichtungen
                    normalized_weights = {k: v / total_weight for k, v in weights.items()}
                    return trading_rules_engine.config_manager.get_config()["risk_scoring"]["weights"].update(normalized_weights)
                else:
                    return trading_rules_engine.config_manager.get_config()["risk_scoring"]["weights"].update({parts[2]: value / 100})
        
        elif parts[0] == "rebalancing":
            if parts[1] == "rules":
                return trading_rules_engine.config_manager.update_rebalancing_rules({parts[2]: value})
            elif parts[1] == "strategies":
                # Strategy-spezifische Updates
                current_config = trading_rules_engine.config_manager.get_rebalancing_config()
                strategies = current_config.get("strategies", {}).copy()
                
                if parts[2] not in strategies:
                    strategies[parts[2]] = {}
                strategies[parts[2]][parts[3]] = value
                
                return trading_rules_engine.config_manager.update_rebalancing_rules({"strategies": strategies})
        
        return False
    
    except Exception as e:
        logger.error(f"Error updating configuration value {field_id}: {str(e)}")
        return False

@configuration_bp.route('/presets', methods=['GET'])
def get_configuration_presets():
    """Vordefinierte Konfigurationspresets abrufen"""
    presets = {
        "conservative": {
            "name": "Konservativ",
            "description": "Sicherheitsorientierte Einstellungen mit niedrigen Risiko-Limits",
            "settings": {
                "max_position_size.max_position_percent": 5,
                "daily_loss_limit.max_daily_loss_percent": 2,
                "sufficient_cash.min_cash_buffer_percent": 15,
                "high_volatility_warning.volatility_threshold": 20,
                "rebalancing.rules.max_drift_threshold": 3
            },
            "risk_profile": "low"
        },
        "balanced": {
            "name": "Ausgewogen",
            "description": "Ausgewogene Einstellungen für moderate Risikobereitschaft",
            "settings": {
                "max_position_size.max_position_percent": 10,
                "daily_loss_limit.max_daily_loss_percent": 5,
                "sufficient_cash.min_cash_buffer_percent": 5,
                "high_volatility_warning.volatility_threshold": 30,
                "rebalancing.rules.max_drift_threshold": 5
            },
            "risk_profile": "medium"
        },
        "aggressive": {
            "name": "Aggressiv",
            "description": "Renditeorientierte Einstellungen mit höheren Risiko-Limits",
            "settings": {
                "max_position_size.max_position_percent": 20,
                "daily_loss_limit.max_daily_loss_percent": 8,
                "sufficient_cash.min_cash_buffer_percent": 2,
                "high_volatility_warning.volatility_threshold": 50,
                "rebalancing.rules.max_drift_threshold": 8
            },
            "risk_profile": "high"
        }
    }
    
    return jsonify({"success": True, "presets": presets})

@configuration_bp.route('/apply-preset', methods=['POST'])
def apply_configuration_preset():
    """Konfigurationspresets anwenden"""
    try:
        data = request.get_json()
        preset_name = data.get('preset_name')
        
        presets_response = get_configuration_presets()
        presets = presets_response.get_json()["presets"]
        
        if preset_name not in presets:
            return jsonify({"success": False, "error": "Unbekanntes Preset"}), 400
        
        preset = presets[preset_name]
        failed_updates = []
        
        # Alle Preset-Settings anwenden
        for field_id, value in preset["settings"].items():
            success = _update_configuration_value(field_id, value)
            if not success:
                failed_updates.append(field_id)
        
        if failed_updates:
            return jsonify({
                "success": False,
                "error": f"Fehler beim Anwenden von: {', '.join(failed_updates)}"
            }), 500
        
        # Hot-Reload
        trading_rules_engine.reload_configuration()
        
        return jsonify({
            "success": True,
            "message": f"Preset '{preset['name']}' erfolgreich angewendet",
            "applied_settings": len(preset["settings"])
        })
    
    except Exception as e:
        logger.error(f"Error applying preset: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500

@configuration_bp.route('/export', methods=['GET'])
def export_configuration():
    """Aktuelle Konfiguration als Download exportieren"""
    try:
        config = trading_rules_engine.config_manager.get_config()
        
        return jsonify({
            "success": True,
            "configuration": config,
            "export_timestamp": datetime.utcnow().isoformat(),
            "filename": f"aktienanalyse_config_{datetime.utcnow().strftime('%Y%m%d_%H%M%S')}.json"
        })
    
    except Exception as e:
        logger.error(f"Error exporting configuration: {str(e)}")
        return jsonify({"success": False, "error": str(e)}), 500
```

#### 1.3.2 **Strukturierte Frontend-Navigation für Configuration-Management**
```typescript
// services/frontend-service/src/components/ConfigurationDashboard.tsx
import React, { useState, useEffect } from 'react';
import { 
  Card, CardContent, CardHeader, CardTitle,
  Button, Badge, Separator,
  Alert, AlertDescription,
  Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger,
  ScrollArea
} from '@/components/ui';
import { 
  Settings, Shield, TrendingUp, RotateCcw, Save, 
  DollarSign, AlertTriangle, Activity, BarChart3,
  Target, Clock, Zap, Database, Users, FileText,
  ChevronRight, Home, HelpCircle
} from 'lucide-react';

// Hauptnavigation-Struktur
interface NavigationItem {
  id: string;
  title: string;
  description: string;
  icon: React.ReactNode;
  category: 'main' | 'sub';
  parentId?: string;
  badge?: string;
  riskLevel?: 'low' | 'medium' | 'high' | 'critical';
}

const navigationStructure: NavigationItem[] = [
  // Hauptbereiche
  {
    id: 'dashboard',
    title: 'Übersicht',
    description: 'Gesamtübersicht aller Konfigurationen und aktueller Status',
    icon: <Home className="h-5 w-5" />,
    category: 'main'
  },
  {
    id: 'risk_management',
    title: 'Risikomanagement',
    description: 'Verlustlimits, Positionsgrößen und Sicherheitseinstellungen',
    icon: <Shield className="h-5 w-5" />,
    category: 'main',
    badge: 'Kritisch',
    riskLevel: 'critical'
  },
  {
    id: 'trading_rules',
    title: 'Trading-Regeln',
    description: 'Handelsregeln, Marktzeiten und Liquiditätsmanagement',
    icon: <TrendingUp className="h-5 w-5" />,
    category: 'main',
    riskLevel: 'high'
  },
  {
    id: 'portfolio_management',
    title: 'Portfolio-Management',
    description: 'Rebalancing, Diversifikation und Allokationsstrategien',
    icon: <BarChart3 className="h-5 w-5" />,
    category: 'main',
    riskLevel: 'medium'
  },
  {
    id: 'risk_scoring',
    title: 'Risk-Scoring',
    description: 'Risikobewertung, Benchmarks und Gewichtungen',
    icon: <Target className="h-5 w-5" />,
    category: 'main',
    riskLevel: 'medium'
  },
  {
    id: 'automation',
    title: 'Automatisierung',
    description: 'Zeitbasierte Regeln, Trigger und automatische Aktionen',
    icon: <Zap className="h-5 w-5" />,
    category: 'main',
    riskLevel: 'low'
  },
  
  // Unterbereiche für Risikomanagement
  {
    id: 'position_limits',
    title: 'Positionslimits',
    description: 'Maximale Positionsgrößen und Konzentrationsrisiken',
    icon: <DollarSign className="h-4 w-4" />,
    category: 'sub',
    parentId: 'risk_management',
    riskLevel: 'critical'
  },
  {
    id: 'loss_limits',
    title: 'Verlustlimits',
    description: 'Tägliche und wöchentliche Verlustgrenzen',
    icon: <AlertTriangle className="h-4 w-4" />,
    category: 'sub',
    parentId: 'risk_management',
    riskLevel: 'critical'
  },
  {
    id: 'cash_management',
    title: 'Liquiditätsmanagement',
    description: 'Cash-Puffer und Notfall-Reserven',
    icon: <Database className="h-4 w-4" />,
    category: 'sub',
    parentId: 'risk_management',
    riskLevel: 'high'
  },
  
  // Unterbereiche für Trading-Regeln
  {
    id: 'market_timing',
    title: 'Marktzeiten',
    description: 'Handelszeiten und After-Hours-Trading',
    icon: <Clock className="h-4 w-4" />,
    category: 'sub',
    parentId: 'trading_rules',
    riskLevel: 'medium'
  },
  {
    id: 'volatility_rules',
    title: 'Volatilitäts-Regeln',
    description: 'VIX-Schwellen und Volatilitäts-Anpassungen',
    icon: <Activity className="h-4 w-4" />,
    category: 'sub',
    parentId: 'trading_rules',
    riskLevel: 'high'
  },
  {
    id: 'liquidity_rules',
    title: 'Liquiditäts-Regeln',
    description: 'Mindestvolumen und Spread-Limits',
    icon: <FileText className="h-4 w-4" />,
    category: 'sub',
    parentId: 'trading_rules',
    riskLevel: 'medium'
  },
  
  // Unterbereiche für Portfolio-Management
  {
    id: 'rebalancing_rules',
    title: 'Rebalancing-Regeln',
    description: 'Drift-Schwellen und Rebalancing-Trigger',
    icon: <RotateCcw className="h-4 w-4" />,
    category: 'sub',
    parentId: 'portfolio_management',
    riskLevel: 'medium'
  },
  {
    id: 'diversification',
    title: 'Diversifikation',
    description: 'Sektor-Limits und Asset-Verteilung',
    icon: <Target className="h-4 w-4" />,
    category: 'sub',
    parentId: 'portfolio_management',
    riskLevel: 'medium'
  }
];

const ConfigurationDashboard: React.FC = () => {
  const [activeMainSection, setActiveMainSection] = useState<string>('dashboard');
  const [activeSubSection, setActiveSubSection] = useState<string | null>(null);
  const [configurationStatus, setConfigurationStatus] = useState<any>({});
  const [pendingChanges, setPendingChanges] = useState<Record<string, any>>({});

  useEffect(() => {
    loadConfigurationStatus();
  }, []);

  const loadConfigurationStatus = async () => {
    // Lade aktuellen Configuration-Status
    try {
      const response = await fetch('/api/configuration/status');
      const data = await response.json();
      if (data.success) {
        setConfigurationStatus(data.status);
      }
    } catch (error) {
      console.error('Error loading configuration status:', error);
    }
  };

  const getMainSections = () => {
    return navigationStructure.filter(item => item.category === 'main');
  };

  const getSubSections = (parentId: string) => {
    return navigationStructure.filter(item => 
      item.category === 'sub' && item.parentId === parentId
    );
  };

  const getRiskLevelColor = (riskLevel?: string) => {
    switch (riskLevel) {
      case 'low': return 'bg-green-100 text-green-800 border-green-200';
      case 'medium': return 'bg-yellow-100 text-yellow-800 border-yellow-200';
      case 'high': return 'bg-orange-100 text-orange-800 border-orange-200';
      case 'critical': return 'bg-red-100 text-red-800 border-red-200';
      default: return 'bg-gray-100 text-gray-800 border-gray-200';
    }
  };

  const handleMainSectionClick = (sectionId: string) => {
    setActiveMainSection(sectionId);
    setActiveSubSection(null);
    
    // Wenn Sektion Unterelemente hat, wähle das erste aus
    const subSections = getSubSections(sectionId);
    if (subSections.length > 0) {
      setActiveSubSection(subSections[0].id);
    }
  };

  const renderSidebar = () => (
    <div className="w-80 bg-gray-50 border-r border-gray-200 h-screen overflow-hidden flex flex-col">
      {/* Header */}
      <div className="p-6 border-b border-gray-200 bg-white">
        <div className="flex items-center gap-3">
          <div className="p-2 bg-blue-100 rounded-lg">
            <Settings className="h-6 w-6 text-blue-600" />
          </div>
          <div>
            <h1 className="text-xl font-bold text-gray-900">Trading-Konfiguration</h1>
            <p className="text-sm text-gray-600">Systemeinstellungen verwalten</p>
          </div>
        </div>
      </div>

      {/* Navigation */}
      <ScrollArea className="flex-1 p-4">
        <div className="space-y-2">
          {getMainSections().map((section) => {
            const isActive = activeMainSection === section.id;
            const subSections = getSubSections(section.id);
            
            return (
              <div key={section.id} className="space-y-1">
                <button
                  onClick={() => handleMainSectionClick(section.id)}
                  className={`
                    w-full flex items-center gap-3 px-3 py-3 rounded-lg text-left transition-all
                    ${isActive 
                      ? 'bg-blue-100 text-blue-900 border border-blue-200' 
                      : 'hover:bg-gray-100 text-gray-700'
                    }
                  `}
                >
                  <div className={`
                    p-1 rounded-md
                    ${isActive ? 'bg-blue-200' : 'bg-gray-200'}
                  `}>
                    {section.icon}
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-medium truncate">{section.title}</span>
                      {section.badge && (
                        <Badge className={`text-xs ${getRiskLevelColor(section.riskLevel)}`}>
                          {section.badge}
                        </Badge>
                      )}
                    </div>
                    <p className="text-xs text-gray-500 truncate">{section.description}</p>
                  </div>
                  {subSections.length > 0 && (
                    <ChevronRight className={`h-4 w-4 transition-transform ${
                      isActive ? 'rotate-90' : ''
                    }`} />
                  )}
                </button>
                
                {/* Untermenü */}
                {isActive && subSections.length > 0 && (
                  <div className="ml-6 space-y-1 border-l-2 border-gray-200 pl-4">
                    {subSections.map((subSection) => {
                      const isSubActive = activeSubSection === subSection.id;
                      
                      return (
                        <button
                          key={subSection.id}
                          onClick={() => setActiveSubSection(subSection.id)}
                          className={`
                            w-full flex items-center gap-2 px-3 py-2 rounded-md text-left text-sm transition-all
                            ${isSubActive 
                              ? 'bg-blue-50 text-blue-800 border border-blue-100' 
                              : 'hover:bg-gray-50 text-gray-600'
                            }
                          `}
                        >
                          {subSection.icon}
                          <div className="flex-1 min-w-0">
                            <div className="flex items-center gap-2">
                              <span className="font-medium truncate">{subSection.title}</span>
                              {subSection.riskLevel && (
                                <div className={`w-2 h-2 rounded-full ${
                                  subSection.riskLevel === 'critical' ? 'bg-red-500' :
                                  subSection.riskLevel === 'high' ? 'bg-orange-500' :
                                  subSection.riskLevel === 'medium' ? 'bg-yellow-500' :
                                  'bg-green-500'
                                }`} />
                              )}
                            </div>
                            <p className="text-xs text-gray-500 truncate">{subSection.description}</p>
                          </div>
                        </button>
                      );
                    })}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      </ScrollArea>

      {/* Footer mit Aktionen */}
      <div className="p-4 border-t border-gray-200 bg-white space-y-2">
        <Button 
          className="w-full flex items-center gap-2"
          disabled={Object.keys(pendingChanges).length === 0}
        >
          <Save className="h-4 w-4" />
          Änderungen speichern ({Object.keys(pendingChanges).length})
        </Button>
        <Button variant="outline" className="w-full flex items-center gap-2">
          <HelpCircle className="h-4 w-4" />
          Hilfe & Dokumentation
        </Button>
      </div>
    </div>
  );

  const renderMainContent = () => {
    const currentSection = navigationStructure.find(item => item.id === activeMainSection);
    const currentSubSection = activeSubSection ? 
      navigationStructure.find(item => item.id === activeSubSection) : null;

    return (
      <div className="flex-1 flex flex-col">
        {/* Content Header */}
        <div className="bg-white border-b border-gray-200 px-8 py-6">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center gap-2 text-sm text-gray-600 mb-1">
                <span>{currentSection?.title}</span>
                {currentSubSection && (
                  <>
                    <ChevronRight className="h-4 w-4" />
                    <span>{currentSubSection.title}</span>
                  </>
                )}
              </div>
              <h1 className="text-2xl font-bold text-gray-900">
                {currentSubSection?.title || currentSection?.title}
              </h1>
              <p className="text-gray-600 mt-1">
                {currentSubSection?.description || currentSection?.description}
              </p>
            </div>
            
            {(currentSection?.riskLevel || currentSubSection?.riskLevel) && (
              <Badge className={`${getRiskLevelColor(
                currentSubSection?.riskLevel || currentSection?.riskLevel
              )}`}>
                {currentSubSection?.riskLevel === 'critical' || currentSection?.riskLevel === 'critical' ? 'Kritisches Risiko' :
                 currentSubSection?.riskLevel === 'high' || currentSection?.riskLevel === 'high' ? 'Hohes Risiko' :
                 currentSubSection?.riskLevel === 'medium' || currentSection?.riskLevel === 'medium' ? 'Mittleres Risiko' :
                 'Niedriges Risiko'}
              </Badge>
            )}
          </div>
        </div>

        {/* Content Area */}
        <div className="flex-1 overflow-auto">
          <div className="p-8">
            {renderContentForSection(activeMainSection, activeSubSection)}
          </div>
        </div>
      </div>
    );
  };

  const renderContentForSection = (mainSection: string, subSection: string | null) => {
    // Dashboard-Übersicht
    if (mainSection === 'dashboard') {
      return <ConfigurationOverview />;
    }

    // Risikomanagement
    if (mainSection === 'risk_management') {
      if (subSection === 'position_limits') {
        return <PositionLimitsConfiguration />;
      }
      if (subSection === 'loss_limits') {
        return <LossLimitsConfiguration />;
      }
      if (subSection === 'cash_management') {
        return <CashManagementConfiguration />;
      }
      return <RiskManagementOverview />;
    }

    // Trading-Regeln
    if (mainSection === 'trading_rules') {
      if (subSection === 'market_timing') {
        return <MarketTimingConfiguration />;
      }
      if (subSection === 'volatility_rules') {
        return <VolatilityRulesConfiguration />;
      }
      if (subSection === 'liquidity_rules') {
        return <LiquidityRulesConfiguration />;
      }
      return <TradingRulesOverview />;
    }

    // Portfolio-Management
    if (mainSection === 'portfolio_management') {
      if (subSection === 'rebalancing_rules') {
        return <RebalancingRulesConfiguration />;
      }
      if (subSection === 'diversification') {
        return <DiversificationConfiguration />;
      }
      return <PortfolioManagementOverview />;
    }

    // Risk-Scoring
    if (mainSection === 'risk_scoring') {
      return <RiskScoringConfiguration />;
    }

    // Automatisierung
    if (mainSection === 'automation') {
      return <AutomationConfiguration />;
    }

    // Fallback
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-center">
          <Settings className="h-12 w-12 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-medium text-gray-900 mb-2">Bereich in Entwicklung</h3>
          <p className="text-gray-600">Dieser Konfigurationsbereich wird bald verfügbar sein.</p>
        </div>
      </div>
    );
  };

  return (
    <div className="h-screen flex bg-gray-50">
      {renderSidebar()}
      {renderMainContent()}
    </div>
  );
};

export default ConfigurationDashboard;

// ============================================================================
// SPEZIFISCHE KOMPONENTEN FÜR JEDEN BEREICH
// ============================================================================

// 1. Dashboard-Übersicht Komponente
const ConfigurationOverview: React.FC = () => {
  const [systemStatus, setSystemStatus] = useState<any>({});
  const [quickStats, setQuickStats] = useState<any>({});

  useEffect(() => {
    loadSystemOverview();
  }, []);

  const loadSystemOverview = async () => {
    try {
      const response = await fetch('/api/configuration/overview');
      const data = await response.json();
      if (data.success) {
        setSystemStatus(data.system_status);
        setQuickStats(data.quick_stats);
      }
    } catch (error) {
      console.error('Error loading system overview:', error);
    }
  };

  return (
    <div className="space-y-6">
      {/* System Status Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">System-Status</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-green-100 rounded-full">
                <Activity className="h-5 w-5 text-green-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-green-600">Aktiv</p>
                <p className="text-sm text-gray-600">Alle Services laufen</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Risk-Level</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-yellow-100 rounded-full">
                <Shield className="h-5 w-5 text-yellow-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-yellow-600">Mittel</p>
                <p className="text-sm text-gray-600">Balanced Konfiguration</p>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-sm font-medium text-gray-600">Ausstehende Änderungen</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="p-2 bg-blue-100 rounded-full">
                <Settings className="h-5 w-5 text-blue-600" />
              </div>
              <div>
                <p className="text-2xl font-bold text-blue-600">3</p>
                <p className="text-sm text-gray-600">Parameter geändert</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>

      {/* Schnellkonfiguration */}
      <Card>
        <CardHeader>
          <CardTitle>Schnellkonfiguration</CardTitle>
          <p className="text-sm text-gray-600">
            Häufig verwendete Einstellungen und Presets
          </p>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Button variant="outline" className="h-20 flex flex-col items-center gap-2">
              <Shield className="h-5 w-5" />
              <span>Konservative Einstellungen</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col items-center gap-2">
              <TrendingUp className="h-5 w-5" />
              <span>Ausgewogene Einstellungen</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col items-center gap-2">
              <Zap className="h-5 w-5" />
              <span>Aggressive Einstellungen</span>
            </Button>
            <Button variant="outline" className="h-20 flex flex-col items-center gap-2">
              <AlertTriangle className="h-5 w-5" />
              <span>Notfall-Modus</span>
            </Button>
          </div>
        </CardContent>
      </Card>

      {/* Aktuelle Konfiguration Zusammenfassung */}
      <Card>
        <CardHeader>
          <CardTitle>Aktuelle Konfiguration</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 md:grid-cols-4 gap-4 text-sm">
            <div>
              <p className="font-medium text-gray-600">Max. Position</p>
              <p className="text-lg font-bold">10%</p>
            </div>
            <div>
              <p className="font-medium text-gray-600">Tagesverlust-Limit</p>
              <p className="text-lg font-bold">5%</p>
            </div>
            <div>
              <p className="font-medium text-gray-600">Cash-Puffer</p>
              <p className="text-lg font-bold">5%</p>
            </div>
            <div>
              <p className="font-medium text-gray-600">Rebalancing-Schwelle</p>
              <p className="text-lg font-bold">5%</p>
            </div>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 2. Position Limits Configuration
const PositionLimitsConfiguration: React.FC = () => {
  const [limits, setLimits] = useState({
    max_position_percent: 10,
    emergency_max_percent: 5,
    exclude_etfs: false
  });

  return (
    <div className="space-y-6">
      <Alert>
        <AlertTriangle className="h-4 w-4" />
        <AlertDescription>
          <strong>Kritischer Bereich:</strong> Änderungen hier beeinflussen direkt das Handelsrisiko.
        </AlertDescription>
      </Alert>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <DollarSign className="h-5 w-5" />
            Maximale Positionsgröße
          </CardTitle>
          <p className="text-sm text-gray-600">
            Begrenzt die Größe einer einzelnen Position als Prozentsatz des Gesamtportfolios
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Normale Positionsgröße: {limits.max_position_percent}%
            </label>
            <input
              type="range"
              min="1"
              max="50"
              value={limits.max_position_percent}
              onChange={(e) => setLimits(prev => ({
                ...prev,
                max_position_percent: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <div className="flex justify-between text-xs text-gray-500 mt-1">
              <span>1% (Sehr konservativ)</span>
              <span>50% (Sehr riskant)</span>
            </div>
            <p className="text-sm text-blue-600 mt-2">
              Bei einem Portfolio von €100.000 darf eine Position maximal €{(limits.max_position_percent * 1000).toLocaleString()} betragen.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Notfall-Positionslimit: {limits.emergency_max_percent}%
            </label>
            <input
              type="range"
              min="1"
              max="25"
              value={limits.emergency_max_percent}
              onChange={(e) => setLimits(prev => ({
                ...prev,
                emergency_max_percent: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              In volatilen Marktphasen wird automatisch auf {limits.emergency_max_percent}% reduziert.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <input
              type="checkbox"
              id="exclude_etfs"
              checked={limits.exclude_etfs}
              onChange={(e) => setLimits(prev => ({
                ...prev,
                exclude_etfs: e.target.checked
              }))}
            />
            <label htmlFor="exclude_etfs" className="text-sm">
              ETFs von Positionslimits ausschließen (ETFs gelten als diversifiziert)
            </label>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 3. Loss Limits Configuration
const LossLimitsConfiguration: React.FC = () => {
  const [lossLimits, setLossLimits] = useState({
    daily_loss_percent: 5,
    weekly_loss_percent: 10,
    notification_percent: 3,
    stop_trading_on_limit: true
  });

  return (
    <div className="space-y-6">
      <Alert>
        <AlertTriangle className="h-4 w-4" />
        <AlertDescription>
          <strong>Kritischer Schutz:</strong> Diese Limits schützen vor größeren Verlusten.
        </AlertDescription>
      </Alert>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <AlertTriangle className="h-5 w-5" />
            Verlustgrenzen
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Tägliches Verlustlimit: {lossLimits.daily_loss_percent}%
            </label>
            <input
              type="range"
              min="1"
              max="20"
              step="0.5"
              value={lossLimits.daily_loss_percent}
              onChange={(e) => setLossLimits(prev => ({
                ...prev,
                daily_loss_percent: parseFloat(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-red-600 mt-2">
              Bei €100.000 Portfolio wird bei €{(lossLimits.daily_loss_percent * 1000).toLocaleString()} Tagesverlust automatisch gestoppt.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Vorwarnung bei: {lossLimits.notification_percent}%
            </label>
            <input
              type="range"
              min="1"
              max="15"
              step="0.5"
              value={lossLimits.notification_percent}
              onChange={(e) => setLossLimits(prev => ({
                ...prev,
                notification_percent: parseFloat(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-yellow-600 mt-2">
              Bei {lossLimits.notification_percent}% Verlust erhalten Sie eine Warnung.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <input
              type="checkbox"
              id="stop_trading"
              checked={lossLimits.stop_trading_on_limit}
              onChange={(e) => setLossLimits(prev => ({
                ...prev,
                stop_trading_on_limit: e.target.checked
              }))}
            />
            <label htmlFor="stop_trading" className="text-sm">
              Trading automatisch stoppen bei Erreichen des Limits
            </label>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 4. Cash Management Configuration
const CashManagementConfiguration: React.FC = () => {
  const [cashSettings, setCashSettings] = useState({
    min_cash_buffer_percent: 5,
    emergency_cash_percent: 10,
    margin_enabled: false
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Database className="h-5 w-5" />
            Liquiditätsmanagement
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Mindest-Cash-Puffer: {cashSettings.min_cash_buffer_percent}%
            </label>
            <input
              type="range"
              min="0"
              max="30"
              value={cashSettings.min_cash_buffer_percent}
              onChange={(e) => setCashSettings(prev => ({
                ...prev,
                min_cash_buffer_percent: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-blue-600 mt-2">
              Von €100.000 bleiben mindestens €{(cashSettings.min_cash_buffer_percent * 1000).toLocaleString()} in liquiden Mitteln.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Notfall-Cash-Reserve: {cashSettings.emergency_cash_percent}%
            </label>
            <input
              type="range"
              min="5"
              max="50"
              value={cashSettings.emergency_cash_percent}
              onChange={(e) => setCashSettings(prev => ({
                ...prev,
                emergency_cash_percent: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              In Krisenzeiten wird automatisch {cashSettings.emergency_cash_percent}% des Portfolios in Cash gehalten.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 5. Market Timing Configuration
const MarketTimingConfiguration: React.FC = () => {
  const [marketSettings, setMarketSettings] = useState({
    allow_after_hours: false,
    allow_weekend_crypto: true
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Clock className="h-5 w-5" />
            Marktzeiten-Einstellungen
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">After-Hours Trading</h4>
              <p className="text-sm text-gray-600">
                Handel außerhalb der regulären Börsenzeiten (nach 17:30 XETRA)
              </p>
            </div>
            <input
              type="checkbox"
              checked={marketSettings.allow_after_hours}
              onChange={(e) => setMarketSettings(prev => ({
                ...prev,
                allow_after_hours: e.target.checked
              }))}
              className="scale-125"
            />
          </div>

          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">Krypto-Handel am Wochenende</h4>
              <p className="text-sm text-gray-600">
                Bitcoin und andere Kryptowährungen auch samstags und sonntags
              </p>
            </div>
            <input
              type="checkbox"
              checked={marketSettings.allow_weekend_crypto}
              onChange={(e) => setMarketSettings(prev => ({
                ...prev,
                allow_weekend_crypto: e.target.checked
              }))}
              className="scale-125"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 6. Volatility Rules Configuration
const VolatilityRulesConfiguration: React.FC = () => {
  const [volatilitySettings, setVolatilitySettings] = useState({
    volatility_threshold: 30,
    vix_threshold: 25,
    reduce_position_size: true,
    max_position_during_volatility: 5
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Activity className="h-5 w-5" />
            Volatilitäts-Management
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Volatilitäts-Warnschwelle: {volatilitySettings.volatility_threshold}%
            </label>
            <input
              type="range"
              min="10"
              max="100"
              step="5"
              value={volatilitySettings.volatility_threshold}
              onChange={(e) => setVolatilitySettings(prev => ({
                ...prev,
                volatility_threshold: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              Assets mit über {volatilitySettings.volatility_threshold}% Tagesvolatilität lösen eine Warnung aus.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              VIX-Warnschwelle: {volatilitySettings.vix_threshold}
            </label>
            <input
              type="range"
              min="10"
              max="60"
              value={volatilitySettings.vix_threshold}
              onChange={(e) => setVolatilitySettings(prev => ({
                ...prev,
                vix_threshold: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-red-600 mt-2">
              VIX über {volatilitySettings.vix_threshold} signalisiert erhöhte Marktangst.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 7. Liquidity Rules Configuration
const LiquidityRulesConfiguration: React.FC = () => {
  const [liquiditySettings, setLiquiditySettings] = useState({
    min_daily_volume: 1000000, // €1M
    min_market_cap: 500000000, // €500M
    max_bid_ask_spread: 0.5, // 0.5%
    exclude_illiquid_assets: true
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Droplets className="h-5 w-5" />
            Liquiditäts-Anforderungen
          </CardTitle>
          <p className="text-sm text-gray-600">
            Mindestanforderungen für handelbare Assets
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Mindest-Tagesvolumen: €{(liquiditySettings.min_daily_volume / 1000000).toFixed(1)}M
            </label>
            <input
              type="range"
              min="100000"
              max="10000000"
              step="100000"
              value={liquiditySettings.min_daily_volume}
              onChange={(e) => setLiquiditySettings(prev => ({
                ...prev,
                min_daily_volume: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-blue-600 mt-2">
              Assets mit geringerem Tagesvolumen werden automatisch ausgeschlossen.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Mindest-Marktkapitalisierung: €{(liquiditySettings.min_market_cap / 1000000).toFixed(0)}M
            </label>
            <input
              type="range"
              min="50000000"
              max="5000000000"
              step="50000000"
              value={liquiditySettings.min_market_cap}
              onChange={(e) => setLiquiditySettings(prev => ({
                ...prev,
                min_market_cap: parseInt(e.target.value)
              }))}
              className="w-full"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Max. Bid-Ask-Spread: {liquiditySettings.max_bid_ask_spread}%
            </label>
            <input
              type="range"
              min="0.1"
              max="3"
              step="0.1"
              value={liquiditySettings.max_bid_ask_spread}
              onChange={(e) => setLiquiditySettings(prev => ({
                ...prev,
                max_bid_ask_spread: parseFloat(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              Assets mit größerem Spread werden als illiquide betrachtet.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <input
              type="checkbox"
              id="exclude_illiquid"
              checked={liquiditySettings.exclude_illiquid_assets}
              onChange={(e) => setLiquiditySettings(prev => ({
                ...prev,
                exclude_illiquid_assets: e.target.checked
              }))}
            />
            <label htmlFor="exclude_illiquid" className="text-sm">
              Illiquide Assets automatisch vom Handel ausschließen
            </label>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 8. Rebalancing Rules Configuration
const RebalancingRulesConfiguration: React.FC = () => {
  const [rebalancingSettings, setRebalancingSettings] = useState({
    rebalancing_threshold: 5, // %
    max_rebalancing_frequency: 7, // days
    min_rebalancing_amount: 1000, // €
    automatic_rebalancing: true
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <RotateCcw className="h-5 w-5" />
            Portfolio-Rebalancing
          </CardTitle>
          <p className="text-sm text-gray-600">
            Automatische Anpassung der Portfolio-Allokation
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Rebalancing-Schwelle: {rebalancingSettings.rebalancing_threshold}%
            </label>
            <input
              type="range"
              min="2"
              max="20"
              step="0.5"
              value={rebalancingSettings.rebalancing_threshold}
              onChange={(e) => setRebalancingSettings(prev => ({
                ...prev,
                rebalancing_threshold: parseFloat(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-blue-600 mt-2">
              Rebalancing wird ausgelöst, wenn die Abweichung {rebalancingSettings.rebalancing_threshold}% übersteigt.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Max. Häufigkeit: alle {rebalancingSettings.max_rebalancing_frequency} Tage
            </label>
            <input
              type="range"
              min="1"
              max="30"
              value={rebalancingSettings.max_rebalancing_frequency}
              onChange={(e) => setRebalancingSettings(prev => ({
                ...prev,
                max_rebalancing_frequency: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              Verhindert zu häufiges Rebalancing und reduziert Transaktionskosten.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Mindest-Rebalancing-Betrag: €{rebalancingSettings.min_rebalancing_amount.toLocaleString()}
            </label>
            <input
              type="range"
              min="100"
              max="10000"
              step="100"
              value={rebalancingSettings.min_rebalancing_amount}
              onChange={(e) => setRebalancingSettings(prev => ({
                ...prev,
                min_rebalancing_amount: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-gray-600 mt-2">
              Kleine Abweichungen unter €{rebalancingSettings.min_rebalancing_amount.toLocaleString()} werden ignoriert.
            </p>
          </div>

          <div className="flex items-center space-x-3">
            <input
              type="checkbox"
              id="auto_rebalancing"
              checked={rebalancingSettings.automatic_rebalancing}
              onChange={(e) => setRebalancingSettings(prev => ({
                ...prev,
                automatic_rebalancing: e.target.checked
              }))}
            />
            <label htmlFor="auto_rebalancing" className="text-sm">
              Automatisches Rebalancing aktivieren
            </label>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 9. Diversification Configuration
const DiversificationConfiguration: React.FC = () => {
  const [diversificationSettings, setDiversificationSettings] = useState({
    max_sector_allocation: 25, // %
    max_country_allocation: 60, // %
    min_asset_count: 10,
    max_correlation: 0.7
  });

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Target className="h-5 w-5" />
            Diversifikations-Regeln
          </CardTitle>
          <p className="text-sm text-gray-600">
            Risikostreuung über Sektoren, Länder und Asset-Klassen
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div>
            <label className="block text-sm font-medium mb-2">
              Max. Sektor-Allokation: {diversificationSettings.max_sector_allocation}%
            </label>
            <input
              type="range"
              min="10"
              max="50"
              step="5"
              value={diversificationSettings.max_sector_allocation}
              onChange={(e) => setDiversificationSettings(prev => ({
                ...prev,
                max_sector_allocation: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-blue-600 mt-2">
              Kein einzelner Sektor (z.B. Technologie) darf mehr als {diversificationSettings.max_sector_allocation}% ausmachen.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Max. Länder-Allokation: {diversificationSettings.max_country_allocation}%
            </label>
            <input
              type="range"
              min="30"
              max="80"
              step="5"
              value={diversificationSettings.max_country_allocation}
              onChange={(e) => setDiversificationSettings(prev => ({
                ...prev,
                max_country_allocation: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-orange-600 mt-2">
              Geografische Streuung: Max. {diversificationSettings.max_country_allocation}% in einem Land.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Mindest-Anzahl Assets: {diversificationSettings.min_asset_count}
            </label>
            <input
              type="range"
              min="5"
              max="50"
              value={diversificationSettings.min_asset_count}
              onChange={(e) => setDiversificationSettings(prev => ({
                ...prev,
                min_asset_count: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-green-600 mt-2">
              Portfolio muss mindestens {diversificationSettings.min_asset_count} verschiedene Assets enthalten.
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Max. Korrelation: {diversificationSettings.max_correlation}
            </label>
            <input
              type="range"
              min="0.3"
              max="0.9"
              step="0.1"
              value={diversificationSettings.max_correlation}
              onChange={(e) => setDiversificationSettings(prev => ({
                ...prev,
                max_correlation: parseFloat(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-purple-600 mt-2">
              Assets mit Korrelation über {diversificationSettings.max_correlation} lösen eine Warnung aus.
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 10. Risk Scoring Configuration
const RiskScoringConfiguration: React.FC = () => {
  const [riskSettings, setRiskSettings] = useState({
    volatility_weight: 40,
    correlation_weight: 30,
    liquidity_weight: 20,
    sentiment_weight: 10
  });

  const totalWeight = riskSettings.volatility_weight + riskSettings.correlation_weight + 
                     riskSettings.liquidity_weight + riskSettings.sentiment_weight;

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Calculator className="h-5 w-5" />
            Risk-Scoring Algorithmus
          </CardTitle>
          <p className="text-sm text-gray-600">
            Gewichtung der Faktoren für die Risikobewertung
          </p>
        </CardHeader>
        <CardContent className="space-y-6">
          <div className={`p-3 rounded-lg ${totalWeight === 100 ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'}`}>
            <p className={`text-sm font-medium ${totalWeight === 100 ? 'text-green-700' : 'text-red-700'}`}>
              Gesamtgewichtung: {totalWeight}% {totalWeight !== 100 && '(Muss 100% ergeben!)'}
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Volatilität: {riskSettings.volatility_weight}%
            </label>
            <input
              type="range"
              min="10"
              max="70"
              step="5"
              value={riskSettings.volatility_weight}
              onChange={(e) => setRiskSettings(prev => ({
                ...prev,
                volatility_weight: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-gray-600 mt-1">
              Einfluss der historischen Kursschwankungen auf den Risk-Score
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Korrelation: {riskSettings.correlation_weight}%
            </label>
            <input
              type="range"
              min="10"
              max="50"
              step="5"
              value={riskSettings.correlation_weight}
              onChange={(e) => setRiskSettings(prev => ({
                ...prev,
                correlation_weight: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-gray-600 mt-1">
              Wie stark korreliert das Asset mit dem Gesamtportfolio
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Liquidität: {riskSettings.liquidity_weight}%
            </label>
            <input
              type="range"
              min="10"
              max="40"
              step="5"
              value={riskSettings.liquidity_weight}
              onChange={(e) => setRiskSettings(prev => ({
                ...prev,
                liquidity_weight: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-gray-600 mt-1">
              Handelsvolumen und Bid-Ask-Spread
            </p>
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Markt-Sentiment: {riskSettings.sentiment_weight}%
            </label>
            <input
              type="range"
              min="5"
              max="30"
              step="5"
              value={riskSettings.sentiment_weight}
              onChange={(e) => setRiskSettings(prev => ({
                ...prev,
                sentiment_weight: parseInt(e.target.value)
              }))}
              className="w-full"
            />
            <p className="text-sm text-gray-600 mt-1">
              Nachrichten-Sentiment und Analystenbewertungen
            </p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// 11. Automation Configuration
const AutomationConfiguration: React.FC = () => {
  const [automationSettings, setAutomationSettings] = useState({
    auto_trading_enabled: true,
    auto_rebalancing_enabled: true,
    auto_stop_loss: true,
    notification_level: 'medium',
    trading_hours_only: true
  });

  return (
    <div className="space-y-6">
      <Alert>
        <Settings className="h-4 w-4" />
        <AlertDescription>
          <strong>Automatisierung:</strong> Diese Einstellungen steuern, welche Aktionen automatisch ausgeführt werden.
        </AlertDescription>
      </Alert>

      <Card>
        <CardHeader>
          <CardTitle className="flex items-center gap-2">
            <Zap className="h-5 w-5" />
            Automatisierungs-Optionen
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">Automatischer Handel</h4>
              <p className="text-sm text-gray-600">
                System führt Käufe und Verkäufe basierend auf Regeln automatisch aus
              </p>
            </div>
            <input
              type="checkbox"
              checked={automationSettings.auto_trading_enabled}
              onChange={(e) => setAutomationSettings(prev => ({
                ...prev,
                auto_trading_enabled: e.target.checked
              }))}
              className="scale-125"
            />
          </div>

          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">Automatisches Rebalancing</h4>
              <p className="text-sm text-gray-600">
                Portfolio wird automatisch an Ziel-Allokation angepasst
              </p>
            </div>
            <input
              type="checkbox"
              checked={automationSettings.auto_rebalancing_enabled}
              onChange={(e) => setAutomationSettings(prev => ({
                ...prev,
                auto_rebalancing_enabled: e.target.checked
              }))}
              className="scale-125"
            />
          </div>

          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">Automatische Stop-Loss-Orders</h4>
              <p className="text-sm text-gray-600">
                Verlustbegrenzung durch automatische Verkaufsorders
              </p>
            </div>
            <input
              type="checkbox"
              checked={automationSettings.auto_stop_loss}
              onChange={(e) => setAutomationSettings(prev => ({
                ...prev,
                auto_stop_loss: e.target.checked
              }))}
              className="scale-125"
            />
          </div>

          <div>
            <label className="block text-sm font-medium mb-2">
              Benachrichtigungs-Level
            </label>
            <select
              value={automationSettings.notification_level}
              onChange={(e) => setAutomationSettings(prev => ({
                ...prev,
                notification_level: e.target.value
              }))}
              className="w-full p-2 border rounded-lg"
            >
              <option value="minimal">Minimal - Nur kritische Ereignisse</option>
              <option value="medium">Medium - Wichtige Trades und Warnungen</option>
              <option value="detailed">Detailliert - Alle automatischen Aktionen</option>
            </select>
          </div>

          <div className="flex items-center justify-between p-4 border rounded-lg">
            <div>
              <h4 className="font-medium">Nur zu Handelszeiten</h4>
              <p className="text-sm text-gray-600">
                Automatische Aktionen nur während regulärer Börsenzeiten
              </p>
            </div>
            <input
              type="checkbox"
              checked={automationSettings.trading_hours_only}
              onChange={(e) => setAutomationSettings(prev => ({
                ...prev,
                trading_hours_only: e.target.checked
              }))}
              className="scale-125"
            />
          </div>
        </CardContent>
      </Card>
    </div>
  );
};

// Übersichts-Komponenten
const RiskManagementOverview: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Shield className="h-5 w-5 text-red-500" />
              Verlustschutz
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Tagesverlust-Limit:</span>
                <span className="font-medium">5%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Wochenverlust-Limit:</span>
                <span className="font-medium">10%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Auto-Stop:</span>
                <span className="font-medium text-green-600">Aktiv</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <DollarSign className="h-5 w-5 text-blue-500" />
              Positionslimits
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Max. Position:</span>
                <span className="font-medium">10%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Notfall-Limit:</span>
                <span className="font-medium">5%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">ETF-Ausnahme:</span>
                <span className="font-medium text-blue-600">Nein</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Activity className="h-5 w-5 text-orange-500" />
              Volatilitäts-Management
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Volatilitäts-Schwelle:</span>
                <span className="font-medium">30%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">VIX-Warnung:</span>
                <span className="font-medium">25</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Position-Reduktion:</span>
                <span className="font-medium text-green-600">Aktiv</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

const TradingRulesOverview: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Clock className="h-5 w-5" />
              Marktzeiten-Regeln
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm">After-Hours Trading:</span>
                <span className="px-2 py-1 bg-red-100 text-red-700 rounded text-xs">Deaktiviert</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Krypto-Wochenendhandel:</span>
                <span className="px-2 py-1 bg-green-100 text-green-700 rounded text-xs">Aktiv</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Handel zu Feiertagen:</span>
                <span className="px-2 py-1 bg-red-100 text-red-700 rounded text-xs">Deaktiviert</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle className="flex items-center gap-2">
              <Droplets className="h-5 w-5" />
              Liquiditäts-Anforderungen
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-3">
              <div className="flex items-center justify-between">
                <span className="text-sm">Min. Tagesvolumen:</span>
                <span className="font-medium">€1M</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Min. Marktkapitalisierung:</span>
                <span className="font-medium">€500M</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="text-sm">Max. Bid-Ask-Spread:</span>
                <span className="font-medium">0.5%</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

const PortfolioManagementOverview: React.FC = () => {
  return (
    <div className="space-y-6">
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <RotateCcw className="h-5 w-5 text-blue-500" />
              Rebalancing
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Schwelle:</span>
                <span className="font-medium">5%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Max. Häufigkeit:</span>
                <span className="font-medium">7 Tage</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Mindestbetrag:</span>
                <span className="font-medium">€1.000</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Target className="h-5 w-5 text-green-500" />
              Diversifikation
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Max. Sektor:</span>
                <span className="font-medium">25%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Max. Land:</span>
                <span className="font-medium">60%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Min. Assets:</span>
                <span className="font-medium">10</span>
              </div>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader className="pb-3">
            <CardTitle className="text-lg flex items-center gap-2">
              <Database className="h-5 w-5 text-purple-500" />
              Cash-Management
            </CardTitle>
          </CardHeader>
          <CardContent>
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Min. Cash-Puffer:</span>
                <span className="font-medium">5%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Notfall-Reserve:</span>
                <span className="font-medium">10%</span>
              </div>
              <div className="flex justify-between">
                <span className="text-sm text-gray-600">Margin-Handel:</span>
                <span className="font-medium text-red-600">Deaktiviert</span>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
};

interface ConfigurationField {
  field_id: string;
  display_name: string;
  description: string;
  field_type: string;
  current_value: any;
  default_value: any;
  min_value?: number;
  max_value?: number;
  step?: number;
  unit: string;
  category: string;
  risk_level: string;
  affects_trading: boolean;
  example_explanation: string;
}

interface ConfigurationMetadata {
  trading_rules: Record<string, ConfigurationField[]>;
  risk_scoring: Record<string, ConfigurationField[]>;
  rebalancing: Record<string, ConfigurationField[]>;
}

const ConfigurationManager: React.FC = () => {
  const [metadata, setMetadata] = useState<ConfigurationMetadata | null>(null);
  const [currentConfig, setCurrentConfig] = useState<Record<string, any>>({});
  const [pendingChanges, setPendingChanges] = useState<Record<string, any>>({});
  const [isLoading, setIsLoading] = useState(true);
  const [selectedCategory, setSelectedCategory] = useState<string>('all');
  const [searchTerm, setSearchTerm] = useState('');

  useEffect(() => {
    loadConfiguration();
  }, []);

  const loadConfiguration = async () => {
    try {
      setIsLoading(true);
      const [metadataResponse, configResponse] = await Promise.all([
        fetch('/api/configuration/metadata'),
        fetch('/api/configuration/current')
      ]);

      const metadataData = await metadataResponse.json();
      const configData = await configResponse.json();

      if (metadataData.success && configData.success) {
        setMetadata(metadataData.metadata);
        setCurrentConfig(configData.configuration);
      }
    } catch (error) {
      console.error('Error loading configuration:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const updateFieldValue = (fieldId: string, value: any) => {
    setPendingChanges(prev => ({
      ...prev,
      [fieldId]: value
    }));
  };

  const saveConfiguration = async () => {
    const updates = Object.entries(pendingChanges);
    let successCount = 0;

    for (const [fieldId, value] of updates) {
      try {
        const response = await fetch('/api/configuration/update', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ field_id: fieldId, value })
        });

        if (response.ok) {
          successCount++;
          setCurrentConfig(prev => ({
            ...prev,
            [fieldId]: value
          }));
        }
      } catch (error) {
        console.error(`Error updating ${fieldId}:`, error);
      }
    }

    if (successCount === updates.length) {
      setPendingChanges({});
      // Show success notification
    }
  };

  const resetToDefaults = () => {
    setPendingChanges({});
    // Reset logic here
  };

  const getRiskLevelColor = (riskLevel: string) => {
    switch (riskLevel) {
      case 'low': return 'bg-green-100 text-green-800';
      case 'medium': return 'bg-yellow-100 text-yellow-800';
      case 'high': return 'bg-orange-100 text-orange-800';
      case 'critical': return 'bg-red-100 text-red-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const renderField = (field: ConfigurationField) => {
    const currentValue = pendingChanges[field.field_id] ?? currentConfig[field.field_id] ?? field.default_value;
    const hasChanges = field.field_id in pendingChanges;

    return (
      <Card key={field.field_id} className={`mb-4 ${hasChanges ? 'border-blue-500' : ''}`}>
        <CardHeader className="pb-3">
          <div className="flex items-start justify-between">
            <div className="flex-1">
              <CardTitle className="text-lg flex items-center gap-2">
                {field.display_name}
                <Badge className={getRiskLevelColor(field.risk_level)}>
                  {field.risk_level}
                </Badge>
                {field.affects_trading && (
                  <Badge variant="outline">Beeinflusst Trading</Badge>
                )}
              </CardTitle>
              <p className="text-sm text-gray-600 mt-1">{field.description}</p>
            </div>
            <Dialog>
              <DialogTrigger asChild>
                <Button variant="ghost" size="sm">
                  <InfoIcon className="h-4 w-4" />
                </Button>
              </DialogTrigger>
              <DialogContent>
                <DialogHeader>
                  <DialogTitle>{field.display_name}</DialogTitle>
                </DialogHeader>
                <div className="space-y-4">
                  <div>
                    <h4 className="font-semibold">Beschreibung:</h4>
                    <p className="text-sm">{field.description}</p>
                  </div>
                  <div>
                    <h4 className="font-semibold">Beispiel:</h4>
                    <p className="text-sm text-blue-600">{field.example_explanation}</p>
                  </div>
                  <div className="grid grid-cols-2 gap-4 text-sm">
                    <div>
                      <span className="font-semibold">Aktueller Wert:</span><br />
                      {currentValue}{field.unit}
                    </div>
                    <div>
                      <span className="font-semibold">Standard:</span><br />
                      {field.default_value}{field.unit}
                    </div>
                    {field.min_value !== undefined && (
                      <div>
                        <span className="font-semibold">Minimum:</span><br />
                        {field.min_value}{field.unit}
                      </div>
                    )}
                    {field.max_value !== undefined && (
                      <div>
                        <span className="font-semibold">Maximum:</span><br />
                        {field.max_value}{field.unit}
                      </div>
                    )}
                  </div>
                </div>
              </DialogContent>
            </Dialog>
          </div>
        </CardHeader>
        <CardContent>
          <div className="space-y-3">
            {field.field_type === 'boolean' ? (
              <div className="flex items-center space-x-3">
                <Switch
                  checked={currentValue}
                  onCheckedChange={(checked) => updateFieldValue(field.field_id, checked)}
                />
                <span className="text-sm">
                  {currentValue ? 'Aktiviert' : 'Deaktiviert'}
                </span>
              </div>
            ) : field.field_type === 'percentage' || field.field_type === 'number' ? (
              <div className="space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium">
                    {currentValue}{field.unit}
                  </span>
                  <Input
                    type="number"
                    value={currentValue}
                    onChange={(e) => updateFieldValue(field.field_id, parseFloat(e.target.value))}
                    className="w-24 text-right"
                    min={field.min_value}
                    max={field.max_value}
                    step={field.step}
                  />
                </div>
                {field.min_value !== undefined && field.max_value !== undefined && (
                  <Slider
                    value={[currentValue]}
                    onValueChange={([value]) => updateFieldValue(field.field_id, value)}
                    min={field.min_value}
                    max={field.max_value}
                    step={field.step || 1}
                    className="w-full"
                  />
                )}
                <div className="flex justify-between text-xs text-gray-500">
                  <span>{field.min_value}{field.unit}</span>
                  <span>{field.max_value}{field.unit}</span>
                </div>
              </div>
            ) : (
              <Input
                value={currentValue}
                onChange={(e) => updateFieldValue(field.field_id, e.target.value)}
                placeholder={`Standard: ${field.default_value}`}
              />
            )}
            
            {hasChanges && (
              <Alert>
                <AlertTriangle className="h-4 w-4" />
                <AlertDescription>
                  Änderung wird bei Speichern übernommen: {field.current_value} → {currentValue}
                </AlertDescription>
              </Alert>
            )}
          </div>
        </CardContent>
      </Card>
    );
  };

  const getAllFields = (): ConfigurationField[] => {
    if (!metadata) return [];
    
    const allFields: ConfigurationField[] = [];
    Object.values(metadata.trading_rules).forEach(fields => allFields.push(...fields));
    Object.values(metadata.risk_scoring).forEach(fields => allFields.push(...fields));
    Object.values(metadata.rebalancing).forEach(fields => allFields.push(...fields));
    
    return allFields;
  };

  const filteredFields = getAllFields().filter(field => {
    const matchesSearch = field.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         field.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || field.category === selectedCategory;
    
    return matchesSearch && matchesCategory;
  });

  const getUniqueCategories = () => {
    const categories = new Set(getAllFields().map(field => field.category));
    return Array.from(categories).sort();
  };

  if (isLoading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="container mx-auto p-6 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold flex items-center gap-2">
            <Settings className="h-8 w-8" />
            Trading-Konfiguration
          </h1>
          <p className="text-gray-600 mt-1">
            Verwalten Sie alle Trading-Rules und Risk-Management-Parameter
          </p>
        </div>
        
        <div className="flex gap-2">
          <Button
            variant="outline"
            onClick={resetToDefaults}
            className="flex items-center gap-2"
          >
            <RotateCcw className="h-4 w-4" />
            Zurücksetzen
          </Button>
          <Button
            onClick={saveConfiguration}
            disabled={Object.keys(pendingChanges).length === 0}
            className="flex items-center gap-2"
          >
            <Save className="h-4 w-4" />
            Änderungen speichern ({Object.keys(pendingChanges).length})
          </Button>
        </div>
      </div>

      {/* Filter-Bereich */}
      <Card>
        <CardContent className="pt-6">
          <div className="flex gap-4 items-center">
            <div className="flex-1">
              <Input
                placeholder="Parameter suchen..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
            <Select value={selectedCategory} onValueChange={setSelectedCategory}>
              <SelectTrigger className="w-64">
                <SelectValue placeholder="Kategorie wählen" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="all">Alle Kategorien</SelectItem>
                {getUniqueCategories().map(category => (
                  <SelectItem key={category} value={category}>{category}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
        </CardContent>
      </Card>

      {/* Tabs für verschiedene Bereiche */}
      <Tabs defaultValue="all" className="space-y-4">
        <TabsList className="grid w-full grid-cols-4">
          <TabsTrigger value="all">Alle Parameter</TabsTrigger>
          <TabsTrigger value="trading">Trading Rules</TabsTrigger>
          <TabsTrigger value="risk">Risk Scoring</TabsTrigger>
          <TabsTrigger value="rebalancing">Rebalancing</TabsTrigger>
        </TabsList>

        <TabsContent value="all" className="space-y-4">
          <div className="grid gap-4">
            {filteredFields.map(renderField)}
          </div>
        </TabsContent>

        <TabsContent value="trading" className="space-y-4">
          {metadata && Object.entries(metadata.trading_rules).map(([section, fields]) => (
            <div key={section}>
              <h3 className="text-xl font-semibold mb-4">{section}</h3>
              <div className="grid gap-4">
                {fields.filter(field => 
                  field.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                  field.description.toLowerCase().includes(searchTerm.toLowerCase())
                ).map(renderField)}
              </div>
            </div>
          ))}
        </TabsContent>

        <TabsContent value="risk" className="space-y-4">
          {metadata && Object.entries(metadata.risk_scoring).map(([section, fields]) => (
            <div key={section}>
              <h3 className="text-xl font-semibold mb-4">{section}</h3>
              <div className="grid gap-4">
                {fields.filter(field => 
                  field.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                  field.description.toLowerCase().includes(searchTerm.toLowerCase())
                ).map(renderField)}
              </div>
            </div>
          ))}
        </TabsContent>

        <TabsContent value="rebalancing" className="space-y-4">
          {metadata && Object.entries(metadata.rebalancing).map(([section, fields]) => (
            <div key={section}>
              <h3 className="text-xl font-semibold mb-4">{section}</h3>
              <div className="grid gap-4">
                {fields.filter(field => 
                  field.display_name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                  field.description.toLowerCase().includes(searchTerm.toLowerCase())
                ).map(renderField)}
              </div>
            </div>
          ))}
        </TabsContent>
      </Tabs>

      {/* Configuration Presets */}
      <Card>
        <CardHeader>
          <CardTitle>Vordefinierte Einstellungen</CardTitle>
          <p className="text-sm text-gray-600">
            Schnell-Konfigurationen für verschiedene Handelsstrategien
          </p>
        </CardHeader>
        <CardContent>
          <ConfigurationPresets onApplyPreset={(presetName) => {
            // Apply preset logic
            console.log('Applying preset:', presetName);
          }} />
        </CardContent>
      </Card>
    </div>
  );
};

// Configuration Presets Component
const ConfigurationPresets: React.FC<{ onApplyPreset: (presetName: string) => void }> = ({ onApplyPreset }) => {
  const presets = [
    {
      name: 'Konservativ',
      description: 'Minimales Risiko, stabile Renditen',
      icon: <Shield className="h-5 w-5" />,
      color: 'bg-green-50 border-green-200 hover:bg-green-100',
      settings: {
        max_position_percent: 5,
        daily_loss_limit: 2,
        volatility_threshold: 15,
        min_cash_buffer: 15
      }
    },
    {
      name: 'Ausgewogen',
      description: 'Balanced zwischen Risiko und Rendite',
      icon: <TrendingUp className="h-5 w-5" />,
      color: 'bg-blue-50 border-blue-200 hover:bg-blue-100',
      settings: {
        max_position_percent: 10,
        daily_loss_limit: 5,
        volatility_threshold: 30,
        min_cash_buffer: 5
      }
    },
    {
      name: 'Aggressiv',
      description: 'Höhere Risiken für höhere Renditen',
      icon: <Zap className="h-5 w-5" />,
      color: 'bg-orange-50 border-orange-200 hover:bg-orange-100',
      settings: {
        max_position_percent: 20,
        daily_loss_limit: 10,
        volatility_threshold: 50,
        min_cash_buffer: 2
      }
    },
    {
      name: 'Notfall-Modus',
      description: 'Maximaler Schutz in volatilen Zeiten',
      icon: <AlertTriangle className="h-5 w-5" />,
      color: 'bg-red-50 border-red-200 hover:bg-red-100',
      settings: {
        max_position_percent: 2,
        daily_loss_limit: 1,
        volatility_threshold: 10,
        min_cash_buffer: 25
      }
    }
  ];

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
      {presets.map((preset) => (
        <Card key={preset.name} className={`cursor-pointer transition-colors ${preset.color}`}>
          <CardHeader className="pb-3">
            <CardTitle className="flex items-center gap-2 text-lg">
              {preset.icon}
              {preset.name}
            </CardTitle>
            <p className="text-sm text-gray-600">{preset.description}</p>
          </CardHeader>
          <CardContent>
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span>Max. Position:</span>
                <span className="font-medium">{preset.settings.max_position_percent}%</span>
              </div>
              <div className="flex justify-between">
                <span>Tagesverlust-Limit:</span>
                <span className="font-medium">{preset.settings.daily_loss_limit}%</span>
              </div>
              <div className="flex justify-between">
                <span>Volatilitäts-Schwelle:</span>
                <span className="font-medium">{preset.settings.volatility_threshold}%</span>
              </div>
              <div className="flex justify-between">
                <span>Cash-Puffer:</span>
                <span className="font-medium">{preset.settings.min_cash_buffer}%</span>
              </div>
            </div>
            <Button 
              className="w-full mt-4" 
              variant="outline"
              onClick={() => onApplyPreset(preset.name)}
            >
              Preset anwenden
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  );
};

// WebSocket Integration für Live-Updates
interface WebSocketMessage {
  type: string;
  data: any;
  timestamp: string;
}

const useConfigurationWebSocket = () => {
  const [isConnected, setIsConnected] = useState(false);
  const [lastMessage, setLastMessage] = useState<WebSocketMessage | null>(null);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    const connectWebSocket = () => {
      const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
      const wsUrl = `${protocol}//${window.location.host}/ws/configuration`;
      
      wsRef.current = new WebSocket(wsUrl);

      wsRef.current.onopen = () => {
        setIsConnected(true);
        console.log('Configuration WebSocket connected');
      };

      wsRef.current.onmessage = (event) => {
        try {
          const message: WebSocketMessage = JSON.parse(event.data);
          setLastMessage(message);
          
          // Handle different message types
          switch (message.type) {
            case 'configuration_updated':
              // Configuration was updated by another session or system
              console.log('Configuration updated externally:', message.data);
              break;
            case 'system_alert':
              // System alert (e.g., risk limits reached)
              console.log('System alert:', message.data);
              break;
            case 'market_status_change':
              // Market status changed
              console.log('Market status changed:', message.data);
              break;
          }
        } catch (error) {
          console.error('Error parsing WebSocket message:', error);
        }
      };

      wsRef.current.onclose = () => {
        setIsConnected(false);
        console.log('Configuration WebSocket disconnected');
        
        // Reconnect after 5 seconds
        setTimeout(connectWebSocket, 5000);
      };

      wsRef.current.onerror = (error) => {
        console.error('Configuration WebSocket error:', error);
      };
    };

    connectWebSocket();

    return () => {
      if (wsRef.current) {
        wsRef.current.close();
      }
    };
  }, []);

  const sendMessage = (type: string, data: any) => {
    if (wsRef.current && wsRef.current.readyState === WebSocket.OPEN) {
      const message: WebSocketMessage = {
        type,
        data,
        timestamp: new Date().toISOString()
      };
      wsRef.current.send(JSON.stringify(message));
    }
  };

  return {
    isConnected,
    lastMessage,
    sendMessage
  };
};

export {
  ConfigurationDashboard,
  OverviewDashboard,
  PositionLimitsConfiguration,
  LossLimitsConfiguration,
  CashManagementConfiguration,
  MarketTimingConfiguration,
  VolatilityRulesConfiguration,
  LiquidityRulesConfiguration,
  RebalancingRulesConfiguration,
  DiversificationConfiguration,
  RiskScoringConfiguration,
  AutomationConfiguration,
  RiskManagementOverview,
  TradingRulesOverview,
  PortfolioManagementOverview,
  ConfigurationManager,
  ConfigurationPresets,
  useConfigurationWebSocket
};
    </div>
  );
};

interface ConfigurationPresetsProps {
  onApplyPreset: (presetName: string) => void;
}

const ConfigurationPresets: React.FC<ConfigurationPresetsProps> = ({ onApplyPreset }) => {
  const [presets, setPresets] = useState<any>({});

  useEffect(() => {
    loadPresets();
  }, []);

  const loadPresets = async () => {
    try {
      const response = await fetch('/api/configuration/presets');
      const data = await response.json();
      if (data.success) {
        setPresets(data.presets);
      }
    } catch (error) {
      console.error('Error loading presets:', error);
    }
  };

  const applyPreset = async (presetName: string) => {
    try {
      const response = await fetch('/api/configuration/apply-preset', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ preset_name: presetName })
      });
      
      if (response.ok) {
        onApplyPreset(presetName);
        // Reload page or update state
        window.location.reload();
      }
    } catch (error) {
      console.error('Error applying preset:', error);
    }
  };

  return (
    <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
      {Object.entries(presets).map(([key, preset]: [string, any]) => (
        <Card key={key} className="cursor-pointer hover:shadow-md transition-shadow">
          <CardHeader>
            <CardTitle className="flex items-center justify-between">
              {preset.name}
              <Badge className={
                preset.risk_profile === 'low' ? 'bg-green-100 text-green-800' :
                preset.risk_profile === 'medium' ? 'bg-yellow-100 text-yellow-800' :
                'bg-orange-100 text-orange-800'
              }>
                {preset.risk_profile === 'low' ? 'Niedriges Risiko' :
                 preset.risk_profile === 'medium' ? 'Mittleres Risiko' :
                 'Hohes Risiko'}
              </Badge>
            </CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-gray-600 mb-4">{preset.description}</p>
            <div className="space-y-2 text-xs">
              <div>Positionsgröße: {preset.settings['max_position_size.max_position_percent']}%</div>
              <div>Tagesverlust-Limit: {preset.settings['daily_loss_limit.max_daily_loss_percent']}%</div>
              <div>Cash-Puffer: {preset.settings['sufficient_cash.min_cash_buffer_percent']}%</div>
            </div>
            <Button
              className="w-full mt-4"
              onClick={() => applyPreset(key)}
              variant={preset.risk_profile === 'medium' ? 'default' : 'outline'}
            >
              Anwenden
            </Button>
          </CardContent>
        </Card>
      ))}
    </div>
  );
};

export default ConfigurationManager;
```

#### 1.3.3 **WebSocket-Integration für Real-time Updates**
```typescript
// services/frontend-service/src/hooks/useConfigurationUpdates.ts
import { useEffect, useState } from 'react';
import { io, Socket } from 'socket.io-client';

interface ConfigurationUpdate {
  field_id: string;
  old_value: any;
  new_value: any;
  updated_by: string;
  timestamp: string;
}

export const useConfigurationUpdates = () => {
  const [socket, setSocket] = useState<Socket | null>(null);
  const [lastUpdate, setLastUpdate] = useState<ConfigurationUpdate | null>(null);
  const [isConnected, setIsConnected] = useState(false);

  useEffect(() => {
    const newSocket = io('/configuration', {
      path: '/api/ws/socket.io/'
    });

    newSocket.on('connect', () => {
      setIsConnected(true);
      console.log('Connected to configuration updates');
    });

    newSocket.on('disconnect', () => {
      setIsConnected(false);
      console.log('Disconnected from configuration updates');
    });

    newSocket.on('configuration_updated', (update: ConfigurationUpdate) => {
      setLastUpdate(update);
      
      // Show notification
      if (Notification.permission === 'granted') {
        new Notification('Konfiguration aktualisiert', {
          body: `${update.field_id} wurde auf ${update.new_value} geändert`,
          icon: '/favicon.ico'
        });
      }
    });

    newSocket.on('configuration_validation_error', (error: any) => {
      console.error('Configuration validation error:', error);
      // Show error notification
    });

    setSocket(newSocket);

    return () => {
      newSocket.close();
    };
  }, []);

  const subscribeToUpdates = (fieldIds: string[]) => {
    if (socket && isConnected) {
      socket.emit('subscribe_to_fields', fieldIds);
    }
  };

  const unsubscribeFromUpdates = (fieldIds: string[]) => {
    if (socket && isConnected) {
      socket.emit('unsubscribe_from_fields', fieldIds);
    }
  };

  return {
    lastUpdate,
    isConnected,
    subscribeToUpdates,
    unsubscribeFromUpdates
  };
};
```

### 1.4 **Risk-Scoring-Engine**
```python
# shared/business/risk_scoring_engine.py
from dataclasses import dataclass
from typing import Dict, List, Any
from decimal import Decimal
from enum import Enum
import math

class RiskCategory(Enum):
    PORTFOLIO_RISK = "portfolio"
    POSITION_RISK = "position"
    MARKET_RISK = "market"
    LIQUIDITY_RISK = "liquidity"
    CONCENTRATION_RISK = "concentration"

@dataclass
class RiskFactor:
    """Einzelner Risk-Faktor"""
    category: RiskCategory
    name: str
    current_value: Decimal
    benchmark_value: Decimal
    weight: Decimal  # 0-1
    score: Decimal = field(init=False)  # 0-100
    
    def __post_init__(self):
        self.calculate_score()
    
    def calculate_score(self):
        """Risk-Score berechnen (0 = niedrig, 100 = hoch)"""
        if self.benchmark_value == 0:
            self.score = Decimal('50')  # Neutral
            return
        
        ratio = self.current_value / self.benchmark_value
        
        # Logarithmische Skalierung für extreme Werte
        if ratio > 1:
            # Überdurchschnittliches Risiko
            self.score = min(Decimal('100'), Decimal('50') + (Decimal(str(math.log(float(ratio)) * 20))))
        elif ratio < 1:
            # Unterdurchschnittliches Risiko
            self.score = max(Decimal('0'), Decimal('50') - (Decimal(str(math.log(1/float(ratio)) * 20))))
        else:
            self.score = Decimal('50')

@dataclass
class RiskAssessment:
    """Gesamthafte Risk-Assessment"""
    portfolio_id: str
    overall_risk_score: Decimal = Decimal('0')  # 0-100
    risk_level: str = ""  # "LOW", "MEDIUM", "HIGH", "CRITICAL"
    risk_factors: List[RiskFactor] = field(default_factory=list)
    recommendations: List[str] = field(default_factory=list)
    assessment_timestamp: datetime = field(default_factory=datetime.utcnow)
    
    def calculate_overall_score(self):
        """Gesamten Risk-Score berechnen"""
        if not self.risk_factors:
            self.overall_risk_score = Decimal('50')
            self.risk_level = "MEDIUM"
            return
        
        weighted_sum = sum(factor.score * factor.weight for factor in self.risk_factors)
        total_weight = sum(factor.weight for factor in self.risk_factors)
        
        if total_weight > 0:
            self.overall_risk_score = weighted_sum / total_weight
        else:
            self.overall_risk_score = Decimal('50')
        
        # Risk-Level bestimmen
        if self.overall_risk_score <= 25:
            self.risk_level = "LOW"
        elif self.overall_risk_score <= 50:
            self.risk_level = "MEDIUM"
        elif self.overall_risk_score <= 75:
            self.risk_level = "HIGH"
        else:
            self.risk_level = "CRITICAL"

class RiskScoringEngine:
    """Risk-Scoring-Engine für Portfolio-Risiko-Bewertung"""
    
    def __init__(self):
        self.risk_benchmarks = {
            "portfolio_concentration": Decimal('20'),  # Max 20% pro Position
            "sector_concentration": Decimal('25'),     # Max 25% pro Sektor
            "daily_volatility": Decimal('2'),          # Max 2% Tagesvolatilität
            "portfolio_beta": Decimal('1.2'),          # Max Beta 1.2
            "var_95": Decimal('5'),                     # Max 5% VaR
            "max_drawdown": Decimal('10'),              # Max 10% Drawdown
            "cash_ratio": Decimal('5'),                 # Min 5% Cash
            "liquidity_score": Decimal('80')           # Min 80% Liquidity-Score
        }
    
    def assess_portfolio_risk(self, portfolio_context: Dict[str, Any]) -> RiskAssessment:
        """Gesamthaftes Portfolio-Risk-Assessment"""
        portfolio_id = portfolio_context.get('portfolio_id', '')
        risk_factors = []
        
        # Portfolio-Concentration-Risk
        concentration_risk = self._calculate_concentration_risk(portfolio_context)
        risk_factors.extend(concentration_risk)
        
        # Market-Risk-Factors
        market_risk = self._calculate_market_risk(portfolio_context)
        risk_factors.extend(market_risk)
        
        # Liquidity-Risk
        liquidity_risk = self._calculate_liquidity_risk(portfolio_context)
        risk_factors.append(liquidity_risk)
        
        # Assessment erstellen
        assessment = RiskAssessment(
            portfolio_id=portfolio_id,
            risk_factors=risk_factors
        )
        
        assessment.calculate_overall_score()
        assessment.recommendations = self._generate_recommendations(assessment)
        
        return assessment
    
    def _calculate_concentration_risk(self, context: Dict[str, Any]) -> List[RiskFactor]:
        """Konzentrations-Risiko berechnen"""
        factors = []
        
        # Position-Concentration
        largest_position_percent = context.get('largest_position_percent', Decimal('0'))
        factors.append(RiskFactor(
            category=RiskCategory.CONCENTRATION_RISK,
            name="Largest Position Concentration",
            current_value=largest_position_percent,
            benchmark_value=self.risk_benchmarks['portfolio_concentration'],
            weight=Decimal('0.25')
        ))
        
        # Sector-Concentration
        largest_sector_percent = context.get('largest_sector_percent', Decimal('0'))
        factors.append(RiskFactor(
            category=RiskCategory.CONCENTRATION_RISK,
            name="Largest Sector Concentration",
            current_value=largest_sector_percent,
            benchmark_value=self.risk_benchmarks['sector_concentration'],
            weight=Decimal('0.20')
        ))
        
        # Asset-Type-Concentration
        asset_concentration = context.get('asset_type_concentration', {})
        if asset_concentration:
            max_asset_type_percent = max(asset_concentration.values())
            factors.append(RiskFactor(
                category=RiskCategory.CONCENTRATION_RISK,
                name="Asset Type Concentration",
                current_value=Decimal(str(max_asset_type_percent)),
                benchmark_value=Decimal('60'),  # Max 60% pro Asset-Type
                weight=Decimal('0.15')
            ))
        
        return factors
    
    def _calculate_market_risk(self, context: Dict[str, Any]) -> List[RiskFactor]:
        """Markt-Risiko berechnen"""
        factors = []
        
        # Portfolio-Beta
        portfolio_beta = context.get('portfolio_beta', Decimal('1.0'))
        factors.append(RiskFactor(
            category=RiskCategory.MARKET_RISK,
            name="Portfolio Beta",
            current_value=portfolio_beta,
            benchmark_value=self.risk_benchmarks['portfolio_beta'],
            weight=Decimal('0.20')
        ))
        
        # Daily-Volatility
        daily_volatility = context.get('daily_volatility_percent', Decimal('0'))
        factors.append(RiskFactor(
            category=RiskCategory.MARKET_RISK,
            name="Daily Volatility",
            current_value=daily_volatility,
            benchmark_value=self.risk_benchmarks['daily_volatility'],
            weight=Decimal('0.25')
        ))
        
        # Value-at-Risk (95%)
        var_95 = context.get('var_95_percent', Decimal('0'))
        factors.append(RiskFactor(
            category=RiskCategory.MARKET_RISK,
            name="Value at Risk (95%)",
            current_value=var_95,
            benchmark_value=self.risk_benchmarks['var_95'],
            weight=Decimal('0.30')
        ))
        
        # Maximum-Drawdown
        max_drawdown = context.get('max_drawdown_percent', Decimal('0'))
        factors.append(RiskFactor(
            category=RiskCategory.MARKET_RISK,
            name="Maximum Drawdown",
            current_value=max_drawdown,
            benchmark_value=self.risk_benchmarks['max_drawdown'],
            weight=Decimal('0.25')
        ))
        
        return factors
    
    def _calculate_liquidity_risk(self, context: Dict[str, Any]) -> RiskFactor:
        """Liquiditäts-Risiko berechnen"""
        liquidity_score = context.get('portfolio_liquidity_score', Decimal('100'))
        
        return RiskFactor(
            category=RiskCategory.LIQUIDITY_RISK,
            name="Portfolio Liquidity",
            current_value=liquidity_score,
            benchmark_value=self.risk_benchmarks['liquidity_score'],
            weight=Decimal('0.15')
        )
    
    def _generate_recommendations(self, assessment: RiskAssessment) -> List[str]:
        """Risk-basierte Empfehlungen generieren"""
        recommendations = []
        
        for factor in assessment.risk_factors:
            if factor.score > 75:  # Hohes Risiko
                if factor.category == RiskCategory.CONCENTRATION_RISK:
                    recommendations.append(f"Reduce {factor.name.lower()} through diversification")
                elif factor.category == RiskCategory.MARKET_RISK:
                    recommendations.append(f"Consider hedging against {factor.name.lower()}")
                elif factor.category == RiskCategory.LIQUIDITY_RISK:
                    recommendations.append("Increase position in more liquid assets")
        
        # Overall-Recommendations
        if assessment.risk_level == "CRITICAL":
            recommendations.append("URGENT: Portfolio risk is critically high - consider immediate risk reduction")
        elif assessment.risk_level == "HIGH":
            recommendations.append("Portfolio risk is elevated - review and adjust positions")
        
        return recommendations

# Global Risk-Scoring-Engine
risk_scoring_engine = RiskScoringEngine()
```

---

## 🔄 **2. WORKFLOW-STATE-MACHINES**

### 2.1 **Order-Lifecycle-State-Machine**
```python
# shared/workflows/order_state_machine.py
from enum import Enum
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Callable, Any
from datetime import datetime
import logging

class OrderState(Enum):
    DRAFT = "draft"                       # Order wird erstellt
    VALIDATING = "validating"             # Rule-Validation läuft
    VALIDATED = "validated"               # Validation erfolgreich
    REJECTED = "rejected"                 # Validation fehlgeschlagen
    SUBMITTING = "submitting"             # Übertragung an Broker
    SUBMITTED = "submitted"               # Bei Broker eingegangen
    PENDING = "pending"                   # Wartet auf Ausführung
    PARTIALLY_FILLED = "partially_filled" # Teilweise ausgeführt
    FILLED = "filled"                     # Vollständig ausgeführt
    CANCELLING = "cancelling"             # Stornierung läuft
    CANCELLED = "cancelled"               # Storniert
    EXPIRED = "expired"                   # Abgelaufen
    FAILED = "failed"                     # Technischer Fehler

class OrderEvent(Enum):
    VALIDATE = "validate"
    VALIDATION_PASSED = "validation_passed"
    VALIDATION_FAILED = "validation_failed"
    SUBMIT = "submit"
    SUBMISSION_CONFIRMED = "submission_confirmed"
    SUBMISSION_FAILED = "submission_failed"
    PARTIAL_FILL = "partial_fill"
    COMPLETE_FILL = "complete_fill"
    CANCEL = "cancel"
    CANCELLATION_CONFIRMED = "cancellation_confirmed"
    EXPIRE = "expire"
    FAIL = "fail"

@dataclass
class StateTransition:
    """State-Transition-Definition"""
    from_state: OrderState
    event: OrderEvent
    to_state: OrderState
    condition: Optional[Callable] = None
    action: Optional[Callable] = None
    
    def can_transition(self, context: Dict[str, Any]) -> bool:
        """Prüft ob Transition möglich ist"""
        if self.condition:
            return self.condition(context)
        return True
    
    def execute_action(self, context: Dict[str, Any]) -> Dict[str, Any]:
        """Führt Transition-Action aus"""
        if self.action:
            return self.action(context)
        return context

@dataclass
class StateMachineContext:
    """State-Machine-Context"""
    order_id: str
    current_state: OrderState
    previous_state: Optional[OrderState] = None
    transition_history: List[Dict[str, Any]] = field(default_factory=list)
    metadata: Dict[str, Any] = field(default_factory=dict)
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)

class OrderStateMachine:
    """Order-Lifecycle-State-Machine"""
    
    def __init__(self):
        self.transitions: Dict[tuple, StateTransition] = {}
        self.state_handlers: Dict[OrderState, Callable] = {}
        self.logger = logging.getLogger(__name__)
        
        self._initialize_transitions()
        self._initialize_state_handlers()
    
    def _initialize_transitions(self):
        """Standard-Transitions definieren"""
        transitions = [
            # Validation-Flow
            StateTransition(OrderState.DRAFT, OrderEvent.VALIDATE, OrderState.VALIDATING),
            StateTransition(OrderState.VALIDATING, OrderEvent.VALIDATION_PASSED, OrderState.VALIDATED),
            StateTransition(OrderState.VALIDATING, OrderEvent.VALIDATION_FAILED, OrderState.REJECTED),
            
            # Submission-Flow
            StateTransition(OrderState.VALIDATED, OrderEvent.SUBMIT, OrderState.SUBMITTING),
            StateTransition(OrderState.SUBMITTING, OrderEvent.SUBMISSION_CONFIRMED, OrderState.SUBMITTED),
            StateTransition(OrderState.SUBMITTING, OrderEvent.SUBMISSION_FAILED, OrderState.FAILED),
            StateTransition(OrderState.SUBMITTED, OrderEvent.SUBMISSION_CONFIRMED, OrderState.PENDING),
            
            # Execution-Flow
            StateTransition(OrderState.PENDING, OrderEvent.PARTIAL_FILL, OrderState.PARTIALLY_FILLED),
            StateTransition(OrderState.PENDING, OrderEvent.COMPLETE_FILL, OrderState.FILLED),
            StateTransition(OrderState.PARTIALLY_FILLED, OrderEvent.PARTIAL_FILL, OrderState.PARTIALLY_FILLED),
            StateTransition(OrderState.PARTIALLY_FILLED, OrderEvent.COMPLETE_FILL, OrderState.FILLED),
            
            # Cancellation-Flow
            StateTransition(OrderState.PENDING, OrderEvent.CANCEL, OrderState.CANCELLING),
            StateTransition(OrderState.PARTIALLY_FILLED, OrderEvent.CANCEL, OrderState.CANCELLING),
            StateTransition(OrderState.CANCELLING, OrderEvent.CANCELLATION_CONFIRMED, OrderState.CANCELLED),
            
            # Error-Handling
            StateTransition(OrderState.PENDING, OrderEvent.EXPIRE, OrderState.EXPIRED),
            StateTransition(OrderState.PENDING, OrderEvent.FAIL, OrderState.FAILED),
            StateTransition(OrderState.PARTIALLY_FILLED, OrderEvent.FAIL, OrderState.FAILED),
        ]
        
        for transition in transitions:
            key = (transition.from_state, transition.event)
            self.transitions[key] = transition
    
    def _initialize_state_handlers(self):
        """State-spezifische Handler registrieren"""
        self.state_handlers = {
            OrderState.DRAFT: self._handle_draft_state,
            OrderState.VALIDATING: self._handle_validating_state,
            OrderState.VALIDATED: self._handle_validated_state,
            OrderState.REJECTED: self._handle_rejected_state,
            OrderState.SUBMITTING: self._handle_submitting_state,
            OrderState.SUBMITTED: self._handle_submitted_state,
            OrderState.PENDING: self._handle_pending_state,
            OrderState.PARTIALLY_FILLED: self._handle_partially_filled_state,
            OrderState.FILLED: self._handle_filled_state,
            OrderState.CANCELLING: self._handle_cancelling_state,
            OrderState.CANCELLED: self._handle_cancelled_state,
            OrderState.EXPIRED: self._handle_expired_state,
            OrderState.FAILED: self._handle_failed_state,
        }
    
    def process_event(self, context: StateMachineContext, event: OrderEvent, 
                     event_data: Dict[str, Any] = None) -> StateMachineContext:
        """Event verarbeiten und State-Transition durchführen"""
        if event_data is None:
            event_data = {}
        
        current_state = context.current_state
        key = (current_state, event)
        
        if key not in self.transitions:
            self.logger.warning(f"No transition defined for {current_state} + {event}")
            return context
        
        transition = self.transitions[key]
        
        # Transition-Condition prüfen
        if not transition.can_transition(event_data):
            self.logger.warning(f"Transition condition failed for {current_state} + {event}")
            return context
        
        # State-Change durchführen
        context.previous_state = context.current_state
        context.current_state = transition.to_state
        context.updated_at = datetime.utcnow()
        
        # Transition-History aktualisieren
        context.transition_history.append({
            "from_state": transition.from_state.value,
            "event": event.value,
            "to_state": transition.to_state.value,
            "timestamp": context.updated_at.isoformat(),
            "event_data": event_data
        })
        
        # Transition-Action ausführen
        transition.execute_action(event_data)
        
        # State-Handler ausführen
        self._execute_state_handler(context, event_data)
        
        self.logger.info(f"Order {context.order_id}: {transition.from_state.value} -> {transition.to_state.value}")
        
        return context
    
    def _execute_state_handler(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """State-spezifischen Handler ausführen"""
        handler = self.state_handlers.get(context.current_state)
        if handler:
            handler(context, event_data)
    
    # State-Handler-Implementations
    def _handle_draft_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Draft-State-Handler"""
        self.logger.debug(f"Order {context.order_id} in draft state")
    
    def _handle_validating_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Validating-State-Handler"""
        # Trigger Business-Rules-Validation
        from shared.business.trading_rules_engine import trading_rules_engine
        
        # Rule-Context aus event_data erstellen
        rule_context = event_data.get('rule_context', {})
        rule_context['order_id'] = context.order_id
        
        # Pre-Trade-Rules evaluieren
        rule_results = trading_rules_engine.check_order_placement(rule_context)
        
        # Blocking-Rules prüfen
        blocking_results = [r for r in rule_results if r.blocks_action]
        
        if blocking_results:
            # Validation failed
            context.metadata['validation_errors'] = [r.message for r in blocking_results]
            # Event wird extern getriggert
        else:
            # Validation passed
            context.metadata['validation_warnings'] = [r.message for r in rule_results if not r.passed]
            # Event wird extern getriggert
    
    def _handle_validated_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Validated-State-Handler"""
        context.metadata['validated_at'] = datetime.utcnow().isoformat()
    
    def _handle_rejected_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Rejected-State-Handler"""
        context.metadata['rejected_at'] = datetime.utcnow().isoformat()
        context.metadata['rejection_reason'] = event_data.get('rejection_reason', 'Validation failed')
    
    def _handle_submitting_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Submitting-State-Handler"""
        context.metadata['submission_started_at'] = datetime.utcnow().isoformat()
        # Broker-Submission wird extern getriggert
    
    def _handle_submitted_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Submitted-State-Handler"""
        context.metadata['submitted_at'] = datetime.utcnow().isoformat()
        context.metadata['broker_order_id'] = event_data.get('broker_order_id')
    
    def _handle_pending_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Pending-State-Handler"""
        context.metadata['pending_since'] = datetime.utcnow().isoformat()
        # Market-Monitoring wird extern getriggert
    
    def _handle_partially_filled_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Partially-Filled-State-Handler"""
        fill_data = event_data.get('fill_data', {})
        
        if 'fills' not in context.metadata:
            context.metadata['fills'] = []
        
        context.metadata['fills'].append({
            "fill_quantity": fill_data.get('quantity'),
            "fill_price": fill_data.get('price'),
            "fill_timestamp": datetime.utcnow().isoformat(),
            "fill_id": fill_data.get('fill_id')
        })
    
    def _handle_filled_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Filled-State-Handler"""
        context.metadata['filled_at'] = datetime.utcnow().isoformat()
        context.metadata['final_fill'] = event_data.get('fill_data', {})
        # Post-Trade-Processing wird extern getriggert
    
    def _handle_cancelling_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Cancelling-State-Handler"""
        context.metadata['cancellation_requested_at'] = datetime.utcnow().isoformat()
        context.metadata['cancellation_reason'] = event_data.get('cancellation_reason', 'User requested')
    
    def _handle_cancelled_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Cancelled-State-Handler"""
        context.metadata['cancelled_at'] = datetime.utcnow().isoformat()
    
    def _handle_expired_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Expired-State-Handler"""
        context.metadata['expired_at'] = datetime.utcnow().isoformat()
    
    def _handle_failed_state(self, context: StateMachineContext, event_data: Dict[str, Any]):
        """Failed-State-Handler"""
        context.metadata['failed_at'] = datetime.utcnow().isoformat()
        context.metadata['failure_reason'] = event_data.get('failure_reason', 'Technical error')
        context.metadata['error_details'] = event_data.get('error_details', {})

# Global Order-State-Machine
order_state_machine = OrderStateMachine()
```

### 2.2 **Portfolio-Rebalancing-Workflow**
```python
# shared/workflows/portfolio_rebalancing_workflow.py
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Any
from decimal import Decimal
from enum import Enum
from datetime import datetime, timedelta

class RebalancingTrigger(Enum):
    SCHEDULED = "scheduled"           # Zeitbasiert (monatlich, quarterly)
    DRIFT_THRESHOLD = "drift"         # Allocation-Drift über Threshold
    PERFORMANCE_BASED = "performance" # Performance-basiert
    RISK_BASED = "risk"              # Risk-Score-basiert
    MANUAL = "manual"                # User-initiiert

class RebalancingStrategy(Enum):
    THRESHOLD = "threshold"          # Threshold-basiertes Rebalancing
    PERIODIC = "periodic"            # Zeitbasiertes Rebalancing
    SMART_BETA = "smart_beta"        # Factor-basiertes Rebalancing
    RISK_PARITY = "risk_parity"      # Risk-Parity-Ansatz

@dataclass
class AllocationTarget:
    """Ziel-Allocation für Rebalancing"""
    asset_id: str
    symbol: str
    target_percent: Decimal
    current_percent: Decimal
    drift: Decimal = field(init=False)
    
    def __post_init__(self):
        self.drift = self.current_percent - self.target_percent

@dataclass
class RebalancingPlan:
    """Rebalancing-Execution-Plan"""
    portfolio_id: str
    strategy: RebalancingStrategy
    trigger: RebalancingTrigger
    allocation_targets: List[AllocationTarget]
    required_trades: List[Dict[str, Any]] = field(default_factory=list)
    estimated_costs: Decimal = Decimal('0')
    expected_improvement: Dict[str, Decimal] = field(default_factory=dict)
    execution_priority: int = 1  # 1-5
    created_at: datetime = field(default_factory=datetime.utcnow)

class PortfolioRebalancingWorkflow:
    """Portfolio-Rebalancing-Workflow-Engine"""
    
    def __init__(self):
        self.rebalancing_rules = {
            "max_drift_threshold": Decimal('5'),      # 5% max Drift
            "min_trade_amount": Decimal('100'),       # Min €100 Trade
            "max_turnover_percent": Decimal('20'),    # Max 20% Portfolio-Turnover
            "cost_threshold_percent": Decimal('0.5'), # Max 0.5% Kosten
        }
    
    def analyze_rebalancing_need(self, portfolio_context: Dict[str, Any]) -> Optional[RebalancingPlan]:
        """Portfolio auf Rebalancing-Bedarf analysieren"""
        portfolio_id = portfolio_context.get('portfolio_id')
        current_allocations = portfolio_context.get('current_allocations', {})
        target_allocations = portfolio_context.get('target_allocations', {})
        portfolio_value = portfolio_context.get('portfolio_value', Decimal('0'))
        
        if not target_allocations:
            return None
        
        # Allocation-Targets erstellen
        allocation_targets = []
        for asset_id, target_percent in target_allocations.items():
            current_percent = current_allocations.get(asset_id, Decimal('0'))
            symbol = portfolio_context.get('symbols', {}).get(asset_id, '')
            
            allocation_targets.append(AllocationTarget(
                asset_id=asset_id,
                symbol=symbol,
                target_percent=target_percent,
                current_percent=current_percent
            ))
        
        # Rebalancing-Trigger prüfen
        trigger = self._analyze_trigger(allocation_targets, portfolio_context)
        if not trigger:
            return None
        
        # Rebalancing-Plan erstellen
        plan = RebalancingPlan(
            portfolio_id=portfolio_id,
            strategy=self._determine_strategy(trigger, portfolio_context),
            trigger=trigger,
            allocation_targets=allocation_targets
        )
        
        # Trade-Plan berechnen
        plan.required_trades = self._calculate_required_trades(allocation_targets, portfolio_value)
        plan.estimated_costs = self._estimate_trading_costs(plan.required_trades)
        plan.expected_improvement = self._calculate_expected_improvement(allocation_targets)
        
        # Cost-Benefit-Analyse
        if not self._is_rebalancing_beneficial(plan):
            return None
        
        return plan
    
    def _analyze_trigger(self, allocation_targets: List[AllocationTarget], 
                        context: Dict[str, Any]) -> Optional[RebalancingTrigger]:
        """Rebalancing-Trigger analysieren"""
        
        # Drift-Threshold-Check
        max_drift = max(abs(target.drift) for target in allocation_targets)
        if max_drift > self.rebalancing_rules["max_drift_threshold"]:
            return RebalancingTrigger.DRIFT_THRESHOLD
        
        # Risk-Score-Check
        risk_score = context.get('portfolio_risk_score', 50)
        if risk_score > 75:  # Hohes Risiko
            return RebalancingTrigger.RISK_BASED
        
        # Performance-Check
        performance_data = context.get('performance_data', {})
        underperformance = performance_data.get('benchmark_underperformance', 0)
        if underperformance > 5:  # 5% Underperformance
            return RebalancingTrigger.PERFORMANCE_BASED
        
        # Scheduled-Check
        last_rebalancing = context.get('last_rebalancing_date')
        if last_rebalancing:
            days_since = (datetime.utcnow() - last_rebalancing).days
            rebalancing_frequency = context.get('rebalancing_frequency_days', 90)
            if days_since >= rebalancing_frequency:
                return RebalancingTrigger.SCHEDULED
        
        return None
    
    def _determine_strategy(self, trigger: RebalancingTrigger, 
                          context: Dict[str, Any]) -> RebalancingStrategy:
        """Rebalancing-Strategy bestimmen"""
        user_strategy = context.get('preferred_strategy')
        if user_strategy:
            return RebalancingStrategy(user_strategy)
        
        # Standard-Strategy basierend auf Trigger
        if trigger == RebalancingTrigger.DRIFT_THRESHOLD:
            return RebalancingStrategy.THRESHOLD
        elif trigger == RebalancingTrigger.SCHEDULED:
            return RebalancingStrategy.PERIODIC
        elif trigger == RebalancingTrigger.RISK_BASED:
            return RebalancingStrategy.RISK_PARITY
        else:
            return RebalancingStrategy.THRESHOLD
    
    def _calculate_required_trades(self, allocation_targets: List[AllocationTarget], 
                                 portfolio_value: Decimal) -> List[Dict[str, Any]]:
        """Erforderliche Trades berechnen"""
        trades = []
        
        for target in allocation_targets:
            target_value = portfolio_value * target.target_percent / 100
            current_value = portfolio_value * target.current_percent / 100
            trade_amount = target_value - current_value
            
            # Minimum-Trade-Amount prüfen
            if abs(trade_amount) < self.rebalancing_rules["min_trade_amount"]:
                continue
            
            side = "buy" if trade_amount > 0 else "sell"
            quantity_value = abs(trade_amount)
            
            trades.append({
                "asset_id": target.asset_id,
                "symbol": target.symbol,
                "side": side,
                "quantity_value": quantity_value,
                "current_allocation": target.current_percent,
                "target_allocation": target.target_percent,
                "drift": target.drift,
                "priority": self._calculate_trade_priority(target.drift)
            })
        
        # Trades nach Priorität sortieren
        trades.sort(key=lambda x: x["priority"], reverse=True)
        
        return trades
    
    def _calculate_trade_priority(self, drift: Decimal) -> int:
        """Trade-Priorität basierend auf Drift berechnen"""
        abs_drift = abs(drift)
        
        if abs_drift > 10:
            return 5  # Höchste Priorität
        elif abs_drift > 7:
            return 4
        elif abs_drift > 5:
            return 3
        elif abs_drift > 3:
            return 2
        else:
            return 1  # Niedrigste Priorität
    
    def _estimate_trading_costs(self, trades: List[Dict[str, Any]]) -> Decimal:
        """Trading-Kosten schätzen"""
        total_costs = Decimal('0')
        
        for trade in trades:
            quantity_value = trade["quantity_value"]
            
            # Geschätzte Kosten: 0.1% Broker-Fee + 0.05% Spread
            estimated_fee = quantity_value * Decimal('0.001')  # 0.1%
            estimated_spread = quantity_value * Decimal('0.0005')  # 0.05%
            
            total_costs += estimated_fee + estimated_spread
        
        return total_costs
    
    def _calculate_expected_improvement(self, allocation_targets: List[AllocationTarget]) -> Dict[str, Decimal]:
        """Erwartete Verbesserung durch Rebalancing"""
        total_drift = sum(abs(target.drift) for target in allocation_targets)
        avg_drift = total_drift / len(allocation_targets) if allocation_targets else Decimal('0')
        
        # Vereinfachte Schätzung der Verbesserung
        expected_risk_reduction = min(avg_drift * Decimal('0.5'), Decimal('10'))  # Max 10%
        expected_return_improvement = min(avg_drift * Decimal('0.2'), Decimal('2'))  # Max 2%
        
        return {
            "risk_reduction_percent": expected_risk_reduction,
            "return_improvement_percent": expected_return_improvement,
            "allocation_improvement_percent": avg_drift
        }
    
    def _is_rebalancing_beneficial(self, plan: RebalancingPlan) -> bool:
        """Cost-Benefit-Analyse für Rebalancing"""
        portfolio_value = sum(trade["quantity_value"] for trade in plan.required_trades)
        if portfolio_value == 0:
            return False
        
        cost_percent = (plan.estimated_costs / portfolio_value) * 100
        
        # Kosten-Threshold prüfen
        if cost_percent > self.rebalancing_rules["cost_threshold_percent"]:
            return False
        
        # Expected-Improvement prüfen
        expected_improvement = plan.expected_improvement.get("return_improvement_percent", 0)
        if expected_improvement < cost_percent * 2:  # ROI mindestens 2:1
            return False
        
        return True
    
    def execute_rebalancing_plan(self, plan: RebalancingPlan) -> Dict[str, Any]:
        """Rebalancing-Plan ausführen"""
        execution_results = {
            "plan_id": plan.portfolio_id,
            "execution_started_at": datetime.utcnow().isoformat(),
            "total_trades": len(plan.required_trades),
            "executed_trades": 0,
            "failed_trades": 0,
            "trade_results": []
        }
        
        for trade in plan.required_trades:
            try:
                # Trade-Order erstellen (Integration mit Order-System)
                order_context = {
                    "portfolio_id": plan.portfolio_id,
                    "asset_id": trade["asset_id"],
                    "side": trade["side"],
                    "quantity_value": trade["quantity_value"],
                    "order_type": "market",  # Market-Orders für Rebalancing
                    "source": "rebalancing_workflow"
                }
                
                # Order-Submission (wird extern implementiert)
                trade_result = self._submit_rebalancing_order(order_context)
                
                execution_results["trade_results"].append(trade_result)
                
                if trade_result.get("success", False):
                    execution_results["executed_trades"] += 1
                else:
                    execution_results["failed_trades"] += 1
                    
            except Exception as e:
                execution_results["failed_trades"] += 1
                execution_results["trade_results"].append({
                    "asset_id": trade["asset_id"],
                    "success": False,
                    "error": str(e)
                })
        
        execution_results["execution_completed_at"] = datetime.utcnow().isoformat()
        execution_results["success_rate"] = (
            execution_results["executed_trades"] / execution_results["total_trades"] * 100
            if execution_results["total_trades"] > 0 else 0
        )
        
        return execution_results
    
    def _submit_rebalancing_order(self, order_context: Dict[str, Any]) -> Dict[str, Any]:
        """Rebalancing-Order submitten (Placeholder für Integration)"""
        # Integration mit Order-Management-System
        # Für jetzt: Mock-Implementation
        
        return {
            "asset_id": order_context["asset_id"],
            "order_id": f"rebal_{datetime.utcnow().timestamp()}",
            "success": True,
            "submitted_at": datetime.utcnow().isoformat()
        }

# Global Rebalancing-Workflow
portfolio_rebalancing_workflow = PortfolioRebalancingWorkflow()
```

---

## ✅ **3. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Trading-Rules-Engine (3 Tage)**
- [ ] TradingRulesEngine mit Rule-Registry implementieren
- [ ] Standard-Business-Rules für Risk-Management erstellen
- [ ] Rule-Evaluation-Functions für alle Rule-Types
- [ ] RiskScoringEngine mit Portfolio-Assessment

### **Phase 2: Order-Workflow-State-Machine (3 Tage)**
- [ ] OrderStateMachine mit allen States und Transitions
- [ ] State-Handler für jede Order-Phase implementieren
- [ ] Event-Integration für State-Changes
- [ ] Order-Lifecycle-Monitoring und -Logging

### **Phase 3: Portfolio-Workflows (3 Tage)**
- [ ] Portfolio-Rebalancing-Workflow-Engine
- [ ] Allocation-Drift-Detection und -Analysis
- [ ] Cost-Benefit-Analysis für Rebalancing-Decisions
- [ ] Automated-Execution-Engine für Rebalancing-Trades

### **Phase 4: Event-Choreography (2 Tage)**
- [ ] Cross-Service-Event-Flows definieren
- [ ] Saga-Pattern für komplexe Multi-Service-Workflows
- [ ] Compensation-Logic für Failed-Workflows
- [ ] Event-Flow-Monitoring und -Debugging

### **Phase 5: ML-Algorithm-Integration (2 Tage)**
- [ ] Scoring-Engine-Framework für AI-Models
- [ ] Signal-Generation-Pipeline aus Analysis-Results
- [ ] Confidence-Scoring und Model-Validation
- [ ] Real-time-Prediction-Workflows

**Gesamtaufwand**: 13 Tage
**Abhängigkeiten**: Datenmodell, Event-Bus, Order-Management

Diese **Business-Logic & Workflow-Spezifikation** vervollständigt die **funktionalen Kern-Requirements** und ermöglicht intelligente, regelbasierte Geschäftsprozesse im Event-driven Aktienanalyse-Ökosystem.