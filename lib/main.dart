import 'package:flutter/material.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

/// Offline / widget-test entry. Uses in-memory mock lending data.
/// Real client builds use [main_local_lending_hub.dart] or
/// [main_cape_finance.dart], which default to Firebase (`USE_MOCKS` is false).
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = LocalLendingHubConfig();
  configureDependencies(useMocks: true);
  runApp(const App());
}
