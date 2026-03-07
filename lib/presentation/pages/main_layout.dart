// lib/presentation/pages/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';

import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../pages/dasboard/dashboard_page.dart';
import '../pages/pos/pos_page.dart';
import 'inventory/inventory_page.dart';
import 'customers/customers_page.dart';
import 'settings/settings_page.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentIndex = ref.watch(navigationProvider);
    final navigationNotifier = ref.read(navigationProvider.notifier);

    // If not authenticated, show login page (shouldn't happen but safety check)
    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: ViberantColors.error),
              SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: GoogleFonts.inter(fontSize: 18),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  // Sign out the user
                  await ref.read(authProvider.notifier).signOut();

                  // Navigate to Login Page
                  // Using Navigator
                  if (context.mounted) {
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                },
                child: Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    final user = authState.user;

    return Scaffold(
      backgroundColor: ViberantColors.background,
      appBar: _buildAppBar(currentIndex, user.businessName),
      body: _buildBody(currentIndex),
      bottomNavigationBar: _buildBottomNavigationBar(
        currentIndex,
        navigationNotifier.setIndex,
      ),
    );
  }

  AppBar? _buildAppBar(int currentIndex, String businessName) {
    final titles = {
      0: 'Dashboard',
      1: 'POS',
      2: 'Inventory',
      3: 'Customers',
      4: 'Settings',
    };

    return AppBar(
      backgroundColor: ViberantColors.surface,
      elevation: 0,
      title: Text(
        titles[currentIndex] ?? 'Viberant POS',
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: ViberantColors.onSurface,
        ),
      ),
      actions: currentIndex == 0 ? _buildDashboardActions() : null,
    );
  }

  List<Widget> _buildDashboardActions() {
    return [
      IconButton(
        icon: Icon(Icons.notifications_none_rounded),
        onPressed: () {},
        tooltip: 'Notifications',
      ),
      IconButton(
        icon: Icon(Icons.refresh_rounded),
        onPressed: () {},
        tooltip: 'Refresh',
      ),
    ];
  }

  Widget _buildBody(int currentIndex) {
    switch (currentIndex) {
      case 0:
        return DashboardPage();
      case 1:
        return PosPage();
      case 2:
        return InventoryPage();
      case 3:
        return CustomersPage();
      case 4:
        return SettingsPage();
      default:
        return DashboardPage();
    }
  }

  Widget _buildBottomNavigationBar(int currentIndex, Function(int) onTap) {
    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.dashboard_rounded,
                label: 'Dashboard',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.point_of_sale_rounded,
                label: 'POS',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.inventory_2_rounded,
                label: 'Inventory',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.people_rounded,
                label: 'Customers',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ViberantColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isActive ? ViberantColors.primary : ViberantColors.grey,
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive ? ViberantColors.primary : ViberantColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
