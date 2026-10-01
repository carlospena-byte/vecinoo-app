import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/visit_detail_sheet.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
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

  Future<void> open(
    WidgetTester tester,
    Visit visit,
    FakeVisitsRepository repo, {
    ThemeMode mode = ThemeMode.light,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => showVisitDetailSheet(
                context,
                visit: visit,
                unitName: 'A-204',
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      mode: mode,
      overrides: [visitsRepositoryProvider.overrideWithValue(repo)],
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows who, unit, same-day validity and status banner', (
    tester,
  ) async {
    final visit = makeVisit(
      name: 'Rappi',
      plate: 'ABC123',
      notes: '  Dejar en portería  ',
    );
    await open(tester, visit, FakeVisitsRepository());

    expect(find.text(l10n.visitsDetailTitle), findsOneWidget);
    expect(find.text(l10n.visitsStatusScheduled), findsOneWidget);
    expect(find.text('Rappi'), findsOneWidget);
    expect(
      find.text(providerKindLabel(l10n, ProviderKind.delivery).toUpperCase()),
      findsOneWidget,
    );
    expect(find.text('A-204'), findsOneWidget);
    expect(
      find.text(l10n.visitsDetailValiditySameDay('Hoy', '14:00', '23:59')),
      findsOneWidget,
    );
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('Dejar en portería'), findsOneWidget);
    expect(find.textContaining('${DateTime.now().year}'), findsOneWidget);
  });

  testWidgets('multi-day validity and non-current year are spelled out', (
    tester,
  ) async {
    final visit = makeVisit(
      validFrom: DateTime(2020, 3, 5, 8),
      validUntil: DateTime(2020, 3, 7, 18, 30),
      status: VisitStatus.completed,
    );
    await open(tester, visit, FakeVisitsRepository());
    expect(
      find.text(
        l10n.visitsDetailValidityRange(
          '5 mar. 2020 08:00',
          '7 mar. 2020 18:30',
        ),
      ),
      findsOneWidget,
    );
    // Not cancellable once completed.
    expect(find.text(l10n.visitsCancelVisit), findsNothing);
    expect(find.text('Rappi'), findsOneWidget);
  });

  testWidgets('tomorrow label, fastlane/frequent kinds and nameless visit', (
    tester,
  ) async {
    await open(
      tester,
      makeVisit(
        name: null,
        type: VisitType.fastlane,
        status: VisitStatus.pendingRegistration,
        day: 1,
        providerKind: null,
      ),
      FakeVisitsRepository(),
    );
    expect(find.text(l10n.visitsPendingInvitationName), findsOneWidget);
    expect(
      find.text(l10n.visitsListSubtitleFastlane.toUpperCase()),
      findsOneWidget,
    );
    expect(
      find.text(l10n.visitsDetailValiditySameDay('Mañana', '14:00', '23:59')),
      findsOneWidget,
    );
    expect(find.text(l10n.visitsCancelVisit), findsOneWidget);
  });

  testWidgets('frequent type label and rejected banner without cancel', (
    tester,
  ) async {
    await open(
      tester,
      makeVisit(
        type: VisitType.frequent,
        status: VisitStatus.rejected,
        providerKind: null,
      ),
      FakeVisitsRepository(),
      mode: ThemeMode.dark,
    );
    expect(find.text(l10n.visitsTypeFrequent.toUpperCase()), findsOneWidget);
    expect(find.text(l10n.visitsStatusRejected), findsOneWidget);
    expect(find.text(l10n.visitsCancelVisit), findsNothing);
  });

  testWidgets('delivery without provider kind defaults to delivery label', (
    tester,
  ) async {
    await open(
      tester,
      makeVisit(providerKind: null, status: VisitStatus.active),
      FakeVisitsRepository(),
    );
    expect(
      find.text(providerKindLabel(l10n, ProviderKind.delivery).toUpperCase()),
      findsOneWidget,
    );
  });

  testWidgets('confirming cancel closes the sheet with a success toast', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await open(tester, makeVisit(id: 'abc'), repo);
    await tester.tap(find.text(l10n.visitsCancelVisit));
    await tester.pumpAndSettle();

    expect(repo.cancelled, ['abc']);
    expect(find.text(l10n.visitsDetailTitle), findsNothing);
    expect(find.text(l10n.visitsDetailCancelledToast), findsOneWidget);
  });

  testWidgets('cancel shows loading and blocks a second tap', (tester) async {
    final repo = FakeVisitsRepository()..gate = Completer<void>();
    await open(tester, makeVisit(id: 'abc'), repo);
    await tester.tap(find.text(l10n.visitsCancelVisit));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.visitsCancelVisit), findsNothing);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.cancelled, ['abc']);
  });

  testWidgets('failure keeps the sheet and shows the cause in an error toast', (
    tester,
  ) async {
    final repo = FakeVisitsRepository()..error = const NetworkFailure();
    await open(tester, makeVisit(id: 'abc'), repo);
    await tester.tap(find.text(l10n.visitsCancelVisit));
    await tester.pumpAndSettle();

    expect(repo.cancelled, isEmpty);
    expect(find.text(l10n.visitsDetailTitle), findsOneWidget);
    expect(find.text(l10n.visitsDetailCancelError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorNetwork} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    // The button is usable again and can retry successfully.
    repo.error = null;
    await tester.tap(find.text(l10n.visitsCancelVisit));
    await tester.pumpAndSettle();
    expect(repo.cancelled, ['abc']);
  });

  testWidgets('unknown failure falls back to the plain retry hint', (
    tester,
  ) async {
    final repo = FakeVisitsRepository()..error = StateError('boom');
    await open(tester, makeVisit(), repo);
    await tester.tap(find.text(l10n.visitsCancelVisit));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsTryAgain), findsOneWidget);
  });
}
