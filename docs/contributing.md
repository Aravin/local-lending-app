# Contributing Guidelines

## Code Style & Standards

1. **Imports**: Always use package imports (`package:local_lending_app/...`), never relative cross-feature imports.
2. **Clean Architecture**: Never import `data/` or Firebase packages in `presentation/` widgets or pages.
3. **State Management**:
   - Use Cubit for single-action/simple states.
   - Use Bloc for multi-event complex business flows.
   - All states and events must be immutable.
4. **Calculations**: All loan calculations must go through `EmiCalculator`. Do not write ad-hoc interest math in UI code.
5. **Linting & Formatting**:
   - `make format` to run `dart format`.
   - `make lint` to verify zero analyzer issues.
   - Lefthook pre-commit hooks will automatically enforce formatting and tests.

## Git Workflow

- Feature branches: `feat/<feature-name>`
- Bug fixes: `fix/<issue-name>`
- All pull requests require passing tests and zero analyzer warnings.
