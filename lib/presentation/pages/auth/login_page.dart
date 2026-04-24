// lib/presentation/pages/auth/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/create_account_page.dart';
import '../../../domain/states/auth_state.dart';

class LoginPage extends ConsumerStatefulWidget {
  final String? initialError;
  const LoginPage({super.key, this.initialError});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.initialError;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref
        .read(authProvider.notifier)
        .signInWithEmailAndPassword(_emailCtrl.text.trim(), _passwordCtrl.text);
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final size = MediaQuery.of(context).size;
    final scheme = Theme.of(context).colorScheme;

    // Surface any auth errors
    if (authState is AuthError && _errorMessage != authState.message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _errorMessage = authState.message);
      });
    }

    return Scaffold(
      backgroundColor: ViberantColors.darkBackground,
      body: Stack(
        children: [
          // Background circles
          _buildBackground(size),

          // Scrollable form content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  SizedBox(height: size.height * 0.08),

                  // Logo + wordmark
                  _buildHeader()
                      .animate()
                      .fadeIn(duration: 600.ms)
                      .slideY(begin: -0.2, end: 0),

                  SizedBox(height: size.height * 0.06),

                  // Glass card
                  _buildFormCard(isLoading, scheme)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),

                  const SizedBox(height: 24),

                  // Sign up link
                  _buildSignUpRow(scheme).animate().fadeIn(delay: 400.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) {
    return Stack(
      children: [
        Positioned(
          top: -80,
          left: -60,
          child: _circle(
            size.width * 0.9,
            ViberantColors.darkPrimaryContainer,
            0.15,
          ),
        ),
        Positioned(
          bottom: -60,
          right: -80,
          child: _circle(
            size.width * 0.7,
            ViberantColors.darkSecondaryContainer,
            0.1,
          ),
        ),
      ],
    );
  }

  Widget _circle(double size, Color color, double opacity) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: color.withValues(alpha: opacity),
    ),
  );

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(ViberantRadius.lg),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: ViberantColors.darkPrimary.withValues(alpha: 0.4),
                blurRadius: 32,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Image.asset(
              'assets/images/viberant_logo4.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Viberant',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            Text(
              ' POS',
              style: GoogleFonts.poppins(
                fontSize: 26,
                fontWeight: FontWeight.w300,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          'Sign in to your account',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(bool isLoading, ColorScheme scheme) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(ViberantRadius.lg),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: ViberantColors.darkError.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(ViberantRadius.md),
                  border: Border.all(
                    color: ViberantColors.darkError.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 16,
                      color: ViberantColors.darkError,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: ViberantColors.darkError,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Email
            _fieldLabel('Email address'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration: _darkFieldDecoration(
                hint: 'you@example.com',
                icon: Icons.email_outlined,
              ),
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),

            const SizedBox(height: 16),

            // Password
            _fieldLabel('Password'),
            const SizedBox(height: 8),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscure,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              decoration:
                  _darkFieldDecoration(
                    hint: '••••••••',
                    icon: Icons.lock_outline_rounded,
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 18,
                        color: Colors.white38,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Minimum 6 characters' : null,
              onFieldSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: 8),

            // Forgot password
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  foregroundColor: ViberantColors.darkPrimary,
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 32),
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(fontSize: 13),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Sign in button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ViberantColors.darkPrimary,
                  foregroundColor: ViberantColors.darkOnPrimary,
                  minimumSize: const Size(double.infinity, 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ViberantRadius.card),
                  ),
                  elevation: 0,
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : Text(
                        'Sign In',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpRow(ColorScheme scheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(
            fontSize: 14,
            color: Colors.white.withValues(alpha: 0.5),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateAccountPage()),
          ),
          style: TextButton.styleFrom(
            foregroundColor: ViberantColors.darkPrimary,
            padding: EdgeInsets.zero,
            minimumSize: const Size(0, 32),
          ),
          child: Text(
            'Create account',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _fieldLabel(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.7),
    ),
  );

  InputDecoration _darkFieldDecoration({
    required String hint,
    required IconData icon,
  }) => InputDecoration(
    hintText: hint,
    hintStyle: GoogleFonts.inter(
      color: Colors.white.withValues(alpha: 0.3),
      fontSize: 14,
    ),
    prefixIcon: Icon(icon, size: 18, color: Colors.white38),
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.06),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ViberantRadius.md),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ViberantRadius.md),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ViberantRadius.md),
      borderSide: const BorderSide(color: ViberantColors.darkPrimary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ViberantRadius.md),
      borderSide: const BorderSide(color: ViberantColors.darkError, width: 1),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(ViberantRadius.md),
      borderSide: const BorderSide(color: ViberantColors.darkError, width: 2),
    ),
    errorStyle: GoogleFonts.inter(color: ViberantColors.darkError),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
  );
}
