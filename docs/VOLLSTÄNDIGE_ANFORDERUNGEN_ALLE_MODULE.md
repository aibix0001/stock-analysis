# 📋 Vollständige Anforderungen - Aktienanalyse-Ökosystem

## 🏢 Gesamtarchitektur: 4 Teilprojekte + 8 Kernmodule

Das **aktienanalyse-ökosystem** besteht aus **4 Teilprojekten**, die jeweils in **modulare Architekturen** unterteilt sind:

```
🏗️ aktienanalyse-ökosystem/
├── 📈 aktienanalyse (Basis-System)           # 4 Module
├── 🧮 aktienanalyse-auswertung (Analytics)   # 4 Module  
├── 💼 aktienanalyse-verwaltung (Trading)     # 8 Module
└── 🌐 data-web-app (Frontend)               # 6 Module
                                             ─────────────
                                             22 Module Total
```

---

## 📈 **PROJEKT 1: aktienanalyse (Basis-System)**

### **Zweck**: Core-Datensammlung, Scoring-Engine und Technical Analysis
### **Status**: Bestehend, wird modularisiert

### Module 1: 🔍 **data-sources Modul**

#### Datenquellen-Integration
- **Alpha Vantage Plugin**: Fundamentaldaten und EOD-Kurse
- **Yahoo Finance Plugin**: Real-time Kurse und Historische Daten  
- **FRED Economic Plugin**: Makroökonomische Indikatoren
- **Bitpanda API Plugin**: Real-time Market Data und Enhanced Analytics ⭐
- **Plugin Manager**: Dynamisches Laden und Konfiguration von Datenquellen

#### Data Collection Pipeline
- Multi-Source Data Aggregation mit Konflikauflösung
- Rate-Limited API-Zugriffe (verschiedene Limits pro Source)
- Data Quality Validation und Plausibilitätsprüfungen
- Fallback-Strategien bei API-Ausfällen
- Historical Data Backfill für neue Instrumente

### Modul 2: 🧮 **scoring-engine Modul**

#### Technical Analysis Engine
- **Technical Indicators**: RSI, MACD, Moving Averages, Bollinger Bands
- **Advanced Indicators**: Stochastic, Williams %R, Commodity Channel Index
- **Candlestick Pattern Recognition**: Doji, Hammer, Engulfing, etc.
- **Support/Resistance Detection**: Automatische Level-Erkennung
- **Trend Analysis**: Multi-Timeframe Trend-Bestimmung

#### Machine Learning Ensemble
- **XGBoost Models**: Gradient Boosting für Price Prediction
- **LSTM Networks**: Long Short-Term Memory für Sequence Prediction
- **Transformer Models**: Attention-Mechanism für Multi-Asset Correlation
- **Random Forest**: Ensemble Learning für Feature Importance
- **Model Validation**: Walk-Forward Analysis und Backtesting

#### Event-Driven Analysis
- **Earnings Events**: Automatische Earnings-Calendar Integration
- **FDA Approvals**: Biotech/Pharma Event-Tracking
- **M&A Events**: Merger & Acquisition Impact Analysis
- **Economic Events**: FOMC, ECB Decisions, Employment Data
- **News Sentiment**: NLP-basierte News-Impact-Bewertung

#### Bitpanda-Enhanced Analytics ⭐
- **Liquidity Score**: Order Book Depth Analysis
- **Volume-Weighted Momentum**: Real-time Momentum mit Volume-Weighting
- **Unusual Volume Detection**: Anomalie-Erkennung im Trading-Volume
- **Cross-Market Correlation**: Bitcoin-Correlation und Market-Beta
- **Real-time Signal Generation**: Live-Trading-Signale

### Modul 3: 🗄️ **data-layer Modul**

#### Database Management
- **aktienanalyse.db**: Hauptdatenbank für Stock-Data und Scores
- **Schema Manager**: Database Migrations und Versionskontrolle
- **Query Optimizer**: Performance-optimierte Abfragen
- **Bitpanda Cache**: High-frequency Data Cache für Real-time Updates ⭐
- **Data Retention**: Automatische Archivierung alter Daten

#### Cross-Database Integration
- **Cross-DB Queries**: Joins zwischen aktienanalyse.db und anderen DBs
- **Data Synchronization**: Real-time Sync mit anderen Teilprojekten
- **Backup Management**: Automatische Backups und Recovery
- **Performance Monitoring**: Query-Performance und Index-Optimierung

### Modul 4: 🌐 **northbound-api Modul**

#### REST API Layer
- **Stock Data API**: CRUD-Operationen für Stock-Daten
- **Scoring API**: Zugriff auf Technical Analysis Scores
- **Real-time Updates**: WebSocket für Live-Score-Updates
- **Bitpanda Proxy**: Rate-Limited Proxy für Bitpanda Market Data ⭐
- **Health Checks**: API Health und Performance Monitoring

#### API Features
- **OpenAPI Documentation**: Swagger-basierte API-Docs
- **Rate Limiting**: API-Usage-Limits für verschiedene Endpunkte
- **Caching Layer**: Redis-basiertes API-Response-Caching
- **Authentication**: Simple API-Key für lokales System
- **Monitoring**: API-Usage-Analytics und Error-Tracking

---

## 🧮 **PROJEKT 2: aktienanalyse-auswertung (Analytics & Reporting)**

### **Zweck**: Performance-Analyse, Backtesting und professionelle Berichtserstellung
### **Status**: Bestehend, wird modularisiert

### Modul 5: 📊 **performance-analytics Modul**

#### Portfolio Performance Analysis
- **ROI Calculation**: Return on Investment mit verschiedenen Methoden
- **Sharpe Ratio**: Risk-adjusted Return Berechnung
- **Maximum Drawdown**: Worst-Case Scenario Analysis
- **Sortino Ratio**: Downside-Risk-adjusted Performance
- **Calmar Ratio**: Return vs. Maximum Drawdown

#### Risk Metrics Engine
- **Value at Risk (VaR)**: 95%/99% VaR Berechnung
- **Beta Calculation**: Market-Beta für einzelne Positionen
- **Correlation Analysis**: Asset-Correlation-Matrix
- **Volatility Analysis**: Historical und Implied Volatility
- **Stress Testing**: Portfolio-Performance in Extremszenarien

#### Backtesting Engine
- **Historical Validation**: Strategy-Backtesting mit Historical Data
- **Walk-Forward Analysis**: Out-of-Sample Validation
- **Monte Carlo Simulation**: Probabilistische Scenario-Analyse
- **Strategy Comparison**: Multiple Strategy Performance-Vergleich
- **Transaction Cost Integration**: Realistic Trading Cost Simulation

#### Benchmark Comparison
- **Index Comparison**: Performance vs. DAX, S&P 500, MSCI World
- **Sector Comparison**: Performance vs. Sektor-ETFs
- **Peer Comparison**: Performance vs. ähnliche Aktien
- **Risk-adjusted Benchmarking**: Alpha und Beta vs. Benchmarks

### Modul 6: 📋 **reporting-engine Modul**

#### Multi-Format Report Generation
- **Excel Generator**: Excel MCP Integration für automatische Reports ⭐
- **PowerPoint Generator**: PowerPoint MCP für Präsentationen ⭐
- **Access Database**: Access MCP für Datenbank-Reports ⭐
- **PDF Exporter**: Client-ready PDF-Reports
- **HTML Reports**: Interactive Web-Reports

#### Report Templates
- **Executive Summary**: High-level Performance Overview
- **Detailed Analytics**: Comprehensive Performance Breakdown
- **Risk Assessment**: Risk-focused Reports für Compliance
- **Tax Reports**: Steuerrelevante Berichte (KESt, SolZ, KiSt)
- **Custom Reports**: Configurable Report Templates

#### Automated Reporting
- **Scheduled Reports**: Daily/Weekly/Monthly automated Generation
- **Email Distribution**: Automatic Report Distribution
- **Report Archiving**: Systematic Report Storage und Versionierung
- **Template Management**: Dynamic Report Template Configuration

### Modul 7: 🔄 **cross-system-sync Modul**

#### Data Integration
- **aktienanalyse Connector**: Live-Sync mit Basis-System
- **depot Connector**: Integration mit Trading-System  
- **Data Synchronizer**: Bi-directional Data Sync
- **Conflict Resolution**: Automatische Data-Conflict-Behandlung
- **Event-driven Updates**: Real-time Cross-System-Updates

#### Performance Correlation
- **Cross-System Analytics**: Performance-Vergleich zwischen allen Systemen
- **Signal Validation**: Validierung von aktienanalyse-Signalen mit Trading-Results
- **Feedback Loop**: Trading-Performance → aktienanalyse Model-Improvement
- **ROI Attribution**: Performance-Attribution nach Signalquellen

### Modul 8: 🌐 **analytics-api Modul**

#### Analytics API Layer
- **Performance Endpoints**: RESTful Performance-Metrics API
- **Report Generation API**: Programmatic Report Creation
- **Cross-system Queries**: Multi-Database Query API
- **Real-time Analytics**: WebSocket für Live-Analytics
- **Export APIs**: Data Export in verschiedenen Formaten

---

## 💼 **PROJEKT 3: aktienanalyse-verwaltung (Trading & Depot Management)**

### **Zweck**: Depot-Management mit automatischer Orderausführung
### **Status**: Neu entwickelt mit modularer Architektur

### Modul 9: 📊 **core-depot Modul**

#### Position Management
- **Position CRUD**: Create, Read, Update, Delete von Positionen
- **Multi-Asset Support**: Aktien, ETFs, Kryptowährungen über Bitpanda
- **Order State Machine**: Kompletter Order-Lifecycle-Management
- **Trade History**: Vollständige Trade-Historie mit Metadaten
- **Portfolio Aggregation**: Real-time Portfolio-Übersicht

#### Account Management
- **Account Balances**: Cash-Positionen und verfügbare Mittel
- **Multi-Currency**: EUR/USD Support für internationale Assets
- **Margin Calculations**: Available Buying Power Berechnung
- **Portfolio Snapshots**: Historische Portfolio-Performance-Tracking

### Modul 10: 🧮 **performance-engine Modul**

#### Enhanced Performance Calculation
- **Brutto-Performance**: Reine Kursdifferenz ohne Nebenkosten
- **Netto-Performance**: Inklusive Steuern und Gebühren
- **Steuerberechnung nach deutschem Steuerrecht (2025)**:
  - **25% Kapitalertragsteuer** + **5,5% Solidaritätszuschlag**
  - **Optional 8%/9% Kirchensteuer** (evangelisch/katholisch)
  - **KEINE Optimierungen**: Keine Abschreibungen oder Loss-Harvesting
  - **Standard-Berechnung**: Einfache lineare Steuerberechnung

#### Performance Ranking & Sorting
- **Zeitraum-normalisierte Performance**: Fair Comparison verschiedener Haltedauern
- **Multi-Kriterien-Ranking**: 40% Netto + 30% Annualisiert + 30% Risk-Adjusted
- **Automatische Depot-Sortierung**: Dynamisches Ranking nach Performance
- **Performance Heatmap**: Visuelle Darstellung von Winners/Losers
- **Rebalancing Suggestions**: Portfolio-Optimierung basierend auf Performance

### Modul 11: 🗄️ **data-layer Modul**

#### Database Architecture
- **depot.db**: Separate Datenbank mit 20 Tabellen für Trading-relevante Daten
- **Core Tables**: Depots, Positions, Orders, Trades, Instruments, Portfolio-Snapshots
- **Performance Tables**: Trade-Costs, Tax-Calculations, Dividends, Currency-Rates
- **Integration Tables**: Broker-Sync-Log, Import-Queue, Cross-System-Rankings

#### Database Operations
- **Repository Pattern**: Einheitliche Database-Abstraction
- **Schema Migrations**: Automated Database Schema Evolution
- **Query Optimization**: Performance-optimierte Queries für Rankings
- **Backup Management**: Automated Backup und Recovery Strategies

### Modul 12: 🔄 **cross-system-sync Modul**

#### Cross-System Intelligence
- **4-System Analysis**: aktienanalyse + auswertung + verwaltung + data-web-app
- **Performance Correlation**: Cross-System Performance-Matrix
- **Auto-Import Logic**: Intelligente Aktien-Übernahme mit Multi-Kriterien-Algorithmus
- **Watchlist Mode**: Import mit 0 Bestand für spätere Kaufentscheidungen

#### Synchronization Engine
- **Scheduled Sync**: Periodische Synchronisation mit anderen Projekten
- **Event-driven Sync**: Real-time Updates über Event-Bus
- **Data Mapping**: aktienanalyse.db ↔ depot.db Mapping
- **Conflict Resolution**: Automatic Handling von Data-Konflikten

### Modul 13: 📡 **broker-integration Modul**

#### Bitpanda Pro Integration
- **REST API Client**: Full Bitpanda Pro API Integration
- **WebSocket Manager**: Real-time Market Data und Account Updates
- **Order Types**: Market, Limit, Stop-Limit, GtC, GtT, IoC, FoK
- **Rate Limiting**: 120 Requests/Minute Compliance
- **Error Handling**: Robust Error Recovery und Retry Logic

#### Event-Driven Architecture
- **Order Events**: trading.order.* Event Publishing für Cross-System Updates
- **Market Data Events**: market.data.* für Live-Updates
- **Cost Events**: trading.cost.* für Performance-Engine Integration
- **Health Events**: system.health.broker.* für Monitoring

#### Broker Abstraction Layer
- **Generic Interface**: Multi-Broker-Support Vorbereitung
- **Plugin Architecture**: Dynamisches Laden verschiedener Broker-Adapter
- **Failover Support**: Automatic Failover zwischen Brokern (zukünftig)

### Modul 14: 🌐 **northbound-api Modul**

#### RESTful API Design
- **Depot Endpoints**: Portfolio-Management API
- **Performance API**: Brutto/Netto-Performance mit Zeitraum-Filterung
- **Order Management API**: Buy/Sell Order-Execution
- **Ranking API**: Position-Rankings mit konfigurierbaren Kriterien
- **Cross-System API**: aktienanalyse-Vergleichs-Endpoints

#### Real-time Integration
- **WebSocket Hub**: Real-time Updates für Portfolio-Änderungen
- **Server-Sent Events**: Live Order-Status Updates
- **API Gateway**: Zentraler API-Router für alle Endpoints
- **OpenAPI Documentation**: Swagger für Frontend-Integration

### Modul 15: ⚙️ **service-foundation Modul**

#### Infrastructure Support
- **Systemd Integration**: Service-Management für dauerhafte Ausführung
- **Configuration Management**: Zentrale YAML/JSON-Konfiguration
- **Logging System**: Strukturierte Logs mit Log-Rotation
- **Health Monitoring**: System Health-Checks und Alerting

#### Task Management
- **Scheduler Service**: Cron-like Task-Scheduling
- **Notification Hub**: Email/Push Notifications für wichtige Events
- **Backup Service**: Automated Database Backups
- **Deployment Support**: LXC Container-Integration

### Modul 16: 🧪 **testing-framework Modul**

#### Test Infrastructure
- **Mock Broker**: Bitpanda Pro Mock-Server für Development
- **Unit Tests**: Comprehensive Test-Suite für alle Module
- **Integration Tests**: Cross-Module und Cross-System Tests
- **Performance Tests**: Load-Testing für API-Endpoints

#### Testing Strategies
- **End-to-End Tests**: Complete Trading-Workflow Tests
- **Test Data Management**: Realistic Test-Datasets
- **Continuous Testing**: Automated Test-Execution
- **Test Reporting**: Comprehensive Test-Results und Coverage

---

## 🌐 **PROJEKT 4: data-web-app (Unified Frontend)**

### **Zweck**: Zentrales Web-Dashboard für alle Teilprojekte
### **Status**: Bestehend, wird als einheitliche Frontend-Lösung ausgebaut

### Modul 17: 🎨 **frontend-core Modul**

#### React Framework
- **Dashboard Framework**: Wiederverwendbare Dashboard-Komponenten
- **Chart Library**: Einheitliche Chart-Komponenten (D3.js, Chart.js)
- **Component Library**: Shared UI-Components für alle Module
- **Theme System**: Einheitliches Design-System und Theming
- **Responsive Design**: Mobile-first Design für alle Devices

#### Authentication & Navigation
- **Single-User Authentication**: Einfache Session-basierte Authentifizierung für einen Benutzer (mdoehler)
- **Project Navigation**: Nahtlose Navigation zwischen allen 4 Projektbereichen
- **Session Management**: Secure Session-Handling für einzelnen Benutzer

### Modul 18: 📈 **aktienanalyse-ui Modul**

#### Stock Analysis Dashboard
- **Stock Screening**: Top-10 Analysis UI mit Filtering
- **Scoring Dashboard**: Technical Analysis Visualisierung
- **Real-time Charts**: Live-Charts mit Bitpanda Real-time Data
- **Signal Display**: Trading-Signale und Recommendations
- **Backtesting UI**: Interactive Backtesting Results

#### Configuration Interface
- **Data Source Config**: Plugin-Konfiguration für verschiedene APIs
- **Model Parameters**: ML-Model Parameter-Tuning UI
- **Alert Configuration**: Custom Alert-Setup für Signals
- **Export Tools**: Data Export in verschiedenen Formaten

### Modul 19: 🧮 **analytics-ui Modul**

#### Performance Dashboard
- **Portfolio Performance**: Interactive Performance-Charts
- **Risk Metrics Display**: VaR, Sharpe Ratio, Beta Visualisierung
- **Benchmark Comparison**: Performance vs. Indices und Peers
- **Attribution Analysis**: Performance-Attribution nach verschiedenen Faktoren

#### Report Management
- **Report Viewer**: Interactive Display für Generated Reports
- **Report Scheduling**: Configuration für Automated Reports
- **Template Management**: Custom Report Template-Editor
- **Export Options**: Multi-Format Report Export

### Modul 20: 💼 **depot-ui Modul**

#### Portfolio Management Interface
- **Portfolio Overview**: Real-time Depot-Übersicht mit Live-Updates
- **Position Details**: Detaillierte Position-Ansicht mit Performance-Metrics
- **Performance Ranking**: Interactive Performance-Ranking mit Sorting
- **Tax Calculator**: Interactive Steuerberechnung (Brutto/Netto)

#### Trading Interface
- **Order Management**: Buy/Sell Order-Interface mit Bitpanda Integration
- **Order History**: Historical Order-Display mit Status-Tracking
- **Watchlist Management**: Interactive Watchlist mit 0-Bestand-Positionen
- **Real-time Updates**: Live Portfolio-Updates über WebSocket

### Modul 21: 🔄 **integration-layer Modul**

#### API Orchestration
- **Multi-API Management**: Koordination aller 4 Backend-APIs
- **Data Synchronization**: Cross-Project Data-Sync im Frontend
- **Real-time Updates**: WebSocket Hub für alle Real-time Data
- **Error Handling**: Unified Error-Handling für alle APIs

#### Cross-System Features
- **Unified Search**: Search across alle 4 Projekte
- **Cross-Project Analytics**: Combined Analytics aus allen Systemen
- **Event Correlation**: Cross-System Event-Display
- **Performance Correlation**: Unified Performance-Dashboard

### Modul 22: 🌐 **unified-api Modul**

#### Frontend API Gateway
- **Request Routing**: Smart Routing zu korrekten Backend-APIs
- **Response Aggregation**: Combining Data aus mehreren Backends
- **Caching Layer**: Frontend-side Caching für Performance
- **WebSocket Management**: Centralized WebSocket-Connection-Management

#### Authentication & Security (Single-User)
- **Simple Session Management**: Session-basierte Authentifizierung für mdoehler
- **Session Persistence**: Persistent Sessions across Browser-Refreshes
- **Internal API Access**: Direct Backend-Access ohne JWT-Komplexität
- **HTTPS-Only**: Port 443 externe Erreichbarkeit, Security Headers (CORS, CSP)

---

## 🔄 **Cross-System Event Architecture**

### Event-Flow zwischen allen 22 Modulen
```
Event-Bus (Redis Pub/Sub):
├── aktienanalyse Events → auswertung + verwaltung + data-web-app
├── auswertung Events → aktienanalyse + verwaltung + data-web-app  
├── verwaltung Events → aktienanalyse + auswertung + data-web-app
└── data-web-app Events → aktienanalyse + auswertung + verwaltung
```

### Unified HTTPS Gateway (Port 443 - Externe Erreichbarkeit)
```
NGINX Reverse Proxy (nur Port 443 von außen):
├── / (Frontend)             → data-web-app:8004 (React SPA)
├── /api/aktienanalyse/*     → aktienanalyse:8001 (intern)
├── /api/auswertung/*        → auswertung:8002 (intern)
├── /api/verwaltung/*        → verwaltung:8003 (intern)
└── /ws/* (WebSocket)        → event-bus:8005 (intern)

# Externe Erreichbarkeit: NUR Port 443 (HTTPS)
# Interne Services: Ports 8001-8005 (nicht extern erreichbar)
```

## 📊 **Deployment-Architektur: Nativer LXC-Container (Keine Docker/Virtualisierung)**

### Single LXC Container - Native systemd Services
```
LXC aktienanalyse-lxc-120 (10.1.1.174):
├── 📈 aktienanalyse-service (systemd, Port 8001)
├── 🧮 auswertung-service (systemd, Port 8002) 
├── 💼 verwaltung-service (systemd, Port 8003)
├── 🌐 frontend-service (systemd, Port 8004)
├── 🔄 event-bus-service (systemd, Port 8005)
├── shared-infrastructure/ (native installiert)
│   ├── redis-server (systemd)
│   ├── nginx (systemd, Port 443 extern)
│   ├── postgresql (systemd)
│   └── zabbix-agent (systemd)
└── 👤 Single-User: mdoehler (Linux User)

# KEINE Container-Virtualisierung (Docker/Podman)
# NUR native LXC mit systemd Services
# Externe Erreichbarkeit: NUR Port 443 (HTTPS)
```

Diese **vollständige Anforderungsübersicht** deckt alle **4 Teilprojekte** mit **22 Modulen** ab und zeigt die komplette Integration des aktienanalyse-ökosystems.