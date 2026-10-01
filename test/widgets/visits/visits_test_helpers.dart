import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:gates_app/features/visits/data/providers_catalog_repository.dart';
import 'package:gates_app/features/visits/domain/access_movement.dart';
import 'package:gates_app/features/visits/domain/provider_catalog_item.dart';
import 'package:gates_app/features/visits/domain/visit.dart';
import 'package:gates_app/features/visits/domain/visits_repository.dart';

/// Builds a [Visit] with sensible defaults; [day] shifts validFrom/validUntil
/// relative to today (0 = today, 1 = tomorrow...).
Visit makeVisit({
  String id = 'v1',
  String? name = 'Rappi',
  VisitStatus status = VisitStatus.scheduled,
  VisitType type = VisitType.delivery,
  int day = 0,
  int hour = 14,
  ProviderKind? providerKind = ProviderKind.delivery,
  VisitorRole? role,
  Recurrence? recurrence,
  ScheduleType? scheduleType,
  List<ScheduleBlock>? blocks,
  String? plate,
  bool hasVehicle = false,
  String? notes,
  String? accessCode,
  String? phone,
  String? idPhotoPath,
  DateTime? validFrom,
  DateTime? validUntil,
}) {
  final now = DateTime.now();
  final base = DateTime(now.year, now.month, now.day + day, hour);
  return Visit(
    id: id,
    unitId: 'unit-1',
    name: name,
    phone: phone,
    plate: plate,
    status: status,
    visitType: type,
    visitorRole: role,
    providerKind: providerKind,
    recurrence: recurrence,
    scheduleType: scheduleType,
    scheduleBlocks: blocks,
    hasVehicle: hasVehicle,
    notes: notes,
    accessCode: accessCode,
    idPhotoPath: idPhotoPath,
    validFrom: validFrom ?? base,
    validUntil: validUntil ?? DateTime(base.year, base.month, base.day, 23, 59),
    createdAt: base,
  );
}

/// In-memory [VisitsRepository]. Push rows with [emit]; every write is
/// recorded and any call throws [error] when set.
class FakeVisitsRepository implements VisitsRepository {
  FakeVisitsRepository([List<Visit> initial = const []]) {
    _current = initial;
  }

  late List<Visit> _current;
  final _controller = StreamController<List<Visit>>.broadcast();

  /// When set, [watchVisits] emits this error instead of data.
  Object? watchError;

  /// When true, [watchVisits] never emits (loading state).
  bool neverEmit = false;

  Object? error;
  Completer<void>? gate;

  /// Simulated network latency for writes (advanced by `tester.pump`).
  Duration latency = Duration.zero;
  AccessMovement? movement;

  int watchCalls = 0;
  final cancelled = <String>[];
  final cancelledFrequent = <String>[];
  final deliveries = <({String name, ProviderKind kind, String? notes})>[];
  final fastlaneCreated = <({String name, String? notes})>[];
  final fastlaneUpdated = <({String id, String name, String? notes})>[];
  final frequentCreated = <Map<String, Object?>>[];
  final frequentUpdated = <Map<String, Object?>>[];
  final uploads = <String>[];
  Visit? fastlaneResult;

  void emit(List<Visit> visits) {
    _current = visits;
    _controller.add(visits);
  }

  Future<void> _maybeFail() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    if (gate != null) await gate!.future;
    if (error != null) throw error!;
  }

  @override
  Stream<List<Visit>> watchVisits(String unitId) async* {
    watchCalls++;
    if (watchError != null) throw watchError!;
    if (neverEmit) {
      await Completer<void>().future;
    }
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<List<Visit>> fetchVisits(String unitId) async => _current;

  @override
  Future<AccessMovement?> fetchLastMovement(String visitId) async => movement;

  @override
  Future<void> cancelVisit(String visitId) async {
    await _maybeFail();
    cancelled.add(visitId);
  }

  @override
  Future<void> cancelFrequentVisit(String visitId) async {
    await _maybeFail();
    cancelledFrequent.add(visitId);
  }

  @override
  Future<String> uploadVisitorDocument({
    required String residentialId,
    required Uint8List bytes,
    required String extension,
  }) async {
    await _maybeFail();
    uploads.add(extension);
    return '$residentialId/doc.$extension';
  }

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
    await _maybeFail();
    deliveries.add((name: name, kind: providerKind, notes: notes));
  }

  @override
  Future<Visit> createFastlaneVisit({
    required String residentialId,
    required String unitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) async {
    await _maybeFail();
    fastlaneCreated.add((name: name, notes: notes));
    return fastlaneResult ??
        makeVisit(
          id: 'new-1',
          name: name,
          type: VisitType.fastlane,
          status: VisitStatus.pendingRegistration,
          accessCode: 'CODE1',
        );
  }

  @override
  Future<void> updateFastlaneVisit({
    required String visitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) async {
    await _maybeFail();
    fastlaneUpdated.add((id: visitId, name: name, notes: notes));
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
    await _maybeFail();
    frequentCreated.add({
      'name': name,
      'phone': phone,
      'role': visitorRole,
      'photo': idPhotoPath,
      'hasVehicle': hasVehicle,
      'plate': plate,
      'recurrence': recurrence,
      'scheduleType': scheduleType,
      'blocks': scheduleBlocks,
      'notify': notifyOnArrival,
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
    await _maybeFail();
    frequentUpdated.add({
      'id': visitId,
      'name': name,
      'phone': phone,
      'photo': idPhotoPath,
      'plate': plate,
      'notes': notes,
    });
  }
}

/// Catalog fake: items per kind, optional error.
class FakeCatalogRepository implements ProvidersCatalogRepository {
  FakeCatalogRepository(this.items);

  final Map<ProviderKind, List<ProviderCatalogItem>> items;
  Object? error;
  final requested = <ProviderKind>[];

  @override
  Future<List<ProviderCatalogItem>> fetchCatalog({
    required String residentialId,
    required ProviderKind kind,
  }) async {
    requested.add(kind);
    if (error != null) throw error!;
    return items[kind] ?? const [];
  }

  @override
  noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

const rappi = ProviderCatalogItem(
  id: 'p-rappi',
  residentialId: null,
  name: 'Rappi',
  kind: ProviderKind.delivery,
);
const dhl = ProviderCatalogItem(
  id: 'p-dhl',
  residentialId: 'res-1',
  name: 'DHL Express',
  kind: ProviderKind.paqueteria,
);
const plomero = ProviderCatalogItem(
  id: 'p-plomero',
  residentialId: null,
  name: 'Control de plagas',
  kind: ProviderKind.proveedor,
);

FakeCatalogRepository defaultCatalog() => FakeCatalogRepository({
  ProviderKind.delivery: [
    rappi,
    const ProviderCatalogItem(
      id: 'p-uber',
      residentialId: null,
      name: 'Uber Eats',
      kind: ProviderKind.delivery,
    ),
  ],
  ProviderKind.paqueteria: [dhl],
  ProviderKind.proveedor: [plomero],
});

/// Drives the shared calendar sheet: next month, day 15, confirm. Returns the
/// picked date (local midnight).
Future<DateTime> pickNextMonthDay15(
  WidgetTester tester,
  String confirmLabel,
) async {
  final now = DateTime.now();
  await tester.fling(find.byType(TableCalendar), const Offset(-400, 0), 1500);
  await tester.pumpAndSettle();
  await tester.tap(find.text('15'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(confirmLabel));
  await tester.pumpAndSettle();
  return DateTime(now.year, now.month + 1, 15);
}
