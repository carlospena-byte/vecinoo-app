enum VisitType { frequent, delivery, fastlane }

enum VisitStatus { pendingRegistration, scheduled, active, inside, completed, cancelled, rejected }

enum VisitorRole { familiar, entrenador, empleado, proveedor, visitante, invitado }

enum ProviderKind { proveedor, delivery, paqueteria }

enum Recurrence { monFri, monSat, daily, custom }

enum ScheduleType { allDay, custom }

VisitType visitTypeFromString(String value) {
  return VisitType.values.firstWhere((t) => t.name == value, orElse: () => VisitType.frequent);
}

VisitStatus visitStatusFromString(String value) {
  switch (value) {
    case 'pending_registration':
      return VisitStatus.pendingRegistration;
    case 'scheduled':
      return VisitStatus.scheduled;
    case 'active':
      return VisitStatus.active;
    case 'inside':
      return VisitStatus.inside;
    case 'completed':
      return VisitStatus.completed;
    case 'cancelled':
      return VisitStatus.cancelled;
    case 'rejected':
      return VisitStatus.rejected;
    default:
      return VisitStatus.scheduled;
  }
}

String visitStatusLabel(VisitStatus status) {
  switch (status) {
    case VisitStatus.pendingRegistration:
      return 'Pendiente de registro';
    case VisitStatus.scheduled:
      return 'Programada';
    case VisitStatus.active:
      return 'Activa';
    case VisitStatus.inside:
      return 'Dentro';
    case VisitStatus.completed:
      return 'Completada';
    case VisitStatus.cancelled:
      return 'Cancelada';
    case VisitStatus.rejected:
      return 'Rechazada';
  }
}

String visitTypeLabel(VisitType type) {
  switch (type) {
    case VisitType.frequent:
      return 'Frecuente';
    case VisitType.delivery:
      return 'Delivery/Proveedor';
    case VisitType.fastlane:
      return 'FastLane';
  }
}

String visitorRoleLabel(VisitorRole role) {
  switch (role) {
    case VisitorRole.familiar:
      return 'Familiar';
    case VisitorRole.entrenador:
      return 'Entrenador';
    case VisitorRole.empleado:
      return 'Empleado';
    case VisitorRole.proveedor:
      return 'Proveedor';
    case VisitorRole.visitante:
      return 'Visitante';
    case VisitorRole.invitado:
      return 'Invitado';
  }
}

String providerKindLabel(ProviderKind kind) {
  switch (kind) {
    case ProviderKind.proveedor:
      return 'Proveedor';
    case ProviderKind.delivery:
      return 'Delivery';
    case ProviderKind.paqueteria:
      return 'Paquetería';
  }
}

String recurrenceLabel(Recurrence recurrence) {
  switch (recurrence) {
    case Recurrence.monFri:
      return 'Lunes a viernes';
    case Recurrence.monSat:
      return 'Lunes a sábado';
    case Recurrence.daily:
      return 'Todos los días';
    case Recurrence.custom:
      return 'Personalizado';
  }
}

/// db value <-> enum name mismatches (snake_case column values vs Dart enum
/// identifiers) are handled by these explicit maps rather than string munging.
const _recurrenceDbValues = {
  Recurrence.monFri: 'mon_fri',
  Recurrence.monSat: 'mon_sat',
  Recurrence.daily: 'daily',
  Recurrence.custom: 'custom',
};

String recurrenceToDb(Recurrence recurrence) => _recurrenceDbValues[recurrence]!;

Recurrence recurrenceFromString(String value) {
  return _recurrenceDbValues.entries.firstWhere((e) => e.value == value, orElse: () => const MapEntry(Recurrence.daily, 'daily')).key;
}

class Visit {
  const Visit({
    required this.id,
    required this.unitId,
    this.name,
    this.phone,
    this.plate,
    required this.status,
    required this.visitType,
    this.visitorRole,
    this.providerKind,
    this.recurrence,
    this.scheduleType,
    this.notes,
    this.accessCode,
    required this.validFrom,
    required this.validUntil,
    required this.createdAt,
  });

  final String id;
  final String unitId;
  final String? name;
  final String? phone;
  final String? plate;
  final VisitStatus status;
  final VisitType visitType;
  final VisitorRole? visitorRole;
  final ProviderKind? providerKind;
  final Recurrence? recurrence;
  final ScheduleType? scheduleType;
  final String? notes;
  final String? accessCode;
  final DateTime validFrom;
  final DateTime validUntil;
  final DateTime createdAt;

  factory Visit.fromMap(Map<String, dynamic> map) {
    return Visit(
      id: map['id'] as String,
      unitId: map['unit_id'] as String,
      name: map['name'] as String?,
      phone: map['phone'] as String?,
      plate: map['plate'] as String?,
      status: visitStatusFromString(map['status'] as String),
      visitType: visitTypeFromString(map['visit_type'] as String),
      visitorRole: (map['visitor_role'] as String?) == null
          ? null
          : VisitorRole.values.firstWhere((r) => r.name == map['visitor_role'], orElse: () => VisitorRole.visitante),
      providerKind: (map['provider_kind'] as String?) == null
          ? null
          : ProviderKind.values.firstWhere((k) => k.name == map['provider_kind'], orElse: () => ProviderKind.delivery),
      recurrence: (map['recurrence'] as String?) == null ? null : recurrenceFromString(map['recurrence'] as String),
      scheduleType: (map['schedule_type'] as String?) == 'custom' ? ScheduleType.custom : ScheduleType.allDay,
      notes: map['notes'] as String?,
      accessCode: map['access_code'] as String?,
      validFrom: DateTime.parse(map['valid_from'] as String).toLocal(),
      validUntil: DateTime.parse(map['valid_until'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
