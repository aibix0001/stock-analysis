# 🏗️ System-Architektur: Aktienanalyse-Verwaltung

## 📊 Schematischer Aufbau der Komponenten

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                           LXC Container: aktienanalyse-lxc-120                   │
│                                    (10.1.1.174)                                  │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────┐                ┌─────────────────────────────────┐ │
│  │   aktienanalyse-        │                │     aktienanalyse-verwaltung    │ │
│  │     auswertung          │                │        (Backend Only)           │ │
│  │   (Bestehend)           │                │                                 │ │
│  └─────────────────────────┘                └─────────────────────────────────┘ │
│             │                                             │                     │
│             │ Cross-System Performance-Sync               │                     │
│             ▼                                             ▼                     │
│  ┌─────────────────────────┐                ┌─────────────────────────────────┐ │
│  │   aktienanalyse.db      │◄──────────────►│         depot.db               │ │
│  │   (Bestehend)           │   JOIN über     │        (20 Tables)             │ │
│  │                         │   Python-APIs  │                                 │ │
│  └─────────────────────────┘                └─────────────────────────────────┘ │
│                                                             │                     │
│                                                             ▼                     │
│                                               ┌─────────────────────────────────┐ │
│                                               │        Northbound API           │ │
│                                               │         (REST/JSON)             │ │
│                                               │     + OpenAPI/Swagger           │ │
│                                               └─────────────────────────────────┘ │
│                                                             │                     │
└─────────────────────────────────────────────────────────────┼─────────────────────┘
                                                              │
                                                              ▼
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          Externe Komponenten                                   │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────┐                ┌─────────────────────────────────┐ │
│  │  aktienanalyse-frontend │                │        Bitpanda Pro            │ │
│  │    (Separates Projekt)  │                │          API                    │ │
│  │                         │                │   REST + WebSocket              │ │
│  │  • Performance-Dashboard│                │                                 │ │
│  │  • Depot-Visualisierung │                │  • Market/Limit Orders          │ │
│  │  • Ranking-Heatmap      │                │  • Real-time Market Data        │ │
│  │  • Watchlist-UI         │                │  • Account Balances             │ │
│  └─────────────────────────┘                └─────────────────────────────────┘ │
│             │                                             ▲                     │
│             │ REST API Calls                              │                     │
│             ▼                                             │                     │
│    (Northbound API)                                       │                     │
│                                                           │                     │
│                                               ┌───────────┴─────────────────────┐ │
│                                               │    Broker-Abstraction Layer    │ │
│                                               │                                 │ │
│                                               │  • Order-Management             │ │
│                                               │  • Trade-Execution              │ │
│                                               │  • Cost-Tracking                │ │
│                                               │  • Error-Handling               │ │
│                                               └─────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 🧩 Detaillierte Komponenten-Struktur

### 🏢 LXC Container: aktienanalyse-lxc-120

#### 1. 📊 aktienanalyse-verwaltung (Modulare Backend-Architektur)
```
aktienanalyse-verwaltung/
├── 📊 core-depot/              # Depot-Management Modul
│   ├── position-manager/       # Position CRUD-Operationen
│   ├── order-manager/          # Order Lifecycle-Management
│   ├── trade-history/          # Trade-Historie und Audit-Trail
│   └── portfolio-calculator/   # Portfolio-Aggregation und Berechnungen
│
├── 🧮 performance-engine/      # Performance-Berechnung Modul
│   ├── tax-calculator/         # Steuer-Engine (KESt, SolZ, KiSt)
│   ├── fee-tracker/           # Gebühren-Tracking und Netto-Berechnung
│   ├── performance-metrics/    # ROI, Sharpe-Ratio, Volatilität
│   └── ranking-engine/        # Multi-Kriterien-Ranking-Algorithmus
│
├── 🗄️ data-layer/             # Database-Abstraction Modul
│   ├── depot-repository/       # depot.db CRUD-Operationen
│   ├── schema-manager/         # Database-Migrations und Schema
│   ├── query-optimizer/        # Performance-optimierte Queries
│   └── backup-manager/         # Backup-Strategien und Recovery
│
├── 🔄 cross-system-sync/       # Integration Modul
│   ├── sync-service/           # Periodischer Sync-Scheduler
│   ├── data-mapper/           # aktienanalyse.db → depot.db Mapping
│   ├── comparison-engine/      # Performance-Vergleichs-Engine
│   └── import-processor/       # Batch-Import Logic (0 Bestand)
│
├── 📡 broker-integration/      # Broker-Abstraction Modul
│   ├── broker-abstraction/     # Generic Broker-Interface
│   ├── bitpanda-adapter/      # Bitpanda-spezifische Implementierung
│   ├── order-executor/        # Order-Ausführung und State-Machine
│   ├── market-data-feed/      # Real-time WebSocket-Handler
│   └── cost-tracker/         # Automatische Gebühren-Integration
│
├── 🌐 northbound-api/         # API-Layer Modul
│   ├── api-gateway/           # Zentraler API-Router
│   ├── depot-endpoints/       # Depot-Verwaltung REST-API
│   ├── performance-api/       # Performance-Metrics API
│   ├── order-api/            # Order-Management API
│   ├── watchlist-api/        # Watchlist-Verwaltung API
│   ├── sync-api/             # Cross-System-Sync API
│   ├── websocket-hub/        # Real-time Updates Hub
│   └── openapi-docs/         # Swagger-Dokumentation
│
├── ⚙️ service-foundation/     # Infrastructure Modul
│   ├── config-manager/        # Zentrale Konfigurationsverwaltung
│   ├── logging-system/        # Strukturierte Logs mit Rotation
│   ├── health-monitor/        # System Health-Checks
│   ├── scheduler/             # Task-Scheduling (Sync, Backup)
│   ├── notification-hub/      # Event-Benachrichtigungen
│   ├── backup-service/        # Automatische Backup-Services
│   └── systemd-integration/   # Service-Management
│
└── 🧪 testing-framework/      # Test-Infrastructure Modul
    ├── unit-tests/            # Modul-spezifische Unit-Tests
    ├── integration-tests/     # Cross-Module Integration-Tests
    ├── mock-broker/          # Bitpanda Pro Mock-Server
    ├── test-data/            # Test-Datensätze und Fixtures
    ├── performance-tests/     # Load/Performance-Tests
    └── e2e-tests/            # End-to-End Test-Suite
```

#### 2. 📈 aktienanalyse-auswertung (Bestehend)
```
aktienanalyse-auswertung/
├── 🗄️ aktienanalyse.db (Bestehend)
├── 📊 Enhanced Integrated Reporter
├── 📧 Mail-System Integration
└── 🔍 Performance-Data für Cross-System-Sync
```

### 🌐 Externe Komponenten

#### 3. 🖥️ aktienanalyse-frontend (Separates Projekt)
```
aktienanalyse-frontend/
├── 📊 Performance-Dashboard
├── 📋 Depot-Übersicht (sortierbar)
├── 🎯 Performance-Ranking-Heatmap
├── 👁️ Watchlist-Management
├── 📈 Charts & Visualisierungen
├── ⚙️ Konfiguration & Settings
└── 🔌 API-Client (REST Integration)
```

#### 4. 💰 Bitpanda Pro API
```
Bitpanda Pro/
├── 📡 REST API (120 Req/Min)
├── 🔄 WebSocket Streams
├── 💹 Trading (Aktien + ETFs + Crypto)
├── 💰 Account Management
└── 📊 Market Data Feed
```

## 🔄 Datenfluss-Architektur

### 📊 Performance-Ranking Flow
```
1. depot.db → Performance-Calculation-Engine
2. aktienanalyse.db → Cross-System-Query
3. Ranking-Comparison → Better-Stocks-Detection
4. Auto-Import → depot.db (0 Bestand)
5. API-Export → aktienanalyse-frontend
```

### 💹 Trading Flow
```
1. Frontend → Northbound API → Order-Request
2. Broker-Abstraction → Bitpanda Pro API
3. Order-Execution → depot.db Update
4. Cost-Tracking → Performance-Recalculation
5. Real-time Updates → WebSocket → Frontend
```

### 🔄 Cross-System-Sync Flow
```
1. Scheduler → aktienanalyse.db Query
2. Performance-Comparison → depot.db Rankings
3. Better-Stocks-Detection → Threshold-Check
4. Auto-Import → Watchlist (0 Bestand)
5. Notification → aktienanalyse-frontend
```

## 📋 API-Interface Schema

### 🌐 Northbound API Endpoints
```
/api/v1/
├── /depot
│   ├── GET /positions (Alle Positionen)
│   ├── GET /portfolio (Portfolio-Übersicht)
│   └── GET /balances (Account-Balances)
│
├── /performance
│   ├── GET /rankings (Performance-Rankings)
│   ├── GET /metrics (Performance-Metriken)
│   └── GET /comparison (Cross-System-Vergleich)
│
├── /orders
│   ├── POST /market (Market Order)
│   ├── POST /limit (Limit Order)
│   ├── GET /history (Order-Historie)
│   └── DELETE /{id} (Order-Cancellation)
│
├── /watchlist
│   ├── GET / (Watchlist-Positionen)
│   ├── POST / (Position hinzufügen)
│   └── GET /suggestions (Auto-Import-Vorschläge)
│
└── /sync
    ├── GET /status (Sync-Status)
    ├── POST /trigger (Manueller Sync)
    └── GET /log (Sync-Historie)
```

## 🛡️ Sicherheit & Integration

### 🔒 Single-User-Vereinfachungen
- ✅ Keine Authentifizierung zwischen Komponenten
- ✅ Lokale Config-Dateien
- ✅ Direkte Database-Zugriffe
- ✅ Shared systemd Services

### 🔧 Service-Integration
- **systemd Units**: depot-management.service
- **Shared Resources**: Postfix, Enhanced Reporter
- **Monitoring**: Integriert in bestehende Infrastruktur
- **Backup**: Separate depot.db Sicherung

## 🚀 Modulare Deployment-Architektur

### 📦 Deployment-Optionen

#### Option A: Development Monolith
```
aktienanalyse-verwaltung-dev/
├── main.py                    # Haupt-Entry-Point
├── modules/                   # Alle 8 Module als Python-Packages
│   ├── core_depot/
│   ├── performance_engine/
│   ├── data_layer/
│   ├── cross_system_sync/
│   ├── broker_integration/
│   ├── northbound_api/
│   ├── service_foundation/
│   └── testing_framework/
└── config/                    # Shared Configuration
```

#### Option B: Production Microservices
```
systemd-services/
├── depot-core.service         # core-depot + data-layer
├── performance-engine.service # performance-engine standalone
├── sync-service.service       # cross-system-sync + scheduler
├── broker-gateway.service     # broker-integration + real-time
├── api-gateway.service        # northbound-api + websocket-hub
└── foundation.service         # service-foundation (shared)
```

#### ✅ Option C: Hybrid (Empfohlen)
```
aktienanalyse-verwaltung/
├── core-services/             # Monolith für kritische Module
│   ├── core-depot/           # Position/Order Management
│   ├── performance-engine/   # Performance-Berechnungen
│   └── data-layer/          # Database-Abstraction
├── integration-services/      # Separate Services
│   ├── sync-service/         # cross-system-sync als Service
│   └── broker-gateway/       # broker-integration als Service
├── api-layer/                # API-Gateway als Service
│   └── northbound-api/      # REST + WebSocket API
└── infrastructure/           # Shared Foundation
    └── service-foundation/   # Logging, Config, Health
```

### 🚌 Event-Driven Service-Kommunikation

#### KommunikationsBus-Architektur
```
                    ┌─────────────────────────────────────────┐
                    │        🚌 Aktienanalyse Event Bus      │
                    │       (Redis Pub/Sub + Message Queue)  │
                    └─────────────────┬───────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ northbound-api  │    │  core-services  │    │ broker-gateway  │
    │ Event Handler:  │    │ Event Handler:  │    │ Event Handler:  │
    │ ├── Publisher   │    │ ├── Publisher   │    │ ├── Publisher   │
    │ ├── Subscriber  │    │ ├── Subscriber  │    │ ├── Subscriber  │
    │ └── Processor   │    │ └── Processor   │    │ └── Processor   │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
             │                       │                       │
             ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │  sync-service   │    │    depot.db     │    │  Bitpanda Pro   │
    │ Event Handler   │    │   (shared)      │    │      API        │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Event-Driven Communication Patterns**:
- **Event Publishing**: Module publishen Events zu Topics/Queues
- **Event Subscription**: Module subscriben relevante Event-Patterns
- **Event Processing**: Asynchrone Verarbeitung mit garantierter Delivery
- **Cross-System Events**: Intelligence-Events für Auto-Import und Performance-Sync
- **Real-time Updates**: WebSocket-Events für Live-UI-Updates
- **Event Analytics**: Monitoring und Tracing aller Event-Flows

**Core Event Types**:
- `stock.analysis.*` - Analyse-Ergebnisse von aktienanalyse
- `portfolio.performance.*` - Performance-Updates von auswertung  
- `trading.orders.*` - Order-Events von verwaltung
- `cross.system.*` - Intelligence-Events für Cross-System-Actions
- `system.health.*` - Health-Check und Monitoring-Events

### 🛠️ Flexibilitäts-Vorteile

**Modulare Entwicklung**:
- ✅ Parallele Entwicklung verschiedener Module
- ✅ Isolierte Testing pro Modul
- ✅ Klare Interface-Definitionen zwischen Modulen

**Deployment-Flexibilität**:
- ✅ **Development**: Alles in einem Process für einfaches Debugging
- ✅ **Production**: Performance-kritische Module als Services trennen
- ✅ **Scaling**: Nur benötigte Services horizontal skalieren

**Service-Evolution**:
- ✅ Module können später als Services ausgelagert werden
- ✅ Interface-Kompatibilität bleibt erhalten
- ✅ Schrittweise Migration möglich

Dieses **modulare API-First Backend-System** bietet maximale Flexibilität für das separate aktienanalyse-frontend Projekt!