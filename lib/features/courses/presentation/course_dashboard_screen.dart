import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/student.dart';
import '../../../shared/models/attendance_session.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/attendance_progress_ring.dart';
import '../../../shared/widgets/empty_state.dart';
import 'course_settings_sheet.dart';

class CourseDashboardScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDashboardScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDashboardScreen> createState() =>
      _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends ConsumerState<CourseDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _studentSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final db = ref.watch(databaseProvider);
    final studentsAsync = ref.watch(studentsStreamProvider(widget.courseId));
    final sessionsAsync = ref.watch(sessionsStreamProvider(widget.courseId));

    return FutureBuilder<Course?>(
      future: db.getCourseById(widget.courseId),
      builder: (context, courseSnapshot) {
        final course = courseSnapshot.data;

        if (course == null) {
          return Scaffold(
            appBar: AppBar(title: const Text('Course')),
            body: const Center(
                child: CircularProgressIndicator(color: AppColors.accent)),
          );
        }

        final students = studentsAsync.value ?? [];
        final sessions = sessionsAsync.value ?? [];

        return FutureBuilder(
          future: db.getAllRecordsForCourse(widget.courseId),
          builder: (context, recordsSnapshot) {
            final records = recordsSnapshot.data ?? [];

            // Record Map: sessionId → studentId → isPresent
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

            final avgPct = summary.averageAttendancePercentage;
            final avgColor = avgPct >= 75
                ? AppColors.success
                : avgPct >= 50
                    ? AppColors.warning
                    : AppColors.error;

            return Scaffold(
              backgroundColor: AppColors.background,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerScrolled) => [
                  SliverAppBar(
                    pinned: true,
                    expandedHeight: 220,
                    backgroundColor: AppColors.navyDeep,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    leading: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back_rounded,
                            size: 18, color: Colors.white),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    actions: [
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.more_vert,
                              size: 18, color: Colors.white),
                        ),
                        onPressed: () =>
                            CourseSettingsSheet.show(context, ref, course),
                      ),
                      const SizedBox(width: 8),
                    ],
                    flexibleSpace: FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      background: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                          ),
                        ),
                        child: SafeArea(
                          child: Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 60, 20, 16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      // Code + level pills
                                      Row(
                                        children: [
                                          _WhitePill(
                                              label: course.courseCode),
                                          const SizedBox(width: 8),
                                          _WhitePill(label: course.level),
                                          const SizedBox(width: 8),
                                          _WhitePill(label: course.semester),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Course title
                                      Text(
                                        course.courseTitle,
                                        style: AppTypography.headlineLg
                                            .copyWith(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),

                                      const SizedBox(height: 4),
                                      Text(
                                        course.department,
                                        style: AppTypography.bodyMd.copyWith(
                                          color: Colors.white
                                              .withValues(alpha: 0.6),
                                          fontSize: 13,
                                        ),
                                      ),

                                      const SizedBox(height: 14),

                                      // Compact stat row
                                      Row(
                                        children: [
                                          _HeroStat(
                                            label: 'Students',
                                            value: '${students.length}',
                                          ),
                                          _StatDivider(),
                                          _HeroStat(
                                            label: 'Classes',
                                            value:
                                                '${sessions.length}/${course.expectedClasses}',
                                          ),
                                          _StatDivider(),
                                          _HeroStat(
                                            label: 'Avg Attend.',
                                            value:
                                                '${avgPct.toStringAsFixed(0)}%',
                                            valueColor: avgColor,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                // Attendance ring
                                AttendanceProgressRing(
                                  percentage: avgPct,
                                  size: 76,
                                  strokeWidth: 7,
                                  textColor: Colors.white,
                                  trackColor: Colors.white.withValues(alpha: 0.2),
                                  ringColor: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    bottom: PreferredSize(
                      preferredSize: const Size.fromHeight(48),
                      child: Container(
                        color: AppColors.navyDeep,
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor:
                              Colors.white.withValues(alpha: 0.5),
                          indicatorColor: AppColors.accent,
                          indicatorWeight: 3,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: AppTypography.titleSm.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          unselectedLabelStyle:
                              AppTypography.titleSm.copyWith(fontSize: 14),
                          tabs: const [
                            Tab(text: 'Attendance'),
                            Tab(text: 'Students'),
                            Tab(text: 'Summary'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
                body: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Attendance Sessions
                    _AttendanceTab(
                      courseId: widget.courseId,
                      sessions: sessions,
                      studentCount: students.length,
                      recordMap: recordMap,
                    ),

                    // Tab 2: Students List
                    _StudentsTab(
                      courseId: widget.courseId,
                      students: students,
                      totalSessions: sessions.length,
                      studentStatsList: studentStatsList,
                      searchQuery: _studentSearchQuery,
                      onSearchChanged: (val) =>
                          setState(() => _studentSearchQuery = val),
                    ),

                    // Tab 3: Summary Statistics
                    _SummaryTab(
                      summary: summary,
                      course: course,
                      sessions: sessions,
                      studentCount: students.length,
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ── Attendance Tab ─────────────────────────────────────────────────────────────
class _AttendanceTab extends StatelessWidget {
  final String courseId;
  final List<AttendanceSession> sessions;
  final int studentCount;
  final Map<String, Map<String, bool>> recordMap;

  const _AttendanceTab({
    required this.courseId,
    required this.sessions,
    required this.studentCount,
    required this.recordMap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEE, d MMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sessions.isEmpty
          ? EmptyStateWidget.noAttendance(
              onRecordFirstClass: () =>
                  context.push('/courses/$courseId/record'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                final presentCount = recordMap[session.id]
                        ?.values
                        .where((v) => v == true)
                        .length ??
                    0;
                final pct = studentCount > 0
                    ? (presentCount / studentCount * 100)
                    : 0.0;
                final isGood = pct >= 75;

                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => context.push(
                          '/courses/$courseId/record?sessionId=${session.id}'),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            // Class number badge
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: AppColors.accentLight,
                                borderRadius: BorderRadius.circular(12),
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

                            const SizedBox(width: 12),

                            // Session info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    session.topic,
                                    style: AppTypography.titleSm
                                        .copyWith(fontSize: 14),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    dateFormat.format(session.date),
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),

                            // Present/total badge
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isGood
                                    ? AppColors.successBg
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(
                                '$presentCount / $studentCount',
                                style: AppTypography.caption.copyWith(
                                  color: isGood
                                      ? AppColors.success
                                      : AppColors.error,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(width: 6),
                            const Icon(Icons.chevron_right_rounded,
                                size: 18, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/courses/$courseId/record'),
        icon: const Icon(Icons.how_to_reg_rounded, size: 20),
        label: const Text('Record Attendance'),
      ),
    );
  }
}

// ── Students Tab ───────────────────────────────────────────────────────────────
class _StudentsTab extends StatelessWidget {
  final String courseId;
  final List<Student> students;
  final int totalSessions;
  final List<StudentAttendanceStats> studentStatsList;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;

  const _StudentsTab({
    required this.courseId,
    required this.students,
    required this.totalSessions,
    required this.studentStatsList,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return EmptyStateWidget.noStudents(
          onUploadClassList: () =>
              context.push('/courses/$courseId/import'));
    }

    final query = searchQuery.trim().toLowerCase();
    final filteredIndices = <int>[];
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      if (s.name.toLowerCase().contains(query) ||
          s.matricNumber.toLowerCase().contains(query)) {
        filteredIndices.add(i);
      }
    }

    return Column(
      children: [
        // Search bar + import action
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search students…',
                    prefixIcon: Icon(Icons.search_rounded, size: 18),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => context.push('/courses/$courseId/import'),
                child: Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.upload_rounded,
                      size: 20, color: AppColors.accent),
                ),
              ),
            ],
          ),
        ),

        // Student count label
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${filteredIndices.length} students',
                style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Text(
                '$totalSessions sessions',
                style: AppTypography.caption,
              ),
            ],
          ),
        ),

        Expanded(
          child: filteredIndices.isEmpty
              ? EmptyStateWidget.searchEmpty(query: searchQuery)
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: filteredIndices.length,
                  itemBuilder: (context, i) {
                    final idx = filteredIndices[i];
                    final s = students[idx];
                    final stats = studentStatsList[idx];
                    final isAtRisk = stats.percentage < 75;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        onTap: () => context.push(
                            '/courses/$courseId/students/${s.id}'),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: CircleAvatar(
                          radius: 20,
                          backgroundColor: isAtRisk
                              ? AppColors.errorBg
                              : AppColors.accentLight,
                          child: Text(
                            s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                            style: AppTypography.titleSm.copyWith(
                              color: isAtRisk ? AppColors.error : AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        title: Text(s.name,
                            style: AppTypography.titleSm.copyWith(fontSize: 14)),
                        subtitle: Text(s.matricNumber,
                            style: AppTypography.caption),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              stats.formattedPercentage,
                              style: AppTypography.titleSm.copyWith(
                                color: isAtRisk
                                    ? AppColors.error
                                    : AppColors.success,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '${stats.classesAttended}/$totalSessions',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ── Summary Tab ───────────────────────────────────────────────────────────────
class _SummaryTab extends StatelessWidget {
  final CourseAttendanceSummary summary;
  final Course course;
  final List<AttendanceSession> sessions;
  final int studentCount;

  const _SummaryTab({
    required this.summary,
    required this.course,
    required this.sessions,
    required this.studentCount,
  });

  @override
  Widget build(BuildContext context) {
    final avgPct = summary.averageAttendancePercentage;
    final avgColor = avgPct >= 75
        ? AppColors.success
        : avgPct >= 50
            ? AppColors.warning
            : AppColors.error;
    final atRisk = summary.studentsBelow75Percent;
    final onTrack = studentCount - atRisk;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Attendance ring card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              AttendanceProgressRing(
                percentage: avgPct,
                size: 100,
                strokeWidth: 10,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Course Attendance',
                      style: AppTypography.caption.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${avgPct.toStringAsFixed(1)}%',
                      style: AppTypography.statLg.copyWith(
                        color: avgColor,
                        fontSize: 32,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      avgPct >= 75 ? 'On track 🎯' : 'Needs attention ⚠️',
                      style: AppTypography.bodyMd.copyWith(
                        color: avgColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Stats grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.6,
          children: [
            _SummaryStatBox(
              title: 'ON TRACK',
              value: '$onTrack',
              subtitle: 'students',
              bg: AppColors.successBg,
              color: AppColors.success,
            ),
            _SummaryStatBox(
              title: 'AT RISK (<75%)',
              value: '$atRisk',
              subtitle: 'students',
              bg: AppColors.errorBg,
              color: AppColors.error,
            ),
            _SummaryStatBox(
              title: 'CLASSES HELD',
              value: '${sessions.length}',
              subtitle: 'of ${course.expectedClasses}',
              bg: AppColors.accentLight,
              color: AppColors.accent,
            ),
            _SummaryStatBox(
              title: 'STUDENTS',
              value: '$studentCount',
              subtitle: 'enrolled',
              bg: AppColors.warningBg,
              color: AppColors.warning,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Attendance distribution bar
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Attendance Distribution',
                  style: AppTypography.headlineMd.copyWith(fontSize: 15)),
              const SizedBox(height: 14),
              _DistributionBar(
                label: 'On Track (≥75%)',
                count: onTrack,
                total: studentCount,
                color: AppColors.success,
              ),
              const SizedBox(height: 10),
              _DistributionBar(
                label: 'At Risk (<75%)',
                count: atRisk,
                total: studentCount,
                color: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DistributionBar extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _DistributionBar({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.bodyMd.copyWith(fontSize: 13)),
            Text(
              '$count students',
              style: AppTypography.caption.copyWith(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(pct * 100).toStringAsFixed(0)}%',
          style: AppTypography.caption.copyWith(color: color),
        ),
      ],
    );
  }
}

class _SummaryStatBox extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color bg;
  final Color color;

  const _SummaryStatBox({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.bg,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTypography.caption.copyWith(
              color: color.withValues(alpha: 0.7),
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: AppTypography.statLg.copyWith(
                    color: color, fontSize: 24, fontWeight: FontWeight.w800),
              ),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                    color: color.withValues(alpha: 0.6)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Small Widgets ─────────────────────────────────────────────────────────────

class _WhitePill extends StatelessWidget {
  final String label;
  const _WhitePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _HeroStat({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.statMd.copyWith(
            color: valueColor ?? Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}
