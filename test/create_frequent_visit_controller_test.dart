import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/domain/visits_repository.dart';
import 'package:gates_app/features/visits/presentation/create_frequent_visit_controller.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';
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

class _Repository implements VisitsRepository {
  final uploads = <({String residentialId, Uint8List bytes, String ext})>[];
  final calls = <Map<String, Object?>>[];
  Object? error;

  @override
  Future<String> uploadVisitorDocument({
    required String residentialId,
    required Uint8List bytes,
    required String extension,
  }) async {
    uploads.add((residentialId: residentialId, bytes: bytes, ext: extension));
    return 'res-1/doc.$extension';
  }

  @override
  Future<void> createFrequentVisit({
    required String residentialId,
    required String unitId,
    required String name,
    String? phone,
    required VisitorRole visitorRole,
    required String idPhotoPath,
    required bool hasVehicle,
    String? plate,
    required Recurrence recurrence,
    required ScheduleType scheduleType,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    List<ScheduleBlock>? scheduleBlocks,
    required bool notifyOnArrival,
    String? notes,
  }) async {
    if (error != null) throw error!;
    calls.add({
      'op': 'create',
      'unitId': unitId,
      'name': name,
      'phone': phone,
      'role': visitorRole,
      'photo': idPhotoPath,
      'hasVehicle': hasVehicle,
      'plate': plate,
      'recurrence': recurrence,
      'blocks': scheduleBlocks,
      'notes': notes,
    });
  }

  @override
  Future<void> updateFrequentVisit({
    required String visitId,
    required String name,
    String? phone,
    required VisitorRole visitorRole,
    String? idPhotoPath,
    required bool hasVehicle,
    String? plate,
    required Recurrence recurrence,
    required ScheduleType scheduleType,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    List<ScheduleBlock>? scheduleBlocks,
    required bool notifyOnArrival,
    String? notes,
  }) async {
    if (error != null) throw error!;
    calls.add({'op': 'update', 'id': visitId, 'photo': idPhotoPath});
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

XFile _photo() => XFile.fromData(
  Uint8List.fromList([1, 2, 3]),
  path: 'id.jpg',
  name: 'id.jpg',
);

({ProviderContainer container, CreateFrequentVisitController controller})
_setup(_Repository repo, {Visit? editing}) {
  final container = ProviderContainer(
    overrides: [
      visitsRepositoryProvider.overrideWithValue(repo),
      selectedMembershipProvider.overrideWith(_Membership.new),
    ],
  );
  addTearDown(container.dispose);
  final provider = createFrequentVisitControllerProvider(editing);
  container.listen(provider, (_, _) {});
  return (container: container, controller: container.read(provider.notifier));
}

Future<void> _submit(CreateFrequentVisitController c) => c.submit(
  name: '  María ',
  phoneDigits: '9999-8888',
  plate: ' hab1234 ',
  notes: '  ',
);

void main() {
  test('creates a visit: uploads the document once, then saves', () async {
    final repo = _Repository();
    final s = _setup(repo);
    await s.container.read(selectedMembershipProvider.future);
    await s.controller.setDocument(_photo());
    s.controller.setHasVehicle(true);
    final events = <CreateFrequentVisitEvent>[];
    s.controller.events.listen(events.add);

    await _submit(s.controller);
    await Future<void>.delayed(Duration.zero);

    expect(repo.uploads, hasLength(1));
    expect(repo.uploads.single.ext, 'jpg');
    expect(repo.uploads.single.bytes, [1, 2, 3]);
    expect(repo.calls.single, containsPair('op', 'create'));
    expect(repo.calls.single['photo'], 'res-1/doc.jpg');
    expect(repo.calls.single['name'], 'María');
    expect(repo.calls.single['phone'], endsWith('99998888'));
    expect(repo.calls.single['plate'], 'HAB1234');
    expect(repo.calls.single['notes'], isNull);
    expect(repo.calls.single['blocks'], isNull);
    expect(events.single, isA<FrequentVisitSaved>());
    expect((events.single as FrequentVisitSaved).updated, isFalse);
  });

  test('editing keeps the existing document when none is replaced', () async {
    final repo = _Repository();
    final visit = Visit(
      id: 'v1',
      unitId: 'unit-1',
      name: 'María',
      status: VisitStatus.scheduled,
      visitType: VisitType.frequent,
      idPhotoPath: 'res-1/old.jpg',
      validFrom: DateTime(2026),
      validUntil: DateTime(2099),
      createdAt: DateTime(2026),
    );
    final s = _setup(repo, editing: visit);
    await s.container.read(selectedMembershipProvider.future);

    await _submit(s.controller);

    expect(repo.uploads, isEmpty);
    expect(repo.calls.single, {'op': 'update', 'id': 'v1', 'photo': null});
  });

  test('missing document or start >= end never reach the repository', () async {
    final repo = _Repository();
    final s = _setup(repo);
    await s.container.read(selectedMembershipProvider.future);
    final events = <CreateFrequentVisitEvent>[];
    s.controller.events.listen(events.add);

    s.controller.next(formValid: true);
    expect(
      s.container.read(createFrequentVisitControllerProvider(null)).step,
      0,
    );
    expect(
      s.container
          .read(createFrequentVisitControllerProvider(null))
          .documentMissing,
      isTrue,
    );
    await _submit(s.controller);
    expect(repo.calls, isEmpty);

    await s.controller.setDocument(_photo());
    s.controller.next(formValid: true);
    s.controller.setScheduleType(ScheduleType.custom);
    s.controller.setScheduleStart(const TimeOfDay(hour: 22, minute: 0));
    s.controller.setScheduleEnd(const TimeOfDay(hour: 22, minute: 0));
    await _submit(s.controller);
    await Future<void>.delayed(Duration.zero);

    expect(repo.uploads, isEmpty);
    expect(repo.calls, isEmpty);
    expect(
      (events.single as FrequentVisitInvalid).issue,
      FrequentVisitIssue.startBeforeEnd,
    );
  });

  test('a failed submit emits a typed failure and re-enables submit', () async {
    final repo = _Repository()..error = TimeoutException('slow');
    final s = _setup(repo);
    await s.container.read(selectedMembershipProvider.future);
    await s.controller.setDocument(_photo());
    final events = <CreateFrequentVisitEvent>[];
    s.controller.events.listen(events.add);

    await _submit(s.controller);
    await Future<void>.delayed(Duration.zero);

    expect(
      (events.single as FrequentVisitSaveFailed).failure,
      isA<NetworkFailure>(),
    );
    expect(
      s.container
          .read(createFrequentVisitControllerProvider(null))
          .isSubmitting,
      isFalse,
    );
  });

  test('custom blocks are validated and sent as the payload', () async {
    final repo = _Repository();
    final s = _setup(repo);
    await s.container.read(selectedMembershipProvider.future);
    await s.controller.setDocument(_photo());
    final events = <CreateFrequentVisitEvent>[];
    s.controller.events.listen(events.add);

    s.controller.setRecurrence(Recurrence.custom);
    var state = s.container.read(createFrequentVisitControllerProvider(null));
    expect(state.blocks.single.days, {'mon', 'tue', 'wed', 'thu', 'fri'});

    s.controller.addBlock();
    await _submit(s.controller);
    await Future<void>.delayed(Duration.zero);
    expect(
      (events.single as FrequentVisitInvalid).issue,
      FrequentVisitIssue.eachBlockNeedsDay,
    );
    expect(repo.calls, isEmpty);

    s.controller.toggleBlockDay(0, 'fri');
    s.controller.toggleBlockDay(1, 'fri');
    s.controller.setBlockStart(1, const TimeOfDay(hour: 9, minute: 30));
    state = s.container.read(createFrequentVisitControllerProvider(null));
    expect(state.daysTakenByOthers(0), {'fri'});

    await _submit(s.controller);

    final blocks = repo.calls.single['blocks']! as List<ScheduleBlock>;
    expect(blocks, hasLength(2));
    expect(blocks[0].days, {'mon', 'tue', 'wed', 'thu'});
    expect(blocks[1].days, {'fri'});
    expect(blocks[1].start, const TimeOfDay(hour: 9, minute: 30));
    expect(blocks[1].end, const TimeOfDay(hour: 22, minute: 0));
  });
}
