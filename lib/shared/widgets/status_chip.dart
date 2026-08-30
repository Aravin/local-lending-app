import 'package:flutter/material.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.color, super.key});

  factory StatusChip.installment(InstallmentStatus status) {
    return switch (status) {
      InstallmentStatus.paid => const StatusChip(
        label: 'Paid',
        color: Color(0xFF059669),
      ),
      InstallmentStatus.partial => const StatusChip(
        label: 'Partial',
        color: Color(0xFF2563EB),
      ),
      InstallmentStatus.overdue => const StatusChip(
        label: 'Overdue',
        color: Color(0xFFBA1A1A),
      ),
      InstallmentStatus.upcoming => const StatusChip(
        label: 'Upcoming',
        color: Color(0xFFD97706),
      ),
      InstallmentStatus.skipped => const StatusChip(
        label: 'Skipped',
        color: Color(0xFF6D7A77),
      ),
    };
  }

  factory StatusChip.loan(LoanStatus status) {
    return switch (status) {
      LoanStatus.pending => const StatusChip(
        label: 'Pending',
        color: Color(0xFFD97706),
      ),
      LoanStatus.approved => const StatusChip(
        label: 'Approved',
        color: Color(0xFF059669),
      ),
      LoanStatus.rejected => const StatusChip(
        label: 'Rejected',
        color: Color(0xFFBA1A1A),
      ),
      LoanStatus.disbursed => const StatusChip(
        label: 'Disbursed',
        color: Color(0xFF2563EB),
      ),
      LoanStatus.fundIssue => const StatusChip(
        label: 'Fund issue',
        color: Color(0xFFD97706),
      ),
      LoanStatus.active => const StatusChip(
        label: 'Active',
        color: Color(0xFF0D9488),
      ),
      LoanStatus.overdue => const StatusChip(
        label: 'Overdue',
        color: Color(0xFFBA1A1A),
      ),
      LoanStatus.closed => const StatusChip(
        label: 'Closed',
        color: Color(0xFF6D7A77),
      ),
      LoanStatus.cancelled => const StatusChip(
        label: 'Cancelled',
        color: Color(0xFF6D7A77),
      ),
    };
  }

  factory StatusChip.kyc(KycStatus status) {
    return switch (status) {
      KycStatus.pending => const StatusChip(
        label: 'Pending',
        color: Color(0xFFD97706),
      ),
      KycStatus.submitted => const StatusChip(
        label: 'Submitted',
        color: Color(0xFF2563EB),
      ),
      KycStatus.verified => const StatusChip(
        label: 'Verified',
        color: Color(0xFF059669),
      ),
      KycStatus.rejected => const StatusChip(
        label: 'Rejected',
        color: Color(0xFFBA1A1A),
      ),
      KycStatus.expired => const StatusChip(
        label: 'Renewal due',
        color: Color(0xFFD97706),
      ),
    };
  }

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}
