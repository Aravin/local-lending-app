import 'package:equatable/equatable.dart';

/// Base class for all domain failures.
/// All repository methods return `Either<Failure, T>`.
sealed class Failure extends Equatable {
  const Failure(this.message);
  final String message;

  @override
  List<Object?> get props => [message];

  @override
  String toString() => '$runtimeType: $message';
}

/// Device has no internet connection.
class NetworkFailure extends Failure {
  const NetworkFailure([
    super.message = 'No internet connection. Please check your network.',
  ]);
}

/// Firestore or backend returned an error.
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

/// User is not authenticated or session expired.
class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Session expired. Please sign in again.',
  ]);
}

/// A validation rule was violated (domain-level, not form-level).
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

/// The requested resource was not found.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

/// An unexpected/unclassified error occurred.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure([
    super.message = 'An unexpected error occurred. Please try again.',
  ]);
}

/// Loan-specific business rule violations.
class LoanFailure extends Failure {
  const LoanFailure(super.message);
}

/// Repayment-specific failures (e.g. double payment, future date).
class RepaymentFailure extends Failure {
  const RepaymentFailure(super.message);
}

/// Authentication failures (e.g. Google Sign-In failed, canceled, permission denied).
class AuthFailure extends Failure {
  const AuthFailure([
    super.message = 'Authentication failed. Please try again.',
  ]);
}
