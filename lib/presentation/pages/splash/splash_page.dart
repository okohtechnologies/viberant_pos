// lib/presentation/pages/splash/splash_page.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(Duration(seconds: 5));

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF6C63FF),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/viberant_logo4.png', // ← your logo
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                )
                // First animation: scale-in bounce
                .animate()
                .scale(duration: 800.ms, curve: Curves.elasticOut)
                // Then continuous pulse (no blur)
                .then()
                .animate(onPlay: (controller) => controller.repeat())
                .scale(
                  duration: 1500.ms,
                  begin: Offset(1, 1),
                  end: Offset(1.07, 1.07),
                  curve: Curves.easeInOut,
                ),

            SizedBox(height: 32),

            // App Name
            Text(
              'Professional POS System',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.3, end: 0),
          ],
        ),
      ),
    );
  }
}
