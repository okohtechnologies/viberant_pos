// lib/presentation/widgets/common/viberant_card.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// Base card container. All screens should use this instead of raw Card().
/// Matches Stitch spec: 16px radius, Level 1 shadow, no border at rest,
/// 2px primary border when [isSelected].
class ViberantCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool isSelected;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const ViberantCard({
    super.key,
    required this.child,
    this.padding,
    this.isSelected = false,
    this.onTap,
    this.color,
    this.borderRadius = ViberantRadius.card,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cardColor =
        color ??
        (Theme.of(context).brightness == Brightness.dark
            ? scheme.surfaceContainer
            : scheme.surfaceContainerLowest);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(borderRadius),
          border: isSelected
              ? Border.all(color: scheme.primary, width: 2)
              : null,
          boxShadow: ViberantShadows.level1,
        ),
        child: padding != null
            ? Padding(padding: padding!, child: child)
            : child,
      ),
    );
  }
}
