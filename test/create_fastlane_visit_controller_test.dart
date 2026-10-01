import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/domain/visits_repository.dart';
import 'package:gates_app/features/visits/presentation/create_fastlane_visit_controller.dart';
import 'package:gates_app/features/visits/presentation/visits_controller.dart';

class _Membership extends SelectedMembershipController {
  @override
  Future<Membership?> build() async => const Membership(
    residentialId: 'res-1',
    residentialName: 'Los Olivos',
    unitId: 'unit-1',
    unitName: 'A-204',
  );
}

class _Call {
  _Call(this.visitId, this.name, this.date, this.arrival, this.notes);
  final String? visitId;
  final String name;
  final DateTime date;
  final TimeOfDay arrival;
  final String? notes;
}

Visit _visit(String id, {String? name, DateTime? validFrom}) => Visit(
  id: id,
  unitId: 'unit-1',
  name: name,
  status: VisitStatus.pendingRegistration,
  visitType: VisitType.fastlane,
  validFrom: validFrom ?? DateTime(2026, 10, 1, 9, 15),
  validUntil: DateTime(2026, 10, 1, 23, 59),
  createdAt: DateTime(2026, 9, 30),
);

class _Repository implements VisitsRepository {
  final creates = <_Call>[];
  final updates = <_Call>[];
  Object? error;
  Completer<void>? gate;

  @override
  Future<Visit> createFastlaneVisit({
    required String residentialId,
    required String unitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) async {
    await gate?.future;
    if (error != null) throw error!;
    creates.add(_Call(null, name, visitDate, arrivalTime, notes));
    return _visit('new-1', name: name);
  }

  @override
  Future<void> updateFastlaneVisit({
    required String visitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) async {
    if (error != null) throw error!;
    updates.add(_Call(visitId, name, visitDate, arrivalTime, notes));
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ProviderContainer _container(_Repository repository, Visit? editing) {
  final container = ProviderContainer(
    overrides: [
      visitsRepositoryProvider.overrideWithValue(repository),
      selectedMembershipProvider.overrideWith(_Membership.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(createFastlaneVisitControllerProvider(editing), (_, _) {});
  return container;
}

void main() {
  test('creates an invitation and emits the new visit', () async {
    final repo = _Repository();
    final container = _container(repo, null);
    await container.read(selectedMembershipProvider.future);
    final controller = container.read(
      createFastlaneVisitControllerProvider(null).notifier,
    );
    final events = <CreateFastlaneVisitEvent>[];
    controller.events.listen(events.add);

    controller.setVisitDate(DateTime(2026, 10, 2));
    controller.setArrivalTime(const TimeOfDay(hour: 18, minute: 30));
    await controller.submit(name: '  Ana  ', notes: '   ');
    await Future<void>.delayed(Duration.zero);

    final call = repo.creates.single;
    expect(call.name, 'Ana');
    expect(call.date, DateTime(2026, 10, 2));
    expect(call.arrival, const TimeOfDay(hour: 18, minute: 30));
    expect(call.notes, isNull);
    expect((events.single as FastlaneCreated).visit.id, 'new-1');
    expect(
      container.read(createFastlaneVisitControllerProvider(null)).isSubmitting,
      isFalse,
    );
  });

  test('editing prefills date/time and updates instead of creating', () async {
    final repo = _Repository();
    final editing = _visit('v-9', name: 'Luis');
    final container = _container(repo, editing);
    await container.read(selectedMembershipProvider.future);
    final state = container.read(
      createFastlaneVisitControllerProvider(editing),
    );
    expect(state.visitDate, editing.validFrom);
    expect(state.arrivalTime, const TimeOfDay(hour: 9, minute: 15));

    final controller = container.read(
      createFastlaneVisitControllerProvider(editing).notifier,
    );
    final events = <CreateFastlaneVisitEvent>[];
    controller.events.listen(events.add);
    await controller.submit(name: 'Luis P', notes: ' portón ');
    await Future<void>.delayed(Duration.zero);

    expect(repo.creates, isEmpty);
    expect(repo.updates.single.visitId, 'v-9');
    expect(repo.updates.single.notes, 'portón');
    expect(events.single, isA<FastlaneUpdated>());
  });

  test('a create failure is emitted as a typed failure', () async {
    final repo = _Repository()..error = const NetworkFailure();
    final container = _container(repo, null);
    await container.read(selectedMembershipProvider.future);
    final controller = container.read(
      createFastlaneVisitControllerProvider(null).notifier,
    );
    final events = <CreateFastlaneVisitEvent>[];
    controller.events.listen(events.add);

    await controller.submit(name: 'Ana', notes: '');
    await Future<void>.delayed(Duration.zero);

    expect(
      (events.single as FastlaneCreateFailed).failure,
      isA<NetworkFailure>(),
    );
    expect(
      container.read(createFastlaneVisitControllerProvider(null)).isSubmitting,
      isFalse,
    );
  });

  test('an untyped update error is wrapped as a Failure', () async {
    final repo = _Repository()..error = StateError('boom');
    final editing = _visit('v-9');
    final container = _container(repo, editing);
    await container.read(selectedMembershipProvider.future);
    final controller = container.read(
      createFastlaneVisitControllerProvider(editing).notifier,
    );
    final events = <CreateFastlaneVisitEvent>[];
    controller.events.listen(events.add);

    await controller.submit(name: 'Ana', notes: '');
    await Future<void>.delayed(Duration.zero);

    expect(
      (events.single as FastlaneUpdateFailed).failure,
      isA<UnknownFailure>(),
    );
  });

  test('ignores a second submit while one is in flight', () async {
    final repo = _Repository()..gate = Completer<void>();
    final container = _container(repo, null);
    await container.read(selectedMembershipProvider.future);
    final controller = container.read(
      createFastlaneVisitControllerProvider(null).notifier,
    );

    final first = controller.submit(name: 'Ana', notes: '');
    expect(
      container.read(createFastlaneVisitControllerProvider(null)).isSubmitting,
      isTrue,
    );
    await controller.submit(name: 'Ana', notes: '');
    repo.gate!.complete();
    await first;

    expect(repo.creates, hasLength(1));
  });
}
