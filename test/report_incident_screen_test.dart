import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fonts.dart';

import 'package:gates_app/core/theme/app_theme.dart';
import 'package:gates_app/core/widgets/gates_text_field.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/domain/incidents_repository.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_screen.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';
import 'package:image_picker/image_picker.dart' show XFile;

class _Membership extends SelectedMembershipController {
  @override
  Future<Membership?> build() async => const Membership(
    residentialId: 'res-1',
    residentialName: 'Los Olivos',
    unitId: 'unit-1',
    unitName: 'A-204',
  );
}

class _Repository implements IncidentsRepository {
  final created = <String>[];
  final uploads = <String>[];

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
    created.add(title);
    return 'incident-1';
  }

  @override
  Future<void> uploadPhoto({
    required String residentialId,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) async => uploads.add(extension);

  @override
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId) async =>
      const [IncidentType(id: 't1', name: 'Mantenimiento')];

  @override
  Future<List<Incident>> fetchIncidents(String residentialId) async => [];

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class _Picker implements PhotoPicker {
  @override
  Future<List<XFile>> pick(PhotoSource source) async => [
    XFile.fromData(Uint8List.fromList([1]), path: 'foto.png'),
  ];
}

void main() {
  setUpAll(loadManrope);

  final l10n = AppLocalizationsEs();

  Future<_Repository> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final repository = _Repository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          incidentsRepositoryProvider.overrideWithValue(repository),
          photoPickerProvider.overrideWithValue(_Picker()),
          selectedMembershipProvider.overrideWith(_Membership.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ReportIncidentScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return repository;
  }

  testWidgets('the submit button stays disabled until there is a title', (
    tester,
  ) async {
    await pumpScreen(tester);

    final button = find.widgetWithText(
      ElevatedButton,
      l10n.incidentsReportAction,
    );
    expect(tester.widget<ElevatedButton>(button).onPressed, isNull);

    await tester.enterText(find.byType(GatesTextField), 'La luz no enciende');
    await tester.pump();

    expect(tester.widget<ElevatedButton>(button).onPressed, isNotNull);
  });

  testWidgets('sending a report creates it once and shows the confirmation', (
    tester,
  ) async {
    final repository = await pumpScreen(tester);

    await tester.enterText(find.byType(GatesTextField), 'La luz no enciende');
    await tester.pump();
    await tester.tap(
      find.widgetWithText(ElevatedButton, l10n.incidentsReportAction),
    );
    await tester.pumpAndSettle();

    expect(repository.created, ['La luz no enciende']);
    expect(find.text(l10n.incidentsReportSentTitle), findsOneWidget);
    expect(find.text('La luz no enciende'), findsOneWidget);
  });
}
