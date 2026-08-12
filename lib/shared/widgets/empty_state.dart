import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Richly designed empty state widget for various scenarios.
class EmptyStateWidget extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  // ── Pre-built empty states ───────────────────

  factory EmptyStateWidget.noCourses({required VoidCallback onAddCourse}) {
    return EmptyStateWidget(
      icon: Icons.school_outlined,
      iconColor: AppColors.accent,
      iconBg: AppColors.accentLight,
      title: 'No courses yet',
      subtitle:
          'Add your first course to start managing attendance for your students.',
      actionLabel: 'Add Course',
      onAction: onAddCourse,
    );
  }

  factory EmptyStateWidget.noAttendance({required VoidCallback onRecordFirstClass}) {
    return EmptyStateWidget(
      icon: Icons.event_note_outlined,
      iconColor: AppColors.success,
      iconBg: AppColors.successBg,
      title: 'No attendance sessions yet',
      subtitle:
          'Record your first class attendance to start tracking student presence.',
      actionLabel: 'Record First Class',
      onAction: onRecordFirstClass,
    );
  }

  factory EmptyStateWidget.noStudents({required VoidCallback onUploadClassList}) {
    return EmptyStateWidget(
      icon: Icons.people_outline,
      iconColor: AppColors.navyMid,
      iconBg: AppColors.accentLight,
      title: 'No students enrolled',
      subtitle:
          'Import a class list or add students manually to get started.',
      actionLabel: 'Import Class List',
      onAction: onUploadClassList,
    );
  }

  factory EmptyStateWidget.noReports() {
    return const EmptyStateWidget(
      icon: Icons.bar_chart_outlined,
      iconColor: AppColors.warning,
      iconBg: AppColors.warningBg,
      title: 'No report data available',
      subtitle:
          'Add courses and record attendance sessions to generate reports.',
    );
  }

  factory EmptyStateWidget.searchEmpty({String query = ''}) {
    return EmptyStateWidget(
      icon: Icons.search_off_rounded,
      iconColor: AppColors.textMuted,
      iconBg: AppColors.surfaceVariant,
      title: 'Nothing found',
      subtitle: query.isNotEmpty
          ? 'No results for "$query". Try a different search.'
          : 'Try adjusting your search.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon container
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: iconColor),
            ),

            const SizedBox(height: 20),

            Text(
              title,
              style: AppTypography.headlineMd.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            Text(
              subtitle,
              style: AppTypography.bodyMd.copyWith(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.55,
              ),
              textAlign: TextAlign.center,
            ),

            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(actionLabel!),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(200, 46),
                    textStyle: AppTypography.titleSm.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
