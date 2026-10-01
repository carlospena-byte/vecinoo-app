import 'package:flutter/widgets.dart';

import 'app_localizations.dart';
import 'app_localizations_es.dart';

export 'app_localizations.dart';

extension AppLocalizationsContext on BuildContext {
  /// Translated strings: `context.l10n.someKey`. Falls back to Spanish when
  /// the tree has no localization delegates (e.g. a bare `MaterialApp` in a
  /// widget test), so screens never crash for lack of them.
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      AppLocalizationsEs();
}
