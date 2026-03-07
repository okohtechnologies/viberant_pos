// lib/presentation/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';

import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: ViberantColors.onSurface,
              ),
            ),
            SizedBox(height: 24),
            if (authState is AuthAuthenticated) ...[
              _SettingsCard(
                title: 'Business Profile',
                subtitle: 'Manage your business information',
                icon: Icons.business_rounded,
                onTap: () {},
              ),
              _SettingsCard(
                title: 'Tax Settings',
                subtitle: 'Configure tax rates and rules',
                icon: Icons.percent_rounded,
                onTap: () {},
              ),
              _SettingsCard(
                title: 'Receipt Settings',
                subtitle: 'Customize receipt templates',
                icon: Icons.receipt_long_rounded,
                onTap: () {},
              ),
              _SettingsCard(
                title: 'Notifications',
                subtitle: 'Manage alerts and notifications',
                icon: Icons.notifications_rounded,
                onTap: () {},
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => ref.read(authProvider.notifier).signOut(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViberantColors.error,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Sign Out'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ViberantColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: ViberantColors.primary),
        ),
        title: Text(
          title,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right_rounded),
        onTap: onTap,
      ),
    );
  }
}
