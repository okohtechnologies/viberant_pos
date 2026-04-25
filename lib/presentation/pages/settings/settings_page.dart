import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/common/widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeModeProvider);

    if (authState is! AuthAuthenticated) {
      return const Center(child: CircularProgressIndicator());
    }

    final user = authState.user;
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Manage your account and preferences',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),

          // ── Account section ────────────────────────────────────────────────
          SectionLabel('Account'),
          _Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar with initials
                  AppAvatar(name: user.displayName, radius: 28),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.displayName,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                        const SizedBox(height: 6),
                        StatusChip.role(user.isAdmin),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Appearance section ─────────────────────────────────────────────
          SectionLabel('Appearance'),
          _Card(
            child: Column(
              children: [
                _SwitchTile(
                  icon: isDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  title: 'Dark Mode',
                  subtitle: isDark ? 'Dark theme active' : 'Light theme active',
                  value: isDark,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
                _Divider(),
                _SwitchTile(
                  icon: Icons.phone_android_rounded,
                  title: 'Use System Theme',
                  subtitle: 'Follow device settings',
                  value: themeMode == ThemeMode.system,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(v ? ThemeMode.system : ThemeMode.light),
                ),
              ],
            ),
          ),

          // ── Business section ───────────────────────────────────────────────
          SectionLabel('Business'),
          _Card(
            child: _InfoTile(
              icon: Icons.business_rounded,
              title: 'Business Name',
              value: user.businessName,
            ),
          ),

          // ── About section ──────────────────────────────────────────────────
          SectionLabel('About'),
          _Card(
            child: Column(
              children: [
                _InfoTile(
                  icon: Icons.info_outline_rounded,
                  title: 'App Version',
                  value: '1.0.0',
                ),
                _Divider(),
                _InfoTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Account Type',
                  value: user.isAdmin ? 'Administrator' : 'Employee',
                ),
              ],
            ),
          ),

          // ── Sign out ───────────────────────────────────────────────────────
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _showSignOutDialog(context, ref),
              style: OutlinedButton.styleFrom(
                foregroundColor: ViberantColors.error,
                side: BorderSide(color: ViberantColors.error.withOpacity(0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: ViberantColors.error,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
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
              'Sign Out',
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ViberantColors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─── Local helper widgets ─────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: ViberantColors.primary.withOpacity(0.03),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    clipBehavior: Clip.antiAlias,
    child: child,
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Divider(
    height: 1,
    thickness: 0.5,
    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
    indent: 56,
  );
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ViberantColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: ViberantColors.primary, size: 18),
    ),
    title: Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    subtitle: Text(
      subtitle,
      style: GoogleFonts.inter(
        fontSize: 12,
        color: Theme.of(context).colorScheme.outline,
      ),
    ),
    trailing: Switch(
      value: value,
      onChanged: onChanged,
      activeColor: ViberantColors.primary,
    ),
  );
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 18,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
    title: Text(
      title,
      style: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
    trailing: Text(
      value,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    ),
  );
}
