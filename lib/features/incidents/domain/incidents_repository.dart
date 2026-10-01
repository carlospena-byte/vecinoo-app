import 'dart:typed_data';

import 'incident.dart';

/// What the incidents feature needs from storage. Implementations throw
/// `Failure`s (see core/error/failure.dart), never raw backend exceptions.
abstract interface class IncidentsRepository {
  /// Incidents visible to the current user in this residential.
  Future<List<Incident>> fetchIncidents(String residentialId);

  Future<Incident> fetchIncident(String incidentId);

  Future<List<IncidentAttachment>> fetchAttachments(String incidentId);

  /// Active incident types configured for this residential.
  Future<List<IncidentType>> fetchIncidentTypes(String residentialId);

  /// Inserts the incident row only; photos go up one by one through
  /// [uploadPhoto] so the UI can show per-photo progress and retry.
  Future<String> createIncident({
    required String residentialId,
    required String unitId,
    required String title,
    String? description,
    String? incidentTypeId,
    String? location,
    IncidentPriority priority = IncidentPriority.medium,
  });

  Future<void> updateIncident({
    required String incidentId,
    required String title,
    String? description,
    String? incidentTypeId,
  });

  Future<void> uploadPhoto({
    required String residentialId,
    required String incidentId,
    required Uint8List bytes,
    required String extension,
  });

  Future<void> deleteAttachment(IncidentAttachment attachment);

  /// Keeps the row (and its history); only flips the status.
  Future<void> cancelIncident(String incidentId);
}
