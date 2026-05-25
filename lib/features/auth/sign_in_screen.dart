// sign_in_screen.dart — TradeRep Pro
// Real Firebase email/password sign-in with timeout and full error handling.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/config/app_config.dart';
import '../../shared/services/app_state.dart';
import '../../shared/services/auth_service.dart';
import '../../shared/widgets/tr_widgets.dart';
import 'sign_up_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────
  Future<void> _signIn() async {
    debugPrint('[SignInScreen] Sign-in button pressed');

    if (!_formKey.currentState!.validate()) {
      debugPrint('[SignInScreen] Form validation failed');
      return;
    }

    setState(() { _loading = true; _error = null; });
    debugPrint('[SignInScreen] Firebase configured: ${AppConfig.isFirebaseConfigured}');
    debugPrint('[SignInScreen] Calling AuthService.signIn...');

    final result = await AuthService.instance.signIn(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    debugPrint('[SignInScreen] AuthService result: success=${result.success}, error=${result.error}');

    if (!mounted) return;

    if (!result.success) {
      debugPrint('[SignInScreen] Auth FAILED — showing error');
      setState(() { _loading = false; _error = result.error; });
      return;
    }

    // ── Auth succeeded — navigate immediately, load data in background ──────
    debugPrint('[SignInScreen] Auth SUCCESS — triggering navigation');

    // Set logged-in state immediately so MaterialApp navigates to MainShell
    // _initFirestoreStreams runs in the background after navigation
    final state = context.read<AppState>();
    state.onFirebaseSignIn(result.user); // fire-and-forget intentionally

    debugPrint('[SignInScreen] Navigation triggered via state.isLoggedIn = true');
    // No need to pop — MaterialApp's Consumer rebuilds to MainShell automatically
  }

  // ─── Forgot Password ───────────────────────────────────────────────────────
  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email address above first.');
      return;
    }
    final result = await AuthService.instance.sendPasswordReset(email);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.success
            ? 'Reset email sent to $email — check your inbox.'
            : result.error ?? 'Could not send reset email.'),
        backgroundColor: result.success ? TRColors.success : TRColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TRColors.navyDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                // Logo
                Center(child: const TRLogo(size: 72, showTagline: false)),
                const SizedBox(height: 32),

                // Heading
                const Text(
                  'Welcome back',
                  style: TextStyle(
                    color: TRColors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                const Text(
                  'Sign in to your TradeRep account',
                  style: TextStyle(color: TRColors.grayLight, fontSize: 15),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),

                // Demo mode banner
                if (!AppConfig.isFirebaseConfigured) ...[
                  _DemoBanner(),
                  const SizedBox(height: 4),
                ],

                // Email
                _label('Email address'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: TRColors.white),
                  decoration: _inputDeco('you@example.com', Icons.email_outlined),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Password
                _label('Password'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _signIn(),
                  style: const TextStyle(color: TRColors.white),
                  decoration: _inputDeco('••••••••', Icons.lock_outline).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                        color: TRColors.grayMid, size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Password must be at least 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 8),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _forgotPassword,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    ),
                    child: const Text(
                      'Forgot password?',
                      style: TextStyle(color: TRColors.gold, fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Error
                if (_error != null) ...[
                  _ErrorBox(_error!),
                  const SizedBox(height: 16),
                ],

                // Sign In button
                _AuthButton(
                  label: 'Sign In',
                  loading: _loading,
                  onTap: _signIn,
                ),
                const SizedBox(height: 28),

                // Divider
                const Row(children: [
                  Expanded(child: Divider(color: TRColors.divider)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: TRColors.grayMid, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: TRColors.divider)),
                ]),
                const SizedBox(height: 24),

                // Sign up link
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Text(
                    "Don't have an account?",
                    style: TextStyle(color: TRColors.grayLight, fontSize: 14),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignUpScreen()),
                    ),
                    child: const Text(
                      'Create one free',
                      style: TextStyle(
                        color: TRColors.gold, fontSize: 14, fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      color: TRColors.grayLight, fontSize: 13,
      fontWeight: FontWeight.w500, letterSpacing: 0.3,
    ),
  );

  InputDecoration _inputDeco(String hint, IconData icon) => InputDecoration(
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

// ─── Shared auth widgets — used by SignInScreen and SignUpScreen ──────────────

class _DemoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            'Preview mode — enter any email & password to continue.',
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

class _AuthButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _AuthButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: TRColors.gold,
          disabledBackgroundColor: TRColors.gold.withValues(alpha: 0.6),
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
