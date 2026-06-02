// ─────────────────────────────────────────────────────────────────────────────
// app_config.dart — TradeRep Pro
//
// Single source of truth for all runtime configuration.
//
// ─── Platform strategy ───────────────────────────────────────────────────────
//
//  • Android APK  → Firebase reads config from google-services.json at runtime.
//                   No --dart-define needed. isFirebaseConfigured detects this
//                   by checking Firebase.apps after initialization.
//
//  • Web build    → No google-services.json. Needs --dart-define flags:
//                   FIREBASE_API_KEY, FIREBASE_PROJECT_ID, FIREBASE_APP_ID_WEB,
//                   FIREBASE_AUTH_DOMAIN, FIREBASE_STORAGE_BUCKET,
//                   FIREBASE_MESSAGING_SENDER_ID
//                   Without them the app runs in demo mode on sample data.
//
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';

class AppConfig {
  AppConfig._(); // static-only

  // ── Firebase (Web --dart-define values) ───────────────────────────────────
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY', defaultValue: '',
  );
  static const String firebaseAppIdWeb = String.fromEnvironment(
    'FIREBASE_APP_ID_WEB', defaultValue: '',
  );
  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID', defaultValue: '',
  );
  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS', defaultValue: '',
  );
  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID', defaultValue: '',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID', defaultValue: '',
  );
  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN', defaultValue: '',
  );
  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET', defaultValue: '',
  );
  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL', defaultValue: '',
  );

  // ── AI Server URL ─────────────────────────────────────────────────────────
  // All three server URLs point to the same Railway instance — split into
  // separate dart-defines so they can be overridden independently if needed.
  static const String aiServerUrl = String.fromEnvironment(
    'AI_SERVER_URL', defaultValue: 'https://web-production-548f4.up.railway.app',
  );

  // ── Server URLs ───────────────────────────────────────────────────────────
  static const String smsServerUrl = String.fromEnvironment(
    'SMS_SERVER_URL', defaultValue: 'https://web-production-548f4.up.railway.app',
  );
  static const String gbpServerUrl = String.fromEnvironment(
    'GBP_SERVER_URL', defaultValue: 'https://web-production-548f4.up.railway.app',
  );
  static const String stripeServerUrl = String.fromEnvironment(
    'STRIPE_SERVER_URL', defaultValue: 'https://web-production-548f4.up.railway.app',
  );
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_live_UBpghiWEYoROk4vQ98a9mu37',
  );

  // ── Firebase Configured Check ─────────────────────────────────────────────
  //
  // IMPORTANT: This checks whether Firebase was successfully initialized,
  // not whether --dart-define flags are present.
  //
  // On Android: google-services.json provides credentials — Firebase.apps
  //             will be non-empty after initializeApp() succeeds.
  // On Web:     --dart-define flags are required. If API key is empty,
  //             Firebase was not initialized and we run in demo mode.
  //
  // Call isFirebaseConfigured only AFTER main() has attempted initializeApp().
  // Use _firebaseInitialized flag which is set by main().

  static bool _firebaseInitialized = false;

  /// Captured exception from Firebase.initializeApp() if it failed.
  /// Displayed in the UI to help diagnose initialization errors.
  static String? firebaseInitError;

  /// Called by main() after a successful Firebase.initializeApp().
  static void markFirebaseInitialized() {
    _firebaseInitialized = true;
    firebaseInitError = null; // clear any previous error
    debugPrint('[AppConfig] Firebase marked as initialized ✅');
  }

  /// True if Firebase was successfully initialized at startup.
  /// Works for both Android (google-services.json) and Web (embedded config).
  static bool get isFirebaseConfigured {
    // Primary check: was initializeApp() called successfully?
    if (_firebaseInitialized) return true;
    // Secondary check: Firebase.apps is non-empty (covers Android native init)
    if (Firebase.apps.isNotEmpty) return true;
    return false;
  }

  static List<String> get missingKeys {
    final missing = <String>[];
    if (firebaseApiKey.isEmpty) missing.add('FIREBASE_API_KEY');
    if (firebaseProjectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (firebaseMessagingSenderId.isEmpty) missing.add('FIREBASE_MESSAGING_SENDER_ID');
    if (firebaseAuthDomain.isEmpty) missing.add('FIREBASE_AUTH_DOMAIN');
    if (firebaseStorageBucket.isEmpty) missing.add('FIREBASE_STORAGE_BUCKET');
    return missing;
  }
}
