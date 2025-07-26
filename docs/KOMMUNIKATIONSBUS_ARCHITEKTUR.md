# 🚌 KommunikationsBus-Architektur: Event-Driven Ecosystem

## 🎯 Event-Driven Communication Vision

**Transformation**: Von direkten REST-API-Calls zu **Event-Driven Architecture** mit **zentralem KommunikationsBus** für lose gekoppelte, skalierbare Inter-Module Communication.

## 🏗️ KommunikationsBus-Architektur

### 🚌 Zentraler Event Bus (Redis Pub/Sub + Message Queue)

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                        🚌 Aktienanalyse Event Bus                              │
│                    (Redis Pub/Sub + Message Queue)                             │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  📡 Topics:                     🔄 Queues:                   ⚡ Real-time:     │
│  ├── stock.analysis.*          ├── order.execution          ├── portfolio.*    │
│  ├── portfolio.performance.*   ├── data.sync               ├── market.data    │
│  ├── trading.orders.*          ├── report.generation       ├── alerts.*       │
│  ├── system.health.*           └── notification.dispatch    └── user.updates   │
│  └── cross.system.*                                                            │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                      │
        ┌─────────────────────────────┼─────────────────────────────┐
        │                             │                             │
        ▼                             ▼                             ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│ 📈 aktienanalyse│        │ 🧮 auswertung   │        │ 💼 verwaltung   │
│                 │        │                 │        │                 │
│ Event Handler:  │        │ Event Handler:  │        │ Event Handler:  │
│ ├── Publisher   │        │ ├── Publisher   │        │ ├── Publisher   │
│ ├── Subscriber  │        │ ├── Subscriber  │        │ ├── Subscriber  │
│ └── Processor   │        │ └── Processor   │        │ └── Processor   │
└─────────────────┘        └─────────────────┘        └─────────────────┘
        │                             │                             │
        ▼                             ▼                             ▼
┌─────────────────┐        ┌─────────────────┐        ┌─────────────────┐
│ aktienanalyse.db│        │ performance.db  │        │    depot.db     │
└─────────────────┘        └─────────────────┘        └─────────────────┘
```

## 📨 Event-Schema-Design

### Core Event Types

#### 1. 📈 **Stock Analysis Events**
```json
{
  "event_type": "stock.analysis.completed",
  "event_id": "uuid-12345",
  "timestamp": "2025-01-25T15:30:00Z",
  "source": "aktienanalyse.scoring-engine",
  "version": "1.0",
  "data": {
    "analysis_id": "analysis-67890",
    "symbol": "AAPL",
    "score": 18.5,
    "confidence": 0.87,
    "technical_indicators": {
      "rsi": 65.2,
      "macd": "bullish",
      "moving_averages": "golden_cross"
    },
    "recommendation": "BUY",
    "target_price": 185.50,
    "risk_level": "MEDIUM"
  },
  "routing_key": "stock.analysis.completed.AAPL"
}
```

#### 2. 🧮 **Performance Analysis Events**
```json
{
  "event_type": "portfolio.performance.updated",
  "event_id": "uuid-23456",
  "timestamp": "2025-01-25T15:35:00Z",
  "source": "auswertung.performance-analytics",
  "version": "1.0",
  "data": {
    "portfolio_id": "portfolio-12345",
    "performance_metrics": {
      "total_return": 12.8,
      "sharpe_ratio": 1.45,
      "max_drawdown": -8.2,
      "volatility": 15.3
    },
    "top_performers": [
      {"symbol": "AAPL", "return": 25.4},
      {"symbol": "MSFT", "return": 18.7}
    ],
    "risk_assessment": "MODERATE",
    "rebalancing_suggestions": [
      {"action": "REDUCE", "symbol": "TSLA", "reason": "high_volatility"}
    ]
  },
  "routing_key": "portfolio.performance.updated.portfolio-12345"
}
```

#### 3. 💼 **Trading Events**
```json
{
  "event_type": "trading.order.executed",
  "event_id": "uuid-34567",
  "timestamp": "2025-01-25T15:40:00Z",
  "source": "verwaltung.broker-integration",
  "version": "1.0",
  "data": {
    "order_id": "order-78901",
    "symbol": "AAPL",
    "side": "BUY",
    "quantity": 10,
    "price": 182.50,
    "total_value": 1825.00,
    "fees": 2.95,
    "broker": "bitpanda_pro",
    "execution_status": "FILLED",
    "execution_timestamp": "2025-01-25T15:39:45Z"
  },
  "routing_key": "trading.order.executed.AAPL"
}
```

#### 4. 🔄 **Cross-System Intelligence Events**
```json
{
  "event_type": "cross.system.intelligence.trigger",
  "event_id": "uuid-45678",
  "timestamp": "2025-01-25T16:00:00Z",
  "source": "verwaltung.cross-system-sync",
  "version": "1.0",
  "data": {
    "trigger_type": "performance_comparison",
    "analysis_results": {
      "aktienanalyse_score": 18.5,
      "auswertung_performance": 12.8,
      "current_depot_ranking": 7
    },
    "recommendation": {
      "action": "AUTO_IMPORT",
      "symbol": "NVDA",
      "reason": "outperforms_worst_position",
      "confidence": 0.92
    },
    "affected_systems": ["verwaltung", "auswertung", "data-web-app"]
  },
  "routing_key": "cross.system.intelligence.auto_import"
}
```

## 🏗️ Module-Event-Handler-Architektur

### 📈 **aktienanalyse** Event Handler
```python
# aktienanalyse/src/event_handling/event_handler.py
class AktienanalyseEventHandler:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.setup_subscribers()
    
    def setup_subscribers(self):
        # Subscribe to relevant events
        self.event_bus.subscribe('market.data.updated.*', self.handle_market_data)
        self.event_bus.subscribe('trading.order.executed.*', self.handle_trade_feedback)
        self.event_bus.subscribe('cross.system.performance.request', self.handle_performance_request)
    
    async def publish_analysis_completed(self, analysis_result):
        event = {
            'event_type': 'stock.analysis.completed',
            'source': 'aktienanalyse.scoring-engine',
            'data': analysis_result,
            'routing_key': f'stock.analysis.completed.{analysis_result.symbol}'
        }
        await self.event_bus.publish(event)
    
    async def handle_market_data(self, event):
        # React to market data updates
        symbol = event['data']['symbol']
        await self.trigger_analysis_update(symbol)
    
    async def handle_trade_feedback(self, event):
        # Update analysis based on actual trade results
        trade_data = event['data']
        await self.update_prediction_accuracy(trade_data)
```

### 🧮 **auswertung** Event Handler
```python
# aktienanalyse-auswertung/src/event_handling/event_handler.py
class AuswertungEventHandler:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.setup_subscribers()
    
    def setup_subscribers(self):
        self.event_bus.subscribe('stock.analysis.completed.*', self.handle_new_analysis)
        self.event_bus.subscribe('trading.order.executed.*', self.handle_trade_execution)
        self.event_bus.subscribe('portfolio.rebalancing.requested', self.handle_rebalancing)
    
    async def publish_performance_update(self, portfolio_data):
        event = {
            'event_type': 'portfolio.performance.updated',
            'source': 'auswertung.performance-analytics',
            'data': portfolio_data,
            'routing_key': f'portfolio.performance.updated.{portfolio_data.portfolio_id}'
        }
        await self.event_bus.publish(event)
    
    async def handle_new_analysis(self, event):
        # Update portfolio analysis with new stock scores
        analysis_data = event['data']
        await self.update_portfolio_rankings(analysis_data)
    
    async def handle_trade_execution(self, event):
        # Update performance metrics after trade execution
        trade_data = event['data']
        await self.recalculate_portfolio_performance(trade_data)
```

### 💼 **verwaltung** Event Handler
```python
# aktienanalyse-verwaltung/src/event_handling/event_handler.py
class VerwaltungEventHandler:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.setup_subscribers()
    
    def setup_subscribers(self):
        self.event_bus.subscribe('stock.analysis.completed.*', self.handle_analysis_update)
        self.event_bus.subscribe('portfolio.performance.updated.*', self.handle_performance_update)
        self.event_bus.subscribe('market.data.realtime.*', self.handle_market_data)
        self.event_bus.subscribe('cross.system.intelligence.*', self.handle_intelligence_trigger)
    
    async def publish_order_executed(self, order_data):
        event = {
            'event_type': 'trading.order.executed',
            'source': 'verwaltung.broker-integration',
            'data': order_data,
            'routing_key': f'trading.order.executed.{order_data.symbol}'
        }
        await self.event_bus.publish(event)
    
    async def handle_analysis_update(self, event):
        # React to new analysis results
        analysis = event['data']
        if analysis['recommendation'] == 'BUY' and analysis['score'] > 15:
            await self.trigger_auto_import(analysis)
    
    async def handle_performance_update(self, event):
        # Update depot performance rankings
        performance_data = event['data']
        await self.update_depot_rankings(performance_data)
    
    async def handle_intelligence_trigger(self, event):
        # Execute cross-system intelligence actions
        intelligence_data = event['data']
        if intelligence_data['recommendation']['action'] == 'AUTO_IMPORT':
            await self.execute_auto_import(intelligence_data)
```

## 🚌 Event Bus Implementation

### Redis-basierter Event Bus
```python
# shared/event_bus/redis_event_bus.py
import redis
import json
import asyncio
from typing import Dict, Callable, List

class RedisEventBus:
    def __init__(self, redis_url: str = "redis://localhost:6379"):
        self.redis_client = redis.Redis.from_url(redis_url)
        self.pubsub = self.redis_client.pubsub()
        self.subscribers = {}
        self.message_queue = asyncio.Queue()
        
    async def publish(self, event: Dict):
        """Publish event to specific topic"""
        topic = event.get('routing_key', event['event_type'])
        
        # Add event metadata
        event.update({
            'event_id': self._generate_event_id(),
            'timestamp': self._get_timestamp(),
            'version': '1.0'
        })
        
        # Publish to Redis Pub/Sub
        self.redis_client.publish(topic, json.dumps(event))
        
        # Also queue for guaranteed delivery
        await self._queue_event(event)
        
    async def subscribe(self, pattern: str, handler: Callable):
        """Subscribe to event pattern with handler"""
        if pattern not in self.subscribers:
            self.subscribers[pattern] = []
            self.pubsub.psubscribe(pattern)
            
        self.subscribers[pattern].append(handler)
    
    async def start_listening(self):
        """Start event processing loop"""
        asyncio.create_task(self._pubsub_listener())
        asyncio.create_task(self._queue_processor())
    
    async def _pubsub_listener(self):
        """Listen for Redis Pub/Sub messages"""
        for message in self.pubsub.listen():
            if message['type'] == 'pmessage':
                pattern = message['pattern'].decode()
                data = json.loads(message['data'].decode())
                
                if pattern in self.subscribers:
                    for handler in self.subscribers[pattern]:
                        asyncio.create_task(handler(data))
    
    async def _queue_processor(self):
        """Process queued events for guaranteed delivery"""
        while True:
            event = await self.message_queue.get()
            await self._process_queued_event(event)
            self.message_queue.task_done()
```

### Event Router & Load Balancer
```python
# shared/event_bus/event_router.py
class EventRouter:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.routing_rules = self._setup_routing_rules()
        
    def _setup_routing_rules(self):
        return {
            # Stock Analysis Events
            'stock.analysis.*': [
                'auswertung.performance-analytics',
                'verwaltung.cross-system-sync',
                'data-web-app.stock-dashboard'
            ],
            
            # Portfolio Performance Events  
            'portfolio.performance.*': [
                'verwaltung.performance-engine',
                'aktienanalyse.scoring-feedback',
                'data-web-app.portfolio-dashboard'
            ],
            
            # Trading Events
            'trading.order.*': [
                'auswertung.trade-analytics',
                'aktienanalyse.prediction-feedback',
                'data-web-app.trading-ui'
            ],
            
            # Cross-System Intelligence Events
            'cross.system.*': [
                'all_modules'  # Broadcast to all
            ],
            
            # System Health Events
            'system.health.*': [
                'data-web-app.monitoring-dashboard',
                'notification.service'
            ]
        }
    
    async def route_event(self, event):
        """Route event to appropriate handlers based on rules"""
        event_type = event['event_type']
        
        for pattern, targets in self.routing_rules.items():
            if self._pattern_matches(pattern, event_type):
                for target in targets:
                    await self._deliver_to_target(target, event)
```

## 🔄 Cross-System Intelligence via Event Bus

### Intelligence Orchestrator
```python
# shared/intelligence/cross_system_orchestrator.py
class CrossSystemIntelligenceOrchestrator:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.correlation_engine = CorrelationEngine()
        self.decision_engine = DecisionEngine()
        
    async def process_intelligence_trigger(self):
        """Main intelligence processing loop"""
        # 1. Collect data from all systems via events
        system_data = await self._collect_system_data()
        
        # 2. Run correlation analysis
        correlations = self.correlation_engine.analyze(system_data)
        
        # 3. Generate recommendations
        recommendations = self.decision_engine.decide(correlations)
        
        # 4. Publish intelligence events
        for recommendation in recommendations:
            await self._publish_intelligence_event(recommendation)
    
    async def _collect_system_data(self):
        """Request data from all systems via events"""
        # Publish data request events
        await self.event_bus.publish({
            'event_type': 'cross.system.data.request',
            'data': {'request_type': 'performance_rankings'},
            'routing_key': 'cross.system.data.request'
        })
        
        # Collect responses (timeout after 5 seconds)
        responses = await self._wait_for_responses(timeout=5)
        return responses
    
    async def _publish_intelligence_event(self, recommendation):
        """Publish intelligence recommendation event"""
        event = {
            'event_type': 'cross.system.intelligence.trigger',
            'source': 'cross-system-orchestrator',
            'data': {
                'recommendation': recommendation,
                'confidence': recommendation.confidence,
                'affected_systems': recommendation.targets
            },
            'routing_key': f'cross.system.intelligence.{recommendation.action.lower()}'
        }
        
        await self.event_bus.publish(event)
```

## 📊 Event Monitoring & Analytics

### Event Analytics Dashboard
```python
# shared/monitoring/event_analytics.py
class EventAnalytics:
    def __init__(self, event_bus):
        self.event_bus = event_bus
        self.metrics = EventMetrics()
        
    def setup_monitoring(self):
        # Subscribe to all events for analytics
        self.event_bus.subscribe('*', self.track_event)
        
    async def track_event(self, event):
        """Track event for analytics"""
        await self.metrics.record_event(
            event_type=event['event_type'],
            source=event['source'],
            timestamp=event['timestamp'],
            processing_time=self._calculate_processing_time(event)
        )
        
    async def generate_analytics_report(self):
        """Generate event analytics report"""
        return {
            'total_events': await self.metrics.count_total_events(),
            'events_by_type': await self.metrics.group_by_type(),
            'events_by_source': await self.metrics.group_by_source(),
            'avg_processing_time': await self.metrics.avg_processing_time(),
            'error_rate': await self.metrics.calculate_error_rate(),
            'throughput': await self.metrics.calculate_throughput()
        }
```

## 🚀 Deployment-Integration mit KommunikationsBus

### Enhanced Service Architecture
```
LXC aktienanalyse-lxc-120/
├── core-services/
│   ├── event-bus-service/         # 🚌 Redis Event Bus (Port 6379)
│   ├── intelligence-orchestrator/ # 🧠 Cross-System Intelligence
│   ├── stock-analysis-engine/     # 📈 aktienanalyse + Event Handler
│   ├── analytics-processor/       # 🧮 auswertung + Event Handler
│   └── trading-core/             # 💼 verwaltung + Event Handler
├── integration-services/
│   ├── event-router/             # 📡 Event Routing & Load Balancing
│   ├── event-analytics/          # 📊 Event Monitoring & Analytics
│   └── api-gateway/              # 🌐 REST API Gateway (fallback)
├── frontend-application/
│   └── data-web-app/            # 🎨 Event-driven Real-time UI
└── shared-infrastructure/
    ├── event-schemas/            # 📋 Event Schema Registry
    ├── event-store/             # 💾 Event Sourcing (optional)
    └── monitoring-system/       # 📈 System-wide Event Monitoring
```

## 🎯 Vorteile der Event-Driven Architecture

### ✅ **Lose Kopplung**
- **Module kennen sich nicht direkt**: Nur Event-Schemas sind geteilt
- **Async Communication**: Keine blockierenden API-Calls zwischen Modulen
- **Fault Tolerance**: Ausfall eines Moduls blockiert nicht andere

### ✅ **Skalierbarkeit** 
- **Event Replay**: Neue Module können Events nachverarbeiten
- **Load Balancing**: Events können auf mehrere Instanzen verteilt werden
- **Horizontal Scaling**: Event Bus kann Redis Cluster verwenden

### ✅ **Real-time Intelligence**
- **Event-Stream Processing**: Sofortige Reaktion auf System-Änderungen
- **Cross-System Correlation**: Ereignisse aus allen Modulen korrelieren
- **Intelligent Automation**: Event-basierte Auto-Triggers

### ✅ **Observability**
- **Event Tracing**: Vollständige Nachverfolgung aller System-Interaktionen
- **Performance Monitoring**: Event-Processing-Metriken
- **Business Intelligence**: Event-Analytics für System-Optimierung

**Diese Event-Driven KommunikationsBus-Architektur** transformiert das Ökosystem von synchronen REST-Calls zu **asynchroner, event-basierter Kommunikation** mit **Real-time Cross-System Intelligence**!