import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'colors.dart';
import 'typography.dart';
import 'design_tokens.dart';

/// Main theme configuration for the Chotu app
class AppTheme {
  AppTheme._();

  /// Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: _lightColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundLight,
      textTheme: createTextTheme(),
      appBarTheme: _lightAppBarTheme,
      cardTheme: _cardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonTheme,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationTheme,
      chipTheme: _chipTheme,
      bottomNavigationBarTheme: _bottomNavTheme,
      floatingActionButtonTheme: _fabTheme,
      dialogTheme: _dialogTheme,
      bottomSheetTheme: _bottomSheetTheme,
      snackBarTheme: _snackBarTheme,
      dividerTheme: _dividerTheme,
      listTileTheme: _listTileTheme,
      checkboxTheme: _checkboxTheme,
      switchTheme: _switchTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      tabBarTheme: _tabBarTheme,
    );
  }

  /// Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: _darkColorScheme,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      textTheme: _darkTextTheme,
      appBarTheme: _darkAppBarTheme,
      cardTheme: _darkCardTheme,
      elevatedButtonTheme: _elevatedButtonTheme,
      outlinedButtonTheme: _outlinedButtonThemeDark,
      textButtonTheme: _textButtonTheme,
      inputDecorationTheme: _inputDecorationThemeDark,
      chipTheme: _chipThemeDark,
      bottomNavigationBarTheme: _bottomNavThemeDark,
      floatingActionButtonTheme: _fabTheme,
      dialogTheme: _dialogThemeDark,
      bottomSheetTheme: _bottomSheetThemeDark,
      snackBarTheme: _snackBarThemeDark,
      dividerTheme: _dividerThemeDark,
      listTileTheme: _listTileThemeDark,
      checkboxTheme: _checkboxTheme,
      switchTheme: _switchTheme,
      progressIndicatorTheme: _progressIndicatorTheme,
      tabBarTheme: _tabBarThemeDark,
    );
  }

  // Color Schemes
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    primaryContainer: AppColors.primarySurface,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textOnSecondary,
    secondaryContainer: AppColors.secondarySurface,
    onSecondaryContainer: AppColors.secondaryDark,
    error: AppColors.error,
    onError: AppColors.textOnPrimary,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorDark,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimary,
    surfaceContainerHighest: AppColors.grey100,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderMedium,
    outlineVariant: AppColors.borderLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    error: AppColors.errorLight,
    onError: AppColors.errorDark,
    errorContainer: AppColors.errorDark,
    onErrorContainer: AppColors.errorLight,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textOnDark,
    surfaceContainerHighest: AppColors.grey800,
    onSurfaceVariant: AppColors.textOnDarkSecondary,
    outline: AppColors.grey600,
    outlineVariant: AppColors.grey700,
  );

  // AppBar Themes
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 2,
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: AppTypography.appBarTitle,
    iconTheme: IconThemeData(color: AppColors.textOnPrimary, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.textOnPrimary, size: 24),
  );

  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    centerTitle: false,
    elevation: 0,
    scrolledUnderElevation: 2,
    backgroundColor: AppColors.surfaceDark,
    foregroundColor: AppColors.textOnDark,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textOnDark,
    ),
    iconTheme: IconThemeData(color: AppColors.textOnDark, size: 24),
    actionsIconTheme: IconThemeData(color: AppColors.textOnDark, size: 24),
  );

  // Card Theme
  static final CardThemeData _cardTheme = CardThemeData(
    elevation: AppElevation.sm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    color: AppColors.surfaceLight,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
  );

  static final CardThemeData _darkCardTheme = CardThemeData(
    elevation: AppElevation.sm,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    ),
    color: AppColors.surfaceDark,
    surfaceTintColor: Colors.transparent,
    margin: EdgeInsets.zero,
  );

  // Button Themes
  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      disabledBackgroundColor: AppColors.grey300,
      disabledForegroundColor: AppColors.grey500,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      elevation: AppElevation.sm,
      textStyle: AppTypography.buttonText,
      minimumSize: const Size(88, AppTouchTarget.minimum),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.grey400,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: AppTypography.buttonText,
      minimumSize: const Size(88, AppTouchTarget.minimum),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonThemeDark = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      disabledForegroundColor: AppColors.grey600,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      side: const BorderSide(color: AppColors.primaryLight, width: 1.5),
      textStyle: AppTypography.buttonText,
      minimumSize: const Size(88, AppTouchTarget.minimum),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      disabledForegroundColor: AppColors.grey400,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      textStyle: AppTypography.buttonText,
      minimumSize: const Size(44, AppTouchTarget.minimum),
    ),
  );

  // Input Decoration Theme
  static final InputDecorationTheme _inputDecorationTheme = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceLight,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.borderMedium),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.borderLight),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.error),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    labelStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
    hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary),
    errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  );

  static final InputDecorationTheme _inputDecorationThemeDark = InputDecorationTheme(
    filled: true,
    fillColor: AppColors.grey800,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.md,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.grey600),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.grey700),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.primaryLight, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.errorLight),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.input),
      borderSide: const BorderSide(color: AppColors.errorLight, width: 2),
    ),
    labelStyle: const TextStyle(color: AppColors.textOnDarkSecondary),
    hintStyle: TextStyle(color: AppColors.textOnDarkSecondary.withOpacity(0.6)),
    errorStyle: const TextStyle(color: AppColors.errorLight, fontSize: 12),
    prefixIconColor: AppColors.textOnDarkSecondary,
    suffixIconColor: AppColors.textOnDarkSecondary,
  );

  // Chip Theme
  static final ChipThemeData _chipTheme = ChipThemeData(
    backgroundColor: AppColors.grey100,
    selectedColor: AppColors.primarySurface,
    disabledColor: AppColors.grey200,
    labelStyle: AppTypography.labelMedium,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
  );

  static final ChipThemeData _chipThemeDark = ChipThemeData(
    backgroundColor: AppColors.grey800,
    selectedColor: AppColors.primaryDark,
    disabledColor: AppColors.grey700,
    labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textOnDark),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.chip),
    ),
  );

  // Bottom Navigation Theme
  static const BottomNavigationBarThemeData _bottomNavTheme = BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.surfaceLight,
    selectedItemColor: AppColors.primary,
    unselectedItemColor: AppColors.textSecondary,
    elevation: 8,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  );

  static const BottomNavigationBarThemeData _bottomNavThemeDark = BottomNavigationBarThemeData(
    type: BottomNavigationBarType.fixed,
    backgroundColor: AppColors.surfaceDark,
    selectedItemColor: AppColors.primaryLight,
    unselectedItemColor: AppColors.textOnDarkSecondary,
    elevation: 8,
    showSelectedLabels: true,
    showUnselectedLabels: true,
    selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
  );

  // FAB Theme
  static const FloatingActionButtonThemeData _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    elevation: 4,
    shape: CircleBorder(),
  );

  // Dialog Theme
  static final DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.surfaceLight,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    titleTextStyle: AppTypography.titleLarge,
    contentTextStyle: AppTypography.bodyMedium,
  );

  static final DialogThemeData _dialogThemeDark = DialogThemeData(
    backgroundColor: AppColors.surfaceDark,
    elevation: 8,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
    titleTextStyle: AppTypography.titleLarge.copyWith(color: AppColors.textOnDark),
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textOnDark),
  );

  // Bottom Sheet Theme
  static final BottomSheetThemeData _bottomSheetTheme = BottomSheetThemeData(
    backgroundColor: AppColors.surfaceLight,
    elevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    dragHandleColor: AppColors.grey400,
    dragHandleSize: const Size(32, 4),
  );

  static final BottomSheetThemeData _bottomSheetThemeDark = BottomSheetThemeData(
    backgroundColor: AppColors.surfaceDark,
    elevation: 8,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppRadius.bottomSheet),
      ),
    ),
    dragHandleColor: AppColors.grey600,
    dragHandleSize: const Size(32, 4),
  );

  // SnackBar Theme
  static final SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    backgroundColor: AppColors.grey800,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textOnDark),
    actionTextColor: AppColors.primaryLight,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );

  static final SnackBarThemeData _snackBarThemeDark = SnackBarThemeData(
    backgroundColor: AppColors.grey200,
    contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
    actionTextColor: AppColors.primary,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.sm),
    ),
  );

  // Divider Theme
  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.borderLight,
    thickness: 1,
    space: 0,
  );

  static const DividerThemeData _dividerThemeDark = DividerThemeData(
    color: AppColors.borderDark,
    thickness: 1,
    space: 0,
  );

  // ListTile Theme
  static const ListTileThemeData _listTileTheme = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    minVerticalPadding: AppSpacing.md,
    iconColor: AppColors.textSecondary,
    textColor: AppColors.textPrimary,
    dense: false,
  );

  static const ListTileThemeData _listTileThemeDark = ListTileThemeData(
    contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
    minVerticalPadding: AppSpacing.md,
    iconColor: AppColors.textOnDarkSecondary,
    textColor: AppColors.textOnDark,
    dense: false,
  );

  // Checkbox Theme
  static final CheckboxThemeData _checkboxTheme = CheckboxThemeData(
    fillColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return Colors.transparent;
    }),
    checkColor: WidgetStateProperty.all(AppColors.textOnPrimary),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(4),
    ),
  );

  // Switch Theme
  static final SwitchThemeData _switchTheme = SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary;
      }
      return AppColors.grey400;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primaryLight;
      }
      return AppColors.grey300;
    }),
  );

  // Progress Indicator Theme
  static const ProgressIndicatorThemeData _progressIndicatorTheme = ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearTrackColor: AppColors.grey200,
    circularTrackColor: AppColors.grey200,
  );

  // Tab Bar Theme
  static const TabBarThemeData _tabBarTheme = TabBarThemeData(
    labelColor: AppColors.primary,
    unselectedLabelColor: AppColors.textSecondary,
    indicatorColor: AppColors.primary,
    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  );

  static const TabBarThemeData _tabBarThemeDark = TabBarThemeData(
    labelColor: AppColors.primaryLight,
    unselectedLabelColor: AppColors.textOnDarkSecondary,
    indicatorColor: AppColors.primaryLight,
    labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    unselectedLabelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
  );

  // Dark text theme
  static TextTheme get _darkTextTheme {
    return TextTheme(
      displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textOnDark),
      displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textOnDark),
      displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textOnDark),
      headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textOnDark),
      headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textOnDark),
      headlineSmall: AppTypography.headlineSmall.copyWith(color: AppColors.textOnDark),
      titleLarge: AppTypography.titleLarge.copyWith(color: AppColors.textOnDark),
      titleMedium: AppTypography.titleMedium.copyWith(color: AppColors.textOnDark),
      titleSmall: AppTypography.titleSmall.copyWith(color: AppColors.textOnDark),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textOnDark),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textOnDark),
      bodySmall: AppTypography.bodySmall.copyWith(color: AppColors.textOnDarkSecondary),
      labelLarge: AppTypography.labelLarge.copyWith(color: AppColors.textOnDark),
      labelMedium: AppTypography.labelMedium.copyWith(color: AppColors.textOnDark),
      labelSmall: AppTypography.labelSmall.copyWith(color: AppColors.textOnDarkSecondary),
    );
  }

  // Legacy color accessors for backward compatibility
  static const Color primaryGreen = AppColors.primary;
  static const Color secondaryOrange = AppColors.secondary;
  static const Color errorRed = AppColors.error;
  static const Color successGreen = AppColors.success;
  static const Color warningYellow = AppColors.warning;
  static const Color infoBlue = AppColors.info;
}
