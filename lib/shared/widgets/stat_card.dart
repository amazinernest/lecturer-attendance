import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor ?? AppColors.primaryContainer,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.labelMd.copyWith(
                      color: AppColors.secondary,
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: AppTypography.statLg.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Small helper enum for CrossAxisAlignment to avoid conflict if pdf package imported in same file
const pwCrossAxisAlignmentStart = CrossAxisAlignment.start;
