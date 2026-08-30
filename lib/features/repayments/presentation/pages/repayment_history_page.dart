import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/repayments/presentation/bloc/history_cubit.dart';
import 'package:local_lending_app/shared/widgets/installment_tile.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class RepaymentHistoryPage extends StatelessWidget {
  const RepaymentHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';
    return BlocProvider(
      create: (_) => getIt<HistoryCubit>()..load(userId),
      child: const _HistoryView(),
    );
  }
}

class _HistoryView extends StatelessWidget {
  const _HistoryView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Repayment History')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final loan = state.selectedLoan;
          if (state.loans.isEmpty) {
            return const Center(
              child: Text(
                'No loans yet. Apply for a loan to see your schedule.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              DropdownButtonFormField(
                initialValue: loan,
                items: state.loans
                    .map(
                      (item) => DropdownMenuItem(
                        value: item,
                        child: Text(
                          '${item.purpose.label} • ${item.frequency.label}',
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    context.read<HistoryCubit>().selectLoan(value);
                  }
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Payment reminders'),
                subtitle: const Text('Notify before each installment is due'),
                value: state.remindersEnabled,
                onChanged: context.read<HistoryCubit>().toggleReminders,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: loan == null
                      ? null
                      : () => context.read<HistoryCubit>().downloadStatement(),
                  icon: const Icon(Icons.download),
                  label: const Text('Download statement / receipts'),
                ),
              ),
              if (loan != null) ...[
                Text('Schedule', style: Theme.of(context).textTheme.titleSmall),
                ...loan.schedule.installments.map(
                  (item) => InstallmentTile(installment: item),
                ),
              ],
              const SizedBox(height: 12),
              Text(
                'Payment ledger',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (state.records.isEmpty)
                const Text('No payments recorded yet.')
              else
                ...state.records.map(
                  (record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(CurrencyFormatter.format(record.amountRupees)),
                    subtitle: Text(
                      '${record.method.label} • ${AppDateUtils.formatDisplay(record.paidAt)}',
                    ),
                    trailing: StatusChip(
                      label: record.isPartial ? 'Partial' : 'Paid',
                      color: const Color(0xFF059669),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
