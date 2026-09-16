import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // iOS System Colors
  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color red = Color(0xFFFF3B30);
  static const Color orange = Color(0xFFFF9500);
  static const Color yellow = Color(0xFFFFCC00);
  static const Color purple = Color(0xFFAF52DE);
  static const Color pink = Color(0xFFFF2D55);
  static const Color teal = Color(0xFF5AC8FA);

  // iOS System Grays
  static const Color gray1 = Color(0xFF8E8E93);
  static const Color gray2 = Color(0xFFAEAEB2);
  static const Color gray3 = Color(0xFFC7C7CC);
  static const Color gray4 = Color(0xFFD1D1D6);
  static const Color gray5 = Color(0xFFE5E5EA);
  static const Color gray6 = Color(0xFFF2F2F7);

  // Semantic
  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0xFF3C3C43);
  static const Color tertiaryLabel = Color(0xFF48484A);
  static const Color systemBackground = Color(0xFFF2F2F7);
  static const Color secondarySystemBackground = Color(0xFFE5E5EA);
  static const Color tertiarySystemBackground = Color(0xFFFFFFFF);
  static const Color separator = Color(0xFFC6C6C8);
  static const Color opaqueSeparator = Color(0xFF38383A);

  // Table states
  static const Color tableActive = Color(0xFF007AFF);
  static const Color tableFree = Color(0xFFE5E5EA);
}

class AppTheme {
  static const Color primary = AppColors.blue;
  static const Color primaryLight = AppColors.blue;
  static const Color primaryDark = Color(0xFF0051D5);
  static const Color accent = AppColors.orange;
  static const Color surface = AppColors.systemBackground;
  static const Color card = AppColors.tertiarySystemBackground;
  static const Color textPrimary = AppColors.label;
  static const Color textSecondary = AppColors.secondaryLabel;
  static const Color divider = AppColors.separator;
  static const Color success = AppColors.green;
  static const Color warning = AppColors.orange;
  static const Color error = AppColors.red;

  static ThemeData get lightTheme {
    final textTheme = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.blue,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFD6E4FF),
        onPrimaryContainer: Color(0xFF001A41),
        secondary: AppColors.green,
        onSecondary: Colors.white,
        secondaryContainer: Color(0xFFB8F0C8),
        onSecondaryContainer: Color(0xFF002109),
        tertiary: AppColors.orange,
        onTertiary: Colors.white,
        tertiaryContainer: Color(0xFFFFDDB3),
        onTertiaryContainer: Color(0xFF261900),
        error: AppColors.red,
        onError: Colors.white,
        errorContainer: Color(0xFFFFDAD6),
        onErrorContainer: Color(0xFF410002),
        surface: AppColors.systemBackground,
        onSurface: AppColors.label,
        onSurfaceVariant: AppColors.secondaryLabel,
        outline: AppColors.separator,
        outlineVariant: AppColors.gray5,
        shadow: Color(0x1A000000),
        inverseSurface: Color(0xFF2C2C2E),
        onInverseSurface: Color(0xFFF2F2F7),
      ),
      scaffoldBackgroundColor: AppColors.systemBackground,
      textTheme: textTheme.copyWith(
        displayLarge: textTheme.displayLarge?.copyWith(color: AppColors.label, fontWeight: FontWeight.w700),
        displayMedium: textTheme.displayMedium?.copyWith(color: AppColors.label, fontWeight: FontWeight.w700),
        displaySmall: textTheme.displaySmall?.copyWith(color: AppColors.label, fontWeight: FontWeight.w600),
        headlineLarge: textTheme.headlineLarge?.copyWith(color: AppColors.label, fontWeight: FontWeight.w700),
        headlineMedium: textTheme.headlineMedium?.copyWith(color: AppColors.label, fontWeight: FontWeight.w600),
        headlineSmall: textTheme.headlineSmall?.copyWith(color: AppColors.label, fontWeight: FontWeight.w600),
        titleLarge: textTheme.titleLarge?.copyWith(color: AppColors.label, fontWeight: FontWeight.w600),
        titleMedium: textTheme.titleMedium?.copyWith(color: AppColors.label, fontWeight: FontWeight.w500),
        titleSmall: textTheme.titleSmall?.copyWith(color: AppColors.label, fontWeight: FontWeight.w500),
        bodyLarge: textTheme.bodyLarge?.copyWith(color: AppColors.label, height: 1.5),
        bodyMedium: textTheme.bodyMedium?.copyWith(color: AppColors.secondaryLabel, height: 1.4),
        bodySmall: textTheme.bodySmall?.copyWith(color: AppColors.tertiaryLabel, height: 1.3),
        labelLarge: textTheme.labelLarge?.copyWith(color: AppColors.blue, fontWeight: FontWeight.w600),
        labelMedium: textTheme.labelMedium?.copyWith(color: AppColors.secondaryLabel, fontWeight: FontWeight.w500),
        labelSmall: textTheme.labelSmall?.copyWith(color: AppColors.tertiaryLabel, fontWeight: FontWeight.w500),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.systemBackground.withValues(alpha: 0.8),
        foregroundColor: AppColors.label,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.label,
        ),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        color: AppColors.tertiarySystemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(14)),
          side: BorderSide(color: AppColors.separator, width: 0.5),
        ),
        margin: EdgeInsets.zero,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.blue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue,
          backgroundColor: Colors.white,
          elevation: 0,
          side: const BorderSide(color: AppColors.separator, width: 0.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.tertiarySystemBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(color: AppColors.gray2, fontSize: 16),
        labelStyle: GoogleFonts.inter(color: AppColors.secondaryLabel, fontSize: 16),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.white,
        selectedColor: AppColors.blue,
        labelStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.separator, width: 0.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.label,
        contentTextStyle: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.tertiarySystemBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titleTextStyle: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.label),
        contentTextStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.secondaryLabel),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.tertiarySystemBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final textTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF000000),
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.inter(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
