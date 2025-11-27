import 'package:flutter/material.dart';

/// Design tokens for consistent spacing, sizing, and visual properties
class AppSpacing {
  AppSpacing._();

  // Base spacing unit: 4px
  static const double xxs = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
  static const double xxxl = 48.0;

  // Component-specific spacing
  static const double cardPadding = 12.0;
  static const double screenPadding = 16.0;
  static const double sectionSpacing = 24.0;
  static const double listItemSpacing = 12.0;
}

/// Border radius tokens
class AppRadius {
  AppRadius._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;

  // Component-specific radius
  static const double card = 12.0;
  static const double button = 8.0;
  static const double chip = 20.0;
  static const double input = 8.0;
  static const double bottomSheet = 20.0;
}

/// Elevation and shadow tokens
class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 16.0;
}

/// Shadow definitions for consistent elevation
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get none => [];

  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 2,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withOpacity(0.06),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 15,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withOpacity(0.10),
      blurRadius: 25,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 10,
      offset: const Offset(0, 4),
    ),
  ];

  // Colored shadows for cards
  static List<BoxShadow> cardShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.12),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: color.withOpacity(0.08),
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];
}

/// Animation duration tokens
class AppDuration {
  AppDuration._();

  static const Duration instant = Duration(milliseconds: 50);
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 600);
}

/// Animation curve tokens
class AppCurves {
  AppCurves._();

  static const Curve standard = Curves.easeInOut;
  static const Curve decelerate = Curves.easeOut;
  static const Curve accelerate = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
  static const Curve smooth = Curves.fastOutSlowIn;
}

/// Icon size tokens
class AppIconSize {
  AppIconSize._();

  static const double xs = 12.0;
  static const double sm = 16.0;
  static const double md = 20.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

/// Touch target sizes (minimum 44px for accessibility)
class AppTouchTarget {
  AppTouchTarget._();

  static const double minimum = 44.0;
  static const double standard = 48.0;
  static const double large = 56.0;
}
