import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../shared/models/course.dart';
import 'create_course_screen.dart';

class CourseSettingsSheet extends StatelessWidget {
  final Course course;
  final WidgetRef ref;

  const CourseSettingsSheet({super.key, required this.course, required this.ref});

  static void show(BuildContext context, WidgetRef ref, Course course) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => CourseSettingsSheet(course: course, ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.courseCode,
                    style: AppTypography.titleMd.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Text(
                    course.courseTitle,
                    style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.primaryContainer),
              title: const Text('Edit Course Details'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (c) => CreateCourseScreen(existingCourse: course)),
                );
              },
            ),

            ListTile(
              leading: const Icon(Icons.upload_file_outlined, color: AppColors.primaryContainer),
              title: const Text('Manage & Import Students'),
              onTap: () {
                Navigator.pop(context);
                context.push('/courses/${course.id}/import');
              },
            ),

            ListTile(
              leading: Icon(
                course.status == CourseStatus.archived ? Icons.unarchive_outlined : Icons.archive_outlined,
                color: AppColors.secondary,
              ),
              title: Text(course.status == CourseStatus.archived ? 'Unarchive Course' : 'Archive Course'),
              onTap: () async {
                Navigator.pop(context);
                final db = ref.read(databaseProvider);
                final updated = course.copyWith(
                  status: course.status == CourseStatus.archived ? CourseStatus.active : CourseStatus.archived,
                  updatedAt: DateTime.now(),
                  synced: false,
                );
                await db.upsertCourse(updated);
              },
            ),

            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.absentRed),
              title: Text('Delete Course', style: AppTypography.bodyMd.copyWith(color: AppColors.absentRed)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this course?'),
        content: Text(
          'This will permanently remove ${course.courseCode} and all associated student and attendance records.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absentRed),
            onPressed: () async {
              Navigator.pop(ctx);
              final db = ref.read(databaseProvider);
              await db.deleteCourse(course.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Course deleted successfully'),
                    backgroundColor: AppColors.absentRed,
                  ),
                );
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
