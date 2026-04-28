import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryDark = Color(0xFF5A4BD1);
  static const Color primaryLight = Color(0xFFA29BFE);
  static const Color accent = Color(0xFF00CEC9);
  static const Color accentDark = Color(0xFF00B5B0);

  static const Color background = Color(0xFF0A0A1A);
  static const Color surface = Color(0xFF1A1A2E);
  static const Color surfaceLight = Color(0xFF252540);
  static const Color card = Color(0xFF16213E);

  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0B0C0);
  static const Color textHint = Color(0xFF6C6C80);

  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFD600);
  static const Color danger = Color(0xFFFF5252);
  static const Color info = Color(0xFF448AFF);

  static const Color flowSlow = Color(0xFF00E676);
  static const Color flowMedium = Color(0xFFFFD600);
  static const Color flowFast = Color(0xFFFF5252);

  static const Color cosmic1 = Color(0xFF6C5CE7);
  static const Color cosmic2 = Color(0xFFA29BFE);
  static const Color cosmic3 = Color(0xFF00CEC9);
  static const Color cosmic4 = Color(0xFFFD79A8);

  static const Color starWhite = Color(0xFFFFFDE7);

  static LinearGradient get cosmicGradient => const LinearGradient(
        colors: [cosmic1, cosmic2, cosmic3],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  static LinearGradient get flowRateGradient => LinearGradient(
        colors: [flowSlow, flowMedium, flowFast],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      );

  static LinearGradient get cardGradient => const LinearGradient(
        colors: [surface, surfaceLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}
