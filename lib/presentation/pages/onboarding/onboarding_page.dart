// lib/presentation/pages/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../auth/login_page.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _OnboardingData(
      icon: Icons.point_of_sale_rounded,
      title: 'Fast Checkout',
      body:
          'Process sales in seconds with our intuitive point-of-sale interface built for high-volume retail.',
      accentColor: ViberantColors.darkPrimary,
    ),
    _OnboardingData(
      icon: Icons.inventory_2_rounded,
      title: 'Live Inventory',
      body:
          'Stock levels update in real time across all your devices the moment a sale is made.',
      accentColor: ViberantColors.darkTertiary,
    ),
    _OnboardingData(
      icon: Icons.bar_chart_rounded,
      title: 'Smart Reports',
      body:
          'Understand your business at a glance — daily revenue, top products, and cashier performance.',
      accentColor: ViberantColors.darkSecondary,
    ),
  ];

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeOut,
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ViberantColors.darkBackground,
      body: Stack(
        children: [
          // Background circles
          Positioned(
            top: -80,
            left: -60,
            child: _circle(
              size.width * 0.85,
              ViberantColors.darkPrimaryContainer,
              0.12,
            ),
          ),
          Positioned(
            bottom: size.height * 0.3,
            right: -80,
            child: _circle(
              size.width * 0.6,
              ViberantColors.darkSecondaryContainer,
              0.08,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16, top: 8),
                    child: TextButton(
                      onPressed: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(fontSize: 14),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemCount: _pages.length,
                    itemBuilder: (_, i) => _PageContent(data: _pages[i]),
                  ),
                ),

                // Bottom card
                _buildBottomCard(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomCard() {
    final isLast = _currentPage == _pages.length - 1;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(ViberantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          // Page indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _pages.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? ViberantColors.darkPrimary
                      : Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _next,
              style: ElevatedButton.styleFrom(
                backgroundColor: ViberantColors.darkPrimary,
                foregroundColor: ViberantColors.darkOnPrimary,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(ViberantRadius.card),
                ),
                elevation: 0,
              ),
              child: Text(
                isLast ? 'Get Started' : 'Continue',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double s, Color c, double o) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: o),
    ),
  );
}

class _PageContent extends StatelessWidget {
  final _OnboardingData data;
  const _PageContent({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: data.accentColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: data.accentColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: data.accentColor.withValues(alpha: 0.25),
                      blurRadius: 40,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 44, color: data.accentColor),
              )
              .animate()
              .scale(duration: 500.ms, curve: Curves.elasticOut)
              .fadeIn(),
          const SizedBox(height: 40),
          Text(
            data.title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            data.body,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.6),
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String body;
  final Color accentColor;
  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.body,
    required this.accentColor,
  });
}
