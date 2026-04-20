import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_constants.dart';

class AppTypography {
  // 1. Inter - The UI Queen
  // Best for: Buttons, Menus, AppBars, Short UI feedback
  static TextStyle ui({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // 2. Nunito - The Friendly EdTech Companion
  // Best for: Greetings, AI tips, Teacher notes, Explanations, Learning content
  static TextStyle friendly({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.nunito(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      fontStyle: fontStyle,
    );
  }

  // 3. Lora - The Reading Specialist (Serif)
  // Best for: Long reading passages (Part 6 & 7), Analysis narratives
  static TextStyle reading({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.normal,
    Color color = AppColors.textPrimary,
    double? height = 1.6,
    FontStyle? fontStyle,
  }) {
    return GoogleFonts.lora(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
      fontStyle: fontStyle,
    );
  }

  // Helper for Section Headers (UI)
  static TextStyle header({
    double fontSize = 16,
    FontWeight fontWeight = FontWeight.bold,
    Color color = AppColors.textPrimary,
  }) => ui(fontSize: fontSize, fontWeight: fontWeight, color: color);
}
