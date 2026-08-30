import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Set the active white-label config FIRST — before anything else reads it.
  FlavorConfig.instance = LocalLendingHubConfig();

  // 2. Lock to portrait orientation (lending apps don't need landscape).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Initialize Firebase for this flavor's google-services.json.
  await Firebase.initializeApp();

  // 4. Wire up all dependencies (repositories, blocs, use cases via get_it).
  const useMocks = bool.fromEnvironment('USE_MOCKS');
  configureDependencies(useMocks: useMocks);

  // 5. Run the app.
  runApp(const App());
}
