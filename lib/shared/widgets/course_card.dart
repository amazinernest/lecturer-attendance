import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/course.dart';

class CourseCard extends StatelessWidget {
  final Course course;
  final int studentCount;
  final int classesHeldCount;
  final double averageAttendancePct;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;
  final VoidCallback? onQuickRecord;

  const CourseCard({
    super.key,
    required this.course,
    required this.studentCount,
    required this.classesHeldCount,
    required this.averageAttendancePct,
    required this.onTap,
    this.onMoreTap,
    this.onQuickRecord,
  });

  Color get _attendanceColor {
    if (averageAttendancePct >= 75) return AppColors.success;
    if (averageAttendancePct >= 50) return AppColors.warning;
    return AppColors.error;
  }

  Color get _attendanceBg {
    if (averageAttendancePct >= 75) return AppColors.successBg;
    if (averageAttendancePct >= 50) return AppColors.warningBg;
    return AppColors.errorBg;
  }

  @override
  Widget build(BuildContext context) {
    final progressFraction = course.expectedClasses > 0
        ? (classesHeldCount / course.expectedClasses).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: AppColors.accentLight,
          highlightColor: AppColors.accentLight.withValues(alpha: 0.4),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Code Pill, Level, Semester & Attendance %
                Row(
                  children: [
                    // Course Code badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        course.courseCode,
                        style: const TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Level tag
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        course.level,
                        style: TextStyle(
                          fontFamily: AppTypography.fontFamily,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Attendance rate badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
                      decoration: BoxDecoration(
                        color: _attendanceBg,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: _attendanceColor.withValues(alpha: 0.25),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: _attendanceColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${averageAttendancePct.toStringAsFixed(0)}% Avg',
                            style: TextStyle(
                              fontFamily: AppTypography.fontFamily,
                              color: _attendanceColor,
                              fontWeight: FontWeight.w800,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (onMoreTap != null) ...[
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: onMoreTap,
                        behavior: HitTestBehavior.opaque,
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 12),

                // Course Title
                Text(
                  course.courseTitle,
                  style: const TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // Department & Semester Info
                Text(
                  '${course.department} • ${course.semester}',
                  style: TextStyle(
                    fontFamily: AppTypography.fontFamily,
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 14),

                // Meta Row: Students + Classes progress
                Row(
                  children: [
                    _InfoPill(
                      icon: Icons.people_outline_rounded,
                      label: '$studentCount Students',
                      color: AppColors.navyLight,
                    ),
                    const SizedBox(width: 12),
                    _InfoPill(
                      icon: Icons.calendar_today_outlined,
                      label: '$classesHeldCount of ${course.expectedClasses} Sessions',
                      color: AppColors.textSecondary,
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Progress Bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 6,
                        backgroundColor: AppColors.surfaceVariant,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          progressFraction >= 0.8
                              ? AppColors.success
                              : AppColors.accent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${(progressFraction * 100).toStringAsFixed(0)}% syllabus completed',
                          style: const TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textMuted,
                          ),
                        ),
                        if (onQuickRecord != null)
                          GestureDetector(
                            onTap: onQuickRecord,
                            child: Row(
                              children: [
                                Icon(Icons.qr_code_rounded,
                                    size: 13, color: AppColors.accent),
                                const SizedBox(width: 3),
                                Text(
                                  'Record',
                                  style: TextStyle(
                                    fontFamily: AppTypography.fontFamily,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: AppTypography.fontFamily,
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
