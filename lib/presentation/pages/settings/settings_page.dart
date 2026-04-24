// lib/presentation/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/app_avatar.dart';
import '../../widgets/common/viberant_card.dart';
import '../../pages/admin/users_management_page.dart';
import '../../pages/reports/sales_report_page.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);
    final themeNotifier = ref.read(themeModeProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    if (authState is! AuthAuthenticated) return const SizedBox.shrink();
    final user = authState.user;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        ViberantCard(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              AppAvatar(name: user.displayName, size: 56),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.displayName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primaryContainer,
                        borderRadius: BorderRadius.circular(
                          ViberantRadius.full,
                        ),
                      ),
                      child: Text(
                        user.isAdmin ? 'Admin' : 'Staff',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: scheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
        _SectionLabel('Business'),
        const SizedBox(height: 8),
        ViberantCard(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.store_rounded,
                label: 'Business Name',
                trailing: Text(
                  user.businessName,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Divider(height: 1, indent: 52),
              _SettingsTile(
                icon: Icons.badge_rounded,
                label: 'Business ID',
                trailing: Text(
                  user.businessId.length > 12
                      ? '${user.businessId.substring(0, 12)}…'
                      : user.businessId,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        _SectionLabel('Appearance'),
        const SizedBox(height: 8),
        ViberantCard(
          child: _SettingsTile(
            icon: Icons.dark_mode_rounded,
            label: 'Dark Mode',
            trailing: Switch(
              value: themeMode == ThemeMode.dark,
              onChanged: (v) => themeNotifier.setThemeMode(
                v ? ThemeMode.dark : ThemeMode.light,
              ),
              activeColor: scheme.primary,
            ),
          ),
        ),

        if (user.isAdmin) ...[
          const SizedBox(height: 20),
          _SectionLabel('Admin'),
          const SizedBox(height: 8),
          ViberantCard(
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.people_rounded,
                  label: 'Manage Staff',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UsersManagementPage(),
                    ),
                  ),
                  showChevron: true,
                ),
                const Divider(height: 1, indent: 52),
                _SettingsTile(
                  icon: Icons.bar_chart_rounded,
                  label: 'Sales Reports',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesReportPage()),
                  ),
                  showChevron: true,
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 20),
        _SectionLabel('Account'),
        const SizedBox(height: 8),
        ViberantCard(
          child: _SettingsTile(
            icon: Icons.logout_rounded,
            label: 'Sign Out',
            iconColor: scheme.error,
            labelColor: scheme.error,
            onTap: () => _confirmSignOut(context, ref),
          ),
        ),

        const SizedBox(height: 32),
        Center(
          child: Text(
            'Viberant POS  ·  v1.0.0',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref) {
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

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      label.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showChevron;
  final Color? iconColor;
  final Color? labelColor;

  const _SettingsTile({
    required this.icon,
    required this.label,
    this.trailing,
    this.onTap,
    this.showChevron = false,
    this.iconColor,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(ViberantRadius.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor ?? scheme.onSurfaceVariant),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: labelColor ?? scheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: scheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
