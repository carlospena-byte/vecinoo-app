import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/create_frequent_visit_screen.dart';
import 'package:gates_app/features/visits/presentation/frequent_visit_formatters.dart';

void main() {
  setUpAll(() => initializeDateFormatting('es'));

  Widget app() => ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const CreateFrequentVisitScreen(),
    ),
  );

  testWidgets('step 1 requires the name and the ID document', (tester) async {
    await tester.pumpWidget(app());

    expect(find.text('1 de 2 · Datos de la visita'), findsOneWidget);
    expect(find.text('Documento de identidad *'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(find.text('Escribe el nombre de la visita.'), findsOneWidget);
    expect(find.text('2 de 2 · Permisos de acceso'), findsNothing);

    await tester.enterText(find.byType(TextField).first, 'María García');
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    // Still on step 1: the document is mandatory.
    expect(
      find.text('Adjunta una foto del documento para continuar.'),
      findsOneWidget,
    );
  });

  testWidgets('vehicle switch enables the plate field', (tester) async {
    // Tall enough for the lazy ListView to build the plate field.
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(app());

    TextField plate() => tester.widget<TextField>(find.byType(TextField).last);
    expect(plate().enabled, isFalse);

    await tester.tap(find.text('Ingresará en vehículo'));
    await tester.pump();
    expect(plate().enabled, isTrue);
  });

  testWidgets('editing prefills the form and keeps the current document', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final visit = Visit(
      id: '1',
      unitId: 'u',
      name: 'María García',
      phone: '+50499998888',
      status: VisitStatus.scheduled,
      visitType: VisitType.frequent,
      visitorRole: VisitorRole.empleado,
      recurrence: Recurrence.monFri,
      scheduleType: ScheduleType.allDay,
      hasVehicle: true,
      plate: 'HAB1234',
      idPhotoPath: 'r/frequent-1.jpg',
      validFrom: DateTime(2026),
      validUntil: DateTime(2099),
      createdAt: DateTime(2026),
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.light(),
          home: CreateFrequentVisitScreen(editing: visit),
        ),
      ),
    );

    expect(find.text('María García'), findsOneWidget);
    expect(find.text('99998888'), findsOneWidget);
    expect(find.text('HAB1234'), findsOneWidget);
    expect(find.text('Documento actual'), findsOneWidget);

    // Nothing to re-upload: Continuar goes straight to step 2.
    await tester.tap(find.text('Continuar'));
    await tester.pump();
    expect(find.text('Guardar cambios'), findsOneWidget);
  });

  test('frequentScheduleSummary describes presets and custom blocks', () {
    final base = Visit(
      id: '1',
      unitId: 'u',
      status: VisitStatus.scheduled,
      visitType: VisitType.frequent,
      recurrence: Recurrence.monFri,
      scheduleType: ScheduleType.allDay,
      validFrom: DateTime(2026),
      validUntil: DateTime(2099),
      createdAt: DateTime(2026),
    );
    expect(frequentScheduleSummary(base), 'Lunes a viernes · Todo el día');

    final custom = Visit(
      id: '2',
      unitId: 'u',
      status: VisitStatus.scheduled,
      visitType: VisitType.frequent,
      recurrence: Recurrence.custom,
      scheduleType: ScheduleType.custom,
      scheduleBlocks: const [
        ScheduleBlock(
          days: {'mon', 'wed'},
          start: TimeOfDay(hour: 8, minute: 0),
          end: TimeOfDay(hour: 22, minute: 0),
        ),
      ],
      validFrom: DateTime(2026),
      validUntil: DateTime(2099),
      createdAt: DateTime(2026),
    );
    expect(frequentScheduleSummary(custom), contains('Lun, Mié · '));
  });
}
