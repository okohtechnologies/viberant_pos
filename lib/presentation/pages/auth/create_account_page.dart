import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/entities/user_entity.dart';
import '../../providers/auth_provider.dart';

class CreateAccountPage extends ConsumerStatefulWidget {
  const CreateAccountPage({super.key});

  @override
  ConsumerState<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends ConsumerState<CreateAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _businessNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirm = false;
  int _passwordStrength = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    _displayNameCtrl.dispose();
    _businessNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int _calcStrength(String p) {
    if (p.isEmpty) return 0;
    int s = 0;
    if (p.length >= 8) s++;
    if (p.contains(RegExp(r'[A-Z]'))) s++;
    if (p.contains(RegExp(r'[0-9]'))) s++;
    if (p.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) s++;
    return s;
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await ref
          .read(authProvider.notifier)
          .signUpWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passwordCtrl.text,
            displayName: _displayNameCtrl.text.trim(),
            businessName: _businessNameCtrl.text.trim(),
            role: UserRole.admin,
            phoneNumber: _phoneCtrl.text.trim().isEmpty
                ? null
                : _phoneCtrl.text.trim(),
          );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_cleanError(e.toString())),
            backgroundColor: ViberantColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _cleanError(String e) {
    if (e.contains('email-already-in-use')) return 'Email already registered';
    if (e.contains('weak-password')) return 'Password too weak';
    if (e.contains('invalid-email')) return 'Invalid email address';
    if (e.contains('network')) return 'Check your internet connection';
    return e.replaceAll('Exception:', '').trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ViberantColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back_rounded),
                color: ViberantColors.onSurface,
                padding: EdgeInsets.zero,
              ),
              const SizedBox(height: 16),

              Text(
                'Create Your Business',
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: ViberantColors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Set up your POS account in under 2 minutes',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: ViberantColors.outline,
                ),
              ),
              const SizedBox(height: 32),

              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _field(
                      ctrl: _businessNameCtrl,
                      label: 'Business Name',
                      icon: Icons.business_rounded,
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'Required'
                          : v!.length < 2
                          ? 'Min 2 chars'
                          : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _displayNameCtrl,
                      label: 'Your Full Name',
                      icon: Icons.person_rounded,
                      validator: (v) =>
                          (v?.isEmpty ?? true) ? 'Required' : null,
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _emailCtrl,
                      label: 'Email Address',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (!v!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _field(
                      ctrl: _phoneCtrl,
                      label: 'Phone Number (Optional)',
                      icon: Icons.phone_rounded,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 14),

                    // Password with strength bar
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: !_showPassword,
                      enabled: !_isLoading,
                      onChanged: (v) =>
                          setState(() => _passwordStrength = _calcStrength(v)),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outlined),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showPassword = !_showPassword),
                        ),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (v!.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),

                    // Strength bar
                    const SizedBox(height: 8),
                    _PasswordStrengthBar(strength: _passwordStrength),
                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_showConfirm,
                      enabled: !_isLoading,
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () =>
                              setState(() => _showConfirm = !_showConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Required';
                        if (v != _passwordCtrl.text)
                          return 'Passwords do not match';
                        return null;
                      },
                    ),
                    const SizedBox(height: 28),

                    // CTA
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createAccount,
                        child: _isLoading
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
                                'Create Business Account',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'By creating an account, you agree to our Terms of Service',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: ViberantColors.outline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Already have an account? ',
                          style: GoogleFonts.inter(
                            color: ViberantColors.outline,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text(
                            'Sign In',
                            style: GoogleFonts.inter(
                              color: ViberantColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final int strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final colors = [
      ViberantColors.error,
      ViberantColors.warning,
      const Color(0xFFEAB308),
      ViberantColors.success,
    ];
    final labels = ['Weak', 'Fair', 'Good', 'Strong'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: i < strength
                      ? colors[strength - 1]
                      : ViberantColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
        if (strength > 0) ...[
          const SizedBox(height: 4),
          Text(
            labels[strength - 1],
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors[strength - 1],
            ),
          ),
        ],
      ],
    );
  }
}
