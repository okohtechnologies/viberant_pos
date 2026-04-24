// lib/presentation/widgets/reports/sales_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../providers/reports/sales_report_provider.dart';

class SalesFilterWidget extends ConsumerWidget {
  const SalesFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(salesReportFiltersProvider);
    final notifier = ref.read(salesReportFiltersProvider.notifier);
    final scheme = Theme.of(context).colorScheme;
    final dateFmt = DateFormat('d MMM');

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range row
          Row(
            children: [
              Expanded(
                child: _DateButton(
                  label: 'From',
                  value: filters.startDate != null
                      ? dateFmt.format(filters.startDate!)
                      : 'Any',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filters.startDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      notifier.state = filters.copyWith(startDate: picked);
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: _DateButton(
                  label: 'To',
                  value: filters.endDate != null
                      ? dateFmt.format(filters.endDate!)
                      : 'Today',
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: filters.endDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      notifier.state = filters.copyWith(endDate: picked);
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              // Reset
              GestureDetector(
                onTap: () {
                  final now = DateTime.now();
                  notifier.state = SalesReportFilters(
                    startDate: DateTime(now.year, now.month, 1),
                    endDate: now,
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(ViberantRadius.md),
                  ),
                  child: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Quick range chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _QuickChip(
                  label: 'Today',
                  onTap: () {
                    final now = DateTime.now();
                    notifier.state = SalesReportFilters(
                      startDate: DateTime(now.year, now.month, now.day),
                      endDate: now,
                    );
                  },
                ),
                _QuickChip(
                  label: 'This Week',
                  onTap: () {
                    final now = DateTime.now();
                    notifier.state = SalesReportFilters(
                      startDate: now.subtract(const Duration(days: 7)),
                      endDate: now,
                    );
                  },
                ),
                _QuickChip(
                  label: 'This Month',
                  onTap: () {
                    final now = DateTime.now();
                    notifier.state = SalesReportFilters(
                      startDate: DateTime(now.year, now.month, 1),
                      endDate: now,
                    );
                  },
                ),
                _QuickChip(
                  label: 'Last 30 Days',
                  onTap: () {
                    final now = DateTime.now();
                    notifier.state = SalesReportFilters(
                      startDate: now.subtract(const Duration(days: 30)),
                      endDate: now,
                    );
                  },
                ),
                _QuickChip(
                  label: 'Last 90 Days',
                  onTap: () {
                    final now = DateTime.now();
                    notifier.state = SalesReportFilters(
                      startDate: now.subtract(const Duration(days: 90)),
                      endDate: now,
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Payment method filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _MethodChip(
                  label: 'All Methods',
                  isSelected: filters.paymentMethod == null,
                  onTap: () =>
                      notifier.state = filters.copyWith(paymentMethod: null),
                ),
                ...[
                  ('Cash', PaymentMethod.cash),
                  ('MoMo', PaymentMethod.momo),
                  ('Card', PaymentMethod.card),
                  ('Bank', PaymentMethod.bankTransfer),
                  ('Credit', PaymentMethod.credit),
                ].map(
                  (e) => _MethodChip(
                    label: e.$1,
                    isSelected: filters.paymentMethod == e.$2,
                    onTap: () =>
                        notifier.state = filters.copyWith(paymentMethod: e.$2),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ViberantRadius.full),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MethodChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(ViberantRadius.full),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
