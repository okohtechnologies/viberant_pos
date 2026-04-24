// lib/presentation/pages/splash/splash_page.dart
// Updated to match Stitch "Viberant Logic" splash spec:
// deep violet background, floating blurred circles, Poppins wordmark,
// animated logo scale-in. Navigation handled by main.dart auth stream —
// removed the manual pushReplacement timer.
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViberantColors.darkBackground,
      body: Stack(
        children: [
          // ── Decorative blurred circles (Stitch "Abstract Depth") ──
          const _BackgroundCircles(),

          // ── Centred content ──
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo card
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(ViberantRadius.lg),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: ViberantColors.darkPrimary.withValues(
                              alpha: 0.3,
                            ),
                            blurRadius: 40,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Image.asset(
                            'assets/images/viberant_logo4.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 800.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.5, 0.5),
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 32),

                // Wordmark: "Viberant" bold + "POS" light
                Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Viberant',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          ' POS',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w300,
                            color: Colors.white.withValues(alpha: 0.8),
                            height: 1.2,
                          ),
                        ),
                      ],
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0, duration: 500.ms),

                const SizedBox(height: 8),

                Text(
                  'Professional POS System',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 0.02 * 13,
                  ),
                ).animate().fadeIn(delay: 500.ms, duration: 600.ms),

                const SizedBox(height: 64),

                // Loading indicator
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      ViberantColors.darkPrimary.withValues(alpha: 0.6),
                    ),
                  ),
                ).animate().fadeIn(delay: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundCircles extends StatelessWidget {
  const _BackgroundCircles();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Stack(
      children: [
        _blur(
          size.width * 0.9,
          -60,
          -80,
          ViberantColors.darkPrimaryContainer,
          0.15,
        ),
        _blur(
          size.width * 0.6,
          size.width * 0.5,
          size.height * 0.6,
          ViberantColors.darkSecondaryContainer,
          0.1,
        ),
        _blur(
          size.width * 0.5,
          -40,
          size.height * 0.5,
          ViberantColors.darkTertiaryContainer,
          0.08,
        ),
      ],
    );
  }

  Widget _blur(
    double size,
    double left,
    double top,
    Color color,
    double opacity,
  ) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}
