import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class QuickActionHub extends StatelessWidget {
  final VoidCallback onTakeAttendance;
  final VoidCallback onAddCourse;
  final VoidCallback onImportRoster;
  final VoidCallback onViewAnalytics;

  const QuickActionHub({
    super.key,
    required this.onTakeAttendance,
    required this.onAddCourse,
    required this.onImportRoster,
    required this.onViewAnalytics,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        label: 'Mark Attendance',
        icon: Icons.fact_check_outlined,
        onTap: onTakeAttendance,
      ),
      _ActionData(
        label: 'Add Course',
        icon: Icons.add_circle_outline_rounded,
        onTap: onAddCourse,
      ),
      _ActionData(
        label: 'Import Class',
        icon: Icons.file_upload_outlined,
        onTap: onImportRoster,
      ),
      _ActionData(
        label: 'Reports',
        icon: Icons.bar_chart_outlined,
        onTap: onViewAnalytics,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: actions.map((item) {
          return Expanded(
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer.withValues(alpha: 0.07),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: AppColors.primaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.label,
                      style: AppTypography.labelMd.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ActionData {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  _ActionData({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}
