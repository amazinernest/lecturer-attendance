import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../data/sync/sync_service.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../core/utils/sample_data.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/models/attendance_session.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/course_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/quick_action_hub.dart';
import '../../../shared/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD STATS PROVIDER (Prevents re-fetch loops & tab-switch flicker)
// ─────────────────────────────────────────────────────────────────────────────
class DashboardCourseData {
  final Course course;
  final int studentCount;
  final int classesHeld;
  final double avgPct;
  final int atRiskCount;
  final List<AttendanceSession> sessions;

  const DashboardCourseData({
    required this.course,
    required this.studentCount,
    required this.classesHeld,
    required this.avgPct,
    required this.atRiskCount,
    required this.sessions,
  });
}

class DashboardAggregateData {
  final List<DashboardCourseData> courseDataList;
  final int totalCourses;
  final int totalStudents;
  final int totalClasses;
  final double globalAvg;
  final int totalAtRisk;
  final List<Map<String, dynamic>> allRecentSessions;

  const DashboardAggregateData({
    required this.courseDataList,
    required this.totalCourses,
    required this.totalStudents,
    required this.totalClasses,
    required this.globalAvg,
    required this.totalAtRisk,
    required this.allRecentSessions,
  });
}

final dashboardAggregateProvider =
    FutureProvider.autoDispose<DashboardAggregateData>((ref) async {
  final db = ref.watch(databaseProvider);
  final courses = await ref.watch(coursesStreamProvider.future);
  final activeCourses =
      courses.where((c) => c.status == CourseStatus.active).toList();

  int totalStudents = 0;
  int totalClasses = 0;
  double pctSum = 0.0;
  int totalAtRisk = 0;
  final allRecentSessions = <Map<String, dynamic>>[];
  final courseDataList = <DashboardCourseData>[];

  for (final c in activeCourses) {
    final students = await db.getStudentsForCourse(c.id);
    final sessions = await db.getSessionsForCourse(c.id);
    final records = await db.getAllRecordsForCourse(c.id);

    final recordMap = <String, Map<String, bool>>{};
    for (final r in records) {
      recordMap.putIfAbsent(r.attendanceSessionId,
          () => {})[r.studentId] = (r.status == AttendanceStatus.present);
    }

    int atRiskStudentsForCourse = 0;
    final studentStatsList = students.map((s) {
      int attended = 0;
      for (final sess in sessions) {
        if (recordMap[sess.id]?[s.id] == true) attended++;
      }
      final stats = AttendanceCalculator.calculateStudentStats(
        totalClassesHeld: sessions.length,
        classesAttended: attended,
      );
      if (sessions.isNotEmpty && stats.percentage < 75.0) {
        atRiskStudentsForCourse++;
      }
      return stats;
    }).toList();

    final summary = AttendanceCalculator.calculateCourseSummary(
      classesHeld: sessions.length,
      studentStatsList: studentStatsList,
    );

    final avgPct = summary.averageAttendancePercentage;
    totalStudents += students.length;
    totalClasses += sessions.length;
    pctSum += avgPct;
    totalAtRisk += atRiskStudentsForCourse;

    for (final s in sessions) {
      int presentCount = 0;
      final sessionRecords = recordMap[s.id] ?? {};
      for (final isPres in sessionRecords.values) {
        if (isPres) presentCount++;
      }

      allRecentSessions.add({
        'session': s,
        'course': c,
        'courseCode': c.courseCode,
        'courseTitle': c.courseTitle,
        'courseId': c.id,
        'presentCount': presentCount,
        'totalEnrolled': students.length,
      });
    }

    courseDataList.add(DashboardCourseData(
      course: c,
      studentCount: students.length,
      classesHeld: sessions.length,
      avgPct: avgPct,
      atRiskCount: atRiskStudentsForCourse,
      sessions: sessions,
    ));
  }

  allRecentSessions.sort((a, b) {
    final dateA = (a['session'] as AttendanceSession).date;
    final dateB = (b['session'] as AttendanceSession).date;
    return dateB.compareTo(dateA);
  });

  final globalAvg =
      activeCourses.isNotEmpty ? (pctSum / activeCourses.length) : 0.0;

  return DashboardAggregateData(
    courseDataList: courseDataList,
    totalCourses: activeCourses.length,
    totalStudents: totalStudents,
    totalClasses: totalClasses,
    globalAvg: globalAvg,
    totalAtRisk: totalAtRisk,
    allRecentSessions: allRecentSessions,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedTab = 0; // 0 = Courses, 1 = Recent Activity

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final db = ref.read(databaseProvider);
      final user = ref.read(currentUserProvider);
      if (user != null) {
        await SampleDataSeeder.seedIfEmpty(db, user.id);
      }
    });
  }

  void _showNotificationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _NotificationCenterSheet(),
    );
  }

  void _showCoursePickerModal(
      BuildContext context, List<Course> courses, String title, Function(Course) onSelect) {
    if (courses.isEmpty) {
      context.push('/courses/create');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CoursePickerSheet(
        title: title,
        courses: courses,
        onSelect: onSelect,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final aggAsync = ref.watch(dashboardAggregateProvider);
    final user = ref.watch(currentUserProvider);
    final syncState = ref.watch(syncServiceProvider).state;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final dateStr = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      body: aggAsync.when(
        loading: () => const _DashboardSkeleton(),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline_rounded,
                    size: 48, color: AppColors.error),
                const SizedBox(height: 16),
                Text('Unable to load dashboard', style: AppTypography.headlineMd),
                const SizedBox(height: 8),
                Text('$err',
                    style: AppTypography.bodyMd, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.refresh(dashboardAggregateProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final courses = data.courseDataList.map((e) => e.course).toList();
          final isHealthy = data.globalAvg >= 75.0;

          return RefreshIndicator(
            color: AppColors.accent,
            onRefresh: () async {
              if (user != null) {
                await ref
                    .read(syncServiceProvider)
                    .syncNow(lecturerId: user.id);
              }
              ref.invalidate(dashboardAggregateProvider);
            },
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── 1. PREMIUM HERO HEADER ─────────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF070E1E),
                          Color(0xFF0F2248),
                          Color(0xFF193B7B),
                        ],
                      ),
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 24,
                          offset: Offset(0, 10),
                        ),
                      ],
                    ),
                    child: SafeArea(
                      bottom: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile row + Notification button
                            Row(
                              children: [
                                // Avatar with online ring
                                GestureDetector(
                                  onTap: () => context.go('/profile'),
                                  child: Stack(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(2.5),
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFF60A5FA),
                                              Color(0xFF2563EB),
                                            ],
                                          ),
                                        ),
                                        child: CircleAvatar(
                                          radius: 22,
                                          backgroundColor: const Color(0xFF1E293B),
                                          backgroundImage:
                                              user?.photoUrl != null
                                                  ? NetworkImage(user!.photoUrl!)
                                                  : null,
                                          child: user?.photoUrl == null
                                              ? Text(
                                                  (user?.name.isNotEmpty == true)
                                                      ? user!.name[0].toUpperCase()
                                                      : 'L',
                                                  style: const TextStyle(
                                                    fontFamily:
                                                        AppTypography.fontFamily,
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 1,
                                        right: 1,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF10B981),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: const Color(0xFF070E1E),
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 14),
                                // Greeting & Lecturer Name
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            '$greeting,',
                                            style: TextStyle(
                                              fontFamily:
                                                  AppTypography.fontFamily,
                                              color: Colors.white
                                                  .withValues(alpha: 0.7),
                                              fontSize: 12.5,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: Colors.white
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'FACULTY',
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTypography.fontFamily,
                                                color: Color(0xFF93C5FD),
                                                fontSize: 9,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        user?.name ?? 'Dr. Ernest Ochuko',
                                        style: const TextStyle(
                                          fontFamily: AppTypography.fontFamily,
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.2,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                // Notification Button
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showNotificationSheet(context),
                                    borderRadius: BorderRadius.circular(100),
                                    child: Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              Colors.white.withValues(alpha: 0.15),
                                          width: 1,
                                        ),
                                      ),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Icon(
                                            Icons.notifications_none_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                          Positioned(
                                            top: -2,
                                            right: -2,
                                            child: Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFF38BDF8),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 18),

                            // Date + Live Sync Status Pill
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: 0.12),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 13,
                                        color:
                                            Colors.white.withValues(alpha: 0.8),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        dateStr,
                                        style: TextStyle(
                                          fontFamily:
                                              AppTypography.fontFamily,
                                          color: Colors.white
                                              .withValues(alpha: 0.95),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981)
                                        .withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFF34D399),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Text(
                                        syncState == SyncState.syncing
                                            ? 'Syncing...'
                                            : 'Cloud Sync Active',
                                        style: const TextStyle(
                                          fontFamily:
                                              AppTypography.fontFamily,
                                          color: Color(0xFF6EE7B7),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 20),

                            // ── HERO ATTENDANCE PULSE CARD ────────────────
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  width: 1.2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 18,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'CAMPUS ATTENDANCE PULSE',
                                              style: TextStyle(
                                                fontFamily:
                                                    AppTypography.fontFamily,
                                                color: Colors.white
                                                    .withValues(alpha: 0.7),
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.8,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.baseline,
                                          textBaseline:
                                              TextBaseline.alphabetic,
                                          children: [
                                            Text(
                                              '${data.globalAvg.toStringAsFixed(0)}%',
                                              style: const TextStyle(
                                                fontFamily:
                                                    AppTypography.fontFamily,
                                                color: Colors.white,
                                                fontSize: 44,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: -1.5,
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 3.5),
                                              decoration: BoxDecoration(
                                                color: (isHealthy
                                                        ? const Color(0xFF10B981)
                                                        : const Color(0xFFF59E0B))
                                                    .withValues(alpha: 0.25),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isHealthy
                                                      ? const Color(0xFF34D399)
                                                      : const Color(0xFFFBBF24),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Icon(
                                                    isHealthy
                                                        ? Icons.trending_up_rounded
                                                        : Icons.warning_amber_rounded,
                                                    color: isHealthy
                                                        ? const Color(0xFF34D399)
                                                        : const Color(0xFFFBBF24),
                                                    size: 13,
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    isHealthy
                                                        ? 'ON TRACK'
                                                        : 'ATTENTION',
                                                    style: TextStyle(
                                                      fontFamily:
                                                          AppTypography.fontFamily,
                                                      color: isHealthy
                                                          ? const Color(0xFF34D399)
                                                          : const Color(0xFFFBBF24),
                                                      fontSize: 10,
                                                      fontWeight:
                                                          FontWeight.w800,
                                                      letterSpacing: 0.4,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Across ${data.totalCourses} active courses • ${data.totalStudents} total students',
                                          style: TextStyle(
                                            fontFamily:
                                                AppTypography.fontFamily,
                                            color: Colors.white
                                                .withValues(alpha: 0.75),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Animated radial ring
                                  _AttendanceGauge(percentage: data.globalAvg),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ── 2. BODY CONTENT ─────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── OPERATIONAL METRICS 2x2 GRID (Non-redundant) ──
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            title: 'Active Courses',
                            value: '${data.totalCourses}',
                            subtitle: 'courses',
                            icon: Icons.menu_book_rounded,
                            backgroundColor: const Color(0xFFEFF6FF),
                            waveColor: const Color(0xFF2563EB),
                            textColor: const Color(0xFF1E3A8A),
                            onTap: () => context.go('/courses'),
                          ),
                          StatCard(
                            title: 'Total Students',
                            value: '${data.totalStudents}',
                            subtitle: 'enrolled',
                            icon: Icons.groups_rounded,
                            backgroundColor: const Color(0xFFF0FDF4),
                            waveColor: const Color(0xFF16A34A),
                            textColor: const Color(0xFF14532D),
                            onTap: () => context.go('/courses'),
                          ),
                          StatCard(
                            title: 'Sessions Held',
                            value: '${data.totalClasses}',
                            subtitle: 'classes held',
                            icon: Icons.event_available_rounded,
                            backgroundColor: const Color(0xFFFFFBEB),
                            waveColor: const Color(0xFFD97706),
                            textColor: const Color(0xFF78350F),
                            onTap: () => context.go('/reports'),
                          ),
                          StatCard(
                            title: 'At-Risk Alert',
                            value: '${data.totalAtRisk}',
                            subtitle: data.totalAtRisk == 0 ? 'all on track' : 'below 75%',
                            icon: data.totalAtRisk == 0
                                ? Icons.verified_rounded
                                : Icons.warning_rounded,
                            backgroundColor: data.totalAtRisk == 0
                                ? const Color(0xFFF0FDF4)
                                : const Color(0xFFFEF2F2),
                            waveColor: data.totalAtRisk == 0
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFDC2626),
                            textColor: data.totalAtRisk == 0
                                ? const Color(0xFF14532D)
                                : const Color(0xFF991B1B),
                            badgeText: data.totalAtRisk > 0 ? 'NEEDS REVIEW' : null,
                            onTap: () => context.go('/reports'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── QUICK ACTIONS ───────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            '1-Tap Shortcuts',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      QuickActionHub(
                        onTakeAttendance: () => _showCoursePickerModal(
                          context,
                          courses,
                          'Select Course for Attendance',
                          (c) => context.push('/courses/${c.id}/record'),
                        ),
                        onAddCourse: () => context.push('/courses/create'),
                        onImportRoster: () => _showCoursePickerModal(
                          context,
                          courses,
                          'Select Course to Import Roster',
                          (c) => context.push('/courses/${c.id}/import'),
                        ),
                        onViewAnalytics: () => context.go('/reports'),
                      ),

                      const SizedBox(height: 28),

                      // ── SEGMENTED CONTROL TABS (Courses vs Recent) ──────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                _SegmentedTabItem(
                                  label: 'Courses',
                                  count: data.totalCourses,
                                  isSelected: _selectedTab == 0,
                                  onTap: () =>
                                      setState(() => _selectedTab = 0),
                                ),
                                const SizedBox(width: 4),
                                _SegmentedTabItem(
                                  label: 'Recent Activity',
                                  count: data.allRecentSessions.length,
                                  isSelected: _selectedTab == 1,
                                  onTap: () =>
                                      setState(() => _selectedTab = 1),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedTab == 0)
                            TextButton.icon(
                              onPressed: () => context.push('/courses/create'),
                              icon: const Icon(Icons.add_circle_outline_rounded,
                                  size: 16),
                              label: const Text('Add Course'),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                textStyle: const TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── TAB CONTENT ────────────────────────────────────
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _selectedTab == 0
                            ? _buildCoursesList(context, data.courseDataList)
                            : _buildRecentSessionsList(
                                context, data.allRecentSessions),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCoursesList(
      BuildContext context, List<DashboardCourseData> courseDataList) {
    if (courseDataList.isEmpty) {
      return EmptyStateWidget.noCourses(
        onAddCourse: () => context.push('/courses/create'),
      );
    }

    return Column(
      key: const ValueKey('courses_tab'),
      children: courseDataList.map((data) {
        final course = data.course;
        return CourseCard(
          course: course,
          studentCount: data.studentCount,
          classesHeldCount: data.classesHeld,
          averageAttendancePct: data.avgPct,
          onTap: () => context.push('/courses/${course.id}'),
          onQuickRecord: () => context.push('/courses/${course.id}/record'),
        );
      }).toList(),
    );
  }

  Widget _buildRecentSessionsList(
      BuildContext context, List<Map<String, dynamic>> sessions) {
    if (sessions.isEmpty) {
      return Container(
        key: const ValueKey('empty_sessions'),
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.history_toggle_off_rounded,
                  size: 36, color: AppColors.accent),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Sessions Recorded Yet',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tap "Take Attendance" above to record your first class session.',
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      key: const ValueKey('sessions_tab'),
      children: sessions.take(6).map((data) {
        final sess = data['session'] as AttendanceSession;
        final cCode = data['courseCode'] as String;
        final cId = data['courseId'] as String;
        final cTitle = data['courseTitle'] as String;
        final present = data['presentCount'] as int;
        final enrolled = data['totalEnrolled'] as int;
        final dateFormatted = DateFormat('EEE, d MMM • h:mm a').format(sess.date);

        return _RecentSessionCard(
          session: sess,
          courseCode: cCode,
          courseTitle: cTitle,
          courseId: cId,
          presentCount: present,
          totalEnrolled: enrolled,
          dateStr: dateFormatted,
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RECENT SESSION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _RecentSessionCard extends StatelessWidget {
  final AttendanceSession session;
  final String courseCode;
  final String courseTitle;
  final String courseId;
  final int presentCount;
  final int totalEnrolled;
  final String dateStr;

  const _RecentSessionCard({
    required this.session,
    required this.courseCode,
    required this.courseTitle,
    required this.courseId,
    required this.presentCount,
    required this.totalEnrolled,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    final pct = totalEnrolled > 0
        ? ((presentCount / totalEnrolled) * 100).toStringAsFixed(0)
        : '0';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () =>
              context.push('/courses/$courseId/record?sessionId=${session.id}'),
          borderRadius: BorderRadius.circular(18),
          splashColor: AppColors.accentLight,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                // Class Number Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFEFF6FF),
                        Color(0xFFDBEAFE),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'CLASS',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        '#${session.classNumber}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Session details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            courseCode,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.accent,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              session.topic.isNotEmpty
                                  ? '— ${session.topic}'
                                  : '— General Lecture',
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              fontSize: 11.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // Attendance Summary Pill
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$pct%',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.success,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        '$presentCount / $totalEnrolled',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.success.withValues(alpha: 0.8),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SEGMENTED TAB ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _SegmentedTabItem extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _SegmentedTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDeep : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: AppTypography.fontFamily,
                color: isSelected ? Colors.white : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                fontSize: 13,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.2)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATTENDANCE GAUGE
// ─────────────────────────────────────────────────────────────────────────────
class _AttendanceGauge extends StatelessWidget {
  final double percentage;
  const _AttendanceGauge({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 76,
      height: 76,
      child: CustomPaint(
        painter: _GaugePainter(percentage: percentage / 100),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.bolt_rounded,
                color: Color(0xFF60A5FA),
                size: 20,
              ),
              Text(
                '${percentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double percentage;
  const _GaugePainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.5;
    final radius = (size.width - strokeW) / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFF38BDF8),
          Color(0xFF3B82F6),
          Color(0xFF10B981),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, track);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * percentage.clamp(0.0, 1.0),
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.percentage != percentage;
}

// ─────────────────────────────────────────────────────────────────────────────
// COURSE PICKER BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _CoursePickerSheet extends StatefulWidget {
  final String title;
  final List<Course> courses;
  final Function(Course) onSelect;

  const _CoursePickerSheet({
    required this.title,
    required this.courses,
    required this.onSelect,
  });

  @override
  State<_CoursePickerSheet> createState() => _CoursePickerSheetState();
}

class _CoursePickerSheetState extends State<_CoursePickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.courses.where((c) {
      if (_search.isEmpty) return true;
      final q = _search.toLowerCase();
      return c.courseCode.toLowerCase().contains(q) ||
          c.courseTitle.toLowerCase().contains(q) ||
          c.department.toLowerCase().contains(q);
    }).toList();

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: AppTypography.fontFamily,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Search field
              TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  hintText: 'Search by course code or title...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  filled: true,
                  fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),

              const SizedBox(height: 14),

              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    return ListTile(
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      leading: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          c.courseCode,
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            color: AppColors.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        c.courseTitle,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(
                        '${c.department} • ${c.level}',
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios_rounded,
                          size: 14, color: AppColors.textMuted),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onSelect(c);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NOTIFICATION CENTER SHEET (Investor Demo Ready)
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCenterSheet extends StatelessWidget {
  const _NotificationCenterSheet();

  @override
  Widget build(BuildContext context) {
    final notifications = [
      {
        'title': 'Session Attendance Synced',
        'desc': 'CSC 301 (Operating Systems) Class #4 records pushed to campus cloud.',
        'time': '10 mins ago',
        'icon': Icons.cloud_done_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'At-Risk Student Notice',
        'desc': '3 students in MTH 201 dropped below the 75% exam eligibility threshold.',
        'time': '2 hours ago',
        'icon': Icons.warning_amber_rounded,
        'color': const Color(0xFFF59E0B),
      },
      {
        'title': 'Roster Import Completed',
        'desc': 'Class list for CSC 401 successfully imported with 52 students.',
        'time': 'Yesterday',
        'icon': Icons.file_download_done_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Monthly Attendance Summary',
        'desc': 'September departmental report is ready for export and signature.',
        'time': '2 days ago',
        'icon': Icons.assessment_rounded,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4.5,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Notifications',
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accentLight,
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: const Text(
                          'Live Feed',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            color: AppColors.accent,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...notifications.map((item) {
                final icon = item['icon'] as IconData;
                final color = item['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] as String,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item['desc'] as String,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['time'] as String,
                              style: const TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                fontSize: 10.5,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SKELETON LOADING STATE ───────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const DashboardHeaderSkeleton(),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                const StatCardRowSkeleton(),
                const SizedBox(height: 12),
                const StatCardRowSkeleton(),
                const SizedBox(height: 24),
                ...List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: CourseCardSkeleton(),
                )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
