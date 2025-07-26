# 🔗 Modulabhängigkeiten - Grafische Darstellung

## 📊 Domain-Dependency-Graph (13 Domains)

```
                    ┌─────────────────────────────────────────────────────────────────┐
                    │                    🏢 aktienanalyse-ökosystem                  │
                    │                        (13 Domains)                            │
                    └─────────────────────────────────────────────────────────────────┘
                                                    │
                    ┌───────────────────────────────┼───────────────────────────────┐
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
        │  🔄 Event-Bus    │          │ ⚙️ Infrastructure│          │ 🗄️ Data-         │
        │     Domain       │          │     Domain       │          │  Persistence     │
        │    (Core)        │          │   (Foundation)   │          │    Domain        │
        └──────────────────┘          └──────────────────┘          └──────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                     📊 Data & Analytics Layer                              │
        └─────────────────────────────────────────────────────────────────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
        │ 📊 Data-Ingestion│          │ 🧠 Analytics     │          │ 📈 Performance   │
        │     Domain       │          │    Domain        │          │    Domain        │
        └──────────────────┘          └──────────────────┘          └──────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                      💼 Business Logic Layer                               │
        └─────────────────────────────────────────────────────────────────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
        │ 💼 Portfolio     │          │ 📡 Trading       │          │ 💰 Tax          │
        │    Domain        │          │    Domain        │          │   Domain         │
        └──────────────────┘          └──────────────────┘          └──────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                       📋 Reporting Layer                                   │
        └─────────────────────────────────────────────────────────────────────────────┘
                                                    │
                                                    ▼
                                      ┌──────────────────┐
                                      │ 📋 Reporting     │
                                      │    Domain        │
                                      └──────────────────┘
                                                    │
                                                    ▼
        ┌─────────────────────────────────────────────────────────────────────────────┐
        │                      🌐 Interface Layer                                    │
        └─────────────────────────────────────────────────────────────────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
        ┌──────────────────┐          ┌──────────────────┐          ┌──────────────────┐
        │ 🌐 API-Gateway   │          │ 👤 User-         │          │ 🎨 Frontend      │
        │    Domain        │          │  Interaction     │          │    Domain        │
        │                  │          │    Domain        │          │                  │
        └──────────────────┘          └──────────────────┘          └──────────────────┘
                    │                               │                               │
                    ▼                               ▼                               ▼
                                      ┌──────────────────┐
                                      │   👨‍💻 User       │
                                      │   Interface      │
                                      └──────────────────┘
```

## 🎯 Detaillierte Dependency-Matrix

### Layer 1: Foundation (Infrastructure)
```
⚙️ infrastructure-domain
├── Abhängigkeiten: KEINE (Foundation Layer)
├── Wird genutzt von: ALLE anderen Domains
└── Funktion: Configuration, Logging, Monitoring, Security
```

### Layer 2: Core Services
```
🔄 event-bus-domain                    🗄️ data-persistence-domain
├── Abhängigkeiten: infrastructure     ├── Abhängigkeiten: infrastructure
├── Wird genutzt von: ALLE Domains     ├── Wird genutzt von: Domains mit DB-Bedarf
└── Funktion: Event-System             └── Funktion: Database Management
```

### Layer 3: Data & Analytics
```
📊 data-ingestion-domain               🧠 analytics-domain                 📈 performance-domain
├── Abhängigkeiten:                    ├── Abhängigkeiten:                ├── Abhängigkeiten:
│   ├── data-persistence               │   ├── data-ingestion              │   ├── portfolio-domain
│   ├── event-bus                      │   ├── data-persistence            │   ├── trading-domain
│   └── infrastructure                 │   └── event-bus                   │   ├── data-persistence
├── Wird genutzt von:                  ├── Wird genutzt von:              │   └── event-bus
│   ├── analytics-domain               │   ├── portfolio-domain            ├── Wird genutzt von:
│   ├── portfolio-domain               │   ├── trading-domain              │   ├── reporting-domain
│   └── trading-domain                 │   └── performance-domain          │   └── api-gateway-domain
└── Funktion: Multi-Source Data        └── Funktion: AI & Technical Analysis └── Funktion: Performance Analytics
```

### Layer 4: Business Logic
```
💼 portfolio-domain                    📡 trading-domain                   💰 tax-domain
├── Abhängigkeiten:                    ├── Abhängigkeiten:                ├── Abhängigkeiten:
│   ├── analytics-domain               │   ├── portfolio-domain            │   ├── trading-domain
│   ├── performance-domain             │   ├── analytics-domain            │   ├── performance-domain
│   ├── data-persistence               │   ├── performance-domain          │   └── data-persistence
│   └── event-bus                      │   ├── tax-domain                  ├── Wird genutzt von:
├── Wird genutzt von:                  │   └── event-bus                   │   ├── reporting-domain
│   ├── trading-domain                 ├── Wird genutzt von:              │   └── performance-domain
│   ├── performance-domain             │   ├── performance-domain          └── Funktion: German Tax Law
│   └── reporting-domain               │   └── api-gateway-domain          
└── Funktion: Portfolio Management     └── Funktion: Order Execution       
```

### Layer 5: Reporting
```
📋 reporting-domain
├── Abhängigkeiten:
│   ├── performance-domain
│   ├── tax-domain
│   ├── portfolio-domain
│   └── data-persistence
├── Wird genutzt von:
│   ├── api-gateway-domain
│   └── user-interaction-domain
└── Funktion: Multi-Format Reports (Excel, PowerPoint, Access MCP)
```

### Layer 6: Interface Layer
```
🌐 api-gateway-domain                  👤 user-interaction-domain          🎨 frontend-domain
├── Abhängigkeiten:                    ├── Abhängigkeiten:                ├── Abhängigkeiten:
│   └── ALL Domains (Orchestration)   │   ├── api-gateway-domain          │   ├── user-interaction-domain
├── Wird genutzt von:                  │   ├── event-bus-domain            │   ├── api-gateway-domain
│   ├── user-interaction-domain        │   └── frontend-domain             │   └── event-bus-domain
│   ├── frontend-domain                ├── Wird genutzt von:              ├── Wird genutzt von:
│   └── externe Clients                │   ├── frontend-domain             │   └── User (Browser)
└── Funktion: API Orchestration        │   └── externe User-Inputs         └── Funktion: UI Components & Views
                                       └── Funktion: UX & Workflow Control
```

## 🚀 Kommunikations-Flow-Diagramm

```
User Input
    │
    ▼
┌─────────────────┐    Workflow     ┌─────────────────┐    UI Updates    ┌─────────────────┐
│ 👤 User-        │◄─── Events ────►│ 🎨 Frontend     │◄─── & State ────►│ 👨‍💻 User       │
│  Interaction    │                 │    Domain       │                 │   Browser       │
│  Domain         │                 └─────────────────┘                 └─────────────────┘
└─────────────────┘                           │
         │                                    │
    API Calls                            Real-time
         │                               Updates
         ▼                                    │
┌─────────────────┐    Orchestration   ┌─────▼───────────┐
│ 🌐 API-Gateway  │◄──── Layer ───────►│ 🔄 Event-Bus    │
│    Domain       │                    │    Domain       │
└─────────────────┘                    └─────────────────┘
         │                                    │
    Domain APIs                          Cross-Domain
         │                               Events
         ▼                                    │
┌─────────────────────────────────────────────▼───────────────────────────────────────────────┐
│                            🏢 Business Logic Domains                                        │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │📊 Data-      │  │🧠 Analytics  │  │💼 Portfolio  │  │📡 Trading    │  │💰 Tax        │  │
│  │  Ingestion   │  │   Domain     │  │   Domain     │  │   Domain     │  │  Domain      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  └──────────────┘  │
│         │                  │                  │                  │                  │       │
│         └──────────────────┼──────────────────┼──────────────────┼──────────────────┘       │
└────────────────────────────┼──────────────────┼──────────────────┼─────────────────────────┘
                             │                  │                  │
                        ┌────▼──────┐      ┌────▼──────┐      ┌────▼──────┐
                        │📈 Performance│      │📋 Reporting│      │External APIs│
                        │   Domain    │      │   Domain  │      │(Bitpanda)  │
                        └─────────────┘      └───────────┘      └───────────┘
                             │                  │
                             └──────────────────┘
                                      │
                             ┌────────▼────────┐
                             │🗄️ Data-         │
                             │  Persistence    │
                             │  Domain         │
                             └─────────────────┘
                                      │
                             ┌────────▼────────┐
                             │⚙️ Infrastructure │
                             │   Domain        │
                             │ (Foundation)    │
                             └─────────────────┘
```

## 📊 Cross-Domain Event-Flow

```
Event Types & Propagation:

📊 Data Events:
market.data.update → analytics, portfolio, trading
stock.analysis.completed → portfolio, performance, reporting

💼 Portfolio Events:
portfolio.rebalance.suggested → user-interaction, trading
position.added → performance, tax, reporting

📡 Trading Events:
order.executed → portfolio, performance, tax, event-bus
trade.completed → performance, reporting, user-interaction

📈 Performance Events:
performance.calculated → reporting, user-interaction
risk.threshold.exceeded → user-interaction, trading

💰 Tax Events:
tax.calculated → performance, reporting
tax.year.closed → reporting, user-interaction

📋 Reporting Events:
report.generated → user-interaction, infrastructure (email)
export.completed → user-interaction

👤 User Events:
workflow.started → all relevant domains
user.preference.changed → personalization across domains

🎨 Frontend Events:
ui.state.changed → user-interaction
real-time.update.requested → event-bus
```

## 🔧 Deployment-Service-Mapping

```
LXC Container Services & Domain-Mapping:

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ data-ingestion-service :8001    │    │ analytics-service :8002         │
│ ├── 📊 data-ingestion-domain    │    │ ├── 🧠 analytics-domain         │
│ └── (External API Integration)  │    │ └── (ML & Technical Analysis)   │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ portfolio-trading-service :8003 │    │ performance-tax-service :8004   │
│ ├── 💼 portfolio-domain         │    │ ├── 📈 performance-domain       │
│ └── 📡 trading-domain           │    │ └── 💰 tax-domain               │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ reporting-service :8005         │    │ user-interaction-service :8006  │
│ ├── 📋 reporting-domain         │    │ ├── 👤 user-interaction-domain  │
│ └── (Excel/PowerPoint/Access)   │    │ └── (UX & Workflow Control)     │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────┐
│ frontend-service :8007          │
│ ├── 🎨 frontend-domain          │
│ └── (React UI Components)       │
└─────────────────────────────────┘

Infrastructure Services:
┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ api-gateway :443 (HTTPS)        │    │ event-bus-redis :6379           │
│ ├── 🌐 api-gateway-domain       │    │ ├── 🔄 event-bus-domain         │
│ └── (NGINX Reverse Proxy)       │    │ └── (Redis Pub/Sub Cluster)     │
└─────────────────────────────────┘    └─────────────────────────────────┘

┌─────────────────────────────────┐    ┌─────────────────────────────────┐
│ data-persistence-cluster        │    │ infrastructure-monitoring       │
│ ├── 🗄️ data-persistence-domain  │    │ ├── ⚙️ infrastructure-domain    │
│ ├── SQLite Databases           │    │ ├── Prometheus + Grafana        │
│ └── Redis Cache                │    │ └── Logging + Health Checks     │
└─────────────────────────────────┘    └─────────────────────────────────┘
```

Diese grafische Darstellung zeigt die **13 Domains** mit ihren Abhängigkeiten, Kommunikationsmustern und Service-Mappings für das aktienanalyse-ökosystem.