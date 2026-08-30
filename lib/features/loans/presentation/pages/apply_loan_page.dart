import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/features/loans/presentation/bloc/apply_loan_cubit.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';
import 'package:local_lending_app/shared/widgets/emi_calculator_card.dart';
import 'package:local_lending_app/shared/widgets/installment_tile.dart';

class ApplyLoanPage extends StatelessWidget {
  const ApplyLoanPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ApplyLoanCubit>(),
      child: const _ApplyLoanView(),
    );
  }
}

class _ApplyLoanView extends StatelessWidget {
  const _ApplyLoanView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApplyLoanCubit, ApplyLoanState>(
      listener: (context, state) {
        if (state.status == ApplyLoanStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan request submitted for review.')),
          );
          context.go('/loans/status');
        } else if (state.status == ApplyLoanStatus.error &&
            state.errorMessage != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Apply for Loan • Step ${state.step + 1} of 4'),
          ),
          body: Column(
            children: [
              LinearProgressIndicator(value: (state.step + 1) / 4),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (state.step == 0) const _PurposeStep(),
                    if (state.step == 1) const _AmountStep(),
                    if (state.step == 2) const _FrequencyStep(),
                    if (state.step == 3) const _PreviewStep(),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    children: [
                      if (state.step > 0)
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () =>
                                context.read<ApplyLoanCubit>().previousStep(),
                            child: const Text('Back'),
                          ),
                        ),
                      if (state.step > 0) const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: state.status == ApplyLoanStatus.submitting
                              ? null
                              : () => _onPrimary(context, state),
                          child: Text(state.step == 3 ? 'Submit' : 'Continue'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _onPrimary(BuildContext context, ApplyLoanState state) {
    if (state.step < 3) {
      context.read<ApplyLoanCubit>().nextStep();
      return;
    }
    final auth = context.read<AuthCubit>().state;
    if (auth is! Authenticated) return;
    context.read<ApplyLoanCubit>().submit(
      borrowerId: auth.user.id,
      borrowerName: auth.user.name,
      borrowerPhone: auth.user.phoneNumber,
    );
  }
}

class _PurposeStep extends StatelessWidget {
  const _PurposeStep();

  @override
  Widget build(BuildContext context) {
    final selected = context.watch<ApplyLoanCubit>().state.purpose;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What is this loan for?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...LoanPurpose.values.map(
          (purpose) => ListTile(
            selected: selected == purpose,
            leading: Icon(
              selected == purpose
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
            ),
            title: Text(purpose.label),
            subtitle: Text(purpose.description),
            onTap: () => context.read<ApplyLoanCubit>().setPurpose(purpose),
          ),
        ),
      ],
    );
  }
}

class _AmountStep extends StatelessWidget {
  const _AmountStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ApplyLoanCubit>().state;
    final min = FlavorConfig.minLoanAmountRupees;
    final max = FlavorConfig.maxLoanAmountRupees;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How much do you need?',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          CurrencyFormatter.format(state.amountRupees),
          style: Theme.of(context).textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: FlavorConfig.primaryColor,
          ),
        ),
        Slider(
          min: min,
          max: max,
          value: state.amountRupees.clamp(min, max),
          divisions: 99,
          onChanged: (value) => context.read<ApplyLoanCubit>().setAmount(value),
        ),
        Text(
          'Min ${CurrencyFormatter.formatNoDecimal(min)} • Max ${CurrencyFormatter.formatNoDecimal(max)}',
        ),
      ],
    );
  }
}

class _FrequencyStep extends StatelessWidget {
  const _FrequencyStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ApplyLoanCubit>().state;
    final frequencies = FlavorConfig.supportedFrequencies;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose repayment plan',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: frequencies
              .map(
                (frequency) => AppChoiceChip(
                  label: frequency.label,
                  selected: state.frequency == frequency,
                  onSelected: (_) =>
                      context.read<ApplyLoanCubit>().setFrequency(frequency),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 20),
        Text(
          'Interest rate ${state.annualInterestRatePercent.toStringAsFixed(0)}% p.a.',
        ),
        Slider(
          min: FlavorConfig.minAnnualInterestRatePercent,
          max: FlavorConfig.maxAnnualInterestRatePercent,
          divisions:
              (FlavorConfig.maxAnnualInterestRatePercent -
                      FlavorConfig.minAnnualInterestRatePercent)
                  .round(),
          value: state.annualInterestRatePercent.clamp(
            FlavorConfig.minAnnualInterestRatePercent,
            FlavorConfig.maxAnnualInterestRatePercent,
          ),
          label: '${state.annualInterestRatePercent.toStringAsFixed(0)}%',
          onChanged: (value) =>
              context.read<ApplyLoanCubit>().setAnnualInterestRate(value),
        ),
        const SizedBox(height: 8),
        Text('Tenure (${state.frequency.tenureUnit})'),
        Slider(
          min: state.frequency.minTenure.toDouble(),
          max: state.frequency.maxTenure.toDouble(),
          divisions: state.frequency.maxTenure - state.frequency.minTenure,
          value: state.tenure
              .clamp(state.frequency.minTenure, state.frequency.maxTenure)
              .toDouble(),
          label: '${state.tenure}',
          onChanged: (value) =>
              context.read<ApplyLoanCubit>().setTenure(value.round()),
        ),
        Text('${state.tenure} ${state.frequency.tenureUnit}'),
      ],
    );
  }
}

class _PreviewStep extends StatelessWidget {
  const _PreviewStep();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ApplyLoanCubit>().state;
    final schedule = state.schedule;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Review & submit', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          '${state.purpose.label} • ${CurrencyFormatter.format(state.amountRupees)} • ${state.frequency.label} • ${state.annualInterestRatePercent.toStringAsFixed(0)}% p.a.',
        ),
        const SizedBox(height: 16),
        if (schedule != null) ...[
          EmiCalculatorCard(schedule: schedule),
          const SizedBox(height: 16),
          Text(
            'Schedule preview',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          ...schedule.installments
              .take(6)
              .map((item) => InstallmentTile(installment: item)),
          if (schedule.installments.length > 6)
            Text('+ ${schedule.installments.length - 6} more installments'),
        ],
      ],
    );
  }
}
