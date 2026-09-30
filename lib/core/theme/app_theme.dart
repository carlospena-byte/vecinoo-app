import 'package:flutter/material.dart';

class GatesColors {
  GatesColors._();

  static const bgBrand = Color(0xFF344F40);
  static const bgPressed = Color(0xFF243B2D);
  static const bgAccent = Color(0xFFDDE8D6);
  static const bgSurface = Color(0xFFFFFFFF);
  static const bgSubtle = Color(0xFFEEF2EB);
  static const bgCanvas = Color(0xFFF7F8F4);
  static const bgWarm = Color(0xFFF8E4AF);
  static const bgLilac = Color(0xFFE8E3F3);
  static const accentCoral = Color(0xFFE07A5F);
  static const borderDefault = Color(0xFFDCE2DA);
  static const borderFocus = Color(0xFF344F40);
  static const statusError = Color(0xFFB04439);
  static const statusErrorBg = Color(0xFFFBECE8);
  static const statusWarningBg = Color(0xFFFFF3D6);
  static const statusWarning = Color(0xFF795B18);
  static const statusSuccessBg = Color(0xFFE6F1E5);
  static const statusSuccess = Color(0xFF39704A);
  static const textInverse = Color(0xFFFFFFFF);
  static const textBrand = Color(0xFF344F40);
  static const textPrimary = Color(0xFF252D29);
  static const textSecondary = Color(0xFF68726B);
}

class GatesSpacing {
  GatesSpacing._();

  static const space4 = 4.0;
  static const space8 = 8.0;
  static const space12 = 12.0;
  static const space16 = 16.0;
  static const space24 = 24.0;
}

class GatesRadius {
  GatesRadius._();

  static const radius8 = 8.0;
  static const radius16 = 16.0;
  static const radius24 = 24.0;
  static const radiusFull = 999.0;
}

class GatesTypography {
  GatesTypography._();

  static const _fontFamily = 'Manrope';

  static const TextStyle headingLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.4,
    color: GatesColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.2,
    color: GatesColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.1,
    color: GatesColors.textPrimary,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
    color: GatesColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
    color: GatesColors.textPrimary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 0.1,
    color: GatesColors.textSecondary,
  );

  /// [label] (14px) at regular weight and secondary color — helper copy under
  /// a heading (schedule times, payment methods...) that needs the 14px size
  /// but shouldn't read as a form label.
  static final TextStyle labelSecondary = label.copyWith(
    fontWeight: FontWeight.w400,
    color: GatesColors.textSecondary,
  );
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(Color onSurface) {
    return TextTheme(
      displayLarge: GatesTypography.headingLarge.copyWith(color: onSurface),
      displayMedium: GatesTypography.headingLarge.copyWith(color: onSurface),
      displaySmall: GatesTypography.headingLarge.copyWith(color: onSurface),
      headlineLarge: GatesTypography.headingMedium.copyWith(color: onSurface),
      headlineMedium: GatesTypography.headingMedium.copyWith(color: onSurface),
      headlineSmall: GatesTypography.headingSmall.copyWith(color: onSurface),
      titleLarge: GatesTypography.headingSmall.copyWith(color: onSurface),
      titleMedium: GatesTypography.label.copyWith(color: onSurface),
      titleSmall: GatesTypography.label.copyWith(color: onSurface),
      bodyLarge: GatesTypography.body.copyWith(color: onSurface),
      bodyMedium: GatesTypography.body.copyWith(color: onSurface),
      bodySmall: GatesTypography.caption,
      labelLarge: GatesTypography.label.copyWith(color: onSurface),
      labelMedium: GatesTypography.label.copyWith(color: onSurface),
      labelSmall: GatesTypography.caption,
    );
  }

  static ThemeData light() {
    const scheme = ColorScheme.light(
      primary: GatesColors.bgBrand,
      onPrimary: GatesColors.textInverse,
      secondary: GatesColors.bgAccent,
      onSecondary: GatesColors.textBrand,
      error: GatesColors.statusError,
      onError: GatesColors.textInverse,
      surface: GatesColors.bgSurface,
      onSurface: GatesColors.textPrimary,
      outline: GatesColors.borderDefault,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme(scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GatesTypography.headingMedium,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        elevation: 0,
        margin: EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        dragHandleColor: GatesColors.borderDefault,
        dragHandleSize: Size(40, 4),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: GatesColors.bgBrand,
      brightness: Brightness.dark,
    ).copyWith(error: GatesColors.statusError);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: _textTheme(scheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        centerTitle: false,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        dragHandleColor: GatesColors.borderDefault,
        dragHandleSize: Size(40, 4),
      ),
    );
  }
}
