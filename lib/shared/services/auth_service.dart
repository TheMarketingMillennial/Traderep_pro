// auth_service.dart — TradeRep Pro
// Wraps Firebase Authentication. All auth operations go through here.
// AppState listens to authStateChanges() to drive login/logout navigation.

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

// ─── Result type ─────────────────────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.ok(User user) => AuthResult._(success: true, user: user);
  factory AuthResult.fail(String error) =>
      AuthResult._(success: false, error: error);
}

// ─── AuthService ─────────────────────────────────────────────────────────────
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  // Current signed-in Firebase user (null if not logged in)
  User? get currentUser => AppConfig.isFirebaseConfigured ? _auth.currentUser : null;

  // Stream that emits on sign-in / sign-out / token refresh
  Stream<User?> authStateChanges() {
    if (!AppConfig.isFirebaseConfigured) {
      return const Stream.empty();
    }
    return _auth.authStateChanges();
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    if (!AppConfig.isFirebaseConfigured) {
      // Demo mode — simulate successful sign-in
      return AuthResult._(success: true, user: null);
    }
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return AuthResult.ok(cred.user!);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      return AuthResult.fail('Sign in failed. Please try again.');
    }
  }

  // ─── Sign Up ───────────────────────────────────────────────────────────────
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String companyName,
    required String tradeCategory,
    required String phone,
  }) async {
    if (!AppConfig.isFirebaseConfigured) {
      return AuthResult._(success: true, user: null);
    }
    try {
      // 1. Create Firebase Auth account
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user!;

      // 2. Update display name
      await user.updateDisplayName(fullName);

      // 3. Write company document (keyed to uid)
      await _db.collection('companies').doc(user.uid).set({
        'name': companyName,
        'owner_uid': user.uid,
        'trade_category': tradeCategory,
        'phone': phone,
        'email': email.trim(),
        'logo_url': '',
        'service_area': '',
        'website': '',
        'team_size': 1,
        'google_connected': false,
        'google_business_id': '',
        'google_review_link': '',
        'gbp_location_id': null,
        'created_at': FieldValue.serverTimestamp(),
      });

      // 4. Write user document
      await _db.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': fullName,
        'email': email.trim(),
        'role': 'admin',
        'company_id': user.uid,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      return AuthResult.ok(user);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      if (kDebugMode) debugPrint('AuthService.signUp error: $e');
      return AuthResult.fail('Sign up failed. Please try again.');
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    if (!AppConfig.isFirebaseConfigured) return;
    await _auth.signOut();
  }

  // ─── Password Reset ────────────────────────────────────────────────────────
  Future<AuthResult> sendPasswordReset(String email) async {
    if (!AppConfig.isFirebaseConfigured) {
      return AuthResult.fail('Firebase not configured in this build.');
    }
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return AuthResult._(success: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      return AuthResult.fail('Could not send reset email. Please try again.');
    }
  }

  // ─── Human-readable Firebase error messages ────────────────────────────────
  String _authMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
