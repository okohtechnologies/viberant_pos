import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/sale_entity.dart';
import '../../../presentation/pages/orders/sales_details_page.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderHistoryPage extends ConsumerWidget {
  final String businessId; // <-- Add this

  const OrderHistoryPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final salesStream = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId) // <-- use the passed businessId
        .collection('sales')
        .where('cashierId', isEqualTo: user.id)
        .orderBy('saleDate', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: AppBar(
        title: const Text('Sales History'),
        backgroundColor: ViberantColors.surface,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: salesStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No sales recorded yet',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final sales = snapshot.data!.docs
              .map((doc) => SaleEntity.fromFirestore(doc))
              .toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: sales.length,
            itemBuilder: (context, index) {
              final sale = sales[index];
              final date = DateFormat('yMMMd – hh:mm a').format(sale.saleDate);

              return Card(
                color: ViberantColors.surface,
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    sale.customerName?.isNotEmpty == true
                        ? sale.customerName!
                        : "Walk-in Customer",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text("Date: $date\nItems: ${sale.totalItems}"),
                  trailing: Text(
                    "₵${NumberFormat('#,###.00').format(sale.finalAmount)}",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SaleDetailsPage(sale: sale),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
