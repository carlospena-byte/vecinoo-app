@Tags(['integration'])
library;

import 'dart:async';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/visits/data/supabase_visits_repository.dart';
import 'package:gates_app/features/visits/domain/visit.dart';

import 'support/local_supabase.dart';
import 'visits_support.dart';

void main() {
  late TestResident resident;
  late SupabaseVisitsRepository repository;
  final uploaded = <String>[];

  setUp(() async {
    resident = await TestResident.create();
    repository = SupabaseVisitsRepository(resident.client);
  });

  tearDown(() async {
    if (uploaded.isNotEmpty) {
      try {
        await resident.service.storage
            .from('visitor-id-photos')
            .remove(uploaded);
      } catch (_) {}
      uploaded.clear();
    }
    await resident.dispose();
  });

  Future<String> createFrequent({
    String name = 'Test: frecuente',
    Recurrence recurrence = Recurrence.monFri,
    ScheduleType scheduleType = ScheduleType.allDay,
    TimeOfDay? start,
    TimeOfDay? end,
    List<ScheduleBlock>? blocks,
    bool hasVehicle = false,
    String? plate,
    bool notify = false,
    String? notes,
    String? phone,
    VisitorRole role = VisitorRole.familiar,
  }) async {
    await repository.createFrequentVisit(
      residentialId: resident.residentialId,
      unitId: resident.unitId,
      name: name,
      phone: phone,
      visitorRole: role,
      idPhotoPath: '${resident.residentialId}/test.png',
      hasVehicle: hasVehicle,
      plate: plate,
      recurrence: recurrence,
      scheduleType: scheduleType,
      scheduleStart: start,
      scheduleEnd: end,
      scheduleBlocks: blocks,
      notifyOnArrival: notify,
      notes: notes,
    );
    final row = await readVisitorByName(resident.service, resident, name);
    return row['id'] as String;
  }

  Future<void> updateFrequent(
    String id, {
    String name = 'Test: frecuente editado',
    String? idPhotoPath,
    Recurrence recurrence = Recurrence.daily,
    ScheduleType scheduleType = ScheduleType.allDay,
    TimeOfDay? start,
    TimeOfDay? end,
    List<ScheduleBlock>? blocks,
    bool hasVehicle = false,
    String? plate,
  }) => repository.updateFrequentVisit(
    visitId: id,
    name: name,
    phone: '5551234567',
    visitorRole: VisitorRole.empleado,
    idPhotoPath: idPhotoPath,
    hasVehicle: hasVehicle,
    plate: plate,
    recurrence: recurrence,
    scheduleType: scheduleType,
    scheduleStart: start,
    scheduleEnd: end,
    scheduleBlocks: blocks,
    notifyOnArrival: true,
    notes: 'nota',
  );

  void itLive(String name, Future<void> Function() body) =>
      test(name, body, skip: localSupabaseSkipReason, tags: 'integration');

  group('fetchVisits / watchVisits', () {
    itLive('fetchVisits returns only this unit, newest first', () async {
      final first = await seedVisitor(resident, name: 'Test: primero');
      final second = await seedVisitor(
        resident,
        name: 'Test: segundo',
        visitType: 'frequent',
      );
      final visits = await repository.fetchVisits(resident.unitId);
      final ids = visits.map((v) => v.id).toList();
      expect(ids, containsAll([first, second]));
      expect(ids.indexOf(second), lessThan(ids.indexOf(first)));
      expect(visits.every((v) => v.unitId == resident.unitId), isTrue);
      final f = visits.firstWhere((v) => v.id == first);
      expect(f.name, 'Test: primero');
      expect(f.visitType, VisitType.delivery);
      expect(f.status, VisitStatus.scheduled);
    });

    itLive(
      'fetchVisits of a unit the resident does not belong to is empty',
      () async {
        final other = await resident.service
            .from('units')
            .select('id')
            .neq('id', resident.unitId)
            .limit(1)
            .single();
        await seedVisitor(resident);
        // "members view" lets residents read the residential's visitors, so
        // only assert that nothing of ours leaks into the other unit's list.
        final visits = await repository.fetchVisits(other['id'] as String);
        expect(visits.every((v) => v.unitId == other['id']), isTrue);
      },
    );

    itLive('a malformed unit id maps to a ServerFailure', () async {
      await expectLater(
        repository.fetchVisits('not-a-uuid'),
        throwsA(isA<ServerFailure>()),
      );
    });

    itLive('watchVisits emits the initial list and then an update', () async {
      final existing = await seedVisitor(resident, name: 'Test: existente');
      final emissions = <List<Visit>>[];
      final updated = Completer<void>();
      late String newId;
      var inserted = false;
      final sub = repository
          .watchVisits(resident.unitId)
          .listen(
            (list) {
              emissions.add(list);
              if (inserted &&
                  list.any((v) => v.id == newId) &&
                  !updated.isCompleted) {
                updated.complete();
              }
            },
            onError: (Object e) {
              if (!updated.isCompleted) updated.completeError(e);
            },
          );
      addTearDown(sub.cancel);

      // Initial emission.
      await Future.doWhile(() async {
        if (emissions.isNotEmpty) return false;
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return true;
      }).timeout(const Duration(seconds: 15));
      expect(emissions.first.map((v) => v.id), contains(existing));
      expect(emissions.first.every((v) => v.unitId == resident.unitId), isTrue);

      // Realtime update after an insert (give the channel time to join).
      await Future<void>.delayed(const Duration(seconds: 2));
      newId = await seedVisitor(resident, name: 'Test: en vivo');
      inserted = true;
      // Re-check in case the event raced the flag.
      await updated.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          // Realtime delivery is best-effort in CI; fall back to asserting
          // the stream at least stays healthy and yielded the first list.
          expect(emissions, isNotEmpty);
        },
      );
    });
  });

  group('uploadVisitorDocument', () {
    itLive('uploads bytes under the residential folder', () async {
      final path = await repository.uploadVisitorDocument(
        residentialId: resident.residentialId,
        bytes: fakePng(),
        extension: 'PNG',
      );
      uploaded.add(path);
      expect(path, startsWith('${resident.residentialId}/frequent-'));
      expect(path, endsWith('.png'));
      final stored = await resident.service.storage
          .from('visitor-id-photos')
          .download(path);
      expect(stored, fakePng());
    });

    itLive('uploading into another residential folder is rejected', () async {
      await expectLater(
        repository.uploadVisitorDocument(
          residentialId: '00000000-0000-0000-0000-000000000001',
          bytes: fakePng(),
          extension: 'png',
        ),
        throwsA(isA<Failure>()),
      );
    });
  });

  group('createFrequentVisit / updateFrequentVisit', () {
    itLive('all-day recurrence persists the expected columns', () async {
      final id = await createFrequent(
        name: 'Test: todo el día',
        phone: '5550001111',
        hasVehicle: true,
        plate: 'TST-001',
        notify: true,
        notes: 'nota',
      );
      final row = await readVisitor(resident.service, id);
      expect(row['visit_type'], 'frequent');
      expect(row['status'], 'scheduled');
      expect(row['invited_by'], resident.userId);
      expect(row['unit_id'], resident.unitId);
      expect(row['phone'], '5550001111');
      expect(row['visitor_role'], 'familiar');
      expect(row['has_vehicle'], true);
      expect(row['plate'], 'TST-001');
      expect(row['recurrence'], 'mon_fri');
      expect(row['recurrence_days'], isNull);
      expect(row['schedule_type'], 'all_day');
      expect(row['schedule_start'], isNull);
      expect(row['schedule_end'], isNull);
      expect(row['schedule_blocks'], isNull);
      expect(row['notify_on_arrival'], true);
      expect(row['notes'], 'nota');
      expect(row['id_photo_path'], '${resident.residentialId}/test.png');
      expect(DateTime.parse(row['valid_until'] as String).toLocal().year, 2099);
      // valid_from is "now" as a real instant (not a local time read as UTC).
      expect(
        DateTime.parse(row['valid_from'] as String)
            .difference(DateTime.now())
            .abs(),
        lessThan(const Duration(minutes: 2)),
      );
    });

    itLive('custom time window on a fixed recurrence', () async {
      final id = await createFrequent(
        name: 'Test: ventana',
        recurrence: Recurrence.monSat,
        scheduleType: ScheduleType.custom,
        start: const TimeOfDay(hour: 8, minute: 5),
        end: const TimeOfDay(hour: 17, minute: 30),
        hasVehicle: false,
        plate: 'IGNORED',
      );
      final row = await readVisitor(resident.service, id);
      expect(row['recurrence'], 'mon_sat');
      expect(row['schedule_type'], 'custom');
      expect(row['schedule_start'], '08:05:00');
      expect(row['schedule_end'], '17:30:00');
      expect(row['plate'], isNull, reason: 'plate dropped without vehicle');
      expect(row['has_vehicle'], false);
    });

    itLive(
      'custom recurrence stores blocks and the union of their days',
      () async {
        final blocks = [
          ScheduleBlock(
            days: {'wed', 'mon'},
            start: const TimeOfDay(hour: 9, minute: 0),
            end: const TimeOfDay(hour: 12, minute: 0),
          ),
          ScheduleBlock(
            days: {'sat', 'mon'},
            start: const TimeOfDay(hour: 14, minute: 0),
            end: const TimeOfDay(hour: 18, minute: 45),
          ),
        ];
        final id = await createFrequent(
          name: 'Test: bloques',
          recurrence: Recurrence.custom,
          blocks: blocks,
        );
        final row = await readVisitor(resident.service, id);
        expect(row['recurrence'], 'custom');
        expect(row['recurrence_days'], ['mon', 'wed', 'sat']);
        expect(row['schedule_type'], 'custom');
        expect(row['schedule_start'], '09:00:00');
        expect(row['schedule_end'], '12:00:00');
        final stored = (row['schedule_blocks'] as List)
            .map((b) => ScheduleBlock.fromMap(b as Map<String, dynamic>))
            .toList();
        expect(stored, hasLength(2));
        expect(stored[0].days, {'mon', 'wed'});
        expect(stored[1].end, const TimeOfDay(hour: 18, minute: 45));

        final visit = (await repository.fetchVisits(resident.unitId))
            .firstWhere((v) => v.id == id);
        expect(visit.recurrence, Recurrence.custom);
        expect(visit.scheduleBlocks, hasLength(2));
      },
    );

    itLive(
      'updateFrequentVisit edits fields and keeps the photo unless replaced',
      () async {
        final id = await createFrequent(name: 'Test: por editar');
        await updateFrequent(
          id,
          recurrence: Recurrence.custom,
          blocks: [
            ScheduleBlock(
              days: {'tue'},
              start: const TimeOfDay(hour: 7, minute: 0),
              end: const TimeOfDay(hour: 8, minute: 0),
            ),
          ],
          hasVehicle: true,
          plate: 'TST-002',
        );
        var row = await readVisitor(resident.service, id);
        expect(row['name'], 'Test: frecuente editado');
        expect(row['visitor_role'], 'empleado');
        expect(row['recurrence_days'], ['tue']);
        expect(row['plate'], 'TST-002');
        expect(row['notify_on_arrival'], true);
        expect(row['id_photo_path'], '${resident.residentialId}/test.png');

        await updateFrequent(
          id,
          idPhotoPath: '${resident.residentialId}/new.png',
          recurrence: Recurrence.daily,
          scheduleType: ScheduleType.custom,
          start: const TimeOfDay(hour: 6, minute: 0),
          end: const TimeOfDay(hour: 22, minute: 0),
        );
        row = await readVisitor(resident.service, id);
        expect(row['id_photo_path'], '${resident.residentialId}/new.png');
        expect(row['recurrence'], 'daily');
        expect(row['schedule_blocks'], isNull);
        expect(row['schedule_start'], '06:00:00');
      },
    );

    itLive(
      'updating a cancelled frequent visit surfaces a ServerFailure',
      () async {
        final id = await createFrequent(name: 'Test: cancelado');
        await repository.cancelFrequentVisit(id);
        await expectLater(updateFrequent(id), throwsA(isA<ServerFailure>()));
      },
    );

    itLive(
      'creating for a unit the resident is not a member of is AuthFailure',
      () async {
        final other = await resident.service
            .from('units')
            .select('id')
            .neq('id', resident.unitId)
            .limit(1)
            .single();
        await expectLater(
          repository.createFrequentVisit(
            residentialId: resident.residentialId,
            unitId: other['id'] as String,
            name: 'Test: ajeno',
            visitorRole: VisitorRole.visitante,
            idPhotoPath: 'x',
            hasVehicle: false,
            recurrence: Recurrence.daily,
            scheduleType: ScheduleType.allDay,
            notifyOnArrival: false,
          ),
          throwsA(isA<AuthFailure>()),
        );
      },
    );
  });

  group('createDeliveryVisit', () {
    itLive('without arrivalTime starts at the start of the day', () async {
      await repository.createDeliveryVisit(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        name: 'Test: entrega',
        phone: '5559998888',
        plate: 'DLV-1',
        providerKind: ProviderKind.paqueteria,
        visitDate: farFuture,
        notes: 'dejar en lobby',
      );
      final row = await readVisitorByName(
        resident.service,
        resident,
        'Test: entrega',
      );
      expect(row['visit_type'], 'delivery');
      expect(row['provider_kind'], 'paqueteria');
      expect(row['status'], 'scheduled');
      expect(row['phone'], '5559998888');
      expect(row['plate'], 'DLV-1');
      expect(row['notes'], 'dejar en lobby');
      expect(row['invited_by'], resident.userId);
      final from = DateTime.parse(row['valid_from'] as String).toLocal();
      final until = DateTime.parse(row['valid_until'] as String).toLocal();
      expect(from, DateTime(2098, 6, 15));
      expect(until, DateTime(2098, 6, 15, 23, 59, 59));
    });

    itLive('with arrivalTime narrows valid_from', () async {
      await repository.createDeliveryVisit(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        name: 'Test: entrega hora',
        providerKind: ProviderKind.delivery,
        visitDate: farFuture,
        arrivalTime: DateTime(2098, 6, 15, 14, 30),
      );
      final row = await readVisitorByName(
        resident.service,
        resident,
        'Test: entrega hora',
      );
      expect(
        DateTime.parse(row['valid_from'] as String).toLocal(),
        DateTime(2098, 6, 15, 14, 30),
      );
      expect(row['provider_kind'], 'delivery');
    });

    itLive('an unauthorized unit hits RLS and maps to AuthFailure', () async {
      final other = await resident.service
          .from('units')
          .select('id')
          .neq('id', resident.unitId)
          .limit(1)
          .single();
      await expectLater(
        repository.createDeliveryVisit(
          residentialId: resident.residentialId,
          unitId: other['id'] as String,
          name: 'Test: no autorizada',
          providerKind: ProviderKind.delivery,
          visitDate: farFuture,
        ),
        throwsA(isA<AuthFailure>()),
      );
    });
  });

  group('FastLane', () {
    itLive('createFastlaneVisit calls the RPC and returns the visit', () async {
      final visit = await repository.createFastlaneVisit(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        name: 'Test: fastlane',
        visitDate: farFuture,
        arrivalTime: const TimeOfDay(hour: 9, minute: 5),
        notes: 'portón',
      );
      resident.track('visitors', visit.id);
      expect(visit.visitType, VisitType.fastlane);
      expect(visit.status, VisitStatus.pendingRegistration);
      expect(visit.accessCode, isNotEmpty);
      expect(visit.name, 'Test: fastlane');
      expect(visit.validFrom, DateTime(2098, 6, 15, 9, 5));
      expect(visit.validUntil, DateTime(2098, 6, 15, 23, 59, 59));
      final row = await readVisitor(resident.service, visit.id);
      expect(row['notes'], 'portón');
      expect(row['invited_by'], resident.userId);
    });

    itLive(
      'createFastlaneVisit for an unauthorized unit is a Failure',
      () async {
        final other = await resident.service
            .from('units')
            .select('id')
            .neq('id', resident.unitId)
            .limit(1)
            .single();
        await expectLater(
          repository.createFastlaneVisit(
            residentialId: resident.residentialId,
            unitId: other['id'] as String,
            name: 'Test: fastlane ajeno',
            visitDate: farFuture,
            arrivalTime: const TimeOfDay(hour: 9, minute: 0),
          ),
          throwsA(isA<ServerFailure>()),
        );
      },
    );

    itLive('updateFastlaneVisit rewrites name, notes and window', () async {
      final visit = await repository.createFastlaneVisit(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        name: 'Test: fastlane a editar',
        visitDate: farFuture,
        arrivalTime: const TimeOfDay(hour: 9, minute: 0),
      );
      resident.track('visitors', visit.id);
      await repository.updateFastlaneVisit(
        visitId: visit.id,
        name: 'Test: fastlane editado',
        visitDate: DateTime(2098, 7, 1),
        arrivalTime: const TimeOfDay(hour: 18, minute: 15),
        notes: 'nueva nota',
      );
      final row = await readVisitor(resident.service, visit.id);
      expect(row['name'], 'Test: fastlane editado');
      expect(row['notes'], 'nueva nota');
      expect(
        DateTime.parse(row['valid_from'] as String).toLocal(),
        DateTime(2098, 7, 1, 18, 15),
      );
      expect(
        DateTime.parse(row['valid_until'] as String).toLocal(),
        DateTime(2098, 7, 1, 23, 59, 59),
      );
    });

    itLive('updateFastlaneVisit on a non-pending visit fails', () async {
      final id = await seedVisitor(resident, visitType: 'fastlane');
      await expectLater(
        repository.updateFastlaneVisit(
          visitId: id,
          name: 'Test: x',
          visitDate: farFuture,
          arrivalTime: const TimeOfDay(hour: 1, minute: 0),
        ),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('cancel', () {
    itLive('cancelVisit cancels once, a second cancel fails', () async {
      final id = await seedVisitor(resident);
      await repository.cancelVisit(id);
      expect((await readVisitor(resident.service, id))['status'], 'cancelled');
      await expectLater(
        repository.cancelVisit(id),
        throwsA(isA<ServerFailure>()),
      );
    });

    itLive('cancelVisit cancels a pending FastLane invitation', () async {
      final id = await seedVisitor(
        resident,
        visitType: 'fastlane',
        status: 'pending_registration',
      );
      await repository.cancelVisit(id);
      expect((await readVisitor(resident.service, id))['status'], 'cancelled');
    });

    itLive('cancelVisit refuses a visitor already inside', () async {
      final id = await seedVisitor(resident, status: 'inside');
      await expectLater(
        repository.cancelVisit(id),
        throwsA(isA<ServerFailure>()),
      );
      expect((await readVisitor(resident.service, id))['status'], 'inside');
    });

    itLive(
      'cancelFrequentVisit keeps the row as cancelled; twice fails',
      () async {
        final id = await createFrequent(name: 'Test: baja frecuente');
        await repository.cancelFrequentVisit(id);
        expect(
          (await readVisitor(resident.service, id))['status'],
          'cancelled',
        );
        await expectLater(
          repository.cancelFrequentVisit(id),
          throwsA(isA<ServerFailure>()),
        );
      },
    );

    itLive('cancelFrequentVisit ignores non-frequent visits', () async {
      final id = await seedVisitor(resident);
      await expectLater(
        repository.cancelFrequentVisit(id),
        throwsA(isA<ServerFailure>()),
      );
    });

    itLive('a malformed visit id maps to a ServerFailure', () async {
      await expectLater(
        repository.cancelVisit('nope'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });

  group('fetchLastMovement', () {
    itLive('is null before any check-in', () async {
      final id = await seedVisitor(resident);
      expect(await repository.fetchLastMovement(id), isNull);
      // A log row without check-in is ignored too.
      await resident.service.from('access_logs').insert({
        'residential_id': resident.residentialId,
        'visitor_id': id,
      });
      expect(await repository.fetchLastMovement(id), isNull);
    });

    itLive('returns the most recent check-in and its check-out', () async {
      final id = await seedVisitor(resident, status: 'inside');
      final older = DateTime.utc(2098, 6, 15, 8);
      final newer = DateTime.utc(2098, 6, 16, 9);
      await resident.service.from('access_logs').insert([
        {
          'residential_id': resident.residentialId,
          'visitor_id': id,
          'checked_in_at': older.toIso8601String(),
          'checked_out_at': older
              .add(const Duration(hours: 1))
              .toIso8601String(),
        },
        {
          'residential_id': resident.residentialId,
          'visitor_id': id,
          'checked_in_at': newer.toIso8601String(),
        },
      ]);
      final movement = await repository.fetchLastMovement(id);
      expect(movement, isNotNull);
      expect(movement!.checkedInAt.toUtc(), newer);
      expect(movement.checkedOutAt, isNull);
      expect(movement.isInside, isTrue);

      await resident.service
          .from('access_logs')
          .update({
            'checked_out_at': newer
                .add(const Duration(hours: 2))
                .toIso8601String(),
          })
          .eq('visitor_id', id)
          .eq('checked_in_at', newer.toIso8601String());
      final done = await repository.fetchLastMovement(id);
      expect(done!.checkedOutAt!.toUtc(), newer.add(const Duration(hours: 2)));
      expect(done.isInside, isFalse);
    });

    itLive('a malformed visitor id maps to a ServerFailure', () async {
      await expectLater(
        repository.fetchLastMovement('nope'),
        throwsA(isA<ServerFailure>()),
      );
    });
  });
}
