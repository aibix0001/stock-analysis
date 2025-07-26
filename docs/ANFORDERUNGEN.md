# 📋 Anforderungen - Aktienanalyse-Verwaltung

**Datum**: 24.07.2025  
**Projekt**: aktienanalyse-verwaltung  
**Status**: 📝 Anforderungsaufnahme

---

## 🎯 Projektübersicht

Das Aktienanalyse-Verwaltungssystem ist **Teil eines integrierten 4-Projekt-Ökosystems** für umfassende Aktienanalyse und Portfolio-Management.

### 🏗️ Ökosystem-Integration

**aktienanalyse-verwaltung** ist das **Trading & Depot-Management Modul** im **Aktienanalyse-Ökosystem**:

```
Aktienanalyse-Ökosystem (4 Teilprojekte):
├── 📈 aktienanalyse (Basis-System)        → Stock Analysis & Scoring
├── 🧮 aktienanalyse-auswertung (Analytics) → Performance Analysis & Reporting  
├── 💼 aktienanalyse-verwaltung (Trading)   → **Depot Management & Trading** ⭐
└── 🌐 data-web-app (Frontend)             → Unified Web Dashboard
```

**Cross-System Integration**:
- **Input**: Stock-Scores von `aktienanalyse`, Performance-Daten von `auswertung`
- **Output**: Portfolio-Daten an `auswertung`, Trading-UI an `data-web-app`
- **Intelligence**: Auto-Import besserer Stocks basierend auf Cross-System Performance-Vergleich

**🔒 Scope**: Privates Ökosystem für Einzelbenutzer - keine Multi-User-Funktionalität erforderlich.

---

## 📊 Hauptanforderungen

### 1. 💼 Lokale Depot-Verwaltung

**Anforderung**: Ein lokales Aktien-Depot soll vollständig verwaltet werden können

**Details**:
- Lokale Speicherung aller Depot-Positionen
- Verwaltung von Aktienbeständen (Anzahl, Kaufkurs, Kaufdatum)
- Portfolio-Übersicht mit aktuellen Kursen
- **Enhanced Performance-Tracking**: Brutto- und Netto-Gewinn/Verlust-Berechnung

**✅ ERWEITERTE PERFORMANCE-BERECHNUNG**:
- **Brutto-Performance**: Reine Kursdifferenz ohne Nebenkosten
- **Netto-Performance**: Inklusive Steuern und Gebühren (optional aktivierbar)
- **Steuerberechnung nach deutschem Steuerrecht (2025)**:
  - **Kapitalertragsteuer (KESt)**: 25% auf Kapitalgewinne
  - **Solidaritätszuschlag (SolZ)**: 5,5% auf KESt (= 1,375% auf Gewinne)
  - **Kirchensteuer (KiSt)**: 8% (evangelisch) oder 9% (katholisch) auf KESt (optional)
  - **KEINE Optimierungen**: Keine Abschreibungen, Verlustverrechnung oder steuerliche Tricks
  - **Standard-Berechnung**: Einfache lineare Steuerberechnung ohne komplexe Strategien
- **Gebührentracking**: Kauf-/Verkaufgebühren, Börsenplatzentgelte, Spreads
- **Dividenden**: Brutto/Netto-Ausschüttungen mit Quellensteuer-Anrechnung
- **Vergleichsmodi**: Umschaltbar zwischen Brutto- und Netto-Sicht

**✅ PERFORMANCE-RANKING & DEPOT-SORTIERUNG**:
- **Netto-Gewinn-Vergleich**: Zeitraum-normalisierte Performance aller Positionen
- **Automatische Depot-Sortierung**: Nach Netto-Performance-Ranking
- **Zeitraum-Anpassung**: Gleiche Berechnungsbasis für faire Vergleiche
- **Multi-Kriterien-Sortierung**: Netto-Gewinn, ROI, Sharpe-Ratio, Volatilität
- **Performance-Heatmap**: Visuelle Darstellung der Gewinner/Verlierer
- **Rebalancing-Vorschläge**: Auf Basis der Performance-Analyse

**Fragen zur Klärung**:
- Welche Daten sollen für jede Position gespeichert werden?
- Soll es mehrere Depots/Portfolios geben können?
- **Steuer-Konfiguration**: Persönliche Steuersätze (KESt, SolZ, KiSt) konfigurierbar?
- **Gebühren-Modell**: Automatische Gebühren-Erkennung von Bitpanda oder manuelle Eingabe?
- **Währungsumrechnung**: Steuerberechnung bei Fremdwährungs-Assets (USD/EUR)?
- **Verlustvortrag**: Sollen Verluste für steuerliche Verrechnung gespeichert werden?
- **Performance-Zeiträume**: Welche Standard-Zeiträume für Vergleiche (1M, 3M, 6M, 1Y, YTD)?
- **Sortier-Kriterien**: Priorität der Sortierkriterien (Netto-Gewinn, ROI, Risk-Adjusted Return)?
- **Benchmark-Vergleich**: Sollen Positionen gegen Markt-Indices verglichen werden?

### 2. 🔄 Online-Broker Integration

**Anforderung**: Kauf- und Verkaufaufträge sollen automatisch an ein Online-Depot bei einem Broker ausgeführt werden

**Details**:
- Automatische Synchronisation zwischen lokalem und Online-Depot
- Ausführung von Buy/Sell-Orders über Broker-API
- Parallelführung: Lokales Depot + Online-Broker-Depot

**✅ BROKER-AUSWAHL ENTSCHIEDEN: Bitpanda Pro**

**Bitpanda Pro API Details**:
- **Base URL**: `https://api.exchange.bitpanda.com/public/v1`
- **API-Typ**: REST + WebSocket
- **Rate Limit**: 120 Requests/Minute
- **Authentifizierung**: Bearer Token (API Key)

**Verfügbare Order-Typen**:
- ✅ **Market Orders** - Sofortige Ausführung zum aktuellen Marktpreis
- ✅ **Limit Orders** - Ausführung bei Erreichen des Zielpreises
- ✅ **Stop-Limit Orders** - Stop-Loss mit Preislimit
- ✅ **Good 'til Cancelled (GtC)** - Standard für Limit Orders
- ✅ **Good 'til Time (GtT)** - Zeitgesteuerte Order (bis 1 Woche)
- ✅ **Immediate or Cancel (IoC)** - Sofort oder stornieren
- ✅ **Fill or Kill (FoK)** - Komplett oder gar nicht

**API-Berechtigungen**:
- **Read**: Account-Balances, Order-History, Market-Data
- **Trade**: Order-Placement, Order-Cancellation
- **Withdraw**: Ein-/Auszahlungen (nicht für Aktien-Trading relevant)

**WebSocket Real-time Features**:
- Account Feed (Balance-Updates)
- Market Data Feed (Preise, Ticker)
- Order Book Updates
- Candlestick-Streaming

**✅ ASSET-SUPPORT BESTÄTIGT**: Bitpanda unterstützt **Aktien + ETFs + Crypto**

**Verfügbare Instrumente**:
- ✅ **Aktien**: Einzelaktien verschiedener Märkte
- ✅ **ETFs**: Exchange Traded Funds  
- ✅ **Kryptowährungen**: Bitcoin, Ethereum, etc.
- ✅ **Fiat-Währungen**: EUR, USD für Trading-Pairs

**✅ BITPANDA API ALS DATENQUELLE ERGÄNZT**:
- **Market Data Integration**: Bitpanda Pro API als primäre Datenquelle für aktienanalyse
- **Dual-Purpose**: Trading-API (verwaltung) + Market Data (aktienanalyse)  
- **Real-time Streams**: WebSocket für Live-Kursanalyse und Vorhersagen
- **Enhanced Analytics**: Liquiditäts-Scores, Volume-Profile, Momentum-Indikatoren
- **Rate-Limited Access**: 100/120 Requests/Min für Public/Private API

**Verbleibende Fragen**:
- Sollen Orders sofort oder zeitgesteuert ausgeführt werden?
- Wie soll mit Teilausführungen umgegangen werden?
- Welche spezifischen Märkte/Börsen sind über Bitpanda verfügbar?

### 3. 📥 Cross-System Aktien-Intelligence

**Anforderung**: Intelligente Aktien-Übernahme aus dem gesamten Ökosystem mit Cross-System Performance-Vergleich

**Details**:
- **Multi-Source Import**: Aktien aus allen 3 Backend-Systemen (aktienanalyse, auswertung, data-web-app)
- **Intelligence-Algorithmus**: Performance-Vergleich zwischen allen Systemen
- **Watchlist-Modus**: Übernahme mit 0 Bestand für spätere Kaufentscheidungen
- **Cross-System Validation**: Duplikatserkennung über alle Projekte

**✅ ÖKOSYSTEM-INTEGRATION**:
- **Primary Source**: `aktienanalyse` → Top-Scored Stocks aus Technical Analysis
- **Secondary Source**: `auswertung` → High-Performance Stocks aus Portfolio Analytics
- **Tertiary Source**: `data-web-app` → User-definierte Watchlist-Inputs
- **Performance Matrix**: 4-System Performance-Cross-Correlation-Analyse
- **Auto-Import Logic**: Multi-Kriterien-Algorithmus für beste Stock-Selection

**Cross-System Intelligence-Algorithmus**:
```python
def cross_system_intelligence():
    # System 1: aktienanalyse Technical Scores
    technical_scores = get_aktienanalyse_top_performers()
    
    # System 2: auswertung Performance Analytics
    analytics_scores = get_auswertung_performance_rankings()
    
    # System 3: verwaltung Current Depot Performance
    depot_performance = get_current_depot_rankings()
    
    # System 4: data-web-app User Preferences
    user_preferences = get_user_watchlist_signals()
    
    # Cross-System Correlation Matrix
    correlation_matrix = calculate_cross_system_correlations(
        technical_scores, analytics_scores, depot_performance, user_preferences
    )
    
    # Multi-Criteria Decision Algorithm
    import_candidates = select_best_performers(
        correlation_matrix,
        weights={'technical': 0.4, 'analytics': 0.3, 'depot': 0.2, 'user': 0.1}
    )
    
    # Auto-Import to Depot (0 Bestand)
    for stock in import_candidates:
        if stock.combined_score > worst_depot_position.score:
            auto_import_to_watchlist(stock, quantity=0)
    
    return import_candidates
```

**Performance-Vergleichslogik**:
- **Depot-Performance**: Netto-Gewinn-Ranking der aktuellen Positionen
- **Analyse-Performance**: Bewertungen aus aktienanalyse-auswertung
- **Übernahme-Kriterium**: Aktie aus aktienanalyse besser als schlechteste Depot-Position
- **Watchlist-Modus**: Neue Aktien mit 0 Bestand für spätere Kaufentscheidungen

**Fragen zur Klärung**:
- **Performance-Mapping**: Wie werden aktienanalyse-Scores mit Depot-Rankings verglichen?
- **Übernahme-Schwellwert**: Ab welcher Performance-Differenz übernehmen?
- **Sync-Frequenz**: Wie oft soll der Vergleich durchgeführt werden?
- **Filterkriterien**: Zusätzliche Filter neben Performance (Sektor, Marktkapitalisierung)?
- **Benachrichtigungen**: Sollen neue Übernahmen dem Benutzer gemeldet werden?

### 4. 🏠 Deployment und Integration

**Anforderung**: Das Programm soll dauerhaft auf dem LXC Container mit den anderen Aktienanalyse-Teilprojekten laufen

**Details**:
- Deployment auf aktienanalyse-lxc-120 (10.1.1.174)
- Integration mit bestehender Aktienanalyse-Infrastruktur
- Dauerhafte Ausführung als Service/Daemon
- Gemeinsame Nutzung der vorhandenen Ressourcen (Datenbank, Mail-System, etc.)

**Technische Anforderungen**:
- systemd Service Integration
- Shared Data Access mit aktienanalyse-auswertung
- Nutzung des Enhanced Integrated Reporters
- Integration in bestehende Monitoring-Infrastruktur

**✅ DATENBANK-INTEGRATION GEKLÄRT**:
- **Separate Datenbank**: `depot.db` für Trading-relevante Daten
- **Cross-System Integration**: Python-APIs für Daten-Austausch
- **Backup-Strategie**: Unabhängige Sicherung beider Datenbanken
- **Schema-Management**: Separate Migrations für depot.db

**Verbleibende Fragen**:
- Soll es ein eigener Service oder Teil des bestehenden aktienanalyse-daemon werden?
- Sollen eigene Log-Dateien oder gemeinsame Logs verwendet werden?
- **Cross-System-Integration**: Wie wird die Performance-Synchronisation implementiert?
- **Daten-Mapping**: Welche Felder aus aktienanalyse.db werden für Vergleiche benötigt?
- **Sync-Scheduler**: Soll die Synchronisation zeitgesteuert oder event-basiert erfolgen?

### 5. 🌐 Northbound API (ohne Frontend)

**Anforderung**: Design und Implementation einer RESTful API für externe Frontend-Anbindung

**Details**:
- Vollständiger API-Zugriff auf alle Depot-Funktionen
- API-First Architektur für maximale Flexibilität
- **Frontend-Abgrenzung**: Separates Projekt "aktienanalyse-frontend" für UI

**API-Funktionen (zu designen)**:
- Depot-Übersicht und Portfolio-Status
- Positionen verwalten (CRUD-Operationen)
- Order-Management (Buy/Sell Orders)
- Performance-Daten und Statistiken
- Historische Daten und Charts
- Konfiguration und Einstellungen

**Technische Anforderungen**:
- RESTful API Design (OpenAPI/Swagger)
- Einfache lokale Authentifizierung (optional)
- JSON-basierte Datenübertragung
- WebSocket für Real-time Updates (optional)

**✅ FRONTEND-ABGRENZUNG GEKLÄRT**:
- **Kein Frontend**: aktienanalyse-verwaltung = Backend + API nur
- **Separates Projekt**: "aktienanalyse-frontend" für alle UI-Komponenten
- **API-Only-Fokus**: Vollständige REST-API für Frontend-Anbindung
- **Interface-Definition**: OpenAPI/Swagger für Frontend-Integration

**Vereinfachungen durch Single-User-Scope**:
- Keine komplexe Benutzerauthentifizierung erforderlich
- Keine Autorisierungslogik für verschiedene Benutzerrollen
- Keine Rate Limiting für API-Zugriffe notwendig
- Einfache lokale Konfiguration ausreichend

**Fragen zur Klärung**:
- Welche API-Standards sollen verwendet werden? (REST, GraphQL, etc.)
- **API-Interface**: Welche spezifischen Endpoints für aktienanalyse-frontend benötigt?

### 6. 📡 Backend Order-Management API

**Anforderung**: Es soll eine Backend-API geben, die für das Order-Management zuständig ist und sich an den Vorgaben der Online-Plattformen orientiert

**Details**:
- Standardisierte Order-Management API nach Broker-Standards
- Kompatibilität mit gängigen Online-Broker APIs
- Abstraktionsschicht zwischen lokalem System und verschiedenen Brokern
- Einheitliche Order-Schnittstelle unabhängig vom verwendeten Broker

**API-Standards Orientierung**:
- **Interactive Brokers API** (IB Gateway, TWS API)
- **Alpaca Trading API** (REST/WebSocket)
- **TD Ameritrade API** (REST-basiert)
- **E*TRADE API** (OAuth + REST)
- **Schwab API** (REST + OAuth)
- **FIX Protocol** (Financial Information eXchange)

**Order-Management Funktionen**:
- Order Placement (Market, Limit, Stop, Stop-Limit)
- Order Modification und Cancellation
- Order Status Tracking und Updates
- Position Management und Monitoring
- Account Information und Balances
- Real-time Market Data Integration

**Technische Anforderungen**:
- **Broker-Abstraction Layer**: Einheitliche API für verschiedene Broker
- **Order State Management**: Tracking von Order-Lifecycle
- **Error Handling**: Robust error handling für API-Failures
- **Broker Rate Limiting**: Compliance mit Broker-Rate-Limits
- **Reconnection Logic**: Automatische Wiederverbindung bei Verbindungsabbrüchen
- **Order Persistence**: Lokale Speicherung von Orders und Status

**Vereinfachungen durch Single-User-Scope**:
- Keine Benutzer-spezifische Order-Isolation erforderlich
- Keine Session-Management oder Token-Verwaltung
- Einfache lokale Konfigurationsdateien für Broker-Credentials
- Keine mandantenfähige Datenbanktrennung

**Fragen zur Klärung**:
- Welche spezifischen Broker-APIs sollen als Referenz dienen?
- Sollen mehrere Broker gleichzeitig unterstützt werden?
- Wie soll das Failover zwischen Brokern funktionieren?
- Welche Order-Typen haben höchste Priorität für die Implementierung?

---

## ❓ Offene Fragen für weitere Details

### 🔧 Technische Grundlagen
1. ✅ **Broker-Auswahl**: **Bitpanda Pro** - REST API + WebSocket Support
2. ✅ **Order-Typen**: Market, Limit, Stop-Limit + erweiterte Typen (GtC, GtT, IoC, FoK)
3. **Risikomanagement**: Sollen automatische Stopp-Loss oder Take-Profit-Orders gesetzt werden?
4. **Datenquellen**: Bitpanda Pro Market Data Feed + externe Quellen?
5. **API-Design**: REST (Bitpanda-kompatibel) + WebSocket für Real-time
6. ✅ **Frontend-Technologie**: **Separates Projekt "aktienanalyse-frontend"**
7. ✅ **Asset-Support geklärt**: Bitpanda Pro unterstützt **Aktien + ETFs + Crypto**

### 📊 Funktionale Details  
7. ✅ **Aktien-Quellen**: **aktienanalyse-auswertung** als primäre Datenquelle bestätigt
8. **Import-Filter**: Performance-basierte Übernahme + zusätzliche Filterkriterien?
9. **Benachrichtigungen**: Wie sollen Order-Ausführungen und neue Übernahmen kommuniziert werden?
10. **Order-Priorität**: Welche Order-Typen haben höchste Implementierungspriorität?
11. **Performance-Mapping**: Wie aktienanalyse-Scores mit Depot-Rankings vergleichen?
12. **Sync-Frequenz**: Zeitgesteuerte vs. event-basierte Synchronisation?

### 🏗️ Architektur
13. **Service-Integration**: Eigener Daemon oder Integration in bestehenden aktienanalyse-daemon?
14. ✅ **Datenbank-Sharing**: **Separate depot.db** + Cross-Database-Sync mit aktienanalyse.db
15. **Broker-API-Referenz**: Welche spezifischen Broker-APIs als Vorbild?
16. **Multi-Broker-Support**: Sollen mehrere Broker gleichzeitig unterstützt werden?
17. **Failover-Strategie**: Wie soll das Failover zwischen Brokern funktionieren?
18. **Cross-System-Sync**: Wie Performance-Daten zwischen beiden Systemen abgleichen?

### ✅ Vereinfacht durch Single-User-Scope
~~**API-Authentifizierung**~~: Nicht erforderlich für privates System  
~~**Benutzerinterface-Berechtigung**~~: Vollzugriff für einzigen Benutzer  
~~**API-Scope-Management**~~: Nur interne Nutzung  
~~**Multi-Tenant-Sicherheit**~~: Nicht relevant für Einzelbenutzer  
~~**Session-Management**~~: Keine Benutzer-Sessions erforderlich  
~~**Mandantenfähigkeit**~~: Keine Datenbanktrennung zwischen Benutzern  
~~**Berechtigungsmatrix**~~: Vollzugriff auf alle Funktionen für Einzelbenutzer  
~~**Audit-Logs**~~: Vereinfachte Protokollierung ohne Benutzer-Tracking

## 🏗️ Architektur-Überlegungen

### LXC Container Integration
- **Bestehende Infrastruktur**: aktienanalyse-lxc-120 (10.1.1.174)
- **Shared Services**: Postfix Mail-Server, Enhanced Reporter, /opt Report-Speicherung
- **Database**: Erwiterung der bestehenden aktienanalyse.db oder neue depot.db?
- **Monitoring**: Integration in bestehendes System-Monitoring

### Mögliche Architektur-Ansätze
1. **Monolithisch**: Erweiterung des bestehenden aktienanalyse-daemon
2. **Microservice**: Separater depot-service mit API-Kommunikation  
3. **Hybrid**: Separate Anwendung mit geteilten Ressourcen
4. **API-First**: Backend-Service + Northbound API + separates Frontend

### API-First Architektur mit Order-Management (Empfohlen)
```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────┐
│   Frontend      │    │  Northbound API  │    │  Depot-Service  │
│  (Web/Mobile)   │◄──►│    (REST/JSON)   │◄──►│   (Backend)     │
└─────────────────┘    └──────────────────┘    └─────────────────┘
                                │                        │
                                │                        ▼
                         ┌──────▼──────┐        ┌──────────────────┐
                         │ API Gateway │        │   Shared Data    │
                         │ (Auth/Rate) │        │ (aktienanalyse.db)│
                         └─────────────┘        └──────────────────┘
                                                         │
                                                         ▼
                         ┌─────────────────────────────────────────┐
                         │      Order-Management Backend API       │
                         │    (Broker-Abstraction Layer)          │
                         └─────────────────────────────────────────┘
                                           │
                    ┌──────────────────────┼──────────────────────┐
                    │                      │                      │
                    ▼                      ▼                      ▼
            ┌───────────────┐    ┌───────────────┐    ┌───────────────┐
            │ Interactive   │    │    Alpaca     │    │  TD Ameritrade│
            │   Brokers     │    │   Trading     │    │      API      │
            │     API       │    │     API       │    │               │
            └───────────────┘    └───────────────┘    └───────────────┘
```

**Single-User API-First Architektur**:
- ✅ **Frontend-Flexibilität** (Web, Mobile, Desktop)
- ✅ **Broker-Abstraction Layer** für Multi-Broker-Support
- ✅ **Standardisierte Order-API** nach Broker-Vorgaben
- ✅ **Saubere Trennung** zwischen UI, Business Logic und Broker-Integration
- ✅ **Failover-Mechanismen** zwischen verschiedenen Brokern
- ✅ **Einheitliche Order-Schnittstelle** unabhängig vom Broker

**Vereinfachungen für privaten Gebrauch**:
- 🔓 **Keine komplexe Authentifizierung** - lokaler Zugriff ohne Login
- 📝 **Einfache Konfiguration** - lokale Config-Dateien statt User-Management
- 🚀 **Schnellere Entwicklung** - Fokus auf Funktionalität statt Sicherheitsfeatures
- 🔧 **Direkte API-Zugriffe** - keine Rate-Limiting oder Permission-Checks
- 💾 **Einfache Datenhaltung** - Single-User-Schema ohne Mandantentrennung

---

## 💰 Priorisierung der Implementierung

### Phase 1: Core Module-Entwicklung (🔴 Kritisch)

#### 1. 📊 **core-depot Modul**
**Sub-Module-Struktur**:
```
core-depot/
├── position-manager/     # Position CRUD
├── order-manager/        # Order Lifecycle
├── trade-history/        # Trade-Historie
└── portfolio-calculator/ # Portfolio-Aggregation
```
- SQLite Datenbank-Schema (20 Tables)
- Position-Management mit CRUD-Operationen
- Order State Machine und Lifecycle-Management
- Portfolio-Übersicht und Aggregation

#### 2. 🧮 **performance-engine Modul**
**Pipeline-Architektur**:
```
performance-engine/
├── tax-calculator/       # Steuer-Engine (KESt, SolZ, KiSt)
├── fee-tracker/         # Gebühren-Berechnung
├── performance-metrics/ # ROI, Sharpe-Ratio etc.
└── ranking-engine/      # Multi-Kriterien-Ranking
```
- **Steuerberechnung nach aktuellem deutschen Steuerrecht (2025)**
- **KEINE Steueroptimierungen**: Keine Abschreibungen, Loss-Harvesting oder komplexe Optimierungen
- **Standard-Sätze**: 25% KESt + 5,5% SolZ + opt. 8%/9% KiSt
- Gebühren-Tracking und Netto-Performance-Berechnung
- Multi-Kriterien-Algorithmus (40% Netto, 30% Annualisiert, 30% Risk-Adjusted)
- Performance-Ranking und automatische Depot-Sortierung

#### 3. 🗄️ **data-layer Modul**
**Database-Abstraction**:
```
data-layer/
├── depot-repository/     # depot.db Operations
├── schema-manager/       # Database Migrations
├── query-optimizer/      # Performance Optimierung
└── backup-manager/       # Backup-Strategien
```
- Einheitliche Database-Abstraktion für alle Module
- Schema-Management und Migrations
- Cross-Database-Queries für aktienanalyse.db Integration

### Phase 2: External Integration Module (🟡 Wichtig)

#### 4. 🔄 **cross-system-sync Modul**
**Scheduled-Sync-Architektur**:
```
cross-system-sync/
├── sync-service/          # Periodischer Sync
├── data-mapper/          # aktienanalyse.db → depot.db
├── comparison-engine/     # Performance-Vergleich
└── import-processor/     # Batch-Import Logic (0 Bestand)
```
- Regelmäßige Synchronisation mit aktienanalyse-auswertung
- Performance-Vergleich zwischen Depot-Rankings und Analyse-Ergebnissen
- Automatische Übernahme besserer Aktien in Watchlist
- Cross-Database-Queries mit Fehlerbehandlung

#### 5. 📡 **broker-integration Modul**
**Event-Driven Broker-Abstraction**:
```
broker-integration/
├── broker-abstraction/    # Generic Broker Interface
├── bitpanda-adapter/     # Bitpanda-spezifische Impl.
├── order-executor/       # Event-driven Order-Ausführung
├── market-data-feed/     # Real-time Event-Publishing
├── cost-tracker/        # Event-basierte Gebühren-Integration
└── event-handler/       # Event Bus Integration
    ├── order-events/    # trading.orders.* Event Publishing
    ├── market-events/   # market.data.* Event Publishing  
    ├── cost-events/     # trading.costs.* Event Publishing
    └── broker-health/   # system.health.broker.* Events
```
- **Event-Driven Architecture**: Alle Broker-Aktionen über Event Bus
- **Order Events**: `trading.order.created/executed/failed` für Cross-System Updates
- **Market Data Events**: `market.data.realtime.*` für Live-Updates
- **Cost Events**: `trading.cost.calculated` für Performance-Engine
- **Health Events**: `system.health.broker.*` für Monitoring

### Phase 3: Northbound API Module (🟢 Erweiterung)

#### 6. 🌐 **northbound-api Modul**
**API-First-Architektur**:
```
northbound-api/
├── api-gateway/          # Zentraler API-Router
├── depot-endpoints/      # Depot-Verwaltung API
├── performance-api/      # Performance-Metrics API
├── order-api/           # Order-Management API
├── watchlist-api/       # Watchlist-Verwaltung API
├── sync-api/            # Cross-System-Sync API
├── websocket-hub/       # Real-time Updates
└── openapi-docs/        # Swagger-Dokumentation
```
- RESTful API Design mit standardisierten HTTP-Methoden
- OpenAPI/Swagger Dokumentation für aktienanalyse-frontend Integration
- JSON-basierte Datenübertragung mit Schema-Validierung
- WebSocket-Support für Real-time Updates (Portfolio-Änderungen, Order-Status)
- **Performance-API**: Brutto/Netto-Performance Endpoints mit Zeitraum-Filterung
- **Ranking-API**: Position-Rankings mit konfigurierbaren Sortierkriterien
- **Cross-System-API**: aktienanalyse-Vergleichs-Endpoints mit Synchronisation

#### 7. ⚙️ **service-foundation Modul**
**Infrastructure-Support**:
```
service-foundation/
├── config-manager/      # Zentrale Konfiguration
├── logging-system/      # Strukturierte Logs
├── health-monitor/      # System Health Checks
├── scheduler/           # Task-Scheduling
├── notification-hub/    # Benachrichtigungen
├── backup-service/      # Automatische Backups
└── systemd-integration/ # Service-Management
```
- Systemd Service Integration für dauerhafte Ausführung
- Zentrale Konfigurationsverwaltung (YAML/JSON-basiert)
- Strukturiertes Logging mit Log-Rotation
- Health-Check-Endpoints für Monitoring
- Task-Scheduler für periodische Jobs (Sync, Backup, Cleanup)
- Notification-System für wichtige Events

### Phase 4: Advanced Features Module (🔵 Zusatzfeatures)

#### 8. 🧪 **testing-framework Modul**
**Test-Infrastructure**:
```
testing-framework/
├── unit-tests/          # Modul-spezifische Tests
├── integration-tests/   # Cross-Module-Tests
├── mock-broker/         # Bitpanda Pro Mock-Server
├── test-data/          # Test-Datensätze
├── performance-tests/   # Load/Performance Tests
└── e2e-tests/          # End-to-End Tests
```
- Mock-Broker für Development und Testing ohne echte API-Calls
- Comprehensive Test-Suite für alle Module
- Performance-Tests für Ranking-Algorithmen
- Integration-Tests für Cross-System-Sync
- End-to-End Tests für komplette Trading-Workflows

#### 9. 🔬 **advanced-features Modul** (Optional)
**Extended Functionality**:
```
advanced-features/
├── tax-optimizer/       # Steueroptimierung
├── rebalancing-engine/  # Portfolio-Rebalancing
├── strategy-framework/  # Trading-Strategien
├── alert-system/       # Performance-Alerts
└── analytics-engine/   # Advanced Analytics
```
- **Steueroptimierung**: Verlustverrechnungs-Vorschläge und Tax-Loss-Harvesting
- **Portfolio-Rebalancing**: Automatische Optimierung basierend auf Cross-System Performance-Ranking
- **Trading-Strategien**: Framework für regelbasierte Kauf-/Verkaufentscheidungen
- **Performance-Alerts**: Benachrichtigungen bei neuen aktienanalyse-Empfehlungen
- **Enhanced Analytics**: Erweiterte Reportings mit Steuer-/Gebühren-Breakdown

**Modulare Deployment-Optionen**:
- **Development**: Alle Module als Python-Packages in einer Anwendung
- **Production-Monolith**: Alle Module in einem systemd-Service
- **Microservices**: Kritische Module (core-depot, broker-integration) als separate Services
- **Hybrid**: Flexibler Mix je nach Performance- und Maintenance-Anforderungen

---

## 🛠️ Technische Entscheidungen

### Datenbank-Strategie
**✅ ENTSCHIEDEN: Separate `depot.db` Datenbank**

**Vorteile der separaten Datenbank**:
- ✅ **Saubere Domänen-Trennung**: Depot-Management vs. Aktienanalyse
- ✅ **Unabhängige Schema-Evolution**: Keine Konflikte bei Updates
- ✅ **Separate Backup-Strategien**: Unabhängige Datensicherung
- ✅ **Microservice-Ready**: Vorbereitung für Service-Trennung
- ✅ **Klare Zuständigkeiten**: depot.db nur für Trading-relevante Daten

**Datenbank-Architektur `depot.db` (20 Tables)**:
```sql
-- Core Tables für Depot-Management (7)
depots              # Depot-Konfiguration und Metadaten
positions           # Aktuelle Positionen (Symbol, Anzahl, Durchschnittspreis)
orders              # Order-Management (Status, Typ, Ausführung)
trades              # Ausgeführte Trades (Buy/Sell Historie)
instruments         # Verfügbare Aktien/ETFs von Bitpanda
portfolio_snapshots # Historische Portfolio-Performance
account_balances    # Cash-Positionen und verfügbare Mittel

-- Enhanced Performance-Tracking Tables (6)
trade_costs         # Kauf-/Verkaufgebühren, Spreads, Börsenplatzentgelte
tax_calculations    # Standard-Steuerberechnung pro Trade (25% KESt + 5,5% SolZ + opt. KiSt)
dividends           # Dividenden-Historie (Brutto/Netto, Quellensteuer)
tax_simple_tracking # Einfache Steuer-Erfassung OHNE Optimierungen oder Verlustverrechnung
currency_rates      # Historische Wechselkurse für Fremdwährungs-Assets
performance_metrics # Berechnete Performance-Kennzahlen (Brutto/Netto nach Standardsteuer)

-- Performance-Ranking & Comparison Tables (4)
position_rankings   # Zeitraum-spezifische Performance-Rankings nach Netto-Gewinn
benchmark_data      # Markt-Indices für Vergleiche (DAX, S&P500, MSCI World)
risk_metrics        # Volatilität, Sharpe-Ratio, Maximum Drawdown pro Position
rebalancing_suggestions # Automatische Portfolio-Optimierungsvorschläge

-- Integration Tables (5)
broker_sync_log     # Synchronisation mit Bitpanda Pro
import_queue        # Externe Aktien-Imports (Warteschlange) 
notifications       # Order-Ausführung Benachrichtigungen
aktienanalyse_sync  # Cross-System Performance-Synchronisation
cross_system_rankings # Vergleich zwischen Depot- und Analyse-Performance
```

**Performance-Ranking Algorithmus**:
```python
# Zeitraum-normalisierte Netto-Performance-Berechnung
def calculate_position_ranking(position, time_period):
    net_return = (current_value - purchase_value - total_costs - taxes) / investment
    annualized_return = ((1 + net_return) ** (365/holding_days)) - 1
    risk_adjusted_return = annualized_return / volatility  # Sharpe-like ratio
    
    ranking_score = (
        net_return * 0.4 +           # Absolute Netto-Performance
        annualized_return * 0.3 +    # Zeitraum-normalisiert  
        risk_adjusted_return * 0.3   # Risk-adjusted
    )
    return ranking_score

# Cross-System Performance-Vergleich mit aktienanalyse-auswertung
def compare_with_aktienanalyse():
    depot_rankings = get_depot_performance_rankings()
    analyse_rankings = query_aktienanalyse_db()
    
    # Finde bessere Aktien aus aktienanalyse-auswertung
    better_stocks = []
    worst_depot_score = min(depot_rankings.values())
    
    for stock, analyse_score in analyse_rankings.items():
        if stock not in depot_rankings:  # Nicht im Depot
            if analyse_score > worst_depot_score:  # Besser als schlechteste Depot-Position
                better_stocks.append({
                    'symbol': stock,
                    'analyse_score': analyse_score,
                    'potential_improvement': analyse_score - worst_depot_score
                })
    
    # Automatische Übernahme in Depot (0 Bestand)
    for stock in better_stocks:
        add_to_depot_watchlist(stock['symbol'], quantity=0)
    
    return better_stocks
```

**Inter-Database Communication**:
- **Cross-Database Queries**: Bei Bedarf JOIN über Python-Layer
- **Shared Configuration**: Gemeinsame Config-Dateien für beide Systeme
- **Data Sharing**: RESTful APIs für Daten-Austausch zwischen Services

### Service-Integration-Strategie
**✅ ENTSCHIEDEN: Modulare Domain-Driven Architektur mit flexibler Deployment-Strategie**

**8-Module-Architektur**:
```
aktienanalyse-verwaltung/
├── 📊 core-depot/              # Domain: Depot-Management (4 Sub-Module)
├── 🧮 performance-engine/      # Domain: Performance-Berechnung (4 Sub-Module)
├── 🗄️ data-layer/             # Domain: Database-Abstraction (4 Sub-Module)
├── 🔄 cross-system-sync/       # Domain: aktienanalyse Integration (4 Sub-Module)
├── 📡 broker-integration/      # Domain: Bitpanda Pro Integration (5 Sub-Module)
├── 🌐 northbound-api/          # Domain: REST API Layer (8 Sub-Module)
├── ⚙️ service-foundation/      # Domain: Service Infrastructure (7 Sub-Module)
└── 🧪 testing-framework/      # Domain: Test Infrastructure (6 Sub-Module)
```

**✅ HYBRID-DEPLOYMENT-STRATEGIE (Empfohlen)**:
```
Deployment-Architektur:
├── core-services/              # Monolith (Performance-kritisch)
│   ├── core-depot/            # Position/Order Management
│   ├── performance-engine/    # Performance-Berechnungen
│   └── data-layer/           # Database-Abstraction
├── integration-services/       # Separate Services
│   ├── sync-service/          # cross-system-sync als Service
│   └── broker-gateway/        # broker-integration als Service
├── api-layer/                 # API-Gateway als Service
│   └── northbound-api/       # REST + WebSocket API
└── infrastructure/            # Shared Foundation
    └── service-foundation/    # Logging, Config, Health
```

**Service-Kommunikation**:
- **In-Process**: Module innerhalb core-services (niedrige Latenz)
- **REST APIs**: Inter-Service Communication (broker-gateway ↔ sync-service)
- **Shared Database**: depot.db für alle Services zugänglich
- **WebSocket**: Real-time Updates (broker-gateway → api-layer)

**Modulare Architektur-Vorteile**:
- ✅ **Domain-Driven Design**: Klare fachliche Abgrenzung der Module
- ✅ **Parallel Development**: 8 Module können unabhängig entwickelt werden
- ✅ **Isolierte Testing**: Jedes Modul mit eigener Test-Suite
- ✅ **Flexible Deployment**: Development-Monolith → Production-Hybrid → Microservices
- ✅ **Service Evolution**: Module können schrittweise als Services ausgelagert werden
- ✅ **Interface-Stabilität**: Definierte Interfaces bleiben bei Deployment-Änderungen stabil
- ✅ **Performance-Optimierung**: Kritische Module (core-depot) bleiben im Monolith
- ✅ **Skalierbarkeit**: Nur benötigte Services (broker-gateway) horizontal skalieren

### Broker-API-Standards
**✅ PRIMÄRE IMPLEMENTIERUNG: Bitpanda Pro API**

**Bitpanda Pro API Spezifikation**:
- **Base URL**: `https://api.exchange.bitpanda.com/public/v1`
- **Authentifizierung**: `Authorization: Bearer <API_KEY>`
- **Rate Limit**: 120 Requests/Minute (HTTP 429 bei Überschreitung)
- **Content-Type**: `application/json`

**Core Trading Endpoints**:
```
POST /account/orders          # Order-Placement
DELETE /account/orders/{id}   # Order-Cancellation  
GET /account/orders           # Order-History
GET /account/balances         # Account-Balances
GET /account/trades           # Trade-History
GET /instruments              # Verfügbare Instrumente
GET /currencies               # Unterstützte Währungen
```

**WebSocket-Streams (Real-time)**:
- `wss://streams.exchange.bitpanda.com/` 
- Account Feed: Balance-Updates, Order-Status
- Market Data: Ticker, OrderBook, Candlesticks
- Parallel WebSocket-Connections supported

**Python Integration (Referenz)**:
```python
# Basierend auf bitpanda-aio Client
client = BitpandaClient(api_key="YOUR_API_KEY")
await client.create_market_order(
    instrument_code="BTC_EUR", 
    side=OrderSide.BUY, 
    amount="1.0"
)
```

**✅ VOLLSTÄNDIGER ASSET-SUPPORT BESTÄTIGT**:
- **Aktien**: Direkter Zugang zu Aktien verschiedener Märkte
- **ETFs**: Exchange Traded Funds verfügbar
- **Crypto**: Bitcoin, Ethereum und weitere Kryptowährungen
- **Fiat**: EUR, USD für Trading-Pairs und Settlements
- **Single-Broker-Lösung**: Keine zusätzlichen Broker erforderlich

---

## 📋 Nächste Schritte

### Unmittelbare Aufgaben
1. ✅ **Broker-Auswahl finalisiert** - **Bitpanda Pro** mit REST + WebSocket API
2. ✅ **Asset-Support bestätigt** - **Aktien + ETFs + Crypto** vollständig unterstützt
3. **Order-Typen priorisieren** - Market, Limit, Stop-Limit Implementierungsreihenfolge
4. ✅ **Datenbank-Strategie entschieden** - **Separate `depot.db` Datenbank**
5. **Service-Architektur wählen** - Monolith vs. Microservice

### Technische Vorbereitung
1. **API-Standards definieren** - REST/GraphQL Entscheidung
2. ✅ **Frontend-Abgrenzung geklärt** - **Separates Projekt "aktienanalyse-frontend"**
3. **Deployment-Strategie** - systemd Service-Integration planen
4. **Testing-Strategie** - Mock-Broker für Development definieren
5. **API-Interface-Design** - OpenAPI/Swagger für aktienanalyse-frontend Integration

### Dokumentation
1. **API-Spezifikation** - OpenAPI/Swagger Schema für aktienanalyse-frontend
2. **Broker-Integration-Guide** - Schritt-für-Schritt Anleitung
3. **Deployment-Dokumentation** - LXC Container Setup-Guide
4. **API-Documentation** - Vollständige API-Referenz für Frontend-Integration
