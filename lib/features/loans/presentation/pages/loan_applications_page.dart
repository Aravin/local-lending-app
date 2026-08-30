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
      body: BlocBuilder<LoanApplicationsCubit, LoanApplicationsState>(
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
            Text(application.status.borrowerMessage),
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
            const SizedBox(height: 16),
            StatusTimeline(steps: _stepsFor(application)),
          ],
        ),
      ),
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
          subtitle: status.isOpen ? 'Loan is live' : 'After approval',
          state: status.isOpen
              ? StatusStepState.completed
              : status == LoanStatus.approved
              ? StatusStepState.current
              : StatusStepState.upcoming,
        ),
      ],
    ];
  }
}
