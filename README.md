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

### Data source modes

- `flutter run lib/main.dart` uses the in-memory mock data source for offline
  development.
- Flavor entrypoints initialize Firebase and use Firestore by default.
- Use in-memory lending data explicitly for offline development:

  ```bash
  flutter run --flavor localLendingHub \
    -t lib/main_local_lending_hub.dart \
    --dart-define=USE_MOCKS=true
  ```

### Granting admin access

Admin access is derived from a trusted Firebase Authentication custom claim.
It cannot be assigned in the Firebase Authentication dashboard. Copy the
user's UID from the dashboard, then run:

```bash
make set-admin
```

The script prompts for the UID and sets `admin: true` with the Firebase Admin
SDK. It uses `GOOGLE_APPLICATION_CREDENTIALS` when set, otherwise a local
service-account JSON outside this repo. Never commit that JSON or ship the
Admin SDK in the Flutter app. The user must sign out and sign in again after
the claim changes. Firestore Security Rules should protect
all lender-only collections and mutations with
`request.auth.token.admin == true`; client-side route guards are only a UX
layer and are not an authorization boundary.

Deploy the trusted backend, Firestore rules, and KYC Storage rules to the
Firebase project used by the selected flavor:

```bash
firebase deploy --only functions,firestore:rules --project YOUR_FIREBASE_PROJECT_ID
firebase deploy --only storage:kyc --project YOUR_FIREBASE_PROJECT_ID
```

Until these rules are deployed, Firebase's default deny rules will surface as
`cloud_firestore/permission-denied` when a signed-in borrower loads the home
screen.

KYC documents are stored in the dedicated
`gs://cape-finance-kyc-265372728533` bucket. Its access rules are defined in
`storage.rules` and deployed through the `kyc` Firebase Storage target. KYC
submission is handled by the `submitKyc` callable, which verifies both uploaded
documents before creating the Firestore record.

Loan balances are changed only by the `recordRepayment` callable. Until a
payment-gateway webhook is integrated, only authenticated admins can confirm
received electronic, bank-transfer, or cash payments; borrowers cannot
self-declare a successful payment.

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
