import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';
import '../../../core/services/storage_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingAvatar = false;

  Future<void> _pickAndUploadAvatar() async {
    setState(() => _isUploadingAvatar = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final bytes = file.bytes;

        if (bytes != null) {
          final avatarUrl =
              await StorageService().uploadAvatar(bytes, file.name);

          if (avatarUrl != null) {
            final currentUser = ref.read(currentUserProvider);
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(photoUrl: avatarUrl);
              await ref
                  .read(currentUserProvider.notifier)
                  .updateUserProfile(updatedUser);

              // Update photo_url in Supabase profiles table
              try {
                await Supabase.instance.client
                    .from('profiles')
                    .update({'photo_url': avatarUrl}).eq('id', currentUser.id);
              } catch (_) {}
            }

            messenger.showSnackBar(
              SnackBar(
                content: const Text('Profile picture updated successfully!'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Avatar upload failed: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final coursesAsync = ref.watch(coursesStreamProvider);
    final syncState = ref.watch(syncServiceProvider).state;
    final avatarLetter =
        (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'D';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Premium Profile Header ─────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0A1628), Color(0xFF1A3A6B)],
                ),
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                  child: Column(
                    children: [
                      // Title row
                      Row(
                        children: [
                          Text(
                            'Profile',
                            style: AppTypography.displayLg.copyWith(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.settings_outlined,
                                color: Colors.white, size: 18),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Avatar + Name
                      Row(
                        children: [
                          // Avatar with camera overlay
                          GestureDetector(
                            onTap: _isUploadingAvatar
                                ? null
                                : _pickAndUploadAvatar,
                            child: Stack(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.4),
                                        width: 2),
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: AppColors.accent,
                                    backgroundImage: user?.photoUrl != null
                                        ? NetworkImage(user!.photoUrl!)
                                        : null,
                                    child: user?.photoUrl == null
                                        ? Text(
                                            avatarLetter,
                                            style: AppTypography.displayLg
                                                .copyWith(
                                              color: Colors.white,
                                              fontSize: 26,
                                              fontWeight: FontWeight.w800,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                Positioned(
                                  bottom: 2,
                                  right: 2,
                                  child: Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: AppColors.accent,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: _isUploadingAvatar
                                        ? const SizedBox(
                                            width: 12,
                                            height: 12,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white))
                                        : const Icon(Icons.camera_alt,
                                            size: 13, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Name, email, role
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user?.name ?? 'Dr. Ernest',
                                  style: AppTypography.headlineLg.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  user?.email ??
                                      'ernest.lecturer@university.edu.ng',
                                  style: AppTypography.bodyMd.copyWith(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(100),
                                    border: Border.all(
                                        color: AppColors.success
                                            .withValues(alpha: 0.4)),
                                  ),
                                  child: Text(
                                    '✓ Verified Lecturer',
                                    style: AppTypography.caption.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Quick stats row
                      coursesAsync.when(
                        data: (courses) => Row(
                          children: [
                            Expanded(
                              child: _HeaderStat(
                                value: '${courses.length}',
                                label: 'Courses',
                              ),
                            ),
                            Container(
                              width: 1,
                              height: 32,
                              color: Colors.white.withValues(alpha: 0.2),
                            ),
                            Expanded(
                              child: _HeaderStat(
                                value: syncState.label,
                                label: 'Sync',
                              ),
                            ),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Settings List ──────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                _SectionLabel(label: 'Account'),
                const SizedBox(height: 8),

                _SettingsCard(items: [
                  _SettingsTile(
                    icon: Icons.person_outline_rounded,
                    color: AppColors.accent,
                    bg: AppColors.accentLight,
                    title: 'Display Name',
                    subtitle: user?.name ?? '—',
                  ),
                  _SettingsTile(
                    icon: Icons.email_outlined,
                    color: AppColors.navyMid,
                    bg: const Color(0xFFF0F4FF),
                    title: 'Email Address',
                    subtitle: user?.email ?? '—',
                  ),
                ]),

                const SizedBox(height: 20),

                _SectionLabel(label: 'System'),
                const SizedBox(height: 8),

                _SettingsCard(items: [
                  _SettingsTile(
                    icon: Icons.cloud_upload_outlined,
                    color: AppColors.success,
                    bg: AppColors.successBg,
                    title: 'Cloud Storage Bucket',
                    subtitle: 'lecturers-attendance-files',
                    trailing: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 18),
                  ),
                  _SettingsTile(
                    icon: Icons.sync_rounded,
                    color: AppColors.warning,
                    bg: AppColors.warningBg,
                    title: 'Database Sync',
                    subtitle: 'PostgreSQL & Drift Offline SQLite',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppColors.textMuted, size: 18),
                    onTap: () async {
                      if (user != null) {
                        await ref
                            .read(syncServiceProvider)
                            .syncNow(lecturerId: user.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Database sync completed!'),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    },
                  ),
                ]),

                const SizedBox(height: 20),

                _SectionLabel(label: 'Help & About'),
                const SizedBox(height: 8),

                _SettingsCard(items: [
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    color: AppColors.navyMid,
                    bg: const Color(0xFFF0F4FF),
                    title: 'Help & Support',
                    subtitle: 'amazinernest@gmail.com',
                    trailing: const Icon(Icons.mail_outline_rounded,
                        size: 18, color: AppColors.textMuted),
                    onTap: () async {
                      final Uri emailUri = Uri(
                        scheme: 'mailto',
                        path: 'amazinernest@gmail.com',
                        queryParameters: {
                          'subject': 'AttendTrack Support & Inquiry'
                        },
                      );
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Contact: amazinernest@gmail.com'),
                          ),
                        );
                      }
                    },
                  ),
                  _SettingsTile(
                    icon: Icons.info_outline_rounded,
                    color: AppColors.textMuted,
                    bg: AppColors.surfaceVariant,
                    title: 'App Version',
                    subtitle: 'AttendTrack v1.0.0',
                  ),
                ]),

                const SizedBox(height: 28),

                // Sign Out
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                    minimumSize: const Size(double.infinity, 52),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => _confirmSignOut(context, ref),
                  icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                  label: const Text('Sign Out'),
                ),

                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign Out?'),
        content: const Text(
            'Are you sure you want to sign out? Your local data will remain saved on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(currentUserProvider.notifier).signOut();
              if (context.mounted) {
                context.go('/welcome');
              }
            },
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;

  const _HeaderStat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.statMd.copyWith(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.caption.copyWith(
              color: Colors.white.withValues(alpha: 0.6), fontSize: 11),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.caption.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: AppColors.textMuted,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<_SettingsTile> items;
  const _SettingsCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: items
            .map((tile) => Column(
                  children: [
                    tile,
                    if (items.indexOf(tile) < items.length - 1)
                      const Divider(height: 1),
                  ],
                ))
            .toList(),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      title: Text(title, style: AppTypography.titleSm.copyWith(fontSize: 14)),
      subtitle: Text(subtitle, style: AppTypography.caption),
      trailing: trailing,
    );
  }
}
