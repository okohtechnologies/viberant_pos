import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/sale_entity.dart';
import 'package:viberant_pos/presentation/pages/orders/sales_details_page.dart'; // Make sure you import this

class TodaySalesPage extends StatelessWidget {
  final String businessId;

  const TodaySalesPage({super.key, required this.businessId});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    final salesStream = FirebaseFirestore.instance
        .collection('businesses')
        .doc(businessId)
        .collection('sales')
        .where('saleDate', isGreaterThanOrEqualTo: startOfDay)
        .orderBy('saleDate', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: AppBar(
        title: const Text("Today's Sales"),
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
              child: Text('No sales today', style: TextStyle(fontSize: 16)),
            );
          }

          final sales = snapshot.data!.docs
              .map((doc) => SaleEntity.fromFirestore(doc))
              .toList();

          final totalRevenue = sales.fold(
            0.0,
            (sum, sale) => sum + sale.finalAmount,
          );

          return Column(
            children: [
              // Summary Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text(
                                'Total Sales',
                                style: TextStyle(color: ViberantColors.grey),
                              ),
                              Text(
                                '${sales.length}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ViberantColors.primary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                'Total Revenue',
                                style: TextStyle(color: ViberantColors.grey),
                              ),
                              Text(
                                '₵${NumberFormat('#,###.00').format(totalRevenue)}',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: ViberantColors.success,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Sales List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: sales.length,
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    final date = DateFormat('hh:mm a').format(sale.saleDate);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          sale.customerName?.isNotEmpty == true
                              ? sale.customerName!
                              : "Walk-in Customer",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ViberantColors.primary,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Time: $date"),
                            Text("Items: ${sale.totalItems}"),
                            Text("Cashier: ${sale.cashierName}"),
                          ],
                        ),
                        trailing: Text(
                          "₵${NumberFormat('#,###.00').format(sale.finalAmount)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: ViberantColors.success,
                          ),
                        ),
                        onTap: () {
                          // Navigate to SaleDetailsPage when clicked
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
