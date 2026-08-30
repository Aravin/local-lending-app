import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/core/utils/currency_formatter.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/flavors/flavor_config.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = FlavorConfig.primaryColor;

    return BlocConsumer<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is Unauthenticated) {
          context.go('/login');
        } else if (state is Authenticated && state.role.isClient) {
          context.go('/client/dashboard');
        }
      },
      builder: (context, state) {
        final adminName = state is Authenticated
            ? state.user.name
            : 'Administrator';

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          appBar: AppBar(
            elevation: 0,
            title: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.admin_panel_settings,
                    color: Colors.white,
                    size: 20,
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
                    const Text(
                      'Admin & Lender Console',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFFD97706),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Log out',
                onPressed: () {
                  context.read<AuthCubit>().signOut();
                },
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Greeting
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          adminName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lending Portfolio Overview',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD97706).withAlpha(25),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFD97706).withAlpha(80),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            size: 14,
                            color: Color(0xFFD97706),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Lender & Admin',
                            style: TextStyle(
                              color: Color(0xFFD97706),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Portfolio KPI Metrics Grid (2x2)
                _buildPortfolioMetrics(theme, primaryColor),
                const SizedBox(height: 20),

                // Repayment Frequency Breakdown
                _buildFrequencyBreakdown(theme, primaryColor),
                const SizedBox(height: 20),

                // Admin Action Cards
                _buildAdminActionCards(context, theme, primaryColor),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioMetrics(ThemeData theme, Color primaryColor) {
    return Column(
      children: [
        Row(
          children: [
            // Disbursed Capital
            Expanded(
              child: _buildMetricCard(
                theme: theme,
                title: 'Total Disbursed',
                value: CurrencyFormatter.formatCompact(2450000),
                subValue: '85 Active Loans',
                icon: Icons.account_balance_wallet_outlined,
                accentColor: primaryColor,
              ),
            ),
            const SizedBox(width: 14),
            // Collected Capital
            Expanded(
              child: _buildMetricCard(
                theme: theme,
                title: 'Total Collected',
                value: CurrencyFormatter.formatCompact(1820000),
                subValue: '74.2% Return Rate',
                icon: Icons.payments_outlined,
                accentColor: const Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            // Outstanding Dues
            Expanded(
              child: _buildMetricCard(
                theme: theme,
                title: 'Total Outstanding',
                value: CurrencyFormatter.formatCompact(630000),
                subValue: 'Principal + Flat Interest',
                icon: Icons.pending_actions_outlined,
                accentColor: const Color(0xFF2563EB),
              ),
            ),
            const SizedBox(width: 14),
            // Overdue Risk
            Expanded(
              child: _buildMetricCard(
                theme: theme,
                title: 'Overdue Risk Ratio',
                value: '2.4%',
                subValue: 'Low Risk • 2 Overdue',
                icon: Icons.shield_outlined,
                accentColor: const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required ThemeData theme,
    required String title,
    required String value,
    required String subValue,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(icon, color: accentColor, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subValue,
            style: TextStyle(
              color: accentColor,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyBreakdown(ThemeData theme, Color primaryColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Repayment Frequency Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildFrequencyPill('Daily', '42 Loans', primaryColor),
              const SizedBox(width: 8),
              _buildFrequencyPill(
                'Weekly',
                '28 Loans',
                const Color(0xFF059669),
              ),
              const SizedBox(width: 8),
              _buildFrequencyPill(
                'Monthly',
                '15 Loans',
                const Color(0xFF2563EB),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyPill(String name, String count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withAlpha(50)),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              count,
              style: const TextStyle(color: Colors.black87, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActionCards(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
  ) {
    return Column(
      children: [
        // 1. Today's Daily Collection Sheet
        _buildActionTile(
          theme: theme,
          icon: Icons.calendar_today_rounded,
          iconColor: primaryColor,
          title: 'Daily Collection Sheet',
          subtitle: '₹28,500 due today across 18 borrowers',
          trailingBadge: '18 DUES',
          badgeColor: primaryColor,
        ),
        const SizedBox(height: 12),

        // 2. Pending Loan Approvals
        _buildActionTile(
          theme: theme,
          icon: Icons.fact_check_outlined,
          iconColor: const Color(0xFFD97706),
          title: 'Loan Application Approvals',
          subtitle: '4 pending loan requests awaiting decision',
          trailingBadge: '4 NEW',
          badgeColor: const Color(0xFFD97706),
        ),
        const SizedBox(height: 12),

        // 3. Reports & Delinquency Aging
        _buildActionTile(
          theme: theme,
          icon: Icons.analytics_outlined,
          iconColor: const Color(0xFF2563EB),
          title: 'Reports & Risk Insights',
          subtitle: 'Delinquency aging buckets (1-7d, 8-30d) and CSV export',
          trailingBadge: 'PDF/CSV',
          badgeColor: const Color(0xFF2563EB),
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String trailingBadge,
    required Color badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              trailingBadge,
              style: TextStyle(
                color: badgeColor,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.chevron_right, color: theme.colorScheme.outline, size: 18),
        ],
      ),
    );
  }
}
