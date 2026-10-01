import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/session/domain/membership.dart';
import 'package:gates_app/features/session/presentation/session_controller.dart';
import 'package:gates_app/features/visits/domain/provider_catalog_item.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/domain/visits_repository.dart';
import 'package:gates_app/features/visits/presentation/visit_details_controller.dart';
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

class _Delivery {
  _Delivery(this.name, this.kind, this.date, this.arrival, this.notes);
  final String name;
  final ProviderKind kind;
  final DateTime date;
  final DateTime? arrival;
  final String? notes;
}

class _Repository implements VisitsRepository {
  final deliveries = <_Delivery>[];
  Object? error;

  @override
  Future<void> createDeliveryVisit({
    required String residentialId,
    required String unitId,
    required String name,
    String? phone,
    String? plate,
    required ProviderKind providerKind,
    required DateTime visitDate,
    String? notes,
    DateTime? arrivalTime,
  }) async {
    if (error != null) throw error!;
    deliveries.add(
      _Delivery(name, providerKind, visitDate, arrivalTime, notes),
    );
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const _rappi = ProviderCatalogItem(
  id: 'p1',
  residentialId: null,
  name: 'Rappi',
  kind: ProviderKind.delivery,
);

ProviderContainer _container(_Repository repository, VisitDetailsArgs args) {
  final container = ProviderContainer(
    overrides: [
      visitsRepositoryProvider.overrideWithValue(repository),
      selectedMembershipProvider.overrideWith(_Membership.new),
    ],
  );
  addTearDown(container.dispose);
  container.listen(visitDetailsControllerProvider(args), (_, _) {});
  return container;
}

void main() {
  test(
    'authorizes a delivery with its arrival time and trimmed notes',
    () async {
      final repo = _Repository();
      const args = VisitDetailsArgs(
        kind: ProviderKind.delivery,
        provider: _rappi,
      );
      final container = _container(repo, args);
      await container.read(selectedMembershipProvider.future);
      final controller = container.read(
        visitDetailsControllerProvider(args).notifier,
      );
      final events = <VisitDetailsEvent>[];
      controller.events.listen(events.add);

      controller.setVisitDate(DateTime(2026, 10, 2));
      controller.setArrivalTime(const TimeOfDay(hour: 18, minute: 30));
      await controller.submit(customName: '', notes: '  Dejar en portería  ');
      await Future<void>.delayed(Duration.zero);

      final delivery = repo.deliveries.single;
      expect(delivery.name, 'Rappi');
      expect(delivery.kind, ProviderKind.delivery);
      expect(delivery.arrival, DateTime(2026, 10, 2, 18, 30));
      expect(delivery.notes, 'Dejar en portería');
      expect(events.single, isA<VisitAuthorized>());
      expect(
        container.read(visitDetailsControllerProvider(args)).isSubmitting,
        isFalse,
      );
    },
  );

  test(
    'a vendor visit has no arrival time and blank notes become null',
    () async {
      final repo = _Repository();
      const args = VisitDetailsArgs(kind: ProviderKind.proveedor);
      final container = _container(repo, args);
      await container.read(selectedMembershipProvider.future);

      await container
          .read(visitDetailsControllerProvider(args).notifier)
          .submit(customName: ' Técnico de aire ', notes: '   ');

      final delivery = repo.deliveries.single;
      expect(delivery.name, 'Técnico de aire');
      expect(delivery.arrival, isNull);
      expect(delivery.notes, isNull);
    },
  );

  test('without a provider or name it asks who is coming', () async {
    final repo = _Repository();
    const args = VisitDetailsArgs(kind: ProviderKind.delivery);
    final container = _container(repo, args);
    await container.read(selectedMembershipProvider.future);
    final controller = container.read(
      visitDetailsControllerProvider(args).notifier,
    );
    final events = <VisitDetailsEvent>[];
    controller.events.listen(events.add);

    await controller.submit(customName: '  ');
    await Future<void>.delayed(Duration.zero);

    expect(repo.deliveries, isEmpty);
    expect(events.single, isA<NeedsProvider>());
  });

  test(
    'a failed call reports a typed failure and re-enables the button',
    () async {
      final repo = _Repository()..error = TimeoutException('offline');
      const args = VisitDetailsArgs(
        kind: ProviderKind.delivery,
        provider: _rappi,
      );
      final container = _container(repo, args);
      await container.read(selectedMembershipProvider.future);
      final controller = container.read(
        visitDetailsControllerProvider(args).notifier,
      );
      final events = <VisitDetailsEvent>[];
      controller.events.listen(events.add);

      await controller.submit(customName: '');
      await Future<void>.delayed(Duration.zero);

      final failed = events.single as AuthorizeFailed;
      expect(failed.failure, isA<NetworkFailure>());
      expect(
        container.read(visitDetailsControllerProvider(args)).isSubmitting,
        isFalse,
      );
    },
  );

  test('switching to "Otro" or another kind updates what is needed', () async {
    final repo = _Repository();
    const args = VisitDetailsArgs(
      kind: ProviderKind.delivery,
      provider: _rappi,
    );
    final container = _container(repo, args);
    final controller = container.read(
      visitDetailsControllerProvider(args).notifier,
    );

    controller.changeProvider(null, ProviderKind.proveedor);

    final state = container.read(visitDetailsControllerProvider(args));
    expect(state.provider, isNull);
    expect(state.needsTime, isFalse);
  });
}
