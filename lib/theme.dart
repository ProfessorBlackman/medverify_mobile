import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryGreen = Color(0xFF13EC5B);
  static const Color secondGreen = Color(0xFF02A137);
  static const Color backgroundLight = Color(0xFFF6F8F6);
  static const Color backgroundDark = Color(0xFF102216);
  static const Color textLight = Color(0xFF111813);
  static const Color textDark = Color(0xFFECFDF3);
  static const Color secondaryText = Color(0xFF618983);
  static const Color secondaryBackground = Color(0x1A02A137);
  static const Color warningRed = Color(0xFFEF4444);
  static const Color warningOrange = Color(0xFFF59E0B); // Was expiredOrange
  static const Color recalledBlack = Color(0xFF000000); // Or dark grey
  static const Color logoColor = Color(0xFFD0F2ED); // Or dark grey
  static const Color logoColor2 = Color(0xFF26C2AD); // Or dark grey

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        surface: Colors.white,
        onPrimary: Colors.black, // Text on green should be dark
        onSurface: textLight,
        error: warningRed,
      ),
      textTheme: GoogleFonts.publicSansTextTheme().copyWith(
        displayLarge: GoogleFonts.publicSans(
          color: textLight,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.notoSans(
          color: textLight,
        ),
        bodyMedium: GoogleFonts.notoSans(
          color: textLight,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundLight,
        foregroundColor: textLight,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.publicSans(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: primaryGreen,
        surface: Color(0xFF1A2C20), // Slightly lighter than bg
        onPrimary: Colors.black,
        onSurface: textDark,
        error: warningRed,
      ),
      textTheme: GoogleFonts.publicSansTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.publicSans(
          color: textDark,
          fontWeight: FontWeight.bold,
        ),
        bodyLarge: GoogleFonts.notoSans(
          color: textDark,
        ),
        bodyMedium: GoogleFonts.notoSans(
          color: textDark,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundDark,
        foregroundColor: textDark,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.black,
          textStyle: GoogleFonts.publicSans(
            fontWeight: FontWeight.bold,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
