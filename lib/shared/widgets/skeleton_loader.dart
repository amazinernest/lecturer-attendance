import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// A shimmer skeleton loader for use while content is loading.
/// Provide [child] as the placeholder layout to animate.
class SkeletonLoader extends StatefulWidget {
  final Widget child;

  const SkeletonLoader({super.key, required this.child});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(_animation.value - 1, 0),
              end: Alignment(_animation.value + 1, 0),
              colors: const [
                Color(0xFFE8EDF2),
                Color(0xFFF5F7FA),
                Color(0xFFE8EDF2),
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single skeleton placeholder box
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// Pre-built skeleton for a course card
class CourseCardSkeleton extends StatelessWidget {
  const CourseCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SkeletonBox(width: 100, height: 22, borderRadius: 100),
                const SkeletonBox(width: 64, height: 22, borderRadius: 100),
              ],
            ),
            const SizedBox(height: 12),
            const SkeletonBox(width: double.infinity, height: 18),
            const SizedBox(height: 8),
            const SkeletonBox(width: 160, height: 14),
            const SizedBox(height: 16),
            const SkeletonBox(width: double.infinity, height: 6, borderRadius: 3),
          ],
        ),
      ),
    );
  }
}

/// Pre-built skeleton for a stat card row
class StatCardRowSkeleton extends StatelessWidget {
  const StatCardRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Row(
        children: List.generate(
          2,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 0 ? 8 : 0),
              height: 90,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Pre-built skeleton for the dashboard header
class DashboardHeaderSkeleton extends StatelessWidget {
  const DashboardHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        color: AppColors.border,
        height: 160,
      ),
    );
  }
}
