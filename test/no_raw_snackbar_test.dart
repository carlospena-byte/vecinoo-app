import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Design rule: user feedback is shown with `showGatesToast` (Figma "Toast",
/// lib/core/widgets/gates_toast.dart), never a raw Material SnackBar.
void main() {
  test('no raw SnackBar outside gates_toast.dart', () {
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('core/widgets/gates_toast.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (RegExp(r'\bSnackBar\b|showSnackBar|MaterialBanner')
            .hasMatch(lines[i])) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(
      offenders,
      isEmpty,
      reason:
          'Use showGatesToast(...) from core/widgets/gates_toast.dart '
          'instead of SnackBar. Found in: ${offenders.join(', ')}',
    );
  });
}
