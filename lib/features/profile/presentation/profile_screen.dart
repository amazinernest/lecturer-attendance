import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
          final avatarUrl = await StorageService().uploadAvatar(bytes, file.name);

          if (avatarUrl != null) {
            final currentUser = ref.read(currentUserProvider);
            if (currentUser != null) {
              final updatedUser = currentUser.copyWith(photoUrl: avatarUrl);
              await ref.read(currentUserProvider.notifier).updateUserProfile(updatedUser);

              // Update photo_url in Supabase profiles table
              try {
                await Supabase.instance.client
                    .from('profiles')
                    .update({'photo_url': avatarUrl})
                    .eq('id', currentUser.id);
              } catch (_) {}
            }

            messenger.showSnackBar(
              const SnackBar(
                content: Text('Profile picture updated successfully!'),
                backgroundColor: AppColors.presentGreen,
              ),
            );
          }
        }
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Avatar upload failed: $e'),
          backgroundColor: AppColors.absentRed,
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

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Profile & Settings', style: AppTypography.headlineLg.copyWith(fontSize: 20)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Lecturer Profile Card with Interactive Avatar Upload
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                        child: user?.photoUrl == null
                            ? Text(
                                (user?.name.isNotEmpty == true) ? user!.name[0].toUpperCase() : 'D',
                                style: AppTypography.displayLg.copyWith(color: AppColors.onPrimary, fontSize: 24),
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: _isUploadingAvatar
                                ? const SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.name ?? 'Dr. Ernest',
                          style: AppTypography.headlineLg.copyWith(fontSize: 18),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'ernest.lecturer@university.edu.ng',
                          style: AppTypography.labelMd.copyWith(color: AppColors.secondary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.presentBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Lecturer Profile',
                            style: AppTypography.labelMd.copyWith(
                              color: AppColors.presentGreen,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Overview Stats Row
          coursesAsync.when(
            data: (courses) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _ProfileStatItem(title: 'Active Courses', value: '${courses.length}'),
                      const SizedBox(height: 30, child: VerticalDivider()),
                      _ProfileStatItem(title: 'Sync Status', value: syncState.label),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: 24),

          Text(
            'Settings',
            style: AppTypography.titleMd.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primaryContainer),
                  title: const Text('Cloud Storage Bucket'),
                  subtitle: const Text('lecturers-attendance-files'),
                  trailing: const Icon(Icons.check_circle, color: AppColors.presentGreen, size: 20),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.storage_outlined, color: AppColors.primaryContainer),
                  title: const Text('Database Sync'),
                  subtitle: const Text('PostgreSQL & Drift Offline SQLite'),
                  trailing: const Icon(Icons.sync, color: AppColors.primaryContainer, size: 20),
                  onTap: () async {
                    if (user != null) {
                      await ref.read(syncServiceProvider).syncNow(lecturerId: user.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Database sync completed!'),
                            backgroundColor: AppColors.presentGreen,
                          ),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined, color: AppColors.primaryContainer),
                  title: const Text('Privacy & Security'),
                  subtitle: const Text('Supabase RLS Data Isolation Active'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Sign Out Button with Confirmation Dialog
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.absentRed,
              side: const BorderSide(color: AppColors.absentRed, width: 1.5),
            ),
            onPressed: () => _confirmSignOut(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.absentRed),
            label: const Text('Sign Out'),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out?'),
        content: const Text('Are you sure you want to sign out of Lecturer Attendance? Your local data will remain saved on this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.absentRed),
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

class _ProfileStatItem extends StatelessWidget {
  final String title;
  final String value;

  const _ProfileStatItem({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: AppTypography.statLg.copyWith(fontSize: 18, color: AppColors.primaryContainer)),
        const SizedBox(height: 2),
        Text(title, style: AppTypography.labelMd.copyWith(fontSize: 12)),
      ],
    );
  }
}
