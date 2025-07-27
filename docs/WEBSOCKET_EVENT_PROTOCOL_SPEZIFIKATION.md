# 🔄 WebSocket Event Protocol Spezifikation - Real-time Updates

## 🎯 **Übersicht**

**Kontext**: Event-driven Architektur mit real-time Frontend-Updates für Aktienanalyse-Ökosystem
**Ziel**: Bidirektionale WebSocket-Kommunikation für Live-Daten und Benutzerinteraktionen
**Ansatz**: Standardisiertes Event-Protocol mit Auto-Reconnection und Failover

---

## 🏗️ **1. WEBSOCKET-ARCHITEKTUR**

### 1.1 **Event-Bus-WebSocket-Gateway**
```python
# services/event-bus-service/src/websocket_gateway.py
import asyncio
import json
import redis.asyncio as redis
from typing import Dict, Set, Optional, Any
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from dataclasses import dataclass, asdict
from datetime import datetime
import uuid
import logging

@dataclass
class WebSocketMessage:
    """Standardisiertes WebSocket-Message-Format"""
    type: str
    event: str
    data: Dict[str, Any]
    timestamp: str
    correlation_id: Optional[str] = None
    source_service: Optional[str] = None
    target_client: Optional[str] = None
    
    @classmethod
    def create(cls, event_type: str, event_name: str, data: Dict[str, Any], 
               correlation_id: str = None, source: str = None) -> 'WebSocketMessage':
        return cls(
            type=event_type,
            event=event_name,
            data=data,
            timestamp=datetime.utcnow().isoformat(),
            correlation_id=correlation_id or str(uuid.uuid4()),
            source_service=source
        )

class WebSocketEventTypes:
    """Event-Type-Konstanten"""
    # Portfolio-Events
    PORTFOLIO_UPDATE = "portfolio.update"
    POSITION_CHANGED = "portfolio.position_changed"
    PORTFOLIO_VALUE_CHANGED = "portfolio.value_changed"
    
    # Trading-Events
    ORDER_CREATED = "trading.order_created"
    ORDER_FILLED = "trading.order_filled"
    ORDER_CANCELLED = "trading.order_cancelled"
    ORDER_FAILED = "trading.order_failed"
    
    # Market-Data-Events
    PRICE_UPDATE = "market.price_update"
    MARKET_ALERT = "market.alert"
    ANALYSIS_COMPLETE = "analysis.complete"
    
    # System-Events
    SERVICE_STATUS = "system.service_status"
    PERFORMANCE_ALERT = "system.performance_alert"
    ERROR_OCCURRED = "system.error"
    
    # User-Events (bidirektional)
    USER_ACTION = "user.action"
    USER_COMMAND = "user.command"
    USER_SUBSCRIPTION = "user.subscription"

class ConnectionManager:
    """WebSocket-Connection-Manager"""
    
    def __init__(self):
        # Client-Connections: client_id -> WebSocket
        self.active_connections: Dict[str, WebSocket] = {}
        
        # Subscriptions: event_type -> Set[client_id]
        self.subscriptions: Dict[str, Set[str]] = {}
        
        # Client-Metadata: client_id -> metadata
        self.client_metadata: Dict[str, Dict[str, Any]] = {}
        
        # Redis für Event-Pub/Sub
        self.redis_client = None
        
        # Logging
        self.logger = logging.getLogger(__name__)
    
    async def initialize_redis(self):
        """Redis-Connection für Event-Bus initialisieren"""
        self.redis_client = redis.Redis(
            host='localhost', 
            port=6379, 
            decode_responses=True
        )
        
        # Event-Bus-Subscriber starten
        asyncio.create_task(self.event_bus_subscriber())
    
    async def connect(self, websocket: WebSocket, client_id: str = None) -> str:
        """WebSocket-Connection registrieren"""
        await websocket.accept()
        
        if not client_id:
            client_id = str(uuid.uuid4())
        
        self.active_connections[client_id] = websocket
        self.client_metadata[client_id] = {
            "connected_at": datetime.utcnow().isoformat(),
            "last_activity": datetime.utcnow().isoformat(),
            "subscriptions": set()
        }
        
        self.logger.info(f"WebSocket client {client_id} connected")
        
        # Welcome-Message senden
        await self.send_to_client(client_id, WebSocketMessage.create(
            "system", "connection.established",
            {"client_id": client_id, "server_time": datetime.utcnow().isoformat()}
        ))
        
        return client_id
    
    async def disconnect(self, client_id: str):
        """WebSocket-Connection entfernen"""
        if client_id in self.active_connections:
            # Alle Subscriptions entfernen
            for event_type in list(self.subscriptions.keys()):
                if client_id in self.subscriptions[event_type]:
                    self.subscriptions[event_type].remove(client_id)
                    if not self.subscriptions[event_type]:
                        del self.subscriptions[event_type]
            
            # Connection entfernen
            del self.active_connections[client_id]
            del self.client_metadata[client_id]
            
            self.logger.info(f"WebSocket client {client_id} disconnected")
    
    async def subscribe(self, client_id: str, event_type: str):
        """Client für Event-Type registrieren"""
        if event_type not in self.subscriptions:
            self.subscriptions[event_type] = set()
        
        self.subscriptions[event_type].add(client_id)
        self.client_metadata[client_id]["subscriptions"].add(event_type)
        
        self.logger.info(f"Client {client_id} subscribed to {event_type}")
        
        # Bestätigung senden
        await self.send_to_client(client_id, WebSocketMessage.create(
            "system", "subscription.confirmed",
            {"event_type": event_type, "client_id": client_id}
        ))
    
    async def unsubscribe(self, client_id: str, event_type: str):
        """Client von Event-Type entfernen"""
        if event_type in self.subscriptions and client_id in self.subscriptions[event_type]:
            self.subscriptions[event_type].remove(client_id)
            self.client_metadata[client_id]["subscriptions"].discard(event_type)
            
            if not self.subscriptions[event_type]:
                del self.subscriptions[event_type]
            
            self.logger.info(f"Client {client_id} unsubscribed from {event_type}")
    
    async def send_to_client(self, client_id: str, message: WebSocketMessage):
        """Nachricht an spezifischen Client senden"""
        if client_id in self.active_connections:
            try:
                websocket = self.active_connections[client_id]
                await websocket.send_text(json.dumps(asdict(message)))
                
                # Last-Activity aktualisieren
                self.client_metadata[client_id]["last_activity"] = datetime.utcnow().isoformat()
                
            except Exception as e:
                self.logger.error(f"Error sending message to client {client_id}: {str(e)}")
                await self.disconnect(client_id)
    
    async def broadcast_to_subscribers(self, event_type: str, message: WebSocketMessage):
        """Nachricht an alle Subscriber eines Event-Types senden"""
        if event_type in self.subscriptions:
            subscribers = list(self.subscriptions[event_type])
            
            for client_id in subscribers:
                await self.send_to_client(client_id, message)
    
    async def broadcast_to_all(self, message: WebSocketMessage):
        """Nachricht an alle verbundenen Clients senden"""
        client_ids = list(self.active_connections.keys())
        
        for client_id in client_ids:
            await self.send_to_client(client_id, message)
    
    async def event_bus_subscriber(self):
        """Redis Event-Bus-Subscriber für interne Events"""
        try:
            pubsub = self.redis_client.pubsub()
            await pubsub.subscribe("aktienanalyse:events:websocket")
            
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    try:
                        event_data = json.loads(message['data'])
                        
                        # WebSocket-Message erstellen
                        ws_message = WebSocketMessage.create(
                            event_data.get('type', 'unknown'),
                            event_data.get('event', 'unknown'),
                            event_data.get('data', {}),
                            event_data.get('correlation_id'),
                            event_data.get('source_service')
                        )
                        
                        # An entsprechende Subscriber weiterleiten
                        event_type = event_data.get('event')
                        if event_type:
                            await self.broadcast_to_subscribers(event_type, ws_message)
                        
                    except Exception as e:
                        self.logger.error(f"Error processing event bus message: {str(e)}")
                        
        except Exception as e:
            self.logger.error(f"Event bus subscriber error: {str(e)}")

# WebSocket-Gateway-Service
app = FastAPI(title="Event-Bus WebSocket Gateway")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

connection_manager = ConnectionManager()

@app.on_event("startup")
async def startup():
    await connection_manager.initialize_redis()

@app.websocket("/ws/{client_id}")
async def websocket_endpoint(websocket: WebSocket, client_id: str = None):
    client_id = await connection_manager.connect(websocket, client_id)
    
    try:
        while True:
            # Nachricht vom Client empfangen
            data = await websocket.receive_text()
            
            try:
                message_data = json.loads(data)
                await handle_client_message(client_id, message_data)
                
            except json.JSONDecodeError:
                await connection_manager.send_to_client(client_id, WebSocketMessage.create(
                    "error", "invalid_message_format",
                    {"error": "Invalid JSON format"}
                ))
                
    except WebSocketDisconnect:
        await connection_manager.disconnect(client_id)

async def handle_client_message(client_id: str, message_data: Dict[str, Any]):
    """Client-Message-Handler"""
    message_type = message_data.get('type')
    event = message_data.get('event')
    data = message_data.get('data', {})
    
    if message_type == "subscription":
        if event == "subscribe":
            event_types = data.get('event_types', [])
            for event_type in event_types:
                await connection_manager.subscribe(client_id, event_type)
        elif event == "unsubscribe":
            event_types = data.get('event_types', [])
            for event_type in event_types:
                await connection_manager.unsubscribe(client_id, event_type)
    
    elif message_type == "user":
        # User-Commands an Backend weiterleiten
        await forward_user_command(client_id, event, data)
    
    elif message_type == "ping":
        # Heartbeat
        await connection_manager.send_to_client(client_id, WebSocketMessage.create(
            "system", "pong",
            {"timestamp": datetime.utcnow().isoformat()}
        ))

async def forward_user_command(client_id: str, event: str, data: Dict[str, Any]):
    """User-Commands an entsprechende Backend-Services weiterleiten"""
    
    # Event für Backend-Services erstellen
    backend_event = {
        "type": "user_command",
        "event": event,
        "data": data,
        "client_id": client_id,
        "timestamp": datetime.utcnow().isoformat(),
        "correlation_id": str(uuid.uuid4())
    }
    
    # An Redis Event-Bus senden
    await connection_manager.redis_client.publish(
        "aktienanalyse:events:user_commands",
        json.dumps(backend_event)
    )
```

### 1.2 **WebSocket-Client-Integration**
```typescript
// services/frontend-service/src/static/js/websocket-client.ts
interface WebSocketMessage {
    type: string;
    event: string;
    data: any;
    timestamp: string;
    correlation_id?: string;
    source_service?: string;
    target_client?: string;
}

interface SubscriptionConfig {
    event_types: string[];
    auto_reconnect: boolean;
    heartbeat_interval: number;
}

class WebSocketEventClient {
    private ws: WebSocket | null = null;
    private clientId: string | null = null;
    private isConnected: boolean = false;
    private subscriptions: Set<string> = new Set();
    private eventHandlers: Map<string, Function[]> = new Map();
    private reconnectAttempts: number = 0;
    private maxReconnectAttempts: number = 10;
    private reconnectInterval: number = 1000;
    private heartbeatTimer: NodeJS.Timer | null = null;
    
    constructor(
        private wsUrl: string = 'wss://localhost/ws',
        private config: SubscriptionConfig = {
            event_types: [],
            auto_reconnect: true,
            heartbeat_interval: 30000
        }
    ) {}
    
    async connect(): Promise<void> {
        try {
            this.ws = new WebSocket(`${this.wsUrl}/${this.clientId || ''}`);
            
            this.ws.onopen = (event) => {
                console.log('WebSocket connected');
                this.isConnected = true;
                this.reconnectAttempts = 0;
                
                // Initial-Subscriptions
                if (this.config.event_types.length > 0) {
                    this.subscribe(this.config.event_types);
                }
                
                // Heartbeat starten
                this.startHeartbeat();
                
                this.emit('connection.established', {});
            };
            
            this.ws.onmessage = (event) => {
                try {
                    const message: WebSocketMessage = JSON.parse(event.data);
                    this.handleMessage(message);
                } catch (error) {
                    console.error('Invalid WebSocket message:', error);
                }
            };
            
            this.ws.onclose = (event) => {
                console.log('WebSocket disconnected');
                this.isConnected = false;
                this.stopHeartbeat();
                
                if (this.config.auto_reconnect && this.reconnectAttempts < this.maxReconnectAttempts) {
                    setTimeout(() => {
                        this.reconnectAttempts++;
                        console.log(`Reconnection attempt ${this.reconnectAttempts}/${this.maxReconnectAttempts}`);
                        this.connect();
                    }, this.reconnectInterval * this.reconnectAttempts);
                }
                
                this.emit('connection.closed', { code: event.code, reason: event.reason });
            };
            
            this.ws.onerror = (error) => {
                console.error('WebSocket error:', error);
                this.emit('connection.error', { error });
            };
            
        } catch (error) {
            console.error('WebSocket connection failed:', error);
            throw error;
        }
    }
    
    disconnect(): void {
        if (this.ws) {
            this.config.auto_reconnect = false;
            this.stopHeartbeat();
            this.ws.close();
            this.ws = null;
        }
    }
    
    subscribe(eventTypes: string[]): void {
        if (!this.isConnected) {
            console.warn('Cannot subscribe - WebSocket not connected');
            return;
        }
        
        eventTypes.forEach(type => this.subscriptions.add(type));
        
        this.send({
            type: 'subscription',
            event: 'subscribe',
            data: { event_types: eventTypes },
            timestamp: new Date().toISOString()
        });
    }
    
    unsubscribe(eventTypes: string[]): void {
        if (!this.isConnected) {
            console.warn('Cannot unsubscribe - WebSocket not connected');
            return;
        }
        
        eventTypes.forEach(type => this.subscriptions.delete(type));
        
        this.send({
            type: 'subscription',
            event: 'unsubscribe',
            data: { event_types: eventTypes },
            timestamp: new Date().toISOString()
        });
    }
    
    sendUserCommand(command: string, data: any): void {
        if (!this.isConnected) {
            console.warn('Cannot send command - WebSocket not connected');
            return;
        }
        
        this.send({
            type: 'user',
            event: command,
            data: data,
            timestamp: new Date().toISOString(),
            correlation_id: this.generateCorrelationId()
        });
    }
    
    on(eventType: string, handler: Function): void {
        if (!this.eventHandlers.has(eventType)) {
            this.eventHandlers.set(eventType, []);
        }
        this.eventHandlers.get(eventType)!.push(handler);
    }
    
    off(eventType: string, handler?: Function): void {
        if (handler) {
            const handlers = this.eventHandlers.get(eventType);
            if (handlers) {
                const index = handlers.indexOf(handler);
                if (index > -1) {
                    handlers.splice(index, 1);
                }
            }
        } else {
            this.eventHandlers.delete(eventType);
        }
    }
    
    private send(message: Partial<WebSocketMessage>): void {
        if (this.ws && this.ws.readyState === WebSocket.OPEN) {
            this.ws.send(JSON.stringify(message));
        }
    }
    
    private handleMessage(message: WebSocketMessage): void {
        // System-Messages
        if (message.type === 'system') {
            if (message.event === 'connection.established') {
                this.clientId = message.data.client_id;
            }
        }
        
        // Event an Handler weiterleiten
        this.emit(message.event, message);
    }
    
    private emit(eventType: string, data: any): void {
        const handlers = this.eventHandlers.get(eventType);
        if (handlers) {
            handlers.forEach(handler => {
                try {
                    handler(data);
                } catch (error) {
                    console.error(`Error in event handler for ${eventType}:`, error);
                }
            });
        }
    }
    
    private startHeartbeat(): void {
        this.heartbeatTimer = setInterval(() => {
            if (this.isConnected) {
                this.send({
                    type: 'ping',
                    event: 'heartbeat',
                    data: {},
                    timestamp: new Date().toISOString()
                });
            }
        }, this.config.heartbeat_interval);
    }
    
    private stopHeartbeat(): void {
        if (this.heartbeatTimer) {
            clearInterval(this.heartbeatTimer);
            this.heartbeatTimer = null;
        }
    }
    
    private generateCorrelationId(): string {
        return Math.random().toString(36).substring(2, 15) + 
               Math.random().toString(36).substring(2, 15);
    }
    
    // Utility-Methods
    getConnectionStatus(): string {
        if (!this.ws) return 'disconnected';
        switch (this.ws.readyState) {
            case WebSocket.CONNECTING: return 'connecting';
            case WebSocket.OPEN: return 'connected';
            case WebSocket.CLOSING: return 'closing';
            case WebSocket.CLOSED: return 'closed';
            default: return 'unknown';
        }
    }
    
    getSubscriptions(): string[] {
        return Array.from(this.subscriptions);
    }
    
    getClientId(): string | null {
        return this.clientId;
    }
}

// Frontend-Integration
class PortfolioWebSocketClient {
    private wsClient: WebSocketEventClient;
    
    constructor() {
        this.wsClient = new WebSocketEventClient('wss://localhost/ws', {
            event_types: [
                'portfolio.update',
                'portfolio.position_changed',
                'portfolio.value_changed',
                'trading.order_filled',
                'trading.order_cancelled',
                'market.price_update'
            ],
            auto_reconnect: true,
            heartbeat_interval: 30000
        });
        
        this.setupEventHandlers();
    }
    
    async connect(): Promise<void> {
        await this.wsClient.connect();
    }
    
    private setupEventHandlers(): void {
        // Portfolio-Updates
        this.wsClient.on('portfolio.update', (message: WebSocketMessage) => {
            this.updatePortfolioDisplay(message.data);
        });
        
        this.wsClient.on('portfolio.value_changed', (message: WebSocketMessage) => {
            this.updatePortfolioValue(message.data);
        });
        
        // Trading-Updates
        this.wsClient.on('trading.order_filled', (message: WebSocketMessage) => {
            this.showOrderNotification('Order erfolgreich ausgeführt', message.data);
            this.refreshOrderHistory();
        });
        
        // Market-Data-Updates
        this.wsClient.on('market.price_update', (message: WebSocketMessage) => {
            this.updatePriceDisplay(message.data);
        });
        
        // Connection-Events
        this.wsClient.on('connection.established', () => {
            this.showConnectionStatus('Verbunden', 'success');
        });
        
        this.wsClient.on('connection.closed', () => {
            this.showConnectionStatus('Verbindung getrennt', 'warning');
        });
    }
    
    // User-Actions
    placeOrder(orderData: any): void {
        this.wsClient.sendUserCommand('place_order', orderData);
    }
    
    cancelOrder(orderId: string): void {
        this.wsClient.sendUserCommand('cancel_order', { order_id: orderId });
    }
    
    requestPortfolioUpdate(): void {
        this.wsClient.sendUserCommand('refresh_portfolio', {});
    }
    
    // UI-Update-Methods
    private updatePortfolioDisplay(data: any): void {
        // Portfolio-UI aktualisieren
        console.log('Portfolio update:', data);
        
        // Implementierung der UI-Updates
        const portfolioElement = document.getElementById('portfolio-value');
        if (portfolioElement && data.total_value) {
            portfolioElement.textContent = `€${data.total_value.toLocaleString('de-DE', {
                minimumFractionDigits: 2,
                maximumFractionDigits: 2
            })}`;
        }
    }
    
    private updatePortfolioValue(data: any): void {
        // Portfolio-Wert-Animation
        const change = data.change || 0;
        const changePercent = data.change_percent || 0;
        
        this.animateValueChange('portfolio-change', change, changePercent);
    }
    
    private updatePriceDisplay(data: any): void {
        // Kurs-Updates in Realtime
        const { symbol, price, change, change_percent } = data;
        
        const priceElement = document.querySelector(`[data-symbol="${symbol}"] .price`);
        if (priceElement) {
            priceElement.textContent = `€${price.toFixed(2)}`;
            
            // Farb-Animation für Änderungen
            const changeClass = change >= 0 ? 'price-up' : 'price-down';
            priceElement.classList.add(changeClass);
            setTimeout(() => priceElement.classList.remove(changeClass), 1000);
        }
    }
    
    private showOrderNotification(message: string, orderData: any): void {
        // Toast-Notification für Orders
        const notification = document.createElement('div');
        notification.className = 'notification success';
        notification.innerHTML = `
            <div class="notification-content">
                <strong>${message}</strong>
                <br>
                ${orderData.symbol} - ${orderData.quantity} Stück zu €${orderData.price}
            </div>
        `;
        
        document.body.appendChild(notification);
        setTimeout(() => notification.remove(), 5000);
    }
    
    private showConnectionStatus(message: string, type: string): void {
        const statusElement = document.getElementById('connection-status');
        if (statusElement) {
            statusElement.textContent = message;
            statusElement.className = `status ${type}`;
        }
    }
    
    private animateValueChange(elementId: string, change: number, changePercent: number): void {
        const element = document.getElementById(elementId);
        if (element) {
            const changeClass = change >= 0 ? 'positive' : 'negative';
            element.textContent = `${change >= 0 ? '+' : ''}€${change.toFixed(2)} (${changePercent.toFixed(2)}%)`;
            element.className = `change ${changeClass}`;
        }
    }
    
    private refreshOrderHistory(): void {
        // Order-History neu laden
        fetch('/api/trading/orders/history')
            .then(response => response.json())
            .then(data => {
                // UI-Update für Order-History
                console.log('Order history updated:', data);
            });
    }
}

// Global-Instance
const portfolioWS = new PortfolioWebSocketClient();

// Auto-Connect bei Page-Load
document.addEventListener('DOMContentLoaded', () => {
    portfolioWS.connect().catch(console.error);
});
```

---

## ⚡ **2. EVENT-SCHEMA-DEFINITIONEN**

### 2.1 **Portfolio-Events**
```python
# shared/events/portfolio_events.py
from dataclasses import dataclass
from typing import List, Optional, Dict, Any
from decimal import Decimal
from datetime import datetime

@dataclass
class PortfolioUpdateEvent:
    """Portfolio-Update-Event"""
    event_type: str = "portfolio.update"
    portfolio_id: str = ""
    total_value: Decimal = Decimal('0')
    total_change: Decimal = Decimal('0')
    total_change_percent: Decimal = Decimal('0')
    positions_count: int = 0
    last_updated: str = ""
    positions: List[Dict[str, Any]] = None
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "portfolio_id": self.portfolio_id,
            "total_value": float(self.total_value),
            "total_change": float(self.total_change),
            "total_change_percent": float(self.total_change_percent),
            "positions_count": self.positions_count,
            "last_updated": self.last_updated,
            "positions": self.positions or []
        }

@dataclass
class PositionChangedEvent:
    """Position-Änderungs-Event"""
    event_type: str = "portfolio.position_changed"
    portfolio_id: str = ""
    symbol: str = ""
    isin: str = ""
    action: str = ""  # "buy", "sell", "update"
    quantity: Decimal = Decimal('0')
    price: Decimal = Decimal('0')
    value: Decimal = Decimal('0')
    change: Decimal = Decimal('0')
    change_percent: Decimal = Decimal('0')
    timestamp: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "portfolio_id": self.portfolio_id,
            "symbol": self.symbol,
            "isin": self.isin,
            "action": self.action,
            "quantity": float(self.quantity),
            "price": float(self.price),
            "value": float(self.value),
            "change": float(self.change),
            "change_percent": float(self.change_percent),
            "timestamp": self.timestamp
        }

@dataclass
class PortfolioValueChangedEvent:
    """Portfolio-Wert-Änderungs-Event"""
    event_type: str = "portfolio.value_changed"
    portfolio_id: str = ""
    previous_value: Decimal = Decimal('0')
    current_value: Decimal = Decimal('0')
    change: Decimal = Decimal('0')
    change_percent: Decimal = Decimal('0')
    trigger_reason: str = ""  # "price_update", "position_change", "manual_refresh"
    timestamp: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "portfolio_id": self.portfolio_id,
            "previous_value": float(self.previous_value),
            "current_value": float(self.current_value),
            "change": float(self.change),
            "change_percent": float(self.change_percent),
            "trigger_reason": self.trigger_reason,
            "timestamp": self.timestamp
        }
```

### 2.2 **Trading-Events**
```python
# shared/events/trading_events.py
from dataclasses import dataclass
from typing import Optional, Dict, Any
from decimal import Decimal
from datetime import datetime

@dataclass
class OrderCreatedEvent:
    """Order-Erstellungs-Event"""
    event_type: str = "trading.order_created"
    order_id: str = ""
    symbol: str = ""
    order_type: str = ""  # "market", "limit", "stop"
    side: str = ""  # "buy", "sell"
    quantity: Decimal = Decimal('0')
    price: Optional[Decimal] = None
    stop_price: Optional[Decimal] = None
    status: str = "pending"
    created_at: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "symbol": self.symbol,
            "order_type": self.order_type,
            "side": self.side,
            "quantity": float(self.quantity),
            "price": float(self.price) if self.price else None,
            "stop_price": float(self.stop_price) if self.stop_price else None,
            "status": self.status,
            "created_at": self.created_at
        }

@dataclass
class OrderFilledEvent:
    """Order-Ausführungs-Event"""
    event_type: str = "trading.order_filled"
    order_id: str = ""
    symbol: str = ""
    side: str = ""
    quantity: Decimal = Decimal('0')
    filled_quantity: Decimal = Decimal('0')
    fill_price: Decimal = Decimal('0')
    total_value: Decimal = Decimal('0')
    fees: Decimal = Decimal('0')
    status: str = "filled"  # "filled", "partially_filled"
    filled_at: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "symbol": self.symbol,
            "side": self.side,
            "quantity": float(self.quantity),
            "filled_quantity": float(self.filled_quantity),
            "fill_price": float(self.fill_price),
            "total_value": float(self.total_value),
            "fees": float(self.fees),
            "status": self.status,
            "filled_at": self.filled_at
        }

@dataclass
class OrderCancelledEvent:
    """Order-Stornieruns-Event"""
    event_type: str = "trading.order_cancelled"
    order_id: str = ""
    symbol: str = ""
    cancel_reason: str = ""
    remaining_quantity: Decimal = Decimal('0')
    cancelled_at: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "symbol": self.symbol,
            "cancel_reason": self.cancel_reason,
            "remaining_quantity": float(self.remaining_quantity),
            "cancelled_at": self.cancelled_at
        }

@dataclass
class OrderFailedEvent:
    """Order-Fehler-Event"""
    event_type: str = "trading.order_failed"
    order_id: str = ""
    symbol: str = ""
    error_code: str = ""
    error_message: str = ""
    failed_at: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "order_id": self.order_id,
            "symbol": self.symbol,
            "error_code": self.error_code,
            "error_message": self.error_message,
            "failed_at": self.failed_at
        }
```

### 2.3 **Market-Data-Events**
```python
# shared/events/market_events.py
from dataclasses import dataclass
from typing import Dict, Any, List
from decimal import Decimal

@dataclass
class PriceUpdateEvent:
    """Kurs-Update-Event"""
    event_type: str = "market.price_update"
    symbol: str = ""
    isin: str = ""
    price: Decimal = Decimal('0')
    previous_price: Decimal = Decimal('0')
    change: Decimal = Decimal('0')
    change_percent: Decimal = Decimal('0')
    volume: int = 0
    timestamp: str = ""
    source: str = ""  # "bitpanda", "alpha_vantage"
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "symbol": self.symbol,
            "isin": self.isin,
            "price": float(self.price),
            "previous_price": float(self.previous_price),
            "change": float(self.change),
            "change_percent": float(self.change_percent),
            "volume": self.volume,
            "timestamp": self.timestamp,
            "source": self.source
        }

@dataclass
class MarketAlertEvent:
    """Market-Alert-Event"""
    event_type: str = "market.alert"
    alert_type: str = ""  # "price_threshold", "volume_spike", "volatility"
    symbol: str = ""
    message: str = ""
    severity: str = ""  # "info", "warning", "critical"
    trigger_value: Decimal = Decimal('0')
    current_value: Decimal = Decimal('0')
    threshold: Decimal = Decimal('0')
    timestamp: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "alert_type": self.alert_type,
            "symbol": self.symbol,
            "message": self.message,
            "severity": self.severity,
            "trigger_value": float(self.trigger_value),
            "current_value": float(self.current_value),
            "threshold": float(self.threshold),
            "timestamp": self.timestamp
        }

@dataclass
class AnalysisCompleteEvent:
    """Analyse-Abschluss-Event"""
    event_type: str = "analysis.complete"
    analysis_id: str = ""
    analysis_type: str = ""  # "technical", "fundamental", "sentiment"
    symbol: str = ""
    result: Dict[str, Any] = None
    confidence_score: Decimal = Decimal('0')
    recommendation: str = ""  # "buy", "sell", "hold"
    completed_at: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "analysis_id": self.analysis_id,
            "analysis_type": self.analysis_type,
            "symbol": self.symbol,
            "result": self.result or {},
            "confidence_score": float(self.confidence_score),
            "recommendation": self.recommendation,
            "completed_at": self.completed_at
        }
```

### 2.4 **System-Events**
```python
# shared/events/system_events.py
from dataclasses import dataclass
from typing import Dict, Any, Optional

@dataclass
class ServiceStatusEvent:
    """Service-Status-Event"""
    event_type: str = "system.service_status"
    service_name: str = ""
    status: str = ""  # "online", "offline", "degraded"
    health_score: int = 100
    response_time_ms: float = 0.0
    error_rate: float = 0.0
    timestamp: str = ""
    additional_info: Optional[Dict[str, Any]] = None
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "service_name": self.service_name,
            "status": self.status,
            "health_score": self.health_score,
            "response_time_ms": self.response_time_ms,
            "error_rate": self.error_rate,
            "timestamp": self.timestamp,
            "additional_info": self.additional_info or {}
        }

@dataclass
class PerformanceAlertEvent:
    """Performance-Alert-Event"""
    event_type: str = "system.performance_alert"
    alert_type: str = ""  # "high_latency", "memory_usage", "cpu_usage"
    service_name: str = ""
    metric_name: str = ""
    current_value: float = 0.0
    threshold: float = 0.0
    severity: str = ""  # "warning", "critical"
    timestamp: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "alert_type": self.alert_type,
            "service_name": self.service_name,
            "metric_name": self.metric_name,
            "current_value": self.current_value,
            "threshold": self.threshold,
            "severity": self.severity,
            "timestamp": self.timestamp
        }

@dataclass
class ErrorOccurredEvent:
    """Error-Event"""
    event_type: str = "system.error"
    error_id: str = ""
    service_name: str = ""
    error_type: str = ""
    error_message: str = ""
    stack_trace: Optional[str] = None
    severity: str = ""  # "warning", "error", "critical"
    user_affected: bool = False
    timestamp: str = ""
    
    def to_websocket_data(self) -> Dict[str, Any]:
        return {
            "error_id": self.error_id,
            "service_name": self.service_name,
            "error_type": self.error_type,
            "error_message": self.error_message,
            "severity": self.severity,
            "user_affected": self.user_affected,
            "timestamp": self.timestamp
        }
```

---

## 🔄 **3. EVENT-DISPATCHER-INTEGRATION**

### 3.1 **Service-seitige Event-Emission**
```python
# shared/events/websocket_dispatcher.py
import asyncio
import json
import redis.asyncio as redis
from typing import Any, Dict
from datetime import datetime
import logging

class WebSocketEventDispatcher:
    """Event-Dispatcher für WebSocket-Events"""
    
    def __init__(self):
        self.redis_client = None
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """Redis-Connection initialisieren"""
        self.redis_client = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True
        )
    
    async def emit_portfolio_update(self, event: 'PortfolioUpdateEvent'):
        """Portfolio-Update-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def emit_position_changed(self, event: 'PositionChangedEvent'):
        """Position-Changed-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def emit_order_filled(self, event: 'OrderFilledEvent'):
        """Order-Filled-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def emit_price_update(self, event: 'PriceUpdateEvent'):
        """Price-Update-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def emit_market_alert(self, event: 'MarketAlertEvent'):
        """Market-Alert-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def emit_system_error(self, event: 'ErrorOccurredEvent'):
        """System-Error-Event senden"""
        await self._emit_event(event.event_type, event.to_websocket_data())
    
    async def _emit_event(self, event_type: str, event_data: Dict[str, Any]):
        """Event an WebSocket-Gateway senden"""
        if not self.redis_client:
            await self.initialize()
        
        websocket_message = {
            "type": self._get_event_category(event_type),
            "event": event_type,
            "data": event_data,
            "timestamp": datetime.utcnow().isoformat(),
            "source_service": self._get_service_name()
        }
        
        try:
            await self.redis_client.publish(
                "aktienanalyse:events:websocket",
                json.dumps(websocket_message)
            )
            
            self.logger.debug(f"WebSocket event emitted: {event_type}")
            
        except Exception as e:
            self.logger.error(f"Failed to emit WebSocket event {event_type}: {str(e)}")
    
    def _get_event_category(self, event_type: str) -> str:
        """Event-Category aus Event-Type ableiten"""
        if event_type.startswith("portfolio."):
            return "portfolio"
        elif event_type.startswith("trading."):
            return "trading"
        elif event_type.startswith("market."):
            return "market"
        elif event_type.startswith("analysis."):
            return "analysis"
        elif event_type.startswith("system."):
            return "system"
        else:
            return "unknown"
    
    def _get_service_name(self) -> str:
        """Service-Name ermitteln"""
        import os
        return os.environ.get("SERVICE_NAME", "unknown-service")

# Global-Instance für Services
websocket_dispatcher = WebSocketEventDispatcher()

# Usage-Example in Services
async def on_portfolio_value_changed(portfolio_id: str, new_value: Decimal, previous_value: Decimal):
    """Beispiel-Usage für Portfolio-Value-Changed"""
    from shared.events.portfolio_events import PortfolioValueChangedEvent
    
    change = new_value - previous_value
    change_percent = (change / previous_value * 100) if previous_value > 0 else Decimal('0')
    
    event = PortfolioValueChangedEvent(
        portfolio_id=portfolio_id,
        previous_value=previous_value,
        current_value=new_value,
        change=change,
        change_percent=change_percent,
        trigger_reason="price_update",
        timestamp=datetime.utcnow().isoformat()
    )
    
    await websocket_dispatcher.emit_portfolio_update(event)

async def on_order_execution(order_data: Dict[str, Any]):
    """Beispiel-Usage für Order-Execution"""
    from shared.events.trading_events import OrderFilledEvent
    
    event = OrderFilledEvent(
        order_id=order_data["order_id"],
        symbol=order_data["symbol"],
        side=order_data["side"],
        quantity=Decimal(str(order_data["quantity"])),
        filled_quantity=Decimal(str(order_data["filled_quantity"])),
        fill_price=Decimal(str(order_data["fill_price"])),
        total_value=Decimal(str(order_data["total_value"])),
        fees=Decimal(str(order_data.get("fees", 0))),
        status=order_data["status"],
        filled_at=datetime.utcnow().isoformat()
    )
    
    await websocket_dispatcher.emit_order_filled(event)
```

### 3.2 **User-Command-Handler**
```python
# shared/events/user_command_handler.py
import asyncio
import json
import redis.asyncio as redis
from typing import Dict, Any, Callable
import logging

class UserCommandHandler:
    """Handler für User-Commands vom WebSocket-Frontend"""
    
    def __init__(self):
        self.redis_client = None
        self.command_handlers: Dict[str, Callable] = {}
        self.logger = logging.getLogger(__name__)
    
    async def initialize(self):
        """Redis-Connection und Command-Handlers initialisieren"""
        self.redis_client = redis.Redis(
            host='localhost',
            port=6379,
            decode_responses=True
        )
        
        # Command-Handlers registrieren
        self.register_command_handlers()
        
        # User-Command-Subscriber starten
        asyncio.create_task(self.user_command_subscriber())
    
    def register_command_handlers(self):
        """Command-Handlers registrieren"""
        self.command_handlers.update({
            # Portfolio-Commands
            "refresh_portfolio": self.handle_refresh_portfolio,
            "update_position": self.handle_update_position,
            
            # Trading-Commands
            "place_order": self.handle_place_order,
            "cancel_order": self.handle_cancel_order,
            "modify_order": self.handle_modify_order,
            
            # Analysis-Commands
            "start_analysis": self.handle_start_analysis,
            "get_recommendations": self.handle_get_recommendations,
            
            # System-Commands
            "get_system_status": self.handle_get_system_status,
            "subscribe_alerts": self.handle_subscribe_alerts
        })
    
    async def user_command_subscriber(self):
        """Redis-Subscriber für User-Commands"""
        try:
            pubsub = self.redis_client.pubsub()
            await pubsub.subscribe("aktienanalyse:events:user_commands")
            
            async for message in pubsub.listen():
                if message['type'] == 'message':
                    try:
                        command_data = json.loads(message['data'])
                        await self.handle_user_command(command_data)
                        
                    except Exception as e:
                        self.logger.error(f"Error processing user command: {str(e)}")
                        
        except Exception as e:
            self.logger.error(f"User command subscriber error: {str(e)}")
    
    async def handle_user_command(self, command_data: Dict[str, Any]):
        """User-Command verarbeiten"""
        event = command_data.get('event')
        data = command_data.get('data', {})
        client_id = command_data.get('client_id')
        correlation_id = command_data.get('correlation_id')
        
        if event in self.command_handlers:
            try:
                result = await self.command_handlers[event](data, client_id)
                
                # Erfolgreiche Response senden
                await self.send_command_response(
                    client_id, event, "success", result, correlation_id
                )
                
            except Exception as e:
                self.logger.error(f"Error handling command {event}: {str(e)}")
                
                # Error-Response senden
                await self.send_command_response(
                    client_id, event, "error", 
                    {"error": str(e)}, correlation_id
                )
        else:
            self.logger.warning(f"Unknown user command: {event}")
            
            await self.send_command_response(
                client_id, event, "error",
                {"error": f"Unknown command: {event}"}, correlation_id
            )
    
    async def send_command_response(self, client_id: str, command: str, 
                                  status: str, data: Any, correlation_id: str = None):
        """Command-Response an WebSocket-Client senden"""
        response_message = {
            "type": "command_response",
            "event": f"{command}.response",
            "data": {
                "status": status,
                "command": command,
                "result": data
            },
            "timestamp": datetime.utcnow().isoformat(),
            "correlation_id": correlation_id,
            "target_client": client_id
        }
        
        await self.redis_client.publish(
            "aktienanalyse:events:websocket",
            json.dumps(response_message)
        )
    
    # Command-Handler-Implementations
    async def handle_refresh_portfolio(self, data: Dict[str, Any], client_id: str) -> Dict[str, Any]:
        """Portfolio-Refresh-Command"""
        # Portfolio-Service aufrufen
        from services.intelligent_core_service.src.portfolio_manager import PortfolioManager
        
        portfolio_manager = PortfolioManager()
        portfolio_data = await portfolio_manager.get_current_portfolio()
        
        # Portfolio-Update-Event senden
        from shared.events.portfolio_events import PortfolioUpdateEvent
        
        event = PortfolioUpdateEvent(
            portfolio_id=portfolio_data["portfolio_id"],
            total_value=Decimal(str(portfolio_data["total_value"])),
            total_change=Decimal(str(portfolio_data["total_change"])),
            total_change_percent=Decimal(str(portfolio_data["total_change_percent"])),
            positions_count=len(portfolio_data["positions"]),
            last_updated=datetime.utcnow().isoformat(),
            positions=portfolio_data["positions"]
        )
        
        await websocket_dispatcher.emit_portfolio_update(event)
        
        return {"message": "Portfolio refreshed successfully"}
    
    async def handle_place_order(self, data: Dict[str, Any], client_id: str) -> Dict[str, Any]:
        """Order-Placement-Command"""
        # Trading-Service aufrufen
        from services.broker_gateway_service.src.trading_manager import TradingManager
        
        trading_manager = TradingManager()
        order_result = await trading_manager.place_order(
            symbol=data["symbol"],
            side=data["side"],
            quantity=Decimal(str(data["quantity"])),
            order_type=data.get("order_type", "market"),
            price=Decimal(str(data["price"])) if data.get("price") else None
        )
        
        return {
            "order_id": order_result["order_id"],
            "status": order_result["status"],
            "message": "Order placed successfully"
        }
    
    async def handle_cancel_order(self, data: Dict[str, Any], client_id: str) -> Dict[str, Any]:
        """Order-Cancellation-Command"""
        from services.broker_gateway_service.src.trading_manager import TradingManager
        
        trading_manager = TradingManager()
        cancel_result = await trading_manager.cancel_order(data["order_id"])
        
        return {
            "order_id": data["order_id"],
            "status": cancel_result["status"],
            "message": "Order cancelled successfully"
        }
    
    async def handle_start_analysis(self, data: Dict[str, Any], client_id: str) -> Dict[str, Any]:
        """Analysis-Start-Command"""
        from services.intelligent_core_service.src.analysis_engine import AnalysisEngine
        
        analysis_engine = AnalysisEngine()
        analysis_id = await analysis_engine.start_analysis(
            symbol=data["symbol"],
            analysis_type=data.get("analysis_type", "technical"),
            parameters=data.get("parameters", {})
        )
        
        return {
            "analysis_id": analysis_id,
            "message": "Analysis started successfully"
        }
    
    async def handle_get_system_status(self, data: Dict[str, Any], client_id: str) -> Dict[str, Any]:
        """System-Status-Command"""
        # System-Status sammeln
        system_status = {
            "services": {
                "core": "online",
                "broker": "online", 
                "event_bus": "online",
                "monitoring": "online"
            },
            "overall_health": 95,
            "timestamp": datetime.utcnow().isoformat()
        }
        
        return system_status

# Global-Instance
user_command_handler = UserCommandHandler()
```

---

## ✅ **4. IMPLEMENTIERUNGS-CHECKLIST**

### **Phase 1: WebSocket-Gateway-Setup (2 Tage)**
- [ ] WebSocket-Gateway-Service mit FastAPI implementieren
- [ ] Connection-Manager für Client-Verbindungen entwickeln
- [ ] Event-Subscription-System implementieren
- [ ] Redis-Integration für Event-Bus einrichten

### **Phase 2: Event-Schema und -Dispatcher (2 Tage)**
- [ ] Event-Schema-Definitionen für alle Event-Types erstellen
- [ ] WebSocket-Event-Dispatcher für Service-Integration implementieren
- [ ] Event-zu-WebSocket-Message-Transformation entwickeln
- [ ] Event-Validation und -Serialization implementieren

### **Phase 3: Frontend-WebSocket-Client (2 Tage)**
- [ ] TypeScript-WebSocket-Client mit Auto-Reconnection entwickeln
- [ ] Event-Handler-System für UI-Updates implementieren
- [ ] Subscription-Management und User-Commands integrieren
- [ ] Portfolio-UI-Integration mit Real-time-Updates

### **Phase 4: User-Command-Handler (1 Tag)**
- [ ] User-Command-Handler für bidirektionale Kommunikation implementieren
- [ ] Command-Response-System einrichten
- [ ] Service-Integration für Commands (Portfolio, Trading, Analysis)
- [ ] Error-Handling und Validation für User-Commands

### **Phase 5: Monitoring und Testing (1 Tag)**
- [ ] WebSocket-Connection-Monitoring implementieren
- [ ] Event-Flow-Logging und Debugging-Tools
- [ ] Performance-Optimierung für High-Frequency-Events
- [ ] Integration-Tests für End-to-End-Event-Flow

**Gesamtaufwand**: 8 Tage
**Abhängigkeiten**: Event-Bus-Service, Redis, Frontend-Service

Diese Spezifikation ermöglicht **real-time bidirektionale Kommunikation** zwischen Frontend und Backend mit standardisiertem Event-Protocol für das Event-driven Aktienanalyse-Ökosystem.