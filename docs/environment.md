# Environment & Configuration

## Overview

The application relies on two levels of configuration:
1. **Compile-time White-Label Flavors**: Theme colors, assets, default frequency restrictions, client name, and package ID defined in `lib/flavors/clients/`.
2. **Runtime Configuration (.env)**: Optional dynamic backend URLs and feature flags managed via `flutter_dotenv`.

## Setting up .env

Copy the provided `.env.example` to `.env`:
```bash
cp .env.example .env
```

Available keys:
- `API_BASE_URL`: Custom REST API endpoint (leave empty to use Firestore directly).
- `ENABLE_ADMIN_FEATURES`: Override admin capabilities for local testing (`true`/`false`).

## Firebase Integration

Place client-specific `google-services.json` inside the flavor directory:
`android/app/src/localLendingHub/google-services.json`
