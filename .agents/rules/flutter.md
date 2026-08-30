# Antigravity Rules — Local Lending Hub Flutter App

## Code Generation
- After creating/modifying any `@freezed` class or `@JsonSerializable` model, run `make gen`
- Never manually edit `.g.dart` or `.freezed.dart` files
- All BLoC events and states MUST use `@freezed`

## File Creation Rules
- New feature? Create ALL three layers: `data/`, `domain/`, `presentation/`
- New screen? Also create: widget test in `test/widget/`, golden test in `test/golden/`
- New BLoC? Also create: unit test in `test/unit/` covering all states
- New utility? Also create: unit test with edge cases

## Flutter-Specific
- Run `flutter analyze` after every file change — zero warnings/errors required
- Run `dart format lib/ test/` after writing new code
- Use `flutter_lints` rules — no `print()`, no relative imports across features
- Use `const` constructors everywhere possible
- Prefer `SizedBox` over `Container` when only size is needed
- Prefer `Padding` widget over `Container(padding: ...)`

## State Management
- Simple state (single async op): use `Cubit`
- Complex state (multiple events, side effects): use `Bloc`
- Never call `emit()` after `close()` — check `!isClosed` guard
- All BLoC states must be handled in UI (never ignore `BlocBuilder` states)

## Repayment Frequency — Critical
- EMI calculation ONLY through `EmiCalculator` — never inline math in UI or BLoC
- Always handle all 4 frequencies: `daily`, `weekly`, `biweekly`, `monthly`
- Monthly edge case: always use `DateUtils.clampToMonthEnd()` for due date calculation
- Never assume 30 days = 1 month

## White-Label
- NEVER hardcode: colors, app name, logo path, API URL, package name
- Always read from `FlavorConfig.instance`
- `AppConfig.supportedFrequencies` controls which frequencies a client allows

## Testing
- Minimum 80% code coverage — check with `make coverage`
- Use `mocktail` for mocking (never `mockito`)
- Test file mirrors source file: `lib/core/utils/emi_calculator.dart` → `test/unit/emi_calculator_test.dart`
- Golden tests: update with `flutter test --update-goldens` only when intentional

## Imports Order (enforced by analyzer)
1. dart: imports
2. package: imports
3. Relative imports (only within same feature)
