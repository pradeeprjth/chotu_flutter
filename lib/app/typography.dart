import 'package:flutter/material.dart';
import 'colors.dart';

/// Typography scale for the Chotu app
/// NOTE: Colors are NOT hardcoded in these styles to support dark mode.
/// Use Theme.of(context).textTheme for automatic dark mode support,
/// or wrap with AppTypography.adaptive() for theme-aware colors.
class AppTypography {
  AppTypography._();

  // Font Family - Using system fonts for now, can be replaced with Poppins
  static const String fontFamily = 'Roboto';

  // Display Styles (Large headlines for splash/marketing)
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    height: 1.12,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.16,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.22,
  );

  // Headline Styles (Section titles)
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.25,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.29,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.33,
  );

  // Title Styles (Card titles, list headers)
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.27,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.50,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  // Body Styles (Main content)
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.50,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label Styles (Buttons, chips, input labels)
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Custom Styles for Chotu App
  static const TextStyle productName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle productPrice = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.priceGreen,
  );

  static const TextStyle productOldPrice = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
    height: 1.2,
    color: AppColors.oldPrice,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle discountBadge = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    height: 1.2,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static const TextStyle categoryName = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle sectionTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    height: 1.3,
  );

  static const TextStyle appBarTitle = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: 0,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle cartItemName = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    height: 1.3,
  );

  static const TextStyle orderTotal = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    letterSpacing: 0,
    height: 1.2,
  );

  // Helper for secondary text color
  static TextStyle secondary(TextStyle style) {
    return style.copyWith(color: AppColors.textSecondary);
  }

  // Helper for custom color
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }
}

/// Light text theme for Material theme
TextTheme createTextTheme() {
  return TextTheme(
    displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
    displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
    displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
    headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
    headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
    headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textPrimary),
    titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
    titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
    titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textPrimary),
    bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
    bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
    bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
    labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textPrimary),
    labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textPrimary),
    labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
  );
}
