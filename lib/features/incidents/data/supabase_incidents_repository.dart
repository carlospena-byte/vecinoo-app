import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';
import '../domain/incident.dart';
import '../domain/incidents_repository.dart';

/// Supabase-backed [IncidentsRepository]; every call surfaces errors as
/// `Failure`s.
class SupabaseIncidentsRepository implements IncidentsRepository {
  SupabaseIncidentsRepository(this._client);

  final SupabaseClient _client;

  /// Incidents visible to the current user in this residential: owner/admin
  /// see all of them; security/member only see the ones they reported
  /// themselves, plus any whose type has been granted to their role from
  /// Settings (see incident_type_roles RLS policies).
  @override
  Future<List<Incident>> fetchIncidents(String residentialId) =>
      guardFailure(() async {
        final rows = await _client
            .from('incidents')
            .select('*, incident_types(name)')
            .eq('residential_id', residentialId)
            .order('created_at', ascending: false);
        return (rows as List)
            .map((row) => Incident.fromMap(row as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Incident> fetchIncident(String incidentId) => guardFailure(() async {
    final row = await _client
        .from('incidents')
        .select('*, incident_types(name)')
        .eq('id', incidentId)
        .single();
    return Incident.fromMap(row);
  });

  @override
  Future<List<IncidentAttachment>> fetchAttachments(String incidentId) =>
      guardFailure(() async {
        final rows = await _client
            .from('incident_attachments')
            .select('id, storage_path')
            .eq('incident_id', incidentId)
            .order('created_at', ascending: true);
        final list = (rows as List).cast<Map<String, dynamic>>();
        if (list.isEmpty) return const [];
        final signed = await _client.storage
            .from('incident-attachments')
            .createSignedUrlsResult([
              for (final r in list) r['storage_path'] as String,
            ], 60 * 60);
        final urls = {
          for (final result in signed)
            if (result is SignedUrlSuccess) result.path: result.signedUrl,
        };
        return [
          for (final r in list)
            if (urls[r['storage_path']] != null)
              IncidentAttachment(
                id: r['id'] as String,
                storagePath: r['storage_path'] as String,
                url: urls[r['storage_path']]!,
              ),
        ];
      });

  @override
  Future<void> updateIncident({
    required String incidentId,
    required String title,
    String? description,
    String? incidentTypeId,
  }) async {
    await _client
        .from('incidents')
        .update({
          'title': title,
          'description': description,
          'incident_type_id': incidentTypeId,
        })
        .eq('id', incidentId);
  }

  @override
  Future<void> deleteAttachment(IncidentAttachment attachment) =>
      guardFailure(() async {
        await _client
            .from('incident_attachments')
            .delete()
            .eq('id', attachment.id);
        await _client.storage.from('incident-attachments').remove([
          attachment.storagePath,
        ]);
      });

  /// Keeps the row (and its history); only flips the status.
  @override
  Future<void> cancelIncident(String incidentId) => guardFailure(() async {
    await _client
        .from('incidents')
        .update({'status': 'cancelled'})
        .eq('id', incidentId);
  });

  /// Active incident types configured for this residential (Ajustes >
  /// Tipos de incidencia), used to populate the report form's dropdown.
  @override
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId) =>
      guardFailure(() async {
        final rows = await _client
            .from('incident_types')
            .select('id, name')
            .eq('residential_id', residentialId)
            .eq('is_active', true)
            .order('name', ascending: true);
        return (rows as List)
            .map((row) => IncidentType.fromMap(row as Map<String, dynamic>))
            .toList();
      });

  /// Inserts the incident row only; photos are uploaded one by one through
  /// [uploadPhoto] so the report screen can show per-photo progress and retry.
  @override
  Future<String> createIncident({
    required String residentialId,
    required String unitId,
    required String title,
    String? description,
    String? incidentTypeId,
    String? location,
    IncidentPriority priority = IncidentPriority.medium,
  }) => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final inserted = await _client
        .from('incidents')
        .insert({
          'residential_id': residentialId,
          'unit_id': unitId,
          'reported_by': userId,
          'title': title,
          'description': description,
          'incident_type_id': incidentTypeId,
          'location': location,
          'priority': priority.name,
        })
        .select('id')
        .single();
    return inserted['id'] as String;
  });

  @override
  Future<void> uploadPhoto({
    required String residentialId,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  }) => guardFailure(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw const AuthFailure();
    final storagePath =
        '$residentialId/$incidentId-${DateTime.now().microsecondsSinceEpoch}.$extension';
    await _client.storage
        .from('incident-attachments')
        .uploadBinary(storagePath, bytes);
    await _client.from('incident_attachments').insert({
      'incident_id': incidentId,
      'residential_id': residentialId,
      'storage_path': storagePath,
      'uploaded_by': userId,
    });
  });
}
