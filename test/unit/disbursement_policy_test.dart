import 'package:flutter_test/flutter_test.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

void main() {
  final disbursedOn = DateTime(2026, 8, 30);

  test('confirmation window covers disbursement day and the next day', () {
    expect(
      DisbursementPolicy.confirmationDeadline(disbursedOn),
      DateTime(2026, 9, 1),
    );
    expect(
      DisbursementPolicy.isWithinConfirmationWindow(
        disbursementDate: disbursedOn,
        now: DateTime(2026, 8, 30, 18),
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.isWithinConfirmationWindow(
        disbursementDate: disbursedOn,
        now: DateTime(2026, 8, 31),
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.isWithinConfirmationWindow(
        disbursementDate: disbursedOn,
        now: DateTime(2026, 9, 1),
      ),
      isFalse,
    );
  });

  test('borrower can report a fund issue only while disbursed in window', () {
    expect(
      DisbursementPolicy.canReportIssue(
        status: LoanStatus.disbursed,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 8, 31),
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.canReportIssue(
        status: LoanStatus.approved,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 8, 31),
      ),
      isFalse,
    );
    expect(
      DisbursementPolicy.canReportIssue(
        status: LoanStatus.disbursed,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 9, 1),
      ),
      isFalse,
    );
  });

  test('EMI starts from disbursement date after the window if no issue', () {
    expect(
      DisbursementPolicy.hasEmiStarted(
        status: LoanStatus.disbursed,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 8, 31),
      ),
      isFalse,
    );
    expect(
      DisbursementPolicy.hasEmiStarted(
        status: LoanStatus.disbursed,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 9, 1),
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.hasEmiStarted(
        status: LoanStatus.fundIssue,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 9, 2),
        issueReportedAt: DateTime(2026, 8, 30),
      ),
      isFalse,
    );
  });

  test('resolved status becomes active after confirmation', () {
    expect(
      DisbursementPolicy.resolvedStatus(
        status: LoanStatus.disbursed,
        disbursementDate: disbursedOn,
        now: DateTime(2026, 9, 1),
      ),
      LoanStatus.active,
    );
  });

  test('allows approve then disburse then fund issue', () {
    expect(
      DisbursementPolicy.isAllowedTransition(
        LoanStatus.pending,
        LoanStatus.approved,
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.isAllowedTransition(
        LoanStatus.approved,
        LoanStatus.disbursed,
      ),
      isTrue,
    );
    expect(
      DisbursementPolicy.isAllowedTransition(
        LoanStatus.pending,
        LoanStatus.disbursed,
      ),
      isFalse,
    );
  });
}
