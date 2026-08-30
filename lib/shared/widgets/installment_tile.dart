import 'package:flutter/material.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/domain/entities/repayment_installment.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class InstallmentTile extends StatelessWidget {
  const InstallmentTile({required this.installment, super.key, this.onTap});

  final RepaymentInstallment installment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainer,
        child: Text(
          '#${installment.installmentNumber}',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        CurrencyFormatter.format(installment.amountRupees),
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        AppDateUtils.formatDisplay(installment.dueDate),
        style: theme.textTheme.bodySmall,
      ),
      trailing: StatusChip.installment(installment.status),
    );
  }
}
