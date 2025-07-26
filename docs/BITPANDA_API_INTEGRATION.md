# 📊 Bitpanda API Integration für Kursanalyse und Vorhersage

## 🎯 Integration Overview

Die **Bitpanda Pro API** wird als **primäre Datenquelle** für Kursanalyse und Vorhersage im **aktienanalyse** Basis-System integriert. Dies erweitert die bestehenden Datenquellen (Alpha Vantage, Yahoo Finance, FRED) um hochqualitative Echtzeit-Marktdaten.

### 🔄 Dual-Purpose Integration
```
Bitpanda Pro API
├── 📊 aktienanalyse (Market Data Source)
│   ├── Historical Price Data
│   ├── Real-time Market Data
│   ├── Volume & Liquidity Data
│   └── Technical Analysis Input
└── 💼 aktienanalyse-verwaltung (Trading Interface)
    ├── Order Execution
    ├── Portfolio Sync
    ├── Account Management
    └── Trade Execution
```

## 📡 Bitpanda Pro API Spezifikation

### API Endpoints für Market Data
```
Public Market Data (Keine Authentifizierung):
GET /public/v1/instruments          # Verfügbare Instrumente
GET /public/v1/order-book/{symbol}  # Order Book Daten
GET /public/v1/time                 # Server Zeit
GET /public/v1/candlesticks/{symbol} # OHLCV Candlestick Daten

Private Market Data (API Key erforderlich):
GET /account/balances               # Account Balances
GET /account/trades                 # Trade History
GET /account/orders                 # Order History
```

### WebSocket Market Data Streams
```
Public Streams:
MARKET_TICKER           # Real-time Price Updates
ORDER_BOOK_UPDATES      # Order Book Changes
CANDLESTICKS           # Real-time OHLCV Data
MARKET_TICKER_STATS    # 24h Statistics

Private Streams:
ACCOUNT_UPDATES        # Balance Changes
ORDER_UPDATES          # Order Status Changes
TRADE_UPDATES          # Trade Execution Updates
```

### Rate Limits
- **Public API**: 100 Requests/Minute
- **Private API**: 120 Requests/Minute  
- **WebSocket**: Unbegrenzte Connections

## 🔍 Integration in aktienanalyse data-sources

### BitpandaAPI Plugin Architektur
```
data-sources/bitpanda-api/
├── bitpanda_client.py              # REST API Client
├── bitpanda_websocket.py           # WebSocket Manager
├── bitpanda_data_mapper.py         # Data Format Converter
├── bitpanda_cache_manager.py       # Local Data Cache
├── bitpanda_rate_limiter.py        # Rate Limit Management
└── config/
    ├── instruments.json            # Supported Instruments
    ├── api_config.yaml            # API Configuration
    └── data_schema.json           # Data Schema Definitions
```

### BitpandaClient Implementation
```python
class BitpandaMarketDataClient:
    """
    Bitpanda Pro API Client für Market Data
    Separate Instanz von Trading Client in aktienanalyse-verwaltung
    """
    
    def __init__(self, api_key: str = None, rate_limit: int = 100):
        self.base_url = "https://api.exchange.bitpanda.com/public/v1"
        self.api_key = api_key  # Optional für Public Data
        self.rate_limiter = RateLimiter(rate_limit, window=60)
        self.cache = BitpandaDataCache()
        
    async def get_instruments(self) -> List[Dict]:
        """Verfügbare Trading-Instrumente abrufen"""
        return await self._fetch("/instruments")
        
    async def get_candlesticks(self, instrument: str, 
                             granularity: str = "1h",
                             from_time: datetime = None,
                             to_time: datetime = None) -> List[Dict]:
        """OHLCV Candlestick Daten für technische Analyse"""
        params = {
            "instrument_code": instrument,
            "unit": granularity,
            "from": from_time.isoformat() if from_time else None,
            "to": to_time.isoformat() if to_time else None
        }
        return await self._fetch(f"/candlesticks/{instrument}", params)
        
    async def get_order_book(self, instrument: str, level: int = 3) -> Dict:
        """Order Book für Liquidity-Analyse"""
        return await self._fetch(f"/order-book/{instrument}?level={level}")
        
    async def get_ticker_stats(self, instrument: str) -> Dict:
        """24h Trading Statistics"""
        return await self._fetch(f"/market-ticker/{instrument}")
```

### WebSocket Market Data Stream
```python
class BitpandaWebSocketFeed:
    """
    Real-time Market Data über WebSocket
    """
    
    def __init__(self, on_data_callback: Callable):
        self.ws_url = "wss://streams.exchange.bitpanda.com/"
        self.on_data = on_data_callback
        self.subscriptions = set()
        
    async def subscribe_ticker(self, instruments: List[str]):
        """Real-time Ticker Daten abonnieren"""
        for instrument in instruments:
            await self._subscribe("MARKET_TICKER", {"instrument_code": instrument})
            
    async def subscribe_candlesticks(self, instruments: List[str], granularity: str = "1m"):
        """Real-time Candlestick Updates"""
        for instrument in instruments:
            await self._subscribe("CANDLESTICKS", {
                "instrument_code": instrument,
                "time_granularity": granularity
            })
            
    async def _on_message(self, message: Dict):
        """WebSocket Message Handler"""
        if message["channel"] == "MARKET_TICKER":
            await self._handle_ticker_update(message)
        elif message["channel"] == "CANDLESTICKS":
            await self._handle_candlestick_update(message)
            
        # Forward zu aktienanalyse Event System
        await self.on_data(message)
```

## 🧮 Integration in scoring-engine

### Bitpanda Analytics Module
```
scoring-engine/bitpanda-analytics/
├── bitpanda_technical_analysis.py  # Bitpanda-spezifische TA
├── liquidity_analyzer.py          # Order Book Liquidity Analysis
├── volume_profile_analyzer.py     # Volume Profile Analysis
├── real_time_momentum.py          # Real-time Momentum Indicators
└── bitpanda_ml_features.py        # ML Feature Engineering
```

### Bitpanda-spezifische Technical Analysis
```python
class BitpandaTechnicalAnalysis:
    """
    Erweiterte technische Analyse mit Bitpanda-spezifischen Metriken
    """
    
    def __init__(self, bitpanda_client: BitpandaMarketDataClient):
        self.client = bitpanda_client
        
    async def calculate_liquidity_score(self, instrument: str) -> float:
        """
        Liquidity Score basierend auf Order Book Depth
        """
        order_book = await self.client.get_order_book(instrument, level=3)
        
        bid_depth = sum(float(level["amount"]) for level in order_book["bids"])
        ask_depth = sum(float(level["amount"]) for level in order_book["asks"])
        
        spread = float(order_book["asks"][0]["price"]) - float(order_book["bids"][0]["price"])
        mid_price = (float(order_book["asks"][0]["price"]) + float(order_book["bids"][0]["price"])) / 2
        
        spread_pct = spread / mid_price
        total_depth = bid_depth + ask_depth
        
        # Liquidity Score: Hohe Tiefe, niedriger Spread = bessere Liquidität
        liquidity_score = total_depth / (1 + spread_pct * 100)
        
        return min(liquidity_score / 1000, 1.0)  # Normalisiert auf 0-1
        
    async def calculate_volume_weighted_momentum(self, instrument: str, 
                                               periods: int = 14) -> Dict:
        """
        Volume-gewichteter Momentum Indikator
        """
        candlesticks = await self.client.get_candlesticks(
            instrument, granularity="1h", 
            from_time=datetime.utcnow() - timedelta(hours=periods*2)
        )
        
        vwap_values = []
        momentum_values = []
        
        for i in range(len(candlesticks) - periods):
            # Volume Weighted Average Price
            total_volume = sum(float(c["volume"]) for c in candlesticks[i:i+periods])
            vwap = sum(float(c["close"]) * float(c["volume"]) 
                      for c in candlesticks[i:i+periods]) / total_volume
            vwap_values.append(vwap)
            
            # Momentum vs VWAP
            current_price = float(candlesticks[i+periods-1]["close"])
            momentum = (current_price - vwap) / vwap
            momentum_values.append(momentum)
            
        return {
            "current_momentum": momentum_values[-1],
            "momentum_trend": momentum_values[-3:],  # Last 3 periods
            "vwap": vwap_values[-1],
            "strength": abs(momentum_values[-1])
        }
        
    async def detect_unusual_volume(self, instrument: str) -> Dict:
        """
        Erkennung ungewöhnlicher Handelsvolumen
        """
        # 24h Stats für Referenz
        stats_24h = await self.client.get_ticker_stats(instrument)
        avg_volume_24h = float(stats_24h["volume"])
        
        # Aktuelle Stunden-Volumen
        recent_candles = await self.client.get_candlesticks(
            instrument, granularity="1h",
            from_time=datetime.utcnow() - timedelta(hours=6)
        )
        
        current_hour_volume = float(recent_candles[-1]["volume"])
        avg_hour_volume = avg_volume_24h / 24
        
        volume_ratio = current_hour_volume / avg_hour_volume
        
        return {
            "volume_ratio": volume_ratio,
            "is_unusual": volume_ratio > 2.0,  # 200% über Durchschnitt
            "current_volume": current_hour_volume,
            "average_volume": avg_hour_volume,
            "volume_trend": [float(c["volume"]) for c in recent_candles[-6:]]
        }
```

## 🗄️ Data Layer Integration

### Bitpanda Cache Management
```
data-layer/bitpanda-cache/
├── bitpanda_data_store.py         # SQLite Cache für Bitpanda Daten
├── real_time_buffer.py           # In-Memory Buffer für WebSocket
├── cache_sync_manager.py         # Synchronisation zwischen Cache und DB
└── data_retention_policy.py     # Datenaufbewahrung und Cleanup
```

### Bitpanda Data Schema
```sql
-- Bitpanda Market Data Cache Tables
CREATE TABLE bitpanda_instruments (
    id INTEGER PRIMARY KEY,
    instrument_code TEXT UNIQUE NOT NULL,
    base_currency TEXT NOT NULL,
    quote_currency TEXT NOT NULL,
    min_size DECIMAL(15,8),
    max_size DECIMAL(15,8),
    price_precision INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    last_updated DATETIME NOT NULL
);

CREATE TABLE bitpanda_candlesticks (
    id INTEGER PRIMARY KEY,
    instrument_code TEXT NOT NULL,
    granularity TEXT NOT NULL,  -- 1m, 5m, 15m, 1h, 4h, 1d
    timestamp DATETIME NOT NULL,
    open_price DECIMAL(15,8) NOT NULL,
    high_price DECIMAL(15,8) NOT NULL, 
    low_price DECIMAL(15,8) NOT NULL,
    close_price DECIMAL(15,8) NOT NULL,
    volume DECIMAL(15,8) NOT NULL,
    UNIQUE(instrument_code, granularity, timestamp)
);

CREATE TABLE bitpanda_order_book_snapshots (
    id INTEGER PRIMARY KEY,
    instrument_code TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    best_bid DECIMAL(15,8),
    best_ask DECIMAL(15,8),
    bid_depth_1 DECIMAL(15,8),    -- Level 1-3 Order Book
    ask_depth_1 DECIMAL(15,8),
    spread_pct DECIMAL(8,6),
    liquidity_score DECIMAL(8,6)
);

CREATE TABLE bitpanda_real_time_feed (
    id INTEGER PRIMARY KEY,
    instrument_code TEXT NOT NULL,
    timestamp DATETIME NOT NULL,
    price DECIMAL(15,8) NOT NULL,
    volume_24h DECIMAL(15,8),
    price_change_24h DECIMAL(8,6),
    feed_type TEXT CHECK(feed_type IN ('ticker', 'trade', 'orderbook'))
);
```

## 🌐 Northbound API Integration

### Bitpanda Proxy API
```
northbound-api/bitpanda-proxy/
├── market_data_proxy.py          # Proxy für Market Data Endpoints
├── real_time_stream_proxy.py     # WebSocket Proxy für Frontend
├── cache_api.py                  # Cached Data API
└── aggregated_analytics_api.py   # Kombinierte Analytics API
```

### API Endpoints für Frontend
```python
@app.route('/api/bitpanda/instruments')
async def get_instruments():
    """Verfügbare Instrumente mit Bitpanda-spezifischen Metriken"""
    
@app.route('/api/bitpanda/market-data/<instrument>')
async def get_market_data(instrument):
    """Umfassende Marktdaten für ein Instrument"""
    
@app.route('/api/bitpanda/analytics/<instrument>')
async def get_bitpanda_analytics(instrument):
    """Bitpanda-spezifische Analytics (Liquidität, Momentum etc.)"""
    
@app.route('/api/bitpanda/real-time/<instrument>')
async def websocket_real_time_feed(instrument):
    """WebSocket für Real-time Updates"""
```

## 🔄 Event-Driven Integration

### Cross-System Event Flow
```
Bitpanda WebSocket → aktienanalyse Event Bus → All Projects

Event Types:
├── bitpanda.market.ticker.update
├── bitpanda.market.candlestick.new
├── bitpanda.market.orderbook.change
├── bitpanda.market.volume.unusual
├── bitpanda.analytics.momentum.change
└── bitpanda.analytics.liquidity.update
```

### Event Schema Example
```json
{
  "event_type": "bitpanda.market.ticker.update",
  "timestamp": "2025-07-26T10:30:00Z",
  "source": "bitpanda-websocket",
  "data": {
    "instrument_code": "BTC_EUR",
    "price": 45678.90,
    "volume_24h": 1234567.89,
    "price_change_24h": 0.0234,
    "liquidity_score": 0.87,
    "momentum_score": 0.34
  },
  "analytics": {
    "unusual_volume": false,
    "momentum_direction": "bullish",
    "liquidity_tier": "high"
  }
}
```

## 📊 ML Feature Engineering mit Bitpanda Daten

### Enhanced Features für ML Modelle
```python
class BitpandaMLFeatures:
    """
    Erweiterte Feature-Generierung mit Bitpanda-spezifischen Daten
    """
    
    def generate_liquidity_features(self, instrument: str, lookback: int = 168) -> Dict:
        """Liquiditäts-Features über Zeit"""
        return {
            "avg_spread_1h": float,
            "avg_spread_24h": float,
            "order_book_imbalance": float,  # bid_depth / ask_depth
            "liquidity_volatility": float,  # Schwankung der Liquidität
            "depth_percentile_rank": float  # Ranking vs. andere Assets
        }
        
    def generate_volume_profile_features(self, instrument: str) -> Dict:
        """Volume Profile Features"""
        return {
            "volume_at_price_levels": List[float],
            "poc_distance": float,  # Distance to Point of Control
            "volume_concentration": float,  # Konzentration um POC
            "volume_trend_strength": float
        }
        
    def generate_cross_market_features(self, instrument: str) -> Dict:
        """Cross-Market Correlation Features"""
        return {
            "btc_correlation": float,  # Korrelation zu Bitcoin
            "market_beta": float,      # Beta zum Gesamtmarkt
            "relative_strength": float # vs. ähnliche Assets
        }
```

Diese **Bitpanda API Integration** erweitert das aktienanalyse-ökosystem um:

✅ **Hochqualitative Echtzeit-Marktdaten** für verbesserte Analysen  
✅ **Bitpanda-spezifische Analytics** (Liquidität, Volume Profile)  
✅ **Real-time Event-Stream** für alle Projekte im Ökosystem  
✅ **Enhanced ML Features** für bessere Vorhersagemodelle  
✅ **Unified Data Source** für Trading und Analyse  
✅ **Rate-Limited & Cached** API-Zugriff für Stabilität