import 'package:flutter/material.dart';

class AppColors {
  // Primary
  static const primary = Color(0xFF1A237E); // Deep Blue
  static const primaryLight = Color(0xFF534BAE);
  static const primaryDark = Color(0xFF000051);

  // Accent
  static const accent = Color(0xFF00BCD4); // Cyan

  // Status Colors
  static const success = Color(0xFF4CAF50); // Green
  static const successLight = Color(0xFF81C784);
  static const warning = Color(0xFFFF9800); // Orange
  static const warningLight = Color(0xFFFFB74D);
  static const error = Color(0xFFF44336); // Red
  static const errorLight = Color(0xFFE57373);
  static const info = Color(0xFF2196F3); // Blue
  static const infoLight = Color(0xFF64B5F6);

  // Neutral
  static const white = Color(0xFFFFFFFF);
  static const black = Color(0xFF000000);
  static const grey50 = Color(0xFFFAFAFA);
  static const grey100 = Color(0xFFF5F5F5);
  static const grey200 = Color(0xFFEEEEEE);
  static const grey300 = Color(0xFFE0E0E0);
  static const grey400 = Color(0xFFBDBDBD);
  static const grey500 = Color(0xFF9E9E9E);
  static const grey600 = Color(0xFF757575);
  static const grey700 = Color(0xFF616161);
  static const grey800 = Color(0xFF424242);
  static const grey900 = Color(0xFF212121);

  // Backgrounds
  static const background = Color(0xFFF8F9FA);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1E1E1E);

  // Opacity helpers
  static Color withOpacity(Color color, double opacity) {
    return color.withOpacity(opacity);
  }
}
