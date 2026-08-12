import 'dart:math' as math;
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
import '../../../shared/widgets/skeleton_loader.dart';

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
      backgroundColor: AppColors.background,
      body: coursesAsync.when(
        data: (courses) {
          final activeCourses =
              courses.where((c) => c.status == CourseStatus.active).toList();
          return _DashboardContent(courses: activeCourses);
        },
        loading: () => const _DashboardSkeleton(),
        error: (err, stack) => Center(
          child: Text('Error loading dashboard: $err'),
        ),
      ),
    );
  }
}

// ── Skeleton Loading State ───────────────────────────────────────────────────
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header skeleton
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

// ── Dashboard Content ─────────────────────────────────────────────────────────
class _DashboardContent extends ConsumerStatefulWidget {
  final List<Course> courses;

  const _DashboardContent({required this.courses});

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  int _selectedTab = 0; // 0 = Courses, 1 = Recent Sessions

  void _showCoursePickerModal(
      BuildContext context, String title, Function(Course) onSelect) {
    if (widget.courses.isEmpty) {
      context.push('/courses/create');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
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
                      title,
                      style: AppTypography.headlineMd,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: widget.courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = widget.courses[index];
                      return ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            c.courseCode,
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        title: Text(
                          c.courseTitle,
                          style: AppTypography.titleSm,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(
                          '${c.department} · ${c.level}',
                          style: AppTypography.caption,
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textMuted),
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

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : hour < 17
            ? 'Good Afternoon'
            : 'Good Evening';

    final dateStr =
        DateFormat('EEEE, d MMMM').format(DateTime.now());

    return FutureBuilder(
      future: Future.wait(widget.courses.map((c) async {
        final students = await db.getStudentsForCourse(c.id);
        final sessions = await db.getSessionsForCourse(c.id);
        final records = await db.getAllRecordsForCourse(c.id);

        final recordMap = <String, Map<String, bool>>{};
        for (final r in records) {
          recordMap.putIfAbsent(r.attendanceSessionId,
              () => {})[r.studentId] = (r.status == AttendanceStatus.present);
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
          return const _DashboardSkeleton();
        }

        final courseDataList =
            snapshot.data as List<Map<String, dynamic>>;

        // Global metrics
        final totalCourses = widget.courses.length;
        int totalStudents = 0;
        int totalClasses = 0;
        double pctSum = 0.0;
        final allRecentSessions = <Map<String, dynamic>>[];

        for (final data in courseDataList) {
          final c = data['course'] as Course;
          final sList = data['sessions'] as List<AttendanceSession>;
          totalStudents += data['studentCount'] as int;
          totalClasses += data['classesHeld'] as int;
          pctSum += data['avgPct'] as double;

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

        final globalAvg =
            totalCourses > 0 ? (pctSum / totalCourses) : 0.0;

        final avgColor = globalAvg >= 75
            ? AppColors.success
            : globalAvg >= 50
                ? AppColors.warning
                : AppColors.error;
        final avgBg = globalAvg >= 75
            ? AppColors.successBg
            : globalAvg >= 50
                ? AppColors.warningBg
                : AppColors.errorBg;

        return RefreshIndicator(
          color: AppColors.accent,
          onRefresh: () async {
            if (user != null) {
              await ref
                  .read(syncServiceProvider)
                  .syncNow(lecturerId: user.id);
            }
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // ── HEADER ─────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                    ),
                    borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(28)),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // User row
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () => context.go('/profile'),
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.3),
                                        width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 21,
                                    backgroundColor:
                                        AppColors.navyLight,
                                    backgroundImage: user?.photoUrl != null
                                        ? NetworkImage(user!.photoUrl!)
                                        : null,
                                    child: user?.photoUrl == null
                                        ? Text(
                                            (user?.name.isNotEmpty == true)
                                                ? user!.name[0].toUpperCase()
                                                : 'L',
                                            style: AppTypography.titleMd
                                                .copyWith(
                                                    color: Colors.white,
                                                    fontSize: 15),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      greeting,
                                      style: AppTypography.bodyMd.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.65),
                                          fontSize: 12),
                                    ),
                                    Text(
                                      user?.name ?? 'Dr. Ernest',
                                      style: AppTypography.headlineMd
                                          .copyWith(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              // Notification badge
                              Container(
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.notifications_none_rounded,
                                    color: Colors.white,
                                    size: 20),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Date + term chip
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      Colors.white.withValues(alpha: 0.1),
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded,
                                        size: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.7)),
                                    const SizedBox(width: 6),
                                    Text(
                                      dateStr,
                                      style: AppTypography.caption.copyWith(
                                        color: Colors.white
                                            .withValues(alpha: 0.9),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.3),
                                  borderRadius:
                                      BorderRadius.circular(100),
                                ),
                                child: Text(
                                  'Academic 2026',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Featured: Avg attendance card
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.09),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color:
                                      Colors.white.withValues(alpha: 0.12)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'AVERAGE ATTENDANCE',
                                        style: AppTypography.caption.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          letterSpacing: 0.8,
                                          fontSize: 10,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        '${globalAvg.toStringAsFixed(0)}%',
                                        style:
                                            AppTypography.statXL.copyWith(
                                          color: Colors.white,
                                          fontSize: 48,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Across $totalCourses active courses',
                                        style: AppTypography.bodyMd.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Visual arc indicator
                                _AttendanceArc(percentage: globalAvg),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ── BODY ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Stat cards grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                      childAspectRatio: 1.55,
                      children: [
                        StatCard(
                          title: 'COURSES',
                          value: '$totalCourses',
                          subtitle: 'active',
                          backgroundColor: AppColors.accentLight,
                          waveColor: AppColors.accent,
                          textColor: AppColors.navyMid,
                          onTap: () => context.go('/courses'),
                        ),
                        StatCard(
                          title: 'STUDENTS',
                          value: '$totalStudents',
                          subtitle: 'enrolled',
                          backgroundColor: const Color(0xFFEFF8FF),
                          waveColor: const Color(0xFF0EA5E9),
                          textColor: const Color(0xFF0C4A6E),
                          onTap: () {},
                        ),
                        StatCard(
                          title: 'CLASSES HELD',
                          value: '$totalClasses',
                          subtitle: 'sessions',
                          backgroundColor: AppColors.warningBg,
                          waveColor: AppColors.warning,
                          textColor: const Color(0xFF78350F),
                          onTap: () => context.go('/reports'),
                        ),
                        StatCard(
                          title: 'AVG ATTEND.',
                          value: '${globalAvg.toStringAsFixed(0)}%',
                          subtitle: globalAvg >= 75 ? 'on track' : 'needs attention',
                          backgroundColor: avgBg,
                          waveColor: avgColor,
                          textColor: avgColor,
                          onTap: () => context.go('/reports'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Quick actions
                    _SectionHeader(
                      title: 'Quick Actions',
                      trailing: null,
                    ),
                    const SizedBox(height: 12),
                    QuickActionHub(
                      onTakeAttendance: () => _showCoursePickerModal(
                        context,
                        'Select Course',
                        (c) => context.push('/courses/${c.id}/record'),
                      ),
                      onAddCourse: () => context.push('/courses/create'),
                      onImportRoster: () => _showCoursePickerModal(
                        context,
                        'Import Roster For',
                        (c) => context.push('/courses/${c.id}/import'),
                      ),
                      onViewAnalytics: () => context.go('/reports'),
                    ),

                    const SizedBox(height: 28),

                    // Tab filter + content
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _TabPill(
                              label: 'Courses',
                              count: widget.courses.length,
                              isSelected: _selectedTab == 0,
                              onTap: () => setState(() => _selectedTab = 0),
                            ),
                            const SizedBox(width: 8),
                            _TabPill(
                              label: 'Recent',
                              count: allRecentSessions.length,
                              isSelected: _selectedTab == 1,
                              onTap: () => setState(() => _selectedTab = 1),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => context.push('/courses/create'),
                          icon: const Icon(Icons.add_rounded, size: 15),
                          label: const Text('Add'),
                          style: TextButton.styleFrom(
                            textStyle: AppTypography.labelMd.copyWith(
                                fontSize: 13, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Tab content
                    if (_selectedTab == 0) ...[
                      if (widget.courses.isEmpty)
                        EmptyStateWidget.noCourses(
                            onAddCourse: () =>
                                context.push('/courses/create'))
                      else
                        ...courseDataList.map((data) {
                          final course = data['course'] as Course;
                          return CourseCard(
                            course: course,
                            studentCount: data['studentCount'] as int,
                            classesHeldCount: data['classesHeld'] as int,
                            averageAttendancePct: data['avgPct'] as double,
                            onTap: () =>
                                context.push('/courses/${course.id}'),
                          );
                        }),
                    ] else ...[
                      if (allRecentSessions.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(
                            child: Text(
                              'No attendance sessions recorded yet.',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        )
                      else
                        ...allRecentSessions.take(5).map((data) {
                          final sess =
                              data['session'] as AttendanceSession;
                          final cCode = data['courseCode'] as String;
                          final cId = data['courseId'] as String;
                          final dateStr2 =
                              DateFormat('EEE, MMM d').format(sess.date);

                          return _RecentSessionTile(
                            session: sess,
                            courseCode: cCode,
                            courseId: cId,
                            dateStr: dateStr2,
                          );
                        }),
                    ],

                    const SizedBox(height: 32),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _AttendanceArc extends StatelessWidget {
  final double percentage;
  const _AttendanceArc({required this.percentage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: CustomPaint(
        painter: _ArcPainter(percentage: percentage / 100),
        child: Center(
          child: Text(
            percentage.toStringAsFixed(0),
            style: AppTypography.caption.copyWith(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double percentage;
  const _ArcPainter({required this.percentage});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const strokeW = 6.0;
    final radius = (size.width - strokeW) / 2;

    final track = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeW
      ..strokeCap = StrokeCap.round;

    final arc = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
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
  bool shouldRepaint(_ArcPainter old) => old.percentage != percentage;
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTypography.headlineMd.copyWith(fontSize: 16)),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _TabPill extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabPill({
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.navyDeep : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(
          '$label ($count)',
          style: AppTypography.labelMd.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _RecentSessionTile extends StatelessWidget {
  final AttendanceSession session;
  final String courseCode;
  final String courseId;
  final String dateStr;

  const _RecentSessionTile({
    required this.session,
    required this.courseCode,
    required this.courseId,
    required this.dateStr,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        onTap: () =>
            context.push('/courses/$courseId/record?sessionId=${session.id}'),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.accentLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '#${session.classNumber}',
              style: AppTypography.titleSm.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          '$courseCode — ${session.topic}',
          style: AppTypography.titleSm.copyWith(fontSize: 14),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          dateStr,
          style: AppTypography.caption,
        ),
        trailing: const Icon(Icons.chevron_right_rounded,
            size: 18, color: AppColors.textMuted),
      ),
    );
  }
}
