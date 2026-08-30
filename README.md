# Local Lending Hub

A modern, white-label fintech mobile app built with Flutter for digital lending and micro-finance operations in India.

## Key Features

- **White-Label Multi-Client Architecture**: Flavor-based build system allowing zero-code-change tenant configurations with custom brand colors, logos, and feature flags.
- **Comprehensive Repayment Support**: Full domain engine supporting **Daily**, **Weekly**, **Biweekly**, and **Monthly** loan schedules with integer paise precision, Sunday/holiday shifts, and month-end clamping.
- **Clean Architecture**: Strict separation of concerns (Domain, Data, Presentation) per feature.
- **Design System**: Material 3 implementation based on the Kinship Lending System (Stitch) spec.
- **Free Google Sign-In Auth**: Zero-cost authentication model without SMS/WhatsApp OTP expenses.
- **Pre-commit Automation**: Built-in Git hooks via Lefthook for formatting, linting, and automated testing.
- **AI-Ready Context**: Pre-configured guidelines for Antigravity, OpenCode, and Cursor.

## Quick Start

```bash
# Setup dependencies and git hooks
make setup

# Run the app (default flavor: localLendingHub)
make run

# Run all tests (50+ unit & widget tests)
make test

# Format code
make format

# Analyze code
make lint
```

## Documentation

Full architectural guides, design tokens, screen flows, and deployment steps are available in the [`docs/`](docs/) directory:

- [Architecture Overview](docs/architecture.md)
- [White-Label Guide](docs/white-label.md)
- [Design System](docs/design-system.md)
- [Screen Catalog & Flows](docs/screens.md)
- [Testing Strategy](docs/testing.md)
- [Deployment Guide](docs/deployment.md)
- [Architecture Decision Records (ADRs)](docs/adr/decisions.md)
- [AI Tools & Context](docs/ai-tools.md)
