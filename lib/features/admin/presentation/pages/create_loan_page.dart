import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/create_loan_cubit.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';

class CreateLoanPage extends StatelessWidget {
  const CreateLoanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<CreateLoanCubit>()..load(),
      child: const _CreateLoanView(),
    );
  }
}

class _CreateLoanView extends StatelessWidget {
  const _CreateLoanView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CreateLoanCubit, CreateLoanState>(
      listener: (context, state) {
        if (state.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan disbursed successfully.')),
          );
          context.go('/admin/dashboard');
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Create Loan for User')),
          body: state.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    DropdownButtonFormField(
                      initialValue: state.selectedCustomer,
                      items: state.customers
                          .map(
                            (customer) => DropdownMenuItem(
                              value: customer,
                              child: Text(customer.name),
                            ),
                          )
                          .toList(),
                      onChanged: (customer) {
                        if (customer != null) {
                          context.read<CreateLoanCubit>().selectCustomer(
                            customer,
                          );
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Borrower'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      CurrencyFormatter.format(state.principalRupees),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    Slider(
                      min: FlavorConfig.minLoanAmountRupees,
                      max: FlavorConfig.maxLoanAmountRupees,
                      value: state.principalRupees.clamp(
                        FlavorConfig.minLoanAmountRupees,
                        FlavorConfig.maxLoanAmountRupees,
                      ),
                      onChanged: context.read<CreateLoanCubit>().setPrincipal,
                    ),
                    Text(
                      'Flat interest ${state.ratePercent.toStringAsFixed(0)}% p.a.',
                    ),
                    Slider(
                      min: FlavorConfig.minAnnualInterestRatePercent,
                      max: FlavorConfig.maxAnnualInterestRatePercent,
                      divisions:
                          (FlavorConfig.maxAnnualInterestRatePercent -
                                  FlavorConfig.minAnnualInterestRatePercent)
                              .round(),
                      value: state.ratePercent.clamp(
                        FlavorConfig.minAnnualInterestRatePercent,
                        FlavorConfig.maxAnnualInterestRatePercent,
                      ),
                      label: '${state.ratePercent.toStringAsFixed(0)}%',
                      onChanged: context.read<CreateLoanCubit>().setRate,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: FlavorConfig.supportedFrequencies
                          .map(
                            (frequency) => AppChoiceChip(
                              label: frequency.label,
                              selected: state.frequency == frequency,
                              onSelected: (_) => context
                                  .read<CreateLoanCubit>()
                                  .setFrequency(frequency),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tenure ${state.tenure} ${state.frequency.tenureUnit}',
                    ),
                    Slider(
                      min: state.frequency.minTenure.toDouble(),
                      max: state.frequency.maxTenure.toDouble(),
                      value: state.tenure
                          .clamp(
                            state.frequency.minTenure,
                            state.frequency.maxTenure,
                          )
                          .toDouble(),
                      onChanged: (value) => context
                          .read<CreateLoanCubit>()
                          .setTenure(value.round()),
                    ),
                    DropdownButtonFormField<LoanPurpose>(
                      initialValue: state.purpose,
                      items: LoanPurpose.values
                          .map(
                            (purpose) => DropdownMenuItem(
                              value: purpose,
                              child: Text(purpose.label),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          context.read<CreateLoanCubit>().setPurpose(value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Purpose'),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_month),
                      title: const Text('Disbursement date'),
                      subtitle: Text(
                        AppDateUtils.formatDisplay(
                          state.disbursementDate ?? DateTime.now(),
                        ),
                      ),
                      trailing: const Icon(Icons.edit_calendar),
                      onTap: () => _selectDisbursementDate(context, state),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: state.submitting
                          ? null
                          : context.read<CreateLoanCubit>().submit,
                      child: Text(
                        state.submitting ? 'Creating…' : 'Disburse loan',
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<void> _selectDisbursementDate(
    BuildContext context,
    CreateLoanState state,
  ) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: state.disbursementDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
    );
    if (selected != null && context.mounted) {
      context.read<CreateLoanCubit>().setDisbursementDate(selected);
    }
  }
}
