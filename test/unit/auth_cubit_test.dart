import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;
  late AuthCubit cubit;

  const adminUser = AuthUser(
    id: 'admin_1',
    name: 'Admin Officer',
    email: 'admin@locallending.in',
    role: UserRole.admin,
  );

  const clientUser = AuthUser(
    id: 'client_1',
    name: 'Ramesh Patel',
    email: 'ramesh@patel.in',
    role: UserRole.client,
  );

  setUp(() {
    repository = _MockAuthRepository();
    cubit = AuthCubit(authRepository: repository);
  });

  tearDown(() => cubit.close());

  test('admin sign-in defaults to admin portal', () async {
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(adminUser));

    await cubit.signInWithGoogle();

    final state = cubit.state;
    expect(state, isA<Authenticated>());
    expect((state as Authenticated).role, UserRole.admin);
    expect(state.user.role, UserRole.admin);
    expect(state.canSwitchPortal, isTrue);
  });

  test('admin can toggle between admin and client portals', () async {
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(adminUser));
    await cubit.signInWithGoogle();

    cubit.togglePortal();
    expect((cubit.state as Authenticated).role, UserRole.client);
    expect((cubit.state as Authenticated).user.role, UserRole.admin);

    cubit.togglePortal();
    expect((cubit.state as Authenticated).role, UserRole.admin);
  });

  test('client cannot switch to admin portal', () async {
    when(
      () => repository.signInWithGoogle(),
    ).thenAnswer((_) async => const Right(clientUser));
    await cubit.signInWithGoogle();

    cubit.switchPortal(UserRole.admin);

    final state = cubit.state as Authenticated;
    expect(state.role, UserRole.client);
    expect(state.canSwitchPortal, isFalse);
  });
}
