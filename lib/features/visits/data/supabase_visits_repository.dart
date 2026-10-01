import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart' show TimeOfDay;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/access_movement.dart';
import '../domain/visit.dart';
import '../domain/visits_repository.dart';

/// Supabase-backed [VisitsRepository]; every call surfaces errors as
/// `Failure`s.
class SupabaseVisitsRepository implements VisitsRepository {
  SupabaseVisitsRepository(this._client);

  final SupabaseClient _client;

  /// Only this unit's visits — the resident's own, per the "members manage
  /// own unit" RLS policy (they could also see every visitor in the
  /// residential via "members view", but that's not what this screen shows).
  @override
  Future<List<Visit>> fetchVisits(String unitId) => guardFailure(() async {
    final rows = await _client
        .from('visitors')
        .select()
        .eq('unit_id', unitId)
        .order('created_at', ascending: false);
    return (rows as List)
        .map((row) => Visit.fromMap(row as Map<String, dynamic>))
        .toList();
  });

  /// Same rows as [fetchVisits], but live: Supabase Realtime pushes any
  /// insert/update/delete on this unit's visitors (e.g. a guard's check-in
  /// flipping status to "inside") straight into this stream, so the list
  /// updates without a manual pull-to-refresh.
  @override
  Stream<List<Visit>> watchVisits(String unitId) {
    return _client
        .from('visitors')
        .stream(primaryKey: ['id'])
        .eq('unit_id', unitId)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(Visit.fromMap).toList())
        .transform(
          StreamTransformer.fromHandlers(
            handleError: (error, stackTrace, sink) =>
                sink.addError(Failure.from(error), stackTrace),
          ),
        );
  }

  /// Uploads the visitor's ID photo to the private `visitor-id-photos` bucket
  /// (folder = residential id, which the member-insert policy checks) and
  /// returns its storage path.
  @override
  Future<String> uploadVisitorDocument({
    required String residentialId,
    required Uint8List bytes,
    required String extension,
  }) => guardFailure(() async {
    final storagePath =
        '$residentialId/frequent-${DateTime.now().millisecondsSinceEpoch}.${extension.toLowerCase()}';
    await _client.storage
        .from('visitor-id-photos')
        .uploadBinary(storagePath, bytes);
    return storagePath;
  });

  /// Columns a frequent visit's form controls, shared by create and update.
  /// Custom frequency is described by its blocks; the legacy columns get the
  /// union of their days and the first block's window.
  Map<String, dynamic> _frequentFields({
    required String name,
    String? phone,
    required VisitorRole visitorRole,
    required bool hasVehicle,
    String? plate,
    required Recurrence recurrence,
    required ScheduleType scheduleType,
    TimeOfDay? scheduleStart,
    TimeOfDay? scheduleEnd,
    List<ScheduleBlock>? scheduleBlocks,
    required bool notifyOnArrival,
    String? notes,
  }) {
    final isCustom = recurrence == Recurrence.custom;
    final blocks = isCustom ? scheduleBlocks! : null;
    final customSchedule = isCustom || scheduleType == ScheduleType.custom;
    final start = isCustom ? blocks!.first.start : scheduleStart;
    final end = isCustom ? blocks!.first.end : scheduleEnd;
    return {
      'name': name,
      'phone': phone,
      'plate': hasVehicle ? plate : null,
      'has_vehicle': hasVehicle,
      'visitor_role': visitorRole.name,
      'recurrence': recurrenceToDb(recurrence),
      'recurrence_days': isCustom
          ? [
              for (final day in weekdayKeys)
                if (blocks!.any((b) => b.days.contains(day))) day,
            ]
          : null,
      'schedule_type': customSchedule ? 'custom' : 'all_day',
      'schedule_start': customSchedule ? timeToDb(start!) : null,
      'schedule_end': customSchedule ? timeToDb(end!) : null,
      'schedule_blocks': blocks?.map((b) => b.toMap()).toList(),
      'notify_on_arrival': notifyOnArrival,
      'notes': notes,
    };
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
  }) => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('visitors').insert({
      'residential_id': residentialId,
      'unit_id': unitId,
      'invited_by': userId,
      'id_photo_path': idPhotoPath,
      'visit_type': 'frequent',
      ..._frequentFields(
        name: name,
        phone: phone,
        visitorRole: visitorRole,
        hasVehicle: hasVehicle,
        plate: plate,
        recurrence: recurrence,
        scheduleType: scheduleType,
        scheduleStart: scheduleStart,
        scheduleEnd: scheduleEnd,
        scheduleBlocks: scheduleBlocks,
        notifyOnArrival: notifyOnArrival,
        notes: notes,
      ),
      // Open-ended: active until the resident cancels it.
      'valid_from': DateTime.now().toIso8601String(),
      'valid_until': DateTime(2099, 12, 31).toIso8601String(),
    });
  });

  /// Edits a still-active frequent visit. [idPhotoPath] is only sent when the
  /// resident replaced the document. `.select().single()` makes a
  /// silently-filtered (0 rows) update surface as an error.
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
  }) => guardFailure(() async {
    await _client
        .from('visitors')
        .update({
          'id_photo_path': ?idPhotoPath,
          ..._frequentFields(
            name: name,
            phone: phone,
            visitorRole: visitorRole,
            hasVehicle: hasVehicle,
            plate: plate,
            recurrence: recurrence,
            scheduleType: scheduleType,
            scheduleStart: scheduleStart,
            scheduleEnd: scheduleEnd,
            scheduleBlocks: scheduleBlocks,
            notifyOnArrival: notifyOnArrival,
            notes: notes,
          ),
        })
        .eq('id', visitId)
        .eq('visit_type', 'frequent')
        .inFilter('status', ['scheduled', 'active', 'inside'])
        .select()
        .single();
  });

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
    // Narrows access to start at this time of day instead of midnight —
    // used by the "Hora de llegada" field on delivery/paquetería visits.
    DateTime? arrivalTime,
  }) => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    final dayStart =
        arrivalTime ?? DateTime(visitDate.year, visitDate.month, visitDate.day);
    final dayEnd = DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
      23,
      59,
      59,
    );
    await _client.from('visitors').insert({
      'residential_id': residentialId,
      'unit_id': unitId,
      'invited_by': userId,
      'name': name,
      'phone': phone,
      'plate': plate,
      'visit_type': 'delivery',
      'provider_kind': providerKind.name,
      'notes': notes,
      'valid_from': dayStart.toIso8601String(),
      'valid_until': dayEnd.toIso8601String(),
    });
  });

  /// Creates the FastLane row via the create_fastlane_visit RPC (so
  /// access_code is always server-generated) and returns the shareable
  /// self-registration link. The resident shares it themselves through the
  /// device's native share sheet — this no longer triggers a backend
  /// SMS/WhatsApp send, so there's no phone number to collect.
  @override
  Future<Visit> createFastlaneVisit({
    required String residentialId,
    required String unitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) => guardFailure(() async {
    final created = await _client
        .rpc(
          'create_fastlane_visit',
          params: {
            '_residential_id': residentialId,
            '_unit_id': unitId,
            '_visit_date':
                '${visitDate.year.toString().padLeft(4, '0')}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}',
            '_name': name,
            '_arrival_time':
                '${arrivalTime.hour.toString().padLeft(2, '0')}:${arrivalTime.minute.toString().padLeft(2, '0')}:00',
            '_notes': notes,
            // So the server can compute valid_from/valid_until against this
            // resident's own local midnight instead of UTC midnight — see
            // 20261102000000_fastlane_visit_local_tz.sql.
            '_tz_offset_minutes': visitDate.timeZoneOffset.inMinutes,
          },
        )
        .single();

    return Visit.fromMap(created);
  });

  /// Edits a still-pending FastLane invitation. Mirrors what
  /// create_fastlane_visit computes server-side: valid_from is the chosen
  /// day at the arrival time, valid_until is the end of that day, both in the
  /// resident's own timezone (sent as UTC instants). The "members update own
  /// unit" RLS policy allows this direct update; `.select().single()` makes a
  /// silently-filtered (0 rows) update surface as an error instead.
  @override
  Future<void> updateFastlaneVisit({
    required String visitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  }) => guardFailure(() async {
    final validFrom = DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
      arrivalTime.hour,
      arrivalTime.minute,
    );
    final validUntil = DateTime(
      visitDate.year,
      visitDate.month,
      visitDate.day,
      23,
      59,
      59,
    );
    await _client
        .from('visitors')
        .update({
          'name': name,
          'notes': notes,
          'valid_from': validFrom.toUtc().toIso8601String(),
          'valid_until': validUntil.toUtc().toIso8601String(),
        })
        .eq('id', visitId)
        .eq('status', 'pending_registration')
        .select()
        .single();
  });

  /// Cancels a visit that hasn't happened yet: a FastLane invitation still
  /// waiting for its data (its link stops working because fastlane-submit only
  /// accepts `pending_registration` rows) or a scheduled/active delivery.
  /// `.select().single()` surfaces a silently-filtered update as an error.
  @override
  Future<void> cancelVisit(String visitId) => guardFailure(() async {
    await _client
        .from('visitors')
        .update({'status': 'cancelled'})
        .eq('id', visitId)
        .inFilter('status', ['pending_registration', 'scheduled', 'active'])
        .select()
        .single();
  });

  /// Ends a frequent visit's standing access. The row stays (with status
  /// `cancelled`) so its history is kept; `.select().single()` surfaces a
  /// silently-filtered update as an error.
  @override
  Future<void> cancelFrequentVisit(String visitId) => guardFailure(() async {
    await _client
        .from('visitors')
        .update({'status': 'cancelled'})
        .eq('id', visitId)
        .eq('visit_type', 'frequent')
        .inFilter('status', ['scheduled', 'active', 'inside'])
        .select()
        .single();
  });

  /// The visitor's most recent gate movement (check-in, and check-out if any),
  /// or null if they haven't come in yet.
  @override
  Future<AccessMovement?> fetchLastMovement(String visitId) =>
      guardFailure(() async {
        final rows = await _client
            .from('access_logs')
            .select('checked_in_at, checked_out_at')
            .eq('visitor_id', visitId)
            .not('checked_in_at', 'is', null)
            .order('checked_in_at', ascending: false)
            .limit(1);
        if (rows.isEmpty) return null;
        return AccessMovement.fromMap(rows.first);
      });
}
