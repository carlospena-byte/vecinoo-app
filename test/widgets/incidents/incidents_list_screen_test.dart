import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incidents_list_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  final l10n = AppLocalizationsEs();

  final incidents = [
    makeIncident(
      id: 'a',
      title: 'Pendiente vieja',
      typeName: 'Ruido',
      createdAt: DateTime(2026, 1, 1),
    ),
    makeIncident(
      id: 'b',
      title: 'Pendiente nueva',
      createdAt: DateTime(2026, 2, 1),
    ),
    makeIncident(
      id: 'c',
      title: 'En curso uno',
      status: IncidentStatus.inProgress,
    ),
    makeIncident(
      id: 'd',
      title: 'Fuga resuelta',
      status: IncidentStatus.resolved,
    ),
    makeIncident(
      id: 'e',
      title: 'Ruido cerrado',
      status: IncidentStatus.closed,
    ),
    makeIncident(
      id: 'f',
      title: 'Visita cancelada',
      status: IncidentStatus.cancelled,
    ),
  ];

  Future<FakeIncidentsRepository> pump(
    WidgetTester tester, {
    List<Incident>? data,
    Object? error,
    ThemeMode mode = ThemeMode.light,
    List<String>? visited,
  }) async {
    final repo = FakeIncidentsRepository()
      ..incidents = data ?? incidents
      ..listError = error;
    await pumpApp(
      tester,
      const IncidentsListScreen(),
      overrides: incidentOverrides(repo),
      mode: mode,
      visited: visited,
      routes: {
        '/incidents/report': (_) => const Text('REPORT'),
        '/incidents/:id': (s) => Text('DETAIL ${s.pathParameters['id']}'),
      },
    );
    return repo;
  }

  testWidgets('pending tab lists new incidents, newest first', (tester) async {
    await pump(tester);

    expect(find.text(l10n.incidentsListTitle), findsOneWidget);
    expect(find.text('Pendiente nueva'), findsOneWidget);
    expect(find.text('Pendiente vieja'), findsOneWidget);
    expect(find.text('En curso uno'), findsNothing);
    expect(find.text('Ruido'), findsOneWidget);
    expect(find.text(l10n.incidentsStatusNew), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.text('Pendiente nueva')).dy,
      lessThan(tester.getTopLeft(find.text('Pendiente vieja')).dy),
    );
  });

  testWidgets('tabs filter in progress and history', (tester) async {
    await pump(tester);

    await tester.tap(find.text(l10n.incidentsTabInProgress));
    await tester.pumpAndSettle();
    expect(find.text('En curso uno'), findsOneWidget);
    expect(find.text('Pendiente nueva'), findsNothing);

    await tester.tap(find.text(l10n.incidentsTabHistory));
    await tester.pumpAndSettle();
    expect(find.text('Fuga resuelta'), findsOneWidget);
    expect(find.text('Ruido cerrado'), findsOneWidget);
    expect(find.text('Visita cancelada'), findsOneWidget);
    expect(find.text('En curso uno'), findsNothing);
  });

  testWidgets('empty tabs show their own message', (tester) async {
    await pump(tester, data: const []);
    expect(find.text(l10n.incidentsListEmptyPending), findsOneWidget);

    await tester.tap(find.text(l10n.incidentsTabInProgress));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsListEmptyInProgress), findsOneWidget);

    await tester.tap(find.text(l10n.incidentsTabHistory));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsListEmptyHistory), findsOneWidget);
  });

  testWidgets('load error shows a retry that refetches', (tester) async {
    final repo = await pump(tester, error: const NetworkFailure());
    expect(find.text(l10n.incidentsListLoadError), findsOneWidget);
    // Tabs are hidden while there is no data.
    expect(find.text(l10n.incidentsTabHistory), findsNothing);
    final before = repo.listFetches;

    repo.listError = null;
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(repo.listFetches, greaterThan(before));
    expect(find.text('Pendiente nueva'), findsOneWidget);
  });

  testWidgets('tapping a card opens its detail and refetches on return', (
    tester,
  ) async {
    final visited = <String>[];
    final repo = await pump(tester, visited: visited);
    final before = repo.listFetches;

    await tester.tap(find.text('Pendiente nueva'));
    await tester.pumpAndSettle();
    expect(visited, ['/incidents/b']);
    expect(find.text('DETAIL b'), findsOneWidget);

    Navigator.of(tester.element(find.text('DETAIL b'))).pop();
    await tester.pumpAndSettle();
    expect(repo.listFetches, greaterThan(before));
  });

  testWidgets('the add button opens the report flow', (tester) async {
    final visited = <String>[];
    await pump(tester, visited: visited);

    await tester.tap(find.bySemanticsLabel(l10n.incidentsReportAction));
    await tester.pumpAndSettle();
    expect(visited, ['/incidents/report']);
  });

  testWidgets('pull to refresh refetches', (tester) async {
    final repo = await pump(tester);
    final before = repo.listFetches;
    await tester.fling(
      find.text('Pendiente nueva'),
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();
    expect(repo.listFetches, greaterThan(before));
  });

  testWidgets('renders in dark mode', (tester) async {
    await pump(tester, mode: ThemeMode.dark);
    expect(find.text('Pendiente nueva'), findsOneWidget);
    await tester.tap(find.text(l10n.incidentsTabHistory));
    await tester.pumpAndSettle();
    expect(find.text('Visita cancelada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('status badge renders every status', (tester) async {
    await pumpApp(
      tester,
      Scaffold(
        body: Column(
          children: [
            for (final s in IncidentStatus.values)
              IncidentStatusBadge(status: s),
          ],
        ),
      ),
    );
    expect(find.text(l10n.incidentsStatusResolved), findsOneWidget);
    expect(find.text(l10n.incidentsStatusClosed), findsOneWidget);
    expect(find.text(l10n.incidentsStatusInProgress), findsOneWidget);
  });
}
