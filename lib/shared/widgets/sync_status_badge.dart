import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/sync/sync_service.dart';

class SyncStatusBadge extends StatelessWidget {
  final SyncState state;

  const SyncStatusBadge({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    IconData icon;

    switch (state) {
      case SyncState.synced:
        bg = AppColors.presentBg;
        fg = AppColors.presentGreen;
        icon = Icons.cloud_done_rounded;
        break;
      case SyncState.waitingToSync:
        bg = AppColors.warningBg;
        fg = AppColors.warningOrange;
        icon = Icons.cloud_queue_rounded;
        break;
      case SyncState.syncing:
        bg = AppColors.secondaryContainer;
        fg = AppColors.primaryContainer;
        icon = Icons.sync_rounded;
        break;
      case SyncState.error:
        bg = AppColors.absentBg;
        fg = AppColors.absentRed;
        icon = Icons.cloud_off_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            state.label,
            style: AppTypography.labelMd.copyWith(
              color: fg,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
