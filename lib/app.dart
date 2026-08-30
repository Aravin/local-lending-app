import 'package:flutter/material.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/theme/app_theme.dart';

/// Root widget of the application.
/// Reads branding from [FlavorConfig] — never hardcodes any values.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: FlavorConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(),
      // TODO(routing): Replace with go_router once core/router/app_router.dart is set up
      home: Scaffold(
        appBar: AppBar(title: Text(FlavorConfig.appName)),
        body: const Center(child: Text('Local Lending Hub — scaffold ready')),
      ),
    );
  }
}
