// sign_up_screen.dart — TradeRep Pro
// Firebase email/password account creation with company setup.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/tr_widgets.dart';
import '../../core/config/app_config.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _error;
  String _selectedTrade = 'General Contractor';

  static const List<String> _trades = [
    'General Contractor',
    'Roofing',
    'HVAC',
    'Plumbing',
    'Electrical',
    'Flooring',
    'Painting',
    'Remodeling',
    'Home Services',
    'Construction',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    debugPrint('[SignUpScreen] Create Account pressed');
    if (!_formKey.currentState!.validate()) {
      debugPrint('[SignUpScreen] Form validation failed');
      return;
    }
    setState(() { _loading = true; _error = null; });
    debugPrint('[SignUpScreen] Firebase configured: ${AppConfig.isFirebaseConfigured}');
    debugPrint('[SignUpScreen] Calling AuthService.signUp...');

    final result = await AuthService.instance.signUp(
      email: _emailCtrl.text,
      password: _passCtrl.text,
      fullName: _nameCtrl.text.trim(),
      companyName: _companyCtrl.text.trim(),
      tradeCategory: _selectedTrade,
      phone: _phoneCtrl.text.trim(),
    );

    debugPrint('[SignUpScreen] result: success=${result.success}, error=${result.error}');
    if (!mounted) return;

    if (!result.success) {
      debugPrint('[SignUpScreen] SignUp FAILED — showing error');
      setState(() { _loading = false; _error = result.error; });
      return;
    }

    // ── Success: clear spinner FIRST, then navigate ───────────────────────────
    debugPrint('[SignUpScreen] SignUp SUCCESS — clearing spinner and triggering navigation');

    // CRITICAL: clear loading state before onFirebaseSignIn so the spinner
    // doesn't stay stuck if the widget lingers during the Navigator rebuild.
    setState(() { _loading = false; });

    final state = context.read<AppState>();
    state.onFirebaseSignIn(result.user); // void — notifyListeners() fires immediately
    debugPrint('[SignUpScreen] Navigation triggered via state.isLoggedIn = true');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      appBar: AppBar(
        backgroundColor: TRColors.navyDeep,
        foregroundColor: TRColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create Account',
          style: TextStyle(color: TRColors.white, fontWeight: FontWeight.w600, fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Heading
                Center(child: const TRLogo(size: 56, showTagline: false)),
                const SizedBox(height: 20),
                const Text(
                  'Start your free trial',
                  style: TextStyle(
                    color: TRColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                const Text(
                  '14 days free · No credit card required',
                  style: TextStyle(color: TRColors.gold, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),

                // Demo banner
                if (!AppConfig.isFirebaseConfigured) _DemoBanner(),

                // ── Section: About You ──────────────────────────────────────
                _sectionLabel('About You'),
                const SizedBox(height: 10),

                _field(
                  controller: _nameCtrl,
                  hint: 'John Smith',
                  label: 'Full name',
                  icon: Icons.person_outline_rounded,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Your name is required' : null,
                ),
                const SizedBox(height: 14),

                _field(
                  controller: _emailCtrl,
                  hint: 'you@company.com',
                  label: 'Email address',
                  icon: Icons.email_outlined,
                  type: TextInputType.emailAddress,
                  action: TextInputAction.next,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                _field(
                  controller: _phoneCtrl,
                  hint: '(555) 555-5555',
                  label: 'Phone number',
                  icon: Icons.phone_outlined,
                  type: TextInputType.phone,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Phone number is required' : null,
                ),
                const SizedBox(height: 24),

                // ── Section: Your Business ──────────────────────────────────
                _sectionLabel('Your Business'),
                const SizedBox(height: 10),

                _field(
                  controller: _companyCtrl,
                  hint: 'Apex Roofing LLC',
                  label: 'Company name',
                  icon: Icons.business_outlined,
                  action: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Company name is required' : null,
                ),
                const SizedBox(height: 14),

                // Trade category dropdown
                _label('Trade / specialty'),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _selectedTrade,
                  dropdownColor: TRColors.navyDark,
                  style: const TextStyle(color: TRColors.white, fontSize: 15),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, color: TRColors.grayMid),
                  decoration: _inputDecoration('', Icons.construction_outlined),
                  items: _trades.map((t) => DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  )).toList(),
                  onChanged: (v) => setState(() => _selectedTrade = v ?? _selectedTrade),
                ),
                const SizedBox(height: 24),

                // ── Section: Password ───────────────────────────────────────
                _sectionLabel('Set Password'),
                const SizedBox(height: 10),

                // Password
                _label('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: TRColors.white),
                  decoration: _inputDecoration('Min. 6 characters', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: TRColors.grayMid, size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                // Confirm password
                _label('Confirm password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signUp(),
                  style: const TextStyle(color: TRColors.white),
                  decoration: _inputDecoration('Repeat password', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: TRColors.grayMid, size: 20,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passCtrl.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Error
                if (_error != null) _ErrorBox(_error!),
                if (_error != null) const SizedBox(height: 16),

                // Create Account button
                _PrimaryButton(
                  label: 'Create Account',
                  loading: _loading,
                  onTap: _signUp,
                ),
                const SizedBox(height: 16),

                // Terms note
                const Text(
                  'By creating an account you agree to our Terms of Service and Privacy Policy.',
                  style: TextStyle(color: TRColors.grayMid, fontSize: 11),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: TRColors.gold,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.2,
    ),
  );

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: TRColors.grayLight,
      fontSize: 13,
      fontWeight: FontWeight.w500,
    ),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required String label,
    required IconData icon,
    TextInputType type = TextInputType.text,
    TextInputAction action = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label(label),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: type,
        textInputAction: action,
        style: const TextStyle(color: TRColors.white),
        decoration: _inputDecoration(hint, icon),
        validator: validator,
      ),
    ]);
  }

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: TRColors.grayMid),
    prefixIcon: Icon(icon, color: TRColors.grayMid, size: 20),
    filled: true,
    fillColor: TRColors.navyDark,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TRColors.divider),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TRColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TRColors.gold, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TRColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: TRColors.error, width: 1.5),
    ),
    errorStyle: const TextStyle(color: TRColors.error),
  );
}

// ─── Shared widgets (imported by sign_in_screen.dart too) ────────────────────

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TRColors.goldDim,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TRColors.gold.withValues(alpha: 0.3)),
      ),
      child: const Row(children: [
        Icon(Icons.info_outline_rounded, color: TRColors.gold, size: 16),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            'Preview mode — any credentials will sign you in.',
            style: TextStyle(color: TRColors.gold, fontSize: 12),
          ),
        ),
      ]),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox(this.message);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: TRColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: TRColors.error.withValues(alpha: 0.4)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline_rounded, color: TRColors.error, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: TRColors.error, fontSize: 13),
          ),
        ),
      ]),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: TRColors.gold,
          disabledBackgroundColor: TRColors.gold.withValues(alpha: 0.5),
          foregroundColor: TRColors.navyDeep,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: TRColors.navyDeep,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3,
                ),
              ),
      ),
    );
  }
}
