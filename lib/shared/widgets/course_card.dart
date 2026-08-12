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

  const CourseCard({
    super.key,
    required this.course,
    required this.studentCount,
    required this.classesHeldCount,
    required this.averageAttendancePct,
    required this.onTap,
    this.onMoreTap,
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: AppColors.accentLight,
            highlightColor: AppColors.accentLight.withValues(alpha: 0.5),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: _attendanceColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                      ),
                    ),
                  ),

                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: code pill + attendance badge + menu
                          Row(
                            children: [
                              // Course code pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentLight,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  course.courseCode,
                                  style: AppTypography.labelMd.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              const SizedBox(width: 8),

                              // Level pill
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceVariant,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  course.level,
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),

                              const Spacer(),

                              // Attendance % badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _attendanceBg,
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: Text(
                                  '${averageAttendancePct.toStringAsFixed(0)}%',
                                  style: AppTypography.caption.copyWith(
                                    color: _attendanceColor,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),

                              if (onMoreTap != null) ...[
                                const SizedBox(width: 2),
                                SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.more_vert_rounded,
                                        size: 18, color: AppColors.textMuted),
                                    onPressed: onMoreTap,
                                  ),
                                ),
                              ],
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Course title
                          Text(
                            course.courseTitle,
                            style: AppTypography.headlineMd.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),

                          // Department
                          Text(
                            course.department,
                            style: AppTypography.bodyMd.copyWith(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 12),

                          // Meta row: students + classes
                          Row(
                            children: [
                              _MetaChip(
                                icon: Icons.people_alt_outlined,
                                label: '$studentCount Students',
                              ),
                              const SizedBox(width: 12),
                              _MetaChip(
                                icon: Icons.event_note_outlined,
                                label: '$classesHeldCount / ${course.expectedClasses}',
                              ),
                              const Spacer(),
                              // Semester label
                              Text(
                                course.semester,
                                style: AppTypography.caption,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Classes progress bar
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progressFraction,
                                  minHeight: 5,
                                  backgroundColor: AppColors.surfaceVariant,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      _attendanceColor),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${(progressFraction * 100).toStringAsFixed(0)}% classes completed',
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
