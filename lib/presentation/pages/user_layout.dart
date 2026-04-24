// lib/presentation/pages/user_layout.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import '../pages/pos/pos_page.dart';
import '../pages/orders/order_history.dart';
import '../pages/sales/today_sales_page.dart';
import '../../domain/states/auth_state.dart';

class UserLayout extends ConsumerStatefulWidget {
  const UserLayout({super.key});

  @override
  ConsumerState<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends ConsumerState<UserLayout> {
  int _index = 0;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Home'),
    _TabItem(icon: Icons.point_of_sale_rounded, label: 'POS'),
    _TabItem(icon: Icons.receipt_long_rounded, label: 'My Sales'),
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final scheme = Theme.of(context).colorScheme;

    if (authState is! AuthAuthenticated) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            child: const Text('Return to Login'),
          ),
        ),
      );
    }

    const titles = ['Home', 'POS', 'My Sales'];

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Text(
          titles[_index],
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: scheme.surfaceContainerLowest,
        elevation: 0,
        actions: [
          // Sign out icon in app bar for quick access
          if (_index == 0)
            IconButton(
              icon: Icon(
                Icons.logout_rounded,
                size: 20,
                color: scheme.onSurfaceVariant,
              ),
              tooltip: 'Sign out',
              onPressed: () => _confirmSignOut(context),
            ),
        ],
      ),
      body: _buildBody(authState),
      bottomNavigationBar: _buildBottomNav(scheme),
    );
  }

  Widget _buildBody(AuthAuthenticated authState) {
    switch (_index) {
      case 0:
        return _EmployeeHome(user: authState.user);
      case 1:
        return const PosPage();
      case 2:
        return const OrderHistoryPage();
      default:
        return _EmployeeHome(user: authState.user);
    }
  }

  Widget _buildBottomNav(ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 60,
          child: Row(
            children: List.generate(
              _tabs.length,
              (i) => Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _index = i),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _index == i
                              ? scheme.primary.withValues(alpha: 0.1)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(
                            ViberantRadius.full,
                          ),
                        ),
                        child: Icon(
                          _tabs[i].icon,
                          size: 22,
                          color: _index == i
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _tabs[i].label,
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: _index == i
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: _index == i
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Sign Out',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

class _EmployeeHome extends StatelessWidget {
  final dynamic user;
  const _EmployeeHome({required this.user});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [scheme.primary, scheme.primaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(ViberantRadius.card),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_greeting()},',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.businessName,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    user.displayName.isNotEmpty
                        ? user.displayName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Quick action grid
        Text(
          'Quick Actions',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            _QuickCard(
              icon: Icons.point_of_sale_rounded,
              label: 'New Sale',
              color: scheme.primary,
              onTap: () {},
            ),
            _QuickCard(
              icon: Icons.receipt_long_rounded,
              label: 'My Orders',
              color: ViberantColors.secondary,
              onTap: () {},
            ),
            _QuickCard(
              icon: Icons.today_rounded,
              label: "Today's Sales",
              color: ViberantColors.tertiary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TodaySalesPage()),
              ),
            ),
            _QuickCard(
              icon: Icons.history_rounded,
              label: 'Full History',
              color: ViberantColors.info,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const OrderHistoryPage()),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'morning';
    if (h < 17) return 'afternoon';
    return 'evening';
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(ViberantRadius.card),
          boxShadow: ViberantShadows.level1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(ViberantRadius.sm),
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ],
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
