import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final int studentCount;
  final int classesHeldCount;
  final double averageAttendancePct;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const CourseCard({
    super.key,
    required this.course,
    required this.studentCount,
    required this.classesHeldCount,
    required this.averageAttendancePct,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final progressFraction = course.expectedClasses > 0
        ? (classesHeldCount / course.expectedClasses).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.courseCode,
                      style: AppTypography.labelMd.copyWith(
                        color: AppColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: averageAttendancePct >= 75
                              ? AppColors.presentBg
                              : AppColors.absentBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${averageAttendancePct.toStringAsFixed(0)}% Avg',
                          style: AppTypography.labelMd.copyWith(
                            color: averageAttendancePct >= 75
                                ? AppColors.presentGreen
                                : AppColors.absentRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      if (onMoreTap != null)
                        IconButton(
                          icon: const Icon(Icons.more_vert, size: 20, color: AppColors.secondary),
                          onPressed: onMoreTap,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                course.courseTitle,
                style: AppTypography.titleMd.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.people_outline, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '$studentCount Students',
                    style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13),
                  ),
                  const SizedBox(width: 16),
                  const Icon(Icons.class_outlined, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 4),
                  Text(
                    '$classesHeldCount / ${course.expectedClasses} Classes',
                    style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: AppColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
