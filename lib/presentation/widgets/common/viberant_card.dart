import 'package:flutter/material.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';

class ViberantCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double borderRadius;
  final bool showBorder;
  final VoidCallback? onTap;

  const ViberantCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
    this.borderRadius = 16,
    this.showBorder = true,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = color ?? theme.colorScheme.surface;

    Widget card = Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: showBorder
            ? Border.all(
                color: theme.colorScheme.outlineVariant.withOpacity(0.4),
                width: 0.5,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: ViberantColors.primary.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: padding,
      child: child,
    );

    if (onTap != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            splashColor: ViberantColors.primary.withOpacity(0.06),
            child: card,
          ),
        ),
      );
    }
    return card;
  }
}
