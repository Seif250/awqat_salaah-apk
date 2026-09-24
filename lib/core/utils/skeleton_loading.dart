import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Lightweight pulsing placeholder box.
/// Uses simple opacity animation — extremely light on low-end devices.
class ShimmerBox extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerBox({
    super.key,
    this.width = double.infinity,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: isDark ? AppColors.darkCard : const Color(0xFFE8EDE9),
      ),
    );
  }
}

/// Wraps children with a gentle opacity pulse animation.
/// Uses a single AnimationController — minimal resource usage.
class ShimmerWrap extends StatefulWidget {
  final Widget child;
  const ShimmerWrap({super.key, required this.child});

  @override
  State<ShimmerWrap> createState() => _ShimmerWrapState();
}

class _ShimmerWrapState extends State<ShimmerWrap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _opacity, child: widget.child);
  }
}

/// Skeleton for the home page — mirrors the real layout structure
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header skeleton
            const ShimmerBox(height: 56),
            const SizedBox(height: 16),
            // Next prayer card skeleton
            const ShimmerBox(height: 180, borderRadius: 24),
            const SizedBox(height: 18),
            // Azkar ward card skeleton
            const ShimmerBox(height: 72, borderRadius: 18),
            const SizedBox(height: 20),
            // Prayer times label
            const ShimmerBox(height: 24, width: 100),
            const SizedBox(height: 12),
            // Prayer rows
            ...List.generate(
              6,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: ShimmerBox(height: 60, borderRadius: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for the azkar page
class AzkarSkeleton extends StatelessWidget {
  const AzkarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerWrap(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Category chips skeleton
            const ShimmerBox(height: 40),
            const SizedBox(height: 12),
            // Progress header skeleton
            const ShimmerBox(height: 60, borderRadius: 16),
            const SizedBox(height: 12),
            // Azkar cards
            ...List.generate(
              4,
              (_) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: ShimmerBox(height: 140, borderRadius: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
