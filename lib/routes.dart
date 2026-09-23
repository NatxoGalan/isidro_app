import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'presentation/providers/auth_provider.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/dashboard_screen.dart';
import 'presentation/screens/table_detail_screen.dart';
import 'presentation/screens/menu_management_screen.dart';
import 'presentation/screens/printers_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.value;

  return GoRouter(
    initialLocation: user != null ? '/dashboard' : '/login',
    redirect: (context, state) {
      final isLoggedIn = user != null;
      final isOnLogin = state.matchedLocation == '/login';
      if (!isLoggedIn && !isOnLogin) return '/login';
      if (isLoggedIn && isOnLogin) return '/dashboard';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
        routes: [
          GoRoute(
            path: 'table/:tableId',
            builder: (context, state) => TableDetailScreen(tableId: state.pathParameters['tableId']!),
          ),
          GoRoute(
            path: 'menu',
            builder: (context, state) => const MenuManagementScreen(),
          ),
          GoRoute(
            path: 'printers',
            builder: (context, state) => const PrintersScreen(),
          ),
        ],
      ),
    ],
  );
});
