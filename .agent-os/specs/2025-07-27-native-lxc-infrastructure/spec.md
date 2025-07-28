# Spec Requirements Document

> Spec: Native LXC Infrastructure Setup
> Created: 2025-07-27
> Status: Planning

## Overview

Create a build system that generates a ready-to-deploy LXC template containing the complete stock-analysis ecosystem. The build process runs on the current development machine and produces a template package (tar.gz) that includes all installation scripts, configuration files, and the full product setup, ready to be deployed on any Proxmox host.

## User Stories

### LXC Template Build System

As a developer, I want to run a build script on my development machine that generates a complete LXC template package, so that I can distribute a ready-to-deploy stock-analysis system without manual installation steps.

The workflow involves running a build script that creates all necessary installation scripts, configuration files, systemd service definitions, and packages them into an LXC template structure. When this template is deployed on a Proxmox host, it will automatically set up the complete stock-analysis ecosystem including PostgreSQL, Redis, RabbitMQ, Python environments, and all five microservices.

### Event-Driven Communication Infrastructure

As a developer, I want to have PostgreSQL Event-Store, Redis cluster, and RabbitMQ properly configured, so that services can communicate through events with optimal performance.

This includes setting up PostgreSQL 15+ with event store schema, configuring a 3-node Redis cluster for high availability, installing RabbitMQ with appropriate exchanges and queues, and ensuring all systems are accessible to the microservices.

### Monitoring and Health Checks

As an operator, I want basic health check endpoints for all services, so that I can monitor system status and detect issues early.

Each service should expose a /health endpoint that verifies database connections, message queue availability, and basic service functionality, enabling integration with monitoring tools like Zabbix.

## Spec Scope

1. **Build System Creation** - Develop scripts that run on the build machine to generate the LXC template
2. **Installation Scripts** - Create automated setup scripts that will run inside the container during deployment
3. **Configuration Templates** - Generate all configuration files for services, databases, and system components
4. **Service Definitions** - Create systemd service files for all five microservices with proper dependencies
5. **Template Packaging** - Package everything into a distributable LXC template format (tar.gz)

## Out of Scope

- Application code implementation for the 5 services
- Frontend setup or Caddy reverse proxy configuration
- Zabbix monitoring installation (only health endpoints)
- SSL certificate configuration
- Production API keys or credentials

## Expected Deliverable

1. A build system (`lxc-build/`) that generates LXC templates when run on the development machine
2. A complete LXC template package (tar.gz) containing all installation scripts and configurations
3. When deployed, the template automatically installs: PostgreSQL 15+, Redis cluster, RabbitMQ, Python 3.11+, uv, and all stock-analysis services
4. Documentation for running the build process and deploying the generated template on Proxmox hosts

## Spec Documentation

- Tasks: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/tasks.md
- Technical Specification: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/technical-spec.md
- Database Schema: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/database-schema.md
- Tests Specification: @.agent-os/specs/2025-07-27-native-lxc-infrastructure/sub-specs/tests.md