import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/presentation/providers/dashboard_provider.dart';
import '../../core/constants/breakpoints.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/navigation_provider.dart';
import '../pages/dasboard/dashboard_page.dart';
import '../pages/pos/pos_page.dart';
import '../pages/inventory/inventory_page.dart';
import '../pages/customers/customers_page.dart';
import '../pages/settings/settings_page.dart';
import '../../domain/states/auth_state.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  static const _titles = [
    'Dashboard',
    'POS',
    'Inventory',
    'Customers',
    'Settings',
  ];
  static const _icons = [
    Icons.dashboard_rounded,
    Icons.point_of_sale_rounded,
    Icons.inventory_2_rounded,
    Icons.people_rounded,
    Icons.settings_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final idx = ref.watch(navigationProvider);
    final navNotifier = ref.read(navigationProvider.notifier);

    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDesktop = Breakpoints.isDesktop(context);

    if (isDesktop) {
      return _DesktopLayout(
        idx: idx,
        navNotifier: navNotifier,
        authState: authState,
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context, idx, authState.user.businessName, ref),
      body: _buildBody(idx),
      bottomNavigationBar: _buildBottomNav(context, idx, navNotifier),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    int idx,
    String businessName,
    WidgetRef ref,
  ) {
    return AppBar(
      title: Row(
        children: [
          Text(
            _titles[idx],
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
      actions: idx == 0
          ? [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () {},
                tooltip: 'Notifications',
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: () => ref.invalidate(dashboardStatsProvider),
                tooltip: 'Refresh',
              ),
              const SizedBox(width: 8),
            ]
          : null,
    );
  }

  Widget _buildBody(int idx) {
    switch (idx) {
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
    int idx,
    NavigationNotifier notifier,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
              5,
              (i) => _NavItem(
                icon: _icons[i],
                label: _titles[i],
                isActive: idx == i,
                onTap: () => notifier.setIndex(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop sidebar layout ───────────────────────────────────────────────────
class _DesktopLayout extends ConsumerWidget {
  final int idx;
  final NavigationNotifier navNotifier;
  final AuthAuthenticated authState;

  const _DesktopLayout({
    required this.idx,
    required this.navNotifier,
    required this.authState,
  });

  static const _titles = MainLayout._titles;
  static const _icons = MainLayout._icons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 240,
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              children: [
                const SizedBox(height: 24),
                // Brand
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: ViberantColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.point_of_sale_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Viberant',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: ViberantColors.primary,
                            ),
                          ),
                          Text(
                            authState.user.businessName,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: ViberantColors.outline,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.4),
                ),
                const SizedBox(height: 8),

                // Nav items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: List.generate(
                      5,
                      (i) => _SidebarItem(
                        icon: _icons[i],
                        label: _titles[i],
                        isActive: idx == i,
                        onTap: () => navNotifier.setIndex(i),
                      ),
                    ),
                  ),
                ),

                // User section
                Divider(
                  color: Theme.of(
                    context,
                  ).colorScheme.outlineVariant.withOpacity(0.4),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: ViberantColors.primary.withOpacity(
                          0.1,
                        ),
                        child: Text(
                          authState.user.displayName.isNotEmpty
                              ? authState.user.displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: ViberantColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              authState.user.displayName,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: ViberantColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ADMIN',
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: ViberantColors.primary,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        color: ViberantColors.outline,
                        onPressed: () =>
                            ref.read(authProvider.notifier).signOut(),
                        tooltip: 'Sign Out',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          VerticalDivider(
            width: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withOpacity(0.4),
          ),

          // Main content
          Expanded(
            child: Column(
              children: [
                // Desktop top bar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    border: Border(
                      bottom: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _titles[idx],
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      if (idx == 0) ...[
                        IconButton(
                          icon: const Icon(Icons.notifications_none_rounded),
                          onPressed: () {},
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded),
                          onPressed: () =>
                              ref.invalidate(dashboardStatsProvider),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: _buildBody(idx)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(int idx) {
    switch (idx) {
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
}

class _SidebarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: isActive ? ViberantColors.primary.withOpacity(0.08) : null,
        borderRadius: BorderRadius.circular(10),
        border: isActive
            ? Border(left: BorderSide(color: ViberantColors.primary, width: 3))
            : null,
      ),
      child: ListTile(
        dense: true,
        contentPadding: EdgeInsets.only(left: isActive ? 13 : 16, right: 8),
        leading: Icon(
          icon,
          size: 20,
          color: isActive ? ViberantColors.primary : ViberantColors.outline,
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
            color: isActive
                ? ViberantColors.primary
                : ViberantColors.onSurfaceVariant,
          ),
        ),
        onTap: onTap,
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
    final color = isActive ? ViberantColors.primary : ViberantColors.outline;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? ViberantColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
