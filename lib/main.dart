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
  // Firebase config is now embedded in firebase_options.dart for all platforms.
  // Always attempt initialization — no --dart-define flags needed.
  try {
    debugPrint('[Firebase] Initializing...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => throw TimeoutException('Firebase init timed out'),
    );
    AppConfig.markFirebaseInitialized();
    debugPrint('[Firebase] Initialized ✅ (apps: ${Firebase.apps.length})');
  } on TimeoutException catch (e) {
    debugPrint('[Firebase] ⚠️ Init TIMEOUT: $e');
  } catch (e) {
    debugPrint('[Firebase] ⚠️ Init ERROR: $e');
    debugPrint('[Firebase] ⚠️ Error type: ${e.runtimeType}');
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
            home: state.isLoggedIn
                ? const MainShell()
                : const OnboardingScreen(),
          );
        },
      ),
    );
  }
}
