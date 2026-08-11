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
        label: 'Mark Class',
        subtitle: 'Record attendance',
        icon: Icons.fact_check_rounded,
        bgColor: const Color(0xFFEEF2FF),
        iconColor: const Color(0xFF4F46E5),
        onTap: onTakeAttendance,
      ),
      _ActionData(
        label: 'Add Course',
        subtitle: 'New subject',
        icon: Icons.post_add_rounded,
        bgColor: const Color(0xFFECFDF5),
        iconColor: const Color(0xFF059669),
        onTap: onAddCourse,
      ),
      _ActionData(
        label: 'Import Roster',
        subtitle: 'CSV, Excel, PDF',
        icon: Icons.upload_file_rounded,
        bgColor: const Color(0xFFFFFBEB),
        iconColor: const Color(0xFFD97706),
        onTap: onImportRoster,
      ),
      _ActionData(
        label: 'Reports',
        subtitle: 'PDF & Analytics',
        icon: Icons.insights_rounded,
        bgColor: const Color(0xFFFFF1F2),
        iconColor: const Color(0xFFE11D48),
        onTap: onViewAnalytics,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2.1,
      children: actions.map((item) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: [
              BoxShadow(
                color: item.iconColor.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: item.onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.bgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.icon,
                        color: item.iconColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: AppTypography.titleMd.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.subtitle,
                            style: AppTypography.labelMd.copyWith(
                              fontSize: 11,
                              color: AppColors.secondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ActionData {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  _ActionData({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });
}
