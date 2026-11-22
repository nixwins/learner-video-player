import 'package:flutter/material.dart';

/// Single source of truth for the "cinema" look.
abstract final class AppColors {
  static const background = Color(0xFF0B0B0F);
  static const surface = Color(0xFF14141A);
  static const surfaceHigh = Color(0xFF1C1C25);
  static const accent = Color(0xFF8B7CF6);
  static const accentSoft = Color(0xFFC4B5FD);
  static const outline = Color(0x1FFFFFFF);
}

ThemeData buildAppTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: Brightness.dark,
    surface: AppColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.background,
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.outline),
      ),
      textStyle: const TextStyle(fontSize: 12, color: Colors.white),
      waitDuration: const Duration(milliseconds: 400),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surfaceHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
    ),
    sliderTheme: const SliderThemeData(
      trackHeight: 3,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
      overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
      activeTrackColor: AppColors.accent,
      inactiveTrackColor: Color(0x33FFFFFF),
      thumbColor: AppColors.accentSoft,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: Colors.white),
    ),
  );
}
