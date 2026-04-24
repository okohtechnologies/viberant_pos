// lib/presentation/widgets/common/status_chip.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

enum ChipStatus { success, warning, error, info, neutral, pending }

/// Color-coded status pill. Maps to Stitch's Chips & Tags spec:
/// 4px radius, micro-caps typography, tinted background.
class StatusChip extends StatelessWidget {
  final String label;
  final ChipStatus status;
  final IconData? icon;

  const StatusChip({
    super.key,
    required this.label,
    required this.status,
    this.icon,
  });

  /// Convenience constructors
  const StatusChip.success({super.key, required this.label, this.icon})
    : status = ChipStatus.success;
  const StatusChip.warning({super.key, required this.label, this.icon})
    : status = ChipStatus.warning;
  const StatusChip.error({super.key, required this.label, this.icon})
    : status = ChipStatus.error;
  const StatusChip.neutral({super.key, required this.label, this.icon})
    : status = ChipStatus.neutral;
  const StatusChip.pending({super.key, required this.label, this.icon})
    : status = ChipStatus.pending;

  @override
  Widget build(BuildContext context) {
    final colors = _colorsForStatus(status, context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: BorderRadius.circular(ViberantRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: colors.$2),
            const SizedBox(width: 4),
          ],
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: colors.$2,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colorsForStatus(ChipStatus s, BuildContext ctx) {
    switch (s) {
      case ChipStatus.success:
        return (
          ViberantColors.success.withValues(alpha: 0.12),
          ViberantColors.success,
        );
      case ChipStatus.warning:
        return (
          ViberantColors.warning.withValues(alpha: 0.12),
          ViberantColors.warning,
        );
      case ChipStatus.error:
        return (
          ViberantColors.error.withValues(alpha: 0.12),
          ViberantColors.error,
        );
      case ChipStatus.info:
        return (
          ViberantColors.info.withValues(alpha: 0.12),
          ViberantColors.info,
        );
      case ChipStatus.pending:
        return (
          ViberantColors.tertiary.withValues(alpha: 0.12),
          ViberantColors.tertiary,
        );
      case ChipStatus.neutral:
        final scheme = Theme.of(ctx).colorScheme;
        return (scheme.surfaceContainerHigh, scheme.onSurfaceVariant);
    }
  }
}
