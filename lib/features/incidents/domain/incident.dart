enum IncidentPriority { low, medium, high, urgent }

enum IncidentStatus { newIncident, inProgress, resolved, closed }

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
    default:
      return IncidentStatus.newIncident;
  }
}

String statusLabel(IncidentStatus status) {
  switch (status) {
    case IncidentStatus.newIncident:
      return 'Nueva';
    case IncidentStatus.inProgress:
      return 'En progreso';
    case IncidentStatus.resolved:
      return 'Resuelta';
    case IncidentStatus.closed:
      return 'Cerrada';
  }
}

String priorityLabel(IncidentPriority priority) {
  switch (priority) {
    case IncidentPriority.low:
      return 'Baja';
    case IncidentPriority.medium:
      return 'Media';
    case IncidentPriority.high:
      return 'Alta';
    case IncidentPriority.urgent:
      return 'Urgente';
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
