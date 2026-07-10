import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/firebase/firebase_options.dart';
import 'shared/services/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/main_shell.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('[FlutterError] ${details.exceptionAsString()}');
      debugPrint('${details.stack}');
    };

    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('[main] Flutter binding initialized');

    // ── Stripe Init ────────────────────────────────────────────────────────
    // Only initialize on mobile — Stripe SDK is not supported on web.
    if (!kIsWeb) {
      Stripe.publishableKey = AppConfig.stripePublishableKey;
      await Stripe.instance.applySettings();
      debugPrint('[Stripe] Initialized ✅');
    }

    // ── Firebase Init ──────────────────────────────────────────────────────
    // Android: google-services.json provides config — no dart-define needed.
    //          DefaultFirebaseOptions.android reads from the JSON at runtime.
    // Web:     Needs --dart-define flags. If missing, runs in demo mode.
    await _initFirebase();

    // Web: skip orientation lock (throws on web)
    try {
      SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ));
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } catch (_) {}

    debugPrint('[main] Launching TradeRepApp');
    runApp(const TradeRepApp());
  }, (error, stack) {
    debugPrint('[ZoneError] $error');
    debugPrint('$stack');
    runApp(_ErrorApp(error: '$error'));
  });
}

Future<void> _initFirebase() async {
  // Firebase config is embedded in firebase_options.dart.
  // firebase_core_web injects the JS SDK scripts automatically at runtime.
  try {
    debugPrint('[Firebase] Initializing...');

    // If already initialized (hot restart), just mark and return
    if (Firebase.apps.isNotEmpty) {
      AppConfig.markFirebaseInitialized();
      debugPrint('[Firebase] Already initialized ✅ (apps: ${Firebase.apps.length})');
      return;
    }

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () => throw TimeoutException('Firebase init timed out after 20s'),
    );
    AppConfig.markFirebaseInitialized();
    debugPrint('[Firebase] Initialized ✅ (apps: ${Firebase.apps.length})');
  } on TimeoutException catch (e) {
    AppConfig.firebaseInitError = 'Firebase timed out: $e';
    debugPrint('[Firebase] ⚠️ TIMEOUT: $e');
  } catch (e) {
    AppConfig.firebaseInitError = e.toString();
    debugPrint('[Firebase] ⚠️ ERROR: $e  (type: ${e.runtimeType})');
  }
}

// ─── Auth loading splash — shown for ~200 ms while Firebase restores session ──
/// Prevents the login screen flashing on web refresh when the user is already
/// authenticated. Firebase Auth restores sessions from localStorage, but the
/// first authStateChanges() event arrives asynchronously — this widget bridges
/// that gap with a matching dark background.
class _AuthLoadingSplash extends StatelessWidget {
  const _AuthLoadingSplash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0A1730), // matches AppTheme dark background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Error screen shown when a fatal zone error occurs ───────────────────────
class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0A1730),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Startup Error',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error.length > 400 ? '${error.substring(0, 400)}...' : error,
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Root app ─────────────────────────────────────────────────────────────────
class TradeRepApp extends StatelessWidget {
  const TradeRepApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: Consumer<AppState>(
        builder: (context, state, _) {
          return MaterialApp(
            title: 'TradeRep Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: state.themeMode,
            home: !state.authCheckComplete
                // Auth state not yet resolved — show a brief loading splash.
                // This prevents the login screen from flashing before Firebase
                // restores the session on web refresh.
                ? const _AuthLoadingSplash()
                : state.isLoggedIn
                    ? const MainShell()
                    : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
