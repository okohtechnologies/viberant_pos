// lib/presentation/widgets/common/loading_shimmer.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Skeleton loading shimmer — animated box placeholder.
/// Use inside AsyncValue.loading() cases.
class LoadingShimmer extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const LoadingShimmer({
    super.key,
    this.width = double.infinity,
    this.height = 16,
    this.borderRadius = ViberantRadius.sm,
  });

  /// Pre-built card skeleton (matches StatCard height)
  const LoadingShimmer.card({super.key})
    : width = double.infinity,
      height = 100,
      borderRadius = ViberantRadius.card;

  /// Pre-built list row skeleton
  const LoadingShimmer.row({super.key})
    : width = double.infinity,
      height = 56,
      borderRadius = ViberantRadius.md;

  @override
  State<LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.4,
      end: 0.8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh.withValues(
            alpha: _animation.value,
          ),
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

/// A column of shimmer rows — drop-in loading placeholder for list screens.
class ShimmerList extends StatelessWidget {
  final int count;
  const ShimmerList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => LoadingShimmer.row(),
    );
  }
}
