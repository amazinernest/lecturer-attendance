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
import '../../../shared/widgets/empty_state.dart';
import 'course_settings_sheet.dart';

class CourseDashboardScreen extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDashboardScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseDashboardScreen> createState() => _CourseDashboardScreenState();
}

class _CourseDashboardScreenState extends ConsumerState<CourseDashboardScreen> with SingleTickerProviderStateMixin {
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
            appBar: AppBar(title: const Text('Course Dashboard')),
            body: const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
          );
        }

        final students = studentsAsync.value ?? [];
        final sessions = sessionsAsync.value ?? [];

        return FutureBuilder(
          future: db.getAllRecordsForCourse(widget.courseId),
          builder: (context, recordsSnapshot) {
            final records = recordsSnapshot.data ?? [];

            // Record Map: sessionId -> studentId -> isPresent
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

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: AppBar(
                title: Text(course.courseCode, style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700)),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => CourseSettingsSheet.show(context, ref, course),
                  ),
                ],
              ),
              body: Column(
                children: [
                  // Course Header Summary Box
                  Container(
                    width: double.infinity,
                    color: AppColors.surface,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.courseTitle,
                          style: AppTypography.headlineLg.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Text('${students.length} Students', style: AppTypography.labelMd),
                            const Text('  •  ', style: TextStyle(color: AppColors.outline)),
                            Text('${sessions.length} / ${course.expectedClasses} Classes', style: AppTypography.labelMd),
                            const Text('  •  ', style: TextStyle(color: AppColors.outline)),
                            Text(
                              '${summary.averageAttendancePercentage.toStringAsFixed(0)}% Attendance',
                              style: AppTypography.labelMd.copyWith(
                                color: summary.averageAttendancePercentage >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    color: AppColors.surface,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primaryContainer,
                      unselectedLabelColor: AppColors.secondary,
                      indicatorColor: AppColors.primaryContainer,
                      indicatorWeight: 3,
                      labelStyle: AppTypography.titleMd.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
                      tabs: const [
                        Tab(text: 'Attendance'),
                        Tab(text: 'Students'),
                        Tab(text: 'Summary'),
                      ],
                    ),
                  ),

                  const Divider(height: 1),

                  // Tab Content Views
                  Expanded(
                    child: TabBarView(
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
                          onSearchChanged: (val) => setState(() => _studentSearchQuery = val),
                        ),

                        // Tab 3: Summary Statistics
                        _SummaryTab(summary: summary),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

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
    final dateFormat = DateFormat('dd MMMM yyyy');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: sessions.isEmpty
          ? EmptyStateWidget.noAttendance(
              onRecordFirstClass: () => context.push('/courses/$courseId/record'),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final presentCount = recordMap[session.id]?.values.where((v) => v == true).length ?? 0;

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    title: Text(
                      'Class ${session.classNumber} — ${session.topic}',
                      style: AppTypography.titleMd.copyWith(fontSize: 16),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        dateFormat.format(session.date),
                        style: AppTypography.labelMd,
                      ),
                    ),
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$presentCount / $studentCount Present',
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () => context.push('/courses/$courseId/record?sessionId=${session.id}'),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryContainer,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('+ Record Attendance'),
        onPressed: () => context.push('/courses/$courseId/record'),
      ),
    );
  }
}

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
        onUploadClassList: () => context.push('/courses/$courseId/import'),
      );
    }

    final query = searchQuery.trim().toLowerCase();
    final filteredIndices = <int>[];
    for (int i = 0; i < students.length; i++) {
      final s = students[i];
      if (s.name.toLowerCase().contains(query) || s.matricNumber.toLowerCase().contains(query)) {
        filteredIndices.add(i);
      }
    }

    return Column(
      children: [
        // Search & Add Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: onSearchChanged,
                  decoration: const InputDecoration(
                    hintText: 'Search name or matric number...',
                    prefixIcon: Icon(Icons.search, color: AppColors.secondary),
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.person_add_outlined),
                style: IconButton.styleFrom(backgroundColor: AppColors.primaryContainer),
                onPressed: () => context.push('/courses/$courseId/import'),
                tooltip: 'Import Students',
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: filteredIndices.length,
            itemBuilder: (context, idx) {
              final studentIndex = filteredIndices[idx];
              final s = students[studentIndex];
              final stats = studentStatsList[studentIndex];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.1),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0].toUpperCase() : 'S',
                      style: AppTypography.titleMd.copyWith(color: AppColors.primaryContainer, fontSize: 14),
                    ),
                  ),
                  title: Text(s.name, style: AppTypography.titleMd.copyWith(fontSize: 15)),
                  subtitle: Text(s.matricNumber, style: AppTypography.labelMd),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${stats.classesAttended} / $totalSessions',
                        style: AppTypography.titleMd.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        stats.formattedPercentage,
                        style: AppTypography.labelMd.copyWith(
                          color: stats.percentage >= 75 ? AppColors.presentGreen : AppColors.absentRed,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => context.push('/courses/$courseId/students/${s.id}'),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _SummaryTab extends StatelessWidget {
  final CourseAttendanceSummary summary;

  const _SummaryTab({required this.summary});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Stats Grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _SummaryBox(title: 'Total Students', value: '${summary.totalStudents}', icon: Icons.groups_outlined),
            _SummaryBox(title: 'Classes Held', value: '${summary.classesHeld}', icon: Icons.event_note_outlined),
            _SummaryBox(
              title: '100% Attendance',
              value: '${summary.studentsWithHundredPercent}',
              icon: Icons.star_outline,
              color: AppColors.presentGreen,
            ),
            _SummaryBox(
              title: 'Below 75% Risk',
              value: '${summary.studentsBelow75Percent}',
              icon: Icons.warning_amber_rounded,
              color: AppColors.absentRed,
            ),
          ],
        ),

        const SizedBox(height: 24),

        Text(
          'Attendance Distribution',
          style: AppTypography.titleMd.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: summary.distribution.entries.map((entry) {
                final count = entry.value;
                final fraction = summary.totalStudents > 0 ? count / summary.totalStudents : 0.0;
                Color barColor = AppColors.primaryContainer;
                if (entry.key == '<50%') barColor = AppColors.absentRed;
                if (entry.key == '50-74%') barColor = AppColors.warningOrange;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: AppTypography.labelMd.copyWith(fontWeight: FontWeight.w600)),
                          Text('$count Students (${(fraction * 100).toStringAsFixed(0)}%)', style: AppTypography.labelMd),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: fraction,
                          minHeight: 8,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation<Color>(barColor),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;

  const _SummaryBox({
    required this.title,
    required this.value,
    required this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color ?? AppColors.primaryContainer),
            const SizedBox(height: 6),
            Text(value, style: AppTypography.statLg.copyWith(fontSize: 22, color: color ?? AppColors.primaryContainer)),
            const SizedBox(height: 2),
            Text(title, style: AppTypography.labelMd.copyWith(fontSize: 12), maxLines: 1),
          ],
        ),
      ),
    );
  }
}
