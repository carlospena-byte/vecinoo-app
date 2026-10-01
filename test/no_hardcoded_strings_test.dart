import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// User-visible text lives in `lib/l10n/app_es.arb` and is read with
/// `context.l10n`. This catches the common ways a literal sneaks back in.
void main() {
  test('no hardcoded UI strings outside lib/l10n', () {
    final widgetText = RegExp(
      r"(Text\(|label:|title:|message:|hintText:|helperText:|tooltip:|semanticLabel:|hint:)\s*'[^']*[A-Za-zÁÉÍÓÚáéíóúñ¿¡][^']*'",
    );
    final accented = RegExp("['\"][^'\"]*[áéíóúñ¿¡ÁÉÍÓÚ][^'\"]*['\"]");
    // Brand name and the country catalog (names resolved via localizedName).
    const allowed = {
      'lib/main.dart',
      'lib/core/widgets/gates_phone_field.dart',
    };
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (path.startsWith('lib/l10n/') || allowed.contains(path)) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i];
        if (line.trimLeft().startsWith('//') || line.contains('debugPrint')) {
          continue;
        }
        if (widgetText.hasMatch(line) || accented.hasMatch(line)) {
          offenders.add('$path:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: 'Add the text to app_es.arb instead.');
  });
}
