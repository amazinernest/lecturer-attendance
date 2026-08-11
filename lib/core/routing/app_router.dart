import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/welcome_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../features/courses/presentation/courses_screen.dart';
import '../../features/courses/presentation/create_course_screen.dart';
import '../../features/courses/presentation/course_dashboard_screen.dart';
import '../../features/attendance/presentation/record_attendance_screen.dart';
import '../../features/students/presentation/import_class_list_screen.dart';
import '../../features/students/presentation/student_details_screen.dart';
import '../../features/reports/presentation/reports_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../services/providers.dart';
import '../theme/app_theme.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

final routerProvider = Provider<GoRouter>((ref) {
  final user = ref.watch(currentUserProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: user != null ? '/dashboard' : '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),

      // Main App Shell with Bottom Navigation Bar
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => ScaffoldWithBottomNavBar(child: child),
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
          return RecordAttendanceScreen(courseId: courseId, existingSessionId: sessionId);
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

  void _onItemTapped(int index, BuildContext context) {
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onItemTapped(index, context),
        selectedItemColor: AppColors.primaryContainer,
        unselectedItemColor: AppColors.secondary,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.book_outlined),
            activeIcon: Icon(Icons.book),
            label: 'Courses',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assessment_outlined),
            activeIcon: Icon(Icons.assessment),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
