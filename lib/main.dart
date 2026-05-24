import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/theme/app_theme.dart';
import 'core/config/app_config.dart';
import 'core/firebase/firebase_options.dart';
import 'shared/services/app_state.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/auth/main_shell.dart';

// Global error capture for web preview debugging
String? _startupError;

Future<void> main() async {
  await runZonedGuarded(() async {
    // Catch all Flutter framework errors and show on screen
    FlutterError.onError = (FlutterErrorDetails details) {
      debugPrint('=== FLUTTER ERROR ===');
      debugPrint(details.exceptionAsString());
      debugPrint(details.stack.toString());
      _startupError = '${details.exceptionAsString()}\n\n${details.stack}';
    };

    WidgetsFlutterBinding.ensureInitialized();

    // ── Firebase Init ────────────────────────────────────────────────────────
    // Only initialise when real credentials are present (injected via
    // --dart-define at build time). Without them the app runs on local
    // sample data — safe for web previews and demos.
    if (AppConfig.isFirebaseConfigured) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      } catch (e) {
        debugPrint('Firebase init error: $e');
      }
    } else {
      debugPrint('Firebase not configured — running on sample data.');
    }

    // Web: skip orientation lock (not supported on web)
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

    runApp(const TradeRepApp());
  }, (error, stack) {
    // Catch all zone errors (unhandled async exceptions)
    debugPrint('=== ZONE ERROR ===');
    debugPrint('$error');
    debugPrint('$stack');
    _startupError = '$error\n\n$stack';
    // Show error app
    runApp(_ErrorApp(error: '$error'));
  });
}

// Shown when an unrecoverable startup error occurs
class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1a1a2e),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'App Error',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade900.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    error,
                    style: const TextStyle(color: Colors.redAccent, fontSize: 11, fontFamily: 'monospace'),
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
