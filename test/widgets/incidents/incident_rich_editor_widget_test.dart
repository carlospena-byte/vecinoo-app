import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/incidents/presentation/incident_rich_editor.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';

void main() {
  setUpAll(loadManrope);

  final l10n = AppLocalizationsEs();

  Future<RichTextController> pump(
    WidgetTester tester, {
    ThemeMode mode = ThemeMode.light,
    String? initialHtml,
  }) async {
    final controller = RichTextController()..loadHtml(initialHtml);
    addTearDown(controller.dispose);
    await pumpApp(
      tester,
      Scaffold(body: IncidentRichEditor(controller: controller)),
      mode: mode,
    );
    return controller;
  }

  Finder tool(String label) => find.bySemanticsLabel(RegExp(label));

  testWidgets('shows label, hint and the four tools', (tester) async {
    await pump(tester);
    expect(find.text(l10n.incidentsEditorDescriptionLabel), findsOneWidget);
    expect(find.text(l10n.incidentsEditorDescriptionHint), findsOneWidget);
    for (final label in [
      l10n.incidentsEditorBold,
      l10n.incidentsEditorItalic,
      l10n.incidentsEditorList,
      l10n.incidentsEditorLink,
    ]) {
      expect(tool(label), findsOneWidget);
    }
  });

  testWidgets('bold and italic apply to the selection and reflect state', (
    tester,
  ) async {
    final c = await pump(tester);
    await tester.enterText(find.byType(TextField), 'hola mundo');
    c.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
    await tester.pump();

    await tester.tap(tool(l10n.incidentsEditorBold));
    await tester.pump();
    expect(c.isBold, isTrue);
    expect(c.toHtml(), '<p><strong>hola</strong> mundo</p>');

    await tester.tap(tool(l10n.incidentsEditorItalic));
    await tester.pump();
    expect(c.isItalic, isTrue);
    expect(c.toHtml(), '<p><em><strong>hola</strong></em> mundo</p>');

    await tester.tap(tool(l10n.incidentsEditorBold));
    await tester.pump();
    expect(c.isBold, isFalse);
    expect(c.toHtml(), '<p><em>hola</em> mundo</p>');
  });

  testWidgets('a collapsed caret toggles the style of the next typing', (
    tester,
  ) async {
    final c = await pump(tester);
    await tester.enterText(find.byType(TextField), 'a');
    c.selection = const TextSelection.collapsed(offset: 1);
    await tester.tap(tool(l10n.incidentsEditorBold));
    await tester.pump();
    expect(c.isBold, isTrue);

    c.value = const TextEditingValue(
      text: 'ab',
      selection: TextSelection.collapsed(offset: 2),
    );
    expect(c.toHtml(), '<p>a<strong>b</strong></p>');
    // Moving the caret drops the pending style.
    c.selection = const TextSelection.collapsed(offset: 1);
    expect(c.isBold, isFalse);
  });

  testWidgets('list tool adds and removes the bullet', (tester) async {
    final c = await pump(tester);
    await tester.enterText(find.byType(TextField), 'Uno');
    c.selection = const TextSelection.collapsed(offset: 3);
    await tester.tap(tool(l10n.incidentsEditorList));
    await tester.pump();
    expect(c.text, '• Uno');
    expect(c.isBullet, isTrue);
    expect(c.toHtml(), '<ul><li>Uno</li></ul>');

    await tester.tap(tool(l10n.incidentsEditorList));
    await tester.pump();
    expect(c.text, 'Uno');
    expect(c.isBullet, isFalse);
  });

  testWidgets('link sheet: selection becomes a link, scheme added', (
    tester,
  ) async {
    final c = await pump(tester);
    await tester.enterText(find.byType(TextField), 'ver sitio');
    c.selection = const TextSelection(baseOffset: 4, extentOffset: 9);
    await tester.pump();

    await tester.tap(tool(l10n.incidentsEditorLink));
    await tester.pumpAndSettle();
    // With a selection there is no "select text" hint.
    expect(find.text(l10n.incidentsEditorLinkNoSelection), findsNothing);
    await tester.enterText(
      find.widgetWithText(TextField, '').last,
      'example.com/a',
    );
    await tester.tap(find.text(l10n.incidentsEditorAddLink).last);
    await tester.pumpAndSettle();

    expect(c.toHtml(), '<p>ver <a href="https://example.com/a">sitio</a></p>');
    expect(find.text(l10n.incidentsEditorAddLink), findsNothing);
  });

  testWidgets('link sheet validates and inserts the url at a bare caret', (
    tester,
  ) async {
    final c = await pump(tester);
    c.selection = const TextSelection.collapsed(offset: 0);
    await tester.tap(tool(l10n.incidentsEditorLink));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsEditorLinkNoSelection), findsOneWidget);

    final field = find.byType(EditableText).last;
    // Empty submit does nothing.
    await tester.tap(find.text(l10n.incidentsEditorAddLink).last);
    await tester.pump();
    expect(find.text(l10n.incidentsEditorLinkInvalid), findsNothing);

    await tester.enterText(field, 'ftp://x.com');
    await tester.tap(find.text(l10n.incidentsEditorAddLink).last);
    await tester.pump();
    expect(find.text(l10n.incidentsEditorLinkInvalid), findsOneWidget);

    // Typing clears the error.
    await tester.enterText(field, 'nodot');
    await tester.pump();
    expect(find.text(l10n.incidentsEditorLinkInvalid), findsNothing);
    await tester.tap(find.text(l10n.incidentsEditorAddLink).last);
    await tester.pump();
    expect(find.text(l10n.incidentsEditorLinkInvalid), findsOneWidget);

    await tester.enterText(field, 'mailto:a@b.co');
    await tester.tap(find.text(l10n.incidentsEditorAddLink).last);
    await tester.pumpAndSettle();
    expect(c.text, 'mailto:a@b.co');
    expect(c.toHtml(), contains('<a href="mailto:a@b.co">'));
  });

  testWidgets('loads saved html into the editor and renders in dark mode', (
    tester,
  ) async {
    await pump(
      tester,
      mode: ThemeMode.dark,
      initialHtml:
          '<p>Hola <strong>fuerte</strong> <a href="https://a.co">link</a></p>',
    );
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('RichTextController', () {
    test('toHtml is null for blank content', () {
      final c = RichTextController();
      expect(c.toHtml(), isNull);
      c.loadHtml('   ');
      expect(c.toHtml(), isNull);
    });

    test('loadHtml keeps legacy plain text and unescapes entities', () {
      final c = RichTextController()..loadHtml('a &lt; b &amp; "c"');
      expect(c.text, 'a < b & "c"');
      expect(c.toHtml(), '<p>a &lt; b &amp; &quot;c&quot;</p>');
    });

    test('loadHtml handles blocks, nesting, b/i aliases and lists', () {
      final c = RichTextController()
        ..loadHtml(
          '<p><b>A</b><i>B</i></p><p>C</p><ul><li>x</li><li><em>y</em></li></ul>',
        );
      expect(c.text, 'AB\nC\n• x\n• y');
      expect(
        c.toHtml(),
        '<p><strong>A</strong><em>B</em></p><p>C</p>'
        '<ul><li>x</li><li><em>y</em></li></ul>',
      );
    });

    test('links: unsafe and missing hrefs are dropped, mailto kept', () {
      final c = RichTextController()
        ..loadHtml(
          '<p><a>no</a> <a href="javascript:x">js</a> '
          '<a href="mailto:a@b.co">m</a> <a href="https://a.co?x=1&amp;y=2">h</a></p>',
        );
      expect(
        c.toHtml(),
        '<p>no js <a href="mailto:a@b.co">m</a> '
        '<a href="https://a.co?x=1&amp;y=2">h</a></p>',
      );
    });

    test('typing after a link continues it; hasSelection reflects range', () {
      final c = RichTextController()
        ..loadHtml('<p><a href="https://a.co">ab</a></p>');
      expect(c.hasSelection, isFalse);
      c.value = const TextEditingValue(
        text: 'abc',
        selection: TextSelection.collapsed(offset: 3),
      );
      expect(c.toHtml(), '<p><a href="https://a.co">abc</a></p>');
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
      expect(c.hasSelection, isTrue);
    });

    test('deleting text keeps formatting aligned', () {
      final c = RichTextController();
      c.value = const TextEditingValue(
        text: 'abcdef',
        selection: TextSelection.collapsed(offset: 6),
      );
      c.selection = const TextSelection(baseOffset: 3, extentOffset: 6);
      c.toggleBold();
      c.value = const TextEditingValue(
        text: 'aef',
        selection: TextSelection.collapsed(offset: 1),
      );
      expect(c.toHtml(), '<p>a<strong>ef</strong></p>');
    });

    test('toggleBullet on a later line and with an invalid selection', () {
      final c = RichTextController();
      c.value = const TextEditingValue(
        text: 'uno\ndos',
        selection: TextSelection.collapsed(offset: 7),
      );
      c.toggleBullet();
      expect(c.text, 'uno\n• dos');
      expect(c.toHtml(), '<p>uno</p><ul><li>dos</li></ul>');

      final d = RichTextController();
      d.toggleBullet();
      expect(d.text, '• ');
      d.toggleBold(); // caret after the bullet: next typing is bold
      expect(d.isBold, isTrue);
      d.applyLink('https://a.co');
      expect(d.text, '• https://a.co');
    });

    test('isActive requires every char of a selection to be styled', () {
      final c = RichTextController();
      c.value = const TextEditingValue(
        text: 'abcd',
        selection: TextSelection.collapsed(offset: 4),
      );
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 2);
      c.toggleBold();
      c.selection = const TextSelection(baseOffset: 0, extentOffset: 4);
      expect(c.isBold, isFalse);
      c.toggleBold();
      expect(c.isBold, isTrue);
    });

    testWidgets('buildTextSpan styles bold, italic and links', (tester) async {
      final c = RichTextController()
        ..loadHtml(
          '<p>a <strong>b</strong> <em>c</em> <a href="https://a.co">d</a></p>',
        );
      late TextSpan span;
      await pumpApp(
        tester,
        Builder(
          builder: (context) {
            span = c.buildTextSpan(context: context, withComposing: false);
            return const SizedBox();
          },
        ),
      );
      final children = span.children!.cast<TextSpan>();
      expect(children.map((s) => s.text).join(), 'a b c d');
      expect(
        children.any((s) => s.style?.fontWeight == FontWeight.w700),
        isTrue,
      );
      expect(
        children.any((s) => s.style?.fontStyle == FontStyle.italic),
        isTrue,
      );
      expect(
        children.any((s) => s.style?.decoration == TextDecoration.underline),
        isTrue,
      );
      expect(
        RichTextController()
            .buildTextSpan(
              context: tester.element(find.byType(SizedBox)),
              withComposing: false,
            )
            .text,
        '',
      );
    });
  });
}
