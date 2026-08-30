import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/core/utils/date_utils.dart';
import 'package:local_lending_app/core/utils/disbursement_policy.dart';
import 'package:local_lending_app/features/admin/domain/entities/kyc_profile.dart';
import 'package:local_lending_app/features/admin/domain/entities/risk_tier.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/dashboard/presentation/bloc/borrower_dashboard_cubit.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_application.dart';
import 'package:local_lending_app/features/loans/domain/entities/loan_status.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/installment_tile.dart';
import 'package:local_lending_app/shared/widgets/portal_switch_action.dart';
import 'package:local_lending_app/shared/widgets/status_chip.dart';

class ClientDashboardPage extends StatelessWidget {
  const ClientDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final userId = auth is Authenticated ? auth.user.id : '';
    final userName = auth is Authenticated ? auth.user.name : 'Borrower';

    return BlocProvider(
      create: (_) => getIt<BorrowerDashboardCubit>()..load(userId),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/login');
          } else if (state is Authenticated && state.role.isAdmin) {
            context.go('/admin/dashboard');
          }
        },
        builder: (context, _) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: const _BrandTitle(subtitle: 'Client / Borrower Portal'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.verified_user_outlined),
                  tooltip: 'KYC',
                  onPressed: () => context.push('/profile/kyc'),
                ),
                const PortalSwitchAction(),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: 'Log out',
                  onPressed: () => context.read<AuthCubit>().signOut(),
                ),
              ],
            ),
            body: BlocBuilder<BorrowerDashboardCubit, BorrowerDashboardState>(
              builder: (context, state) {
                if (state.status == DashboardStatus.loading ||
                    state.status == DashboardStatus.initial) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == DashboardStatus.error) {
                  return Center(
                    child: Text(
                      state.errorMessage ?? 'Unable to load dashboard',
                    ),
                  );
                }
                return _DashboardBody(userName: userName, state: state);
              },
            ),
          );
        },
      ),
    );
  }
}

class _BrandTitle extends StatelessWidget {
  const _BrandTitle({required this.subtitle});

  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = FlavorConfig.primaryColor;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: primaryColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              FlavorConfig.logoAssetPath,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  Icon(Icons.account_balance, size: 20, color: primaryColor),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              FlavorConfig.appName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.userName, required this.state});

  final String userName;
  final BorrowerDashboardState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loan = state.activeLoan;
    final canPay = loan != null && loan.status.isCollectable;
    return RefreshIndicator(
      onRefresh: () {
        final auth = context.read<AuthCubit>().state;
        final id = auth is Authenticated ? auth.user.id : '';
        return context.read<BorrowerDashboardCubit>().load(id);
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        children: [
          Text(
            'Namaste, $userName',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Here is your loan & repayment status',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
          const SizedBox(height: 20),
          if (state.kyc != null && state.kyc!.canSubmit())
            _KycActionBanner(profile: state.kyc!),
          if (loan != null && loan.status == LoanStatus.disbursed)
            _DisbursementBanner(loan: loan)
          else if (loan != null && loan.status == LoanStatus.fundIssue)
            const _FundIssueBanner()
          else if (loan != null)
            _NextDueCard(loan: loan)
          else
            const _EmptyLoanCard(),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add_card,
                  title: 'Apply for Loan',
                  subtitle: 'Instant digital approval',
                  color: FlavorConfig.primaryColor,
                  onTap: () => context.push('/loans/apply'),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _ActionCard(
                  icon: Icons.track_changes,
                  title: 'Track application',
                  subtitle: 'See review status',
                  color: const Color(0xFF2563EB),
                  onTap: () => context.push('/loans/status'),
                ),
              ),
            ],
          ),
          if (canPay) ...[
            const SizedBox(height: 14),
            _ActionCard(
              icon: Icons.qr_code_scanner,
              title: 'Pay EMI Online',
              subtitle: 'UPI & Net Banking',
              color: const Color(0xFF059669),
              onTap: () => context.push('/repayments/pay'),
            ),
          ],
          if (state.applications.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Your applications',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/loans/status'),
                  child: const Text('Track status'),
                ),
              ],
            ),
            ...state.applications
                .take(3)
                .map(
                  (application) => _ApplicationTile(application: application),
                ),
          ],
          const SizedBox(height: 24),
          if (canPay) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Upcoming installments',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => context.push('/repayments/history'),
                  child: const Text('View schedule'),
                ),
              ],
            ),
            ...loan.schedule.installments
                .where((item) => !item.isSettled)
                .take(4)
                .map((item) => InstallmentTile(installment: item)),
          ],
          const SizedBox(height: 12),
          Text(
            'Recent repayments',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (state.recentRepayments.isEmpty)
            Text(
              'No repayments recorded yet.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            )
          else
            ...state.recentRepayments.map(
              (record) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF059669),
                ),
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
      ),
    );
  }
}

class _DisbursementBanner extends StatelessWidget {
  const _DisbursementBanner({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final disbursedOn = loan.disbursementDate ?? loan.appliedAt;
    final deadline = DisbursementPolicy.confirmationDeadline(disbursedOn);
    return Material(
      color: const Color(0xFFEFF6FF),
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        leading: const Icon(Icons.account_balance_wallet_outlined),
        title: const Text('Funds released'),
        subtitle: Text(
          'Confirm receipt by ${AppDateUtils.formatDisplay(deadline.subtract(const Duration(days: 1)))}. EMI starts from ${AppDateUtils.formatDisplay(disbursedOn)} if no issue is reported.',
        ),
        trailing: TextButton(
          onPressed: () => context.push('/loans/status'),
          child: const Text('Report issue'),
        ),
      ),
    );
  }
}

class _FundIssueBanner extends StatelessWidget {
  const _FundIssueBanner();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF7ED),
      borderRadius: BorderRadius.circular(16),
      child: const ListTile(
        leading: Icon(
          Icons.report_gmailerrorred_outlined,
          color: Color(0xFFD97706),
        ),
        title: Text('Fund issue reported'),
        subtitle: Text('EMI is paused until the lender re-releases the funds.'),
      ),
    );
  }
}

class _NextDueCard extends StatelessWidget {
  const _NextDueCard({required this.loan});

  final Loan loan;

  @override
  Widget build(BuildContext context) {
    final primaryColor = FlavorConfig.primaryColor;
    final next = loan.nextDue;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withAlpha(220)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NEXT EMI DUE',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                next == null
                    ? 'All caught up'
                    : AppDateUtils.dueLabel(next.dueDate),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            CurrencyFormatter.format(next?.outstandingRupees ?? 0),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${loan.frequency.label} • ${loan.purpose.label}',
            style: TextStyle(color: Colors.white.withAlpha(220), fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Outstanding ${CurrencyFormatter.format(loan.outstandingRupees)}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              Text(
                '${loan.schedule.paidCount} / ${loan.schedule.installments.length} paid',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _KycActionBanner extends StatelessWidget {
  const _KycActionBanner({required this.profile});

  final KycProfile profile;

  @override
  Widget build(BuildContext context) {
    final status = profile.effectiveStatus();
    final message = profile.isExpiringSoon() && profile.expiresAt != null
        ? 'KYC expires on ${AppDateUtils.formatDisplay(profile.expiresAt!)}. Renew to stay verified.'
        : switch (status) {
            KycStatus.expired =>
              'Annual KYC has expired. Complete verification again.',
            KycStatus.rejected =>
              'KYC was rejected. Update documents and resubmit.',
            _ => 'Complete KYC so your loan requests can be reviewed.',
          };
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        child: ListTile(
          leading: const Icon(
            Icons.verified_user_outlined,
            color: Color(0xFFD97706),
          ),
          title: Text(message),
          trailing: StatusChip.kyc(status),
          onTap: () => context.push('/profile/kyc'),
        ),
      ),
    );
  }
}

class _ApplicationTile extends StatelessWidget {
  const _ApplicationTile({required this.application});

  final LoanApplication application;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        '${application.purpose.label} • ${CurrencyFormatter.format(application.requestedAmountRupees)}',
      ),
      subtitle: Text(
        'Applied ${AppDateUtils.formatDisplay(application.requestedAt)}',
      ),
      trailing: StatusChip.loan(application.status),
      onTap: () => context.push('/loans/status'),
    );
  }
}

class _EmptyLoanCard extends StatelessWidget {
  const _EmptyLoanCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: const Text('No active loan yet. Apply to get started.'),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: theme.colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha(30),
                radius: 20,
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
