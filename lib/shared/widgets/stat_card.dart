import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Premium stat card used in Dashboard and Course Summary screens.
/// Supports wave decoration via CustomPainter.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color waveColor;
  final Color textColor;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.waveColor,
    required this.textColor,
    this.onTap,
    this.icon,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: waveColor.withValues(alpha: 0.15)),
        ),
        clipBehavior: Clip.antiAlias,
        child: CustomPaint(
          painter: _WavePainter(waveColor: waveColor.withValues(alpha: 0.12)),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (icon != null)
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: waveColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(icon, size: 14, color: textColor),
                      ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: AppTypography.statLg.copyWith(
                        fontSize: 26,
                        color: textColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: textColor.withValues(alpha: 0.6),
                          fontSize: 10,
                        ),
                      ),
                    ],
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

/// Featured large stat card — used for the primary dashboard metric
class FeaturedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  final Color backgroundColor;
  final Color valueColor;
  final VoidCallback? onTap;

  const FeaturedStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.trailing,
    required this.backgroundColor,
    required this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: valueColor.withValues(alpha: 0.15)),
          boxShadow: [
            BoxShadow(
              color: valueColor.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.caption.copyWith(
                      color: valueColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: AppTypography.statXL.copyWith(
                      color: valueColor,
                      fontSize: 44,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMd.copyWith(
                        color: valueColor.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color waveColor;
  const _WavePainter({required this.waveColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = waveColor
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, size.height * 0.6)
      ..quadraticBezierTo(
          size.width * 0.25, size.height * 0.45,
          size.width * 0.5, size.height * 0.55)
      ..quadraticBezierTo(
          size.width * 0.75, size.height * 0.65,
          size.width, size.height * 0.5)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter oldDelegate) =>
      oldDelegate.waveColor != waveColor;
}
