import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/loan_approvals_cubit.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class LoanApprovalsPage extends StatelessWidget {
  const LoanApprovalsPage({super.key, this.quickActionsOnly = false});

  final bool quickActionsOnly;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoanApprovalsCubit>()..load(),
      child: _ApprovalsView(quickActionsOnly: quickActionsOnly),
    );
  }
}

class _ApprovalsView extends StatelessWidget {
  const _ApprovalsView({required this.quickActionsOnly});

  final bool quickActionsOnly;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(quickActionsOnly ? 'New Loan Requests' : 'Loan Approvals'),
      ),
      body: BlocBuilder<LoanApprovalsCubit, LoanApprovalsState>(
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (quickActionsOnly)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        FilterChip(
                          label: const Text('All'),
                          selected: state.frequencyFilter == null,
                          onSelected: (_) => context
                              .read<LoanApprovalsCubit>()
                              .setFrequencyFilter(null),
                        ),
                        ...[
                          for (final frequency
                              in state.applications
                                  .map((e) => e.frequency)
                                  .toSet())
                            FilterChip(
                              label: Text(frequency.label),
                              selected: state.frequencyFilter == frequency,
                              onSelected: (_) => context
                                  .read<LoanApprovalsCubit>()
                                  .setFrequencyFilter(frequency),
                            ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _selectRequestDate(context, state),
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              state.requestedAfter == null
                                  ? 'Request date'
                                  : 'Since ${AppDateUtils.formatDisplay(state.requestedAfter!)}',
                            ),
                          ),
                        ),
                        if (state.requestedAfter != null)
                          IconButton(
                            onPressed: () => context
                                .read<LoanApprovalsCubit>()
                                .setRequestedAfter(null),
                            tooltip: 'Clear request date',
                            icon: const Icon(Icons.clear),
                          ),
                      ],
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              ...state.visible.map(
                (app) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                app.borrowerName,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                            StatusChip.loan(app.status),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${app.purpose.label} • ${CurrencyFormatter.format(app.requestedAmountRupees)} • ${app.frequency.label} × ${app.tenure}',
                        ),
                        Text(AppDateUtils.formatDisplay(app.requestedAt)),
                        if (app.notes != null) Text(app.notes!),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () =>
                                  context.read<LoanApprovalsCubit>().decide(
                                    UpdateLoanStatusParams(
                                      applicationId: app.id,
                                      status: LoanStatus.approved,
                                    ),
                                  ),
                              child: const Text('Approve'),
                            ),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(0, 40),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              onPressed: () => _reject(context, app),
                              child: const Text('Reject'),
                            ),
                            if (!quickActionsOnly)
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: () => _counter(context, app),
                                child: const Text('Counter-offer'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _selectRequestDate(
    BuildContext context,
    LoanApprovalsState state,
  ) async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: state.requestedAfter ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (selected != null && context.mounted) {
      await context.read<LoanApprovalsCubit>().setRequestedAfter(selected);
    }
  }

  Future<void> _reject(BuildContext context, LoanApplication app) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reject application'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await context.read<LoanApprovalsCubit>().decide(
      UpdateLoanStatusParams(
        applicationId: app.id,
        status: LoanStatus.rejected,
        rejectionReason: reason,
      ),
    );
  }

  Future<void> _counter(BuildContext context, LoanApplication app) async {
    final controller = TextEditingController(
      text: app.requestedAmountRupees.toStringAsFixed(0),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Counter-offer principal'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount (₹)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, double.tryParse(controller.text)),
            child: const Text('Approve with offer'),
          ),
        ],
      ),
    );
    if (amount == null || !context.mounted) return;
    await context.read<LoanApprovalsCubit>().decide(
      UpdateLoanStatusParams(
        applicationId: app.id,
        status: LoanStatus.approved,
        counterOfferPrincipalRupees: amount,
      ),
    );
  }
}
