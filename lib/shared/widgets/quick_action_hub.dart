import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Investor-grade quick action hub for Dashboard.
/// Features a prominent Hero Take Attendance trigger + 3 secondary action cards.
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
    return Column(
      children: [
        // Primary Hero Action Card
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTakeAttendance,
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withValues(alpha: 0.15),
            highlightColor: Colors.white.withValues(alpha: 0.08),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF2563EB),
                    Color(0xFF1D4ED8),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.28),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.2,
                      ),
                    ),
                    child: const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Take Attendance',
                              style: TextStyle(
                                fontFamily: AppTypography.fontFamily,
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: const Text(
                                'ACTIVE',
                                style: TextStyle(
                                  fontFamily: AppTypography.fontFamily,
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Record new session or scan student pass',
                          style: TextStyle(
                            fontFamily: AppTypography.fontFamily,
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 10),

        // 3 Supporting Action Cards Row
        Row(
          children: [
            Expanded(
              child: _SecondaryActionCard(
                icon: Icons.add_circle_outline_rounded,
                label: 'Add Course',
                iconColor: AppColors.accent,
                bgColor: AppColors.accentLight,
                borderColor: AppColors.accent.withValues(alpha: 0.15),
                onTap: onAddCourse,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionCard(
                icon: Icons.upload_file_rounded,
                label: 'Import Roster',
                iconColor: const Color(0xFF7C3AED),
                bgColor: const Color(0xFFF5F3FF),
                borderColor: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                onTap: onImportRoster,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryActionCard(
                icon: Icons.insights_rounded,
                label: 'Analytics',
                iconColor: AppColors.success,
                bgColor: AppColors.successBg,
                borderColor: AppColors.success.withValues(alpha: 0.15),
                onTap: onViewAnalytics,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SecondaryActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color bgColor;
  final Color borderColor;
  final VoidCallback onTap;

  const _SecondaryActionCard({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.bgColor,
    required this.borderColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: iconColor.withValues(alpha: 0.12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(icon, size: 20, color: iconColor),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
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
  }
}
