import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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

              // Academic App Logo Icon
              Center(
                child: Container(
                  width: 108,
                  height: 108,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryContainer.withValues(alpha: 0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      'assets/images/app_icon.png',
                      width: 108,
                      height: 108,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // App Title & Tagline
              Text(
                'Lecturer Attendance',
                style: AppTypography.displayLg.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryContainer,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),

              Text(
                'Fast, seamless attendance tracking for university lecturers.',
                style: AppTypography.bodyMd.copyWith(
                  color: AppColors.secondary,
                  fontSize: 15,
                ),
                textAlign: TextAlign.center,
              ),

              const Spacer(flex: 2),

              // Create Account Button
              ElevatedButton(
                onPressed: () => context.push('/register'),
                child: const Text('Create Account'),
              ),

              const SizedBox(height: 12),

              // Sign In Button
              OutlinedButton(
                onPressed: () => context.push('/login'),
                child: const Text('Sign In'),
              ),

              const SizedBox(height: 32),

              Text(
                'Works offline • Automatic Cloud Sync',
                style: AppTypography.labelMd.copyWith(
                  fontSize: 12,
                  color: AppColors.outline,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
