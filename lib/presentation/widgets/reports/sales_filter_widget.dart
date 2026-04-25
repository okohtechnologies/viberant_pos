// lib/presentation/widgets/reports/sales_filter_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/sale_entity.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/reports/sales_report_provider.dart';

class SalesFilterWidget extends ConsumerStatefulWidget {
  const SalesFilterWidget({super.key});

  @override
  ConsumerState<SalesFilterWidget> createState() => _SalesFilterWidgetState();
}

class _SalesFilterWidgetState extends ConsumerState<SalesFilterWidget> {
  DateTime? _startDate;
  DateTime? _endDate;
  PaymentMethod? _selectedPaymentMethod;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
    _applyFilters();
  }

  void _applyFilters() {
    ref.read(salesReportFiltersProvider.notifier).state = ref
        .read(salesReportFiltersProvider)
        .copyWith(
          startDate: _startDate,
          endDate: _endDate,
          paymentMethod: _selectedPaymentMethod,
        );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? _startDate ?? DateTime.now()
          : _endDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
      _applyFilters();
    }
  }

  void _clearFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _selectedPaymentMethod = null;
      _searchController.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.filter_list_rounded, size: 20),
              const SizedBox(width: 8),
              Text(
                'Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.onSurface,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Date Range
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: ViberantColors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ViberantColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ViberantColors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _startDate != null
                                  ? dateFormat.format(_startDate!)
                                  : 'Select Date',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: ViberantColors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: ViberantColors.background,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: ViberantColors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              _endDate != null
                                  ? dateFormat.format(_endDate!)
                                  : 'Select Date',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Payment Method Filter
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Method',
                style: TextStyle(fontSize: 12, color: ViberantColors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: PaymentMethod.values.map((method) {
                  final isSelected = _selectedPaymentMethod == method;
                  return FilterChip(
                    label: Text(_formatPaymentMethod(method)),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedPaymentMethod = selected ? method : null;
                      });
                      _applyFilters();
                    },
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    selectedColor: ViberantColors.primary.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: isSelected
                          ? ViberantColors.primary
                          : ViberantColors.onSurface,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.normal,
                    ),
                    checkmarkColor: ViberantColors.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(PaymentMethod method) {
    switch (method) {
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
}
