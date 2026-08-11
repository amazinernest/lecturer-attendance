import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../core/utils/sample_data.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/stat_card.dart';
import '../../../shared/widgets/course_card.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/sync_status_badge.dart';

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
    final syncState = ref.watch(syncServiceProvider).state;

    final greetingHour = DateTime.now().hour;
    final timeGreeting = greetingHour < 12
        ? 'Good morning'
        : greetingHour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
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
              user?.email ?? '',
              style: AppTypography.labelMd.copyWith(fontSize: 12),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SyncStatusBadge(state: syncState),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

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

        for (final data in courseDataList) {
          totalStudentsCount += data['studentCount'] as int;
          totalClassesHeldCount += data['classesHeld'] as int;
          globalPctSum += data['avgPct'] as double;
        }

        final globalAvgAttendance = totalCoursesCount > 0
            ? (globalPctSum / totalCoursesCount)
            : 0.0;

        return RefreshIndicator(
          onRefresh: () async {
            final user = ref.read(currentUserProvider);
            if (user != null) {
              await ref.read(syncServiceProvider).syncNow(lecturerId: user.id);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stat Cards 2x2 Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: [
                  StatCard(
                    title: 'Courses',
                    value: '$totalCoursesCount',
                    icon: Icons.book_outlined,
                  ),
                  StatCard(
                    title: 'Students',
                    value: '$totalStudentsCount',
                    icon: Icons.people_outline,
                  ),
                  StatCard(
                    title: 'Classes Held',
                    value: '$totalClassesHeldCount',
                    icon: Icons.event_note_outlined,
                  ),
                  StatCard(
                    title: 'Average Attendance',
                    value: '${globalAvgAttendance.toStringAsFixed(0)}%',
                    icon: Icons.pie_chart_outline,
                    iconColor: AppColors.presentGreen,
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // My Courses Section Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Courses',
                    style: AppTypography.headlineLg.copyWith(fontSize: 20),
                  ),
                  TextButton.icon(
                    onPressed: () => context.push('/courses/create'),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('+ Add Course'),
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
