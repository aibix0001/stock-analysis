# Technical Stack

> Last Updated: 2025-01-27
> Version: 1.0.0

## Frontend Stack

- **Application Framework:** React 18
- **Language:** TypeScript 4.9+
- **UI Component Library:** Material UI (MUI) 5.x
- **Charts Library:** TradingView Lightweight Charts
- **State Management:** Redux Toolkit with RTK Query
- **Real-time Updates:** WebSocket + Server-Sent Events (SSE)
- **Build Tool:** Vite 5.x
- **Package Manager:** npm (Node 18+)

## Backend Stack

- **Application Framework:** Python 3.11+ with FastAPI
- **Database System:** PostgreSQL 15+ (Event-Store)
- **Cache/Sessions:** Redis 7+
- **Message Queue:** RabbitMQ 3.12+
- **ORM:** SQLAlchemy 2.0+
- **Data Validation:** Pydantic 2.x
- **Task Queue:** Celery 5.x
- **Package Management:** uv (Astral)

## Infrastructure

- **Container Technology:** LXC (Linux Containers)
- **Service Management:** systemd
- **Reverse Proxy:** Caddy 2.x (with automatic SSL)
- **Monitoring:** Zabbix 6.x
- **Operating System:** Debian 12 (Bookworm)

## External Services

- **Development API:** Alpha Vantage (500 calls/day free tier)
- **Production API:** EODHD (€240-600/year)
- **Trading API:** Bitpanda Pro
- **SSL Certificates:** Let's Encrypt (via Caddy)

## Deployment

- **CI/CD Pipeline:** GitHub Actions
- **Deployment Target:** Native LXC on Proxmox
- **Service Discovery:** systemd socket activation
- **Log Management:** systemd journal + Zabbix
- **Backup Strategy:** PostgreSQL WAL + Redis RDB snapshots

## Development Tools

- **Version Control:** Git + GitHub
- **API Documentation:** OpenAPI 3.1 / Swagger
- **Testing Framework:** pytest (Python) + Jest (TypeScript)
- **Code Quality:** Ruff (Python) + ESLint (TypeScript)
- **IDE:** VS Code with Python + TypeScript extensions

## Architecture Patterns

- **Event Sourcing:** All state changes as events
- **CQRS:** Command-Query Responsibility Segregation
- **Materialized Views:** PostgreSQL views for read optimization
- **Domain-Driven Design:** Service boundaries by business domain
- **API Gateway:** Unified HTTPS entry point on port 443