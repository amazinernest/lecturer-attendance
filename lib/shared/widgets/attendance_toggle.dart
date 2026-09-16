import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';
import '../models/attendance_record.dart';

/// Ultra-clean, tactile attendance toggle button optimized for rapid classroom marking.
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onChanged(isPresent ? AttendanceStatus.absent : AttendanceStatus.present);
        },
        borderRadius: BorderRadius.circular(100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          constraints: const BoxConstraints(minWidth: 94),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7.5),
          decoration: BoxDecoration(
            color: isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444),
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: (isPresent ? const Color(0xFF10B981) : const Color(0xFFEF4444))
                    .withValues(alpha: 0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isPresent ? Icons.check_circle_rounded : Icons.cancel_rounded,
                size: 15,
                color: Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                isPresent ? 'Present' : 'Absent',
                style: const TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
