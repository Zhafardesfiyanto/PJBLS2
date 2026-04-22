import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static const Color cobaltBlue = Color(0xFF0047AB);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.white, Color(0xFFF5F7FA)],
  );

  static TextTheme get textTheme => GoogleFonts.plusJakartaSansTextTheme();

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: cobaltBlue,
          primary: cobaltBlue,
        ),
        textTheme: textTheme,
        primaryColor: cobaltBlue,
      );
}
