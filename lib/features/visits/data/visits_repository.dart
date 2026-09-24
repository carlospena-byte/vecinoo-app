import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/visit.dart';

class VisitsRepository {
  VisitsRepository(this._client);

  final SupabaseClient _client;

  /// Only this unit's visits — the resident's own, per the "members manage
  /// own unit" RLS policy (they could also see every visitor in the
  /// residential via "members view", but that's not what this screen shows).
  Future<List<Visit>> fetchVisits(String unitId) async {
    final rows = await _client
        .from('visitors')
        .select()
        .eq('unit_id', unitId)
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Visit.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<void> createFrequentVisit({
    required String residentialId,
    required String unitId,
    required String name,
    String? phone,
    String? plate,
    required VisitorRole visitorRole,
    required Recurrence recurrence,
    List<String>? recurrenceDays,
    required ScheduleType scheduleType,
    String? scheduleStart,
    String? scheduleEnd,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    await _client.from('visitors').insert({
      'residential_id': residentialId,
      'unit_id': unitId,
      'invited_by': userId,
      'name': name,
      'phone': phone,
      'plate': plate,
      'visit_type': 'frequent',
      'visitor_role': visitorRole.name,
      'recurrence': recurrenceToDb(recurrence),
      'recurrence_days': recurrence == Recurrence.custom ? recurrenceDays : null,
      'schedule_type': scheduleType == ScheduleType.custom ? 'custom' : 'all_day',
      'schedule_start': scheduleType == ScheduleType.custom ? scheduleStart : null,
      'schedule_end': scheduleType == ScheduleType.custom ? scheduleEnd : null,
      'notes': notes,
      // Open-ended: active until an admin cancels it, not tied to one date.
      'valid_from': DateTime.now().toIso8601String(),
      'valid_until': DateTime(2099, 12, 31).toIso8601String(),
    });
  }

  Future<void> createDeliveryVisit({
    required String residentialId,
    required String unitId,
    required String name,
    String? phone,
    String? plate,
    required ProviderKind providerKind,
    required DateTime visitDate,
    String? notes,
  }) async {
    final userId = _client.auth.currentUser?.id;
    final dayStart = DateTime(visitDate.year, visitDate.month, visitDate.day);
    final dayEnd = dayStart.add(const Duration(hours: 23, minutes: 59, seconds: 59));
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
  }

  /// Creates the FastLane row via the create_fastlane_visit RPC (so
  /// access_code is always server-generated) then immediately triggers the
  /// SMS/WhatsApp send. Returns whether the notification actually went out —
  /// Twilio being unconfigured is a normal, surfaced outcome, not an error.
  Future<({String visitId, String accessCode, bool notificationSent, String? notificationError})> createFastlaneVisit({
    required String residentialId,
    required String unitId,
    required String phone,
    required DateTime visitDate,
    String? notes,
    required String channel,
  }) async {
    final created = await _client
        .rpc('create_fastlane_visit', params: {
          '_residential_id': residentialId,
          '_unit_id': unitId,
          '_phone': phone,
          '_visit_date':
              '${visitDate.year.toString().padLeft(4, '0')}-${visitDate.month.toString().padLeft(2, '0')}-${visitDate.day.toString().padLeft(2, '0')}',
          '_notes': notes,
        })
        .single();

    final visitId = created['id'] as String;
    final accessCode = created['access_code'] as String;

    final response = await _client.functions.invoke(
      'send-visit-notification',
      body: {'visitId': visitId, 'channel': channel},
    );
    final data = response.data as Map<String, dynamic>? ?? const {};

    return (
      visitId: visitId,
      accessCode: accessCode,
      notificationSent: data['notificationSent'] as bool? ?? false,
      notificationError: data['error'] as String?,
    );
  }
}
