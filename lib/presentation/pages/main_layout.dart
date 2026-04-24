// lib/presentation/pages/main_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../pages/dasboard/dashboard_page.dart';
import '../pages/pos/pos_page.dart';
import 'inventory/inventory_page.dart';
import 'customers/customers_page.dart';
import 'settings/settings_page.dart';
import '../../domain/states/auth_state.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  static const _tabs = [
    _TabItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _TabItem(icon: Icons.point_of_sale_rounded, label: 'POS'),
    _TabItem(icon: Icons.inventory_2_rounded, label: 'Inventory'),
    _TabItem(icon: Icons.people_rounded, label: 'Customers'),
    _TabItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final currentIndex = ref.watch(navigationProvider);
    final nav = ref.read(navigationProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline_rounded, size: 48, color: scheme.error),
              const SizedBox(height: 16),
              Text(
                'Session expired',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(authProvider.notifier).signOut(),
                child: const Text('Return to Login'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: _buildAppBar(
        context,
        currentIndex,
        authState.user.businessName,
        scheme,
      ),
      body: _buildBody(currentIndex),
      bottomNavigationBar: _buildBottomNav(
        context,
        currentIndex,
        nav.setIndex,
        scheme,
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    int index,
    String businessName,
    ColorScheme scheme,
  ) {
    const titles = ['Dashboard', 'POS', 'Inventory', 'Customers', 'Settings'];
    return AppBar(
      backgroundColor: scheme.surfaceContainerLowest,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: scheme.outlineVariant,
      title: Text(
        titles[index],
        style: GoogleFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
      actions: index == 0
          ? [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: scheme.onSurfaceVariant,
                ),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
            ]
          : null,
    );
  }

  Widget _buildBody(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const PosPage();
      case 2:
        return const InventoryPage();
      case 3:
        return const CustomersPage();
      case 4:
        return const SettingsPage();
      default:
        return const DashboardPage();
    }
  }

  Widget _buildBottomNav(
    BuildContext context,
    int currentIndex,
    void Function(int) onTap,
    ColorScheme scheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              _tabs.length,
              (i) => Expanded(
                child: _NavItem(
                  tab: _tabs[i],
                  isActive: currentIndex == i,
                  onTap: () => onTap(i),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _NavItem extends StatelessWidget {
  final _TabItem tab;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.tab,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isActive
                  ? scheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(ViberantRadius.full),
            ),
            child: Icon(
              tab.icon,
              size: 22,
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            tab.label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
