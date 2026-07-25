import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTypography {
  // Display / Headings (Fraunces serif)
  static TextStyle headlineLarge({Color color = AppColors.ink}) =>
      GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.2,
      );

  static TextStyle headlineMedium({Color color = AppColors.ink}) =>
      GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static TextStyle titleLarge({Color color = AppColors.ink}) =>
      GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color,
      );

  // Body / UI (Inter)
  static TextStyle bodyLarge({Color color = AppColors.ink}) =>
      GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodyMedium({Color color = AppColors.ink}) =>
      GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle bodySmall({Color color = AppColors.slate}) =>
      GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );

  static TextStyle labelBold({Color color = AppColors.ink}) =>
      GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle eyebrow({Color color = AppColors.signalGreen}) =>
      GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: color,
      );

  // Data / Money / Numbers (IBM Plex Mono)
  static TextStyle monoLarge({Color color = AppColors.ink}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle monoMedium({Color color = AppColors.ink}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      );

  static TextStyle monoRegular({Color color = AppColors.ink}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle monoSmall({Color color = AppColors.slate}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: color,
      );
}
