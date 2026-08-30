# OpenCode Context — Local Lending Hub

## Project
Flutter white-label fintech app for local lending communities.
Android-first. Multi-client via Flutter flavors.

## Quick Commands
```bash
make run                    # Run app (localLendingHub flavor)
make test                   # Run all tests
make gen                    # Generate freezed/json code
make lint                   # Run flutter analyze
make format                 # Format all Dart files
make build-apk              # Build debug APK
make coverage               # Run tests + open coverage report
```

## Architecture: Clean Architecture per feature
```
features/<name>/
  data/datasources/   ← Firestore
  data/models/        ← Freezed + JsonSerializable
  data/repositories/  ← implements domain interface
  domain/entities/    ← pure Dart
  domain/repositories/← abstract
  domain/usecases/    ← single-purpose
  presentation/bloc/  ← BLoC/Cubit + states
  presentation/pages/ ← screens
  presentation/widgets/← components
```

## Critical Rules
1. NEVER call Firestore from widgets — go through BLoC → UseCase → Repository
2. NEVER use `Navigator.push()` — use `context.go()` or `context.push()` from go_router
3. NEVER hardcode colors/strings — always from `FlavorConfig.instance`
4. NEVER use `print()` — use logger
5. ALL async ops return `Either<Failure, T>` from dartz
6. ALL monetary values formatted via `CurrencyFormatter.format()` → "₹1,23,456"
7. ALL BLoC events/states must be `@freezed`

## Repayment Frequencies (core domain)
- Supported: `daily | weekly | biweekly | monthly`
- EMI calc: `lib/core/utils/emi_calculator.dart` — do NOT inline
- Daily: may skip Sundays/holidays based on `AppConfig.allowHolidaySkip`
- Monthly: clamp to month-end (Jan 31 → Feb 28)

## Adding a New Client
See `docs/white-label.md`

## Key Files
- `lib/core/utils/emi_calculator.dart` — EMI and schedule calculation
- `lib/core/utils/currency_formatter.dart` — ₹ formatting
- `lib/core/di/injection.dart` — all DI registrations
- `lib/core/router/app_router.dart` — all routes
- `lib/flavors/clients/` — one file per white-label client
