import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final String? buttonText;
  final VoidCallback? onButtonPressed;

  const EmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.buttonText,
    this.onButtonPressed,
  });

  factory EmptyStateWidget.noCourses({required VoidCallback onAddCourse}) {
    return EmptyStateWidget(
      title: "You haven't added any courses yet.",
      description: "Create your first course to begin tracking student attendance across academic semesters.",
      icon: Icons.school_outlined,
      buttonText: "Add Your First Course",
      onButtonPressed: onAddCourse,
    );
  }

  factory EmptyStateWidget.noStudents({required VoidCallback onUploadClassList}) {
    return EmptyStateWidget(
      title: "No students have been added to this course.",
      description: "Upload a CSV or XLSX class list to populate students and matriculation numbers.",
      icon: Icons.people_outline,
      buttonText: "Upload Class List",
      onButtonPressed: onUploadClassList,
    );
  }

  factory EmptyStateWidget.noAttendance({required VoidCallback onRecordFirstClass}) {
    return EmptyStateWidget(
      title: "No attendance has been recorded yet.",
      description: "Start taking attendance for your lectures. Your data will be calculated automatically.",
      icon: Icons.assignment_outlined,
      buttonText: "Record First Class",
      onButtonPressed: onRecordFirstClass,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 36,
                color: AppColors.primaryContainer,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: AppTypography.titleMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTypography.bodyMd.copyWith(
                color: AppColors.secondary,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onButtonPressed,
                icon: const Icon(Icons.add, size: 18),
                label: Text(buttonText!),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
