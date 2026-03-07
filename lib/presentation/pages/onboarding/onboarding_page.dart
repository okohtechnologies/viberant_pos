// lib/presentation/pages/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../auth/login_page.dart';

class OnboardingPage extends HookWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final pageController = usePageController();
    final currentPage = useState(0);

    final pages = [
      _OnboardingStep(
        title: "Smart Sales Management",
        description:
            "Process sales quickly with our modern POS interface and multiple payment options",
        icon: Icons.point_of_sale_rounded,
      ),
      _OnboardingStep(
        title: "AI Inventory Insights",
        description:
            "Get smart stock predictions and automatic reorder suggestions",
        icon: Icons.inventory_2_rounded,
      ),
      _OnboardingStep(
        title: "Real-time Analytics",
        description:
            "Make data-driven decisions with beautiful charts and reports",
        icon: Icons.analytics_rounded,
      ),
    ];

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        child: Stack(
          children: [
            // Page View
            PageView(
              controller: pageController,
              onPageChanged: (value) => currentPage.value = value,
              children: pages,
            ),

            // Skip Button
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () => _navigateToLogin(context),
                child: Text(
                  "Skip",
                  style: GoogleFonts.inter(
                    color: Color(0xFF718096),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // Bottom Section
            Positioned(
              bottom: 40,
              left: 24,
              right: 24,
              child: Column(
                children: [
                  // Page Indicators
                  _buildPageIndicators(currentPage.value, pages.length),
                  SizedBox(height: 32),

                  // Animated Continue Button
                  _AnimatedContinueButton(
                    currentPage: currentPage.value,
                    totalPages: pages.length,
                    onPressed: () {
                      if (currentPage.value < pages.length - 1) {
                        pageController.nextPage(
                          duration: Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        _navigateToLogin(context);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageIndicators(int currentPage, int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          width: currentPage == index ? 24 : 8,
          height: 8,
          margin: EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: currentPage == index
                ? Color(0xFF6C63FF)
                : Color(0xFF718096).withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ).animate(delay: Duration(milliseconds: index * 100)).scale();
      }),
    );
  }

  void _navigateToLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
    );
  }
}

class _OnboardingStep extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const _OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon Container
          Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Icon(icon, color: Color(0xFF6C63FF), size: 120),
              )
              .animate()
              .scale(
                duration: Duration(milliseconds: 600),
                curve: Curves.elasticOut,
              )
              .fadeIn(),

          SizedBox(height: 48),

          Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                  height: 1.2,
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 200))
              .slideY(begin: 0.3, end: 0),

          SizedBox(height: 16),

          Text(
                description,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF718096),
                  height: 1.5,
                ),
              )
              .animate()
              .fadeIn(delay: Duration(milliseconds: 400))
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _AnimatedContinueButton extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPressed;

  const _AnimatedContinueButton({
    required this.currentPage,
    required this.totalPages,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  currentPage == totalPages - 1 ? "Get Started" : "Continue",
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(delay: Duration(milliseconds: 600))
        .slideY(begin: 0.5, end: 0);
  }
}
