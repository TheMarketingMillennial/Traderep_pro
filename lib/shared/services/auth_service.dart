// auth_service.dart — TradeRep Pro
// Wraps Firebase Authentication. Includes 12s timeout on every call,
// full debug logging, and demo-mode fallback when Firebase is not configured.

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../core/config/app_config.dart';

// ─── Result type ──────────────────────────────────────────────────────────────
class AuthResult {
  final bool success;
  final String? error;
  final User? user;

  const AuthResult._({required this.success, this.error, this.user});

  factory AuthResult.ok(User user) => AuthResult._(success: true, user: user);

  /// Success with no Firebase user (demo mode)
  factory AuthResult.demo() => const AuthResult._(success: true);

  factory AuthResult.fail(String error) =>
      AuthResult._(success: false, error: error);
}

// ─── Auth timeout ─────────────────────────────────────────────────────────────
const Duration _kAuthTimeout = Duration(seconds: 12);

// ─── AuthService ──────────────────────────────────────────────────────────────
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  FirebaseAuth get _auth => FirebaseAuth.instance;
  FirebaseFirestore get _db => FirebaseFirestore.instance;

  /// Whether Firebase Auth is actually usable right now.
  bool get isAvailable => AppConfig.isFirebaseConfigured;

  User? get currentUser => isAvailable ? _auth.currentUser : null;

  Stream<User?> authStateChanges() {
    if (!isAvailable) return const Stream.empty();
    return _auth.authStateChanges();
  }

  // ─── Sign In ───────────────────────────────────────────────────────────────
  Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('[AuthService] signIn() called — email: ${email.trim()}');
    debugPrint('[AuthService] Firebase available: $isAvailable');

    if (!isAvailable) {
      debugPrint('[AuthService] Firebase not configured — blocking sign-in');
      return AuthResult.fail(
        'Authentication is not configured. Please contact support.',
      );
    }

    try {
      debugPrint('[AuthService] Calling signInWithEmailAndPassword...');
      final cred = await _auth
          .signInWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            _kAuthTimeout,
            onTimeout: () => throw TimeoutException(
              'Firebase sign-in timed out after ${_kAuthTimeout.inSeconds}s. '
              'Check your network connection.',
            ),
          );

      debugPrint('[AuthService] signIn SUCCESS — uid: ${cred.user?.uid}');
      return AuthResult.ok(cred.user!);
    } on TimeoutException catch (e) {
      debugPrint('[AuthService] signIn TIMEOUT: $e');
      return AuthResult.fail(
        'Sign-in timed out. Check your internet connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} — ${e.message}');
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      debugPrint('[AuthService] Unexpected signIn error: $e');
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
    debugPrint('[AuthService] signUp() called — email: ${email.trim()}');
    debugPrint('[AuthService] Firebase available: $isAvailable');

    if (!isAvailable) {
      debugPrint('[AuthService] Firebase not configured — blocking sign-up');
      return AuthResult.fail(
        'Account creation is not available. Please contact support.',
      );
    }

    try {
      debugPrint('[AuthService] Calling createUserWithEmailAndPassword...');
      final cred = await _auth
          .createUserWithEmailAndPassword(
            email: email.trim(),
            password: password,
          )
          .timeout(
            _kAuthTimeout,
            onTimeout: () => throw TimeoutException(
              'Sign-up timed out after ${_kAuthTimeout.inSeconds}s.',
            ),
          );

      final user = cred.user!;
      debugPrint('[AuthService] Account created — uid: ${user.uid}');

      await user.updateDisplayName(fullName);

      // Write Firestore docs with a separate timeout
      await _writeNewUserDocs(
        uid: user.uid,
        fullName: fullName,
        email: email.trim(),
        companyName: companyName,
        tradeCategory: tradeCategory,
        phone: phone,
      );

      debugPrint('[AuthService] signUp SUCCESS — uid: ${user.uid}');
      return AuthResult.ok(user);
    } on TimeoutException catch (e) {
      debugPrint('[AuthService] signUp TIMEOUT: $e');
      return AuthResult.fail(
        'Sign-up timed out. Check your internet connection and try again.',
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('[AuthService] FirebaseAuthException: ${e.code} — ${e.message}');
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      debugPrint('[AuthService] Unexpected signUp error: $e');
      return AuthResult.fail('Sign up failed. Please try again.');
    }
  }

  Future<void> _writeNewUserDocs({
    required String uid,
    required String fullName,
    required String email,
    required String companyName,
    required String tradeCategory,
    required String phone,
  }) async {
    try {
      final batch = _db.batch();

      batch.set(_db.collection('companies').doc(uid), {
        'name': companyName,
        'owner_uid': uid,
        'trade_category': tradeCategory,
        'phone': phone,
        'email': email,
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

      batch.set(_db.collection('users').doc(uid), {
        'uid': uid,
        'name': fullName,
        'email': email,
        'role': 'admin',
        'company_id': uid,
        'avatar_url': '',
        'created_at': FieldValue.serverTimestamp(),
      });

      await batch.commit().timeout(const Duration(seconds: 10));
      debugPrint('[AuthService] Firestore docs written for uid: $uid');
    } catch (e) {
      // Non-fatal — user is authenticated, Firestore write can be retried
      debugPrint('[AuthService] Warning: Firestore write failed: $e');
    }
  }

  // ─── Sign Out ──────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    debugPrint('[AuthService] signOut() called');
    if (!isAvailable) {
      debugPrint('[AuthService] Demo mode — nothing to sign out of');
      return;
    }
    try {
      await _auth.signOut();
      debugPrint('[AuthService] signOut SUCCESS');
    } catch (e) {
      debugPrint('[AuthService] signOut error: $e');
    }
  }

  // ─── Password Reset ────────────────────────────────────────────────────────
  Future<AuthResult> sendPasswordReset(String email) async {
    debugPrint('[AuthService] sendPasswordReset — email: ${email.trim()}');

    if (!isAvailable) {
      return AuthResult.fail(
        'Password reset is only available in the production app with Firebase configured.',
      );
    }

    try {
      await _auth
          .sendPasswordResetEmail(email: email.trim())
          .timeout(_kAuthTimeout);
      debugPrint('[AuthService] Password reset email sent');
      return AuthResult._(success: true);
    } on TimeoutException {
      return AuthResult.fail('Request timed out. Try again.');
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authMessage(e.code));
    } catch (e) {
      return AuthResult.fail('Could not send reset email. Please try again.');
    }
  }

  // ─── Human-readable error messages ────────────────────────────────────────
  String _authMessage(String code) {
    debugPrint('[AuthService] Mapping error code: $code');
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email address.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account with that email already exists. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled. Contact support.';
      case 'configuration-not-found':
      case 'api-key-not-valid':
        return 'Firebase is not configured correctly. Contact support.';
      default:
        return 'Authentication failed ($code). Please try again.';
    }
  }
}
