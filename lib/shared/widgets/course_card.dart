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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
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
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.school_rounded, size: 14, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 6),
                          Text(
                            '${course.courseCode} • ${course.level}',
                            style: AppTypography.labelMd.copyWith(
                              color: const Color(0xFF1E293B),
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isGoodAttendance ? AppColors.presentBg : AppColors.warningBg,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${averageAttendancePct.toStringAsFixed(0)}% avg',
                            style: AppTypography.labelMd.copyWith(
                              color: isGoodAttendance ? AppColors.presentGreen : AppColors.warningOrange,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
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

                const SizedBox(height: 12),

                // Course Title
                Text(
                  course.courseTitle,
                  style: AppTypography.titleMd.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 12),

                // Student & Class metrics
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.people_alt_outlined, size: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$studentCount Students',
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(Icons.event_available_rounded, size: 14, color: Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$classesHeldCount / ${course.expectedClasses} Classes',
                      style: AppTypography.labelMd.copyWith(color: AppColors.secondary, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Clean Progress Bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: progressFraction,
                    minHeight: 6,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4F46E5)),
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
