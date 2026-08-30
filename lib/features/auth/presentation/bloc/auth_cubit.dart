import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.authRepository}) : super(const Unauthenticated());

  final AuthRepository authRepository;

  /// Production Google Sign-In with Firebase Auth
  Future<void> signInWithGoogle({required UserRole role}) async {
    emit(const AuthLoading(message: 'Signing in with Google...'));
    final result = await authRepository.signInWithGoogle(role: role);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user, role: role)),
    );
  }

  /// Production Sign Out
  Future<void> signOut() async {
    emit(const AuthLoading(message: 'Signing out...'));
    final result = await authRepository.signOut();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const Unauthenticated()),
    );
  }

  /// Check active user session on app launch
  Future<void> checkAuthStatus() async {
    final result = await authRepository.getCurrentUser();
    result.fold((_) => emit(const Unauthenticated()), (user) {
      if (user != null) {
        emit(Authenticated(user: user, role: user.role));
      } else {
        emit(const Unauthenticated());
      }
    });
  }
}
