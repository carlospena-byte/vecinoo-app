import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fonts.dart';

import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/core/widgets/gates_add_button.dart';
import 'package:gates_app/core/widgets/gates_button.dart';
import 'package:gates_app/core/widgets/gates_segmented_tabs.dart';
import 'package:gates_app/core/widgets/gates_select_field.dart';
import 'package:gates_app/core/widgets/gates_switch_row.dart';
import 'package:gates_app/core/widgets/gates_text_field.dart';
import 'package:gates_app/core/widgets/swipe_to_confirm.dart';

/// Renders the shared controls at the largest accessibility text sizes on a
/// phone-width screen; any overflow fails the test.
void main() {
  setUpAll(loadManrope);

  final controls = <String, Widget Function()>{
    'button': () => GatesButton(label: 'Aceptar invitación', onPressed: () {}),
    'segmented tabs': () => GatesSegmentedTabs<int>(
      options: const [
        GatesSegmentedTabOption(value: 0, label: 'Pendientes'),
        GatesSegmentedTabOption(value: 1, label: 'En curso'),
        GatesSegmentedTabOption(value: 2, label: 'Historial'),
      ],
      selected: 0,
      onSelect: (_) {},
    ),
    'text field': () => const GatesTextField(
      label: 'Nombre de referencia',
      hintText: 'Visita de...',
      helperText: 'Escribe un nombre para la visita.',
    ),
    'select field': () => GatesSelectField<int>(
      label: 'Categoría (opcional)',
      value: 0,
      options: const {0: 'Mantenimiento'},
      onChanged: (_) {},
    ),
    'switch row': () => GatesSwitchRow(
      label: 'Mostrar visitas frecuentes',
      value: true,
      onChanged: (_) {},
    ),
    'swipe to confirm': () =>
        SwipeToConfirm(label: 'Desliza para cancelar', onConfirmed: () {}),
    'add button': () =>
        GatesAddButton(semanticLabel: 'Nueva visita', onTap: () {}),
  };

  for (final scale in [1.0, 2.0, 3.0]) {
    for (final entry in controls.entries) {
      testWidgets('${entry.key} fits at ${scale}x text', (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.light(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: entry.value(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });
    }
  }
}
