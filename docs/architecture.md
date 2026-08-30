# Local Lending Hub — Architecture Guide

## Overview

This app follows **Clean Architecture** with a strict separation of concerns. Each feature is self-contained and follows the same layered structure.

## Layer Responsibilities

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│   BLoC/Cubit · Pages · Widgets · Router     │
│   Knows about: domain entities, use cases   │
├─────────────────────────────────────────────┤
│               Domain Layer                   │
│   Entities · Use Cases · Repo Interfaces    │
│   Knows about: nothing (pure Dart)          │
├─────────────────────────────────────────────┤
│                 Data Layer                   │
│   Firestore · Dio · Models · Repo Impl      │
│   Knows about: domain interfaces            │
└─────────────────────────────────────────────┘
```

### Domain Layer (pure Dart — no Flutter, no Firebase)
- **Entities** — core business objects (e.g. `Loan`, `RepaymentInstallment`)
- **Repository interfaces** — abstract contracts (e.g. `LoanRepository`)
- **Use cases** — single-purpose operations (e.g. `ApplyForLoanUseCase`)

### Data Layer
- **Data models** — JSON-serializable, Firestore-mapped (use `freezed + json_serializable`)
- **Data sources** — Firestore collections, Dio API calls
- **Repository implementations** — implement domain interfaces, return `Either<Failure, T>`

### Presentation Layer
- **BLoC/Cubit** — receives events, calls use cases, emits states
- **Pages** — full-screen widgets, connected to BLoC via `BlocProvider`
- **Widgets** — reusable UI components (no business logic)

## Data Flow

```
User tap
  → Page calls BLoC event
    → BLoC calls UseCase
      → UseCase calls Repository interface
        → Repository impl calls DataSource (Firestore)
          → Returns Either<Failure, Entity>
        → Repository maps model → entity
      → UseCase returns Either<Failure, Entity>
    → BLoC emits new state
  → Page rebuilds via BlocBuilder
```

## Dependency Injection (get_it)

All dependencies registered in `lib/core/di/injection.dart`:

```dart
// Data sources
getIt.registerLazySingleton<LoanRemoteDataSource>(
  () => LoanFirestoreDataSource(getIt()),
);
// Repositories
getIt.registerLazySingleton<LoanRepository>(
  () => LoanRepositoryImpl(getIt()),
);
// Use cases (factory — new instance each time)
getIt.registerFactory(() => ApplyForLoanUseCase(getIt()));
// BLoCs (factory — scoped to screen lifecycle)
getIt.registerFactory(() => LoanBloc(getIt(), getIt()));
```

## Error Handling

All repository methods return `Either<Failure, T>`:

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}
class NetworkFailure extends Failure { ... }
class FirestoreFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class UnauthorizedFailure extends Failure { ... }
```

BLoC consumes with `.fold()`:
```dart
result.fold(
  (failure) => emit(state.copyWith(status: Status.error, error: failure.message)),
  (data)    => emit(state.copyWith(status: Status.success, data: data)),
);
```

## Navigation (go_router)

All routes declared in `lib/core/router/app_router.dart`. Use:
```dart
context.go('/dashboard');          // replace stack
context.push('/loans/apply');      // push onto stack
context.pop();                     // go back
```
Never use `Navigator.push()` directly.

## State Management

**Use Cubit when:** simple async operation (load list, toggle, fetch single item)  
**Use Bloc when:** multiple event types, complex transitions, side effects

```dart
// Cubit example
class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit(this._useCase) : super(const DashboardState.initial());
  
  Future<void> loadDashboard() async {
    emit(const DashboardState.loading());
    final result = await _useCase();
    result.fold(
      (f) => emit(DashboardState.error(f.message)),
      (d) => emit(DashboardState.loaded(d)),
    );
  }
}
```

## White-Label System

See `docs/white-label.md` for the full guide.
