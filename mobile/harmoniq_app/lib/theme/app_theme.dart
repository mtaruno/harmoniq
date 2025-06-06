import 'package:flutter/material.dart';

class AppTheme {
  // Cute pastel color palette
  static const Color primaryPink = Color(0xFFFFB6C1);
  static const Color primaryBlue = Color(0xFFADD8E6);
  static const Color primaryPurple = Color(0xFFDDA0DD);
  static const Color primaryPeach = Color(0xFFFFDAB9);
  static const Color primaryMint = Color(0xFF98FB98);
  static const Color primaryLavender = Color(0xFFE6E6FA);
  
  // Chord type colors
  static const Color majorChordColor = Color(0xFFFFB6C1); // Soft pink
  static const Color minorChordColor = Color(0xFFADD8E6); // Light blue
  static const Color seventhChordColor = Color(0xFFDDA0DD); // Plum
  static const Color diminishedChordColor = Color(0xFFFFDAB9); // Peach
  static const Color unknownChordColor = Color(0xFFD3D3D3); // Light gray
  
  // Confidence level colors
  static const Color highConfidenceColor = Color(0xFF90EE90); // Light green
  static const Color mediumConfidenceColor = Color(0xFFFFE4B5); // Moccasin
  static const Color lowConfidenceColor = Color(0xFFFFB6C1); // Light pink
  
  // Background colors
  static const Color lightBackground = Color(0xFFFFFAF0); // Floral white
  static const Color darkBackground = Color(0xFF2C2C2C);
  
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPink,
        brightness: Brightness.light,
        background: lightBackground,
      ),
      fontFamily: 'Poppins',
      
      // AppBar theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      
      // Card theme
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: Colors.white,
      ),
      
      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Floating action button theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: CircleBorder(),
      ),
      
      // Slider theme
      sliderTheme: SliderThemeData(
        activeTrackColor: primaryPink,
        inactiveTrackColor: primaryPink.withOpacity(0.3),
        thumbColor: primaryPink,
        overlayColor: primaryPink.withOpacity(0.2),
        valueIndicatorColor: primaryPink,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // Text theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        displayMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        displaySmall: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        labelLarge: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryPink,
        brightness: Brightness.dark,
        background: darkBackground,
      ),
      fontFamily: 'Poppins',
      
      // Similar structure but with dark colors
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFF3C3C3C),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryPink,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Helper method to get chord color based on chord type
  static Color getChordColor(String chord) {
    if (chord.contains('dim')) {
      return diminishedChordColor;
    } else if (chord.contains('7')) {
      return seventhChordColor;
    } else if (chord.contains('m') && !chord.contains('maj')) {
      return minorChordColor;
    } else if (chord != 'Unknown') {
      return majorChordColor;
    } else {
      return unknownChordColor;
    }
  }

  // Helper method to get confidence color
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return highConfidenceColor;
    } else if (confidence >= 0.65) {
      return mediumConfidenceColor;
    } else {
      return lowConfidenceColor;
    }
  }
}
