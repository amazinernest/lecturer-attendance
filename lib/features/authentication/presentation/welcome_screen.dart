import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/providers.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(currentUserProvider.notifier).signInWithGoogle();
      if (mounted) {
        context.go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign in failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.absentRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // Academic Logo Icon
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.how_to_reg_rounded,
                    size: 52,
                    color: AppColors.onPrimary,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Title & Tagline
              Text(
                'Lecturer Attendance',
                style: AppTypography.displayLg.copyWith(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryContainer,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Simple attendance management for university lecturers.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.secondary,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 3),

              // Continue with Google Button
              ElevatedButton(
                onPressed: _isLoading ? null : _handleGoogleSignIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryContainer,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.g_mobiledata_rounded, size: 28, color: AppColors.onPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Continue with Google',
                            style: AppTypography.titleMd.copyWith(
                              color: AppColors.onPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),

              Text(
                'Works offline • Automatic Cloud Sync',
                style: AppTypography.labelMd.copyWith(
                  fontSize: 12,
                  color: AppColors.outline,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
