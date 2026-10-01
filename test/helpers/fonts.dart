import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Manrope so widget tests lay text out with the real
/// glyph widths instead of the test font's (wider) squares.
Future<void> loadManrope() async {
  final loader = FontLoader('Manrope');
  for (final weight in ['Regular', 'Medium', 'SemiBold', 'Bold']) {
    final bytes = File('assets/fonts/Manrope-$weight.ttf').readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}
