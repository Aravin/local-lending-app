# AI Agent Context — Local Lending Hub

> This file is read by **Antigravity IDE**, **OpenCode**, **Cursor**, and any other AI coding tools.
> Keep it updated when architecture decisions change.

---

## What This Project Is

A **Flutter white-label fintech app** for digital lending in India.
- Borrowers apply for loans and track repayments
- Admins/lenders manage applications, collections, and reports
- Multiple clients ("flavors") share one codebase — each gets their own branding + config

**Platform:** Android-first, iOS added later  
**Currency:** ₹ (INR), Indian number formatting  
**Auth:** Google Sign-In (Firebase Auth) — free, no OTP costs  

---

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter 3.44.x, Dart 3.12.x |
| State | `flutter_bloc` ^9 (Cubit for simple, Bloc for complex) |
| Navigation | `go_router` ^15 |
| Auth | `firebase_auth` + `google_sign_in` |
| Database | `cloud_firestore` |
| HTTP | `dio` ^5 |
| DI | `get_it` ^8 |
| Models | `freezed` + `json_serializable` |
| Error handling | `dartz` — `Either<Failure, T>` |
| Charts | `fl_chart` ^1 |
| Forms | `reactive_forms` ^18 |

---

## Architecture

**Clean Architecture** per feature:

```
features/
└── loans/
    ├── data/
    │   ├── datasources/   ← Firestore / API calls
    │   ├── models/        ← JSON/Freezed models (with .g.dart)
    │   └── repositories/  ← implements domain interface
    ├── domain/
    │   ├── entities/      ← pure Dart classes (no Flutter, no Firebase)
    │   ├── repositories/  ← abstract interface
    │   └── usecases/      ← single-purpose, testable
    └── presentation/
        ├── bloc/          ← BLoC/Cubit + states + events
        ├── pages/         ← full-screen widgets
        └── widgets/       ← reusable screen components
```

**Rules:**
- Widgets NEVER import from `data/` layer directly
- All async ops return `Either<Failure, T>` from domain layer
- BLoC events and states use `freezed` (immutable)
- Navigation: only `go_router` — never `Navigator.push()`
- All strings in `l10n/` ARB files — never hardcode UI text
- Always use **package imports** (`package:local_lending_app/...`), never relative

---

## White-Label System

Each client = one Flutter **flavor** + one config file:

```dart
// lib/flavors/clients/local_lending_hub.dart
class LocalLendingHubConfig extends AppConfig {
  @override String get appName => 'Local Lending Hub';
  @override Color get primaryColor => const Color(0xFF0D9488);
  // ...
}
```

**Never hardcode** colors, strings, logos, or API URLs.  
Always read from `FlavorConfig.instance`.

**To add a new client:** See `docs/white-label.md`

---

## Repayment Frequencies

The app supports 4 repayment frequencies — this is core business logic:

| Frequency | Tenure Unit | Range | Key Edge Case |
|---|---|---|---|
| Daily | days | 7–90 | Sunday/holiday skip |
| Weekly | weeks | 4–52 | Day-of-week consistency |
| Biweekly | fortnights | 2–26 | Strict 14-day intervals |
| Monthly | months | 1–36 | Month-end clamp (Jan 31 → Feb 28) |

EMI calculation is in `lib/core/utils/emi_calculator.dart` — pure Dart, no dependencies.  
Use **flat interest rate** (common in Indian local lending).

---

## Key Conventions

```dart
// ✅ Currency — always use CurrencyFormatter
CurrencyFormatter.format(1234567.50)  // "₹12,34,567.50"

// ✅ Error handling
final result = await loanRepository.applyForLoan(params);
result.fold(
  (failure) => emit(LoanState.error(failure.message)),
  (loan) => emit(LoanState.success(loan)),
);

// ✅ Navigation
context.go('/dashboard');
context.push('/loans/apply');

// ✅ BLoC state emission
emit(state.copyWith(status: LoanStatus.loading));

// ❌ Never do this
Navigator.push(context, MaterialPageRoute(builder: (_) => SomeScreen()));
print('debug');  // use logger instead
```

---

## Running the App

```bash
# Run (default flavor)
make run

# Run specific flavor
make run FLAVOR=localLendingHub

# Build APK
make build-apk FLAVOR=localLendingHub

# All tests
make test

# Generate code (freezed, json)
make gen

# Lint
make lint

# Format
make format
```

---

## File Map

| Task | Look Here |
|---|---|
| Add a new client | `lib/flavors/clients/` + `android/app/src/` |
| Change theme | `lib/theme/app_theme.dart` |
| Change colors | `lib/theme/app_colors.dart` |
| EMI calculation | `lib/core/utils/emi_calculator.dart` |
| DI registration | `lib/core/di/injection.dart` |
| Navigation routes | `lib/core/router/app_router.dart` |
| Translations | `lib/l10n/*.arb` |
| Tests | `test/unit/`, `test/widget/`, `test/integration/` |

---

## Related Docs

- `docs/architecture.md` — Detailed architecture guide
- `docs/white-label.md` — How to add a new client
- `docs/design-system.md` — Colors, typography, components
- `docs/testing.md` — Test strategy and coverage
- `docs/ai-tools.md` — AI tools configuration
