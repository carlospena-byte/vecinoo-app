import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_controller.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_photos.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

import '../../helpers/fonts.dart';
import '../../helpers/pump_app.dart';
import 'fakes.dart';

void main() {
  setUpAll(loadManrope);

  final l10n = AppLocalizationsEs();

  ReportPhoto stored(int id, PhotoStatus status) => ReportPhoto.stored(
    IncidentAttachment(id: 'a$id', storagePath: 'p', url: 'http://x/$id'),
    id: id,
  ).withStatus(status);

  testWidgets('PhotosSection counts photos and hides add when full', (
    tester,
  ) async {
    ignoreImageErrors();
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: PhotosSection(
            photos: [for (var i = 0; i < 10; i++) stored(i, PhotoStatus.done)],
            onAdd: () {},
            onRemove: (_) {},
          ),
        ),
      ),
    );
    expect(find.text('10 / 10'), findsOneWidget);
    expect(find.byType(AddPhotosCard), findsNothing);
    expect(find.text(l10n.incidentsReportPhotosOptional), findsOneWidget);
  });

  testWidgets('PhotoTile shows status pills and respects removable set', (
    tester,
  ) async {
    ignoreImageErrors();
    final removed = <int>[];
    final retried = <int>[];
    await pumpApp(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: PhotosSection(
            photos: [
              stored(1, PhotoStatus.uploading),
              stored(2, PhotoStatus.error),
              stored(3, PhotoStatus.done),
            ],
            onRemove: (p) => removed.add(p.id),
            onRetry: (p) => retried.add(p.id),
            removableStatuses: const {PhotoStatus.error},
            showAdd: false,
          ),
        ),
      ),
    );
    expect(find.text(l10n.incidentsReportUploading), findsOneWidget);
    expect(find.text(l10n.incidentsReportRetry), findsOneWidget);
    expect(find.byType(AddPhotosCard), findsNothing);

    await tester.tap(find.bySemanticsLabel(l10n.incidentsReportRemovePhoto));
    await tester.tap(find.text(l10n.incidentsReportRetry));
    expect(removed, [2]);
    expect(retried, [2]);
  });

  testWidgets('PhotoSourceSheet reports the chosen source', (tester) async {
    final picked = <PhotoSource>[];
    var cancelled = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: PhotoSourceSheet(onPick: picked.add, onCancel: () => cancelled++),
      ),
    );
    await tester.tap(find.text(l10n.incidentsReportTakePhoto));
    await tester.tap(find.text(l10n.incidentsReportChooseGallery));
    await tester.tap(find.text(l10n.incidentsReportCancel));
    await tester.tap(find.byIcon(TablerIcons.x));
    expect(picked, [PhotoSource.camera, PhotoSource.gallery]);
    expect(cancelled, 2);
  });

  testWidgets('AddPhotosCard shows its title and limit', (tester) async {
    var taps = 0;
    await pumpApp(
      tester,
      Scaffold(
        body: AddPhotosCard(title: 'Agregar', onTap: () => taps++),
      ),
      mode: ThemeMode.dark,
    );
    expect(find.text(l10n.incidentsReportUpToPhotos(10)), findsOneWidget);
    await tester.tap(find.text('Agregar'));
    expect(taps, 1);
  });
}
