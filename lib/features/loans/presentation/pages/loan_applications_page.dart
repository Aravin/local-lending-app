import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/features/loans/presentation/bloc/loan_applications_cubit.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';
import 'package:local_lending_app/shared/widgets/status_timeline.dart';

class LoanApplicationsPage extends StatelessWidget {
  const LoanApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';
    return BlocProvider(
      create: (_) => getIt<LoanApplicationsCubit>()..load(userId),
      child: const _LoanApplicationsView(),
    );
  }
}

class _LoanApplicationsView extends StatelessWidget {
  const _LoanApplicationsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Loan application status')),
      body: BlocConsumer<LoanApplicationsCubit, LoanApplicationsState>(
        listenWhen: (previous, current) =>
            previous.errorMessage != current.errorMessage ||
            previous.infoMessage != current.infoMessage,
        listener: (context, state) {
          final message = state.errorMessage ?? state.infoMessage;
          if (message == null) return;
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          if (state.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.errorMessage != null) {
            return Center(child: Text(state.errorMessage!));
          }
          if (state.applications.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('No loan applications yet.'),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.push('/loans/apply'),
                      child: const Text('Apply for a loan'),
                    ),
                  ],
                ),
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () {
              final auth = context.read<AuthCubit>().state;
              final id = auth is Authenticated ? auth.user.id : '';
              return context.read<LoanApplicationsCubit>().load(id);
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: state.applications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _ApplicationCard(application: state.applications[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ApplicationCard extends StatelessWidget {
  const _ApplicationCard({required this.application});

  final LoanApplication application;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${application.purpose.label} loan',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                StatusChip.loan(application.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              CurrencyFormatter.format(application.requestedAmountRupees),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${application.frequency.label} × ${application.tenure} ${application.frequency.tenureUnit}',
            ),
            Text(
              'Applied ${AppDateUtils.formatDisplay(application.requestedAt)}',
            ),
            const SizedBox(height: 8),
            Text(application.trackingMessage()),
            if (application.rejectionReason != null) ...[
              const SizedBox(height: 8),
              Text('Reason: ${application.rejectionReason}'),
            ],
            if (application.counterOfferPrincipalRupees != null) ...[
              const SizedBox(height: 4),
              Text(
                'Counter-offer ${CurrencyFormatter.format(application.counterOfferPrincipalRupees!)}',
              ),
            ],
            if (application.canReportDisbursementIssue()) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _reportIssue(context, application),
                icon: const Icon(Icons.report_gmailerrorred_outlined),
                label: const Text('Fund not received'),
              ),
            ],
            const SizedBox(height: 16),
            StatusTimeline(steps: _stepsFor(application)),
          ],
        ),
      ),
    );
  }

  Future<void> _reportIssue(
    BuildContext context,
    LoanApplication application,
  ) async {
    final controller = TextEditingController(text: 'Funds not received');
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Report fund issue'),
        content: TextField(
          controller: controller,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'What went wrong?',
            hintText: 'Funds not received in my account',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Report issue'),
          ),
        ],
      ),
    );
    if (reason == null || reason.trim().isEmpty || !context.mounted) return;
    await context.read<LoanApplicationsCubit>().reportFundIssue(
      applicationId: application.id,
      reason: reason.trim(),
    );
  }

  List<StatusStep> _stepsFor(LoanApplication application) {
    final status = application.status;
    final appliedSubtitle = AppDateUtils.formatDisplay(application.requestedAt);
    final reviewedSubtitle = application.reviewedAt == null
        ? null
        : AppDateUtils.formatDisplay(application.reviewedAt!);
    return [
      StatusStep(
        title: 'Applied',
        subtitle: appliedSubtitle,
        state: StatusStepState.completed,
      ),
      StatusStep(
        title: 'Under review',
        subtitle: status == LoanStatus.pending ? 'Lender is reviewing' : null,
        state: status == LoanStatus.pending
            ? StatusStepState.current
            : StatusStepState.completed,
      ),
      if (status == LoanStatus.rejected || status == LoanStatus.cancelled)
        StatusStep(
          title: status.label,
          subtitle: reviewedSubtitle ?? application.rejectionReason,
          state: StatusStepState.failed,
        )
      else ...[
        StatusStep(
          title: 'Decision',
          subtitle: status == LoanStatus.pending
              ? 'Waiting for lender'
              : reviewedSubtitle ?? status.label,
          state: status == LoanStatus.pending
              ? StatusStepState.upcoming
              : StatusStepState.completed,
        ),
        StatusStep(
          title: 'Disbursement',
          subtitle: status == LoanStatus.approved
              ? 'Waiting for fund release'
              : status == LoanStatus.disbursed
              ? 'Confirm receipt within 2 days'
              : status == LoanStatus.fundIssue
              ? 'Fund issue reported'
              : status.isCollectable || status == LoanStatus.closed
              ? 'Funds released'
              : 'After approval',
          state: status == LoanStatus.approved
              ? StatusStepState.current
              : status == LoanStatus.disbursed || status == LoanStatus.fundIssue
              ? StatusStepState.current
              : status.isCollectable || status == LoanStatus.closed
              ? StatusStepState.completed
              : StatusStepState.upcoming,
        ),
      ],
    ];
  }
}
