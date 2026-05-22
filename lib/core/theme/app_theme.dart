import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// ─── TradeRep Brand Colors ───────────────────────────────────────────────────
class TRColors {
  // Primary Navy
  static const Color navyDeep   = Color(0xFF0A1730);
  static const Color navyDark   = Color(0xFF0E2446);
  static const Color navyMid    = Color(0xFF132B55);
  static const Color navyLight  = Color(0xFF1A3A6E);

  // Gold Accent
  static const Color gold       = Color(0xFFF7BE1A);
  static const Color goldLight  = Color(0xFFF5C93A);
  static const Color goldDark   = Color(0xFFE2A800);
  static const Color goldDim    = Color(0x26F7BE1A);  // 15% opacity

  // Neutrals
  static const Color white      = Color(0xFFF2F5F8);
  static const Color offWhite   = Color(0xFFEEF2F6);
  static const Color grayLight  = Color(0xFFB7BCC6);
  static const Color grayMid    = Color(0xFF6B7280);
  static const Color grayDark   = Color(0xFF374151);

  // Semantic
  static const Color success    = Color(0xFF22C55E);
  static const Color warning    = Color(0xFFF59E0B);
  static const Color error      = Color(0xFFEF4444);
  static const Color info       = Color(0xFF3B82F6);

  // Status Colors
  static const Color statusLead       = Color(0xFF8B5CF6);
  static const Color statusScheduled  = Color(0xFF3B82F6);
  static const Color statusInProgress = Color(0xFFF59E0B);
  static const Color statusAwaiting   = Color(0xFFEC4899);
  static const Color statusCompleted  = Color(0xFF22C55E);

  // Card / Surface
  static const Color cardDark   = Color(0xFF0F2040);
  static const Color cardMid    = Color(0xFF162A4E);
  static const Color surfaceDim = Color(0xFF0D1B35);
  static const Color divider    = Color(0xFF1E3059);
}

// ─── App Theme ───────────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: TRColors.navyDeep,
      primaryColor: TRColors.gold,
      colorScheme: const ColorScheme.dark(
        primary: TRColors.gold,
        secondary: TRColors.goldLight,
        surface: TRColors.cardDark,
        error: TRColors.error,
        onPrimary: TRColors.navyDeep,
        onSecondary: TRColors.navyDeep,
        onSurface: TRColors.white,
        onError: TRColors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: TRColors.navyDeep,
        foregroundColor: TRColors.white,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        titleTextStyle: TextStyle(
          color: TRColors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: TRColors.cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: TRColors.divider, width: 1),
        ),
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TRColors.gold,
          foregroundColor: TRColors.navyDeep,
          elevation: 0,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: TRColors.gold,
          side: const BorderSide(color: TRColors.gold, width: 1.5),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: TRColors.gold,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: TRColors.cardMid,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
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
        labelStyle: const TextStyle(color: TRColors.grayLight, fontSize: 14),
        hintStyle: const TextStyle(color: TRColors.grayMid, fontSize: 14),
        prefixIconColor: TRColors.grayLight,
        suffixIconColor: TRColors.grayLight,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: TRColors.cardDark,
        selectedItemColor: TRColors.gold,
        unselectedItemColor: TRColors.grayMid,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      dividerTheme: const DividerThemeData(
        color: TRColors.divider,
        thickness: 1,
        space: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: TRColors.cardMid,
        selectedColor: TRColors.goldDim,
        labelStyle: const TextStyle(color: TRColors.white, fontSize: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        side: const BorderSide(color: TRColors.divider),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: TRColors.white, fontSize: 32, fontWeight: FontWeight.w800),
        displayMedium: TextStyle(color: TRColors.white, fontSize: 26, fontWeight: FontWeight.w700),
        displaySmall: TextStyle(color: TRColors.white, fontSize: 22, fontWeight: FontWeight.w700),
        headlineLarge: TextStyle(color: TRColors.white, fontSize: 20, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(color: TRColors.white, fontSize: 18, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: TRColors.white, fontSize: 16, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(color: TRColors.white, fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: TRColors.white, fontSize: 15, fontWeight: FontWeight.w400),
        bodyMedium: TextStyle(color: TRColors.grayLight, fontSize: 14, fontWeight: FontWeight.w400),
        bodySmall: TextStyle(color: TRColors.grayMid, fontSize: 12, fontWeight: FontWeight.w400),
        labelLarge: TextStyle(color: TRColors.navyDeep, fontSize: 15, fontWeight: FontWeight.w700),
        labelMedium: TextStyle(color: TRColors.grayLight, fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(color: TRColors.grayMid, fontSize: 11, fontWeight: FontWeight.w400),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6FB),
      primaryColor: TRColors.navyDeep,
      colorScheme: const ColorScheme.light(
        primary: TRColors.navyDeep,
        secondary: TRColors.gold,
        surface: Colors.white,
        error: TRColors.error,
        onPrimary: Colors.white,
        onSecondary: TRColors.navyDeep,
        onSurface: TRColors.navyDeep,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: TRColors.navyDeep,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: TRColors.navyDeep,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: TRColors.navyDeep,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// ─── Status Helper ────────────────────────────────────────────────────────────
class JobStatusTheme {
  static Color color(String status) {
    switch (status.toLowerCase()) {
      case 'lead':         return TRColors.statusLead;
      case 'scheduled':   return TRColors.statusScheduled;
      case 'in progress': return TRColors.statusInProgress;
      case 'awaiting approval': return TRColors.statusAwaiting;
      case 'completed':   return TRColors.statusCompleted;
      default:            return TRColors.grayMid;
    }
  }

  static IconData icon(String status) {
    switch (status.toLowerCase()) {
      case 'lead':         return Icons.star_outline_rounded;
      case 'scheduled':   return Icons.calendar_today_rounded;
      case 'in progress': return Icons.construction_rounded;
      case 'awaiting approval': return Icons.pending_actions_rounded;
      case 'completed':   return Icons.check_circle_outline_rounded;
      default:            return Icons.help_outline_rounded;
    }
  }
}
