import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _admin = AuthUser(
  id: 'admin_1',
  name: 'Admin User',
  email: 'admin@example.com',
  role: UserRole.admin,
);

void main() {
  late _MockAuthRepository repository;
  late AuthCubit authCubit;

  setUp(() async {
    FlavorConfig.instance = LocalLendingHubConfig();
    await getIt.reset();
    configureDependencies(useMocks: true);

    repository = _MockAuthRepository();
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(_admin));
    authCubit = AuthCubit(authRepository: repository);
    await authCubit.signInWithGoogle();
  });

  tearDown(() => authCubit.close());

  testWidgets('shows repayment mix counts with readable labels', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(),
        home: BlocProvider.value(
          value: authCubit,
          child: const AdminDashboardPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(tester.takeException(), isNull);
    expect(find.text('Repayment mix'), findsOneWidget);
    expect(find.textContaining('open loan'), findsOneWidget);
    expect(find.text('Daily'), findsOneWidget);
    expect(find.text('Weekly'), findsOneWidget);
    expect(find.text('Biweekly'), findsOneWidget);
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });
}
