import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../models/attendance_record.dart';

/// Large, tactile attendance toggle optimised for classroom use.
/// Features large touch targets and animated state transitions.
class AttendanceToggle extends StatelessWidget {
  final AttendanceStatus status;
  final ValueChanged<AttendanceStatus> onChanged;

  const AttendanceToggle({
    super.key,
    required this.status,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isPresent = status == AttendanceStatus.present;

    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Present
          _ToggleButton(
            label: 'Present',
            icon: Icons.check_circle_rounded,
            isActive: isPresent,
            activeColor: AppColors.success,
            activeBg: AppColors.success,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(AttendanceStatus.present);
            },
          ),

          // Absent
          _ToggleButton(
            label: 'Absent',
            icon: Icons.cancel_rounded,
            isActive: !isPresent,
            activeColor: AppColors.error,
            activeBg: AppColors.error,
            onTap: () {
              HapticFeedback.lightImpact();
              onChanged(AttendanceStatus.absent);
            },
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final Color activeColor;
  final Color activeBg;
  final VoidCallback onTap;

  const _ToggleButton({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(100),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: activeBg.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isActive ? Colors.white : AppColors.textMuted,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
