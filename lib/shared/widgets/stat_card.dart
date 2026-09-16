import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Premium stat card used in Dashboard and Analytics screens.
/// Features clean elevation, frosted accents, micro-gradients, and responsive typography.
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color waveColor; // Used as the primary accent color
  final Color textColor;
  final VoidCallback? onTap;
  final IconData? icon;
  final String? subtitle;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeBgColor;

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
    this.badgeText,
    this.badgeColor,
    this.badgeBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        splashColor: waveColor.withValues(alpha: 0.12),
        highlightColor: waveColor.withValues(alpha: 0.05),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: waveColor.withValues(alpha: 0.18),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: waveColor.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top row: Title and Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.toUpperCase(),
                      style: AppTypography.caption.copyWith(
                        color: textColor.withValues(alpha: 0.75),
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      padding: const EdgeInsets.all(5.5),
                      decoration: BoxDecoration(
                        color: waveColor.withValues(alpha: 0.14),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 14, color: waveColor),
                    ),
                ],
              ),
              const Spacer(),
              // Value + Subtitle / Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: AppTypography.statLg.copyWith(
                      fontSize: 24,
                      color: textColor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: AppTypography.caption.copyWith(
                          color: textColor.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              if (badgeText != null) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: badgeBgColor ?? waveColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badgeText!,
                    style: AppTypography.caption.copyWith(
                      color: badgeColor ?? waveColor,
                      fontSize: 9.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
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
          borderRadius: BorderRadius.circular(22),
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
                    label.toUpperCase(),
                    style: AppTypography.caption.copyWith(
                      color: valueColor.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    value,
                    style: AppTypography.statXL.copyWith(
                      color: valueColor,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTypography.bodyMd.copyWith(
                        color: valueColor.withValues(alpha: 0.75),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
