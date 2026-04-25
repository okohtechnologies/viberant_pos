import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/sale_entity.dart';

// ─── StatusChip ───────────────────────────────────────────────────────────────
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({required this.label, required this.color, super.key});

  factory StatusChip.fromSaleStatus(SaleStatus status) {
    const map = {
      SaleStatus.completed: ('COMPLETED', ViberantColors.success),
      SaleStatus.pending: ('PENDING', ViberantColors.warning),
      SaleStatus.refunded: ('REFUNDED', ViberantColors.info),
      SaleStatus.cancelled: ('CANCELLED', ViberantColors.error),
    };
    final (lbl, col) = map[status]!;
    return StatusChip(label: lbl, color: col);
  }

  factory StatusChip.fromStockStatus(String status) {
    const map = {
      'In Stock': ViberantColors.success,
      'Low Stock': ViberantColors.warning,
      'Out of Stock': ViberantColors.error,
    };
    return StatusChip(
      label: status.toUpperCase(),
      color: map[status] ?? ViberantColors.outline,
    );
  }

  factory StatusChip.role(bool isAdmin) => StatusChip(
    label: isAdmin ? 'ADMIN' : 'EMPLOYEE',
    color: isAdmin ? ViberantColors.primary : ViberantColors.success,
  );

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
        letterSpacing: 0.4,
      ),
    ),
  );
}

// ─── AppAvatar ────────────────────────────────────────────────────────────────
class AppAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? backgroundColor;

  const AppAvatar({
    required this.name,
    this.radius = 20,
    this.backgroundColor,
    super.key,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty || parts[0].isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final bg =
        backgroundColor ??
        Theme.of(context).colorScheme.primary.withOpacity(0.1);
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        _initials,
        style: GoogleFonts.poppins(
          fontSize: radius * 0.65,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}

// ─── EmptyState ───────────────────────────────────────────────────────────────
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 56, color: muted.withOpacity(0.3)),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: GoogleFonts.inter(fontSize: 14, color: muted),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              PrimaryButton(
                label: actionLabel!,
                onPressed: onAction!,
                fullWidth: false,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── PrimaryButton ────────────────────────────────────────────────────────────
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool fullWidth;
  final Color? backgroundColor;
  final bool outlined;

  const PrimaryButton({
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.leadingIcon,
    this.trailingIcon,
    this.fullWidth = true,
    this.backgroundColor,
    this.outlined = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? Theme.of(context).colorScheme.primary;

    Widget content = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation(Colors.white),
            ),
          )
        : Row(
            mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leadingIcon != null) ...[
                Icon(
                  leadingIcon,
                  size: 18,
                  color: outlined ? bg : Colors.white,
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: outlined ? bg : Colors.white,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(
                  trailingIcon,
                  size: 18,
                  color: outlined ? bg : Colors.white,
                ),
              ],
            ],
          );

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    );
    final size = SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
    );

    if (outlined) {
      return size.copyWith(
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: bg,
            side: BorderSide(color: bg, width: 1.5),
            shape: shape,
          ),
          child: content,
        ),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          disabledBackgroundColor: bg.withOpacity(0.5),
          elevation: 0,
          shape: shape,
        ),
        child: content,
      ),
    );
  }
}

extension on SizedBox {
  SizedBox copyWith({Widget? child, double? width, double? height}) => SizedBox(
    width: width ?? this.width,
    height: height ?? this.height,
    child: child ?? this.child,
  );
}

// ─── SectionHeader ────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      if (actionLabel != null)
        GestureDetector(
          onTap: onAction,
          child: Text(
            actionLabel!,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
    ],
  );
}

// ─── SectionLabel (uppercase category label) ──────────────────────────────────
class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 8, top: 20),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.outline,
        letterSpacing: 0.8,
      ),
    ),
  );
}

// ─── ShimmerCard ─────────────────────────────────────────────────────────────
class ShimmerCard extends StatefulWidget {
  final double height;
  final double? width;
  const ShimmerCard({this.height = 80, this.width, super.key});
  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _anim = Tween<double>(
      begin: -1,
      end: 2,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHigh;
    final hi = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [base, hi, base],
            stops: [
              (_anim.value - 0.3).clamp(0.0, 1.0),
              _anim.value.clamp(0.0, 1.0),
              (_anim.value + 0.3).clamp(0.0, 1.0),
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerList extends StatelessWidget {
  final int count;
  final double itemHeight;
  const ShimmerList({this.count = 5, this.itemHeight = 72, super.key});

  @override
  Widget build(BuildContext context) => ListView.separated(
    padding: const EdgeInsets.all(16),
    itemCount: count,
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemBuilder: (_, __) => ShimmerCard(height: itemHeight),
  );
}

class ShimmerGrid extends StatelessWidget {
  final int count;
  final int crossAxisCount;
  const ShimmerGrid({this.count = 6, this.crossAxisCount = 2, super.key});

  @override
  Widget build(BuildContext context) => GridView.builder(
    padding: const EdgeInsets.all(16),
    physics: const NeverScrollableScrollPhysics(),
    shrinkWrap: true,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 0.75,
    ),
    itemCount: count,
    itemBuilder: (_, __) => const ShimmerCard(height: double.infinity),
  );
}
