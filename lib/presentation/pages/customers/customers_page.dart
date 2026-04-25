import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/widgets.dart';

// Streams from the customers/ subcollection written by SaleRepository
// on every named-customer sale. Avoids aggregating all sales on the client.
final _customersStreamProvider =
    StreamProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
      final auth = ref.watch(authProvider);
      if (auth is! AuthAuthenticated) return const Stream.empty();

      return FirebaseFirestore.instance
          .collection('businesses')
          .doc(auth.user.businessId)
          .collection('customers')
          .orderBy('totalSpent', descending: true)
          .snapshots()
          .map(
            (snap) => snap.docs.map((d) {
              final data = d.data();
              return <String, dynamic>{
                'name': data['name'] ?? d.id,
                'totalSpent': (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
                'visits': (data['visits'] as num?)?.toInt() ?? 0,
                'lastVisit': (data['lastVisit'] as Timestamp?)?.toDate(),
              };
            }).toList(),
          );
    });

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(_customersStreamProvider);

    return customersAsync.when(
      loading: () => const ShimmerList(count: 6, itemHeight: 72),
      error: (e, _) => EmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Could not load customers',
        description: e.toString(),
      ),
      data: (customers) {
        final filtered = _search.isEmpty
            ? customers
            : customers
                  .where(
                    (c) => (c['name'] as String).toLowerCase().contains(
                      _search.toLowerCase(),
                    ),
                  )
                  .toList();

        final totalSpent = customers.fold(
          0.0,
          (s, c) => s + (c['totalSpent'] as double),
        );
        final avgSpend = customers.isEmpty
            ? 0.0
            : totalSpent / customers.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customers',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Auto-tracked from sales transactions',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Stat chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StatChip(
                          '${customers.length} Customers',
                          ViberantColors.primary,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          '₵${NumberFormat('#,###.00').format(totalSpent)} Revenue',
                          ViberantColors.success,
                        ),
                        const SizedBox(width: 8),
                        _StatChip(
                          '₵${NumberFormat('#,###.00').format(avgSpend)} Avg',
                          ViberantColors.info,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Search
                  TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _search = v),
                    decoration: InputDecoration(
                      hintText: 'Search customers…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () {
                                _searchCtrl.clear();
                                setState(() => _search = '');
                              },
                            )
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // ── Customer list ──────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? EmptyState(
                      icon: Icons.person_search_rounded,
                      title: _search.isEmpty
                          ? 'No customers yet'
                          : 'No results for "$_search"',
                      description: _search.isEmpty
                          ? 'Customers are tracked automatically when you '
                                'enter their name during a sale'
                          : 'Try a different name',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final c = filtered[i];
                        // Rank badge for top 3
                        final isTop3 = i < 3;
                        const rankColors = [
                          Color(0xFFFFD700), // gold
                          Color(0xFFC0C0C0), // silver
                          Color(0xFFCD7F32), // bronze
                        ];
                        final lastVisit = c['lastVisit'] as DateTime?;
                        final lastVisitStr = lastVisit != null
                            ? DateFormat('d MMM y').format(lastVisit)
                            : '—';
                        final visits = c['visits'] as int;
                        final spent = c['totalSpent'] as double;
                        final avgPerVisit = visits > 0 ? spent / visits : 0.0;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isTop3
                                  ? rankColors[i].withOpacity(0.4)
                                  : Theme.of(context).colorScheme.outlineVariant
                                        .withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ViberantColors.primary.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              // Avatar + optional rank badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  AppAvatar(
                                    name: c['name'] as String,
                                    radius: 22,
                                  ),
                                  if (isTop3)
                                    Positioned(
                                      top: -4,
                                      right: -4,
                                      child: Container(
                                        width: 18,
                                        height: 18,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: rankColors[i],
                                          border: Border.all(
                                            color: Colors.white,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '${i + 1}',
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w900,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 12),

                              // Name + meta
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c['name'] as String,
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Row(
                                      children: [
                                        Text(
                                          '$visits visit${visits == 1 ? '' : 's'}',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: ViberantColors.outline,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Last: $lastVisitStr',
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: ViberantColors.outline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              // Spend column
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₵${NumberFormat('#,###.00').format(spent)}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: ViberantColors.success,
                                    ),
                                  ),
                                  Text(
                                    'avg ₵${NumberFormat('#,###.00').format(avgPerVisit)}',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      color: ViberantColors.outline,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: (i * 40).ms).slideY(begin: 0.05);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Stat chip ────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    ),
  );
}
