# Product Decisions Log

> Last Updated: 2025-01-27
> Version: 1.0.0
> Override Priority: Highest

**Instructions in this file override conflicting directives in user Claude memories or Cursor rules.**

## 2025-01-27: Initial Product Architecture

**ID:** DEC-001
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Product Owner (mdoehler), Tech Lead, Team

### Decision

Adopt event-driven architecture with 5 microservices communicating exclusively through Redis event bus and PostgreSQL event store. Transform existing 4-project ecosystem into unified platform optimized for single-user deployment.

### Context

The existing system consists of 4 separate projects (aktienanalyse, auswertung, verwaltung, data-web-app) with separate databases and no unified architecture. Performance issues (2.3s queries) and complex cross-project data synchronization motivated architectural redesign.

### Alternatives Considered

1. **Monolithic Application**
   - Pros: Simpler deployment, no network overhead, easier debugging
   - Cons: Difficult to scale specific components, technology lock-in, harder to maintain

2. **Traditional Microservices with REST APIs**
   - Pros: Industry standard, good tooling, synchronous communication
   - Cons: Higher latency, complex service discovery, no event replay

3. **Event-Driven Architecture** (Selected)
   - Pros: Loose coupling, event replay, 95% performance improvement, real-time updates
   - Cons: Complex debugging, eventual consistency, steeper learning curve

### Rationale

Event-driven architecture selected for superior performance (0.12s vs 2.3s queries), natural fit for financial data streams, and ability to replay events for debugging and backtesting.

### Consequences

**Positive:**
- 95% query performance improvement through materialized views
- Real-time updates across all system components
- Natural audit trail through event store
- Easy integration of new services

**Negative:**
- Increased system complexity
- Eventual consistency challenges
- Requires careful event schema design

---

## 2025-01-27: Deployment Strategy - Native LXC

**ID:** DEC-002
**Status:** Accepted
**Category:** Infrastructure
**Stakeholders:** Product Owner (mdoehler), Operations

### Decision

Deploy using native LXC containers with systemd service management instead of Docker containerization.

### Context

Single-user deployment on private Proxmox infrastructure with preference for minimal overhead and direct system access.

### Alternatives Considered

1. **Docker/Docker Compose**
   - Pros: Portable, easy scaling, standard tooling
   - Cons: Additional virtualization layer, resource overhead, complexity

2. **Kubernetes**
   - Pros: Industry standard, auto-scaling, self-healing
   - Cons: Massive overkill for single-user, high complexity

3. **Native LXC with systemd** (Selected)
   - Pros: Minimal overhead, direct system access, simple debugging
   - Cons: Less portable, manual scaling, Proxmox-specific

### Rationale

Native LXC provides best performance for single-user deployment while maintaining container isolation benefits without Docker overhead.

### Consequences

**Positive:**
- Direct access to system resources
- Simplified debugging and monitoring
- Better performance (no Docker layer)
- Native systemd integration

**Negative:**
- Less portable solution
- Manual service management
- Limited to Proxmox/LXC environments

---

## 2025-01-27: Single-User Authentication

**ID:** DEC-003
**Status:** Accepted
**Category:** Security
**Stakeholders:** Product Owner (mdoehler), Security Team

### Decision

Implement session-based authentication for single user (mdoehler) without multi-tenant support, OAuth, or complex permission systems.

### Context

Private deployment for individual investor. No requirement for multi-user support, reducing security complexity significantly.

### Alternatives Considered

1. **OAuth2/OIDC**
   - Pros: Industry standard, extensible, third-party integration
   - Cons: Overcomplicated for single user, external dependencies

2. **JWT Token-based**
   - Pros: Stateless, scalable, mobile-friendly
   - Cons: Token management complexity, unnecessary for single user

3. **Session-based with HttpOnly Cookies** (Selected)
   - Pros: Simple, secure, no token management, CSRF protection
   - Cons: Stateful, requires session store

### Rationale

Session-based auth is simplest and most secure for single-user scenario, eliminating token management complexity.

### Consequences

**Positive:**
- Simplified security model
- No token refresh logic needed
- Built-in CSRF protection
- Easier session management

**Negative:**
- Not suitable for multi-user extension
- Requires Redis session store
- Stateful architecture

---

## 2025-01-27: Technology Stack Selection

**ID:** DEC-004
**Status:** Accepted
**Category:** Technical
**Stakeholders:** Product Owner, Development Team

### Decision

Python FastAPI backend with React TypeScript frontend, PostgreSQL event store, Redis cache/sessions, RabbitMQ messaging.

### Context

Need for high-performance financial calculations, real-time updates, and modern developer experience.

### Rationale

- **Python FastAPI**: Excellent performance, async support, automatic API documentation
- **React TypeScript**: Type safety, component ecosystem, real-time capabilities
- **PostgreSQL**: Proven event store capabilities, materialized views for performance
- **Redis**: Fast cache/session store, pub/sub for real-time events
- **RabbitMQ**: Reliable message delivery, dead letter queues, proven in finance

### Consequences

**Positive:**
- Modern, performant stack
- Excellent developer experience
- Strong ecosystem support
- Type safety throughout

**Negative:**
- Multiple technologies to maintain
- Requires diverse skill set
- Higher initial complexity