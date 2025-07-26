# 🏗️ Services Architecture

## 🎯 5-Service Event-Driven Architecture

### **Services Overview:**
```
services/
├── intelligent-core-service/    # 🧠 Unified Analysis + Performance + Intelligence
├── broker-gateway-service/      # 📡 Trading Logic (Bitpanda Pro)  
├── event-bus-service/          # 🚌 Redis Cluster Event-Bus
├── frontend-service/           # 🎨 React Event-driven UI
└── monitoring-service/         # 🔍 Analytics & Health Monitoring
```

## 🧠 **intelligent-core-service**

**Unified Service** combining:
- Stock Analysis Engine (aktienanalyse)
- Performance Analytics (auswertung) 
- Cross-System Intelligence (verwaltung)
- Materialized View Generation

**Event Handling:**
- **Publishes**: `analysis.state.changed`, `intelligence.triggered`
- **Subscribes**: `trading.state.changed`, `config.updated`

## 📡 **broker-gateway-service**

**Trading & Market Data Service:**
- Bitpanda Pro API Integration
- Real-time Order Execution
- Market Data WebSocket Streams
- Cost & Fee Tracking

**Event Handling:**
- **Publishes**: `trading.state.changed`, `system.alert.raised`
- **Subscribes**: `intelligence.triggered`, `user.interaction.logged`

## 🚌 **event-bus-service**

**Central Event Infrastructure:**
- Redis Cluster (3-Node)
- Event Routing & Load Balancing
- Dead Letter Queue Management
- Event Analytics & Monitoring

## 🎨 **frontend-service**  

**Event-Driven React UI:**
- Real-time WebSocket Integration
- Unified Dashboard (all 4 projects)
- Event-Stream-based State Management
- Mobile-Responsive Design

**Event Handling:**
- **Publishes**: `user.interaction.logged`  
- **Subscribes**: `*` (all events for UI updates)

## 🔍 **monitoring-service**

**System & Business Intelligence:**
- Health Monitoring (all services)
- Performance Analytics Dashboard  
- Business Intelligence Reporting
- Alert Management & Notification

**Event Handling:**
- **Publishes**: `system.alert.raised`
- **Subscribes**: `*` (all events for analytics)

## 🔧 **Development Guidelines**

### **Service Communication:**
- **Inter-Service**: Only via Event-Bus (no direct API calls)
- **Event-First**: All state changes as events
- **Idempotency**: All event handlers must be idempotent
- **Error Handling**: Failed events go to dead letter queue

### **Service Structure:**
```
{service-name}/
├── src/
│   ├── event_handlers/     # Event processing logic
│   ├── domain/            # Business logic
│   ├── infrastructure/    # External integrations
│   └── api/              # REST API endpoints (if needed)
├── tests/
├── config/
├── Dockerfile
├── requirements.txt
└── README.md
```