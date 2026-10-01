import '../domain/incident.dart';

/// Arguments for `/incidents/:id/edit`.
class IncidentEditArgs {
  const IncidentEditArgs({required this.incident, required this.attachments});

  final Incident incident;
  final List<IncidentAttachment> attachments;
}
