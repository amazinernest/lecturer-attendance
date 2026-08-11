import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../core/utils/sample_data.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/models/attendance_session.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/course_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/quick_action_hub.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
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

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: coursesAsync.when(
        data: (courses) {
          final activeCourses = courses.where((c) => c.status == CourseStatus.active).toList();
          return _DashboardContent(courses: activeCourses);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryContainer),
        ),
        error: (err, stack) => Center(
          child: Text('Error loading courses: $err'),
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerStatefulWidget {
  final List<Course> courses;

  const _DashboardContent({required this.courses});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  int _selectedTab = 0; // 0 = Courses, 1 = Recent Sessions

  void _showCoursePickerModal(BuildContext context, String title, Function(Course) onSelect) {
    if (widget.courses.isEmpty) {
      context.push('/courses/create');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.titleMd.copyWith(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = widget.courses[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            c.courseCode,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.primaryContainer,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        title: Text(
                          c.courseTitle,
                          style: AppTypography.titleMd.copyWith(fontSize: 15),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text('${c.department} • ${c.level}'),
                        trailing: const Icon(Icons.chevron_right, size: 18),
                        onTap: () {
                          Navigator.pop(context);
                          onSelect(c);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(currentUserProvider);

    final greetingHour = DateTime.now().hour;
    final timeGreeting = greetingHour < 12
        ? 'Good Morning,'
        : greetingHour < 17
            ? 'Good Afternoon,'
            : 'Good Evening,';

    final todayFormatted = DateFormat('EEEE, d MMMM yyyy').format(DateTime.now());

    return FutureBuilder(
      future: Future.wait(widget.courses.map((c) async {
        final students = await db.getStudentsForCourse(c.id);
        final sessions = await db.getSessionsForCourse(c.id);
        final records = await db.getAllRecordsForCourse(c.id);

        final recordMap = <String, Map<String, bool>>{};
        for (final r in records) {
          recordMap.putIfAbsent(r.attendanceSessionId, () => {})[r.studentId] = (r.status == AttendanceStatus.present);
        }

        final studentStatsList = students.map((s) {
          int attended = 0;
          for (final sess in sessions) {
            if (recordMap[sess.id]?[s.id] == true) attended++;
          }
          return AttendanceCalculator.calculateStudentStats(
            totalClassesHeld: sessions.length,
            classesAttended: attended,
          );
        }).toList();

        final summary = AttendanceCalculator.calculateCourseSummary(
          classesHeld: sessions.length,
          studentStatsList: studentStatsList,
        );

        return {
          'course': c,
          'studentCount': students.length,
          'classesHeld': sessions.length,
          'avgPct': summary.averageAttendancePercentage,
          'sessions': sessions,
        };
      })),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer));
        }

        final courseDataList = snapshot.data as List<Map<String, dynamic>>;

        // Dynamic Global Metrics
        final totalCoursesCount = widget.courses.length;
        int totalStudentsCount = 0;
        int totalClassesHeldCount = 0;
        double globalPctSum = 0.0;

        final allRecentSessions = <Map<String, dynamic>>[];

        for (final data in courseDataList) {
          final c = data['course'] as Course;
          final sList = data['sessions'] as List<AttendanceSession>;
          totalStudentsCount += data['studentCount'] as int;
          totalClassesHeldCount += data['classesHeld'] as int;
          globalPctSum += data['avgPct'] as double;

          for (final s in sList) {
            allRecentSessions.add({
              'session': s,
              'courseCode': c.courseCode,
              'courseId': c.id,
            });
          }
        }

        allRecentSessions.sort((a, b) {
          final dateA = (a['session'] as AttendanceSession).date;
          final dateB = (b['session'] as AttendanceSession).date;
          return dateB.compareTo(dateA);
        });

        final globalAvgAttendance = totalCoursesCount > 0
            ? (globalPctSum / totalCoursesCount)
            : 0.0;

        return RefreshIndicator(
          onRefresh: () async {
            if (user != null) {
              await ref.read(syncServiceProvider).syncNow(lecturerId: user.id);
            }
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. RICH DEEP GRADIENT HERO HEADER (Inspired by Image 2)
                Container(
                  padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 16, 20, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0F172A), // Deep Slate Navy
                        Color(0xFF1E1B4B), // Rich Indigo Accent
                      ],
                    ),
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                    boxShadow: [
                      BoxShadow(
                        color: Color(0x20000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header User Row
                      Row(
                        children: [
                          InkWell(
                            onTap: () => context.push('/profile'),
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                              ),
                              child: CircleAvatar(
                                radius: 22,
                                backgroundColor: const Color(0xFF312E81),
                                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                                child: user?.photoUrl == null
                                    ? Text(
                                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'D',
                                        style: AppTypography.titleMd.copyWith(color: Colors.white, fontSize: 16),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  timeGreeting,
                                  style: AppTypography.labelMd.copyWith(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  user?.name ?? 'Dr. Ernest',
                                  style: AppTypography.headlineLg.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Notification Icon with Badge
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 22),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFF97316),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Today's Date Banner Ribbon
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                                const SizedBox(width: 8),
                                Text(
                                  todayFormatted,
                                  style: AppTypography.labelMd.copyWith(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            Text(
                              'Term 2026',
                              style: AppTypography.labelMd.copyWith(color: const Color(0xFF818CF8), fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. OVERVIEW STAT CARDS GRID WITH SPARKLINE WAVES (Inspired by Image 1)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overview',
                            style: AppTypography.headlineLg.copyWith(fontSize: 20, fontWeight: FontWeight.w800),
                          ),
                          Text(
                            'Academic Year',
                            style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 12),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 1.45,
                        children: [
                          StatCard(
                            title: 'Active Courses',
                            value: '$totalCoursesCount',
                            backgroundColor: const Color(0xFFF3E8FF), // Soft Lavender
                            waveColor: const Color(0xFF9333EA),
                            textColor: const Color(0xFF3B0764),
                            onTap: () => context.push('/courses/create'),
                          ),
                          StatCard(
                            title: 'Total Students',
                            value: '$totalStudentsCount',
                            backgroundColor: const Color(0xFFE0F2FE), // Soft Cyan
                            waveColor: const Color(0xFF0284C7),
                            textColor: const Color(0xFF0C4A6E),
                            onTap: () {},
                          ),
                          StatCard(
                            title: 'Classes Held',
                            value: '$totalClassesHeldCount',
                            backgroundColor: const Color(0xFFFFEDD5), // Soft Peach/Orange
                            waveColor: const Color(0xFFEA580C),
                            textColor: const Color(0xFF7C2D12),
                            onTap: () => context.go('/reports'),
                          ),
                          StatCard(
                            title: 'Avg Attendance',
                            value: '${globalAvgAttendance.toStringAsFixed(0)}%',
                            backgroundColor: const Color(0xFFDCFCE7), // Soft Mint
                            waveColor: const Color(0xFF16A34A),
                            textColor: const Color(0xFF14532D),
                            onTap: () => context.go('/reports'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 3. QUICK ACTION BUTTONS HUB (Floating cards inspired by Image 2)
                      Text(
                        'Quick Hub',
                        style: AppTypography.headlineLg.copyWith(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 12),

                      QuickActionHub(
                        onTakeAttendance: () {
                          _showCoursePickerModal(
                            context,
                            'Select Course for Attendance',
                            (c) => context.push('/courses/${c.id}/record'),
                          );
                        },
                        onAddCourse: () => context.push('/courses/create'),
                        onImportRoster: () {
                          _showCoursePickerModal(
                            context,
                            'Select Course for Roster Import',
                            (c) => context.push('/courses/${c.id}/import'),
                          );
                        },
                        onViewAnalytics: () => context.go('/reports'),
                      ),

                      const SizedBox(height: 24),

                      // 4. TAB FILTER PILLS (Inspired by Image 1 "My Project (5)" / "Received (2)")
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              _TabFilterPill(
                                label: 'My Courses (${widget.courses.length})',
                                isSelected: _selectedTab == 0,
                                onTap: () => setState(() => _selectedTab = 0),
                              ),
                              const SizedBox(width: 8),
                              _TabFilterPill(
                                label: 'Recent (${allRecentSessions.length})',
                                isSelected: _selectedTab == 1,
                                onTap: () => setState(() => _selectedTab = 1),
                              ),
                            ],
                          ),
                          TextButton.icon(
                            onPressed: () => context.push('/courses/create'),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add'),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // TAB CONTENT
                      if (_selectedTab == 0) ...[
                        if (widget.courses.isEmpty)
                          EmptyStateWidget.noCourses(
                            onAddCourse: () => context.push('/courses/create'),
                          )
                        else
                          ...courseDataList.map((data) {
                            final course = data['course'] as Course;
                            return CourseCard(
                              course: course,
                              studentCount: data['studentCount'] as int,
                              classesHeldCount: data['classesHeld'] as int,
                              averageAttendancePct: data['avgPct'] as double,
                              onTap: () => context.push('/courses/${course.id}'),
                            );
                          }),
                      ] else ...[
                        if (allRecentSessions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: Text('No attendance sessions recorded yet.')),
                          )
                        else
                          ...allRecentSessions.take(5).map((data) {
                            final sess = data['session'] as AttendanceSession;
                            final cCode = data['courseCode'] as String;
                            final cId = data['courseId'] as String;
                            final dateStr = DateFormat('EEE, MMM d, yyyy').format(sess.date);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.cardBorder),
                                boxShadow: const [
                                  BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2)),
                                ],
                              ),
                              child: ListTile(
                                onTap: () => context.push('/courses/$cId/record?sessionId=${sess.id}'),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '#${sess.classNumber}',
                                    style: AppTypography.titleMd.copyWith(
                                      color: const Color(0xFF4F46E5),
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  '$cCode — ${sess.topic}',
                                  style: AppTypography.titleMd.copyWith(fontSize: 15, fontWeight: FontWeight.w700),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                                trailing: const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.secondary),
                              ),
                            );
                          }),
                      ],

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TabFilterPill extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabFilterPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelMd.copyWith(
            color: isSelected ? Colors.white : const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
