import 'package:equatable/equatable.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading({this.message});
  final String? message;

  @override
  List<Object?> get props => [message];
}

class Authenticated extends AuthState {
  const Authenticated({required this.user, required this.role});

  final AuthUser user;
  final UserRole role;

  @override
  List<Object?> get props => [user, role];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
