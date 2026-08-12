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
import '../../../shared/widgets/skeleton_loader.dart';
import 'course_settings_sheet.dart';

class CoursesScreen extends ConsumerStatefulWidget {
  const CoursesScreen({super.key});

  @override
  ConsumerState<CoursesScreen> createState() => _CoursesScreenState();
}

class _CoursesScreenState extends ConsumerState<CoursesScreen> {
  String _searchQuery = '';
  String _selectedFilter = 'All'; // All, Active, Archived, Completed
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coursesAsync = ref.watch(coursesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────
            Container(
              color: AppColors.surface,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('My Courses', style: AppTypography.displayLg.copyWith(fontSize: 24)),
                      _AddCourseButton(
                          onTap: () => context.push('/courses/create')),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Search field
                  TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim().toLowerCase()),
                    decoration: InputDecoration(
                      hintText: 'Search courses, department…',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: ['All', 'Active', 'Archived', 'Completed']
                          .map((f) => _FilterChip(
                                label: f,
                                isSelected: _selectedFilter == f,
                                onTap: () =>
                                    setState(() => _selectedFilter = f),
                              ))
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // ── Course List ──────────────────────────────────────────────
            Expanded(
              child: coursesAsync.when(
                data: (courses) {
                  final filtered = courses.where((c) {
                    final q = _searchQuery;
                    final matchSearch = q.isEmpty ||
                        c.courseCode.toLowerCase().contains(q) ||
                        c.courseTitle.toLowerCase().contains(q) ||
                        c.department.toLowerCase().contains(q);

                    if (!matchSearch) return false;
                    if (_selectedFilter == 'Active') {
                      return c.status == CourseStatus.active;
                    }
                    if (_selectedFilter == 'Archived') {
                      return c.status == CourseStatus.archived;
                    }
                    if (_selectedFilter == 'Completed') {
                      return c.status == CourseStatus.completed;
                    }
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return _searchQuery.isNotEmpty
                        ? EmptyStateWidget.searchEmpty(query: _searchQuery)
                        : EmptyStateWidget.noCourses(
                            onAddCourse: () =>
                                context.push('/courses/create'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) =>
                        _CourseListItem(course: filtered[index]),
                  );
                },
                loading: () => ListView(
                  padding: const EdgeInsets.all(16),
                  children: List.generate(
                    4,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CourseCardSkeleton(),
                    ),
                  ),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseListItem extends ConsumerWidget {
  final Course course;

  const _CourseListItem({required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final db = ref.watch(databaseProvider);

    return FutureBuilder(
      future: Future.wait([
        db.getStudentsForCourse(course.id),
        db.getSessionsForCourse(course.id),
        db.getAllRecordsForCourse(course.id),
      ]),
      builder: (context, snapshot) {
        final studentCount =
            snapshot.hasData ? (snapshot.data![0] as List).length : 0;
        final sessions = snapshot.hasData ? (snapshot.data![1] as List) : [];
        final records = snapshot.hasData ? (snapshot.data![2] as List) : [];

        int totalPresent = 0;
        for (final r in records.cast<AttendanceRecord>()) {
          if (r.status == AttendanceStatus.present) totalPresent++;
        }
        final totalRecords = sessions.length * studentCount;
        final avgPct =
            AttendanceCalculator.calculatePercentage(totalPresent, totalRecords);

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
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _AddCourseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCourseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              'Add Course',
              style: AppTypography.caption.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isSelected ? Colors.white : AppColors.textSecondary,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
