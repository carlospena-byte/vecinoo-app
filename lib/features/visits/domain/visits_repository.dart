import 'dart:typed_data';

import 'package:flutter/material.dart' show TimeOfDay;

import 'access_movement.dart';
import 'visit.dart';

/// What the visits feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class VisitsRepository {
  /// Only this unit's visits — the resident's own, per the "members manage
  /// own unit" RLS policy (they could also see every visitor in the
  /// residential via "members view", but that's not what this screen shows).
  Future<List<Visit>> fetchVisits(String unitId);

  /// Same rows as [fetchVisits], but live: Supabase Realtime pushes any
  /// insert/update/delete on this unit's visitors (e.g. a guard's check-in
  /// flipping status to "inside") straight into this stream, so the list
  /// updates without a manual pull-to-refresh.
  Stream<List<Visit>> watchVisits(String unitId);

  /// Uploads the visitor's ID photo to the private `visitor-id-photos` bucket
  /// (folder = residential id, which the member-insert policy checks) and
  /// returns its storage path.
  Future<String> uploadVisitorDocument({
    required String residentialId,
    required Uint8List bytes,
    required String extension,
  });

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
  });

  /// Edits a still-active frequent visit. [idPhotoPath] is only sent when the
  /// resident replaced the document. `.select().single()` makes a
  /// silently-filtered (0 rows) update surface as an error.
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
  });

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
  });

  /// Creates the FastLane row via the create_fastlane_visit RPC (so
  /// access_code is always server-generated) and returns the shareable
  /// self-registration link. The resident shares it themselves through the
  /// device's native share sheet — this no longer triggers a backend
  /// SMS/WhatsApp send, so there's no phone number to collect.
  Future<Visit> createFastlaneVisit({
    required String residentialId,
    required String unitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  });

  /// Edits a still-pending FastLane invitation. Mirrors what
  /// create_fastlane_visit computes server-side: valid_from is the chosen
  /// day at the arrival time, valid_until is the end of that day, both in the
  /// resident's own timezone (sent as UTC instants). The "members update own
  /// unit" RLS policy allows this direct update; `.select().single()` makes a
  /// silently-filtered (0 rows) update surface as an error instead.
  Future<void> updateFastlaneVisit({
    required String visitId,
    required String name,
    required DateTime visitDate,
    required TimeOfDay arrivalTime,
    String? notes,
  });

  /// Cancels a visit that hasn't happened yet: a FastLane invitation still
  /// waiting for its data (its link stops working because fastlane-submit only
  /// accepts `pending_registration` rows) or a scheduled/active delivery.
  /// `.select().single()` surfaces a silently-filtered update as an error.
  Future<void> cancelVisit(String visitId);

  /// Ends a frequent visit's standing access. The row stays (with status
  /// `cancelled`) so its history is kept; `.select().single()` surfaces a
  /// silently-filtered update as an error.
  Future<void> cancelFrequentVisit(String visitId);

  /// The visitor's most recent gate movement (check-in, and check-out if any),
  /// or null if they haven't come in yet.
  Future<AccessMovement?> fetchLastMovement(String visitId);
}
