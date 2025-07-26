# 🏗️ Multi-Projekt Integration: Aktienanalyse-Ökosystem

## 📊 Übergreifende Architektur-Vision

### 🎯 Aktienanalyse-Ökosystem (4 Teilprojekte)

Das **Aktienanalyse-Ökosystem** besteht aus 4 spezialisierten Teilprojekten, die durch **modulare Service-Architekturen** und **Cross-System APIs** miteinander integriert sind:

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                     🏢 LXC Container: aktienanalyse-lxc-120                     │
│                                (10.1.1.174)                                     │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ 📈 aktienanalyse│  │ 🧮 aktienanalyse│  │ 💼 aktienanalyse│  │ 🌐 data-web │ │
│  │                 │  │   -auswertung   │  │   -verwaltung   │  │    -app     │ │
│  │  (Basis-System) │  │   (Analytics)   │  │   (Trading)     │  │ (Frontend)  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│           │                     │                     │                     │     │
│           ▼                     ▼                     ▼                     ▼     │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ aktienanalyse.db│  │ performance.db  │  │    depot.db     │  │   daki.db   │ │
│  │   (Basis-Daten) │  │ (Analytics)     │  │   (Trading)     │  │(Frontend)   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────────┘  └─────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
                                    │
                                    ▼
                ┌─────────────────────────────────────────────────────────┐
                │            🌐 Unified API Gateway                      │
                │              (Port 443/HTTPS)                         │
                └─────────────────────────────────────────────────────────┘
```

## 🏗️ Detaillierte Projekt-Architektur

### 1. 📈 **aktienanalyse** (Basis-System)
**Zweck**: Core-Datensammlung und Scoring-Engine
**Status**: Bestehend, wird modularisiert

#### Modulare Struktur:
```
aktienanalyse/
├── 🔍 data-sources/            # Data Source Module
│   ├── alpha-vantage/          # Alpha Vantage Plugin
│   ├── yahoo-finance/          # Yahoo Finance Plugin
│   ├── fred-economic/          # FRED Economic Data Plugin
│   ├── bitpanda-api/           # Bitpanda Pro Market Data Plugin ⭐ NEU
│   └── plugin-manager/         # Dynamic Plugin Loader
├── 🧮 scoring-engine/          # Technical Analysis Module
│   ├── technical-indicators/   # RSI, MACD, Moving Averages
│   ├── ml-ensemble/           # XGBoost, LSTM, Transformer
│   ├── event-driven/          # Earnings, FDA, M&A Events
│   ├── bitpanda-analytics/    # Bitpanda-spezifische Analyse ⭐ NEU
│   └── ranking-algorithm/     # Multi-factor Scoring
├── 🗄️ data-layer/             # Database Abstraction
│   ├── aktienanalyse-repository/
│   ├── schema-manager/
│   ├── bitpanda-cache/        # Bitpanda Data Cache ⭐ NEU
│   └── migration-engine/
└── 🌐 northbound-api/         # REST API für andere Projekte
    ├── stock-data-api/
    ├── scoring-api/
    ├── bitpanda-proxy/        # Bitpanda API Proxy ⭐ NEU
    └── realtime-updates/
```

### 2. 🧮 **aktienanalyse-auswertung** (Analytics & Reporting)
**Zweck**: Performance-Analyse und professionelle Berichtserstellung
**Status**: Bestehend, wird modularisiert

#### Modulare Struktur:
```
aktienanalyse-auswertung/
├── 📊 performance-analytics/   # Performance Analysis Module
│   ├── portfolio-calculator/   # ROI, Sharpe, Max Drawdown
│   ├── backtesting-engine/    # Historical Validation
│   ├── risk-metrics/          # VaR, Beta, Correlation
│   └── benchmark-comparison/   # S&P 500, DAX Vergleiche
├── 📋 reporting-engine/       # Report Generation Module
│   ├── excel-generator/       # Excel MCP Integration
│   ├── powerpoint-generator/  # PowerPoint MCP Integration
│   ├── access-database/       # Access MCP Integration
│   └── pdf-exporter/         # Client Reports
├── 🔄 cross-system-sync/      # Integration Module
│   ├── aktienanalyse-connector/
│   ├── depot-connector/
│   └── data-synchronizer/
└── 🌐 analytics-api/          # Analytics API Layer
    ├── performance-endpoints/
    ├── report-generation/
    └── cross-system-queries/
```

### 3. 💼 **aktienanalyse-verwaltung** (Trading & Depot Management)
**Zweck**: Depot-Management mit automatischer Orderausführung
**Status**: Neu entwickelt (modulare Architektur bereits definiert)

#### Modulare Struktur:
```
aktienanalyse-verwaltung/
├── 📊 core-depot/              # Depot Management Module
├── 🧮 performance-engine/      # Performance Calculation Module
├── 🗄️ data-layer/             # Database Abstraction Module
├── 🔄 cross-system-sync/       # Integration Module
├── 📡 broker-integration/      # Bitpanda Pro Integration Module
├── 🌐 northbound-api/          # API Layer Module
├── ⚙️ service-foundation/      # Infrastructure Module
└── 🧪 testing-framework/      # Test Infrastructure Module
```

### 4. 🌐 **data-web-app** (Unified Frontend)
**Zweck**: Zentrales Web-Dashboard für alle Teilprojekte
**Status**: Bestehend, wird als einheitliche Frontend-Lösung ausgebaut

#### Modulare Struktur:
```
data-web-app/
├── 🎨 frontend-core/           # React Core Module
│   ├── dashboard-framework/    # Wiederverwendbare Dashboard-Komponenten
│   ├── chart-library/         # Einheitliche Chart-Komponenten
│   ├── auth-module/           # Single-Sign-On für alle Projekte
│   └── navigation-system/     # Multi-Project Navigation
├── 📈 aktienanalyse-ui/       # Aktienanalyse Dashboard Module
│   ├── stock-screening/       # Top-10 Analysis UI
│   ├── scoring-dashboard/     # Technical Analysis Visualisierung
│   └── data-source-config/    # Plugin-Konfiguration UI
├── 🧮 analytics-ui/           # Analytics Dashboard Module
│   ├── performance-dashboard/ # Portfolio Performance UI
│   ├── report-viewer/         # Generated Reports Viewer
│   └── backtesting-ui/        # Backtesting Results UI
├── 💼 depot-ui/               # Depot Management Module
│   ├── portfolio-overview/    # Depot-Übersicht
│   ├── order-management/      # Trading Interface
│   ├── performance-ranking/   # Position Rankings
│   └── watchlist-management/  # Watchlist UI
├── 🔄 integration-layer/      # Cross-System Integration
│   ├── api-orchestrator/      # Multi-API Management
│   ├── real-time-updates/     # WebSocket Hub
│   └── data-synchronizer/     # Cross-Project Data Sync
└── 🌐 unified-api/            # Frontend API Gateway
    ├── authentication/
    ├── project-router/
    └── websocket-hub/
```

## 🔄 Cross-System Service-Architektur

### Event-Driven Service-Integration

#### Event-Flow-Matrix
```
┌─────────────────────┬─────────────────────────┬─────────────────────────┬─────────────────────────┐
│                     │ aktienanalyse           │ -auswertung             │ -verwaltung             │
├─────────────────────┼─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ Event Publishing    │ stock.analysis.*        │ portfolio.performance.* │ trading.orders.*        │
│                     │ market.analysis.*       │ report.generated.*      │ market.data.*           │
├─────────────────────┼─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ Event Subscription  │ trading.order.executed  │ stock.analysis.completed│ portfolio.performance.* │
│                     │ market.data.realtime    │ trading.order.executed  │ stock.analysis.*        │
├─────────────────────┼─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ Cross-System Events │ cross.system.feedback   │ cross.system.correlation│ cross.system.intelligence│
│                     │ prediction.accuracy     │ performance.benchmark   │ auto.import.trigger     │
├─────────────────────┼─────────────────────────┼─────────────────────────┼─────────────────────────┤
│ data-web-app        │ stock.screening.ui      │ report.display.ui       │ portfolio.trading.ui    │
│                     │ config.management.ui    │ analytics.dashboard.ui  │ realtime.updates.ui     │
└─────────────────────┴─────────────────────────┴─────────────────────────┴─────────────────────────┘
```

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
    │ aktienanalyse   │    │ -auswertung     │    │ -verwaltung     │
    │ Event Handler:  │    │ Event Handler:  │    │ Event Handler:  │
    │ ├── Publisher   │    │ ├── Publisher   │    │ ├── Publisher   │
    │ ├── Subscriber  │    │ ├── Subscriber  │    │ ├── Subscriber  │
    │ └── Processor   │    │ └── Processor   │    │ └── Processor   │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
              │                       │                       │
              ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ aktienanalyse.db│    │ performance.db  │    │    depot.db     │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

**Event-Driven Integration Benefits**:
- **Lose Kopplung**: Module kennen sich nur über Event-Schemas
- **Asynchrone Verarbeitung**: Keine blockierenden Inter-Service-Calls
- **Real-time Intelligence**: Sofortige Cross-System-Reaktionen
- **Event Replay**: Neue Module können historische Events nachverarbeiten
- **Fault Tolerance**: Service-Ausfälle blockieren nicht andere Module

### API-Gateway-Architektur

```
                    ┌─────────────────────────────────────────┐
                    │           🌐 Unified API Gateway        │
                    │              (HTTPS:443)                │
                    └─────────────────┬───────────────────────┘
                                      │
              ┌───────────────────────┼───────────────────────┐
              │                       │                       │
              ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ aktienanalyse   │    │ -auswertung     │    │ -verwaltung     │
    │   :8001         │    │   :8002         │    │   :8003         │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
              │                       │                       │
              ▼                       ▼                       ▼
    ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
    │ aktienanalyse.db│    │ performance.db  │    │    depot.db     │
    └─────────────────┘    └─────────────────┘    └─────────────────┘
```

## 🚀 Deployment-Strategien

### Option A: Monolithische Integration
```
aktienanalyse-ecosystem/
├── shared-services/                # Gemeinsame Services
│   ├── unified-api-gateway/
│   ├── authentication-service/
│   ├── notification-hub/
│   └── monitoring-system/
├── aktienanalyse-core/            # Basis-System als Service
├── analytics-engine/              # Auswertung als Service
├── trading-platform/              # Verwaltung als Service
├── frontend-application/          # Web-App als Service
└── shared-infrastructure/         # Gemeinsame Infrastruktur
    ├── database-layer/
    ├── message-queue/
    └── configuration-management/
```

### Option B: Microservice-Architektur
```
Kubernetes/Docker-Compose Services:
├── api-gateway.service             # HTTPS-Proxy und Routing
├── auth-service.service           # Single-Sign-On für alle Projekte
├── stock-analysis.service         # aktienanalyse Kern-Service
├── performance-analytics.service  # auswertung Analytics-Service
├── trading-platform.service      # verwaltung Trading-Service
├── frontend-app.service          # data-web-app React-App
├── database-cluster/             # Multi-Database Setup
│   ├── aktienanalyse-db/
│   ├── performance-db/
│   └── depot-db/
└── infrastructure-services/
    ├── redis-cache/
    ├── message-broker/
    └── monitoring-stack/
```

### ✅ Option C: Hybrid-Modular (Empfohlen)
```
LXC aktienanalyse-lxc-120/
├── core-services/                 # Performance-kritische Services
│   ├── stock-analysis-engine/     # aktienanalyse + data-layer
│   ├── analytics-processor/       # auswertung + reporting
│   └── trading-core/             # verwaltung + broker-integration
├── integration-services/          # Standalone Services
│   ├── unified-api-gateway/      # HTTPS Gateway (Port 443)
│   ├── cross-system-sync/        # Data Synchronization Service
│   └── notification-service/     # Alert & Reporting Service
├── frontend-application/          # React Frontend
│   └── data-web-app/            # Unified Dashboard
└── shared-infrastructure/         # Gemeinsame Basis
    ├── database-management/
    ├── configuration-service/
    ├── monitoring-system/
    └── backup-service/
```

## 🔄 Cross-System Data Flow

### Datenfluss-Orchestrierung
```
1. Stock Analysis Flow:
   aktienanalyse → Stock Scores → (auswertung + verwaltung) → data-web-app

2. Performance Analysis Flow:
   verwaltung → Portfolio Data → auswertung → Performance Reports → data-web-app

3. Trading Execution Flow:
   data-web-app → verwaltung → Bitpanda Pro → Trade Results → auswertung

4. Cross-System Intelligence Flow:
   auswertung → Performance Ranking → verwaltung → Auto-Import (0 Bestand)
```

### Real-time Update-Architektur
```
┌─────────────────┐    WebSocket    ┌─────────────────┐    Server-Sent    ┌─────────────────┐
│ Bitpanda Pro    │◄──────────────►│ verwaltung      │◄─────Events──────►│ data-web-app    │
│     API         │                │ broker-integration│                 │  WebSocket-Hub  │
└─────────────────┘                └─────────────────┘                 └─────────────────┘
                                             │                                     │
                                             ▼                                     ▼
                   ┌─────────────────────────────────────────────────────────────────┐
                   │                Cross-System Event Bus                          │
                   │  - Order Updates  - Portfolio Changes  - Performance Alerts    │
                   └─────────────────────────────────────────────────────────────────┘
                                             │
                   ┌─────────────────────────┼─────────────────────────┐
                   ▼                         ▼                         ▼
         ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
         │ aktienanalyse   │       │ auswertung      │       │ Email/Push      │
         │ scoring-update  │       │ report-trigger  │       │ Notifications   │
         └─────────────────┘       └─────────────────┘       └─────────────────┘
```

## 📋 Migration & Implementation Roadmap

### Phase 1: Foundation (4 Wochen)
1. **Cross-System API Design**: Einheitliche REST-APIs für alle Projekte
2. **Unified Authentication**: Single-Sign-On-System implementieren
3. **Database Migration**: Cross-Database-Query-Layer entwickeln
4. **API Gateway Setup**: HTTPS-Gateway mit Routing zu allen Services

### Phase 2: Modularization (6 Wochen)
1. **aktienanalyse Modularisierung**: Plugin-System und Service-Trennung
2. **auswertung Integration**: MCP-Server-Integration und Reporting-APIs
3. **verwaltung Finalisierung**: Trading-Module und Cross-System-Sync
4. **data-web-app Ausbau**: Multi-Project Dashboard-Framework

### Phase 3: Integration (4 Wochen)
1. **Cross-System Data Sync**: Real-time Synchronisation implementieren
2. **Unified Frontend**: Gemeinsame Navigation und Dashboard-Integration
3. **Performance Optimization**: Service-übergreifende Performance-Optimierung
4. **Testing & Deployment**: End-to-End-Tests und Production-Deployment

### Phase 4: Advanced Features (2 Wochen)
1. **Advanced Analytics**: Cross-System Performance-Intelligence
2. **Automated Trading**: Vollautomatisierte Trading-Strategies
3. **Enhanced Reporting**: Multi-Project Executive Dashboards
4. **Monitoring & Alerts**: System-weites Monitoring und Alerting

## 🛠️ Technische Entscheidungen

### Service-Kommunikation
- **REST APIs**: Für synchrone Service-zu-Service-Kommunikation
- **WebSocket**: Für Real-time Updates (Frontend ↔ Services)
- **Message Queue**: Für asynchrone Cross-System Events (Redis/RabbitMQ)
- **Shared Database Access**: Direct SQL für Performance-kritische Queries

### Deployment-Infrastruktur
- **Single LXC Container**: Alle Services im gleichen Container für einfache Wartung
- **Systemd Services**: Service-Management über systemd
- **NGINX Reverse Proxy**: HTTPS-Terminierung und Service-Routing
- **SQLite Cluster**: Mehrere SQLite-Datenbanken mit Cross-DB-Joins

### Integration-Standards
- **OpenAPI 3.0**: Einheitliche API-Dokumentation für alle Services
- **JSON Schema**: Validierung für Cross-System Data Exchange
- **Semantic Versioning**: API-Versionierung für Backward-Kompatibilität
- **Health Checks**: Einheitliche Health-Check-Endpoints für alle Services

Diese **modulare Multi-Projekt-Architektur** ermöglicht:
- ✅ **Parallele Entwicklung** aller 4 Teilprojekte
- ✅ **Service-übergreifende Integration** mit klaren APIs
- ✅ **Einheitliche Frontend-Erfahrung** über alle Projekte
- ✅ **Flexible Deployment-Optionen** (Monolith ↔ Microservices)
- ✅ **Cross-System Intelligence** durch Daten-Synchronisation