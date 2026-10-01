import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/create_fastlane_visit_screen.dart';
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

  Visit editable() => makeVisit(
    id: 'fl-9',
    name: 'Tía Rosa',
    type: VisitType.fastlane,
    status: VisitStatus.pendingRegistration,
    providerKind: null,
    notes: 'Trae un perro',
    accessCode: 'CODE9',
    day: 2,
    hour: 16,
  );

  /// Pushed from a home so `context.pop` works; the home also keeps the
  /// membership provider alive like the real app does.
  Future<List<String>> open(
    WidgetTester tester,
    FakeVisitsRepository repo, {
    Visit? editing,
    ThemeMode mode = ThemeMode.light,
  }) async {
    final visited = <String>[];
    await pumpApp(
      tester,
      Consumer(
        builder: (context, ref, _) {
          ref.watch(selectedMembershipProvider);
          return Scaffold(
            body: TextButton(
              onPressed: () => context.push('/form'),
              child: const Text('open'),
            ),
          );
        },
      ),
      mode: mode,
      visited: visited,
      overrides: [
        ...membershipOverrides(),
        visitsRepositoryProvider.overrideWithValue(repo),
      ],
      routes: {
        '/form': (_) => CreateFastlaneVisitScreen(editing: editing),
        '/visits/:id': (s) => Text('SHARE ${s.pathParameters['id']}'),
      },
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return visited;
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pumpAndSettle();
  }

  testWidgets('create form shows unit, today and notes area', (tester) async {
    await open(tester, FakeVisitsRepository(), mode: ThemeMode.dark);
    expect(find.text(l10n.visitsFastlaneTitle), findsOneWidget);
    expect(find.text(l10n.visitsUnitUpper), findsOneWidget);
    expect(find.text('A-204 · Los Olivos'), findsOneWidget);
    expect(find.text(l10n.visitsFastlaneNameLabel), findsOneWidget);
    expect(find.textContaining('Hoy,'), findsOneWidget);
    expect(find.text(l10n.visitsFastlaneDateHelper), findsOneWidget);
    expect(find.text(l10n.visitsFastlaneCreate), findsOneWidget);
  });

  testWidgets('name is required before creating', (tester) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo);
    await submit(tester, l10n.visitsFastlaneCreate);
    expect(find.text(l10n.visitsFastlaneNameRequired), findsOneWidget);
    expect(repo.fastlaneCreated, isEmpty);

    await tester.enterText(find.byType(TextField).first, '   ');
    await submit(tester, l10n.visitsFastlaneCreate);
    expect(find.text(l10n.visitsFastlaneNameRequired), findsOneWidget);
    expect(repo.fastlaneCreated, isEmpty);
  });

  testWidgets('creating opens the share screen for the new invitation', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    final visited = await open(tester, repo);
    await tester.enterText(find.byType(TextField).first, '  Juan Pérez ');
    await tester.enterText(find.byType(TextField).last, ' Llega en moto ');
    await submit(tester, l10n.visitsFastlaneCreate);

    expect(repo.fastlaneCreated.single.name, 'Juan Pérez');
    expect(repo.fastlaneCreated.single.notes, 'Llega en moto');
    expect(visited, contains('/visits/new-1?created=1'));
    expect(find.text('SHARE new-1'), findsOneWidget);
  });

  testWidgets('empty notes are sent as null', (tester) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'Ana');
    await submit(tester, l10n.visitsFastlaneCreate);
    expect(repo.fastlaneCreated.single.notes, isNull);
  });

  testWidgets('create failure shows the cause and keeps the form', (
    tester,
  ) async {
    final repo = FakeVisitsRepository()..error = const NetworkFailure();
    await open(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'Ana');
    await submit(tester, l10n.visitsFastlaneCreate);
    expect(find.text(l10n.visitsFastlaneCreateError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorNetwork} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    expect(find.text('Ana'), findsOneWidget);
  });

  testWidgets('button shows a spinner while saving', (tester) async {
    final repo = FakeVisitsRepository()..gate = Completer<void>();
    await open(tester, repo);
    await tester.enterText(find.byType(TextField).first, 'Ana');
    await tester.tap(find.text(l10n.visitsFastlaneCreate));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text(l10n.visitsFastlaneCreate), findsNothing);
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.fastlaneCreated, hasLength(1));
  });

  testWidgets('date picker changes the shown date', (tester) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.text(l10n.visitsFastlaneVisitDate));
    await tester.pumpAndSettle();
    await pickNextMonthDay15(tester, l10n.commonContinue);
    expect(find.textContaining('Hoy,'), findsNothing);
    expect(find.textContaining('15 '), findsWidgets);
  });

  testWidgets('arrival time picker confirms and cancels', (tester) async {
    await open(tester, FakeVisitsRepository());
    await tester.tap(find.text(l10n.visitsFastlaneArrivalLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonDone));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.visitsFastlaneArrivalLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.commonCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsFastlaneCreate), findsOneWidget);
  });

  testWidgets('editing prefills and saves through updateFastlaneVisit', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo, editing: editable());

    expect(find.text(l10n.visitsPendingEdit), findsOneWidget);
    expect(find.text('Tía Rosa'), findsOneWidget);
    expect(find.text('Trae un perro'), findsOneWidget);
    expect(find.textContaining('4:00'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, 'Tía Rosa M.');
    await submit(tester, l10n.visitsSaveChanges);

    expect(repo.fastlaneUpdated.single.id, 'fl-9');
    expect(repo.fastlaneUpdated.single.name, 'Tía Rosa M.');
    expect(repo.fastlaneUpdated.single.notes, 'Trae un perro');
    expect(repo.fastlaneCreated, isEmpty);
    // Back on the home with a success toast.
    expect(find.text('open'), findsOneWidget);
    expect(find.text(l10n.visitsFastlaneUpdatedToast), findsOneWidget);
  });

  testWidgets('update failure toasts the save error', (tester) async {
    final repo = FakeVisitsRepository()..error = const ServerFailure();
    await open(tester, repo, editing: editable());
    await submit(tester, l10n.visitsSaveChanges);
    expect(find.text(l10n.visitsSaveError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorServer} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    expect(find.text(l10n.visitsSaveChanges), findsOneWidget);
  });
}
