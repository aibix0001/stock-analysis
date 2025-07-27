# Spec Requirements Document

> Spec: Native LXC Infrastructure Setup
> Created: 2025-07-27
> Status: Planning

## Overview

Establish the foundational native LXC infrastructure for the stock-analysis ecosystem with systemd service management, Python virtual environments using uv, and core database/messaging systems. This implementation aligns with the "no Docker" deployment strategy documented in decisions.md.

## User Stories

### Infrastructure Setup and Service Management

As a system administrator, I want to set up native LXC containers with systemd service templates, so that I can deploy and manage the 5 microservices efficiently without Docker overhead.

The workflow involves creating a Debian 12 LXC container, configuring network settings (10.1.1.120), installing all required system packages, setting up systemd service templates for each microservice, and establishing Python virtual environments using uv for isolated dependencies.

### Event-Driven Communication Infrastructure

As a developer, I want to have PostgreSQL Event-Store, Redis cluster, and RabbitMQ properly configured, so that services can communicate through events with optimal performance.

This includes setting up PostgreSQL 15+ with event store schema, configuring a 3-node Redis cluster for high availability, installing RabbitMQ with appropriate exchanges and queues, and ensuring all systems are accessible to the microservices.

### Monitoring and Health Checks

As an operator, I want basic health check endpoints for all services, so that I can monitor system status and detect issues early.

Each service should expose a /health endpoint that verifies database connections, message queue availability, and basic service functionality, enabling integration with monitoring tools like Zabbix.

## Spec Scope

1. **LXC Container Configuration** - Set up Debian 12 container with network configuration and system packages
2. **Systemd Service Templates** - Create reusable templates for Python microservices with proper dependencies
3. **Database Infrastructure** - Install and configure PostgreSQL 15+ with event store schema and user setup
4. **Messaging Infrastructure** - Set up Redis 3-node cluster and RabbitMQ with exchanges/queues
5. **Python Environment Setup** - Configure uv for virtual environment management across all services

## Out of Scope

- Application code implementation for the 5 services
- Frontend setup or Caddy reverse proxy configuration
- Zabbix monitoring installation (only health endpoints)
- SSL certificate configuration
- Production API keys or credentials

## Expected Deliverable

1. Fully configured LXC container with all system dependencies installed and systemd service templates ready
2. PostgreSQL Event-Store operational with initial schema and Redis cluster accepting connections
3. All services can start via systemd and report healthy status through /health endpoints

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/technical-spec.md
- Database Schema: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/database-schema.md
- Tests Specification: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/tests.md