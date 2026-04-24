// lib/presentation/pages/customers/customers_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/empty_state.dart';
import '../../widgets/common/loading_shimmer.dart';
import '../../widgets/common/stat_card.dart';
import '../../widgets/common/viberant_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomersPage extends ConsumerWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    return _CustomersContent(businessId: authState.user.businessId);
  }
}

class _CustomersContent extends StatefulWidget {
  final String businessId;
  const _CustomersContent({required this.businessId});

  @override
  State<_CustomersContent> createState() => _CustomersContentState();
}

class _CustomersContentState extends State<_CustomersContent> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(widget.businessId)
          .collection('customers')
          .orderBy('totalSpent', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                LoadingShimmer.card(),
                const SizedBox(height: 12),
                LoadingShimmer.card(),
                const SizedBox(height: 16),
                const ShimmerList(count: 6),
              ],
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final customers = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          return _Customer(
            name: data['name'] ?? 'Unknown',
            totalSpent: ((data['totalSpent'] ?? 0) as num).toDouble(),
            visits: ((data['visits'] ?? 0) as num).toInt(),
            lastVisit: data['lastVisit'] != null
                ? (data['lastVisit'] as Timestamp).toDate()
                : null,
          );
        }).toList();

        final filtered = _query.isEmpty
            ? customers
            : customers
                  .where(
                    (c) => c.name.toLowerCase().contains(_query.toLowerCase()),
                  )
                  .toList();

        final totalSpent = customers.fold(0.0, (s, c) => s + c.totalSpent);
        final currency = NumberFormat.currency(
          symbol: 'GHS ',
          decimalDigits: 2,
        );

        return Column(
          children: [
            // Stats strip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'Total Customers',
                      value: '${customers.length}',
                      icon: Icons.people_rounded,
                      iconColor: ViberantColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      label: 'Lifetime Value',
                      value: currency.format(totalSpent),
                      icon: Icons.monetization_on_rounded,
                      iconColor: ViberantColors.secondary,
                    ),
                  ),
                ],
              ),
            ),

            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'Search customers…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),

            // List
            Expanded(
              child: filtered.isEmpty
                  ? const EmptyState(
                      icon: Icons.people_outline_rounded,
                      title: 'No customers yet',
                      description:
                          'Customers are added automatically when you record their name during a sale.',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) =>
                          _CustomerRow(customer: filtered[i], rank: i + 1),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Customer {
  final String name;
  final double totalSpent;
  final int visits;
  final DateTime? lastVisit;

  const _Customer({
    required this.name,
    required this.totalSpent,
    required this.visits,
    this.lastVisit,
  });
}

class _CustomerRow extends StatelessWidget {
  final _Customer customer;
  final int rank;

  const _CustomerRow({required this.customer, required this.rank});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = NumberFormat.currency(symbol: 'GHS ', decimalDigits: 2);
    final lastVisitStr = customer.lastVisit != null
        ? DateFormat('d MMM').format(customer.lastVisit!)
        : '—';

    return ViberantCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Rank badge
          SizedBox(
            width: 24,
            child: rank <= 3
                ? Icon(
                    Icons.star_rounded,
                    size: 18,
                    color: rank == 1
                        ? const Color(0xFFFFB800)
                        : rank == 2
                        ? const Color(0xFFB0B0B0)
                        : const Color(0xFFCD7F32),
                  )
                : Text(
                    '$rank',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
          ),
          const SizedBox(width: 10),

          AppAvatar(name: customer.name, size: 40),
          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                Text(
                  '${customer.visits} visit${customer.visits == 1 ? '' : 's'}  ·  Last: $lastVisitStr',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Text(
            currency.format(customer.totalSpent),
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
