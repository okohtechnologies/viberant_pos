import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';

import '../../../core/services/receipt_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';

import '../../widgets/common/viberant_card.dart';
import '../../widgets/common/widgets.dart';
import '../orders/sales_details_page.dart';

// ── Local provider scoped to this screen ────────────────────────────────────
final _reportFiltersProvider = StateProvider.autoDispose<_Filters>((ref) {
  final now = DateTime.now();
  return _Filters(startDate: DateTime(now.year, now.month, 1), endDate: now);
});

final _reportSalesProvider = StreamProvider.autoDispose<List<SaleEntity>>((
  ref,
) {
  final auth = ref.watch(authProvider);
  final filters = ref.watch(_reportFiltersProvider);
  if (auth is! AuthAuthenticated) return const Stream.empty();

  return ref
      .read(saleRepositoryProvider)
      .getSalesWithFilters(
        businessId: auth.user.businessId,
        startDate: filters.startDate,
        endDate: filters.endDate,
        paymentMethod: filters.paymentMethod,
      );
});

class _Filters {
  final DateTime? startDate;
  final DateTime? endDate;
  final PaymentMethod? paymentMethod;
  const _Filters({this.startDate, this.endDate, this.paymentMethod});

  _Filters copyWith({
    DateTime? startDate,
    DateTime? endDate,
    PaymentMethod? paymentMethod,
    bool clearPayment = false,
  }) => _Filters(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    paymentMethod: clearPayment ? null : (paymentMethod ?? this.paymentMethod),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
class SalesReportScreen extends ConsumerStatefulWidget {
  final String businessId;
  const SalesReportScreen({super.key, required this.businessId});

  @override
  ConsumerState<SalesReportScreen> createState() => _SalesReportScreenState();
}

class _SalesReportScreenState extends ConsumerState<SalesReportScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<SaleEntity> _applySearch(List<SaleEntity> sales) {
    if (_searchQuery.isEmpty) return sales;
    final q = _searchQuery.toLowerCase();
    return sales
        .where(
          (s) =>
              s.transactionId.toLowerCase().contains(q) ||
              s.cashierName.toLowerCase().contains(q) ||
              (s.customerName?.toLowerCase().contains(q) ?? false) ||
              _paymentLabel(s.paymentMethod).toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final salesAsync = ref.watch(_reportSalesProvider);
    final filters = ref.watch(_reportFiltersProvider);
    final dateFmt = DateFormat('d MMM yyyy');

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // ── Pinned App Bar ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Text(
              'Sales Reports',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(_reportSalesProvider),
                tooltip: 'Refresh',
              ),
            ],
          ),

          // ── Filter section ────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: ViberantCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.filter_list_rounded,
                          size: 16,
                          color: ViberantColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Filters',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            final now = DateTime.now();
                            ref
                                .read(_reportFiltersProvider.notifier)
                                .state = _Filters(
                              startDate: DateTime(now.year, now.month, 1),
                              endDate: now,
                            );
                            setState(() => _searchQuery = '');
                            _searchCtrl.clear();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Clear',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ViberantColors.outline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Date range row
                    Row(
                      children: [
                        Expanded(
                          child: _DateChip(
                            label: 'From',
                            date: filters.startDate,
                            onTap: () => _pickDate(context, true, filters),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _DateChip(
                            label: 'To',
                            date: filters.endDate,
                            onTap: () => _pickDate(context, false, filters),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Payment method filter
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _MethodChip(
                            label: 'All Methods',
                            isActive: filters.paymentMethod == null,
                            onTap: () =>
                                ref
                                    .read(_reportFiltersProvider.notifier)
                                    .state = filters.copyWith(
                                  clearPayment: true,
                                ),
                          ),
                          const SizedBox(width: 8),
                          ...PaymentMethod.values.map(
                            (m) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: _MethodChip(
                                label: _paymentLabel(m),
                                isActive: filters.paymentMethod == m,
                                onTap: () =>
                                    ref
                                        .read(_reportFiltersProvider.notifier)
                                        .state = filters.copyWith(
                                      paymentMethod: m,
                                    ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Search
                    TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText:
                            'Search by transaction ID, cashier, customer…',
                        prefixIcon: Icon(Icons.search_rounded),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 0,
                        ),
                        constraints: BoxConstraints(maxHeight: 42),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Summary strip ─────────────────────────────────────────────────
          if (salesAsync.asData?.value != null)
            SliverToBoxAdapter(
              child: Builder(
                builder: (_) {
                  final visible = _applySearch(salesAsync.asData!.value);
                  final revenue = visible.fold(
                    0.0,
                    (s, e) => s + e.finalAmount,
                  );
                  final avg = visible.isEmpty ? 0.0 : revenue / visible.length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _SummaryTile(
                            'Revenue',
                            '₵${NumberFormat('#,###.00').format(revenue)}',
                            ViberantColors.success,
                          ),
                          const SizedBox(width: 10),
                          _SummaryTile(
                            'Transactions',
                            '${visible.length}',
                            ViberantColors.primary,
                          ),
                          const SizedBox(width: 10),
                          _SummaryTile(
                            'Avg Sale',
                            '₵${NumberFormat('#,###.00').format(avg)}',
                            ViberantColors.info,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          // ── Transaction list ──────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            sliver: salesAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: ShimmerList(count: 6, itemHeight: 90),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: EmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'Could not load sales',
                  description: e.toString(),
                ),
              ),
              data: (sales) {
                final visible = _applySearch(sales);
                if (visible.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No sales found',
                      description: 'Try adjusting your filters or date range',
                    ),
                  );
                }
                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (_, i) => _TransactionCard(
                      sale: visible[i],
                    ).animate().fadeIn(delay: (i * 30).ms).slideY(begin: 0.04),
                    childCount: visible.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(
    BuildContext context,
    bool isStart,
    _Filters filters,
  ) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart
          ? (filters.startDate ?? DateTime.now())
          : (filters.endDate ?? DateTime.now()),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked == null || !mounted) return;
    ref.read(_reportFiltersProvider.notifier).state = isStart
        ? filters.copyWith(startDate: picked)
        : filters.copyWith(endDate: picked);
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'MoMo';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }
}

// ─── Transaction card ─────────────────────────────────────────────────────────
class _TransactionCard extends StatelessWidget {
  final SaleEntity sale;
  const _TransactionCard({required this.sale});

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('d MMM, h:mm a');
    final txnShort = sale.transactionId.length > 14
        ? '${sale.transactionId.substring(0, 14)}…'
        : sale.transactionId;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => SaleDetailsPage(sale: sale)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: ViberantColors.primary.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            // Row 1: TXN ID + status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  txnShort,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
                Row(
                  children: [
                    StatusChip.fromSaleStatus(sale.status),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          ReceiptService.generateAndShareReceipt(sale, context),
                      child: const Icon(
                        Icons.share_rounded,
                        size: 16,
                        color: ViberantColors.outline,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 2: Customer + date
            Row(
              children: [
                Expanded(
                  child: Text(
                    (sale.customerName?.isNotEmpty == true)
                        ? sale.customerName!
                        : 'Walk-in Customer',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Text(
                  dateFmt.format(sale.saleDate),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Row 3: Cashier + payment + amount
            Row(
              children: [
                Icon(
                  _paymentIcon(sale.paymentMethod),
                  size: 13,
                  color: _paymentColor(sale.paymentMethod),
                ),
                const SizedBox(width: 4),
                Text(
                  _paymentLabel(sale.paymentMethod),
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: _paymentColor(sale.paymentMethod),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${sale.items.length} items',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: ViberantColors.outline,
                  ),
                ),
                const Spacer(),
                Text(
                  '₵${NumberFormat('#,###.00').format(sale.finalAmount)}',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: ViberantColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _paymentLabel(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.momo:
        return 'Mobile Money';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.bankTransfer:
        return 'Bank Transfer';
      case PaymentMethod.credit:
        return 'Credit';
    }
  }

  IconData _paymentIcon(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return Icons.money_rounded;
      case PaymentMethod.momo:
        return Icons.phone_android_rounded;
      case PaymentMethod.card:
        return Icons.credit_card_rounded;
      case PaymentMethod.bankTransfer:
        return Icons.account_balance_rounded;
      case PaymentMethod.credit:
        return Icons.receipt_long_rounded;
    }
  }

  Color _paymentColor(PaymentMethod m) {
    switch (m) {
      case PaymentMethod.cash:
        return ViberantColors.success;
      case PaymentMethod.momo:
        return ViberantColors.primary;
      case PaymentMethod.card:
        return ViberantColors.warning;
      case PaymentMethod.bankTransfer:
        return ViberantColors.info;
      case PaymentMethod.credit:
        return ViberantColors.error;
    }
  }
}

// ─── Helper widgets ───────────────────────────────────────────────────────────
class _DateChip extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;
  const _DateChip({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: ViberantColors.primary,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    color: ViberantColors.outline,
                  ),
                ),
                Text(
                  date != null
                      ? DateFormat('d MMM yyyy').format(date!)
                      : 'Select',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _MethodChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  const _MethodChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isActive
            ? ViberantColors.primary
            : Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isActive ? Colors.white : ViberantColors.outline,
        ),
      ),
    ),
  );
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryTile(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: color.withOpacity(0.08),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, color: color.withOpacity(0.8)),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    ),
  );
}
