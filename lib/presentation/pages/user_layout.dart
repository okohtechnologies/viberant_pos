// lib/presentation/pages/user_layout.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import 'package:viberant_pos/domain/entities/user_entity.dart';
import 'package:viberant_pos/domain/entities/sale_entity.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/pages/auth/login_page.dart';
import 'package:viberant_pos/presentation/pages/orders/order_history.dart';
import 'package:viberant_pos/presentation/pages/products/products_page.dart';
import 'package:viberant_pos/presentation/pages/sales/today_sales_page.dart';

import '../providers/auth_provider.dart';
import 'pos/pos_page.dart';

class UserLayout extends ConsumerStatefulWidget {
  const UserLayout({super.key});

  @override
  ConsumerState<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends ConsumerState<UserLayout> {
  int _currentIndex = 0;

  final List<Widget> _userPages = [
    const UserHomePage(),
    const PosPage(),
    const SizedBox.shrink(), // Logout handled via bottom nav
  ];

  void navigateToPage(int index) {
    if (index == 2) {
      _showLogoutConfirmation(context, ref);
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: _currentIndex == 0 ? _buildAppBar(ref) : null,
      body: _userPages[_currentIndex],
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar? _buildAppBar(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    String titleText = 'Dashboard';

    if (authState is AuthAuthenticated) {
      final user = authState.user;
      titleText = user.businessName.isNotEmpty
          ? user.businessName
          : 'Dashboard';
    }

    return AppBar(
      backgroundColor: ViberantColors.primary,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: Text(
        titleText,
        style: GoogleFonts.inter(
          fontStyle: FontStyle.italic,
          fontSize: 30,
          fontWeight: FontWeight.w600,
          color: const Color.fromARGB(255, 224, 227, 234),
        ),
      ),
      actions: [const SizedBox(width: 5)],
    );
  }

  Future<void> _showLogoutConfirmation(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: const Color.fromARGB(255, 250, 30, 10),
            ),
            const SizedBox(width: 12),
            Text(
              "Confirm Logout",
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to logout?",
              style: GoogleFonts.inter(),
            ),
            const SizedBox(height: 8),
            Text(
              "You'll need to login again to access your account.",
              style: GoogleFonts.inter(
                fontSize: 12,
                color: ViberantColors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              "Cancel",
              style: GoogleFonts.inter(color: ViberantColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 255, 25, 0),
            ),
            child: Text(
              "Logout",
              style: GoogleFonts.inter(
                color: const Color.fromARGB(255, 255, 255, 255),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _performLogout(context, ref);
    }
  }

  Future<void> _performLogout(BuildContext context, WidgetRef ref) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await ref.read(authProvider.notifier).signOut();

      if (context.mounted) Navigator.pop(context);

      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Logged out successfully'),
            backgroundColor: ViberantColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: ViberantColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: navigateToPage,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: ViberantColors.primary,
        unselectedItemColor: ViberantColors.grey,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.point_of_sale_rounded),
            label: 'POS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.logout_rounded),
            label: 'Logout',
          ),
        ],
      ),
    );
  }
}

// -----------------------------
// User Home Page with Welcome Message and Quick Actions
// -----------------------------
class UserHomePage extends ConsumerWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = authState.user;
    final firstName = _getFirstName(user.displayName);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          _buildWelcomeSection(firstName, user, user.displayName),
          const SizedBox(height: 32),
          _buildQuickActionsGrid(context, user),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => _navigateToTodaysSales(context, user),
            child: _buildTodaysSummary(user),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(
    String firstName,
    UserEntity user,
    String displayName,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hi, Enjoy work Today 🤭',
          style: GoogleFonts.inter(
            fontSize: 20,
            color: const Color.fromARGB(255, 123, 52, 205),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: Text(
                displayName,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  color: const Color.fromARGB(255, 123, 52, 205),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: user.isAdmin
                    ? ViberantColors.primary.withOpacity(0.1)
                    : ViberantColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isAdmin ? 'Admin' : 'Employee',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: user.isAdmin
                      ? ViberantColors.primary
                      : ViberantColors.success,
                ),
              ),
            ),
          ],
        ),
        //const SizedBox(height: 8),
        //Text(
        //'Ready to serve customers today?',
        //style: GoogleFonts.inter(fontSize: 16, color: ViberantColors.grey),
        //),
        //const SizedBox(height: 4),
        //Text(
        //'Business: ${user.businessName}',
        //style: GoogleFonts.inter(
        //fontSize: 14,
        //color: ViberantColors.primary,
        //fontWeight: FontWeight.w500,
        //),
        //),
      ],
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context, UserEntity user) {
    final userLayoutState = context
        .findRootAncestorStateOfType<_UserLayoutState>();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildActionCard(
          context,
          'Start POS',
          'Process new sales',
          Icons.point_of_sale_rounded,
          ViberantColors.primary,
          0xFF6C63FF,
          () => userLayoutState?.navigateToPage(1),
        ),
        _buildActionCard(
          context,
          'Sales History',
          'View past transactions',
          Icons.history_rounded,
          ViberantColors.success,
          0xFF10B981,
          () => _navigateToSalesHistory(context, user), // Pass user parameter
        ),
        _buildActionCard(
          context,
          'Today\'s Sales',
          'View today\'s summary',
          Icons.analytics_rounded,
          ViberantColors.warning,
          0xFFF59E0B,
          () => _navigateToTodaysSales(context, user),
        ),
        _buildActionCard(
          context,
          'Products',
          'Browse inventory',
          Icons.inventory_2_rounded,
          ViberantColors.info ?? Colors.blue,
          0xFF3B82F6,
          () => _navigateToProducts(context, user),
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    int colorValue,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(colorValue).withOpacity(0.1),
                Color(colorValue).withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: ViberantColors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSummary(UserEntity user) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('businesses')
          .doc(user.businessId)
          .collection('sales')
          .where(
            'saleDate',
            isGreaterThanOrEqualTo: DateTime(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            ),
          )
          .orderBy('saleDate', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: ViberantColors.primary.withOpacity(0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Summary",
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: ViberantColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Center(child: CircularProgressIndicator()),
                ],
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final sales = docs.map((doc) => SaleEntity.fromFirestore(doc)).toList();

        final totalRevenue = sales.fold(
          0.0,
          (sum, sale) => sum + sale.finalAmount,
        );

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: ViberantColors.primary.withOpacity(0.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Summary",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: ViberantColors.onSurface,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: ViberantColors.grey,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Revenue",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ViberantColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "₵${NumberFormat('#,###.00').format(totalRevenue)}",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ViberantColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Sales",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: ViberantColors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "${sales.length}",
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: ViberantColors.success,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFirstName(String displayName) => displayName.split(' ').first;

  // Updated to accept UserEntity parameter
  void _navigateToSalesHistory(BuildContext context, UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderHistoryPage(businessId: user.businessId),
      ),
    );
  }

  void _navigateToTodaysSales(BuildContext context, UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TodaySalesPage(businessId: user.businessId),
      ),
    );
  }

  void _navigateToProducts(BuildContext context, UserEntity user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsPage(businessId: user.businessId),
      ),
    );
  }
}
