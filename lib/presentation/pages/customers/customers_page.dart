// lib/presentation/pages/customers/customers_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_rounded, size: 64, color: ViberantColors.primary),
            SizedBox(height: 16),
            Text(
              'Customer Management',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: ViberantColors.onSurface,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Coming Soon!',
              style: GoogleFonts.inter(
                fontSize: 16,
                color: ViberantColors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
