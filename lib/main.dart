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

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Firebase Init ──────────────────────────────────────────────────────────
  // Only initialise when real credentials are present (injected via
  // --dart-define at build time).  Without them the app runs on local
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

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const TradeRepApp());
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
