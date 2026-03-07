// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:viberant_pos/domain/states/auth_state.dart';
import 'package:viberant_pos/presentation/pages/main_layout.dart';
import '../../pages/user_layout.dart';
import '../../providers/auth_provider.dart';
import 'create_account_page.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final isPasswordVisible = useState(false);
    final authState = ref.watch(authProvider);

    // Handle successful login
    useEffect(() {
      if (authState is AuthAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final user = authState.user;
          if (user.isAdmin) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainLayout()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const UserLayout()),
            );
          }
        });
      }
      return null;
    }, [authState]);

    void navigateToCreateAccount() {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateAccountPage()),
      );
    }

    void forgotPassword() {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Password Reset'),
          content: const Text(
            'Password reset functionality will be implemented soon.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // Purple Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF8A7FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Animated floating circles
          const Positioned(
            top: -50,
            left: -50,
            child: _AnimatedCircle(color: Colors.white24, size: 120),
          ),
          const Positioned(
            bottom: -40,
            right: -40,
            child: _AnimatedCircle(color: Colors.white24, size: 180),
          ),

          // Login Card
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome Text
                      Text(
                            "Welcome Back",
                            style: GoogleFonts.poppins(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF2D3748),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 8),

                      Text(
                            "Sign in to continue to Viberant POS",
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: const Color(0xFF718096),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 48),

                      // Email Field
                      TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: "Email Address",
                              prefixIcon: const Icon(
                                Icons.email_rounded,
                                color: Color(0xFF718096),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 300.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 20),

                      // Password Field
                      TextField(
                            controller: passwordController,
                            obscureText: !isPasswordVisible.value,
                            decoration: InputDecoration(
                              labelText: "Password",
                              prefixIcon: const Icon(
                                Icons.lock_rounded,
                                color: Color(0xFF718096),
                              ),
                              suffixIcon: IconButton(
                                onPressed: () => isPasswordVisible.value =
                                    !isPasswordVisible.value,
                                icon: Icon(
                                  isPasswordVisible.value
                                      ? Icons.visibility_rounded
                                      : Icons.visibility_off_rounded,
                                  color: const Color(0xFF718096),
                                ),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFFE2E8F0),
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                  color: Color(0xFF6C63FF),
                                ),
                              ),
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 400.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 16),

                      // Forgot Password
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: forgotPassword,
                          child: Text(
                            "Forgot Password?",
                            style: GoogleFonts.inter(
                              color: const Color(0xFF6C63FF),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 500.ms),

                      // Error Message
                      if (authState is AuthError)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF44336).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF44336).withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                color: Color(0xFFF44336),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  authState.message,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: const Color(0xFFF44336),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn().slideY(begin: -0.2, end: 0),

                      if (authState is AuthError) const SizedBox(height: 16),

                      const SizedBox(height: 24),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: (authState is AuthLoading)
                              ? null
                              : () {
                                  if (emailController.text.isEmpty ||
                                      passwordController.text.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Please enter both email and password',
                                        ),
                                        backgroundColor: Color(0xFFF44336),
                                      ),
                                    );
                                    return;
                                  }

                                  ref
                                      .read(authProvider.notifier)
                                      .signInWithEmailAndPassword(
                                        emailController.text.trim(),
                                        passwordController.text.trim(),
                                      );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: authState is AuthLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : Text(
                                  "Sign In",
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 32),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: Colors.grey.withOpacity(0.3)),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "OR",
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: Colors.grey.withOpacity(0.3)),
                          ),
                        ],
                      ).animate().fadeIn(delay: 700.ms),

                      const SizedBox(height: 32),

                      // Create Account Button
                      Column(
                            children: [
                              Text(
                                "You're Newbie 🥹?",
                                style: GoogleFonts.inter(
                                  color: Colors.grey[700],
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: OutlinedButton(
                                  onPressed: navigateToCreateAccount,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    side: const BorderSide(
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                  child: Text(
                                    "Create Business Account",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6C63FF),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideY(begin: 0.2, end: 0),

                      const SizedBox(height: 32),

                      // Copyright Text
                      Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.copyright,
                              size: 16,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              "2025 OKOH TECHNOLOGIES",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 900.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated floating circle widget
class _AnimatedCircle extends StatefulWidget {
  final double size;
  final Color color;
  const _AnimatedCircle({required this.size, required this.color});

  @override
  State<_AnimatedCircle> createState() => _AnimatedCircleState();
}

class _AnimatedCircleState extends State<_AnimatedCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: 20,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Transform.translate(
        offset: Offset(_animation.value, _animation.value),
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
