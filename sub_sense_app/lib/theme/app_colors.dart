import 'package:flutter/material.dart';

class AppColors {
  // Core Ledger Palette
  static const Color ink = Color(0xFF0F1B2E);
  static const Color inkSoft = Color(0xFF1C2C44);
  static const Color paper = Color(0xFFFBFAF8);
  static const Color paperDim = Color(0xFFF2F0EA);
  static const Color line = Color(0xFFDEDAD0);
  static const Color slate = Color(0xFF5B6472);

  // Semantic Signals
  static const Color signalGreen = Color(0xFF1A7A5E);
  static const Color amber = Color(0xFFC4791F);
  static const Color coral = Color(0xFFC1443C);

  // Score-Based Palette Helper
  static Color getScoreColor(int score) {
    if (score >= 75) return signalGreen;
    if (score >= 50) return amber;
    return coral;
  }
}
