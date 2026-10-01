import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/features/visits/presentation/visits_list_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
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

  Future<void> pump(
    WidgetTester tester,
    FakeVisitsRepository repo, {
    List<String>? visited,
    ThemeMode mode = ThemeMode.light,
    bool settle = true,
  }) => pumpApp(
    tester,
    const VisitsListScreen(),
    mode: mode,
    settle: settle,
    visited: visited,
    overrides: [
      ...membershipOverrides(),
      visitsRepositoryProvider.overrideWithValue(repo),
    ],
    routes: {
      '/visits/new': (_) => const Text('NEW'),
      '/visits/:id/access': (s) => Text('ACCESS ${s.pathParameters['id']}'),
      '/visits/:id': (s) => Text('PENDING ${s.pathParameters['id']}'),
    },
  );

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('shows loading, then the pending visits grouped by day', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([
      makeVisit(id: 'a', name: 'Rappi'),
      makeVisit(id: 'b', name: 'Amazon', day: 1, hour: 9),
      makeVisit(id: 'c', name: 'Lejano', day: 7, hour: 9),
      makeVisit(
        id: 'd',
        name: null,
        type: VisitType.fastlane,
        status: VisitStatus.pendingRegistration,
        providerKind: null,
      ),
    ]);
    await pump(tester, repo);

    expect(find.text(l10n.visitsListTitle), findsOneWidget);
    expect(find.text('Rappi'), findsOneWidget);
    expect(find.text('Amazon'), findsOneWidget);
    expect(find.text('Lejano'), findsOneWidget);
    // Fastlane invitation without a name yet.
    expect(find.text(l10n.visitsPendingInvitationName), findsOneWidget);
    // Date group headings: today and tomorrow are named.
    expect(find.textContaining('Accesos para hoy ·'), findsOneWidget);
    expect(
      find.textContaining(RegExp(r'^Mañana · \d{1,2} \w+\.$')),
      findsOneWidget,
    );
    // Status pills.
    expect(find.text(l10n.visitsStatusScheduled), findsNWidgets(3));
    expect(find.text(l10n.visitsStatusPendingRegistration), findsOneWidget);
    // Subtitles by type.
    expect(find.text(l10n.visitsListSubtitleFastlane), findsOneWidget);
    expect(
      find.text(
        l10n.visitsListSubtitleDeliveryKind(
          providerKindLabel(l10n, ProviderKind.delivery),
        ),
      ),
      findsNWidgets(3),
    );
    expect(find.text(l10n.visitsListDailyVisit), findsNWidgets(4));
  });

  testWidgets('loading view while the stream has not emitted', (tester) async {
    final repo = FakeVisitsRepository()..neverEmit = true;
    await pump(tester, repo, settle: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    // Tabs are hidden until data arrives.
    expect(find.text(l10n.visitsTabOngoing), findsNothing);
  });

  testWidgets('error state shows the cause and retry reloads', (tester) async {
    final repo = FakeVisitsRepository()..watchError = const AuthFailure();
    await pump(tester, repo);

    expect(
      find.text('${l10n.commonErrorSession} ${l10n.visitsListLoadError}'),
      findsOneWidget,
    );
    final before = repo.watchCalls;
    repo.watchError = null;
    await tester.tap(find.text(l10n.commonRetry));
    await tester.pumpAndSettle();
    expect(repo.watchCalls, greaterThan(before));
    expect(find.text(l10n.visitsListEmptyPending), findsOneWidget);
  });

  testWidgets('empty states per tab', (tester) async {
    await pump(tester, FakeVisitsRepository());
    expect(find.text(l10n.visitsListEmptyPending), findsOneWidget);
    await tapTab(tester, l10n.visitsTabOngoing);
    expect(find.text(l10n.visitsListEmptyOngoing), findsOneWidget);
    await tapTab(tester, l10n.visitsTabHistory);
    expect(find.text(l10n.visitsListEmptyHistory), findsOneWidget);
  });

  testWidgets('tabs filter by status; history is newest first', (tester) async {
    final repo = FakeVisitsRepository([
      makeVisit(id: 'p', name: 'Pendiente'),
      makeVisit(id: 'o', name: 'Persona dentro', status: VisitStatus.inside),
      makeVisit(id: 'o2', name: 'Persona activa', status: VisitStatus.active),
      makeVisit(
        id: 'h1',
        name: 'Viejo',
        status: VisitStatus.completed,
        day: -3,
      ),
      makeVisit(
        id: 'h2',
        name: 'Reciente',
        status: VisitStatus.cancelled,
        day: -1,
      ),
    ]);
    await pump(tester, repo);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Persona dentro'), findsNothing);

    await tapTab(tester, l10n.visitsTabOngoing);
    expect(find.text('Persona dentro'), findsOneWidget);
    expect(find.text('Persona activa'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);

    await tapTab(tester, l10n.visitsTabHistory);
    expect(find.text('Viejo'), findsOneWidget);
    expect(find.text('Reciente'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Reciente')).dy,
      lessThan(tester.getTopLeft(find.text('Viejo')).dy),
    );
    expect(find.text(l10n.visitsStatusCancelled), findsOneWidget);
    expect(find.text(l10n.visitsStatusCompleted), findsOneWidget);
  });

  testWidgets('frequent accesses are hidden until the switch is on', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([
      makeVisit(
        id: 'f',
        name: 'María',
        type: VisitType.frequent,
        providerKind: null,
        role: VisitorRole.familiar,
        recurrence: Recurrence.monFri,
        scheduleType: ScheduleType.allDay,
      ),
      makeVisit(
        id: 'f2',
        name: 'Sin rol',
        type: VisitType.frequent,
        providerKind: null,
      ),
    ]);
    await pump(tester, repo);

    expect(find.text('María'), findsNothing);
    expect(find.text(l10n.visitsListHiddenFrequent(2)), findsNothing);
    expect(
      find.textContaining(l10n.visitsListHiddenFrequent(2)),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.visitsListShowFrequent));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsListFrequentHeading), findsOneWidget);
    expect(find.text('María'), findsOneWidget);
    expect(
      find.text(visitorRoleLabel(l10n, VisitorRole.familiar)),
      findsOneWidget,
    );
    expect(
      find.text(
        '${recurrenceLabel(l10n, Recurrence.monFri)} · ${l10n.visitsAllDay}',
      ),
      findsOneWidget,
    );
    // No status pill for frequent visits on the pending tab.
    expect(find.text(l10n.visitsStatusScheduled), findsNothing);
    // Role-less visit falls back to the type label.
    expect(find.text(l10n.visitsTypeFrequent), findsWidgets);
  });

  testWidgets('hidden-frequent hint uses the singular plural form', (
    tester,
  ) async {
    await pump(
      tester,
      FakeVisitsRepository([
        makeVisit(id: 'f', type: VisitType.frequent, providerKind: null),
      ]),
    );
    expect(
      find.textContaining(l10n.visitsListHiddenFrequent(1)),
      findsOneWidget,
    );
  });

  testWidgets('frequent card on the ongoing tab shows its status pill', (
    tester,
  ) async {
    await pump(
      tester,
      FakeVisitsRepository([
        makeVisit(
          id: 'f',
          name: 'Entrenador',
          type: VisitType.frequent,
          status: VisitStatus.inside,
          providerKind: null,
        ),
      ]),
    );
    await tapTab(tester, l10n.visitsTabOngoing);
    await tester.tap(find.text(l10n.visitsListShowFrequent));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsStatusInside), findsOneWidget);
  });

  testWidgets('add button pushes /visits/new', (tester) async {
    final visited = <String>[];
    await pump(tester, FakeVisitsRepository(), visited: visited);
    await tester.tap(find.bySemanticsLabel(l10n.visitsListNewVisit));
    await tester.pumpAndSettle();
    expect(visited, ['/visits/new']);
    expect(find.text('NEW'), findsOneWidget);
  });

  testWidgets('card taps route by type and status', (tester) async {
    final visited = <String>[];
    final repo = FakeVisitsRepository([
      makeVisit(
        id: 'fl',
        name: 'Invitado',
        type: VisitType.fastlane,
        status: VisitStatus.pendingRegistration,
        providerKind: null,
      ),
      makeVisit(
        id: 'fr',
        name: 'Don Pepe',
        type: VisitType.frequent,
        providerKind: null,
      ),
    ]);
    await pump(tester, repo, visited: visited);
    await tester.tap(find.text('Invitado'));
    await tester.pumpAndSettle();
    expect(visited.last, '/visits/fl');
  });

  testWidgets('frequent card tap opens the access screen', (tester) async {
    final visited = <String>[];
    await pump(
      tester,
      FakeVisitsRepository([
        makeVisit(
          id: 'fr',
          name: 'Don Pepe',
          type: VisitType.frequent,
          providerKind: null,
        ),
      ]),
      visited: visited,
    );
    await tester.tap(find.text(l10n.visitsListShowFrequent));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Don Pepe'));
    await tester.pumpAndSettle();
    expect(visited.last, '/visits/fr/access');
  });

  testWidgets('tapping a scheduled delivery opens the detail sheet', (
    tester,
  ) async {
    await pump(
      tester,
      FakeVisitsRepository([makeVisit(id: 'd', name: 'Rappi')]),
    );
    await tester.tap(find.text('Rappi'));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsDetailTitle), findsOneWidget);
    expect(find.text(l10n.visitsCancelVisit), findsOneWidget);
    expect(find.text('A-204'), findsOneWidget);
  });

  testWidgets('realtime update moves a visit between tabs', (tester) async {
    final repo = FakeVisitsRepository([makeVisit(id: 'd', name: 'Rappi')]);
    await pump(tester, repo);
    expect(find.text('Rappi'), findsOneWidget);
    repo.emit([makeVisit(id: 'd', name: 'Rappi', status: VisitStatus.inside)]);
    await tester.pumpAndSettle();
    expect(find.text('Rappi'), findsNothing);
    await tapTab(tester, l10n.visitsTabOngoing);
    expect(find.text('Rappi'), findsOneWidget);
  });

  testWidgets('pull to refresh re-subscribes', (tester) async {
    final repo = FakeVisitsRepository([makeVisit(id: 'd', name: 'Rappi')]);
    await pump(tester, repo);
    final before = repo.watchCalls;
    await tester.fling(find.text('Rappi'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(repo.watchCalls, greaterThan(before));
  });

  testWidgets('renders in dark mode with all card kinds', (tester) async {
    final repo = FakeVisitsRepository([
      makeVisit(id: '1', name: 'A'),
      makeVisit(
        id: '2',
        name: 'B',
        type: VisitType.fastlane,
        status: VisitStatus.pendingRegistration,
      ),
      makeVisit(id: '3', name: 'C', status: VisitStatus.active),
      makeVisit(id: '4', name: 'D', status: VisitStatus.rejected),
    ]);
    await pump(tester, repo, mode: ThemeMode.dark);
    expect(find.text('A'), findsOneWidget);
    await tapTab(tester, l10n.visitsTabOngoing);
    expect(find.text('C'), findsOneWidget);
    await tapTab(tester, l10n.visitsTabHistory);
    expect(find.text('D'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('delivery without a kind uses the generic subtitle; expired '
      'visits live in history', (tester) async {
    await pump(
      tester,
      FakeVisitsRepository([
        makeVisit(id: 'g', name: 'Algo', providerKind: null),
        makeVisit(
          id: 'e',
          name: 'Vencida',
          status: VisitStatus.expired,
          day: -2,
        ),
      ]),
    );
    expect(find.text(l10n.visitsDeliveryOrProvider), findsOneWidget);
    await tapTab(tester, l10n.visitsTabHistory);
    expect(find.text('Vencida'), findsOneWidget);
    expect(find.text(l10n.visitsStatusExpired), findsOneWidget);
  });

  testWidgets('coming back from "new visit" refreshes the list', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await pump(tester, repo);
    final before = repo.watchCalls;
    await tester.tap(find.bySemanticsLabel(l10n.visitsListNewVisit));
    await tester.pumpAndSettle();
    expect(find.text('NEW'), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    expect(repo.watchCalls, greaterThan(before));
  });

  testWidgets('without a selected membership only a spinner shows', (
    tester,
  ) async {
    await pumpApp(
      tester,
      const VisitsListScreen(),
      settle: false,
      overrides: [
        selectedMembershipProvider.overrideWith(
          () => FakeSelectedMembership(null),
        ),
        visitsRepositoryProvider.overrideWithValue(FakeVisitsRepository()),
      ],
    );
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(l10n.visitsListTitle), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
