import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/domain/access_movement.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/frequent_visit_detail_screen.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'visits_test_helpers.dart';

void main() {
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
  });

  final l10n = AppLocalizationsEs();

  Visit frequent({
    VisitStatus status = VisitStatus.scheduled,
    String? name = 'María García',
    VisitorRole? role = VisitorRole.empleado,
    bool hasVehicle = true,
    String? plate = 'HAB1234',
    Recurrence recurrence = Recurrence.monFri,
    List<ScheduleBlock>? blocks,
  }) => makeVisit(
    id: 'fr-1',
    name: name,
    type: VisitType.frequent,
    status: status,
    providerKind: null,
    role: role,
    recurrence: recurrence,
    scheduleType: ScheduleType.allDay,
    blocks: blocks,
    hasVehicle: hasVehicle,
    plate: plate,
  );

  Future<List<String>> open(
    WidgetTester tester,
    FakeVisitsRepository repo, {
    bool settle = true,
    ThemeMode mode = ThemeMode.light,
  }) async {
    final visited = <String>[];
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/frequent'),
            child: const Text('open'),
          ),
        ),
      ),
      mode: mode,
      visited: visited,
      overrides: [
        ...membershipOverrides(),
        visitsRepositoryProvider.overrideWithValue(repo),
      ],
      routes: {
        '/frequent': (_) => const FrequentVisitDetailScreen(visitId: 'fr-1'),
        '/visits/:id/access/edit': (s) =>
            Text('EDIT ${s.pathParameters['id']}'),
      },
    );
    await tester.tap(find.text('open'));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
    }
    return visited;
  }

  testWidgets('active access shows summary, vehicle and actions', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([frequent()]));

    expect(find.text(l10n.visitsFrequentActiveIntro), findsOneWidget);
    expect(
      find.text(
        l10n.visitsFrequentVisitCaptionRole(
          visitorRoleLabel(l10n, VisitorRole.empleado),
        ),
      ),
      findsOneWidget,
    );
    expect(find.text('María García'), findsOneWidget);
    expect(find.text(l10n.visitsFrequentActiveStatus), findsOneWidget);
    expect(find.text(l10n.visitsFrequentValidUntilCancelled), findsOneWidget);
    expect(
      find.text(
        '${recurrenceLabel(l10n, Recurrence.monFri)} · ${l10n.visitsAllDay}',
      ),
      findsOneWidget,
    );
    expect(find.text('A-204'), findsOneWidget);
    expect(find.text('HAB1234'), findsOneWidget);
    expect(find.text(l10n.visitsFrequentEditAccess), findsOneWidget);
    expect(find.text(l10n.visitsCancelAccess), findsOneWidget);
    // No movement yet.
    expect(find.text(l10n.visitsFrequentLastMovement), findsNothing);
  });

  testWidgets('shows the last gate movement when there is one', (tester) async {
    final repo = FakeVisitsRepository([frequent(status: VisitStatus.inside)])
      ..movement = AccessMovement(
        checkedInAt: DateTime.now().subtract(const Duration(minutes: 1)),
      );
    await open(tester, repo);
    expect(find.text(l10n.visitsFrequentLastMovement), findsOneWidget);
    expect(find.textContaining('Ingreso'), findsOneWidget);
    expect(find.textContaining(l10n.visitsMovementDayToday), findsOneWidget);
  });

  testWidgets('custom blocks list one line per block', (tester) async {
    await open(
      tester,
      FakeVisitsRepository([
        frequent(
          recurrence: Recurrence.custom,
          blocks: const [
            ScheduleBlock(
              days: {'mon', 'tue'},
              start: TimeOfDay(hour: 8, minute: 0),
              end: TimeOfDay(hour: 10, minute: 0),
            ),
            ScheduleBlock(
              days: {'sat'},
              start: TimeOfDay(hour: 9, minute: 0),
              end: TimeOfDay(hour: 12, minute: 0),
            ),
          ],
        ),
      ]),
    );
    expect(find.textContaining('Lun, Mar · '), findsOneWidget);
    expect(find.textContaining('Sáb · '), findsOneWidget);
  });

  testWidgets('no role, name or plate falls back to defaults', (tester) async {
    await open(
      tester,
      FakeVisitsRepository([
        frequent(name: null, role: null, hasVehicle: false, plate: null),
      ]),
    );
    expect(find.text(l10n.visitsFrequentVisitCaption), findsOneWidget);
    expect(find.text(l10n.visitsFrequentNoName), findsOneWidget);
    expect(find.text(l10n.visitsFrequentVehicle), findsNothing);
  });

  testWidgets('inactive access hides the actions and shows its status', (
    tester,
  ) async {
    await open(
      tester,
      FakeVisitsRepository([frequent(status: VisitStatus.cancelled)]),
      mode: ThemeMode.dark,
    );
    expect(find.text(l10n.visitsFrequentInactiveIntro), findsOneWidget);
    expect(find.text(l10n.visitsStatusCancelled), findsOneWidget);
    expect(find.text(l10n.visitsCancelAccess), findsNothing);
    expect(find.text(l10n.visitsFrequentEditAccess), findsNothing);
    expect(find.text(l10n.visitsFrequentValidUntilCancelled), findsNothing);
  });

  testWidgets('edit pushes the edit route', (tester) async {
    final visited = await open(tester, FakeVisitsRepository([frequent()]));
    await tester.tap(find.text(l10n.visitsFrequentEditAccess));
    await tester.pumpAndSettle();
    expect(visited, contains('/visits/fr-1/access/edit'));
  });

  testWidgets('loading while the row has not arrived', (tester) async {
    await open(tester, FakeVisitsRepository()..neverEmit = true, settle: false);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.visitsFrequentAccess), findsOneWidget);
  });

  testWidgets('error with cause and retry', (tester) async {
    final repo = FakeVisitsRepository()..watchError = const AuthFailure();
    await open(tester, repo);
    expect(
      find.text('${l10n.commonErrorSession} ${l10n.visitsFrequentLoadError}'),
      findsOneWidget,
    );
    repo
      ..watchError = null
      ..emit([frequent()]);
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(find.text('María García'), findsOneWidget);
  });

  testWidgets('cancel access: confirm sheet names the visit, then toasts', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([frequent()])
      ..latency = const Duration(milliseconds: 500);
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsCancelAccess));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.visitsFrequentCancelBody('María García')),
      findsOneWidget,
    );
    await tester.tap(find.text(l10n.visitsFrequentCancelConfirm));
    await tester.pumpAndSettle();

    expect(repo.cancelledFrequent, ['fr-1']);
    expect(repo.cancelled, isEmpty);
    expect(find.text(l10n.visitsFrequentCancelledToast), findsOneWidget);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancel body uses the default name when unnamed', (tester) async {
    await open(tester, FakeVisitsRepository([frequent(name: null)]));
    await tester.tap(find.text(l10n.visitsCancelAccess));
    await tester.pumpAndSettle();
    expect(
      find.text(l10n.visitsFrequentCancelBody(l10n.visitsFrequentDefaultName)),
      findsOneWidget,
    );
  });

  testWidgets('cancel failure keeps the screen and toasts the cause', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([frequent()])
      ..error = const NetworkFailure();
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsCancelAccess));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.visitsFrequentCancelConfirm));
    await tester.pumpAndSettle();

    expect(find.text(l10n.visitsFrequentCancelError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorNetwork} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    expect(find.text('María García'), findsOneWidget);
  });

  testWidgets('actions are disabled while cancelling', (tester) async {
    final repo = FakeVisitsRepository([frequent()])..gate = Completer<void>();
    final visited = await open(tester, repo);
    await tester.tap(find.text(l10n.visitsCancelAccess));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.visitsFrequentCancelConfirm));
    await tester.pumpAndSettle();
    await tester.tap(
      find.text(l10n.visitsFrequentEditAccess),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(visited, isNot(contains('/visits/fr-1/access/edit')));
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.cancelledFrequent, ['fr-1']);
  });

  testWidgets('dismissing the confirm sheet cancels nothing', (tester) async {
    final repo = FakeVisitsRepository([frequent()]);
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsCancelAccess));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(repo.cancelledFrequent, isEmpty);
  });
}
