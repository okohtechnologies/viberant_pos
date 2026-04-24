// lib/presentation/pages/auth/create_account_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/states/auth_state.dart';
import '../../providers/auth_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _obscureConfirm = true;
  String? _errorMessage;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _businessCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _errorMessage = null);
    await ref
        .read(authProvider.notifier)
        .signUpWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          displayName: _nameCtrl.text.trim(),
          businessName: _businessCtrl.text.trim(),
          role: UserRole.admin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthLoading;
    final size = MediaQuery.of(context).size;

    if (authState is AuthError && _errorMessage != authState.message) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _errorMessage = authState.message);
      });
    }

    return Scaffold(
      backgroundColor: ViberantColors.darkBackground,
      body: Stack(
        children: [
          _buildBackground(size),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  // Back + title
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Create Account',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ).animate().fadeIn(),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 52),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Register your business to get started',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFormCard(
                    isLoading,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Size size) => Stack(
    children: [
      Positioned(
        top: -100,
        right: -60,
        child: _circle(
          size.width * 0.8,
          ViberantColors.darkPrimaryContainer,
          0.12,
        ),
      ),
      Positioned(
        bottom: -80,
        left: -60,
        child: _circle(
          size.width * 0.6,
          ViberantColors.darkSecondaryContainer,
          0.08,
        ),
      ),
    ],
  );

  Widget _circle(double s, Color c, double o) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: c.withValues(alpha: o),
    ),
  );

  Widget _buildFormCard(bool isLoading) {
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
            if (_errorMessage != null) ...[
              _errorBanner(_errorMessage!),
              const SizedBox(height: 20),
            ],
            _label('Full Name'),
            const SizedBox(height: 8),
            _field(
              _nameCtrl,
              'e.g. Kofi Mensah',
              Icons.person_outline_rounded,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 16),
            _label('Business Name'),
            const SizedBox(height: 8),
            _field(
              _businessCtrl,
              'e.g. Accra Fresh Foods',
              Icons.store_outlined,
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Business name is required'
                  : null,
            ),
            const SizedBox(height: 16),
            _label('Email address'),
            const SizedBox(height: 8),
            _field(
              _emailCtrl,
              'you@example.com',
              Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) =>
                  v == null || !v.contains('@') ? 'Enter a valid email' : null,
            ),
            const SizedBox(height: 16),
            _label('Password'),
            const SizedBox(height: 8),
            _field(
              _passwordCtrl,
              '••••••••',
              Icons.lock_outline_rounded,
              obscure: _obscurePass,
              toggleObscure: () => setState(() => _obscurePass = !_obscurePass),
              validator: (v) =>
                  v == null || v.length < 6 ? 'Minimum 6 characters' : null,
            ),
            const SizedBox(height: 16),
            _label('Confirm Password'),
            const SizedBox(height: 8),
            _field(
              _confirmCtrl,
              '••••••••',
              Icons.lock_outline_rounded,
              obscure: _obscureConfirm,
              toggleObscure: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
              validator: (v) =>
                  v != _passwordCtrl.text ? 'Passwords do not match' : null,
            ),
            const SizedBox(height: 24),
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
                        'Create Account',
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

  Widget _label(String text) => Text(
    text,
    style: GoogleFonts.inter(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: Colors.white.withValues(alpha: 0.7),
    ),
  );

  Widget _errorBanner(String msg) => Container(
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
            msg,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: ViberantColors.darkError,
            ),
          ),
        ),
      ],
    ),
  );

  Widget _field(
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      obscureText: obscure,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withValues(alpha: 0.3),
          fontSize: 14,
        ),
        prefixIcon: Icon(icon, size: 18, color: Colors.white38),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: Colors.white38,
                ),
                onPressed: toggleObscure,
              )
            : null,
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
          borderSide: const BorderSide(
            color: ViberantColors.darkPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkError,
            width: 1,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(ViberantRadius.md),
          borderSide: const BorderSide(
            color: ViberantColors.darkError,
            width: 2,
          ),
        ),
        errorStyle: GoogleFonts.inter(color: ViberantColors.darkError),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}
