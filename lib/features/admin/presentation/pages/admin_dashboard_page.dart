import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/di/injection.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/domain/entities/repayment_frequency.dart';
import 'package:local_lending_app/features/admin/presentation/bloc/admin_dashboard_cubit.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';
import 'package:local_lending_app/shared/widgets/logout_action.dart';
import 'package:local_lending_app/shared/widgets/metric_card.dart';
import 'package:local_lending_app/shared/widgets/portal_switch_action.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AdminDashboardCubit>()..load(),
      child: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            context.go('/login');
          } else if (state is Authenticated && state.role.isClient) {
            context.go('/client/dashboard');
          }
        },
        builder: (context, authState) {
          final adminName = authState is Authenticated
              ? authState.user.name
              : 'Administrator';
          return Scaffold(
            appBar: AppBar(
              title: Text(FlavorConfig.appName),
              actions: const [PortalSwitchAction(), LogoutAction()],
            ),
            body: BlocBuilder<AdminDashboardCubit, AdminDashboardState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                final stats = state.stats;
                if (stats == null) {
                  return Center(child: Text(state.errorMessage ?? 'No data'));
                }
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      adminName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Text('Admin & Lender Console'),
                    const Text('Lending Portfolio Overview'),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Total Disbursed',
                            value: CurrencyFormatter.formatCompact(
                              stats.totalDisbursedRupees,
                            ),
                            subValue: '${stats.activeLoanCount} active loans',
                            icon: Icons.account_balance_wallet_outlined,
                            accentColor: FlavorConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricCard(
                            title: 'Total Collected',
                            value: CurrencyFormatter.formatCompact(
                              stats.totalCollectedRupees,
                            ),
                            subValue:
                                '${(stats.collectionRate * 100).toStringAsFixed(1)}% collected',
                            icon: Icons.payments_outlined,
                            accentColor: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: MetricCard(
                            title: 'Outstanding',
                            value: CurrencyFormatter.formatCompact(
                              stats.totalOutstandingRupees,
                            ),
                            subValue: 'Principal + flat interest',
                            icon: Icons.pending_actions_outlined,
                            accentColor: const Color(0xFF2563EB),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: MetricCard(
                            title: 'Overdue ratio',
                            value:
                                '${(stats.overdueRatio * 100).toStringAsFixed(1)}%',
                            subValue: '${stats.overdueCount} overdue',
                            icon: Icons.shield_outlined,
                            accentColor: const Color(0xFFDC2626),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _FrequencyMixCard(loansByFrequency: stats.loansByFrequency),
                    const SizedBox(height: 20),
                    _NavTile(
                      icon: Icons.calendar_today_rounded,
                      title: 'Daily Collection Sheet',
                      subtitle:
                          '${CurrencyFormatter.format(stats.dueTodayRupees)} due today • ${stats.dueTodayCount} borrowers',
                      route: '/admin/collections',
                    ),
                    const _NavTile(
                      icon: Icons.people_outline,
                      title: 'Customer Management',
                      subtitle: 'Search borrowers, risk tiers, repayment rate',
                      route: '/admin/customers',
                    ),
                    const _NavTile(
                      icon: Icons.verified_user_outlined,
                      title: 'KYC Review',
                      subtitle: 'Approve, reject, and track annual renewals',
                      route: '/admin/kyc',
                    ),
                    _NavTile(
                      icon: Icons.fact_check_outlined,
                      title: 'Loan Management & Approvals',
                      subtitle:
                          '${stats.pendingApplicationCount} pending requests • approve, reject, or counter-offer',
                      route: '/admin/loans',
                    ),
                    const _NavTile(
                      icon: Icons.add_business_outlined,
                      title: 'Create Loan for User',
                      subtitle: 'Admin-initiated disbursement',
                      route: '/admin/loans/create',
                    ),
                    const _NavTile(
                      icon: Icons.analytics_outlined,
                      title: 'Reports & Insights',
                      subtitle: 'Trends, delinquency buckets, CSV/PDF export',
                      route: '/admin/reports',
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _FrequencyMixCard extends StatelessWidget {
  const _FrequencyMixCard({required this.loansByFrequency});

  final Map<RepaymentFrequency, int> loansByFrequency;

  static Color _accentFor(RepaymentFrequency frequency) {
    return switch (frequency) {
      RepaymentFrequency.daily => FlavorConfig.primaryColor,
      RepaymentFrequency.weekly => FlavorConfig.secondaryColor,
      RepaymentFrequency.biweekly => FlavorConfig.tertiaryColor,
      RepaymentFrequency.monthly => const Color(0xFFD97706),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final frequencies = FlavorConfig.supportedFrequencies;
    final total = frequencies.fold<int>(
      0,
      (sum, frequency) => sum + (loansByFrequency[frequency] ?? 0),
    );
    final segments = frequencies
        .where((frequency) => (loansByFrequency[frequency] ?? 0) > 0)
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Repayment mix',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                total == 1 ? '1 open loan' : '$total open loans',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 8,
              child: segments.isEmpty
                  ? ColoredBox(color: scheme.surfaceContainer)
                  : Row(
                      children: [
                        for (var i = 0; i < segments.length; i++) ...[
                          if (i > 0)
                            const ColoredBox(
                              color: Colors.white,
                              child: SizedBox(width: 2, height: 8),
                            ),
                          Expanded(
                            flex: loansByFrequency[segments[i]] ?? 0,
                            child: ColoredBox(color: _accentFor(segments[i])),
                          ),
                        ],
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 12),
          for (var i = 0; i < frequencies.length; i += 2) ...[
            if (i > 0) const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _FrequencyMixRow(
                    frequency: frequencies[i],
                    count: loansByFrequency[frequencies[i]] ?? 0,
                    total: total,
                    color: _accentFor(frequencies[i]),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: i + 1 < frequencies.length
                      ? _FrequencyMixRow(
                          frequency: frequencies[i + 1],
                          count: loansByFrequency[frequencies[i + 1]] ?? 0,
                          total: total,
                          color: _accentFor(frequencies[i + 1]),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _FrequencyMixRow extends StatelessWidget {
  const _FrequencyMixRow({
    required this.frequency,
    required this.count,
    required this.total,
    required this.color,
  });

  final RepaymentFrequency frequency;
  final int count;
  final int total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = total == 0 ? 0 : ((count / total) * 100).round();
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            frequency.label,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          '$count',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '$percent%',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _NavTile extends StatelessWidget {
  const _NavTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: FlavorConfig.primaryColor),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.push(route),
      ),
    );
  }
}
