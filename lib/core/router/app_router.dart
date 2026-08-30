import 'package:go_router/go_router.dart';
import 'package:local_lending_app/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:local_lending_app/features/auth/presentation/pages/login_page.dart';
import 'package:local_lending_app/features/dashboard/presentation/pages/client_dashboard_page.dart';

class AppRouter {
  AppRouter._();

  static final GoRouter router = GoRouter(
    initialLocation: '/login',
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
        path: '/admin/dashboard',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardPage(),
      ),
    ],
  );
}
