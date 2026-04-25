import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/sale_entity.dart';
import '../../domain/states/auth_state.dart';
import '../../presentation/pages/admin/users_management_page.dart';
import '../../presentation/pages/auth/login_page.dart';
import '../../presentation/pages/orders/order_history.dart';
import '../../presentation/pages/orders/sales_details_page.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../presentation/pages/reports/sales_report_page.dart';
import '../../presentation/pages/sales/today_sales_page.dart';
import '../../presentation/providers/auth_provider.dart';

class AppNavigator {
  static void toSaleDetails(BuildContext context, SaleEntity sale) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SaleDetailsPage(sale: sale)),
    );
  }

  static void toOrderHistory(BuildContext context, String businessId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OrderHistoryPage(businessId: businessId),
      ),
    );
  }

  static void toTodaySales(BuildContext context, String businessId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TodaySalesPage(businessId: businessId)),
    );
  }

  static void toProducts(BuildContext context, String businessId) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductsPage(businessId: businessId)),
    );
  }

  static void toUsersManagement(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated || !auth.user.isAdmin) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin access required')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const UsersManagementPage()),
    );
  }

  static void toSalesReport(BuildContext context, WidgetRef ref) {
    final auth = ref.read(authProvider);
    if (auth is! AuthAuthenticated || !auth.user.isAdmin) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SalesReportScreen(businessId: auth.user.businessId),
      ),
    );
  }

  static void toLogin(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (_) => false,
    );
  }
}
