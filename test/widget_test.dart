import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/app.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/flavors/clients/local_lending_hub.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    FlavorConfig.instance = LocalLendingHubConfig();
    mockAuthRepository = MockAuthRepository();

    when(
      () => mockAuthRepository.getCurrentUser(),
    ).thenAnswer((_) async => const Right(null));

    when(
      () => mockAuthRepository.authStateChanges,
    ).thenAnswer((_) => Stream.value(null));

    getIt.reset();
    configureDependencies(useMocks: true);
    getIt.unregister<AuthRepository>();
    getIt.registerLazySingleton<AuthRepository>(() => mockAuthRepository);
    getIt.unregister<AuthCubit>();
    getIt.registerFactory<AuthCubit>(() => AuthCubit(authRepository: getIt()));
  });

  testWidgets('App renders secure Google sign-in on Login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    expect(find.text(FlavorConfig.appName), findsWidgets);
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Borrower Portal'), findsOneWidget);
  });

  testWidgets(
    'Successful Google login as Client navigates to Client Dashboard',
    (WidgetTester tester) async {
      const clientUser = AuthUser(
        id: 'client_1',
        name: 'Ramesh Patel',
        email: 'ramesh@patel.in',
        role: UserRole.client,
      );

      when(
        () => mockAuthRepository.signInWithGoogle(),
      ).thenAnswer((_) async => const Right(clientUser));

      await tester.pumpWidget(const App());
      await tester.pumpAndSettle();

      // Tap Google sign-in
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      // Verify Client Dashboard is visible
      expect(find.text('Client / Borrower Portal'), findsOneWidget);
      expect(
        find.text('No active loan yet. Apply to get started.'),
        findsOneWidget,
      );
      expect(find.text('Apply for Loan'), findsOneWidget);
      expect(find.text('NEXT EMI DUE'), findsNothing);
      expect(find.text('Pay EMI Online'), findsNothing);
    },
  );

  testWidgets('Successful Google login as Admin navigates to Admin Dashboard', (
    WidgetTester tester,
  ) async {
    const adminUser = AuthUser(
      id: 'admin_1',
      name: 'Admin Officer',
      email: 'admin@locallending.in',
      role: UserRole.admin,
    );

    when(
      () => mockAuthRepository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(adminUser));

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    // Verify Admin Dashboard is visible
    expect(find.text('Admin & Lender Console'), findsOneWidget);
    expect(find.text('Total Disbursed'), findsOneWidget);
    expect(find.text('Daily Collection Sheet'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to client view'));
    await tester.pumpAndSettle();

    expect(find.text('Client / Borrower Portal'), findsOneWidget);
    expect(find.byTooltip('Switch to admin view'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to admin view'));
    await tester.pumpAndSettle();

    expect(find.text('Admin & Lender Console'), findsOneWidget);
  });

  testWidgets('Client login does not show portal switch', (
    WidgetTester tester,
  ) async {
    const clientUser = AuthUser(
      id: 'client_1',
      name: 'Ramesh Patel',
      email: 'ramesh@patel.in',
      role: UserRole.client,
    );

    when(
      () => mockAuthRepository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(clientUser));

    await tester.pumpWidget(const App());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Client / Borrower Portal'), findsOneWidget);
    expect(find.byTooltip('Switch to admin view'), findsNothing);
    expect(find.byTooltip('Switch to client view'), findsNothing);
  });
}
