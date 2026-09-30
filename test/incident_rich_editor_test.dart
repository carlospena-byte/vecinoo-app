import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/incidents/presentation/incident_rich_editor.dart';

void main() {
  test('formatting round-trips through sanitized HTML', () {
    final c = RichTextController();
    c.value = const TextEditingValue(
      text: 'Hola <b> & mundo',
      selection: TextSelection.collapsed(offset: 16),
    );
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    c.toggleBold();
    c.selection = const TextSelection(baseOffset: 5, extentOffset: 8);
    c.applyLink('https://example.com');

    final html = c.toHtml()!;
    expect(html, contains('<strong>Hola</strong>'));
    expect(html, contains('<a href="https://example.com">&lt;b&gt;</a>'));
    expect(html, contains('&amp;'));

    final d = RichTextController()..loadHtml(html);
    expect(d.text, 'Hola <b> & mundo');
    expect(d.toHtml(), html);
  });

  test('bullets serialize to a list and unsafe links are dropped', () {
    final c = RichTextController();
    c.value = const TextEditingValue(
      text: 'Uno',
      selection: TextSelection.collapsed(offset: 3),
    );
    c.toggleBullet();
    expect(c.text, '• Uno');
    expect(c.toHtml(), '<ul><li>Uno</li></ul>');

    final d = RichTextController()
      ..loadHtml('<p><a href="javascript:alert(1)">x</a></p>');
    expect(d.toHtml(), '<p>x</p>');
  });
}
