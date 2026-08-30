import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/router/app_router.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/theme/app_theme.dart';

/// Root widget of the application.
/// Reads branding from [FlavorConfig] — never hardcodes any values.
class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<AuthCubit>()..checkAuthStatus(),
      child: MaterialApp.router(
        title: FlavorConfig.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
