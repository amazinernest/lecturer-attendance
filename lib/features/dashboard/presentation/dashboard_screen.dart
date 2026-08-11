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
    final user = ref.watch(currentUserProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);

    final greetingHour = DateTime.now().hour;
    final timeGreeting = greetingHour < 12
        ? 'Good morning'
        : greetingHour < 17
            ? 'Good afternoon'
            : 'Good evening';

    final todayFormatted = DateFormat('EEEE, d MMMM').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$timeGreeting, ${user?.name ?? 'Dr. Ernest'}',
              style: AppTypography.titleMd.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              todayFormatted,
              style: AppTypography.labelMd.copyWith(
                fontSize: 12,
                color: AppColors.secondary,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: InkWell(
              onTap: () => context.push('/profile'),
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryContainer,
                backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                child: user?.photoUrl == null
                    ? Text(
                        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'D',
                        style: AppTypography.titleMd.copyWith(color: AppColors.onPrimary, fontSize: 14),
                      )
                    : null,
              ),
            ),
          ),
        ],
      ),
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

class _DashboardContent extends ConsumerWidget {
  final List<Course> courses;

  const _DashboardContent({required this.courses});

  void _showCoursePickerModal(BuildContext context, String title, Function(Course) onSelect) {
    if (courses.isEmpty) {
      context.push('/courses/create');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
                    itemCount: courses.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final c = courses[index];
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
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);
    final user = ref.watch(currentUserProvider);

    return FutureBuilder(
      future: Future.wait(courses.map((c) async {
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

        // Dynamic Global Summary Calculations
        final totalCoursesCount = courses.length;
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
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Quick Actions Bar
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

              const SizedBox(height: 20),

              // 2x2 Overview Metrics Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Active Courses',
                    value: '$totalCoursesCount',
                    icon: Icons.book_outlined,
                  ),
                  StatCard(
                    title: 'Total Students',
                    value: '$totalStudentsCount',
                    icon: Icons.people_outline,
                  ),
                  StatCard(
                    title: 'Classes Held',
                    value: '$totalClassesHeldCount',
                    icon: Icons.event_note_outlined,
                  ),
                  StatCard(
                    title: 'Avg Attendance',
                    value: '${globalAvgAttendance.toStringAsFixed(0)}%',
                    icon: Icons.pie_chart_outline,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Recent Sessions Section (if any sessions exist)
              if (allRecentSessions.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Sessions',
                      style: AppTypography.headlineLg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    TextButton(
                      onPressed: () => context.go('/reports'),
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...allRecentSessions.take(3).map((data) {
                  final sess = data['session'] as AttendanceSession;
                  final cCode = data['courseCode'] as String;
                  final cId = data['courseId'] as String;
                  final dateStr = DateFormat('MMM d, yyyy').format(sess.date);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: ListTile(
                      onTap: () => context.push('/courses/$cId/record?sessionId=${sess.id}'),
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primaryContainer.withValues(alpha: 0.08),
                        child: Text(
                          '#${sess.classNumber}',
                          style: AppTypography.labelMd.copyWith(
                            color: AppColors.primaryContainer,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      title: Text(
                        '$cCode - ${sess.topic}',
                        style: AppTypography.titleMd.copyWith(fontSize: 14),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(dateStr, style: const TextStyle(fontSize: 12, color: AppColors.secondary)),
                      trailing: const Icon(Icons.chevron_right, size: 18, color: AppColors.secondary),
                    ),
                  );
                }),
                const SizedBox(height: 20),
              ],

              // My Courses Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Courses',
                    style: AppTypography.headlineLg.copyWith(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/courses/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Course'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              if (courses.isEmpty)
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
            ],
          ),
        );
      },
    );
  }
}
