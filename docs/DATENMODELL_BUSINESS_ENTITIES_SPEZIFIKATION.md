# 🗃️ Datenmodell & Business-Entities Spezifikation

## 🎯 **Übersicht**

**Kontext**: Vollständige Definition aller Business-Entities für das Event-driven Aktienanalyse-Ökosystem
**Ziel**: Konsistente Datenstrukturen mit PostgreSQL Event-Store und materialisierten Views
**Ansatz**: Domain-driven Design mit strikter Typisierung und Validation

---

## 🏗️ **1. DOMAIN-ENTITY-HIERARCHIE**

### 1.1 **Core-Domain-Entities**
```python
# shared/models/core_entities.py
from dataclasses import dataclass, field
from typing import Optional, List, Dict, Any, Union
from decimal import Decimal
from datetime import datetime
from enum import Enum
import uuid

# Basis-Klassen
@dataclass
class BaseEntity:
    """Basis-Entity für alle Domain-Objects"""
    id: str = field(default_factory=lambda: str(uuid.uuid4()))
    created_at: datetime = field(default_factory=datetime.utcnow)
    updated_at: datetime = field(default_factory=datetime.utcnow)
    version: int = 1
    
    def __post_init__(self):
        """Post-Init-Validation"""
        if not self.id:
            self.id = str(uuid.uuid4())
        
        if not isinstance(self.created_at, datetime):
            raise ValueError("created_at must be datetime")
            
        if not isinstance(self.updated_at, datetime):
            raise ValueError("updated_at must be datetime")

@dataclass
class AggregateRoot(BaseEntity):
    """Aggregate-Root für Domain-Aggregates"""
    events: List['DomainEvent'] = field(default_factory=list, init=False)
    
    def add_event(self, event: 'DomainEvent'):
        """Domain-Event hinzufügen"""
        self.events.append(event)
        self.updated_at = datetime.utcnow()
        self.version += 1

# Enums für Business-Constanten
class AssetType(Enum):
    STOCK = "stock"
    ETF = "etf"
    BOND = "bond"
    CRYPTO = "crypto"
    COMMODITY = "commodity"
    FOREX = "forex"

class Currency(Enum):
    EUR = "EUR"
    USD = "USD"
    GBP = "GBP"
    CHF = "CHF"
    BTC = "BTC"
    ETH = "ETH"

class OrderSide(Enum):
    BUY = "buy"
    SELL = "sell"

class OrderType(Enum):
    MARKET = "market"
    LIMIT = "limit"
    STOP = "stop"
    STOP_LIMIT = "stop_limit"

class OrderStatus(Enum):
    PENDING = "pending"
    SUBMITTED = "submitted"
    PARTIALLY_FILLED = "partially_filled"
    FILLED = "filled"
    CANCELLED = "cancelled"
    REJECTED = "rejected"
    EXPIRED = "expired"

class AnalysisType(Enum):
    TECHNICAL = "technical"
    FUNDAMENTAL = "fundamental"
    SENTIMENT = "sentiment"
    QUANTITATIVE = "quantitative"

class RiskLevel(Enum):
    VERY_LOW = "very_low"
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    VERY_HIGH = "very_high"
```

### 1.2 **Asset & Instrument-Entities**
```python
# shared/models/asset_entities.py
from shared.models.core_entities import *

@dataclass
class Asset(BaseEntity):
    """Basis-Asset-Definition"""
    symbol: str = ""
    isin: str = ""
    wkn: str = ""
    name: str = ""
    asset_type: AssetType = AssetType.STOCK
    base_currency: Currency = Currency.EUR
    exchange: str = ""
    sector: Optional[str] = None
    industry: Optional[str] = None
    country: Optional[str] = None
    
    # Trading-Properties
    is_tradeable: bool = True
    min_order_size: Decimal = Decimal('1')
    tick_size: Decimal = Decimal('0.01')
    
    # Metadata
    description: Optional[str] = None
    website_url: Optional[str] = None
    logo_url: Optional[str] = None
    tags: List[str] = field(default_factory=list)
    
    def __post_init__(self):
        super().__post_init__()
        if not self.symbol:
            raise ValueError("symbol is required")
        if not self.name:
            raise ValueError("name is required")
        
        # Symbol normalisieren
        self.symbol = self.symbol.upper().strip()
        
        # ISIN validieren (falls vorhanden)
        if self.isin and len(self.isin) != 12:
            raise ValueError("ISIN must be 12 characters")
    
    @property
    def display_name(self) -> str:
        """Display-Name für UI"""
        return f"{self.symbol} - {self.name}"
    
    @property
    def unique_identifier(self) -> str:
        """Eindeutiger Identifier (ISIN preferred, dann Symbol)"""
        return self.isin if self.isin else self.symbol

@dataclass
class MarketData(BaseEntity):
    """Market-Data für Asset"""
    asset_id: str = ""
    symbol: str = ""
    
    # Kursdaten
    price: Decimal = Decimal('0')
    previous_close: Decimal = Decimal('0')
    open_price: Decimal = Decimal('0')
    high_price: Decimal = Decimal('0')
    low_price: Decimal = Decimal('0')
    
    # Volumen & Liquidität
    volume: int = 0
    volume_avg_30d: Optional[int] = None
    market_cap: Optional[Decimal] = None
    
    # Berechnete Werte
    change_absolute: Decimal = field(init=False)
    change_percent: Decimal = field(init=False)
    
    # Metadata
    data_source: str = ""  # "bitpanda", "alpha_vantage", "twelve_data"
    data_timestamp: datetime = field(default_factory=datetime.utcnow)
    is_realtime: bool = True
    
    def __post_init__(self):
        super().__post_init__()
        
        # Berechnete Werte aktualisieren
        self.calculate_changes()
        
        if not self.asset_id:
            raise ValueError("asset_id is required")
        if not self.symbol:
            raise ValueError("symbol is required")
        if self.price < 0:
            raise ValueError("price cannot be negative")
    
    def calculate_changes(self):
        """Change-Werte berechnen"""
        if self.previous_close > 0:
            self.change_absolute = self.price - self.previous_close
            self.change_percent = (self.change_absolute / self.previous_close) * 100
        else:
            self.change_absolute = Decimal('0')
            self.change_percent = Decimal('0')
    
    @property
    def is_trending_up(self) -> bool:
        """Asset steigt"""
        return self.change_absolute > 0
    
    @property
    def is_trending_down(self) -> bool:
        """Asset fällt"""
        return self.change_absolute < 0

@dataclass
class PriceHistory(BaseEntity):
    """Historische Kursdaten"""
    asset_id: str = ""
    symbol: str = ""
    
    # OHLCV-Daten
    timestamp: datetime = field(default_factory=datetime.utcnow)
    open_price: Decimal = Decimal('0')
    high_price: Decimal = Decimal('0')
    low_price: Decimal = Decimal('0')
    close_price: Decimal = Decimal('0')
    volume: int = 0
    
    # Adjusted-Values (für Stock-Splits, Dividenden)
    adjusted_close: Optional[Decimal] = None
    dividend_amount: Optional[Decimal] = None
    split_factor: Optional[Decimal] = None
    
    # Technische Indikatoren (berechnet)
    sma_20: Optional[Decimal] = None
    sma_50: Optional[Decimal] = None
    sma_200: Optional[Decimal] = None
    ema_12: Optional[Decimal] = None
    ema_26: Optional[Decimal] = None
    rsi_14: Optional[Decimal] = None
    macd: Optional[Decimal] = None
    macd_signal: Optional[Decimal] = None
    bollinger_upper: Optional[Decimal] = None
    bollinger_lower: Optional[Decimal] = None
    
    def __post_init__(self):
        super().__post_init__()
        if not self.asset_id:
            raise ValueError("asset_id is required")
        if self.open_price <= 0 or self.close_price <= 0:
            raise ValueError("prices must be positive")
        if self.high_price < max(self.open_price, self.close_price):
            raise ValueError("high_price must be >= max(open, close)")
        if self.low_price > min(self.open_price, self.close_price):
            raise ValueError("low_price must be <= min(open, close)")
    
    @property
    def change_percent(self) -> Decimal:
        """Tages-Performance"""
        if self.open_price > 0:
            return ((self.close_price - self.open_price) / self.open_price) * 100
        return Decimal('0')
    
    @property
    def typical_price(self) -> Decimal:
        """Typical-Price (HLC/3)"""
        return (self.high_price + self.low_price + self.close_price) / 3
```

### 1.3 **Portfolio & Position-Entities**
```python
# shared/models/portfolio_entities.py
from shared.models.core_entities import *
from shared.models.asset_entities import Asset

@dataclass
class Portfolio(AggregateRoot):
    """Portfolio-Aggregate"""
    user_id: str = ""
    name: str = "Default Portfolio"
    description: Optional[str] = None
    base_currency: Currency = Currency.EUR
    
    # Portfolio-Status
    is_active: bool = True
    is_simulated: bool = False  # Paper-Trading
    
    # Performance-Tracking
    initial_value: Decimal = Decimal('0')
    cash_balance: Decimal = Decimal('0')
    invested_value: Decimal = Decimal('0')
    total_value: Decimal = Decimal('0')
    unrealized_pnl: Decimal = Decimal('0')
    realized_pnl: Decimal = Decimal('0')
    
    # Risk-Management
    max_position_size_percent: Decimal = Decimal('10')  # Max 10% pro Position
    max_sector_allocation_percent: Decimal = Decimal('25')  # Max 25% pro Sektor
    stop_loss_percentage: Optional[Decimal] = None
    
    # Metadata
    risk_profile: RiskLevel = RiskLevel.MEDIUM
    investment_strategy: Optional[str] = None
    
    def __post_init__(self):
        super().__post_init__()
        if not self.user_id:
            raise ValueError("user_id is required")
        if self.cash_balance < 0:
            raise ValueError("cash_balance cannot be negative")
    
    def calculate_total_value(self, positions: List['Position']) -> Decimal:
        """Gesamtwert Portfolio berechnen"""
        positions_value = sum(pos.current_value for pos in positions if pos.is_active)
        self.total_value = self.cash_balance + positions_value
        return self.total_value
    
    def calculate_performance(self) -> Dict[str, Decimal]:
        """Portfolio-Performance berechnen"""
        if self.initial_value > 0:
            total_return = self.total_value - self.initial_value
            total_return_percent = (total_return / self.initial_value) * 100
        else:
            total_return = Decimal('0')
            total_return_percent = Decimal('0')
        
        return {
            "total_return": total_return,
            "total_return_percent": total_return_percent,
            "unrealized_pnl": self.unrealized_pnl,
            "realized_pnl": self.realized_pnl,
            "cash_balance": self.cash_balance
        }
    
    @property
    def allocation_percentage(self) -> Decimal:
        """Investitionsgrad (invested / total)"""
        if self.total_value > 0:
            return (self.invested_value / self.total_value) * 100
        return Decimal('0')

@dataclass
class Position(BaseEntity):
    """Portfolio-Position"""
    portfolio_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    
    # Position-Details
    quantity: Decimal = Decimal('0')
    average_buy_price: Decimal = Decimal('0')
    current_price: Decimal = Decimal('0')
    current_value: Decimal = field(init=False)
    
    # Cost-Basis-Tracking
    total_cost: Decimal = Decimal('0')  # Inkl. Fees
    total_fees: Decimal = Decimal('0')
    realized_pnl: Decimal = Decimal('0')
    unrealized_pnl: Decimal = field(init=False)
    
    # Position-Status
    is_active: bool = True
    is_long: bool = True  # Long vs Short
    
    # Erste und letzte Transaktion
    first_buy_date: Optional[datetime] = None
    last_transaction_date: Optional[datetime] = None
    
    def __post_init__(self):
        super().__post_init__()
        self.calculate_values()
        
        if not self.portfolio_id:
            raise ValueError("portfolio_id is required")
        if not self.asset_id:
            raise ValueError("asset_id is required")
    
    def calculate_values(self):
        """Position-Werte berechnen"""
        self.current_value = self.quantity * self.current_price
        
        if self.quantity > 0:
            cost_basis = self.quantity * self.average_buy_price
            self.unrealized_pnl = self.current_value - cost_basis
        else:
            self.unrealized_pnl = Decimal('0')
    
    @property
    def unrealized_pnl_percent(self) -> Decimal:
        """Unrealized P&L in Prozent"""
        if self.total_cost > 0:
            return (self.unrealized_pnl / self.total_cost) * 100
        return Decimal('0')
    
    @property
    def weight_in_portfolio(self) -> Decimal:
        """Gewichtung in Portfolio (benötigt Portfolio-Context)"""
        # Wird in Service-Layer berechnet
        return Decimal('0')
    
    def update_price(self, new_price: Decimal):
        """Aktuellen Preis aktualisieren"""
        self.current_price = new_price
        self.calculate_values()
        self.updated_at = datetime.utcnow()

@dataclass
class Transaction(BaseEntity):
    """Portfolio-Transaktion"""
    portfolio_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    
    # Transaction-Details
    transaction_type: str = ""  # "buy", "sell", "dividend", "split", "fee"
    quantity: Decimal = Decimal('0')
    price: Decimal = Decimal('0')
    total_amount: Decimal = Decimal('0')
    
    # Fees & Costs
    broker_fee: Decimal = Decimal('0')
    exchange_fee: Decimal = Decimal('0')
    tax_amount: Decimal = Decimal('0')
    
    # Transaction-Status
    status: str = "completed"  # "pending", "completed", "cancelled"
    execution_timestamp: datetime = field(default_factory=datetime.utcnow)
    
    # Referenzen
    order_id: Optional[str] = None
    trade_id: Optional[str] = None
    broker_reference: Optional[str] = None
    
    # Steuerliche Informationen
    tax_year: int = field(init=False)
    is_taxable: bool = True
    
    def __post_init__(self):
        super().__post_init__()
        self.tax_year = self.execution_timestamp.year
        
        if not self.portfolio_id:
            raise ValueError("portfolio_id is required")
        if not self.asset_id:
            raise ValueError("asset_id is required")
        if self.quantity == 0:
            raise ValueError("quantity cannot be zero")
    
    @property
    def total_cost(self) -> Decimal:
        """Gesamtkosten inkl. Fees"""
        return self.total_amount + self.broker_fee + self.exchange_fee
    
    @property
    def is_buy(self) -> bool:
        """Ist Kauf-Transaktion"""
        return self.transaction_type == "buy"
    
    @property
    def is_sell(self) -> bool:
        """Ist Verkaufs-Transaktion"""
        return self.transaction_type == "sell"
```

### 1.4 **Trading & Order-Entities**
```python
# shared/models/trading_entities.py
from shared.models.core_entities import *

@dataclass
class TradingOrder(AggregateRoot):
    """Trading-Order-Aggregate"""
    portfolio_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    
    # Order-Basics
    side: OrderSide = OrderSide.BUY
    order_type: OrderType = OrderType.MARKET
    quantity: Decimal = Decimal('0')
    
    # Preis-Parameter
    limit_price: Optional[Decimal] = None
    stop_price: Optional[Decimal] = None
    
    # Order-Status
    status: OrderStatus = OrderStatus.PENDING
    filled_quantity: Decimal = Decimal('0')
    remaining_quantity: Decimal = field(init=False)
    average_fill_price: Decimal = Decimal('0')
    
    # Timing
    time_in_force: str = "GTC"  # Good Till Cancelled
    expires_at: Optional[datetime] = None
    submitted_at: Optional[datetime] = None
    filled_at: Optional[datetime] = None
    cancelled_at: Optional[datetime] = None
    
    # Execution-Details
    broker_order_id: Optional[str] = None
    broker_name: str = "bitpanda_pro"
    estimated_fees: Decimal = Decimal('0')
    actual_fees: Decimal = Decimal('0')
    
    # Risk-Management
    stop_loss_price: Optional[Decimal] = None
    take_profit_price: Optional[Decimal] = None
    max_slippage_percent: Decimal = Decimal('2')  # 2% max Slippage
    
    # Metadata
    order_source: str = "manual"  # "manual", "algorithm", "api"
    notes: Optional[str] = None
    
    def __post_init__(self):
        super().__post_init__()
        self.remaining_quantity = self.quantity - self.filled_quantity
        
        if not self.portfolio_id:
            raise ValueError("portfolio_id is required")
        if not self.asset_id:
            raise ValueError("asset_id is required")
        if self.quantity <= 0:
            raise ValueError("quantity must be positive")
        
        # Order-Type-spezifische Validierung
        if self.order_type == OrderType.LIMIT and not self.limit_price:
            raise ValueError("limit_price required for limit orders")
        if self.order_type == OrderType.STOP and not self.stop_price:
            raise ValueError("stop_price required for stop orders")
    
    @property
    def is_completely_filled(self) -> bool:
        """Order komplett ausgeführt"""
        return self.filled_quantity >= self.quantity
    
    @property
    def is_partially_filled(self) -> bool:
        """Order teilweise ausgeführt"""
        return 0 < self.filled_quantity < self.quantity
    
    @property
    def fill_percentage(self) -> Decimal:
        """Ausführungsgrad in Prozent"""
        if self.quantity > 0:
            return (self.filled_quantity / self.quantity) * 100
        return Decimal('0')
    
    @property
    def estimated_total_value(self) -> Decimal:
        """Geschätzter Gesamtwert"""
        price = self.limit_price or self.stop_price or Decimal('0')
        return self.quantity * price + self.estimated_fees
    
    def update_fill(self, filled_qty: Decimal, fill_price: Decimal, fees: Decimal = Decimal('0')):
        """Fill-Update verarbeiten"""
        self.filled_quantity += filled_qty
        self.remaining_quantity = self.quantity - self.filled_quantity
        
        # Average-Fill-Price berechnen
        if self.filled_quantity > 0:
            total_value = (self.average_fill_price * (self.filled_quantity - filled_qty)) + (fill_price * filled_qty)
            self.average_fill_price = total_value / self.filled_quantity
        
        self.actual_fees += fees
        
        # Status aktualisieren
        if self.is_completely_filled:
            self.status = OrderStatus.FILLED
            self.filled_at = datetime.utcnow()
        elif self.is_partially_filled:
            self.status = OrderStatus.PARTIALLY_FILLED
        
        self.updated_at = datetime.utcnow()

@dataclass
class Trade(BaseEntity):
    """Trade-Execution-Record"""
    order_id: str = ""
    portfolio_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    
    # Trade-Details
    side: OrderSide = OrderSide.BUY
    quantity: Decimal = Decimal('0')
    price: Decimal = Decimal('0')
    total_value: Decimal = field(init=False)
    
    # Execution-Info
    execution_timestamp: datetime = field(default_factory=datetime.utcnow)
    broker_trade_id: Optional[str] = None
    counterparty: Optional[str] = None
    
    # Costs
    broker_fee: Decimal = Decimal('0')
    exchange_fee: Decimal = Decimal('0')
    settlement_date: Optional[datetime] = None
    
    def __post_init__(self):
        super().__post_init__()
        self.total_value = self.quantity * self.price
        
        if not self.order_id:
            raise ValueError("order_id is required")
        if self.quantity <= 0:
            raise ValueError("quantity must be positive")
        if self.price <= 0:
            raise ValueError("price must be positive")
    
    @property
    def total_cost(self) -> Decimal:
        """Gesamtkosten inkl. Fees"""
        return self.total_value + self.broker_fee + self.exchange_fee

@dataclass
class OrderBook(BaseEntity):
    """Order-Book-Snapshot"""
    asset_id: str = ""
    symbol: str = ""
    exchange: str = ""
    
    # Bid/Ask-Levels
    bids: List[Dict[str, Decimal]] = field(default_factory=list)  # [{"price": x, "quantity": y}]
    asks: List[Dict[str, Decimal]] = field(default_factory=list)
    
    # Best-Bid/Ask
    best_bid: Optional[Decimal] = None
    best_ask: Optional[Decimal] = None
    spread: Optional[Decimal] = field(init=False)
    
    # Metadata
    timestamp: datetime = field(default_factory=datetime.utcnow)
    depth_levels: int = 10
    
    def __post_init__(self):
        super().__post_init__()
        self.calculate_spread()
        
        if not self.asset_id:
            raise ValueError("asset_id is required")
    
    def calculate_spread(self):
        """Bid-Ask-Spread berechnen"""
        if self.best_bid and self.best_ask:
            self.spread = self.best_ask - self.best_bid
        else:
            self.spread = None
    
    @property
    def spread_percentage(self) -> Optional[Decimal]:
        """Spread in Prozent"""
        if self.spread and self.best_ask and self.best_ask > 0:
            return (self.spread / self.best_ask) * 100
        return None
```

### 1.5 **Analysis & Signal-Entities**
```python
# shared/models/analysis_entities.py
from shared.models.core_entities import *

@dataclass
class AnalysisRequest(BaseEntity):
    """Analysis-Request"""
    user_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    
    # Analysis-Configuration
    analysis_type: AnalysisType = AnalysisType.TECHNICAL
    timeframe: str = "1D"  # 1D, 1H, 4H, 1W, 1M
    lookback_periods: int = 50
    
    # Parameter
    parameters: Dict[str, Any] = field(default_factory=dict)
    indicators: List[str] = field(default_factory=list)
    
    # Status
    status: str = "pending"  # "pending", "running", "completed", "failed"
    priority: int = 1  # 1-5, 5 = highest
    
    # Timing
    requested_at: datetime = field(default_factory=datetime.utcnow)
    started_at: Optional[datetime] = None
    completed_at: Optional[datetime] = None
    estimated_duration_seconds: Optional[int] = None
    
    def __post_init__(self):
        super().__post_init__()
        if not self.user_id:
            raise ValueError("user_id is required")
        if not self.asset_id:
            raise ValueError("asset_id is required")

@dataclass
class AnalysisResult(BaseEntity):
    """Analysis-Ergebnis"""
    request_id: str = ""
    asset_id: str = ""
    symbol: str = ""
    analysis_type: AnalysisType = AnalysisType.TECHNICAL
    
    # Ergebnisse
    recommendation: str = "HOLD"  # "BUY", "SELL", "HOLD"
    confidence_score: Decimal = Decimal('50')  # 0-100
    risk_score: Decimal = Decimal('50')  # 0-100
    
    # Detailed-Results
    indicators: Dict[str, Any] = field(default_factory=dict)
    signals: List[Dict[str, Any]] = field(default_factory=list)
    price_targets: Dict[str, Decimal] = field(default_factory=dict)
    
    # Narrative
    summary: Optional[str] = None
    detailed_analysis: Optional[str] = None
    key_factors: List[str] = field(default_factory=list)
    
    # Metadata
    generated_at: datetime = field(default_factory=datetime.utcnow)
    valid_until: Optional[datetime] = None
    model_version: str = "1.0"
    data_quality_score: Decimal = Decimal('100')
    
    def __post_init__(self):
        super().__post_init__()
        if not self.request_id:
            raise ValueError("request_id is required")
        if not (0 <= self.confidence_score <= 100):
            raise ValueError("confidence_score must be 0-100")
        if not (0 <= self.risk_score <= 100):
            raise ValueError("risk_score must be 0-100")
    
    @property
    def is_buy_signal(self) -> bool:
        """Buy-Signal"""
        return self.recommendation == "BUY" and self.confidence_score >= 70
    
    @property
    def is_sell_signal(self) -> bool:
        """Sell-Signal"""
        return self.recommendation == "SELL" and self.confidence_score >= 70
    
    @property
    def is_high_confidence(self) -> bool:
        """Hohe Konfidenz"""
        return self.confidence_score >= 80

@dataclass
class TradingSignal(BaseEntity):
    """Trading-Signal"""
    asset_id: str = ""
    symbol: str = ""
    
    # Signal-Details
    signal_type: str = ""  # "entry", "exit", "stop_loss", "take_profit"
    direction: str = ""  # "long", "short"
    strength: Decimal = Decimal('50')  # 0-100
    
    # Price-Levels
    entry_price: Optional[Decimal] = None
    stop_loss_price: Optional[Decimal] = None
    take_profit_price: Optional[Decimal] = None
    current_price: Decimal = Decimal('0')
    
    # Risk-Management
    position_size_percent: Decimal = Decimal('5')  # Empfohlene Positionsgröße
    risk_reward_ratio: Optional[Decimal] = None
    max_loss_percent: Decimal = Decimal('2')
    
    # Signal-Source
    source_analysis_id: Optional[str] = None
    source_algorithm: str = ""
    source_confidence: Decimal = Decimal('50')
    
    # Timing
    generated_at: datetime = field(default_factory=datetime.utcnow)
    valid_until: Optional[datetime] = None
    is_active: bool = True
    
    def __post_init__(self):
        super().__post_init__()
        if not self.asset_id:
            raise ValueError("asset_id is required")
        if not (0 <= self.strength <= 100):
            raise ValueError("strength must be 0-100")
        
        # Risk-Reward-Ratio berechnen
        if self.entry_price and self.stop_loss_price and self.take_profit_price:
            risk = abs(self.entry_price - self.stop_loss_price)
            reward = abs(self.take_profit_price - self.entry_price)
            if risk > 0:
                self.risk_reward_ratio = reward / risk
    
    @property
    def is_long_signal(self) -> bool:
        """Long-Signal"""
        return self.direction == "long"
    
    @property
    def is_short_signal(self) -> bool:
        """Short-Signal"""
        return self.direction == "short"
    
    @property
    def is_entry_signal(self) -> bool:
        """Entry-Signal"""
        return self.signal_type == "entry"
```

---

## 🗄️ **2. DATABASE-SCHEMA-DEFINITIONEN**

### 2.1 **PostgreSQL Event-Store-Schema**
```sql
-- shared/database/event_store_schema.sql

-- Event-Store-Tables
CREATE TABLE IF NOT EXISTS event_store (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stream_id VARCHAR(255) NOT NULL,
    stream_version INTEGER NOT NULL,
    event_type VARCHAR(255) NOT NULL,
    event_data JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    occurred_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uk_event_store_stream_version UNIQUE (stream_id, stream_version)
);

CREATE INDEX idx_event_store_stream_id ON event_store (stream_id);
CREATE INDEX idx_event_store_event_type ON event_store (event_type);
CREATE INDEX idx_event_store_occurred_at ON event_store (occurred_at);
CREATE INDEX idx_event_store_event_data_gin ON event_store USING GIN (event_data);

-- Snapshot-Store für Aggregates
CREATE TABLE IF NOT EXISTS aggregate_snapshots (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    aggregate_id VARCHAR(255) NOT NULL,
    aggregate_type VARCHAR(255) NOT NULL,
    version INTEGER NOT NULL,
    data JSONB NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    CONSTRAINT uk_snapshots_aggregate_version UNIQUE (aggregate_id, version)
);

CREATE INDEX idx_snapshots_aggregate_id ON aggregate_snapshots (aggregate_id);
CREATE INDEX idx_snapshots_aggregate_type ON aggregate_snapshots (aggregate_type);

-- Materialized Views für Query-Performance
CREATE MATERIALIZED VIEW IF NOT EXISTS current_portfolios AS
SELECT 
    p.id,
    p.user_id,
    p.name,
    p.base_currency,
    p.is_active,
    p.initial_value,
    p.cash_balance,
    p.total_value,
    p.unrealized_pnl,
    p.realized_pnl,
    p.created_at,
    p.updated_at
FROM (
    SELECT DISTINCT ON (stream_id) 
        (event_data->>'id')::UUID as id,
        event_data->>'user_id' as user_id,
        event_data->>'name' as name,
        event_data->>'base_currency' as base_currency,
        (event_data->>'is_active')::BOOLEAN as is_active,
        (event_data->>'initial_value')::DECIMAL as initial_value,
        (event_data->>'cash_balance')::DECIMAL as cash_balance,
        (event_data->>'total_value')::DECIMAL as total_value,
        (event_data->>'unrealized_pnl')::DECIMAL as unrealized_pnl,
        (event_data->>'realized_pnl')::DECIMAL as realized_pnl,
        (event_data->>'created_at')::TIMESTAMP as created_at,
        (event_data->>'updated_at')::TIMESTAMP as updated_at,
        occurred_at
    FROM event_store 
    WHERE event_type LIKE 'Portfolio%'
    ORDER BY stream_id, occurred_at DESC
) p;

CREATE UNIQUE INDEX idx_current_portfolios_id ON current_portfolios (id);
CREATE INDEX idx_current_portfolios_user_id ON current_portfolios (user_id);

CREATE MATERIALIZED VIEW IF NOT EXISTS current_positions AS
SELECT 
    p.id,
    p.portfolio_id,
    p.asset_id,
    p.symbol,
    p.quantity,
    p.average_buy_price,
    p.current_price,
    p.current_value,
    p.total_cost,
    p.unrealized_pnl,
    p.realized_pnl,
    p.is_active,
    p.updated_at
FROM (
    SELECT DISTINCT ON (stream_id)
        (event_data->>'id')::UUID as id,
        (event_data->>'portfolio_id')::UUID as portfolio_id,
        (event_data->>'asset_id')::UUID as asset_id,
        event_data->>'symbol' as symbol,
        (event_data->>'quantity')::DECIMAL as quantity,
        (event_data->>'average_buy_price')::DECIMAL as average_buy_price,
        (event_data->>'current_price')::DECIMAL as current_price,
        (event_data->>'current_value')::DECIMAL as current_value,
        (event_data->>'total_cost')::DECIMAL as total_cost,
        (event_data->>'unrealized_pnl')::DECIMAL as unrealized_pnl,
        (event_data->>'realized_pnl')::DECIMAL as realized_pnl,
        (event_data->>'is_active')::BOOLEAN as is_active,
        (event_data->>'updated_at')::TIMESTAMP as updated_at,
        occurred_at
    FROM event_store 
    WHERE event_type LIKE 'Position%'
    ORDER BY stream_id, occurred_at DESC
) p
WHERE p.is_active = true;

CREATE UNIQUE INDEX idx_current_positions_id ON current_positions (id);
CREATE INDEX idx_current_positions_portfolio_id ON current_positions (portfolio_id);
CREATE INDEX idx_current_positions_asset_id ON current_positions (asset_id);

-- Trading-Orders-View
CREATE MATERIALIZED VIEW IF NOT EXISTS current_trading_orders AS
SELECT 
    o.id,
    o.portfolio_id,
    o.asset_id,
    o.symbol,
    o.side,
    o.order_type,
    o.quantity,
    o.limit_price,
    o.stop_price,
    o.status,
    o.filled_quantity,
    o.remaining_quantity,
    o.average_fill_price,
    o.submitted_at,
    o.filled_at,
    o.updated_at
FROM (
    SELECT DISTINCT ON (stream_id)
        (event_data->>'id')::UUID as id,
        (event_data->>'portfolio_id')::UUID as portfolio_id,
        (event_data->>'asset_id')::UUID as asset_id,
        event_data->>'symbol' as symbol,
        event_data->>'side' as side,
        event_data->>'order_type' as order_type,
        (event_data->>'quantity')::DECIMAL as quantity,
        (event_data->>'limit_price')::DECIMAL as limit_price,
        (event_data->>'stop_price')::DECIMAL as stop_price,
        event_data->>'status' as status,
        (event_data->>'filled_quantity')::DECIMAL as filled_quantity,
        (event_data->>'remaining_quantity')::DECIMAL as remaining_quantity,
        (event_data->>'average_fill_price')::DECIMAL as average_fill_price,
        (event_data->>'submitted_at')::TIMESTAMP as submitted_at,
        (event_data->>'filled_at')::TIMESTAMP as filled_at,
        (event_data->>'updated_at')::TIMESTAMP as updated_at,
        occurred_at
    FROM event_store 
    WHERE event_type LIKE 'TradingOrder%'
    ORDER BY stream_id, occurred_at DESC
) o;

CREATE UNIQUE INDEX idx_current_trading_orders_id ON current_trading_orders (id);
CREATE INDEX idx_current_trading_orders_portfolio_id ON current_trading_orders (portfolio_id);
CREATE INDEX idx_current_trading_orders_status ON current_trading_orders (status);

-- Market-Data-Views
CREATE MATERIALIZED VIEW IF NOT EXISTS current_market_data AS
SELECT 
    m.asset_id,
    m.symbol,
    m.price,
    m.previous_close,
    m.open_price,
    m.high_price,
    m.low_price,
    m.volume,
    m.change_absolute,
    m.change_percent,
    m.data_source,
    m.data_timestamp,
    m.updated_at
FROM (
    SELECT DISTINCT ON (event_data->>'asset_id')
        (event_data->>'asset_id')::UUID as asset_id,
        event_data->>'symbol' as symbol,
        (event_data->>'price')::DECIMAL as price,
        (event_data->>'previous_close')::DECIMAL as previous_close,
        (event_data->>'open_price')::DECIMAL as open_price,
        (event_data->>'high_price')::DECIMAL as high_price,
        (event_data->>'low_price')::DECIMAL as low_price,
        (event_data->>'volume')::INTEGER as volume,
        (event_data->>'change_absolute')::DECIMAL as change_absolute,
        (event_data->>'change_percent')::DECIMAL as change_percent,
        event_data->>'data_source' as data_source,
        (event_data->>'data_timestamp')::TIMESTAMP as data_timestamp,
        (event_data->>'updated_at')::TIMESTAMP as updated_at,
        occurred_at
    FROM event_store 
    WHERE event_type = 'MarketDataUpdated'
    ORDER BY event_data->>'asset_id', occurred_at DESC
) m;

CREATE UNIQUE INDEX idx_current_market_data_asset_id ON current_market_data (asset_id);
CREATE INDEX idx_current_market_data_symbol ON current_market_data (symbol);
CREATE INDEX idx_current_market_data_data_timestamp ON current_market_data (data_timestamp);

-- Performance-optimierte Portfolio-Summary-View
CREATE MATERIALIZED VIEW IF NOT EXISTS portfolio_holdings_view AS
SELECT 
    p.id as portfolio_id,
    p.user_id,
    p.name as portfolio_name,
    pos.id as position_id,
    pos.asset_id,
    pos.symbol,
    a.name as asset_name,
    a.asset_type,
    pos.quantity,
    pos.average_buy_price,
    pos.current_price,
    pos.current_value,
    pos.unrealized_pnl,
    (pos.current_value / NULLIF(p.total_value, 0) * 100) as portfolio_weight_percent,
    pos.is_active,
    pos.updated_at
FROM current_portfolios p
LEFT JOIN current_positions pos ON p.id = pos.portfolio_id
LEFT JOIN (
    SELECT DISTINCT ON (event_data->>'id')
        (event_data->>'id')::UUID as id,
        event_data->>'symbol' as symbol,
        event_data->>'name' as name,
        event_data->>'asset_type' as asset_type
    FROM event_store 
    WHERE event_type = 'AssetCreated'
    ORDER BY event_data->>'id', occurred_at DESC
) a ON pos.asset_id = a.id
WHERE p.is_active = true;

CREATE INDEX idx_portfolio_holdings_portfolio_id ON portfolio_holdings_view (portfolio_id);
CREATE INDEX idx_portfolio_holdings_user_id ON portfolio_holdings_view (user_id);
CREATE INDEX idx_portfolio_holdings_asset_type ON portfolio_holdings_view (asset_type);

-- Analysis-Results-View
CREATE MATERIALIZED VIEW IF NOT EXISTS current_analysis_results AS
SELECT 
    r.id,
    r.asset_id,
    r.symbol,
    r.analysis_type,
    r.recommendation,
    r.confidence_score,
    r.risk_score,
    r.summary,
    r.generated_at,
    r.valid_until
FROM (
    SELECT DISTINCT ON (event_data->>'asset_id', event_data->>'analysis_type')
        (event_data->>'id')::UUID as id,
        (event_data->>'asset_id')::UUID as asset_id,
        event_data->>'symbol' as symbol,
        event_data->>'analysis_type' as analysis_type,
        event_data->>'recommendation' as recommendation,
        (event_data->>'confidence_score')::DECIMAL as confidence_score,
        (event_data->>'risk_score')::DECIMAL as risk_score,
        event_data->>'summary' as summary,
        (event_data->>'generated_at')::TIMESTAMP as generated_at,
        (event_data->>'valid_until')::TIMESTAMP as valid_until,
        occurred_at
    FROM event_store 
    WHERE event_type = 'AnalysisResultCreated'
    ORDER BY event_data->>'asset_id', event_data->>'analysis_type', occurred_at DESC
) r
WHERE r.valid_until IS NULL OR r.valid_until > NOW();

CREATE INDEX idx_current_analysis_results_asset_id ON current_analysis_results (asset_id);
CREATE INDEX idx_current_analysis_results_analysis_type ON current_analysis_results (analysis_type);
CREATE INDEX idx_current_analysis_results_recommendation ON current_analysis_results (recommendation);

-- Refresh-Functions für Materialized Views
CREATE OR REPLACE FUNCTION refresh_all_materialized_views()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_portfolios;
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_positions;
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_trading_orders;
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_market_data;
    REFRESH MATERIALIZED VIEW CONCURRENTLY portfolio_holdings_view;
    REFRESH MATERIALIZED VIEW CONCURRENTLY current_analysis_results;
END;
$$ LANGUAGE plpgsql;

-- Trigger für automatische View-Updates
CREATE OR REPLACE FUNCTION trigger_refresh_materialized_views()
RETURNS trigger AS $$
BEGIN
    -- Async-Refresh für bessere Performance
    PERFORM pg_notify('refresh_views', NEW.event_type);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER event_store_refresh_trigger
    AFTER INSERT ON event_store
    FOR EACH ROW
    EXECUTE FUNCTION trigger_refresh_materialized_views();
```

### 2.2 **Entity-Validation-Rules**
```python
# shared/validation/entity_validators.py
from typing import Any, Dict, List, Optional
from decimal import Decimal
import re
from datetime import datetime

class EntityValidationError(Exception):
    """Entity-Validation-Fehler"""
    def __init__(self, entity_type: str, field: str, message: str):
        self.entity_type = entity_type
        self.field = field
        self.message = message
        super().__init__(f"{entity_type}.{field}: {message}")

class BusinessRuleValidator:
    """Business-Rule-Validator für Entities"""
    
    @staticmethod
    def validate_asset(asset: 'Asset') -> List[EntityValidationError]:
        """Asset-Validation"""
        errors = []
        
        # Symbol-Format
        if not re.match(r'^[A-Z0-9]{1,10}$', asset.symbol):
            errors.append(EntityValidationError(
                "Asset", "symbol", 
                "Symbol must be 1-10 uppercase alphanumeric characters"
            ))
        
        # ISIN-Format (falls vorhanden)
        if asset.isin and not re.match(r'^[A-Z]{2}[A-Z0-9]{9}[0-9]$', asset.isin):
            errors.append(EntityValidationError(
                "Asset", "isin",
                "ISIN must follow format: 2 country letters + 9 alphanumeric + 1 check digit"
            ))
        
        # WKN-Format (falls vorhanden)
        if asset.wkn and not re.match(r'^[A-Z0-9]{6}$', asset.wkn):
            errors.append(EntityValidationError(
                "Asset", "wkn",
                "WKN must be 6 alphanumeric characters"
            ))
        
        # Tick-Size-Validation
        if asset.tick_size <= 0:
            errors.append(EntityValidationError(
                "Asset", "tick_size",
                "Tick size must be positive"
            ))
        
        # Min-Order-Size-Validation
        if asset.min_order_size <= 0:
            errors.append(EntityValidationError(
                "Asset", "min_order_size",
                "Minimum order size must be positive"
            ))
        
        return errors
    
    @staticmethod
    def validate_portfolio(portfolio: 'Portfolio') -> List[EntityValidationError]:
        """Portfolio-Validation"""
        errors = []
        
        # Name-Länge
        if len(portfolio.name.strip()) < 3:
            errors.append(EntityValidationError(
                "Portfolio", "name",
                "Portfolio name must be at least 3 characters"
            ))
        
        # Cash-Balance
        if portfolio.cash_balance < 0:
            errors.append(EntityValidationError(
                "Portfolio", "cash_balance",
                "Cash balance cannot be negative"
            ))
        
        # Position-Size-Limits
        if not (1 <= portfolio.max_position_size_percent <= 100):
            errors.append(EntityValidationError(
                "Portfolio", "max_position_size_percent",
                "Max position size must be between 1% and 100%"
            ))
        
        # Sector-Allocation-Limits
        if not (1 <= portfolio.max_sector_allocation_percent <= 100):
            errors.append(EntityValidationError(
                "Portfolio", "max_sector_allocation_percent",
                "Max sector allocation must be between 1% and 100%"
            ))
        
        # Stop-Loss-Validation
        if portfolio.stop_loss_percentage and not (0.1 <= portfolio.stop_loss_percentage <= 50):
            errors.append(EntityValidationError(
                "Portfolio", "stop_loss_percentage",
                "Stop loss percentage must be between 0.1% and 50%"
            ))
        
        return errors
    
    @staticmethod
    def validate_trading_order(order: 'TradingOrder') -> List[EntityValidationError]:
        """Trading-Order-Validation"""
        errors = []
        
        # Quantity-Validation
        if order.quantity <= 0:
            errors.append(EntityValidationError(
                "TradingOrder", "quantity",
                "Order quantity must be positive"
            ))
        
        # Limit-Order-Validation
        if order.order_type == OrderType.LIMIT:
            if not order.limit_price or order.limit_price <= 0:
                errors.append(EntityValidationError(
                    "TradingOrder", "limit_price",
                    "Limit price required and must be positive for limit orders"
                ))
        
        # Stop-Order-Validation
        if order.order_type in [OrderType.STOP, OrderType.STOP_LIMIT]:
            if not order.stop_price or order.stop_price <= 0:
                errors.append(EntityValidationError(
                    "TradingOrder", "stop_price",
                    "Stop price required and must be positive for stop orders"
                ))
        
        # Stop-Limit-Order-Validation
        if order.order_type == OrderType.STOP_LIMIT:
            if not order.limit_price or order.limit_price <= 0:
                errors.append(EntityValidationError(
                    "TradingOrder", "limit_price",
                    "Limit price required and must be positive for stop-limit orders"
                ))
        
        # Filled-Quantity-Validation
        if order.filled_quantity > order.quantity:
            errors.append(EntityValidationError(
                "TradingOrder", "filled_quantity",
                "Filled quantity cannot exceed order quantity"
            ))
        
        # Price-Reasonableness-Check
        if order.limit_price and order.stop_price:
            if order.side == OrderSide.BUY and order.stop_price > order.limit_price:
                errors.append(EntityValidationError(
                    "TradingOrder", "stop_price",
                    "Stop price should be below limit price for buy stop-limit orders"
                ))
            elif order.side == OrderSide.SELL and order.stop_price < order.limit_price:
                errors.append(EntityValidationError(
                    "TradingOrder", "stop_price",
                    "Stop price should be above limit price for sell stop-limit orders"
                ))
        
        return errors
    
    @staticmethod
    def validate_position(position: 'Position') -> List[EntityValidationError]:
        """Position-Validation"""
        errors = []
        
        # Quantity-Check
        if position.quantity < 0:
            errors.append(EntityValidationError(
                "Position", "quantity",
                "Position quantity cannot be negative"
            ))
        
        # Average-Buy-Price-Check
        if position.quantity > 0 and position.average_buy_price <= 0:
            errors.append(EntityValidationError(
                "Position", "average_buy_price",
                "Average buy price must be positive for non-zero positions"
            ))
        
        # Current-Price-Check
        if position.current_price < 0:
            errors.append(EntityValidationError(
                "Position", "current_price",
                "Current price cannot be negative"
            ))
        
        # Total-Cost-Consistency
        if position.quantity > 0:
            expected_cost = position.quantity * position.average_buy_price
            if abs(expected_cost - position.total_cost + position.total_fees) > Decimal('0.01'):
                errors.append(EntityValidationError(
                    "Position", "total_cost",
                    "Total cost inconsistent with quantity and average price"
                ))
        
        return errors
    
    @staticmethod
    def validate_market_data(market_data: 'MarketData') -> List[EntityValidationError]:
        """Market-Data-Validation"""
        errors = []
        
        # Price-Consistency
        if market_data.high_price < max(market_data.open_price, market_data.price):
            errors.append(EntityValidationError(
                "MarketData", "high_price",
                "High price must be >= max(open, current) price"
            ))
        
        if market_data.low_price > min(market_data.open_price, market_data.price):
            errors.append(EntityValidationError(
                "MarketData", "low_price",
                "Low price must be <= min(open, current) price"
            ))
        
        # Negative-Price-Check
        for field in ['price', 'previous_close', 'open_price', 'high_price', 'low_price']:
            value = getattr(market_data, field)
            if value < 0:
                errors.append(EntityValidationError(
                    "MarketData", field,
                    f"{field} cannot be negative"
                ))
        
        # Volume-Check
        if market_data.volume < 0:
            errors.append(EntityValidationError(
                "MarketData", "volume",
                "Volume cannot be negative"
            ))
        
        # Data-Timestamp-Check
        if market_data.data_timestamp > datetime.utcnow():
            errors.append(EntityValidationError(
                "MarketData", "data_timestamp",
                "Data timestamp cannot be in the future"
            ))
        
        return errors

# Entity-Validation-Decorator
def validate_entity(entity_class):
    """Decorator für automatische Entity-Validation"""
    def decorator(func):
        def wrapper(*args, **kwargs):
            result = func(*args, **kwargs)
            
            if isinstance(result, entity_class):
                validator_method = getattr(
                    BusinessRuleValidator, 
                    f'validate_{entity_class.__name__.lower()}',
                    None
                )
                
                if validator_method:
                    errors = validator_method(result)
                    if errors:
                        error_messages = [str(error) for error in errors]
                        raise ValueError(f"Entity validation failed: {'; '.join(error_messages)}")
            
            return result
        return wrapper
    return decorator
```

---

## ✅ **3. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: Core-Entities-Implementation (3 Tage)**
- [ ] BaseEntity und AggregateRoot Basis-Klassen implementieren
- [ ] Asset und MarketData Entities mit vollständiger Validation
- [ ] Portfolio und Position Entities mit Business-Logic
- [ ] Enums und Konstanten definieren

### **Phase 2: Trading-Entities (2 Tage)**
- [ ] TradingOrder-Aggregate mit State-Management
- [ ] Trade und OrderBook Entities
- [ ] Order-Validation-Rules und Business-Constraints
- [ ] Trading-spezifische Calculated-Properties

### **Phase 3: Analysis-Entities (2 Tage)**
- [ ] AnalysisRequest und AnalysisResult Entities
- [ ] TradingSignal mit Risk-Management-Properties
- [ ] Analysis-Validation und Confidence-Scoring
- [ ] Signal-Generation-Logic

### **Phase 4: Database-Schema-Implementation (3 Tage)**
- [ ] PostgreSQL Event-Store-Schema mit Indexes
- [ ] Materialized Views für Query-Performance
- [ ] Automated View-Refresh-Triggers
- [ ] Performance-Testing und Query-Optimization

### **Phase 5: Validation-Framework (2 Tage)**
- [ ] BusinessRuleValidator mit comprehensive Rules
- [ ] Entity-Validation-Decorators
- [ ] Custom-Validation-Exceptions
- [ ] Integration-Tests für alle Validation-Rules

**Gesamtaufwand**: 12 Tage
**Abhängigkeiten**: PostgreSQL, Event-Store-Framework

Diese **detaillierte Datenmodell-Spezifikation** bildet das **stabile Fundament** für alle Services und ermöglicht konsistente Datenstrukturen im gesamten Event-driven Aktienanalyse-Ökosystem.