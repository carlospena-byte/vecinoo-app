import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Colours live in `GatesPalette` (lib/core/theme) and are read through
/// `context.palette`, so a component can't silently ignore dark mode.
/// Photo/illustration viewers that must stay black/white are allow-listed.
void main() {
  test('no raw colours outside the palette', () {
    const allowed = {
      'lib/core/theme/gates_palette.dart',
      'lib/core/theme/app_theme.dart',
      // Full-screen photo viewer: black backdrop with white chrome by design.
      'lib/features/amenities/presentation/amenity_detail_screen.dart',
    };
    final raw = RegExp(
      r'Color\(0x|Color\.from|Colors\.(white|black|red|green|blue|grey|orange)\b',
    );
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final path = entity.path.replaceAll('\\', '/');
      if (allowed.contains(path)) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (raw.hasMatch(lines[i])) offenders.add('$path:${i + 1}');
      }
    }
    expect(offenders, isEmpty, reason: 'Use context.palette tokens instead.');
  });
}
