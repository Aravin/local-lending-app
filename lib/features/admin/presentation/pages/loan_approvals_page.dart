import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/features/admin/domain/repositories/admin_repository.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/loan_approvals_cubit.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class LoanApprovalsPage extends StatelessWidget {
  const LoanApprovalsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LoanApprovalsCubit>()..load(),
      child: const _ApprovalsView(),
    );
  }
}

class _ApprovalsView extends StatelessWidget {
  const _ApprovalsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan Management & Approvals')),
      body: BlocConsumer<LoanApprovalsCubit, LoanApprovalsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.infoMessage != current.infoMessage,
        listener: (context, state) {
          final message = state.errorMessage ?? state.infoMessage;
          if (message == null) return;
          final isError = state.errorMessage != null;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: isError
                    ? Theme.of(context).colorScheme.error
                    : null,
              ),
            );
        },
        builder: (context, state) {
          if (state.loading && state.applications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          final pending = state.visible;
          final awaiting = state.awaitingDisbursement;
          final confirming = state.inConfirmation;
          final issues = state.fundIssues;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: state.frequencyFilter == null,
                    onSelected: (_) => context
                        .read<LoanApprovalsCubit>()
                        .setFrequencyFilter(null),
                  ),
                  for (final frequency
                      in pending.map((e) => e.frequency).toSet())
                    FilterChip(
                      label: Text(frequency.label),
                      selected: state.frequencyFilter == frequency,
                      onSelected: (_) => context
                          .read<LoanApprovalsCubit>()
                          .setFrequencyFilter(frequency),
                    ),
                ],
              ),
              const SizedBox(height: 8),
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
              if (state.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  state.errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 8),
              if (pending.isEmpty &&
                  awaiting.isEmpty &&
                  confirming.isEmpty &&
                  issues.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 32),
                  child: Center(child: Text('No loan requests in this queue.')),
                ),
              if (pending.isNotEmpty) ...[
                const _SectionTitle('Pending requests'),
                ...pending.map(
                  (app) => _ApplicationCard(
                    application: app,
                    busy: state.decidingApplicationId == app.id,
                    disabled: state.isDeciding,
                  ),
                ),
              ],
              if (awaiting.isNotEmpty) ...[
                const _SectionTitle('Awaiting fund release'),
                ...awaiting.map(
                  (app) => _ApplicationCard(
                    application: app,
                    busy: state.decidingApplicationId == app.id,
                    disabled: state.isDeciding,
                  ),
                ),
              ],
              if (issues.isNotEmpty) ...[
                const _SectionTitle('Fund issues'),
                ...issues.map(
                  (app) => _ApplicationCard(
                    application: app,
                    busy: state.decidingApplicationId == app.id,
                    disabled: state.isDeciding,
                  ),
                ),
              ],
              if (confirming.isNotEmpty) ...[
                const _SectionTitle('Confirmation window'),
                ...confirming.map(
                  (app) => _ApplicationCard(
                    application: app,
                    busy: state.decidingApplicationId == app.id,
                    disabled: state.isDeciding,
                  ),
                ),
              ],
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
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({
    required this.application,
    required this.busy,
    required this.disabled,
  });

  final LoanApplication application;
  final bool busy;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final actionsEnabled = !disabled;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    application.borrowerName,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                StatusChip.loan(application.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${application.purpose.label} • ${CurrencyFormatter.format(application.requestedAmountRupees)} • ${application.frequency.label} × ${application.tenure}',
            ),
            Text(AppDateUtils.formatDisplay(application.requestedAt)),
            if (application.notes != null) Text(application.notes!),
            if (application.disbursementDate != null)
              Text(
                'Disbursed ${AppDateUtils.formatDisplay(application.disbursementDate!)}',
              ),
            if (application.status == LoanStatus.disbursed &&
                application.disbursementDate != null)
              Text(
                'Borrower can report a fund issue until ${AppDateUtils.formatDisplay(DisbursementPolicy.confirmationDeadline(application.disbursementDate!).subtract(const Duration(days: 1)))}. EMI starts from the disbursement date if no issue is reported.',
              ),
            if (application.disbursementIssueReason != null)
              Text('Issue: ${application.disbursementIssueReason}'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (application.status == LoanStatus.pending) ...[
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: actionsEnabled
                        ? () => context.read<LoanApprovalsCubit>().decide(
                            UpdateLoanStatusParams(
                              applicationId: application.id,
                              status: LoanStatus.approved,
                            ),
                          )
                        : null,
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Approve'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: actionsEnabled
                        ? () => _reject(context, application)
                        : null,
                    child: const Text('Reject'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: actionsEnabled
                        ? () => _counter(context, application)
                        : null,
                    child: const Text('Counter-offer'),
                  ),
                ],
                if (application.status == LoanStatus.approved ||
                    application.status == LoanStatus.fundIssue)
                  FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size(0, 40),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: actionsEnabled
                        ? () => context.read<LoanApprovalsCubit>().decide(
                            UpdateLoanStatusParams(
                              applicationId: application.id,
                              status: LoanStatus.disbursed,
                            ),
                          )
                        : null,
                    child: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            application.status == LoanStatus.fundIssue
                                ? 'Re-release funds'
                                : 'Release funds',
                          ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
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
