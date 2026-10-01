import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Keeps `app_es.arb` free of messages nobody reads anymore.
void main() {
  test('every ARB message is used somewhere in lib', () {
    final arb = jsonDecode(
      File('lib/l10n/app_es.arb').readAsStringSync(),
    ) as Map<String, dynamic>;
    final keys = arb.keys.where((k) => !k.startsWith('@'));
    final source = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) =>
              f.path.endsWith('.dart') &&
              !f.path.contains('/l10n/app_localizations'),
        )
        .map((f) => f.readAsStringSync())
        .join('\n');
    final unused = [
      for (final key in keys)
        if (!RegExp('\\b$key\\b').hasMatch(source)) key,
    ];
    expect(unused, isEmpty, reason: 'Remove from app_es.arb: $unused');
  });
}
