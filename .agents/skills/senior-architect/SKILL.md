---
name: senior-architect
description: Comprehensive software architecture skill for designing scalable, maintainable systems using ReactJS, NextJS, NodeJS, FastAPI, Flutter, etc. Includes system design patterns, tech stack decision frameworks, and modularity analysis.
---

# Senior Architect

This skill provides high-level architectural guidance, ensuring the system is scalable, maintainable, and aligned with business goals.

## Core Competencies

### 1. System Design
- **Microservices vs. Monolith**: Evaluate trade-offs based on team size and domain complexity.
- **Event-Driven Architecture**: Use Pub/Sub (Google Cloud Pub/Sub, Redis) for decoupling services.
- **Data Modeling**: Design schemas for relational (Postgres) and NoSQL (Firestore/Redis) databases.

### 2. Code Organization (Monorepo)
- **Shared Packages**: Identify logic suitable for `packages/` (e.g., UI kit, i18n, types).
- **Feature Modules**: encapsulate features rather than technical layers.
- **Dependency Rules**: Enforce strict boundaries (e.g., UI cannot import DB logic directly).

### 3. Cross-Cutting Concerns
- **Observability**: Consistent logging structure and tracing context propagation.
- **Security**: centralized auth verification and secret management.
- **Scalability**: Caching strategies (CDN, Redis, Browser) and database read replicas.

## Decision Framework

When evaluating a new technology or pattern:
1.  **Problem Fit**: Does it solve a real problem we have?
2.  **Cost**: What is the maintenance overhead?
3.  **Team**: Does the team have the skills (or capacity to learn)?
4.  **Lock-in**: How hard is it to replace later?

## When to Use

- "How should we structure the notification system?"
- "Review this DB schema for performance."
- "Should we put this logic in the frontend or backend?"
- "Design a scalable folder structure for the new module."
