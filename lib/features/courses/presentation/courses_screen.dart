import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/utils/attendance_calculator.dart';
import '../../../shared/models/course.dart';
import '../../../shared/models/attendance_record.dart';
import '../../../shared/widgets/course_card.dart';
import '../../../shared/widgets/empty_state.dart';
import 'course_settings_sheet.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Archived, Completed

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Courses',
          style: AppTypography.headlineLg.copyWith(fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.primaryContainer),
            onPressed: () => context.push('/courses/create'),
            tooltip: 'Add Course',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Search courses...',
                prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                fillColor: AppColors.surface,
                filled: true,
              ),
            ),
          ),

          // Filter Chips (All, Active, Archived, Completed)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: ['All', 'Active', 'Archived', 'Completed'].map((filter) {
                final isSelected = _selectedFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(filter),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedFilter = filter);
                    },
                    selectedColor: AppColors.primaryContainer,
                    labelStyle: AppTypography.labelMd.copyWith(
                      color: isSelected ? AppColors.onPrimary : AppColors.onSurface,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surface,
                    side: BorderSide(
                      color: isSelected ? AppColors.primaryContainer : AppColors.outlineVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Course List View
          Expanded(
            child: coursesAsync.when(
              data: (courses) {
                final filtered = courses.where((c) {
                  final matchesSearch = c.courseCode.toLowerCase().contains(_searchQuery) ||
                      c.courseTitle.toLowerCase().contains(_searchQuery) ||
                      c.department.toLowerCase().contains(_searchQuery);

                  if (!matchesSearch) return false;

                  if (_selectedFilter == 'Active') return c.status == CourseStatus.active;
                  if (_selectedFilter == 'Archived') return c.status == CourseStatus.archived;
                  if (_selectedFilter == 'Completed') return c.status == CourseStatus.completed;

                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget.noCourses(
                    onAddCourse: () => context.push('/courses/create'),
                  );
                }

                return _CourseListView(courses: filtered);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primaryContainer)),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }
}

class _CourseListView extends ConsumerWidget {
  final List<Course> courses;

  const _CourseListView({required this.courses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        return FutureBuilder(
          future: Future.wait([
            db.getStudentsForCourse(course.id),
            db.getSessionsForCourse(course.id),
            db.getAllRecordsForCourse(course.id),
          ]),
          builder: (context, snapshot) {
            final studentCount = snapshot.hasData ? (snapshot.data![0] as List).length : 0;
            final sessions = snapshot.hasData ? (snapshot.data![1] as List) : [];
            final records = snapshot.hasData ? (snapshot.data![2] as List) : [];

            int totalPresent = 0;
            for (final r in records.cast<AttendanceRecord>()) {
              if (r.status == AttendanceStatus.present) totalPresent++;
            }
            final totalRecordCount = sessions.length * studentCount;
            final avgPct = AttendanceCalculator.calculatePercentage(totalPresent, totalRecordCount);

            return CourseCard(
              course: course,
              studentCount: studentCount,
              classesHeldCount: sessions.length,
              averageAttendancePct: avgPct,
              onTap: () => context.push('/courses/${course.id}'),
              onMoreTap: () => CourseSettingsSheet.show(context, ref, course),
            );
          },
        );
      },
    );
  }
}
