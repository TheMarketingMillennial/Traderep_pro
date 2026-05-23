// ─────────────────────────────────────────────────────────────────────────────
// app_config.dart — TradeRep Pro
//
// Single source of truth for all runtime configuration.
// Values are injected at BUILD TIME via --dart-define flags — never hardcoded.
//
// ─── How to build with secrets ───────────────────────────────────────────────
//
//   flutter build web --release \
//     --dart-define=FIREBASE_API_KEY=AIzaSy... \
//     --dart-define=FIREBASE_APP_ID_WEB=1:518...:web:abc \
//     --dart-define=FIREBASE_APP_ID_ANDROID=1:518...:android:def \
//     --dart-define=FIREBASE_MESSAGING_SENDER_ID=518784222528 \
//     --dart-define=FIREBASE_PROJECT_ID=traderep-pro \
//     --dart-define=FIREBASE_AUTH_DOMAIN=traderep-pro.firebaseapp.com \
//     --dart-define=FIREBASE_STORAGE_BUCKET=traderep-pro.firebasestorage.app \
//     --dart-define=FIREBASE_DATABASE_URL=https://traderep-pro-default-rtdb.firebaseio.com \
//     --dart-define=SMS_SERVER_URL=https://your-app.up.railway.app \
//     --dart-define=GBP_SERVER_URL=https://your-app.up.railway.app
//
//   flutter build apk --release [same --dart-define flags]
//
// ─── Local development ───────────────────────────────────────────────────────
//   Copy .env.example → .env and fill in values.
//   Then run: source scripts/load_env.sh && flutter run --dart-define=...
//   Or use VS Code launch.json / Android Studio run configurations.
//
// ─── GitHub / CI ─────────────────────────────────────────────────────────────
//   Store all values as GitHub Actions Secrets or Railway environment variables.
//   NEVER commit real values to this file or any other tracked file.
//
// ─────────────────────────────────────────────────────────────────────────────

class AppConfig {
  AppConfig._(); // static-only

  // ── Firebase ──────────────────────────────────────────────────────────────
  // Injected via --dart-define at build time. Empty strings = Firebase init
  // will throw a clear error rather than silently using wrong credentials.

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String firebaseAppIdWeb = String.fromEnvironment(
    'FIREBASE_APP_ID_WEB',
    defaultValue: '',
  );

  static const String firebaseAppIdAndroid = String.fromEnvironment(
    'FIREBASE_APP_ID_ANDROID',
    defaultValue: '',
  );

  static const String firebaseAppIdIos = String.fromEnvironment(
    'FIREBASE_APP_ID_IOS',
    defaultValue: '',
  );

  static const String firebaseMessagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
    defaultValue: '',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: '',
  );

  static const String firebaseAuthDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
    defaultValue: '',
  );

  static const String firebaseStorageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
    defaultValue: '',
  );

  static const String firebaseDatabaseUrl = String.fromEnvironment(
    'FIREBASE_DATABASE_URL',
    defaultValue: '',
  );

  // ── SMS Proxy Server ──────────────────────────────────────────────────────
  // In development: http://localhost:5061
  // In production:  https://your-app.up.railway.app
  // SmsService falls back to local mock if this URL is unreachable.

  static const String smsServerUrl = String.fromEnvironment(
    'SMS_SERVER_URL',
    defaultValue: 'http://localhost:5061',
  );

  // ── GBP Proxy Server ──────────────────────────────────────────────────────
  // Same Railway deployment as the SMS server — both endpoints live in
  // sms_server.py (now also handles /gbp/* routes).
  // In development: http://localhost:5061
  // In production:  https://your-app.up.railway.app
  // GbpService degrades gracefully when this URL is unreachable.

  static const String gbpServerUrl = String.fromEnvironment(
    'GBP_SERVER_URL',
    defaultValue: 'http://localhost:5061',
  );

  // ── Validation ────────────────────────────────────────────────────────────
  // Call this from main() in debug mode to catch missing config early.

  static bool get isFirebaseConfigured =>
      firebaseApiKey.isNotEmpty &&
      firebaseProjectId.isNotEmpty &&
      (firebaseAppIdWeb.isNotEmpty ||
          firebaseAppIdAndroid.isNotEmpty ||
          firebaseAppIdIos.isNotEmpty);

  static List<String> get missingKeys {
    final missing = <String>[];
    if (firebaseApiKey.isEmpty) missing.add('FIREBASE_API_KEY');
    if (firebaseProjectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (firebaseMessagingSenderId.isEmpty) missing.add('FIREBASE_MESSAGING_SENDER_ID');
    if (firebaseAuthDomain.isEmpty) missing.add('FIREBASE_AUTH_DOMAIN');
    if (firebaseStorageBucket.isEmpty) missing.add('FIREBASE_STORAGE_BUCKET');
    if (firebaseDatabaseUrl.isEmpty) missing.add('FIREBASE_DATABASE_URL');
    return missing;
  }
}
