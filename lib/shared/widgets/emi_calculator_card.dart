import 'package:flutter/material.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/domain/entities/repayment_schedule.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

class EmiCalculatorCard extends StatelessWidget {
  const EmiCalculatorCard({required this.schedule, super.key});

  final RepaymentSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = FlavorConfig.primaryColor;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'EMI breakdown',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          _row(
            theme,
            'Installment',
            CurrencyFormatter.withFrequencySuffix(
              schedule.installmentAmountRupees,
              schedule.frequency.suffix,
            ),
            emphasize: true,
            color: primary,
          ),
          _row(
            theme,
            'Principal',
            CurrencyFormatter.format(schedule.principalRupees),
          ),
          _row(
            theme,
            'Interest rate',
            '${schedule.annualInterestRatePercent.toStringAsFixed(0)}% p.a.',
          ),
          _row(
            theme,
            'Total interest',
            CurrencyFormatter.format(schedule.totalInterestRupees),
          ),
          _row(
            theme,
            'Total repayable',
            CurrencyFormatter.format(schedule.totalRepayableRupees),
          ),
          _row(
            theme,
            'Tenure',
            '${schedule.tenure} ${schedule.frequency.tenureUnit}',
          ),
        ],
      ),
    );
  }

  Widget _row(
    ThemeData theme,
    String label,
    String value, {
    bool emphasize = false,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
