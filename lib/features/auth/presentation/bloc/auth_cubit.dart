import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit({required this.authRepository}) : super(const Unauthenticated());

  final AuthRepository authRepository;

  /// Production Google Sign-In with Firebase Auth
  Future<void> signInWithGoogle() async {
    emit(const AuthLoading(message: 'Signing in with Google...'));
    final result = await authRepository.signInWithGoogle();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(Authenticated(user: user, role: user.role)),
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

  /// Switch the active portal. Only users with admin access can leave admin
  /// view for the client portal (and switch back). Defaults stay admin.
  void switchPortal(UserRole portal) {
    final current = state;
    if (current is! Authenticated || !current.canSwitchPortal) return;
    if (current.role == portal) return;
    emit(current.copyWith(role: portal));
  }

  void togglePortal() {
    final current = state;
    if (current is! Authenticated || !current.canSwitchPortal) return;
    switchPortal(current.role.isAdmin ? UserRole.client : UserRole.admin);
  }
}
