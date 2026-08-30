import 'package:dartz/dartz.dart';
import 'package:local_lending_app/core/error/failures.dart';
import 'package:local_lending_app/features/auth/domain/entities/auth_user.dart';

abstract class AuthRepository {
  /// Sign in using Google Sign-In and Firebase Auth.
  Future<Either<Failure, AuthUser>> signInWithGoogle();

  /// Signs out current session.
  Future<Either<Failure, void>> signOut();

  /// Gets the currently authenticated user if session exists.
  Future<Either<Failure, AuthUser?>> getCurrentUser();

  /// Stream of authentication state changes.
  Stream<AuthUser?> get authStateChanges;
}
