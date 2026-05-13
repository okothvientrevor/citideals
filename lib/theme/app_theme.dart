import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Blue-first palette
  static const Color primary = Color(0xFF1A6BFF); // vivid blue
  static const Color primaryDark = Color(0xFF0F52E0); // deeper blue
  static const Color primaryLight = Color(
    0xFF4D90FF,
  ); // softer blue for dark mode
  static const Color accent = Color(0xFF00C6FF); // sky / cyan accent
  static const Color accentSoft = Color(0xFFB3E5FF);
  static const Color mint = Color(0xFF22D3A4); // success / winning (keep)
  static const Color amber = Color(0xFFFFB020); // featured badge (keep)
  static const Color coral = Color(0xFFFF6B5B); // live / error badge (keep)

  // ── Light surfaces (clean white + blue tints) ─────────────────────────────
  static const Color lightBg = Color(0xFFF4F7FF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightMuted = Color(0xFFEBF0FF);
  static const Color lightText = Color(0xFF0B1437);
  static const Color lightSubtle = Color(0xFF6478A3);

  // ── Dark surfaces (pure black + blue accents) ─────────────────────────────
  static const Color darkBg = Color(0xFF000000);
  static const Color darkCard = Color(0xFF0C0C0C);
  static const Color darkMuted = Color(0xFF1A1A1A);
  static const Color darkText = Color(0xFFF5F8FF);
  static const Color darkSubtle = Color(0xFF8298C8);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A6BFF), Color(0xFF00C6FF)],
  );

  static const LinearGradient mintGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF22D3A4), Color(0xFF3DDCDC)],
  );

  static const LinearGradient amberGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB020), Color(0xFFFF6B5B)],
  );

  static List<BoxShadow> softShadow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      BoxShadow(
        color: isDark
            ? Colors.black.withOpacity(0.4)
            : const Color(0xFF1A6BFF).withOpacity(0.10),
        blurRadius: 24,
        offset: const Offset(0, 8),
      ),
    ];
  }

  static TextTheme _textTheme(Color base, Color subtle) {
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.8,
        height: 1.1,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.5,
      ),
      displaySmall: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: base,
        letterSpacing: -0.3,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: base,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: base,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        color: base.withOpacity(0.85),
        height: 1.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: subtle,
        height: 1.45,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        color: subtle,
        letterSpacing: 0.2,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: base,
        letterSpacing: 0.3,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: base,
      ),
    );
  }

  static const _pageTransitions = PageTransitionsTheme(
    builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
    },
  );

  // ── Light Theme ───────────────────────────────────────────────────────────
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.light(
      primary: primary,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: mint,
      surface: lightCard,
      onSurface: lightText,
      surfaceContainerHighest: lightMuted,
      outline: Color(0xFFDDE6FF),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: lightText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: lightText),
    ),
    cardTheme: CardThemeData(
      color: lightCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightMuted,
      selectedColor: primary,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: lightText,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCard,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: lightSubtle,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: _textTheme(lightText, lightSubtle),
  );

  // ── Dark Theme ────────────────────────────────────────────────────────────
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: _pageTransitions,
    colorScheme: const ColorScheme.dark(
      primary: primaryLight,
      onPrimary: Colors.white,
      secondary: accent,
      onSecondary: Colors.white,
      tertiary: mint,
      surface: darkCard,
      onSurface: darkText,
      surfaceContainerHighest: darkMuted,
      outline: Color(0xFF242424),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.black,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: darkText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
      ),
      iconTheme: const IconThemeData(color: darkText),
    ),
    cardTheme: CardThemeData(
      color: darkCard,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkMuted,
      selectedColor: primaryLight,
      labelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w600,
        color: darkText,
      ),
      secondaryLabelStyle: GoogleFonts.plusJakartaSans(
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryLight,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        textStyle: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCard,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: darkSubtle,
        fontWeight: FontWeight.w500,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: primaryLight, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: BorderSide.none,
      ),
    ),
    textTheme: _textTheme(darkText, darkSubtle),
  );
}
