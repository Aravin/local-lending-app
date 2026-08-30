# Testing Guide — Local Lending Hub

## Test Strategy

This project targets **≥80% code coverage** across unit, widget, integration, and golden tests.

## Test Types

### Unit Tests (`test/unit/`)
Pure Dart — no Flutter framework needed. Test business logic, BLoCs, and utilities.

```bash
make test-unit
# or
flutter test test/unit/ --no-pub
```

Key test files:

| File | What It Tests |
|---|---|
| `emi_calculator_test.dart` | All 4 frequencies, edge cases (Sunday skip, month-end, zero interest, etc.) |
| `currency_formatter_test.dart` | Indian ₹ formatting, parse, compact |
| `validators_test.dart` | Phone, amount, tenure validators |
| `auth_bloc_test.dart` | All AuthBloc states |
| `loan_bloc_test.dart` | Loan apply (all frequencies), approve, reject |
| `repayment_bloc_test.dart` | List, filter by frequency, mark paid, partial |
| `admin_bloc_test.dart` | Collection sheet, metrics, export |

### Widget Tests (`test/widget/`)
Flutter framework tests. Test that widgets render correctly and respond to interactions.

```bash
make test-widget
flutter test test/widget/ --no-pub
```

Conventions:
- Use `tester.pumpWidget(...)` with `MaterialApp` wrapper
- Wrap with `BlocProvider.value(...)` to inject pre-seeded BLoC state
- Use `find.byKey(const Key('...'))` for precise widget finding
- Use `find.text(...)` for text content assertions

### Integration Tests (`test/integration/`)
Full flow tests using `integration_test` package. These run on a real device or emulator.

```bash
flutter test test/integration/auth_flow_test.dart \
  --device-id <device_id>
```

### Golden Tests (`test/golden/`)
Screenshot regression tests. Fail if pixel output changes unexpectedly.

```bash
# Run golden tests
flutter test test/golden/ --no-pub

# Update golden files (only when intentional UI changes)
flutter test test/golden/ --update-goldens --no-pub
```

> [!WARNING]
> Never run `--update-goldens` casually — it overwrites the baseline screenshots.
> Only do this after intentional UI changes, and commit the new goldens with a clear commit message.

---

## Running Tests with Coverage

```bash
make coverage
# Opens coverage/html/index.html in browser
```

Coverage report excludes:
- `*.g.dart` (generated)
- `*.freezed.dart` (generated)
- `lib/main_*.dart` (entrypoints)

---

## Test Conventions

### Mocking
Use `mocktail` — **never** `mockito`.

```dart
import 'package:mocktail/mocktail.dart';

class MockLoanRepository extends Mock implements LoanRepository {}
class MockGetIt extends Mock implements GetIt {}
```

### BLoC Testing
Use `bloc_test` package for BLoC/Cubit tests:

```dart
blocTest<LoanBloc, LoanState>(
  'emits [loading, success] when apply succeeds',
  build: () {
    when(() => mockUseCase(any())).thenAnswer((_) async => Right(loan));
    return LoanBloc(mockUseCase);
  },
  act: (bloc) => bloc.add(const LoanEvent.apply(params)),
  expect: () => [
    const LoanState.loading(),
    LoanState.success(loan),
  ],
);
```

### EMI Calculator Tests
Critical — all 4 frequencies must be tested:

```dart
for (final frequency in RepaymentFrequency.values) {
  test('works for ${frequency.name}', () { ... });
}
```

Always test:
- Zero interest (principal-only)
- Month-end clamp for monthly (Jan 31 → Feb 28)
- Sunday skip for daily
- Floating-point safety on large amounts (₹10,00,000+)

---

## CI (GitHub Actions — future)

```yaml
# .github/workflows/flutter.yml
- name: Run tests
  run: flutter test --coverage --no-pub

- name: Check coverage
  run: lcov --summary coverage/lcov.info
```
