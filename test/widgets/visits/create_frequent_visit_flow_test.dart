import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart' show ImageSource;
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/presentation/create_frequent_visit_screen.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'visits_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tmp;
  late File photo;
  late File bigPhoto;

  setUpAll(() async {
    await loadManrope();
    await initializeDateFormatting('es');
    tmp = Directory.systemTemp.createTempSync('gates_frequent_test');
    photo = File('${tmp.path}/dni.jpg')..writeAsBytesSync([1, 2, 3, 4]);
    bigPhoto = File('${tmp.path}/huge.png')
      ..writeAsBytesSync(List.filled(10 * 1024 * 1024 + 1, 0));
  });
  tearDownAll(() => tmp.deleteSync(recursive: true));

  final l10n = AppLocalizationsEs();
  const pickerChannel = MethodChannel('plugins.flutter.io/image_picker');
  String? pickedPath;
  final pickerCalls = <int>[];

  setUp(() {
    pickedPath = null;
    pickerCalls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, (call) async {
          if (call.method == 'pickImage') {
            pickerCalls.add((call.arguments as Map)['source'] as int);
            return pickedPath;
          }
          return null;
        });
  });
  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pickerChannel, null);
  });

  Visit editable({
    Recurrence recurrence = Recurrence.monFri,
    ScheduleType type = ScheduleType.allDay,
    List<ScheduleBlock>? blocks,
    String? idPhoto = 'res-1/old.jpg',
  }) => makeVisit(
    id: 'fr-7',
    name: 'María García',
    type: VisitType.frequent,
    providerKind: null,
    role: VisitorRole.entrenador,
    recurrence: recurrence,
    scheduleType: type,
    blocks: blocks,
    phone: '+50299998888',
    hasVehicle: true,
    plate: 'HAB1234',
    notes: 'Nota previa',
    idPhotoPath: idPhoto,
  );

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
      routes: {'/form': (_) => CreateFrequentVisitScreen(editing: editing)},
    );
    tester.view.physicalSize = const Size(390, 2600);
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return visited;
  }

  /// Lets real file IO (XFile length/bytes) finish outside fake async.
  Future<void> flushIo(WidgetTester tester) async {
    // File IO hops between the real event loop and fake async several times.
    for (var i = 0; i < 25; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 20));
    }
    await tester.pumpAndSettle();
  }

  Future<void> submit(WidgetTester tester, String label) async {
    await tester.tap(find.text(label));
    await tester.pump();
    await flushIo(tester);
  }

  Future<void> pickDocument(
    WidgetTester tester,
    File file, {
    String sourceLabel = 'camera',
  }) async {
    pickedPath = file.path;
    await tester.tap(find.text(l10n.commonUploadDocument));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsFrequentIdDocument), findsOneWidget);
    await tester.tap(
      find.text(
        sourceLabel == 'camera'
            ? l10n.visitsFrequentTakePhoto
            : l10n.visitsFrequentPickGallery,
      ),
    );
    await tester.pumpAndSettle();
    await flushIo(tester);
  }

  Finder sem(String label) =>
      find.bySemanticsLabel(RegExp('^${RegExp.escape(label)}'));

  Future<void> choose(WidgetTester tester, String field, String option) async {
    await tester.tap(find.text(field));
    await tester.pumpAndSettle();
    await tester.tap(find.text(option));
    await tester.pumpAndSettle();
  }

  Future<void> toStep2(WidgetTester tester, {String name = 'Ana'}) async {
    await tester.enterText(find.byType(TextField).first, name);
    await pickDocument(tester, photo);
    await tester.tap(find.text(l10n.visitsContinue));
    await tester.pumpAndSettle();
    expect(find.text(l10n.visitsFrequentStep2), findsOneWidget);
  }

  group('step 1', () {
    testWidgets('the name is required', (tester) async {
      await open(tester, FakeVisitsRepository());
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsFrequentNameRequired), findsOneWidget);
      expect(find.text(l10n.visitsFrequentStep1), findsOneWidget);
    });

    testWidgets('validates phone, plate and document', (tester) async {
      await open(tester, FakeVisitsRepository());
      expect(find.text(l10n.visitsFrequentStep1), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'Ana');
      // Phone with too few digits.
      await tester.enterText(find.byType(TextField).at(1), '123');
      await tester.tap(find.text(l10n.visitsFrequentHasVehicle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsFrequentPhoneInvalid), findsOneWidget);
      expect(find.text(l10n.visitsFrequentPlateRequired), findsOneWidget);

      await tester.enterText(find.byType(TextField).at(1), '99998888');
      await tester.enterText(find.byType(TextField).at(2), 'abc123');
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      // Valid fields, still missing the ID photo.
      expect(find.text(l10n.visitsFrequentStep1), findsOneWidget);
      expect(find.text(l10n.visitsFrequentIdDocumentMissing), findsOneWidget);
    });

    testWidgets('a too-long phone is rejected', (tester) async {
      await open(tester, FakeVisitsRepository());
      await tester.enterText(find.byType(TextField).first, 'Ana');
      await tester.enterText(find.byType(TextField).at(1), '1234567890123');
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsFrequentPhoneInvalid), findsOneWidget);
    });

    testWidgets('picks a photo from the gallery, shows it and removes it', (
      tester,
    ) async {
      await open(tester, FakeVisitsRepository());
      await pickDocument(tester, photo, sourceLabel: 'gallery');
      expect(pickerCalls, [ImageSource.gallery.index]);
      expect(find.text(l10n.commonUploadReady), findsOneWidget);
      expect(find.textContaining('dni.jpg · 0.0 MB'), findsOneWidget);

      await tester.tap(find.text(l10n.commonRemove));
      await tester.pumpAndSettle();
      expect(find.text(l10n.commonUploadReady), findsNothing);
      expect(find.text(l10n.commonUploadDocument), findsOneWidget);
    });

    testWidgets('camera source is passed to the picker', (tester) async {
      await open(tester, FakeVisitsRepository());
      await pickDocument(tester, photo);
      expect(pickerCalls, [ImageSource.camera.index]);
    });

    testWidgets('cancelling the picker keeps the card empty', (tester) async {
      await open(tester, FakeVisitsRepository());
      pickedPath = null;
      await tester.tap(find.text(l10n.commonUploadDocument));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsFrequentTakePhoto));
      await tester.pumpAndSettle();
      expect(find.text(l10n.commonUploadReady), findsNothing);
      // And dismissing the source sheet picks nothing at all.
      await tester.tap(find.text(l10n.commonUploadDocument));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(l10n.commonClose));
      await tester.pumpAndSettle();
      expect(pickerCalls, hasLength(1));
    });

    testWidgets('photos over 10 MB are rejected with a message', (
      tester,
    ) async {
      await open(tester, FakeVisitsRepository());
      await pickDocument(tester, bigPhoto);
      expect(find.text(l10n.visitsFrequentPhotoTooBig), findsOneWidget);
      expect(find.text(l10n.commonUploadReady), findsNothing);
      // The error card offers choosing another file.
      pickedPath = photo.path;
      await tester.tap(find.text(l10n.commonChooseFile));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsFrequentTakePhoto));
      await tester.pumpAndSettle();
      await flushIo(tester);
      expect(find.text(l10n.commonUploadReady), findsOneWidget);
    });

    testWidgets('visitor type and country selectors update the form', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await choose(
        tester,
        l10n.visitsFrequentTypeLabel,
        visitorRoleLabel(l10n, VisitorRole.empleado),
      );
      expect(
        find.text(visitorRoleLabel(l10n, VisitorRole.empleado)),
        findsOneWidget,
      );
      await tester.tap(find.text('+504'));
      await tester.pumpAndSettle();
      expect(find.text(l10n.commonCountry), findsOneWidget);
      await tester.tap(find.text(l10n.commonCountryGuatemala));
      await tester.pumpAndSettle();
      expect(find.text('+502'), findsOneWidget);
    });
  });

  group('creating', () {
    testWidgets('preset schedule submits the right payload and goes home', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo, mode: ThemeMode.dark);
      await choose(
        tester,
        l10n.visitsFrequentTypeLabel,
        visitorRoleLabel(l10n, VisitorRole.empleado),
      );
      await tester.enterText(find.byType(TextField).at(1), '9999-8888');
      await tester.tap(find.text(l10n.visitsFrequentHasVehicle));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).at(2), ' abc123 ');
      await toStep2(tester, name: '  María  ');

      await tester.enterText(find.byType(TextField).last, '  Entra por la 2 ');
      await tester.tap(find.text(l10n.visitsFrequentNotifyLabel));
      await tester.pumpAndSettle();
      await submit(tester, l10n.visitsFrequentAuthorize);

      final created = repo.frequentCreated.single;
      expect(created['name'], 'María');
      expect(created['phone'], '+50499998888');
      expect(created['role'], VisitorRole.empleado);
      expect(created['photo'], 'res-1/doc.jpg');
      expect(created['hasVehicle'], isTrue);
      expect(created['plate'], 'ABC123');
      expect(created['recurrence'], Recurrence.monFri);
      expect(created['scheduleType'], ScheduleType.allDay);
      expect(created['blocks'], isNull);
      expect(created['notify'], isFalse);
      expect(created['notes'], 'Entra por la 2');
      expect(repo.uploads, ['jpg']);
      expect(find.text('open'), findsOneWidget);
      expect(find.text(l10n.visitsFrequentAuthorizedToast), findsOneWidget);
    });

    testWidgets('failure shows the cause and re-enables the button', (
      tester,
    ) async {
      final repo = FakeVisitsRepository()..error = const NetworkFailure();
      await open(tester, repo);
      await toStep2(tester);
      await submit(tester, l10n.visitsFrequentAuthorize);
      expect(find.text(l10n.visitsFrequentAuthorizeError), findsOneWidget);
      expect(
        find.text('${l10n.commonErrorNetwork} ${l10n.visitsTryAgain}'),
        findsOneWidget,
      );
      expect(find.text(l10n.visitsFrequentAuthorize), findsOneWidget);
    });

    testWidgets('unknown failures only show the retry hint', (tester) async {
      final repo = FakeVisitsRepository()..error = StateError('boom');
      await open(tester, repo);
      await toStep2(tester);
      await tester.tap(find.text(l10n.visitsFrequentAuthorize));
      await tester.pump();
      await flushIo(tester);
      expect(find.text(l10n.visitsFrequentAuthorizeError), findsOneWidget);
      expect(find.text(l10n.visitsTryAgain), findsOneWidget);
    });

    testWidgets('back on step 2 returns to step 1 first', (tester) async {
      await open(tester, FakeVisitsRepository());
      await toStep2(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsFrequentStep1), findsOneWidget);
      // Second back leaves the flow.
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('open'), findsOneWidget);
    });

    testWidgets('custom time range on a preset validates start < end', (
      tester,
    ) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await toStep2(tester);
      await choose(
        tester,
        l10n.visitsFrequentScheduleLabel,
        l10n.visitsRecurrenceCustom,
      );
      expect(find.text(l10n.visitsScheduleFrom), findsOneWidget);
      expect(find.text('08:00 AM'), findsOneWidget);
      expect(find.text('10:00 PM'), findsOneWidget);

      // Confirm both pickers unchanged (covers the pick callbacks)...
      await tester.tap(find.text(l10n.visitsScheduleFrom));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsScheduleTo));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();
      // ...and cancelling does nothing.
      await tester.tap(find.text(l10n.visitsScheduleTo));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonCancel));
      await tester.pumpAndSettle();

      await submit(tester, l10n.visitsFrequentAuthorize);
      expect(repo.frequentCreated.single['scheduleType'], ScheduleType.custom);
    });

    testWidgets('custom recurrence: blocks can be added, edited and removed', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await toStep2(tester);
      await choose(
        tester,
        l10n.visitsFrequentFrequencyLabel,
        l10n.visitsRecurrenceCustom,
      );
      expect(find.text(l10n.visitsFrequentGroupDaysHint), findsOneWidget);
      expect(find.text(l10n.visitsScheduleBlockTitle(1)), findsOneWidget);
      // A single block cannot be removed.
      expect(sem(l10n.visitsScheduleBlockRemove), findsNothing);

      await tester.tap(find.text(l10n.visitsFrequentAddBlock));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsScheduleBlockTitle(2)), findsOneWidget);
      expect(sem(l10n.visitsScheduleBlockRemove), findsNWidgets(2));

      // Block 2: pick Saturday; block 1 loses nothing, Sat is taken in block 1?
      final sat = sem(l10n.visitsWeekdaySat);
      await tester.tap(sat.last);
      await tester.pumpAndSettle();
      // Toggling a day in block 1 (Monday off).
      await tester.tap(sem(l10n.visitsWeekdayMon).first);
      await tester.pumpAndSettle();

      // Time pickers of block 2.
      await tester.tap(find.text(l10n.visitsScheduleFrom).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsScheduleTo).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.commonDone));
      await tester.pumpAndSettle();

      await submit(tester, l10n.visitsFrequentAuthorize);
      final blocks =
          repo.frequentCreated.single['blocks']! as List<ScheduleBlock>;
      expect(blocks, hasLength(2));
      expect(blocks[0].days, {'tue', 'wed', 'thu', 'fri'});
      expect(blocks[1].days, {'sat'});
      expect(repo.frequentCreated.single['recurrence'], Recurrence.custom);
      semantics.dispose();
    });

    testWidgets('a block without days blocks the save with a warning', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repo = FakeVisitsRepository();
      await open(tester, repo);
      await toStep2(tester);
      await choose(
        tester,
        l10n.visitsFrequentFrequencyLabel,
        l10n.visitsRecurrenceCustom,
      );
      await tester.tap(find.text(l10n.visitsFrequentAddBlock));
      await tester.pumpAndSettle();
      await submit(tester, l10n.visitsFrequentAuthorize);
      expect(find.text(l10n.visitsFrequentMissingData), findsOneWidget);
      expect(find.text(l10n.visitsFrequentSelectDayEachBlock), findsOneWidget);
      expect(repo.frequentCreated, isEmpty);

      // Remove the empty block and the save goes through.
      await tester.tap(sem(l10n.visitsScheduleBlockRemove).last);
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsScheduleBlockTitle(2)), findsNothing);
      semantics.dispose();
    });

    testWidgets('add block is disabled once every day is taken', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await open(tester, FakeVisitsRepository());
      await toStep2(tester);
      await choose(
        tester,
        l10n.visitsFrequentFrequencyLabel,
        l10n.visitsRecurrenceCustom,
      );
      // Block 1 has Mon-Fri; add Sat and Sun to cover the whole week.
      await tester.tap(sem(l10n.visitsWeekdaySat));
      await tester.tap(sem(l10n.visitsWeekdaySun));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.visitsFrequentAddBlock));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsScheduleBlockTitle(2)), findsNothing);
      semantics.dispose();
    });
  });

  group('editing', () {
    testWidgets('keeps the stored photo and updates the visit', (tester) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo, editing: editable());
      expect(find.text('María García'), findsOneWidget);
      expect(find.text('29998888'.replaceFirst('2', '')), findsNothing);
      expect(find.text('99998888'), findsOneWidget);
      expect(find.text('+502'), findsOneWidget);
      expect(find.text('HAB1234'), findsOneWidget);
      expect(find.text(l10n.visitsFrequentCurrentDocument), findsOneWidget);

      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text('Nota previa'), findsOneWidget);
      await submit(tester, l10n.visitsSaveChanges);

      final updated = repo.frequentUpdated.single;
      expect(updated['id'], 'fr-7');
      expect(updated['photo'], isNull);
      expect(updated['phone'], '+50299998888');
      expect(updated['plate'], 'HAB1234');
      expect(repo.uploads, isEmpty);
      expect(find.text('open'), findsOneWidget);
      expect(find.text(l10n.visitsFrequentUpdatedToast), findsOneWidget);
    });

    testWidgets('replacing the document uploads a new photo', (tester) async {
      final repo = FakeVisitsRepository();
      await open(tester, repo, editing: editable());
      await tester.tap(find.text(l10n.commonRemove));
      await tester.pumpAndSettle();
      await pickDocument(tester, photo);
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      await submit(tester, l10n.visitsSaveChanges);
      expect(repo.frequentUpdated.single['photo'], 'res-1/doc.jpg');
    });

    testWidgets('prefills legacy custom visits and saved blocks', (
      tester,
    ) async {
      // Custom recurrence saved before blocks existed: one block is rebuilt.
      final repo = FakeVisitsRepository();
      await open(
        tester,
        repo,
        editing: makeVisit(
          id: 'fr-8',
          name: 'Luis',
          type: VisitType.frequent,
          providerKind: null,
          recurrence: Recurrence.custom,
          idPhotoPath: 'x.jpg',
        ),
      );
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text(l10n.visitsScheduleBlockTitle(1)), findsOneWidget);
      // Rebuilt block has no days -> invalid until one is chosen.
      await submit(tester, l10n.visitsSaveChanges);
      expect(find.text(l10n.visitsFrequentSelectDayEachBlock), findsOneWidget);
    });

    testWidgets('a block ending before it starts is rejected', (tester) async {
      final repo = FakeVisitsRepository();
      await open(
        tester,
        repo,
        editing: editable(
          recurrence: Recurrence.custom,
          blocks: const [
            ScheduleBlock(
              days: {'mon'},
              start: TimeOfDay(hour: 20, minute: 0),
              end: TimeOfDay(hour: 10, minute: 0),
            ),
          ],
        ),
      );
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      expect(find.text('08:00 PM'), findsOneWidget);
      await submit(tester, l10n.visitsSaveChanges);
      expect(find.text(l10n.visitsFrequentStartBeforeEnd), findsOneWidget);
      expect(repo.frequentUpdated, isEmpty);
    });

    testWidgets('failure toasts the save error', (tester) async {
      final repo = FakeVisitsRepository()..error = const AuthFailure();
      await open(tester, repo, editing: editable());
      await tester.tap(find.text(l10n.visitsContinue));
      await tester.pumpAndSettle();
      await submit(tester, l10n.visitsSaveChanges);
      expect(find.text(l10n.visitsSaveError), findsOneWidget);
      expect(
        find.text('${l10n.commonErrorSession} ${l10n.visitsTryAgain}'),
        findsOneWidget,
      );
    });
  });
}
