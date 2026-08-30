# ADR 001 — Clean Architecture

**Status:** Accepted  
**Date:** 2025-01-01  
**Author:** Team

## Context

We need a folder structure that:
- Is easy for multiple engineers to work in simultaneously
- Makes business logic independently testable without Flutter
- Scales to 5+ features without merge conflicts
- Is understandable to AI tools (Antigravity, OpenCode, Cursor)

## Decision

Adopt **Clean Architecture** (as described by Robert Martin, adapted for Flutter) with a per-feature folder structure.

Each feature lives in `lib/features/<name>/` and contains three layers:
1. **domain/** — pure Dart entities, repository interfaces, use cases
2. **data/** — Firestore/API data sources, models, repository implementations
3. **presentation/** — BLoC/Cubit, pages, widgets

## Consequences

✅ Business logic is testable without Firebase or Flutter SDK  
✅ Data sources can be swapped (Firestore → REST API) without touching presentation  
✅ Clear import boundaries — widgets never import from data layer  
⚠️ More boilerplate per feature (~5 files instead of 1)  
⚠️ New engineers need to learn the pattern

---

# ADR 002 — Flutter Flavor System for White-Labeling

**Status:** Accepted  
**Date:** 2025-01-01

## Context

Multiple clients need their own branding, package ID, and feature flags — but sharing all business logic and screens.

## Decision

Use Flutter **product flavors** (Android) + `AppConfig` abstract class pattern.

- One `main_<client>.dart` per client
- One `<client>Config extends AppConfig` per client
- `FlavorConfig.instance` singleton read everywhere
- Android `productFlavors` in `build.gradle.kts` per client

## Consequences

✅ Zero code changes to add a new client  
✅ Each client gets separate APK / Play Store listing  
✅ Feature flags (e.g. admin portal) controllable per client  
⚠️ CI must build one APK per flavor

---

# ADR 003 — Google Sign-In Over SMS/WhatsApp OTP

**Status:** Accepted  
**Date:** 2025-01-01

## Context

Phone OTP (via Firebase Auth or Twilio) costs money per SMS (~₹0.5–₹2/SMS). At scale, this is significant. WhatsApp OTP requires a Business account and per-message costs.

## Decision

Use **Google Sign-In** (Firebase Auth) — completely free.

- Users authenticate with their Google account
- Profile setup (name, phone) happens in a post-auth screen
- Google One Tap available for smooth UX

## Consequences

✅ Zero auth costs  
✅ No phone number required for login  
✅ Faster auth flow (no OTP wait)  
⚠️ Users must have a Google account (99%+ of Android users do)  
⚠️ No phone-based identity verification (can be added separately if needed)

---

# ADR 004 — flutter_bloc for State Management

**Status:** Accepted  
**Date:** 2025-01-01

## Context

Needed a predictable, testable state management solution.

## Decision

Use **flutter_bloc** (Bloc + Cubit). Cubit for simple single-operation flows, Bloc for multi-event complex flows.

All events and states use `freezed` for immutability.

## Consequences

✅ Highly testable with `bloc_test`  
✅ Clear separation of UI and business logic  
✅ DevTools integration for debugging  
⚠️ More boilerplate than setState or Riverpod

---

# ADR 005 — Repayment Frequency Design

**Status:** Accepted  
**Date:** 2025-01-01

## Context

Local lending in India commonly uses daily, weekly, or monthly collection cycles. Biweekly is also common. The EMI calculation and due date logic must handle each correctly.

## Decision

Support 4 frequencies: `daily`, `weekly`, `biweekly`, `monthly`.

- Flat interest rate (common in micro-lending, simpler for borrowers to understand)
- Integer paise arithmetic to avoid floating-point drift
- Sunday skip configurable per client (for daily frequency)
- Monthly: strict calendar month-end clamping (Jan 31 → Feb 28/29)
- All logic centralized in `EmiCalculator` — never inline in UI or BLoC

## Consequences

✅ Handles all real-world micro-lending patterns in India  
✅ Pure Dart, fully unit-testable (37 tests)  
✅ Per-client frequency restrictions via `AppConfig.supportedFrequencies`  
⚠️ Flat rate may differ from reducing-balance loans (add as future option)
