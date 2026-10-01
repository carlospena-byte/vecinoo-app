import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'gates_palette.dart';

export 'gates_palette.dart';

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
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
    letterSpacing: -0.2,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
    letterSpacing: -0.1,
  );

  static const TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 20 / 14,
    letterSpacing: 0,
  );

  static const TextStyle body = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
    letterSpacing: 0,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 18 / 12,
    letterSpacing: 0.1,
  );

  /// [label] (14px) at regular weight and secondary color — helper copy under
  /// a heading (schedule times, payment methods...) that needs the 14px size
  /// but shouldn't read as a form label.
  static final TextStyle labelSecondary = label.copyWith(
    fontWeight: FontWeight.w400,
  );
}

class AppTheme {
  AppTheme._();

  static TextTheme _textTheme(GatesPalette p) {
    final onSurface = p.textPrimary;
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
      bodySmall: GatesTypography.caption.copyWith(color: p.textSecondary),
      labelLarge: GatesTypography.label.copyWith(color: onSurface),
      labelMedium: GatesTypography.label.copyWith(color: onSurface),
      labelSmall: GatesTypography.caption.copyWith(color: p.textSecondary),
    );
  }

  static ThemeData light() {
    const p = GatesPalette.light;
    return _build(
      p,
      ColorScheme.light(
        primary: p.bgBrand,
        onPrimary: p.textOnBrand,
        secondary: p.bgAccent,
        onSecondary: p.textBrand,
        error: p.statusError,
        onError: p.textOnDanger,
        surface: p.bgSurface,
        onSurface: p.textPrimary,
        outline: p.borderDefault,
      ),
    );
  }

  static ThemeData dark() {
    const p = GatesPalette.dark;
    return _build(
      p,
      ColorScheme.dark(
        primary: p.bgBrand,
        onPrimary: p.textOnBrand,
        secondary: p.bgAccent,
        onSecondary: p.textBrand,
        primaryContainer: p.bgAccent,
        onPrimaryContainer: p.textBrand,
        secondaryContainer: p.bgAccent,
        onSecondaryContainer: p.textBrand,
        errorContainer: p.statusErrorBg,
        onErrorContainer: p.statusError,
        error: p.statusError,
        onError: p.textOnDanger,
        surface: p.bgSurface,
        onSurface: p.textPrimary,
        onSurfaceVariant: p.textSecondary,
        outline: p.borderDefault,
        outlineVariant: p.borderSubtle,
        surfaceContainerLowest: p.bgCanvas,
        surfaceContainerLow: p.bgSurface,
        surfaceContainer: p.bgSurface,
        surfaceContainerHigh: p.bgElevated,
        surfaceContainerHighest: p.bgElevated,
        inverseSurface: p.textPrimary,
        onInverseSurface: p.bgCanvas,
      ),
    );
  }

  static ThemeData _build(GatesPalette p, ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      extensions: [p],
      // Every screen sits on the canvas painted once by `GatesBackground`.
      scaffoldBackgroundColor: Colors.transparent,
      textTheme: _textTheme(p),
      iconTheme: IconThemeData(color: p.iconDefault),
      dividerTheme: DividerThemeData(color: p.borderSubtle),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GatesTypography.headingMedium.copyWith(
          color: p.textPrimary,
        ),
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? p.bgSurface : null,
        margin: const EdgeInsets.symmetric(vertical: 6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: p.borderFocus,
        selectionHandleColor: p.borderFocus,
        selectionColor: p.borderFocus.withValues(alpha: 0.3),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isDark ? p.bgBrand : null,
      ),
      switchTheme: isDark
          ? SwitchThemeData(
              trackColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? p.bgBrand
                    : p.bgSubtle,
              ),
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? p.bgBrand
                    : p.borderDefault,
              ),
              thumbColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? p.textOnBrand
                    : p.knobOff,
              ),
            )
          : null,
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? p.bgElevated : null,
        modalBarrierColor: p.scrim,
        dragHandleColor: p.borderSubtle,
        dragHandleSize: const Size(40, 4),
      ),
      dialogTheme: isDark
          ? DialogThemeData(
              backgroundColor: p.bgElevated,
              surfaceTintColor: Colors.transparent,
            )
          : null,
      popupMenuTheme: isDark
          ? PopupMenuThemeData(
              color: p.bgElevated,
              surfaceTintColor: Colors.transparent,
            )
          : null,
    );
  }
}
