import 'package:flutter/material.dart';

/// Comprehensive color palette for the Chotu app
class AppColors {
  AppColors._();

  // Primary Colors - Green (Brand Color)
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryLight = Color(0xFF81C784);
  static const Color primaryDark = Color(0xFF388E3C);
  static const Color primarySurface = Color(0xFFE8F5E9);

  // Secondary Colors - Orange (Accent)
  static const Color secondary = Color(0xFFFF9800);
  static const Color secondaryLight = Color(0xFFFFB74D);
  static const Color secondaryDark = Color(0xFFF57C00);
  static const Color secondarySurface = Color(0xFFFFF3E0);

  // Semantic Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color successLight = Color(0xFFC8E6C9);
  static const Color successDark = Color(0xFF2E7D32);

  static const Color warning = Color(0xFFFFC107);
  static const Color warningLight = Color(0xFFFFF8E1);
  static const Color warningDark = Color(0xFFFFA000);

  static const Color error = Color(0xFFD32F2F);
  static const Color errorLight = Color(0xFFFFEBEE);
  static const Color errorDark = Color(0xFFB71C1C);

  static const Color info = Color(0xFF2196F3);
  static const Color infoLight = Color(0xFFE3F2FD);
  static const Color infoDark = Color(0xFF1565C0);

  // Neutral Colors (Light Theme)
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // Background Colors
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // Text Colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnSecondary = Color(0xFF000000);
  static const Color textOnDark = Color(0xFFFFFFFF);
  static const Color textOnDarkSecondary = Color(0xB3FFFFFF); // 70% opacity

  // Border Colors
  static const Color borderLight = Color(0xFFE0E0E0);
  static const Color borderMedium = Color(0xFFBDBDBD);
  static const Color borderDark = Color(0xFF424242);

  // Special Colors
  static const Color discount = Color(0xFFD32F2F);
  static const Color priceGreen = Color(0xFF2E7D32);
  static const Color oldPrice = Color(0xFF9E9E9E);
  static const Color badge = Color(0xFFFF9800);
  static const Color cartBadge = Color(0xFFFF5722);

  // Overlay Colors
  static const Color overlay = Color(0x80000000); // 50% black
  static const Color overlayLight = Color(0x40000000); // 25% black
  static const Color scrim = Color(0x52000000); // 32% black

  // Shimmer Colors (for skeleton loading)
  static const Color shimmerBase = Color(0xFFE0E0E0);
  static const Color shimmerHighlight = Color(0xFFF5F5F5);
  static const Color shimmerBaseDark = Color(0xFF424242);
  static const Color shimmerHighlightDark = Color(0xFF616161);

  // Gradient Colors
  static const List<Color> primaryGradient = [
    Color(0xFF4CAF50),
    Color(0xFF81C784),
  ];

  static const List<Color> secondaryGradient = [
    Color(0xFFFF9800),
    Color(0xFFFFB74D),
  ];

  static const List<Color> cardGradient = [
    Color(0xFFFFFFFF),
    Color(0xFFFAFAFA),
  ];

  // Status Colors for Orders
  static const Color orderCreated = Color(0xFF9E9E9E);
  static const Color orderConfirmed = Color(0xFF2196F3);
  static const Color orderPacking = Color(0xFFFF9800);
  static const Color orderOutForDelivery = Color(0xFF9C27B0);
  static const Color orderDelivered = Color(0xFF4CAF50);
  static const Color orderCancelled = Color(0xFFD32F2F);

  // Stock Status Colors
  static const Color inStock = Color(0xFF4CAF50);
  static const Color lowStock = Color(0xFFFF9800);
  static const Color outOfStock = Color(0xFFD32F2F);
}

/// Color scheme extensions for dark mode
extension AppColorScheme on ColorScheme {
  Color get shimmerBase => brightness == Brightness.dark
      ? AppColors.shimmerBaseDark
      : AppColors.shimmerBase;

  Color get shimmerHighlight => brightness == Brightness.dark
      ? AppColors.shimmerHighlightDark
      : AppColors.shimmerHighlight;

  Color get cardBackground => brightness == Brightness.dark
      ? AppColors.surfaceDark
      : AppColors.surfaceLight;

  Color get dividerColor => brightness == Brightness.dark
      ? AppColors.borderDark
      : AppColors.borderLight;
}

/// Extension on BuildContext for easy access to theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  /// Primary text color (adapts to dark mode)
  Color get textPrimary => isDarkMode ? AppColors.textOnDark : AppColors.textPrimary;

  /// Secondary text color (adapts to dark mode)
  Color get textSecondary => isDarkMode ? AppColors.textOnDarkSecondary : AppColors.textSecondary;

  /// Tertiary text color (adapts to dark mode)
  Color get textTertiary => isDarkMode ? AppColors.grey500 : AppColors.textTertiary;

  /// Surface color for containers (adapts to dark mode)
  Color get surfaceColor => isDarkMode ? AppColors.surfaceDark : AppColors.surfaceLight;

  /// Subtle background for items (adapts to dark mode)
  Color get subtleSurface => isDarkMode ? AppColors.grey800 : AppColors.grey100;

  /// Border color (adapts to dark mode)
  Color get borderColor => isDarkMode ? AppColors.borderDark : AppColors.borderLight;
}
