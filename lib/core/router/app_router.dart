import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/providers/app_providers.dart';
import '../../presentation/screens/attendance/attendance_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/dashboard/dashboard_screen.dart';
import '../../presentation/screens/public/public_report_screen.dart';
import '../../presentation/screens/reports/reports_screen.dart';
import '../../presentation/screens/sessions/add_session_screen.dart';
import '../../presentation/screens/share/share_screen.dart';
import '../../presentation/screens/students/student_detail_screen.dart';
import '../../presentation/screens/students/student_form_screen.dart';
import '../../presentation/screens/students/students_list_screen.dart';

// ---------------------------------------------------------------------------
// Refresh notifier: bridges auth stream → GoRouter refresh
// ---------------------------------------------------------------------------

class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Stream<dynamic> stream) {
    _sub = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

// ---------------------------------------------------------------------------
// Router provider
// ---------------------------------------------------------------------------

final routerProvider = Provider<GoRouter>((ref) {
  final authRepo = ref.watch(authRepositoryProvider);
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();

  final notifier = _AuthChangeNotifier(authRepo.watchTeacherId());
  ref.onDispose(notifier.dispose);

  return GoRouter(
    navigatorKey: rootKey,
    refreshListenable: notifier,
    initialLocation: '/dashboard',

    // ------------------------------------------------------------------
    // Auth redirect
    // ------------------------------------------------------------------
    redirect: (context, state) {
      // Public report pages are always accessible.
      if (state.matchedLocation.startsWith('/report/')) return null;

      final isLoggedIn = authRepo.currentTeacherId != null;
      final isLoginPage = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoginPage) return '/login';
      if (isLoggedIn && isLoginPage) return '/dashboard';
      return null;
    },

    routes: [
      // ----------------------------------------------------------------
      // Login (outside shell)
      // ----------------------------------------------------------------
      GoRoute(
        path: '/login',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const LoginScreen(),
      ),

      // ----------------------------------------------------------------
      // Public parent report (outside shell, no auth)
      // ----------------------------------------------------------------
      GoRoute(
        path: '/report/:token',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final token = state.pathParameters['token']!;
          return PublicReportScreen(token: token);
        },
      ),

      // ----------------------------------------------------------------
      // Full-screen routes outside shell (pushed on top)
      // ----------------------------------------------------------------
      GoRoute(
        path: '/students/add',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const StudentFormScreen(),
      ),
      GoRoute(
        path: '/students/:id/edit',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StudentFormScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/students/:id/session',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return AddSessionScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/students/:id/share',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return ShareScreen(studentId: id);
        },
      ),
      GoRoute(
        path: '/students/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return StudentDetailScreen(studentId: id);
        },
      ),

      // ----------------------------------------------------------------
      // Bottom-nav shell: dashboard, students, attendance, reports
      // ----------------------------------------------------------------
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) =>
            _AppShell(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/students',
            builder: (context, state) => const StudentsListScreen(),
          ),
          GoRoute(
            path: '/attendance',
            builder: (context, state) => const AttendanceScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
        ],
      ),
    ],
  );
});

// ---------------------------------------------------------------------------
// Shell widget with NavigationBar
// ---------------------------------------------------------------------------

class _AppShell extends StatelessWidget {
  final String location;
  final Widget child;

  const _AppShell({required this.location, required this.child});

  static const _tabs = [
    _TabItem(
      path: '/dashboard',
      label: 'الرئيسية',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
    ),
    _TabItem(
      path: '/students',
      label: 'الطلاب',
      icon: Icons.groups_outlined,
      activeIcon: Icons.groups_rounded,
    ),
    _TabItem(
      path: '/attendance',
      label: 'الحضور',
      icon: Icons.event_available_outlined,
      activeIcon: Icons.event_available_rounded,
    ),
    _TabItem(
      path: '/reports',
      label: 'التقارير',
      icon: Icons.assessment_outlined,
      activeIcon: Icons.assessment_rounded,
    ),
  ];

  int get _selectedIndex {
    for (var i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _selectedIndex;
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        destinations: [
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.activeIcon),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _TabItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
