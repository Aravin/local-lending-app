# Changelog

All notable changes to this project will be documented in this file.

## Unreleased

### Added
- Borrower loan application status tracking (`/loans/status`) with timeline, dashboard CTA, and post-submit navigation.
- Admin KYC review queue (`/admin/kyc`) with approve/reject.
- KYC completion date and annual renewal: verification is valid for 1 year, then borrowers must complete KYC again.

## [1.0.0+1] - 2026-08-29

### Added
- Multi-client White-label architecture with `AppConfig` and `FlavorConfig`.
- Pure-Dart `EmiCalculator` supporting 4 repayment frequencies (`daily`, `weekly`, `biweekly`, `monthly`) with edge-case handling (Sunday skip, month-end clamping, zero-interest loans).
- Clean Architecture layered folder structure for auth, loans, repayments, and admin features.
- Full Material 3 design system implementation adhering to the Kinship Lending System spec.
- CurrencyFormatter for Indian Rupee notation (`₹1,23,456.78`).
- Strict linting, formatting rules, and Lefthook pre-commit hooks.
- 50+ unit tests covering domain calculation, formatting, and validation.
- Complete documentation suite (`docs/`).
- AI assistant instruction files for Antigravity, OpenCode, and Cursor.
