import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/repayments/domain/entities/payment_method.dart';
import 'package:local_lending_app/features/repayments/presentation/bloc/payment_cubit.dart';

class MakePaymentPage extends StatelessWidget {
  const MakePaymentPage({super.key});

  @override
  Widget build(BuildContext context) {
    if (getIt<LendingDataMode>() == LendingDataMode.firebase) {
      return Scaffold(
        appBar: AppBar(title: const Text('Make a Payment')),
        body: const Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text(
              'Online payments are not enabled yet. Contact your lender to '
              'record a bank transfer or cash payment.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';
    return BlocProvider(
      create: (_) => getIt<PaymentCubit>()..load(userId),
      child: const _MakePaymentView(),
    );
  }
}

class _MakePaymentView extends StatelessWidget {
  const _MakePaymentView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PaymentCubit, PaymentState>(
      listener: (context, state) {
        if (state.status == PaymentUiStatus.success) {
          showDialog<void>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Payment successful'),
              content: Text(
                'Reference ${state.receipt?.reference ?? '-'} for ${CurrencyFormatter.format(state.amountRupees)}.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.go('/client/dashboard');
                  },
                  child: const Text('Done'),
                ),
              ],
            ),
          );
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Make a Payment')),
          body: state.status == PaymentUiStatus.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.loans.isEmpty) ...[
                      const Text('No open loans to repay.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => context.go('/loans/apply'),
                        child: const Text('Apply for a loan'),
                      ),
                    ] else ...[
                      DropdownButtonFormField(
                        initialValue: state.selectedLoan,
                        items: state.loans
                            .map(
                              (loan) => DropdownMenuItem(
                                value: loan,
                                child: Text(
                                  '${loan.purpose.label} • ${loan.frequency.label}',
                                ),
                              ),
                            )
                            .toList(),
                        onChanged: (loan) {
                          if (loan != null) {
                            context.read<PaymentCubit>().selectLoan(loan);
                          }
                        },
                        decoration: const InputDecoration(
                          labelText: 'Select loan',
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (state.selectedLoan?.nextDue != null)
                        Text(
                          'Upcoming installment #${state.selectedLoan!.nextDue!.installmentNumber} • ${CurrencyFormatter.format(state.selectedLoan!.nextDue!.outstandingRupees)} due ${AppDateUtils.formatDisplay(state.selectedLoan!.nextDue!.dueDate)}',
                        ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        children: [
                          ActionChip(
                            label: const Text('Full EMI'),
                            onPressed: () {
                              final due =
                                  state
                                      .selectedLoan
                                      ?.nextDue
                                      ?.outstandingRupees ??
                                  0;
                              context.read<PaymentCubit>().setAmount(due);
                            },
                          ),
                          ActionChip(
                            label: const Text('Partial'),
                            onPressed: () {
                              final due =
                                  state
                                      .selectedLoan
                                      ?.nextDue
                                      ?.outstandingRupees ??
                                  0;
                              context.read<PaymentCubit>().setAmount(due / 2);
                            },
                          ),
                          ActionChip(
                            label: const Text('Advance'),
                            onPressed: () {
                              final due =
                                  state
                                      .selectedLoan
                                      ?.nextDue
                                      ?.outstandingRupees ??
                                  0;
                              context.read<PaymentCubit>().setAmount(due * 2);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        key: ValueKey(state.amountRupees),
                        initialValue: state.amountRupees.toStringAsFixed(2),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                        ),
                        onChanged: (value) {
                          final parsed = double.tryParse(value);
                          if (parsed != null) {
                            context.read<PaymentCubit>().setAmount(parsed);
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text('Payment method'),
                      ...[PaymentMethod.upi, PaymentMethod.netBanking].map(
                        (method) => ListTile(
                          selected: state.method == method,
                          leading: Icon(
                            state.method == method
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                          ),
                          title: Text(method.label),
                          subtitle: Text(
                            method == PaymentMethod.upi
                                ? 'Pay with any UPI app'
                                : 'Pay via net banking',
                          ),
                          onTap: () =>
                              context.read<PaymentCubit>().setMethod(method),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: state.status == PaymentUiStatus.processing
                            ? null
                            : () {
                                final auth = context.read<AuthCubit>().state;
                                if (auth is Authenticated) {
                                  context.read<PaymentCubit>().pay(
                                    auth.user.id,
                                  );
                                }
                              },
                        child: Text(
                          state.status == PaymentUiStatus.processing
                              ? 'Processing…'
                              : 'Pay ${CurrencyFormatter.format(state.amountRupees)}',
                        ),
                      ),
                    ],
                  ],
                ),
        );
      },
    );
  }
}
