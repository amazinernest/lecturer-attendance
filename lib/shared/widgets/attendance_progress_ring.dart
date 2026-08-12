import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Circular progress ring for displaying attendance percentages.
/// Shows the percentage value in the centre with a smooth arc.
class AttendanceProgressRing extends StatelessWidget {
  final double percentage; // 0.0 – 100.0
  final double size;
  final double strokeWidth;
  final Color? ringColor;
  final Color? trackColor;
  final Color? textColor;
  final Widget? centerChild;

  const AttendanceProgressRing({
    super.key,
    required this.percentage,
    this.size = 120,
    this.strokeWidth = 10,
    this.ringColor,
    this.trackColor,
    this.textColor,
    this.centerChild,
  });

  Color get _resolvedRingColor {
    if (ringColor != null) return ringColor!;
    if (percentage >= 75) return AppColors.success;
    if (percentage >= 50) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(
          progress: (percentage / 100).clamp(0.0, 1.0),
          ringColor: _resolvedRingColor,
          trackColor: trackColor ?? AppColors.border,
          strokeWidth: strokeWidth,
        ),
        child: Center(
          child: centerChild ??
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(0)}%',
                    style: AppTypography.statMd.copyWith(
                      fontSize: size * 0.22,
                      color: textColor ?? _resolvedRingColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;
  final Color trackColor;
  final double strokeWidth;

  const _RingPainter({
    required this.progress,
    required this.ringColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.ringColor != ringColor;
}
