enum IncidentPriority { low, medium, high, urgent }

enum IncidentStatus { newIncident, inProgress, resolved, closed, cancelled }

IncidentPriority priorityFromString(String value) {
  return IncidentPriority.values.firstWhere(
    (p) => p.name == value,
    orElse: () => IncidentPriority.medium,
  );
}

IncidentStatus statusFromString(String value) {
  switch (value) {
    case 'new':
      return IncidentStatus.newIncident;
    case 'in_progress':
      return IncidentStatus.inProgress;
    case 'resolved':
      return IncidentStatus.resolved;
    case 'closed':
      return IncidentStatus.closed;
    case 'cancelled':
      return IncidentStatus.cancelled;
    default:
      return IncidentStatus.newIncident;
  }
}

class Incident {
  const Incident({
    required this.id,
    required this.title,
    this.description,
    this.incidentTypeId,
    this.incidentTypeName,
    this.location,
    required this.priority,
    required this.status,
    required this.createdAt,
    this.reportedBy,
  });

  final String id;
  final String title;
  final String? description;
  final String? incidentTypeId;
  final String? incidentTypeName;
  final String? location;
  final IncidentPriority priority;
  final IncidentStatus status;
  final DateTime createdAt;
  final String? reportedBy;

  /// The reporter can still change or cancel the report while nobody has
  /// started working on it.
  bool get isEditable => status == IncidentStatus.newIncident;

  factory Incident.fromMap(Map<String, dynamic> map) {
    final incidentType = map['incident_types'] as Map<String, dynamic>?;
    return Incident(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      incidentTypeId: map['incident_type_id'] as String?,
      incidentTypeName: incidentType?['name'] as String?,
      location: map['location'] as String?,
      priority: priorityFromString(map['priority'] as String),
      status: statusFromString(map['status'] as String),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      reportedBy: map['reported_by'] as String?,
    );
  }
}

class IncidentType {
  const IncidentType({required this.id, required this.name});

  final String id;
  final String name;

  factory IncidentType.fromMap(Map<String, dynamic> map) {
    return IncidentType(id: map['id'] as String, name: map['name'] as String);
  }
}

class IncidentAttachment {
  const IncidentAttachment({
    required this.id,
    required this.storagePath,
    required this.url,
  });

  final String id;
  final String storagePath;

  /// Short-lived signed URL (the bucket is private).
  final String url;
}
