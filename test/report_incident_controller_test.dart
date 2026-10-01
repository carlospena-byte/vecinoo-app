import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/domain/incidents_repository.dart';
import 'package:gates_app/features/incidents/presentation/incident_edit_args.dart';
import 'package:gates_app/features/incidents/presentation/incidents_controller.dart';
import 'package:gates_app/features/incidents/presentation/photo_picker.dart';
import 'package:gates_app/features/incidents/presentation/report_incident_controller.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:image_picker/image_picker.dart' show XFile;

const _membership = Membership(
  residentialId: 'res-1',
  residentialName: 'Los Olivos',
  unitId: 'unit-1',
  unitName: 'A-204',
);

class _FakeMembership extends SelectedMembershipController {
  @override
  Future<Membership?> build() async => _membership;
}

class _FakeRepository implements IncidentsRepository {
  final calls = <String>[];
  Object? createError;
  int uploadFailuresLeft = 0;
  Object? updateError;

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
    calls.add('create:$title');
    if (createError != null) throw createError!;
    return 'incident-1';
  }

  @override
  Future<void> updateIncident({
    required String incidentId,
    required String title,
    String? description,
    String? incidentTypeId,
  }) async {
    calls.add('update:$incidentId:$title');
    if (updateError != null) throw updateError!;
  }

  @override
  Future<void> uploadPhoto({
    required String residentialId,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) async {
    calls.add('upload:$incidentId:$extension');
    if (uploadFailuresLeft > 0) {
      uploadFailuresLeft--;
      throw TimeoutException('slow');
    }
  }

  @override
  Future<void> deleteAttachment(IncidentAttachment attachment) async {
    calls.add('delete:${attachment.id}');
  }

  @override
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId) async =>
      const [IncidentType(id: 'type-1', name: 'Mantenimiento')];

  @override
  Future<List<Incident>> fetchIncidents(String residentialId) async => [];

  @override
  Future<Incident> fetchIncident(String incidentId) =>
      throw UnimplementedError();

  @override
  Future<List<IncidentAttachment>> fetchAttachments(String incidentId) async =>
      [];

  @override
  Future<void> cancelIncident(String incidentId) async {}
}

class _FakePicker implements PhotoPicker {
  _FakePicker(this.count);
  final int count;

  @override
  Future<List<XFile>> pick(PhotoSource source) async => [
    for (var i = 0; i < count; i++)
      XFile.fromData(Uint8List.fromList([i]), path: 'photo$i.jpg'),
  ];
}

ProviderContainer _container(
  _FakeRepository repository, {
  PhotoPicker? picker,
  IncidentEditArgs? editing,
}) {
  final container = ProviderContainer(
    overrides: [
      incidentsRepositoryProvider.overrideWithValue(repository),
      photoPickerProvider.overrideWithValue(picker ?? _FakePicker(2)),
      selectedMembershipProvider.overrideWith(_FakeMembership.new),
    ],
  );
  addTearDown(container.dispose);
  // Keep the autoDispose controller alive for the whole test.
  container.listen(reportIncidentControllerProvider(editing), (_, _) {});
  return container;
}

Future<void> _ready(ProviderContainer container) async {
  await container.read(selectedMembershipProvider.future);
  await container.read(incidentTypesProvider('res-1').future);
}

void main() {
  group('new report', () {
    test('creates the incident once, then uploads each photo', () async {
      final repo = _FakeRepository();
      final container = _container(repo);
      await _ready(container);
      final controller = container.read(
        reportIncidentControllerProvider(null).notifier,
      );

      await controller.addPhotos(PhotoSource.gallery);
      controller.selectType('type-1');
      await controller.submit(title: '  La luz no enciende ');

      final state = container.read(reportIncidentControllerProvider(null));
      expect(repo.calls, [
        'create:La luz no enciende',
        'upload:incident-1:jpg',
        'upload:incident-1:jpg',
      ]);
      expect(state.phase, ReportPhase.sent);
      expect(state.sentTitle, 'La luz no enciende');
      expect(state.sentCategory, 'Mantenimiento');
      expect(state.uploadedCount, 2);
    });

    test('a blank title is not submitted', () async {
      final repo = _FakeRepository();
      final container = _container(repo);
      await _ready(container);

      await container
          .read(reportIncidentControllerProvider(null).notifier)
          .submit(title: '   ');

      expect(repo.calls, isEmpty);
      expect(
        container.read(reportIncidentControllerProvider(null)).phase,
        ReportPhase.form,
      );
    });

    test('failed photos land on the error phase and retrying never creates '
        'a second incident', () async {
      final repo = _FakeRepository()..uploadFailuresLeft = 1;
      final container = _container(repo);
      await _ready(container);
      final controller = container.read(
        reportIncidentControllerProvider(null).notifier,
      );

      await controller.addPhotos(PhotoSource.gallery);
      await controller.submit(title: 'Fuga');

      var state = container.read(reportIncidentControllerProvider(null));
      expect(state.phase, ReportPhase.photoError);
      expect(state.hasPhotoErrors, isTrue);
      expect(state.uploadedCount, 1);

      await controller.uploadPending();

      state = container.read(reportIncidentControllerProvider(null));
      expect(state.phase, ReportPhase.sent);
      expect(state.uploadedCount, 2);
      expect(repo.calls.where((c) => c.startsWith('create')), hasLength(1));
      expect(repo.calls.where((c) => c.startsWith('upload')), hasLength(3));
    });

    test(
      'a failed create keeps the draft and reports a typed failure',
      () async {
        final repo = _FakeRepository()
          ..createError = TimeoutException('offline');
        final container = _container(repo);
        await _ready(container);
        final controller = container.read(
          reportIncidentControllerProvider(null).notifier,
        );
        final events = <ReportEvent>[];
        controller.events.listen(events.add);

        await controller.addPhotos(PhotoSource.gallery);
        await controller.submit(title: 'Fuga');
        await Future<void>.delayed(Duration.zero);

        final state = container.read(reportIncidentControllerProvider(null));
        expect(state.phase, ReportPhase.form);
        expect(state.photos, hasLength(2));
        expect(state.incidentId, isNull);
        expect(events.single, isA<SendFailed>());
        expect((events.single as SendFailed).failure, isA<NetworkFailure>());
      },
    );

    test('only the photos that still fit are added', () async {
      final repo = _FakeRepository();
      final container = _container(repo, picker: _FakePicker(12));
      await _ready(container);
      final controller = container.read(
        reportIncidentControllerProvider(null).notifier,
      );
      final events = <ReportEvent>[];
      controller.events.listen(events.add);

      await controller.addPhotos(PhotoSource.gallery);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(reportIncidentControllerProvider(null)).photos,
        hasLength(maxIncidentPhotos),
      );
      expect((events.single as PhotoLimitReached).added, maxIncidentPhotos);
    });
  });

  group('editing', () {
    final incident = Incident(
      id: 'incident-9',
      title: 'Fuga',
      incidentTypeId: 'type-1',
      priority: IncidentPriority.medium,
      status: IncidentStatus.newIncident,
      createdAt: DateTime(2026, 9, 30),
    );
    const kept = IncidentAttachment(id: 'a1', storagePath: 'p1', url: 'u1');
    const dropped = IncidentAttachment(id: 'a2', storagePath: 'p2', url: 'u2');
    final args = IncidentEditArgs(
      incident: incident,
      attachments: const [kept, dropped],
    );

    test('updates, deletes removed photos and never creates', () async {
      final repo = _FakeRepository();
      final container = _container(repo, editing: args);
      await _ready(container);
      final provider = reportIncidentControllerProvider(args);
      final controller = container.read(provider.notifier);
      final events = <ReportEvent>[];
      controller.events.listen(events.add);

      final removedId = container
          .read(provider)
          .photos
          .firstWhere((p) => p.attachment?.id == 'a2')
          .id;
      controller.removePhoto(removedId);
      await controller.submit(title: 'Fuga grande');
      await Future<void>.delayed(Duration.zero);

      expect(repo.calls, ['update:incident-9:Fuga grande', 'delete:a2']);
      expect(container.read(provider).removedAttachments, isEmpty);
      expect(events.single, isA<EditSaved>());
    });

    test('a failed save returns to the form with the changes intact', () async {
      final repo = _FakeRepository()..updateError = TimeoutException('x');
      final container = _container(repo, editing: args);
      await _ready(container);
      final provider = reportIncidentControllerProvider(args);
      final controller = container.read(provider.notifier);
      final events = <ReportEvent>[];
      controller.events.listen(events.add);

      controller.removePhoto(container.read(provider).photos.first.id);
      await controller.submit(title: 'Fuga');
      await Future<void>.delayed(Duration.zero);

      expect(container.read(provider).phase, ReportPhase.form);
      expect(container.read(provider).removedAttachments, hasLength(1));
      expect(events.single, isA<SaveFailed>());
    });

    test('tracks unsaved changes against what was loaded', () async {
      final repo = _FakeRepository();
      final container = _container(repo, editing: args);
      await _ready(container);
      final provider = reportIncidentControllerProvider(args);
      final controller = container.read(provider.notifier);

      controller.markLoadedDraft(title: 'Fuga', description: 'texto');
      expect(container.read(provider).isDirty, isFalse);

      controller.updateDraft(title: 'Fuga grande', description: 'texto');
      expect(container.read(provider).isDirty, isTrue);

      controller.updateDraft(title: 'Fuga', description: 'texto');
      expect(container.read(provider).isDirty, isFalse);
    });
  });
}
