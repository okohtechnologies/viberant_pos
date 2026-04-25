import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';
import '../main_layout.dart';
import '../user_layout.dart';
import 'create_account_page.dart';

class LoginPage extends HookConsumerWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final emailCtrl = useTextEditingController();
    final passwordCtrl = useTextEditingController();
    final showPassword = useState(false);
    final authState = ref.watch(authProvider);
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Handle successful login
    useEffect(() {
      if (authState is AuthAuthenticated) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => authState.user.isAdmin
                  ? const MainLayout()
                  : const UserLayout(),
            ),
          );
        });
      }
      return null;
    }, [authState]);

    final isLoading = authState is AuthLoading;
    final errorMsg = authState is AuthError
        // ignore: unnecessary_cast
        ? (authState as AuthError).message
        : null;

    return Scaffold(
      body: Stack(
        children: [
          // ── Gradient background ──────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4D41DF), Color(0xFF7B73F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // ── Decorative circles ───────────────────────────────────────────
          const Positioned(
            top: -70,
            left: -70,
            child: _DecorativeCircle(size: 220),
          ),
          const Positioned(
            bottom: -90,
            right: -90,
            child: _DecorativeCircle(size: 300),
          ),

          // ── Scrollable form area ─────────────────────────────────────────
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Error banner
                    if (errorMsg != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: ViberantColors.error.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: ViberantColors.error.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline_rounded,
                              color: Colors.red.shade200,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _cleanError(errorMsg),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.red.shade100,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: -0.2),

                    // Glass card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.88),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.4),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Form(
                            key: formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome Back',
                                  style: GoogleFonts.poppins(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w700,
                                    color: ViberantColors.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'Sign in to continue to Viberant POS',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: ViberantColors.outline,
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Email
                                TextFormField(
                                  controller: emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  enabled: !isLoading,
                                  decoration: const InputDecoration(
                                    labelText: 'Email Address',
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty)
                                      return 'Required';
                                    if (!v.contains('@'))
                                      return 'Invalid email';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                // Password
                                TextFormField(
                                  controller: passwordCtrl,
                                  obscureText: !showPassword.value,
                                  enabled: !isLoading,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outlined),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        showPassword.value
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                      onPressed: () => showPassword.value =
                                          !showPassword.value,
                                    ),
                                  ),
                                  validator: (v) => (v == null || v.isEmpty)
                                      ? 'Required'
                                      : null,
                                ),
                                const SizedBox(height: 8),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        _showForgotPassword(context, ref),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: Text(
                                      'Forgot Password?',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: ViberantColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Sign In button
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: ElevatedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            if (formKey.currentState!
                                                .validate()) {
                                              ref
                                                  .read(authProvider.notifier)
                                                  .signInWithEmailAndPassword(
                                                    emailCtrl.text.trim(),
                                                    passwordCtrl.text,
                                                  );
                                            }
                                          },
                                    child: isLoading
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor:
                                                  AlwaysStoppedAnimation(
                                                    Colors.white,
                                                  ),
                                            ),
                                          )
                                        : Text(
                                            'Sign In',
                                            style: GoogleFonts.inter(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Create account
                                SizedBox(
                                  width: double.infinity,
                                  height: 52,
                                  child: OutlinedButton(
                                    onPressed: isLoading
                                        ? null
                                        : () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  const CreateAccountPage(),
                                            ),
                                          ),
                                    style: OutlinedButton.styleFrom(
                                      side: BorderSide(
                                        color: ViberantColors.primary
                                            .withOpacity(0.4),
                                      ),
                                    ),
                                    child: Text(
                                      'Create Account',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: ViberantColors.primary,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _cleanError(String msg) {
    if (msg.contains('wrong-password') || msg.contains('invalid-credential')) {
      return 'Incorrect email or password';
    }
    if (msg.contains('user-not-found'))
      return 'No account found with this email';
    if (msg.contains('too-many-requests'))
      return 'Too many attempts. Try again later';
    if (msg.contains('deactivated'))
      return 'Account is deactivated. Contact admin';
    if (msg.contains('network')) return 'No internet connection';
    return msg.replaceAll('Exception:', '').trim();
  }

  void _showForgotPassword(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          'Reset Password',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter your email and we\'ll send a reset link.',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: ViberantColors.outline,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email Address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              if (ctrl.text.isNotEmpty) {
                await ref
                    .read(authProvider.notifier)
                    .sendPasswordResetEmail(ctrl.text.trim());
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Reset email sent!')),
                  );
                }
              }
            },
            child: const Text('Send Link'),
          ),
        ],
      ),
    );
  }
}

class _DecorativeCircle extends StatelessWidget {
  final double size;
  const _DecorativeCircle({required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.09),
    ),
  );
}
