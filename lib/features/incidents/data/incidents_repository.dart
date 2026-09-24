import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/incident.dart';

class IncidentsRepository {
  IncidentsRepository(this._client);

  final SupabaseClient _client;

  /// Incidents visible to the current user in this residential: owner/admin
  /// see all of them; security/member only see the ones they reported
  /// themselves, plus any whose type has been granted to their role from
  /// Settings (see incident_type_roles RLS policies).
  Future<List<Incident>> fetchIncidents(String residentialId) async {
    final rows = await _client
        .from('incidents')
        .select('*, incident_types(name)')
        .eq('residential_id', residentialId)
        .order('created_at', ascending: false);
    return (rows as List).map((row) => Incident.fromMap(row as Map<String, dynamic>)).toList();
  }

  /// Active incident types configured for this residential (Ajustes >
  /// Tipos de incidencia), used to populate the report form's dropdown.
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId) async {
    final rows = await _client
        .from('incident_types')
        .select('id, name')
        .eq('residential_id', residentialId)
        .eq('is_active', true)
        .order('name');
    return (rows as List).map((row) => IncidentType.fromMap(row as Map<String, dynamic>)).toList();
  }

  Future<String> reportIncident({
    required String residentialId,
    required String unitId,
    required String title,
    String? description,
    String? incidentTypeId,
    String? location,
    required IncidentPriority priority,
    List<File> photos = const [],
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw StateError('reportIncident called with no signed-in user');
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
    final incidentId = inserted['id'] as String;

    for (final photo in photos) {
      final ext = photo.path.split('.').last;
      final storagePath =
          '$residentialId/$incidentId-${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('incident-attachments').upload(storagePath, photo);
      await _client.from('incident_attachments').insert({
        'incident_id': incidentId,
        'residential_id': residentialId,
        'storage_path': storagePath,
        'uploaded_by': userId,
      });
    }

    return incidentId;
  }
}
