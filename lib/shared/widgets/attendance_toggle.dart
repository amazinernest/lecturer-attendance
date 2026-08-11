import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../models/attendance_record.dart';

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
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Present Button
          GestureDetector(
            onTap: () => onChanged(AttendanceStatus.present),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isPresent ? AppColors.presentGreen : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: isPresent
                    ? [
                        BoxShadow(
                          color: AppColors.presentGreen.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    size: 16,
                    color: isPresent ? AppColors.onPrimary : AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Present',
                    style: AppTypography.labelMd.copyWith(
                      color: isPresent ? AppColors.onPrimary : AppColors.secondary,
                      fontWeight: isPresent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Absent Button
          GestureDetector(
            onTap: () => onChanged(AttendanceStatus.absent),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: !isPresent ? AppColors.absentRed : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                boxShadow: !isPresent
                    ? [
                        BoxShadow(
                          color: AppColors.absentRed.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : [],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.cancel_rounded,
                    size: 16,
                    color: !isPresent ? AppColors.onPrimary : AppColors.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Absent',
                    style: AppTypography.labelMd.copyWith(
                      color: !isPresent ? AppColors.onPrimary : AppColors.secondary,
                      fontWeight: !isPresent ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
