import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/domain/entities/customer_profile.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/create_loan_cubit.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_purpose.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/app_choice_chip.dart';
import 'package:local_lending_app/shared/widgets/emi_calculator_card.dart';

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
      listenWhen: (previous, current) =>
          previous.success != current.success ||
          previous.errorMessage != current.errorMessage,
      listener: (context, state) {
        if (state.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Loan disbursed successfully.')),
          );
          context.go('/admin/dashboard');
          return;
        }
        if (state.errorMessage != null && !state.loading) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
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
                    _BorrowerField(state: state),
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
                    Text(
                      'Repayment frequency',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                      key: ValueKey(state.purpose),
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
                    if (state.schedule != null) ...[
                      const SizedBox(height: 16),
                      EmiCalculatorCard(schedule: state.schedule!),
                    ],
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

class _BorrowerField extends StatefulWidget {
  const _BorrowerField({required this.state});

  final CreateLoanState state;

  @override
  State<_BorrowerField> createState() => _BorrowerFieldState();
}

class _BorrowerFieldState extends State<_BorrowerField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _displayText(widget.state));
  }

  @override
  void didUpdateWidget(covariant _BorrowerField oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = _displayText(widget.state);
    if (_controller.text != next) {
      _controller.text = next;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _displayText(CreateLoanState state) {
    final selected = state.selectedCustomer;
    if (selected == null) return '';
    if (selected.phone.isEmpty) return selected.name;
    return '${selected.name}  ${selected.phone}';
  }

  @override
  Widget build(BuildContext context) {
    final customers = widget.state.customers;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          key: const Key('borrower-field'),
          readOnly: true,
          showCursor: false,
          mouseCursor: SystemMouseCursors.click,
          controller: _controller,
          onTap: _openPicker,
          decoration: InputDecoration(
            labelText: 'Borrower',
            hintText: customers.isEmpty
                ? 'No KYC-submitted borrowers'
                : 'Select a borrower',
            suffixIcon: IconButton(
              tooltip: 'Select borrower',
              icon: const Icon(Icons.arrow_drop_down),
              onPressed: _openPicker,
            ),
          ),
        ),
        if (customers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Only borrowers who have submitted KYC appear here.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
      ],
    );
  }

  Future<void> _openPicker() async {
    final cubit = context.read<CreateLoanCubit>();
    final selected = await showModalBottomSheet<CustomerProfile>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return _BorrowerPickerSheet(
          customers: cubit.state.customers,
          selectedId: cubit.state.selectedCustomer?.id,
        );
      },
    );
    if (selected != null && mounted) {
      cubit.selectCustomer(selected);
    }
  }
}

class _BorrowerPickerSheet extends StatefulWidget {
  const _BorrowerPickerSheet({
    required this.customers,
    required this.selectedId,
  });

  final List<CustomerProfile> customers;
  final String? selectedId;

  @override
  State<_BorrowerPickerSheet> createState() => _BorrowerPickerSheetState();
}

class _BorrowerPickerSheetState extends State<_BorrowerPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final needle = _query.trim().toLowerCase();
    final matches = widget.customers.where((customer) {
      if (needle.isEmpty) return true;
      return customer.name.toLowerCase().contains(needle) ||
          customer.phone.toLowerCase().contains(needle) ||
          customer.email.toLowerCase().contains(needle);
    }).toList();
    final height = MediaQuery.sizeOf(context).height * 0.7;

    return SafeArea(
      child: SizedBox(
        height: height,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select borrower',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('borrower-search-field'),
                autofocus: true,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search),
                  hintText: 'Search name, phone, or email',
                ),
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: matches.isEmpty
                    ? const Center(child: Text('No matching borrowers.'))
                    : ListView.builder(
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final customer = matches[index];
                          final selected = customer.id == widget.selectedId;
                          return ListTile(
                            title: Text(customer.name),
                            subtitle: Text(
                              [
                                if (customer.phone.isNotEmpty) customer.phone,
                                if (customer.email.isNotEmpty) customer.email,
                              ].join(' • '),
                            ),
                            trailing: selected ? const Icon(Icons.check) : null,
                            selected: selected,
                            onTap: () => Navigator.of(context).pop(customer),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
