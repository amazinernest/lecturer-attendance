import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/splash_screen.dart';
import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/authentication/presentation/login_screen.dart';
import '../../features/authentication/presentation/register_screen.dart';
import '../../features/authentication/presentation/forgot_password_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/courses/presentation/create_course_screen.dart';
import '../../features/courses/presentation/course_dashboard_screen.dart';
import '../../features/attendance/presentation/record_attendance_screen.dart';
import '../../features/students/presentation/import_class_list_screen.dart';
import '../../features/students/presentation/student_details_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main App Shell with Premium Bottom Navigation
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) =>
            ScaffoldWithBottomNavBar(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/courses',
            builder: (context, state) => const CoursesScreen(),
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const ReportsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Stack Routes Outside Shell
      GoRoute(
        path: '/courses/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateCourseScreen(),
      ),
      GoRoute(
        path: '/courses/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return CourseDashboardScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:id/record',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          final sessionId = state.uri.queryParameters['sessionId'];
          return RecordAttendanceScreen(
              courseId: courseId, existingSessionId: sessionId);
        },
      ),
      GoRoute(
        path: '/courses/:id/import',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          return ImportClassListScreen(courseId: courseId);
        },
      ),
      GoRoute(
        path: '/courses/:id/students/:studentId',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final courseId = state.pathParameters['id']!;
          final studentId = state.pathParameters['studentId']!;
          return StudentDetailsScreen(courseId: courseId, studentId: studentId);
        },
      ),
    ],
  );
});

class ScaffoldWithBottomNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithBottomNavBar({super.key, required this.child});

  int _calculateSelectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/courses')) return 1;
    if (location.startsWith('/reports')) return 2;
    if (location.startsWith('/profile')) return 3;
    return 0;
  }

  void _onDestinationSelected(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/dashboard');
        break;
      case 1:
        context.go('/courses');
        break;
      case 2:
        context.go('/reports');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            top: BorderSide(color: AppColors.border.withValues(alpha: 0.8), width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBarTheme(
          data: NavigationBarThemeData(
            indicatorColor: AppColors.accentLight,
            indicatorShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            labelTextStyle: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.accent,
                );
              }
              return const TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: AppColors.textMuted,
              );
            }),
            iconTheme: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return const IconThemeData(color: AppColors.accent, size: 22);
              }
              return const IconThemeData(color: AppColors.textSecondary, size: 22);
            }),
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) =>
                _onDestinationSelected(index, context),
            backgroundColor: AppColors.surface,
            elevation: 0,
            height: 66,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon: Icon(Icons.grid_view_rounded),
                label: 'Dashboard',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Courses',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart_rounded),
                label: 'Reports',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_circle_outlined),
                selectedIcon: Icon(Icons.account_circle_rounded),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
