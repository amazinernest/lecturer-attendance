import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Premium quick action hub — 4-button grid for Dashboard.
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
    return Row(
      children: [
        _ActionButton(
          icon: Icons.how_to_reg_outlined,
          label: 'Take\nAttendance',
          iconColor: Colors.white,
          bg: AppColors.accent,
          onTap: onTakeAttendance,
          isPrimary: true,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_circle_outline,
                      label: 'Add Course',
                      iconColor: AppColors.accent,
                      bg: AppColors.accentLight,
                      onTap: onAddCourse,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.upload_file_outlined,
                      label: 'Import Roster',
                      iconColor: AppColors.navyMid,
                      bg: const Color(0xFFF0F4FF),
                      onTap: onImportRoster,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _ActionButton(
                icon: Icons.bar_chart_rounded,
                label: 'View Analytics',
                iconColor: AppColors.success,
                bg: AppColors.successBg,
                onTap: onViewAnalytics,
                fullWidth: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bg;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool fullWidth;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bg,
    required this.onTap,
    this.isPrimary = false,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = Material(
      color: bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: iconColor.withValues(alpha: 0.15),
        child: Padding(
          padding: EdgeInsets.symmetric(
            vertical: isPrimary ? 16 : 12,
            horizontal: isPrimary ? 14 : 12,
          ),
          child: fullWidth
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text(
                      'View Analytics',
                      style: AppTypography.titleSm.copyWith(
                        color: iconColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: isPrimary ? 26 : 20, color: iconColor),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: AppTypography.caption.copyWith(
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.9)
                            : iconColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
        ),
      ),
    );

    if (isPrimary) {
      return SizedBox(
        width: 90,
        height: 90,
        child: content,
      );
    }

    return content;
  }
}
