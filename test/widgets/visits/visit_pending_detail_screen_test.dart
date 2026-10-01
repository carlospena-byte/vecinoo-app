import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/visit_pending_detail_screen.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'visits_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
    dotenv.loadFromString(envString: 'PUBLIC_APP_URL=https://app.test/');
  });

  final l10n = AppLocalizationsEs();
  final binding = TestDefaultBinaryMessengerBinding.instance;
  final shared = <Map<Object?, Object?>>[];
  final clipboard = <String?>[];

  setUp(() {
    shared.clear();
    clipboard.clear();
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      (call) async {
        shared.add(call.arguments as Map<Object?, Object?>);
        return 'dev.fluttercommunity.plus/share/success';
      },
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboard.add((call.arguments as Map)['text'] as String?);
        }
        return null;
      },
    );
  });

  tearDown(() {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/share'),
      null,
    );
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      null,
    );
  });

  Visit pending({String? code = 'CODE1', int day = 0, DateTime? from}) =>
      makeVisit(
        id: 'fl-1',
        name: 'Invitado',
        type: VisitType.fastlane,
        status: VisitStatus.pendingRegistration,
        providerKind: null,
        accessCode: code,
        day: day,
        validFrom: from,
      );

  /// Home with a button that pushes the screen, so `context.pop()` works.
  Future<List<String>> open(
    WidgetTester tester,
    FakeVisitsRepository repo, {
    Visit? initial,
    bool justCreated = false,
    bool settle = true,
    ThemeMode mode = ThemeMode.light,
  }) async {
    final visited = <String>[];
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: TextButton(
            onPressed: () => context.push('/pending'),
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
        '/pending': (_) => VisitPendingDetailScreen(
          visitId: 'fl-1',
          initialVisit: initial,
          justCreated: justCreated,
        ),
        '/visits/:id/edit': (s) => Text('EDIT ${s.pathParameters['id']}'),
      },
    );
    await tester.tap(find.text('open'));
    settle
        ? await tester.pumpAndSettle()
        : await tester.pump(const Duration(milliseconds: 100));
    return visited;
  }

  testWidgets('renders the summary card with arrival and share link', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending()]));

    expect(find.text(l10n.visitsPendingTitle), findsOneWidget);
    expect(find.text(l10n.visitsPendingIntro), findsOneWidget);
    expect(find.text(l10n.visitsPendingExpectedArrival), findsOneWidget);
    expect(find.textContaining('Hoy,'), findsOneWidget);
    expect(find.textContaining('2:00'), findsOneWidget);
    expect(find.text(l10n.visitsPendingDataStatus), findsOneWidget);
    expect(find.text('https://app.test/#fastlane/CODE1'), findsOneWidget);
    expect(find.text(l10n.visitsPendingShare), findsOneWidget);
    expect(find.text(l10n.visitsPendingCancel), findsOneWidget);
    expect(find.text(l10n.visitsPendingGoToVisits), findsNothing);
  });

  testWidgets('tomorrow and far dates (with year) in the arrival label', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending(day: 1)]));
    expect(find.textContaining('Mañana,'), findsOneWidget);
  });

  testWidgets('a date in another year shows the year', (tester) async {
    await open(
      tester,
      FakeVisitsRepository([pending(from: DateTime(2031, 1, 5, 9, 30))]),
    );
    expect(find.textContaining('5 ene. 2031 · 9:30'), findsOneWidget);
  });

  testWidgets('without an access code there is no link or share action', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending(code: null)]));
    expect(find.text(l10n.visitsPendingShare), findsNothing);
    expect(find.text(l10n.visitsPendingCopyLink), findsNothing);
    expect(find.text(l10n.visitsPendingLinkLabel), findsNothing);
  });

  testWidgets('copy link puts the URL on the clipboard and toasts', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending()]));
    await tester.tap(find.text(l10n.visitsPendingCopyLink));
    await tester.pumpAndSettle();
    expect(clipboard, ['https://app.test/#fastlane/CODE1']);
    expect(find.text(l10n.visitsPendingLinkCopied), findsOneWidget);
  });

  testWidgets('share sends title, arrival and link through the OS sheet', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending()]));
    await tester.tap(find.text(l10n.visitsPendingShare));
    await tester.pumpAndSettle();
    expect(shared, hasLength(1));
    final text = shared.single['text'] as String;
    expect(
      text,
      startsWith(l10n.visitsPendingShareTitleResidential('Los Olivos')),
    );
    expect(text, endsWith('https://app.test/#fastlane/CODE1'));
    expect(shared.single['subject'], contains('Los Olivos'));
  });

  testWidgets('edit pushes the edit route carrying the visit', (tester) async {
    final visited = await open(tester, FakeVisitsRepository([pending()]));
    await tester.tap(find.text(l10n.visitsPendingEdit));
    await tester.pumpAndSettle();
    expect(visited, contains('/visits/fl-1/edit'));
  });

  testWidgets('uses the initial visit until the stream has the row', (
    tester,
  ) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo, initial: pending());
    expect(find.text('https://app.test/#fastlane/CODE1'), findsOneWidget);
    // Row arrives (still pending) -> keeps showing.
    repo.emit([pending()]);
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsPendingTitle), findsOneWidget);
  });

  testWidgets('without any visit only a spinner shows', (tester) async {
    final repo = FakeVisitsRepository();
    await open(tester, repo, settle: false);
    expect(find.text(l10n.visitsPendingTitle), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('justCreated offers "go to my visits" instead of cancel', (
    tester,
  ) async {
    await open(tester, FakeVisitsRepository([pending()]), justCreated: true);
    expect(find.text(l10n.visitsPendingGoToVisits), findsOneWidget);
    expect(find.text(l10n.visitsPendingCancel), findsNothing);
    await tester.tap(find.text(l10n.visitsPendingGoToVisits));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
    expect(find.text(l10n.visitsPendingTitle), findsNothing);
  });

  testWidgets('when the visitor registers the screen pops itself', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([pending()]);
    await open(tester, repo);
    expect(find.text(l10n.visitsPendingTitle), findsOneWidget);
    repo.emit([
      makeVisit(id: 'fl-1', type: VisitType.fastlane, accessCode: 'CODE1'),
    ]);
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsPendingTitle), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancel: sheet confirm cancels, pops and toasts', (tester) async {
    final repo = FakeVisitsRepository([pending()])
      ..latency = const Duration(milliseconds: 500);
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsPendingCancel));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsPendingCancelBody), findsOneWidget);
    await tester.tap(find.text(l10n.visitsPendingCancelConfirm));
    await tester.pumpAndSettle();

    expect(repo.cancelled, ['fl-1']);
    expect(find.text('open'), findsOneWidget);
    expect(find.text(l10n.visitsPendingCancelledToast), findsOneWidget);
  });

  testWidgets('cancel: dismissing the sheet does nothing', (tester) async {
    final repo = FakeVisitsRepository([pending()])
      ..latency = const Duration(milliseconds: 500);
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsPendingCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(l10n.commonClose));
    await tester.pumpAndSettle();
    expect(repo.cancelled, isEmpty);
    expect(find.text(l10n.visitsPendingTitle), findsOneWidget);
  });

  testWidgets('cancel failure shows an error toast with the cause', (
    tester,
  ) async {
    final repo = FakeVisitsRepository([pending()])
      ..error = const ServerFailure();
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsPendingCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.visitsPendingCancelConfirm));
    await tester.pumpAndSettle();

    expect(find.text(l10n.visitsPendingCancelError), findsOneWidget);
    expect(
      find.text('${l10n.commonErrorServer} ${l10n.visitsTryAgain}'),
      findsOneWidget,
    );
    expect(find.text(l10n.visitsPendingTitle), findsOneWidget);
  });

  testWidgets('cancel button is disabled while cancelling', (tester) async {
    final repo = FakeVisitsRepository([pending()])..gate = Completer<void>();
    await open(tester, repo);
    await tester.tap(find.text(l10n.visitsPendingCancel));
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.visitsPendingCancelConfirm));
    await tester.pumpAndSettle();
    // Second tap on the (now disabled) action does not start another cancel.
    await tester.tap(
      find.text(l10n.visitsPendingCancel).first,
      warnIfMissed: false,
    );
    await tester.pump();
    repo.gate!.complete();
    await tester.pumpAndSettle();
    expect(repo.cancelled, ['fl-1']);
  });

  testWidgets('renders in dark mode', (tester) async {
    await open(tester, FakeVisitsRepository([pending()]), mode: ThemeMode.dark);
    expect(find.text(l10n.visitsPendingShare), findsOneWidget);
  });
}
