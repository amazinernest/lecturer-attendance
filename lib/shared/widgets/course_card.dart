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

    final isGoodAttendance = averageAttendancePct >= 75;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill & Avg Attendance Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        course.courseCode,
                        style: AppTypography.labelMd.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isGoodAttendance ? AppColors.presentBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${averageAttendancePct.toStringAsFixed(0)}% avg',
                            style: AppTypography.labelMd.copyWith(
                              color: isGoodAttendance ? AppColors.presentGreen : AppColors.warningOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (onMoreTap != null) ...[
                          const SizedBox(width: 4),
                          IconButton(
                            icon: const Icon(Icons.more_vert, size: 20, color: AppColors.secondary),
                            onPressed: onMoreTap,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Course Title
                Text(
                  course.courseTitle,
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Student & Class metrics
                Row(
                  children: [
                    const Icon(Icons.people_outline, size: 15, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '$studentCount Students',
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_outlined, size: 15, color: AppColors.secondary),
                    const SizedBox(width: 4),
                    Text(
                      '$classesHeldCount / ${course.expectedClasses} Classes',
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Clean Linear Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
