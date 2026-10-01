import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/core/widgets/gates_text_field.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incident_edit_args.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_photos.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_screen.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

class _GatedRepository extends FakeIncidentsRepository {
  final gate = Completer<void>();

  @override
  Future<String> createIncident({
    required String residentialId,
    required String unitId,
    required String title,
    String? description,
    String? incidentTypeId,
    String? location,
    IncidentPriority priority = IncidentPriority.medium,
  }) async {
    await gate.future;
    return super.createIncident(
      residentialId: residentialId,
      unitId: unitId,
      title: title,
      description: description,
      incidentTypeId: incidentTypeId,
    );
  }
}

void main() {
  setUpAll(loadManrope);

  final l10n = AppLocalizationsEs();
  final title = find.byType(GatesTextField);
  final submit = find.widgetWithText(
    ElevatedButton,
    l10n.incidentsReportAction,
  );

  /// The report screen is pushed from a home page so pops are observable.
  Future<void> pump(
    WidgetTester tester,
    FakeIncidentsRepository repo, {
    FakePhotoPicker? picker,
    IncidentEditArgs? editing,
    ThemeMode mode = ThemeMode.light,
  }) async {
    ignoreImageErrors();
    await pumpApp(
      tester,
      Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => context.push('/report'),
            child: const Text('HOME'),
          ),
        ),
      ),
      overrides: incidentOverrides(repo, picker: picker ?? FakePhotoPicker()),
      mode: mode,
      routes: {'/report': (_) => ReportIncidentScreen(editing: editing)},
    );
    await tester.tap(find.text('HOME'));
    await tester.pumpAndSettle();
  }

  Future<void> addPhotos(WidgetTester tester, String sourceLabel) async {
    await tester.tap(find.byType(AddPhotosCard).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text(sourceLabel));
    await tester.pumpAndSettle();
  }

  testWidgets('title is required: whitespace keeps the button disabled', (
    tester,
  ) async {
    await pump(tester, FakeIncidentsRepository());
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await tester.enterText(title, '   ');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNull);
    await tester.enterText(title, 'Algo');
    await tester.pump();
    expect(tester.widget<ElevatedButton>(submit).onPressed, isNotNull);
  });

  testWidgets('category, title and description are sent; confirmation shows', (
    tester,
  ) async {
    final repo = FakeIncidentsRepository();
    await pump(tester, repo);

    // Pick a category from the option sheet.
    await tester.tap(find.text(l10n.incidentsReportCategoryPlaceholder));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Seguridad'));
    await tester.pumpAndSettle();

    await tester.enterText(title, '  Puerta rota ');
    await tester.enterText(find.widgetWithText(TextField, '').last, 'Se cae');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(repo.calls, ['create:Puerta rota|<p>Se cae</p>|t2']);
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
    expect(find.text(l10n.incidentsReportSentHeadline), findsOneWidget);
    expect(find.text('Puerta rota'), findsOneWidget);
    expect(find.text('Seguridad'), findsOneWidget);
    expect(find.text('0 / 10'), findsOneWidget);

    // Back home leaves the flow.
    await tester.tap(find.text(l10n.incidentsReportBackHome));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('system back on the confirmation goes home', (tester) async {
    await pump(tester, FakeIncidentsRepository());
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSentHeadline), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('shows the sending phase while the report is created', (
    tester,
  ) async {
    final repo = _GatedRepository();
    await pump(tester, repo);
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await tester.tap(submit);
    await tester.pump();

    expect(find.text(l10n.incidentsReportSending), findsOneWidget);
    expect(find.text(l10n.incidentsReportWaitMessage), findsOneWidget);
    expect(find.text(l10n.incidentsReportSendingButton), findsOneWidget);

    // Back is blocked while sending.
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(find.text(l10n.incidentsReportSending), findsOneWidget);

    repo.gate.complete();
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
  });

  testWidgets('create failure keeps the form and toasts the cause', (
    tester,
  ) async {
    final repo = FakeIncidentsRepository()
      ..createError = const NetworkFailure();
    await pump(tester, repo);
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text(l10n.incidentsReportSendFailed), findsOneWidget);
    expect(
      find.text(
        '${l10n.commonErrorNetwork} ${l10n.incidentsReportSendFailedBody}',
      ),
      findsOneWidget,
    );
    expect(find.text('Ruido'), findsOneWidget);

    // Retrying works and sends only once more.
    repo.createError = null;
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
    expect(repo.calls.where((c) => c.startsWith('create')), hasLength(2));
  });

  testWidgets('unknown create failure uses only the generic body', (
    tester,
  ) async {
    final repo = FakeIncidentsRepository()..createError = StateError('x');
    await pump(tester, repo);
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSendFailedBody), findsOneWidget);
  });

  testWidgets('photos can be added from the gallery and removed', (
    tester,
  ) async {
    final picker = FakePhotoPicker(2);
    await pump(tester, FakeIncidentsRepository(), picker: picker);
    expect(find.text('0 / 10'), findsOneWidget);
    expect(find.text(l10n.incidentsReportAddPhotos), findsOneWidget);

    await addPhotos(tester, l10n.incidentsReportChooseGallery);
    expect(picker.sources, [PhotoSource.gallery]);
    expect(find.text('2 / 10'), findsOneWidget);
    expect(find.text(l10n.incidentsReportAddMorePhotos), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(l10n.incidentsReportRemovePhoto).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('1 / 10'), findsOneWidget);
  });

  testWidgets('camera source and cancelling the sheet', (tester) async {
    final picker = FakePhotoPicker(1);
    await pump(tester, FakeIncidentsRepository(), picker: picker);

    await tester.tap(find.byType(AddPhotosCard));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportPhotoSourceBody), findsOneWidget);
    await tester.tap(find.text(l10n.incidentsReportCancel));
    await tester.pumpAndSettle();
    expect(picker.sources, isEmpty);

    await addPhotos(tester, l10n.incidentsReportTakePhoto);
    expect(picker.sources, [PhotoSource.camera]);
    expect(find.text('1 / 10'), findsOneWidget);
  });

  testWidgets('the close icon also dismisses the source sheet', (tester) async {
    await pump(tester, FakeIncidentsRepository());
    await tester.tap(find.byType(AddPhotosCard));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(TablerIcons.x));
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportPhotoSourceBody), findsNothing);
  });

  testWidgets('picking more than the limit keeps the first ones and toasts', (
    tester,
  ) async {
    final picker = FakePhotoPicker(12);
    await pump(tester, FakeIncidentsRepository(), picker: picker);
    await addPhotos(tester, l10n.incidentsReportChooseGallery);

    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.text(l10n.incidentsReportMaxPhotos(10)), findsOneWidget);
    expect(find.text(l10n.incidentsReportAddedFirst(10)), findsOneWidget);
    // The add card is gone once the limit is reached.
    expect(find.byType(AddPhotosCard), findsNothing);
  });

  testWidgets('a picker failure toasts the permissions hint', (tester) async {
    final picker = FakePhotoPicker()..error = StateError('denied');
    await pump(tester, FakeIncidentsRepository(), picker: picker);
    await addPhotos(tester, l10n.incidentsReportChooseGallery);
    expect(find.text(l10n.incidentsReportPhotosOpenFailed), findsOneWidget);
    expect(find.text(l10n.incidentsReportPhotosPermissions), findsOneWidget);
  });

  testWidgets('photo upload failure lands on the error phase and can retry', (
    tester,
  ) async {
    final repo = FakeIncidentsRepository()..uploadFailuresLeft = 1;
    await pump(tester, repo, picker: FakePhotoPicker(2));
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await addPhotos(tester, l10n.incidentsReportChooseGallery);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text(l10n.incidentsReportPhotoErrorTitle), findsOneWidget);
    expect(find.text(l10n.incidentsReportPhotoErrorBody), findsOneWidget);
    expect(find.text(l10n.incidentsReportRetry), findsOneWidget);
    // "Listo" is blocked while a photo failed.
    final done = find.widgetWithText(ElevatedButton, l10n.incidentsReportDone);
    expect(tester.widget<ElevatedButton>(done).onPressed, isNull);
    // Only the failed photo can be removed.
    expect(
      find.bySemanticsLabel(l10n.incidentsReportRemovePhoto),
      findsOneWidget,
    );

    await tester.tap(find.text(l10n.incidentsReportRetryPhoto));
    await tester.pumpAndSettle();

    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
    expect(find.text('2 / 10'), findsWidgets);
    expect(repo.calls.where((c) => c.startsWith('create')), hasLength(1));
    expect(repo.calls.where((c) => c.startsWith('upload')), hasLength(3));
  });

  testWidgets('retrying through the photo pill and removing a failed photo', (
    tester,
  ) async {
    final repo = FakeIncidentsRepository()..uploadFailuresLeft = 1;
    await pump(tester, repo, picker: FakePhotoPicker(1));
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await addPhotos(tester, l10n.incidentsReportChooseGallery);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    await tester.tap(
      find.bySemanticsLabel(l10n.incidentsReportRetryUploadPhoto),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
  });

  testWidgets('removing the failed photo lets the user finish', (tester) async {
    final repo = FakeIncidentsRepository()..uploadFailuresLeft = 1;
    await pump(tester, repo, picker: FakePhotoPicker(1));
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await addPhotos(tester, l10n.incidentsReportChooseGallery);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel(l10n.incidentsReportRemovePhoto));
    await tester.pumpAndSettle();
    final done = find.widgetWithText(ElevatedButton, l10n.incidentsReportDone);
    expect(tester.widget<ElevatedButton>(done).onPressed, isNotNull);
    await tester.tap(done);
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
  });

  group('edit mode', () {
    final incident = makeIncident(
      title: 'Titulo previo',
      description: '<p>Detalle <strong>previo</strong></p>',
      typeId: 't1',
      typeName: 'Mantenimiento',
    );
    const stored = IncidentAttachment(
      id: 'att-1',
      storagePath: 'p/1.jpg',
      url: 'http://x/1.jpg',
    );
    final args = IncidentEditArgs(
      incident: incident,
      attachments: const [stored],
    );

    testWidgets('prefills the form and pops without asking when untouched', (
      tester,
    ) async {
      await pump(tester, FakeIncidentsRepository(), editing: args);
      expect(find.text(l10n.incidentsReportEditTitle), findsOneWidget);
      expect(find.text('Titulo previo'), findsOneWidget);
      expect(find.text('Detalle previo'), findsOneWidget);
      expect(find.text('Mantenimiento'), findsOneWidget);
      expect(find.text('1 / 10'), findsOneWidget);
      expect(find.text(l10n.incidentsReportSaveChanges), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('leaving with edits asks to discard; keep editing stays', (
      tester,
    ) async {
      await pump(tester, FakeIncidentsRepository(), editing: args);
      await tester.enterText(title, 'Otro titulo');
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text(l10n.incidentsReportDiscardTitle), findsOneWidget);
      expect(find.text(l10n.incidentsReportDiscardBody), findsOneWidget);

      await tester.tap(find.text(l10n.incidentsReportKeepEditing));
      await tester.pumpAndSettle();
      expect(find.text(l10n.incidentsReportDiscardTitle), findsNothing);
      expect(find.text('Otro titulo'), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.incidentsReportDiscardAction));
      await tester.pumpAndSettle();
      expect(find.text('HOME'), findsOneWidget);
    });

    testWidgets('saving updates, deletes removed photos and confirms', (
      tester,
    ) async {
      final repo = FakeIncidentsRepository();
      await pump(tester, repo, editing: args);
      await tester.enterText(title, 'Titulo nuevo');
      await tester.pump();
      await tester.tap(find.bySemanticsLabel(l10n.incidentsReportRemovePhoto));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.incidentsReportSaveChanges));
      await tester.pumpAndSettle();

      expect(repo.calls, [
        'update:i1:Titulo nuevo|<p>Detalle <strong>previo</strong></p>|t1',
        'delete:att-1',
      ]);
      expect(find.text('HOME'), findsOneWidget);
      expect(find.text(l10n.incidentsReportChangesSaved), findsOneWidget);
    });

    testWidgets('a failed save returns to the form with a toast', (
      tester,
    ) async {
      final repo = FakeIncidentsRepository()
        ..updateError = const ServerFailure();
      await pump(tester, repo, editing: args);
      await tester.enterText(title, 'Titulo nuevo');
      await tester.pump();
      await tester.tap(find.text(l10n.incidentsReportSaveChanges));
      await tester.pumpAndSettle();

      expect(find.text(l10n.incidentsReportSaveFailed), findsOneWidget);
      expect(
        find.text(
          '${l10n.commonErrorServer} ${l10n.incidentsReportSaveFailedBody}',
        ),
        findsOneWidget,
      );
      expect(find.text('Titulo nuevo'), findsOneWidget);
    });

    testWidgets('photos added while editing upload right away', (tester) async {
      final repo = FakeIncidentsRepository();
      await pump(tester, repo, editing: args, picker: FakePhotoPicker());
      // The row already exists, so a new photo uploads immediately and the
      // edit closes once it is stored.
      await addPhotos(tester, l10n.incidentsReportChooseGallery);
      expect(repo.calls.any((c) => c.startsWith('upload:i1')), isTrue);
      expect(find.text('HOME'), findsOneWidget);
    });
  });

  testWidgets('renders the form and sent phase in dark mode', (tester) async {
    await pump(tester, FakeIncidentsRepository(), mode: ThemeMode.dark);
    await tester.enterText(title, 'Ruido');
    await tester.pump();
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text(l10n.incidentsReportReceived), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
