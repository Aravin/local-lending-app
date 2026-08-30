import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/shared/widgets/logout_action.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

const _user = AuthUser(
  id: 'client_1',
  name: 'Ramesh Patel',
  email: 'ramesh@patel.in',
  role: UserRole.client,
);

void main() {
  late _MockAuthRepository repository;
  late AuthCubit cubit;

  setUp(() async {
    repository = _MockAuthRepository();
    cubit = AuthCubit(authRepository: repository);
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(_user));
    await cubit.signInWithGoogle();
  });

  tearDown(() => cubit.close());

  Future<void> pumpAction(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: LogoutAction()),
        ),
      ),
    );
  }

  testWidgets('cancel keeps the session signed in', (tester) async {
    await pumpAction(tester);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsNothing);
    verifyNever(() => repository.signOut());
    expect(cubit.state, isA<Authenticated>());
  });

  testWidgets('confirm signs the user out', (tester) async {
    when(() => repository.signOut()).thenAnswer((_) async => const Right(null));
    await pumpAction(tester);

    await tester.tap(find.byTooltip('Log out'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Log out'));
    await tester.pumpAndSettle();

    verify(() => repository.signOut()).called(1);
    expect(cubit.state, isA<Unauthenticated>());
  });
}
