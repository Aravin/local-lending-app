# Local Lending Hub Documentation

Welcome to the **Local Lending Hub** documentation portal. This repository contains the complete Flutter mobile application source code and architectural documentation for a white-label local lending fintech platform.

## Documentation Index

1. [Architecture Overview](architecture.md) — Clean Architecture layers, BLoC pattern, dependency injection, and error handling.
2. [White-Label Guide](white-label.md) — How to add new tenant clients, customize themes, and build separate APKs/bundles.
3. [Design System](design-system.md) — Color tokens, typography hierarchy, component styling, and Stitch design specifications.
4. [Screen Catalog & Flows](screens.md) — Detailed screen breakdown, UX workflows for borrowers and lenders.
5. [Testing Strategy](testing.md) — Unit, widget, integration, and golden testing guidelines.
6. [AI Tools & Context](ai-tools.md) — Guidelines for Antigravity, OpenCode, and Cursor AI coding assistants.
7. [Architecture Decision Records (ADRs)](adr/decisions.md) — Key technical and product decisions.
8. [Environment & Config](environment.md) — Environment variables, flavors, and Firebase setup.
9. [Deployment Guide](deployment.md) — Android Play Store release workflows and CI/CD pipelines.
10. [Contributing Guidelines](contributing.md) — Coding conventions, PR workflow, and pre-commit hooks.
11. [Changelog](changelog.md) — Version history and release notes.

## Quick Start

```bash
# Setup dependencies and git hooks
make setup

# Run with default client flavor (Local Lending Hub)
make run

# Run unit and widget tests
make test

# Format code
make format
```
