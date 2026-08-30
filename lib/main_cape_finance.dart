import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/flavors/clients/cape_finance.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set the active white-label config for Cape Finance
  FlavorConfig.instance = CapeFinanceConfig();

  // 2. Lock to portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Configure DI container
  configureDependencies();

  // 4. Run the application
  runApp(const App());
}
