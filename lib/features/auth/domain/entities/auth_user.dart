import 'package:equatable/equatable.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';

/// Represents an authenticated user profile in the application.
class AuthUser extends Equatable {
  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, name, email, role, phoneNumber, avatarUrl];

  AuthUser copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? phoneNumber,
    String? avatarUrl,
  }) {
    return AuthUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
