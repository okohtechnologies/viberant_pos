import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:viberant_pos/presentation/providers/sale_repository_provider.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/states/auth_state.dart';
import '../providers/auth_provider.dart';
import '../widgets/common/viberant_card.dart';
import '../widgets/common/widgets.dart';
import 'pos/pos_page.dart';

class UserLayout extends ConsumerStatefulWidget {
  const UserLayout({super.key});

  @override
  ConsumerState<UserLayout> createState() => _UserLayoutState();
}

class _UserLayoutState extends ConsumerState<UserLayout> {
  int _currentIndex = 0;

  void navigateToPage(int index) {
    if (index == 2) {
      _showLogoutConfirmation();
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _currentIndex == 0
          ? _buildAppBar(authState.user.businessName)
          : null,
      body: _currentIndex == 0
          ? UserHomePage(onNavigate: navigateToPage)
          : const PosPage(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  AppBar _buildAppBar(String businessName) => AppBar(
    backgroundColor: ViberantColors.primary,
    elevation: 0,
    automaticallyImplyLeading: false,
    title: Text(
      businessName.isEmpty ? 'Viberant POS' : businessName,
      style: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.italic,
        color: Colors.white,
      ),
    ),
    actions: const [SizedBox(width: 8)],
  );

  Widget _buildBottomNav() {
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
            children: [
              _NavBtn(
                icon: Icons.home_rounded,
                label: 'Home',
                isActive: _currentIndex == 0,
                onTap: () => navigateToPage(0),
              ),
              _NavBtn(
                icon: Icons.point_of_sale_rounded,
                label: 'POS',
                isActive: _currentIndex == 1,
                onTap: () => navigateToPage(1),
              ),
              _NavBtn(
                icon: Icons.logout_rounded,
                label: 'Logout',
                isActive: false,
                isLogout: true,
                onTap: () => navigateToPage(2),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogoutConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: ViberantColors.error,
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.inter(color: ViberantColors.outline),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).signOut();
    }
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLogout;
  final VoidCallback onTap;
  const _NavBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isLogout = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? ViberantColors.error
        : isActive
        ? ViberantColors.primary
        : ViberantColors.outline;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? ViberantColors.primary.withOpacity(0.08) : null,
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

// ─── User Home Page ───────────────────────────────────────────────────────────
class UserHomePage extends ConsumerWidget {
  final void Function(int) onNavigate;
  const UserHomePage({required this.onNavigate, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState is! AuthAuthenticated) return const SizedBox.shrink();

    final user = authState.user;
    final todayData = ref.watch(todaySalesProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),

          // ── Greeting ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, Enjoy work Today 🤭',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: ViberantColors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              StatusChip.role(user.isAdmin),
            ],
          ),
          const SizedBox(height: 28),

          // ── Quick Actions 2×2 Grid ───────────────────────────────────────
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.1,
            children: [
              _ActionCard(
                title: 'Start POS',
                subtitle: 'Process new sales',
                icon: Icons.point_of_sale_rounded,
                color: ViberantColors.primary,
                onTap: () => onNavigate(1),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              _ActionCard(
                title: 'Sales History',
                subtitle: 'Past transactions',
                icon: Icons.history_rounded,
                color: ViberantColors.success,
                onTap: () =>
                    AppNavigator.toOrderHistory(context, user.businessId),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              _ActionCard(
                title: "Today's Sales",
                subtitle: 'Daily summary',
                icon: Icons.today_rounded,
                color: ViberantColors.warning,
                onTap: () =>
                    AppNavigator.toTodaySales(context, user.businessId),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              _ActionCard(
                title: 'Products',
                subtitle: 'Browse inventory',
                icon: Icons.inventory_2_rounded,
                color: ViberantColors.info,
                onTap: () => AppNavigator.toProducts(context, user.businessId),
              ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
            ],
          ),
          const SizedBox(height: 28),

          // ── Today's Summary Card ─────────────────────────────────────────
          GestureDetector(
            onTap: () => AppNavigator.toTodaySales(context, user.businessId),
            child: todayData.when(
              loading: () => const ShimmerCard(height: 100),
              error: (_, __) => const SizedBox.shrink(),
              data: (sales) {
                final revenue = sales.fold(0.0, (s, e) => s + e.finalAmount);
                return ViberantCard(
                  color: ViberantColors.primary.withOpacity(0.06),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "Today's Summary",
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: ViberantColors.outline,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _SummaryMetric(
                            label: 'Total Revenue',
                            value:
                                '₵${NumberFormat('#,###.00').format(revenue)}',
                            color: ViberantColors.primary,
                          ),
                          const SizedBox(width: 20),
                          _SummaryMetric(
                            label: 'Total Sales',
                            value: '${sales.length}',
                            color: ViberantColors.success,
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 350.ms);
              },
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ViberantCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: ViberantColors.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: GoogleFonts.inter(fontSize: 11, color: ViberantColors.outline),
      ),
      const SizedBox(height: 4),
      Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ],
  );
}
