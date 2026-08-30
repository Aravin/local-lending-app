import 'package:flutter/material.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.instance = LocalLendingHubConfig();
  configureDependencies();
  runApp(const App());
}
