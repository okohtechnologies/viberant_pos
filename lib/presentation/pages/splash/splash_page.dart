import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Navigation is handled by main.dart auth state — SplashPage auto-replaces
    // when AuthNotifier resolves (Initial → Authenticated/Unauthenticated).
    // No manual navigation timer needed.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4D41DF), Color(0xFF675DF9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative circles ─────────────────────────────────────────────
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 120,
            left: -40,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // ── Center content ─────────────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo container
                Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 12),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Image.asset(
                          'assets/images/viberant_logo4.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.point_of_sale_rounded,
                            color: Color(0xFF4D41DF),
                            size: 48,
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .scale(
                      duration: 700.ms,
                      curve: Curves.elasticOut,
                      begin: const Offset(0.5, 0.5),
                    )
                    .fadeIn(duration: 400.ms),

                const SizedBox(height: 28),

                // Wordmark
                RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Viberant',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: ' POS',
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 8),

                Text(
                  'Smart Sales. Instant Insights.',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.6),
                    letterSpacing: 0.3,
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 500.ms),

                const SizedBox(height: 40),

                // Animated loading dots
                _LoadingDots().animate().fadeIn(delay: 600.ms),
              ],
            ),
          ),

          // ── Version number ─────────────────────────────────────────────────
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.white.withOpacity(0.3),
              ),
            ).animate().fadeIn(delay: 700.ms),
          ),
        ],
      ),
    );
  }
}

class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final phase = (_ctrl.value * 3 - i).clamp(0.0, 1.0);
            final opacity = (phase < 0.5 ? phase * 2 : (1 - phase) * 2).clamp(
              0.3,
              1.0,
            );
            return Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(opacity),
              ),
            );
          },
        );
      }),
    );
  }
}
