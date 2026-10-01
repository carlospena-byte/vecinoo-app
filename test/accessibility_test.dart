import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/core/widgets/gates_add_button.dart';
import 'package:gates_app/core/widgets/gates_button.dart';
import 'package:gates_app/core/widgets/gates_segmented_tabs.dart';
import 'package:gates_app/core/widgets/gates_text_field.dart';
import 'package:gates_app/core/widgets/otp_code_field.dart';
import 'package:gates_app/core/widgets/swipe_to_confirm.dart';

Future<void> _pump(WidgetTester tester, Widget child, {ThemeMode? mode}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode ?? ThemeMode.light,
      home: Scaffold(
        body: Padding(padding: const EdgeInsets.all(24), child: child),
      ),
    ),
  );
}

void main() {
  for (final mode in [ThemeMode.light, ThemeMode.dark]) {
    group('shared controls (${mode.name})', () {
      testWidgets('tap targets are labelled and big enough', (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          Column(
            children: [
              GatesAddButton(semanticLabel: 'Nueva visita', onTap: () {}),
              const SizedBox(height: 12),
              GatesButton(label: 'Continuar', onPressed: () {}),
              const SizedBox(height: 12),
              GatesSegmentedTabs<int>(
                options: const [
                  GatesSegmentedTabOption(value: 0, label: 'Pendientes'),
                  GatesSegmentedTabOption(value: 1, label: 'Historial'),
                ],
                selected: 0,
                onSelect: (_) {},
              ),
            ],
          ),
          mode: mode,
        );
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
        handle.dispose();
      });
    });
  }

  testWidgets('add button is announced as a labelled button', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      GatesAddButton(semanticLabel: 'Nueva visita', onTap: () {}),
    );
    final node = tester.getSemantics(find.bySemanticsLabel('Nueva visita'));
    expect(node.flagsCollection.isButton, isTrue);
    handle.dispose();
  });

  testWidgets('segmented tabs expose the selected state', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      GatesSegmentedTabs<int>(
        options: const [
          GatesSegmentedTabOption(value: 0, label: 'Pendientes'),
          GatesSegmentedTabOption(value: 1, label: 'Historial'),
        ],
        selected: 1,
        onSelect: (_) {},
      ),
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Historial'))
          .flagsCollection
          .isSelected,
      Tristate.isTrue,
    );
    expect(
      tester
          .getSemantics(find.bySemanticsLabel('Pendientes'))
          .flagsCollection
          .isSelected,
      Tristate.isFalse,
    );
    handle.dispose();
  });

  testWidgets('text field is announced with its label, not just the hint', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      const GatesTextField(
        label: 'Nombre de referencia',
        hintText: 'Visita de...',
      ),
    );
    final node = tester.getSemantics(
      find.bySemanticsLabel(RegExp('Nombre de referencia')),
    );
    expect(node.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });

  testWidgets('OTP field is reachable by screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(
      tester,
      OtpCodeField(
        controller: TextEditingController(),
        label: 'Código',
        length: 6,
      ),
    );
    final node = tester.getSemantics(find.bySemanticsLabel(RegExp('Código')));
    expect(node.flagsCollection.isTextField, isTrue);
    handle.dispose();
  });

  testWidgets('swipe to confirm can be confirmed without dragging', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    var confirmed = 0;
    await _pump(
      tester,
      SwipeToConfirm(
        label: 'Desliza para cancelar',
        onConfirmed: () => confirmed++,
      ),
    );
    tester.semantics.tap(find.semantics.byLabel('Desliza para cancelar'));
    await tester.pump();
    expect(confirmed, 1);
    handle.dispose();
  });
}
