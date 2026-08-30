import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:local_lending_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/collections_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/create_loan_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/customers_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/kyc_review_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/loan_approvals_page.dart';
import 'package:local_lending_app/features/admin/presentation/pages/reports_page.dart';
import 'package:local_lending_app/features/auth/domain/entities/user_role.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:local_lending_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:local_lending_app/features/auth/presentation/pages/login_page.dart';
import 'package:local_lending_app/features/dashboard/presentation/pages/client_dashboard_page.dart';
import 'package:local_lending_app/features/kyc/presentation/pages/kyc_page.dart';
import 'package:local_lending_app/features/loans/presentation/pages/apply_loan_page.dart';
import 'package:local_lending_app/features/loans/presentation/pages/loan_applications_page.dart';
import 'package:local_lending_app/features/repayments/presentation/pages/make_payment_page.dart';
import 'package:local_lending_app/features/repayments/presentation/pages/repayment_history_page.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}

class AppRouter {
  AppRouter._();

  static GoRouter create(AuthCubit authCubit) {
    return GoRouter(
      initialLocation: '/login',
      refreshListenable: GoRouterRefreshStream(authCubit.stream),
      redirect: (context, state) {
        final location = state.matchedLocation;
        final authState = authCubit.state;
        final loggedIn = authState is Authenticated;
        final onLogin = location == '/login';

        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) {
          return authState.role.isAdmin
              ? '/admin/dashboard'
              : '/client/dashboard';
        }
        if (loggedIn &&
            location.startsWith('/admin') &&
            !authState.user.role.isAdmin) {
          return '/client/dashboard';
        }
        if (loggedIn &&
            location.startsWith('/admin') &&
            authState.role.isClient) {
          return '/client/dashboard';
        }
        final borrowerPath =
            location.startsWith('/client') ||
            location.startsWith('/loans') ||
            location.startsWith('/repayments') ||
            location.startsWith('/profile');
        if (loggedIn && borrowerPath && authState.role.isAdmin) {
          return '/admin/dashboard';
        }
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          name: 'login',
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/client/dashboard',
          name: 'clientDashboard',
          builder: (context, state) => const ClientDashboardPage(),
        ),
        GoRoute(
          path: '/loans/apply',
          name: 'applyLoan',
          builder: (context, state) => const ApplyLoanPage(),
        ),
        GoRoute(
          path: '/loans/applications',
          name: 'loanApplications',
          builder: (context, state) => const LoanApplicationsPage(),
        ),
        GoRoute(
          path: '/loans/status',
          name: 'loanStatus',
          builder: (context, state) => const LoanApplicationsPage(),
        ),
        GoRoute(
          path: '/profile/kyc',
          name: 'kyc',
          builder: (context, state) => const KycPage(),
        ),
        GoRoute(
          path: '/repayments/pay',
          name: 'makePayment',
          builder: (context, state) => const MakePaymentPage(),
        ),
        GoRoute(
          path: '/repayments/history',
          name: 'repaymentHistory',
          builder: (context, state) => const RepaymentHistoryPage(),
        ),
        GoRoute(
          path: '/admin/dashboard',
          name: 'adminDashboard',
          builder: (context, state) => const AdminDashboardPage(),
        ),
        GoRoute(
          path: '/admin/customers',
          name: 'adminCustomers',
          builder: (context, state) => const CustomersPage(),
        ),
        GoRoute(
          path: '/admin/kyc',
          name: 'adminKyc',
          builder: (context, state) => const KycReviewPage(),
        ),
        GoRoute(
          path: '/admin/loans',
          name: 'adminLoans',
          builder: (context, state) => const LoanApprovalsPage(),
        ),
        GoRoute(
          path: '/admin/loans/create',
          name: 'adminCreateLoan',
          builder: (context, state) => const CreateLoanPage(),
        ),
        GoRoute(
          path: '/admin/loans/requests',
          name: 'adminLoanRequests',
          redirect: (context, state) => '/admin/loans',
        ),
        GoRoute(
          path: '/admin/collections',
          name: 'adminCollections',
          builder: (context, state) => const CollectionsPage(),
        ),
        GoRoute(
          path: '/admin/reports',
          name: 'adminReports',
          builder: (context, state) => const ReportsPage(),
        ),
      ],
    );
  }
}
