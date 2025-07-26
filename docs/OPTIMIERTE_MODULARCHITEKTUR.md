# 🏗️ Optimierte Modularchitektur - Domain-Driven Design

## 📊 Architektur-Analyse der aktuellen 22 Module

### ❌ Probleme in der aktuellen Struktur:
1. **Redundante Module**: `data-layer` existiert 3x in verschiedenen Projekten
2. **Überlappende Funktionen**: Multiple APIs für ähnliche Funktionen
3. **Projektbezogene Trennung**: Module sind zu stark an Projekte gebunden
4. **Fehlende Abstraktion**: Direkter Code in Projektordnern statt Domain-Module
5. **Cross-Cutting Concerns**: Logging, Auth, Config in mehreren Modulen dupliziert

### ✅ Ziel: Domain-Driven Design mit 13 Core-Domains

Umstrukturierung von **22 projektbasierten Modulen** zu **13 domain-basierten Hauptfunktionen** mit klaren Grenzen und Sub-Modulen.

---

## 🎯 **Optimierte Domain-Architektur (13 Domains)**

```
🏢 aktienanalyse-ökosystem/
├── 📊 data-ingestion-domain/          # Domain 1: Datensammlung
├── 🧠 analytics-domain/               # Domain 2: Analyse & KI
├── 💼 portfolio-domain/               # Domain 3: Portfolio Management
├── 📡 trading-domain/                 # Domain 4: Trading Execution
├── 📈 performance-domain/             # Domain 5: Performance & Risk
├── 💰 tax-domain/                     # Domain 6: Steuerberechnung
├── 📋 reporting-domain/               # Domain 7: Reports & Exports
├── 🌐 api-gateway-domain/             # Domain 8: API Management
├── 👤 user-interaction-domain/        # Domain 9: User Interactions & UX ⭐ NEU
├── 🎨 frontend-domain/                # Domain 10: UI Components & Views
├── 🔄 event-bus-domain/               # Domain 11: Event System
├── 🗄️ data-persistence-domain/       # Domain 12: Datenbank Management
└── ⚙️ infrastructure-domain/          # Domain 13: System Infrastructure
```

---

## 📊 **Domain 1: data-ingestion-domain**
**Hauptfunktion**: Sammlung und Normalisierung aller Datenquellen

### Sub-Module:
```
data-ingestion-domain/
├── source-adapters/                   # API-Adapter für verschiedene Quellen
│   ├── alpha-vantage-adapter/
│   ├── yahoo-finance-adapter/
│   ├── fred-economic-adapter/
│   ├── bitpanda-api-adapter/
│   └── news-sentiment-adapter/
├── data-normalization/                # Einheitliche Datenformate
│   ├── price-data-normalizer/
│   ├── volume-data-normalizer/
│   ├── fundamental-data-normalizer/
│   └── event-data-normalizer/
├── rate-limiting/                     # Zentrale Rate-Limit-Verwaltung
│   ├── request-scheduler/
│   ├── quota-manager/
│   └── fallback-strategies/
├── data-validation/                   # Qualitätssicherung
│   ├── plausibility-checks/
│   ├── duplicate-detection/
│   ├── data-quality-scoring/
│   └── anomaly-detection/
└── ingestion-orchestrator/            # Zentrale Steuerung
    ├── source-prioritization/
    ├── conflict-resolution/
    ├── backfill-manager/
    └── real-time-coordinator/
```

**Wird angesteuert von**: analytics-domain, portfolio-domain, trading-domain
**Steuert an**: data-persistence-domain, event-bus-domain

---

## 🧠 **Domain 2: analytics-domain**
**Hauptfunktion**: Technical Analysis, Machine Learning und Signalgenerierung

### Sub-Module:
```
analytics-domain/
├── technical-analysis/                # Technische Indikatoren
│   ├── basic-indicators/             # RSI, MACD, Moving Averages
│   ├── advanced-indicators/          # Stochastic, Williams %R, CCI
│   ├── pattern-recognition/          # Candlestick Patterns
│   ├── support-resistance/           # Level-Detection
│   └── trend-analysis/               # Multi-Timeframe Trends
├── machine-learning/                  # KI-Modelle
│   ├── feature-engineering/
│   ├── model-training/
│   │   ├── xgboost-models/
│   │   ├── lstm-networks/
│   │   ├── transformer-models/
│   │   └── ensemble-models/
│   ├── model-validation/
│   │   ├── backtesting-engine/
│   │   ├── walk-forward-analysis/
│   │   └── cross-validation/
│   └── prediction-engine/
├── signal-generation/                 # Trading-Signale
│   ├── buy-sell-signals/
│   ├── confidence-scoring/
│   ├── signal-aggregation/
│   └── risk-assessment/
├── market-analysis/                   # Marktanalyse
│   ├── sector-analysis/
│   ├── correlation-analysis/
│   ├── liquidity-analysis/
│   └── sentiment-analysis/
└── bitpanda-enhanced-analytics/       # Bitpanda-spezifische Features
    ├── order-book-analysis/
    ├── volume-profile-analysis/
    ├── real-time-momentum/
    └── unusual-activity-detection/
```

**Wird angesteuert von**: data-ingestion-domain, portfolio-domain
**Steuert an**: trading-domain, performance-domain, event-bus-domain

---

## 💼 **Domain 3: portfolio-domain**
**Hauptfunktion**: Portfolio-Konstruktion und Asset-Management

### Sub-Module:
```
portfolio-domain/
├── position-management/               # Position-Verwaltung
│   ├── position-lifecycle/
│   ├── position-sizing/
│   ├── portfolio-allocation/
│   └── rebalancing-logic/
├── asset-universe/                    # Asset-Management
│   ├── instrument-registry/
│   ├── asset-classification/
│   ├── eligibility-screening/
│   └── watchlist-management/
├── portfolio-construction/            # Portfolio-Aufbau
│   ├── strategic-allocation/
│   ├── tactical-allocation/
│   ├── risk-budgeting/
│   └── diversification-engine/
├── cross-system-intelligence/         # Intelligente Asset-Auswahl
│   ├── signal-aggregation/
│   ├── performance-correlation/
│   ├── auto-import-logic/
│   └── decision-framework/
└── portfolio-optimization/            # Optimierung
    ├── mean-variance-optimization/
    ├── risk-parity/
    ├── black-litterman/
    └── constraint-optimization/
```

**Wird angesteuert von**: analytics-domain, performance-domain
**Steuert an**: trading-domain, performance-domain, data-persistence-domain

---

## 📡 **Domain 4: trading-domain**
**Hauptfunktion**: Order-Execution und Broker-Integration

### Sub-Module:
```
trading-domain/
├── order-management/                  # Order-Lifecycle
│   ├── order-validation/
│   ├── order-routing/
│   ├── execution-monitoring/
│   └── order-state-machine/
├── broker-integration/                # Multi-Broker-Support
│   ├── broker-abstraction/
│   ├── bitpanda-adapter/
│   ├── interactive-brokers-adapter/   # Future
│   └── generic-fix-adapter/           # Future
├── execution-algorithms/              # Trading-Algorithmen
│   ├── market-orders/
│   ├── limit-orders/
│   ├── stop-orders/
│   ├── iceberg-orders/
│   └── twap-vwap-orders/
├── risk-management/                   # Execution-Risk
│   ├── pre-trade-checks/
│   ├── position-limits/
│   ├── exposure-limits/
│   └── circuit-breakers/
├── transaction-cost-analysis/         # TCA
│   ├── implementation-shortfall/
│   ├── market-impact-analysis/
│   ├── timing-cost-analysis/
│   └── opportunity-cost-analysis/
└── settlement/                        # Trade Settlement
    ├── trade-confirmation/
    ├── settlement-tracking/
    ├── corporate-actions/
    └── dividend-processing/
```

**Wird angesteuert von**: portfolio-domain, analytics-domain, api-gateway-domain
**Steuert an**: performance-domain, tax-domain, event-bus-domain

---

## 📈 **Domain 5: performance-domain**
**Hauptfunktion**: Performance-Messung und Risk Analytics

### Sub-Module:
```
performance-domain/
├── return-calculation/                # Return-Berechnung
│   ├── time-weighted-returns/
│   ├── money-weighted-returns/
│   ├── attribution-analysis/
│   └── benchmark-relative-returns/
├── risk-analytics/                    # Risk-Metriken
│   ├── volatility-analysis/
│   ├── value-at-risk/
│   ├── expected-shortfall/
│   ├── maximum-drawdown/
│   └── risk-adjusted-returns/
├── benchmark-analysis/                # Benchmark-Vergleiche
│   ├── index-comparison/
│   ├── peer-comparison/
│   ├── sector-comparison/
│   └── alpha-beta-analysis/
├── performance-ranking/               # Ranking-Engine
│   ├── multi-criteria-ranking/
│   ├── time-period-normalization/
│   ├── risk-adjusted-ranking/
│   └── relative-ranking/
├── scenario-analysis/                 # Szenario-Tests
│   ├── stress-testing/
│   ├── monte-carlo-simulation/
│   ├── scenario-modeling/
│   └── sensitivity-analysis/
└── performance-monitoring/            # Live-Monitoring
    ├── real-time-pnl/
    ├── intraday-performance/
    ├── performance-alerts/
    └── performance-dashboard/
```

**Wird angesteuert von**: portfolio-domain, trading-domain
**Steuert an**: reporting-domain, event-bus-domain, api-gateway-domain

---

## 💰 **Domain 6: tax-domain**
**Hauptfunktion**: Steuerberechnung nach deutschem Recht

### Sub-Module:
```
tax-domain/
├── german-tax-engine/                 # Deutsches Steuerrecht 2025
│   ├── kapitalertragsteuer/          # 25% KESt
│   ├── solidaritaetszuschlag/        # 5,5% SolZ
│   ├── kirchensteuer/                # 8%/9% KiSt (optional)
│   └── tax-rate-management/
├── transaction-tax-tracking/          # Trade-basierte Besteuerung
│   ├── fifo-lifo-calculation/
│   ├── wash-sale-rules/
│   ├── holding-period-tracking/
│   └── cost-basis-adjustment/
├── dividend-tax-processing/           # Dividenden-Besteuerung
│   ├── domestic-dividends/
│   ├── foreign-dividends/
│   ├── withholding-tax/
│   └── tax-credit-calculation/
├── tax-reporting/                     # Steuer-Reports
│   ├── tax-summary-generation/
│   ├── transaction-export/
│   ├── tax-loss-harvesting/
│   └── year-end-processing/
└── compliance/                        # Compliance
    ├── tax-validation/
    ├── audit-trail/
    ├── regulatory-reporting/
    └── tax-document-management/
```

**Wird angesteuert von**: trading-domain, performance-domain
**Steuert an**: reporting-domain, data-persistence-domain

---

## 📋 **Domain 7: reporting-domain**
**Hauptfunktion**: Report-Generierung und Export

### Sub-Module:
```
reporting-domain/
├── report-generation/                 # Report-Engine
│   ├── template-engine/
│   ├── data-aggregation/
│   ├── chart-generation/
│   └── layout-management/
├── multi-format-export/               # Export-Formate
│   ├── excel-generator/              # Excel MCP Integration
│   ├── powerpoint-generator/         # PowerPoint MCP
│   ├── access-database/              # Access MCP
│   ├── pdf-generator/
│   └── html-export/
├── report-types/                      # Verschiedene Report-Typen
│   ├── executive-summary/
│   ├── detailed-analytics/
│   ├── risk-reports/
│   ├── tax-reports/
│   ├── regulatory-reports/
│   └── custom-reports/
├── automated-reporting/               # Automation
│   ├── schedule-management/
│   ├── email-distribution/
│   ├── report-archiving/
│   └── version-control/
└── report-analytics/                  # Report-Metriken
    ├── usage-tracking/
    ├── performance-monitoring/
    ├── user-feedback/
    └── report-optimization/
```

**Wird angesteuert von**: performance-domain, tax-domain, portfolio-domain
**Steuert an**: infrastructure-domain (email), data-persistence-domain

---

## 🌐 **Domain 8: api-gateway-domain**
**Hauptfunktion**: Einheitliche API-Schicht und Orchestrierung

### Sub-Module:
```
api-gateway-domain/
├── gateway-core/                      # Gateway-Engine
│   ├── request-routing/
│   ├── load-balancing/
│   ├── circuit-breaker/
│   └── timeout-management/
├── authentication/                    # Auth-System
│   ├── jwt-management/
│   ├── api-key-management/
│   ├── session-management/
│   └── permission-system/
├── rate-limiting/                     # Rate-Control
│   ├── global-rate-limits/
│   ├── per-client-limits/
│   ├── burst-protection/
│   └── quota-management/
├── api-composition/                   # API-Komposition
│   ├── data-aggregation/
│   ├── response-transformation/
│   ├── cross-domain-queries/
│   └── batch-processing/
├── caching/                          # Performance-Caching
│   ├── redis-caching/
│   ├── cache-invalidation/
│   ├── cache-warming/
│   └── cache-analytics/
├── monitoring/                       # API-Monitoring
│   ├── request-logging/
│   ├── performance-metrics/
│   ├── error-tracking/
│   └── sla-monitoring/
└── documentation/                    # API-Docs
    ├── openapi-generation/
    ├── interactive-docs/
    ├── sdk-generation/
    └── versioning/
```

**Wird angesteuert von**: frontend-domain, externe Clients
**Steuert an**: Alle anderen Domains

---

## 👤 **Domain 9: user-interaction-domain**
**Hauptfunktion**: User Experience, Workflow-Steuerung und Frontend-Orchestrierung

### Sub-Module:
```
user-interaction-domain/
├── user-session-management/           # Session & State Management
│   ├── session-lifecycle/
│   ├── user-preferences/
│   ├── workspace-management/
│   ├── multi-tab-coordination/
│   └── session-persistence/
├── workflow-orchestration/            # Business-Workflow-Steuerung
│   ├── trading-workflows/
│   │   ├── order-placement-flow/
│   │   ├── portfolio-rebalancing-flow/
│   │   ├── watchlist-to-position-flow/
│   │   └── risk-assessment-flow/
│   ├── analysis-workflows/
│   │   ├── stock-screening-flow/
│   │   ├── performance-analysis-flow/
│   │   ├── backtesting-flow/
│   │   └── signal-validation-flow/
│   ├── reporting-workflows/
│   │   ├── report-generation-flow/
│   │   ├── tax-calculation-flow/
│   │   ├── export-workflow/
│   │   └── distribution-flow/
│   └── onboarding-workflows/
│       ├── initial-setup-flow/
│       ├── data-source-config-flow/
│       ├── portfolio-import-flow/
│       └── system-tour-flow/
├── user-interaction-patterns/         # Interaction Design Patterns
│   ├── drag-drop-interfaces/
│   ├── context-menus/
│   ├── keyboard-shortcuts/
│   ├── gesture-recognition/
│   └── voice-commands/               # Future
├── intelligent-assistance/            # AI-powered User Assistance
│   ├── recommendation-engine/
│   │   ├── next-best-action/
│   │   ├── workflow-suggestions/
│   │   ├── performance-insights/
│   │   └── risk-warnings/
│   ├── smart-automation/
│   │   ├── auto-completion/
│   │   ├── form-prefilling/
│   │   ├── intelligent-defaults/
│   │   └── bulk-operations/
│   ├── contextual-help/
│   │   ├── inline-guidance/
│   │   ├── progressive-disclosure/
│   │   ├── interactive-tutorials/
│   │   └── context-aware-tooltips/
│   └── anomaly-detection/
│       ├── unusual-user-behavior/
│       ├── potential-errors/
│       ├── performance-degradation/
│       └── security-alerts/
├── personalization-engine/            # Personalisierung
│   ├── adaptive-ui/
│   │   ├── layout-optimization/
│   │   ├── widget-prioritization/
│   │   ├── color-scheme-adaptation/
│   │   └── information-density/
│   ├── behavioral-learning/
│   │   ├── usage-pattern-analysis/
│   │   ├── preference-inference/
│   │   ├── performance-optimization/
│   │   └── efficiency-suggestions/
│   ├── role-based-customization/
│   │   ├── day-trader-mode/
│   │   ├── long-term-investor-mode/
│   │   ├── analyst-mode/
│   │   └── beginner-mode/
│   └── dashboard-personalization/
│       ├── custom-widgets/
│       ├── personal-watchlists/
│       ├── favorite-views/
│       └── quick-actions/
├── notification-orchestration/        # Intelligente Benachrichtigungen
│   ├── notification-prioritization/
│   │   ├── urgency-classification/
│   │   ├── relevance-scoring/
│   │   ├── timing-optimization/
│   │   └── attention-management/
│   ├── multi-channel-delivery/
│   │   ├── in-app-notifications/
│   │   ├── email-notifications/
│   │   ├── push-notifications/
│   │   └── desktop-notifications/
│   ├── notification-aggregation/
│   │   ├── digest-generation/
│   │   ├── summary-creation/
│   │   ├── duplicate-elimination/
│   │   └── batch-processing/
│   └── user-attention-management/
│       ├── focus-mode/
│       ├── do-not-disturb/
│       ├── notification-scheduling/
│       └── interruption-minimization/
└── accessibility-compliance/          # Barrierefreiheit
    ├── wcag-compliance/
    │   ├── keyboard-navigation/
    │   ├── screen-reader-support/
    │   ├── color-contrast-optimization/
    │   └── focus-management/
    ├── adaptive-interfaces/
    │   ├── font-size-scaling/
    │   ├── high-contrast-modes/
    │   ├── motion-reduction/
    │   └── simplified-layouts/
    ├── assistive-technology/
    │   ├── voice-control/
    │   ├── eye-tracking-support/
    │   ├── switch-navigation/
    │   └── head-tracking/
    └── inclusive-design/
        ├── cognitive-load-reduction/
        ├── error-prevention/
        ├── recovery-mechanisms/
        └── clear-communication/
```

**Wird angesteuert von**: frontend-domain, externe User-Inputs
**Steuert an**: api-gateway-domain, event-bus-domain, frontend-domain, alle Backend-Domains

---

## 🎨 **Domain 10: frontend-domain**
**Hauptfunktion**: UI-Komponenten, Views und technische Frontend-Implementation

### Sub-Module:
```
frontend-domain/
├── core-framework/                    # React-Framework
│   ├── component-library/
│   ├── design-system/
│   ├── theme-management/
│   └── responsive-framework/
├── dashboard-components/              # Dashboard-Building
│   ├── chart-components/
│   ├── table-components/
│   ├── filter-components/
│   └── layout-components/
├── domain-specific-ui/                # Fachspezifische UIs
│   ├── portfolio-ui/
│   ├── trading-ui/
│   ├── analytics-ui/
│   ├── performance-ui/
│   └── reporting-ui/
├── real-time-ui/                      # Live-Updates
│   ├── websocket-integration/
│   ├── real-time-charts/
│   ├── live-notifications/
│   └── streaming-data-components/
├── state-management/                  # State-Management
│   ├── redux-store/
│   ├── local-state/
│   ├── cache-management/
│   └── data-synchronization/
└── user-experience/                   # UX-Features
    ├── navigation-system/
    ├── search-functionality/
    ├── help-system/
    └── accessibility/
```

**Wird angesteuert von**: user-interaction-domain, api-gateway-domain
**Steuert an**: api-gateway-domain, event-bus-domain

---

## 🔄 **Domain 11: event-bus-domain**
**Hauptfunktion**: Event-driven Architecture und System-Integration

### Sub-Module:
```
event-bus-domain/
├── event-core/                        # Event-Engine
│   ├── event-dispatcher/
│   ├── event-router/
│   ├── event-serialization/
│   └── event-validation/
├── messaging-infrastructure/          # Messaging-System
│   ├── redis-pubsub/
│   ├── message-queues/
│   ├── topic-management/
│   └── subscription-management/
├── event-schemas/                     # Event-Definitionen
│   ├── market-data-events/
│   ├── trading-events/
│   ├── portfolio-events/
│   ├── performance-events/
│   └── system-events/
├── event-processing/                  # Event-Verarbeitung
│   ├── event-filtering/
│   ├── event-transformation/
│   ├── event-enrichment/
│   └── event-aggregation/
├── integration-patterns/              # Integration-Patterns
│   ├── saga-orchestration/
│   ├── event-sourcing/
│   ├── cqrs-implementation/
│   └── eventual-consistency/
└── event-monitoring/                  # Event-Überwachung
    ├── event-tracking/
    ├── performance-monitoring/
    ├── failure-detection/
    └── replay-mechanisms/
```

**Wird angesteuert von**: Alle anderen Domains
**Steuert an**: Alle anderen Domains

---

## 🗄️ **Domain 12: data-persistence-domain**
**Hauptfunktion**: Datenbank-Management und Persistierung

### Sub-Module:
```
data-persistence-domain/
├── database-engines/                  # DB-Engines
│   ├── sqlite-management/
│   ├── postgresql-management/         # Future
│   ├── redis-management/
│   └── timeseries-db/                # Future
├── schema-management/                 # Schema-Verwaltung
│   ├── migration-engine/
│   ├── version-control/
│   ├── schema-validation/
│   └── compatibility-checking/
├── data-access-layer/                 # Data Access
│   ├── repository-pattern/
│   ├── query-builder/
│   ├── connection-pooling/
│   └── transaction-management/
├── performance-optimization/          # Performance
│   ├── index-management/
│   ├── query-optimization/
│   ├── caching-strategies/
│   └── connection-optimization/
├── backup-recovery/                   # Backup & Recovery
│   ├── automated-backups/
│   ├── point-in-time-recovery/
│   ├── disaster-recovery/
│   └── backup-validation/
├── data-archiving/                    # Archivierung
│   ├── retention-policies/
│   ├── data-compression/
│   ├── cold-storage/
│   └── data-lifecycle-management/
└── monitoring/                        # DB-Monitoring
    ├── performance-monitoring/
    ├── space-monitoring/
    ├── health-checks/
    └── alerting/
```

**Wird angesteuert von**: Alle Domains mit Persistierung-Bedarf
**Steuert an**: infrastructure-domain (Monitoring)

---

## ⚙️ **Domain 13: infrastructure-domain**
**Hauptfunktion**: System-Infrastructure und Cross-Cutting Concerns

### Sub-Module:
```
infrastructure-domain/
├── configuration-management/          # Konfiguration
│   ├── config-loading/
│   ├── environment-management/
│   ├── secret-management/
│   └── dynamic-configuration/
├── logging-system/                    # Logging
│   ├── structured-logging/
│   ├── log-aggregation/
│   ├── log-rotation/
│   └── log-analysis/
├── monitoring-observability/          # Monitoring
│   ├── metrics-collection/
│   ├── health-checks/
│   ├── alerting-system/
│   ├── distributed-tracing/
│   └── performance-profiling/
├── security/                          # Security
│   ├── encryption-decryption/
│   ├── certificate-management/
│   ├── security-scanning/
│   └── vulnerability-management/
├── deployment-orchestration/          # Deployment
│   ├── systemd-integration/
│   ├── container-management/
│   ├── service-discovery/
│   └── health-monitoring/
├── communication/                     # Kommunikation
│   ├── email-service/
│   ├── notification-service/
│   ├── webhook-management/
│   └── sms-service/                   # Future
└── resource-management/               # Resource-Management
    ├── memory-management/
    ├── cpu-monitoring/
    ├── disk-management/
    └── network-monitoring/
```

**Wird angesteuert von**: Alle anderen Domains
**Steuert an**: Externe Services (Email, Monitoring)

---

## 🔗 **Domain-Interaktion-Matrix**

### High-Level Domain-Dependencies:
```
┌─────────────────────┬─────────────────────────────────────────────────────┐
│ Domain              │ Depends On                                          │
├─────────────────────┼─────────────────────────────────────────────────────┤
│ data-ingestion      │ data-persistence, event-bus, infrastructure         │
│ analytics           │ data-ingestion, data-persistence, event-bus         │
│ portfolio           │ analytics, performance, data-persistence, event-bus │
│ trading             │ portfolio, analytics, performance, tax, event-bus   │
│ performance         │ portfolio, trading, data-persistence, event-bus     │
│ tax                 │ trading, performance, data-persistence              │
│ reporting           │ performance, tax, portfolio, data-persistence       │
│ api-gateway         │ ALL domains (orchestration layer)                   │
│ user-interaction    │ api-gateway, event-bus, frontend                    │
│ frontend            │ user-interaction, api-gateway, event-bus            │
│ event-bus           │ infrastructure (core messaging)                     │
│ data-persistence    │ infrastructure (base services)                      │
│ infrastructure      │ NONE (foundation layer)                             │
└─────────────────────┴─────────────────────────────────────────────────────┘
```

### Domain-Communication-Patterns:
- **Synchronous**: Direct API calls für kritische Operationen
- **Asynchronous**: Event-Bus für Cross-Domain-Updates
- **Request-Response**: api-gateway orchestriert Complex-Queries
- **Pub-Sub**: event-bus für Real-time-Updates
- **Batch**: Für Performance-Reports und Analytics

---

## 📊 **Deployment-Architektur mit Domains**

### LXC Container-Layout:
```
LXC aktienanalyse-lxc-120/
├── domain-services/
│   ├── data-ingestion-service/        # Port 8001
│   ├── analytics-service/             # Port 8002
│   ├── portfolio-trading-service/     # Port 8003 (combined)
│   ├── performance-tax-service/       # Port 8004 (combined)
│   ├── reporting-service/             # Port 8005
│   └── frontend-service/              # Port 8006
├── infrastructure-services/
│   ├── api-gateway/                   # Port 443 (HTTPS)
│   ├── event-bus/                     # Redis Cluster
│   ├── data-persistence/              # SQLite + Redis
│   └── monitoring-stack/              # Prometheus + Grafana
└── systemd-services/
    ├── aktienanalyse-ecosystem.service
    ├── redis-cluster.service
    ├── nginx-gateway.service
    └── monitoring.service
```

## ✅ **Vorteile der Domain-Architektur**

1. **Klare Abgrenzung**: Jede Domain hat eine spezifische Hauptfunktion
2. **Modulare Sub-Module**: Domains bestehen aus fokussierten Sub-Modulen
3. **Flexible Kommunikation**: Domains können flexibel andere Domains ansteuern
4. **Single Responsibility**: Jede Domain ist für eine Hauptfunktion verantwortlich
5. **Skalierbarkeit**: Domains können unabhängig entwickelt und deployed werden
6. **Testbarkeit**: Domains haben klare Interfaces und Abhängigkeiten
7. **Wartbarkeit**: Domain-basierte Struktur ist langfristig wartbarer
8. **Team-Struktur**: Teams können Domain-ownership übernehmen

Diese **Domain-Driven Design Architektur** reduziert die Komplexität von 22 projektbasierten Modulen auf **12 focused Domains** mit klaren Verantwortlichkeiten und flexibler Inter-Domain-Kommunikation.