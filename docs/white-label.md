# White-Label Guide — Adding a New Client

## Overview

Each client (white-label tenant) is a Flutter **product flavor**. They share 100% of the business logic, screens, and navigation. Only branding, config, and assets differ.

## Step-by-Step: Adding a New Client

### 1. Create the AppConfig class

Create `lib/flavors/clients/<client_name>.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:local_lending_app/flavors/app_config.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';

class AcmeLendingConfig extends AppConfig {
  @override
  String get appName => 'Acme Lending';

  @override
  String get packageName => 'com.acmelending.app';

  @override
  Color get primaryColor => const Color(0xFF1A73E8);

  @override
  Color get secondaryColor => const Color(0xFF34A853);

  @override
  Color get tertiaryColor => const Color(0xFF1E40AF);

  @override
  String get logoAssetPath => 'assets/images/acme_lending/logo.png';

  @override
  String get apiBaseUrl => 'https://api.acmelending.com/v1';

  @override
  String get currencySymbol => '₹';

  @override
  String get phoneCountryCode => '+91';

  @override
  bool get enableAdminFeatures => true;

  @override
  List<RepaymentFrequency> get supportedFrequencies => [
    RepaymentFrequency.weekly,
    RepaymentFrequency.monthly,
  ];

  @override
  bool get allowHolidaySkip => false;
}
```

### 2. Create the entrypoint

Create `lib/main_acme_lending.dart`:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/flavors/clients/acme_lending.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = AcmeLendingConfig();
  await Firebase.initializeApp();
  configureDependencies();
  runApp(const App());
}
```

### 3. Add Android flavor

In `android/app/build.gradle`, add to `productFlavors`:

```groovy
acmeLending {
    dimension "app"
    applicationId "com.acmelending.app"
    resValue "string", "app_name", "Acme Lending"
}
```

### 4. Create flavor-specific Android resources

```
android/app/src/acmeLending/
├── AndroidManifest.xml       (copy from localLendingHub, update package)
└── res/
    └── mipmap-*/             (launcher icons for this client)
```

### 5. Add flavor assets

```
assets/images/acme_lending/
├── logo.png
├── logo_dark.png
└── splash.png
```

### 6. Add to Makefile

```makefile
run-acme:
	flutter run --flavor acmeLending -t lib/main_acme_lending.dart

build-acme:
	flutter build apk --flavor acmeLending -t lib/main_acme_lending.dart
```

### 7. Firebase config (per-flavor)

Each flavor needs its own `google-services.json` in:
```
android/app/src/acmeLending/google-services.json
```

Get this from the Firebase Console → Project Settings → Add App.

---

## Supported Frequencies per Client

Use `AppConfig.supportedFrequencies` to limit which repayment frequencies a client offers. The Apply for Loan form will only show the allowed options.

```dart
// Client that only supports weekly + monthly:
List<RepaymentFrequency> get supportedFrequencies => [
  RepaymentFrequency.weekly,
  RepaymentFrequency.monthly,
];

// Client that supports all frequencies:
List<RepaymentFrequency> get supportedFrequencies =>
    RepaymentFrequency.values;
```

---

## Build Commands

```bash
# Run
flutter run --flavor acmeLending -t lib/main_acme_lending.dart

# Debug APK
flutter build apk --flavor acmeLending -t lib/main_acme_lending.dart

# Release APK
flutter build apk --release --flavor acmeLending -t lib/main_acme_lending.dart

# Play Store Bundle
flutter build appbundle --release --flavor acmeLending -t lib/main_acme_lending.dart
```

---

## Checklist

- [ ] `lib/flavors/clients/<client>.dart` created
- [ ] `lib/main_<client>.dart` entrypoint created
- [ ] Android `productFlavors` block added
- [ ] `android/app/src/<client>/` directory with manifest + icons
- [ ] `assets/images/<client>/` directory with logo + splash
- [ ] `google-services.json` added for this flavor's Firebase project
- [ ] Makefile targets added
- [ ] Config values tested with `flutter analyze`
