import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Semantic colour tokens (Figma collection "Vecinoo / Color", modes Light
/// and Dark). Widgets read them through `context.palette` and never hold a
/// raw colour, so one place decides how every surface looks per mode.
/// Background/border/foreground triple of a status pill or chip.
@immutable
class GatesTone {
  const GatesTone({
    required this.background,
    required this.border,
    required this.foreground,
  });

  final Color background;
  final Color border;
  final Color foreground;

  static GatesTone lerp(GatesTone a, GatesTone b, double t) => GatesTone(
    background: Color.lerp(a.background, b.background, t)!,
    border: Color.lerp(a.border, b.border, t)!,
    foreground: Color.lerp(a.foreground, b.foreground, t)!,
  );
}

@immutable
class GatesPalette extends ThemeExtension<GatesPalette> {
  const GatesPalette({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgElevated,
    required this.bgBrand,
    required this.bgPressed,
    required this.bgAccent,
    required this.bgSubtle,
    required this.bgWarm,
    required this.bgLilac,
    required this.bgDanger,
    required this.textPrimary,
    required this.textSecondary,
    required this.textBrand,
    required this.textOnBrand,
    required this.textOnDanger,
    required this.textInverse,
    required this.borderDefault,
    required this.borderSubtle,
    required this.borderFocus,
    required this.borderSelected,
    required this.borderSelectedBrand,
    required this.knobOff,
    required this.knobOffGlyph,
    required this.iconDefault,
    required this.iconBrand,
    required this.statusError,
    required this.statusErrorBg,
    required this.statusWarning,
    required this.statusWarningBg,
    required this.statusSuccess,
    required this.statusSuccessBg,
    required this.accentCoral,
    required this.scrim,
    required this.shadow,
    required this.glowStrong,
    required this.glowSoft,
    required this.glowOpacity,
    required this.bgOnBrandAction,
    required this.textOnBrandAction,
    required this.tonePending,
    required this.toneConfirmed,
    required this.toneNeutral,
    required this.toneCancelled,
    required this.toneInfo,
  });

  final Color bgCanvas;
  final Color bgSurface;

  /// Panels raised above [bgSurface]: bottom sheets, dialogs, menus.
  final Color bgElevated;
  final Color bgBrand;
  final Color bgPressed;
  final Color bgAccent;
  final Color bgSubtle;
  final Color bgWarm;
  final Color bgLilac;

  /// Fill of destructive actions; pair with [textOnDanger].
  final Color bgDanger;

  final Color textPrimary;
  final Color textSecondary;
  final Color textBrand;

  /// Text/icons on a [bgBrand] fill — not automatically white.
  final Color textOnBrand;

  /// Text/icons on a [bgDanger] fill.
  final Color textOnDanger;

  /// White-on-photo/scrim text that must stay white in both modes.
  final Color textInverse;

  /// Borders of interactive controls (inputs, selects, outlined buttons).
  final Color borderDefault;

  /// Decorative separators and card outlines.
  final Color borderSubtle;
  final Color borderFocus;

  /// Outline that marks the selected tab/pill without relying on its fill.
  final Color borderSelected;

  /// Outline of a selected control filled with [bgBrand] (tab pill, weekday
  /// chip, selected date); same as the fill in light mode.
  final Color borderSelectedBrand;

  /// Thumb of an "off" switch.
  final Color knobOff;
  final Color knobOffGlyph;

  final Color iconDefault;
  final Color iconBrand;

  final Color statusError;
  final Color statusErrorBg;
  final Color statusWarning;
  final Color statusWarningBg;
  final Color statusSuccess;
  final Color statusSuccessBg;
  final Color accentCoral;

  final Color scrim;
  final Color shadow;
  final Color glowStrong;
  final Color glowSoft;
  final double glowOpacity;

  /// Secondary action sitting on a [bgBrand] card (hero "Reservas" card).
  final Color bgOnBrandAction;
  final Color textOnBrandAction;

  /// Status pills / chips (booking status, access kind).
  final GatesTone tonePending;
  final GatesTone toneConfirmed;
  final GatesTone toneNeutral;
  final GatesTone toneCancelled;
  final GatesTone toneInfo;

  static const light = GatesPalette(
    bgCanvas: Color(0xFFF7F8F4),
    bgSurface: Color(0xFFFFFFFF),
    bgElevated: Color(0xFFFFFFFF),
    bgBrand: Color(0xFF344F40),
    bgPressed: Color(0xFF243B2D),
    bgAccent: Color(0xFFDDE8D6),
    bgSubtle: Color(0xFFEEF2EB),
    bgWarm: Color(0xFFF8E4AF),
    bgLilac: Color(0xFFE8E3F3),
    bgDanger: Color(0xFFB04439),
    textPrimary: Color(0xFF252D29),
    textSecondary: Color(0xFF68726B),
    textBrand: Color(0xFF344F40),
    textOnBrand: Color(0xFFFFFFFF),
    textOnDanger: Color(0xFFFFFFFF),
    textInverse: Color(0xFFFFFFFF),
    borderDefault: Color(0xFFDCE2DA),
    borderSubtle: Color(0xFFDCE2DA),
    borderFocus: Color(0xFF344F40),
    borderSelected: Color(0x00000000),
    borderSelectedBrand: Color(0xFF344F40),
    knobOff: Color(0xFFFFFFFF),
    knobOffGlyph: Color(0xFF344F40),
    iconDefault: Color(0xFF252D29),
    iconBrand: Color(0xFF344F40),
    statusError: Color(0xFFB04439),
    statusErrorBg: Color(0xFFFBECE8),
    statusWarning: Color(0xFF795B18),
    statusWarningBg: Color(0xFFFFF3D6),
    statusSuccess: Color(0xFF39704A),
    statusSuccessBg: Color(0xFFE6F1E5),
    accentCoral: Color(0xFFE07A5F),
    scrim: Color(0x52000000),
    shadow: Color(0x1A252D29),
    glowStrong: Color(0xFFF8D68F),
    glowSoft: Color(0xFFF8E0A6),
    glowOpacity: 0.5,
    bgOnBrandAction: Color(0xFFDDE8D6),
    textOnBrandAction: Color(0xFF344F40),
    tonePending: GatesTone(
      background: Color(0xFFFFF6E3),
      border: Color(0xFFF1BE60),
      foreground: Color(0xFF8C4F09),
    ),
    toneConfirmed: GatesTone(
      background: Color(0xFFE8F3EC),
      border: Color(0xFFA7C7B0),
      foreground: Color(0xFF2F5A3A),
    ),
    toneNeutral: GatesTone(
      background: Color(0xFFF3F4F6),
      border: Color(0xFFD1D5DB),
      foreground: Color(0xFF4B5563),
    ),
    toneCancelled: GatesTone(
      background: Color(0xFFFDECEC),
      border: Color(0xFFE7B7B3),
      foreground: Color(0xFF8A3A2E),
    ),
    toneInfo: GatesTone(
      background: Color(0xFFE9F1FA),
      border: Color(0xFFE9F1FA),
      foreground: Color(0xFF355C85),
    ),
  );

  static const dark = GatesPalette(
    bgCanvas: Color(0xFF141C17),
    bgSurface: Color(0xFF1E2A22),
    bgElevated: Color(0xFF28362C),
    bgBrand: Color(0xFFB5D49F),
    bgPressed: Color(0xFF9FC288),
    bgAccent: Color(0xFF30442E),
    bgSubtle: Color(0xFF28382D),
    bgWarm: Color(0xFF3F341F),
    bgLilac: Color(0xFF332F45),
    bgDanger: Color(0xFFFFB1A3),
    textPrimary: Color(0xFFF0F3E9),
    textSecondary: Color(0xFFB4C0B2),
    textBrand: Color(0xFFC2DDB0),
    textOnBrand: Color(0xFF182313),
    textOnDanger: Color(0xFF321713),
    textInverse: Color(0xFFFFFFFF),
    borderDefault: Color(0xFF718571),
    borderSubtle: Color(0xFF3C4C3E),
    borderFocus: Color(0xFFC2DDB0),
    borderSelected: Color(0xFFC2DDB0),
    borderSelectedBrand: Color(0xFFC2DDB0),
    knobOff: Color(0xFFB4C0B2),
    knobOffGlyph: Color(0xFF141C17),
    iconDefault: Color(0xFFDCE7D7),
    iconBrand: Color(0xFFC2DDB0),
    statusError: Color(0xFFFFB1A3),
    statusErrorBg: Color(0xFF3A2521),
    statusWarning: Color(0xFFF1CF82),
    statusWarningBg: Color(0xFF3F341F),
    statusSuccess: Color(0xFFA9D8A8),
    statusSuccessBg: Color(0xFF233A2B),
    accentCoral: Color(0xFFE07A5F),
    scrim: Color(0x99000000),
    shadow: Color(0x66000000),
    glowStrong: Color(0xFFF8D68F),
    glowSoft: Color(0xFFF8E0A6),
    glowOpacity: 0.3,
    bgOnBrandAction: Color(0xFF344F40),
    textOnBrandAction: Color(0xFFF0F3E9),
    tonePending: GatesTone(
      background: Color(0xFF3F341F),
      border: Color(0xFF8A7438),
      foreground: Color(0xFFF1CF82),
    ),
    toneConfirmed: GatesTone(
      background: Color(0xFF233A2B),
      border: Color(0xFF4F7A5A),
      foreground: Color(0xFFA9D8A8),
    ),
    toneNeutral: GatesTone(
      background: Color(0xFF28382D),
      border: Color(0xFF5B6B5E),
      foreground: Color(0xFFB4C0B2),
    ),
    toneCancelled: GatesTone(
      background: Color(0xFF3A2521),
      border: Color(0xFF8A4F46),
      foreground: Color(0xFFFFB1A3),
    ),
    toneInfo: GatesTone(
      background: Color(0xFF1F3042),
      border: Color(0xFF1F3042),
      foreground: Color(0xFFA9C8E8),
    ),
  );

  @override
  GatesPalette copyWith() => this;

  @override
  GatesPalette lerp(ThemeExtension<GatesPalette>? other, double t) {
    if (other is! GatesPalette) return this;
    Color c(Color a, Color b) => Color.lerp(a, b, t)!;
    return GatesPalette(
      bgCanvas: c(bgCanvas, other.bgCanvas),
      bgSurface: c(bgSurface, other.bgSurface),
      bgElevated: c(bgElevated, other.bgElevated),
      bgBrand: c(bgBrand, other.bgBrand),
      bgPressed: c(bgPressed, other.bgPressed),
      bgAccent: c(bgAccent, other.bgAccent),
      bgSubtle: c(bgSubtle, other.bgSubtle),
      bgWarm: c(bgWarm, other.bgWarm),
      bgLilac: c(bgLilac, other.bgLilac),
      bgDanger: c(bgDanger, other.bgDanger),
      textPrimary: c(textPrimary, other.textPrimary),
      textSecondary: c(textSecondary, other.textSecondary),
      textBrand: c(textBrand, other.textBrand),
      textOnBrand: c(textOnBrand, other.textOnBrand),
      textOnDanger: c(textOnDanger, other.textOnDanger),
      textInverse: c(textInverse, other.textInverse),
      borderDefault: c(borderDefault, other.borderDefault),
      borderSubtle: c(borderSubtle, other.borderSubtle),
      borderFocus: c(borderFocus, other.borderFocus),
      borderSelected: c(borderSelected, other.borderSelected),
      borderSelectedBrand: c(borderSelectedBrand, other.borderSelectedBrand),
      knobOff: c(knobOff, other.knobOff),
      knobOffGlyph: c(knobOffGlyph, other.knobOffGlyph),
      iconDefault: c(iconDefault, other.iconDefault),
      iconBrand: c(iconBrand, other.iconBrand),
      statusError: c(statusError, other.statusError),
      statusErrorBg: c(statusErrorBg, other.statusErrorBg),
      statusWarning: c(statusWarning, other.statusWarning),
      statusWarningBg: c(statusWarningBg, other.statusWarningBg),
      statusSuccess: c(statusSuccess, other.statusSuccess),
      statusSuccessBg: c(statusSuccessBg, other.statusSuccessBg),
      accentCoral: c(accentCoral, other.accentCoral),
      scrim: c(scrim, other.scrim),
      shadow: c(shadow, other.shadow),
      glowStrong: c(glowStrong, other.glowStrong),
      glowSoft: c(glowSoft, other.glowSoft),
      glowOpacity: glowOpacity + (other.glowOpacity - glowOpacity) * t,
      bgOnBrandAction: c(bgOnBrandAction, other.bgOnBrandAction),
      textOnBrandAction: c(textOnBrandAction, other.textOnBrandAction),
      tonePending: GatesTone.lerp(tonePending, other.tonePending, t),
      toneConfirmed: GatesTone.lerp(toneConfirmed, other.toneConfirmed, t),
      toneNeutral: GatesTone.lerp(toneNeutral, other.toneNeutral, t),
      toneCancelled: GatesTone.lerp(toneCancelled, other.toneCancelled, t),
      toneInfo: GatesTone.lerp(toneInfo, other.toneInfo, t),
    );
  }
}

extension GatesPaletteContext on BuildContext {
  /// Falls back to the stock palette for the theme's brightness so widgets
  /// still render under a plain `MaterialApp` (e.g. in tests).
  GatesPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<GatesPalette>() ??
        (theme.brightness == Brightness.dark
            ? GatesPalette.dark
            : GatesPalette.light);
  }

  /// Text styles whose colour depends on the mode (secondary copy).
  GatesText get gatesText => GatesText(palette);
}

/// Mode-dependent text styles; the colourless ones live in
/// `GatesTypography` and inherit the theme's `onSurface`.
class GatesText {
  const GatesText(this._palette);

  final GatesPalette _palette;

  TextStyle get caption =>
      GatesTypography.caption.copyWith(color: _palette.textSecondary);

  /// [GatesTypography.labelSecondary] in the secondary colour.
  TextStyle get labelSecondary =>
      GatesTypography.labelSecondary.copyWith(color: _palette.textSecondary);
}
