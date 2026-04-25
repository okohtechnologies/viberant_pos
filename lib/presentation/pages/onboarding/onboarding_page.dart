import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:viberant_pos/core/theme/app_theme.dart';
import '../auth/login_page.dart';

class OnboardingPage extends HookWidget {
  const OnboardingPage({super.key});

  static const _steps = [
    _StepData(
      title: 'Smart Sales Management',
      description:
          'Process sales quickly with our modern POS interface and multiple payment options including cash, MoMo, and card.',
      icon: Icons.point_of_sale_rounded,
      color: Color(0xFF4D41DF),
    ),
    _StepData(
      title: 'Inventory Insights',
      description:
          'Get real-time stock alerts, automatic low-stock warnings, and manage your entire product catalog effortlessly.',
      icon: Icons.inventory_2_rounded,
      color: Color(0xFF006B5C),
    ),
    _StepData(
      title: 'Real-time Analytics',
      description:
          'Make data-driven decisions with live revenue charts, sales reports, and cashier performance tracking.',
      icon: Icons.analytics_rounded,
      color: Color(0xFFFF9800),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final controller = usePageController();
    final current = useState(0);

    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Page view ──────────────────────────────────────────────────
            PageView.builder(
              controller: controller,
              onPageChanged: (v) => current.value = v,
              itemCount: _steps.length,
              itemBuilder: (ctx, i) => _StepPage(step: _steps[i]),
            ),

            // ── Skip button ────────────────────────────────────────────────
            Positioned(
              top: 12,
              right: 16,
              child: TextButton(
                onPressed: () => _toLogin(context),
                child: Text(
                  'Skip',
                  style: GoogleFonts.inter(
                    color: ViberantColors.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            // ── Bottom controls ────────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _BottomCard(
                current: current.value,
                total: _steps.length,
                onNext: () {
                  if (current.value < _steps.length - 1) {
                    controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _toLogin(context);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toLogin(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }
}

// ─── Step data model ──────────────────────────────────────────────────────────
class _StepData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  const _StepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// ─── Individual page ──────────────────────────────────────────────────────────
class _StepPage extends StatelessWidget {
  final _StepData step;
  const _StepPage({required this.step});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top tinted area with icon
        Expanded(
          flex: 5,
          child: Container(
            width: double.infinity,
            color: step.color.withOpacity(0.08),
            child: Center(
              child:
                  Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: step.color.withOpacity(0.15),
                              blurRadius: 40,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Icon(step.icon, size: 64, color: step.color),
                      )
                      .animate()
                      .scale(
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                        begin: const Offset(0.6, 0.6),
                      )
                      .fadeIn(),
            ),
          ),
        ),
        // Bottom space for the card overlay
        const Expanded(flex: 4, child: SizedBox()),
      ],
    );
  }
}

// ─── Bottom card ──────────────────────────────────────────────────────────────
class _BottomCard extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onNext;
  const _BottomCard({
    required this.current,
    required this.total,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final step = OnboardingPage._steps[current];
    final isLast = current == total - 1;

    return Container(
      decoration: BoxDecoration(
        color: ViberantColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              step.title,
              key: ValueKey(current),
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: ViberantColors.onSurface,
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Description
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              step.description,
              key: ValueKey('desc_$current'),
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ViberantColors.outline,
                height: 1.55,
              ),
            ),
          ),
          const SizedBox(height: 28),

          // Row: indicators + button
          Row(
            children: [
              // Dot indicators
              Row(
                children: List.generate(
                  total,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: i == current ? 24 : 8,
                    height: 8,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: i == current
                          ? ViberantColors.primary
                          : ViberantColors.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // Next / Get Started button
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ViberantColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isLast ? 'Get Started' : 'Continue',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
