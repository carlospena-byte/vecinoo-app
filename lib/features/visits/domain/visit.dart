import 'package:flutter/material.dart' show TimeOfDay;

import '../../../l10n/l10n.dart';

enum VisitType { frequent, delivery, fastlane }

enum VisitStatus {
  pendingRegistration,
  scheduled,
  active,
  inside,
  completed,
  cancelled,
  rejected,
  expired,
}

enum VisitorRole {
  familiar,
  entrenador,
  empleado,
  proveedor,
  visitante,
  invitado,
}

enum ProviderKind { proveedor, delivery, paqueteria }

enum Recurrence { monFri, monSat, daily, custom }

enum ScheduleType { allDay, custom }

VisitType visitTypeFromString(String value) {
  return VisitType.values.firstWhere(
    (t) => t.name == value,
    orElse: () => VisitType.frequent,
  );
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
    case 'expired':
      return VisitStatus.expired;
    default:
      return VisitStatus.scheduled;
  }
}

String visitStatusLabel(AppLocalizations l10n, VisitStatus status) {
  switch (status) {
    case VisitStatus.pendingRegistration:
      return l10n.visitsStatusPendingRegistration;
    case VisitStatus.scheduled:
      return l10n.visitsStatusScheduled;
    case VisitStatus.active:
      return l10n.visitsStatusActive;
    case VisitStatus.inside:
      return l10n.visitsStatusInside;
    case VisitStatus.completed:
      return l10n.visitsStatusCompleted;
    case VisitStatus.cancelled:
      return l10n.visitsStatusCancelled;
    case VisitStatus.rejected:
      return l10n.visitsStatusRejected;
    case VisitStatus.expired:
      return l10n.visitsStatusExpired;
  }
}

String visitTypeLabel(AppLocalizations l10n, VisitType type) {
  switch (type) {
    case VisitType.frequent:
      return l10n.visitsTypeFrequent;
    case VisitType.delivery:
      return l10n.visitsTypeDelivery;
    case VisitType.fastlane:
      return l10n.visitsTypeFastlane;
  }
}

String visitorRoleLabel(AppLocalizations l10n, VisitorRole role) {
  switch (role) {
    case VisitorRole.familiar:
      return l10n.visitsRoleFamiliar;
    case VisitorRole.entrenador:
      return l10n.visitsRoleEntrenador;
    case VisitorRole.empleado:
      return l10n.visitsRoleEmpleado;
    case VisitorRole.proveedor:
      return l10n.visitsRoleProveedor;
    case VisitorRole.visitante:
      return l10n.visitsRoleVisitante;
    case VisitorRole.invitado:
      return l10n.visitsRoleInvitado;
  }
}

String providerKindLabel(AppLocalizations l10n, ProviderKind kind) {
  switch (kind) {
    case ProviderKind.proveedor:
      return l10n.visitsProviderKindProveedor;
    case ProviderKind.delivery:
      return l10n.visitsProviderKindDelivery;
    case ProviderKind.paqueteria:
      return l10n.visitsProviderKindPaqueteria;
  }
}

String recurrenceLabel(AppLocalizations l10n, Recurrence recurrence) {
  switch (recurrence) {
    case Recurrence.monFri:
      return l10n.visitsRecurrenceMonFri;
    case Recurrence.monSat:
      return l10n.visitsRecurrenceMonSat;
    case Recurrence.daily:
      return l10n.visitsRecurrenceDaily;
    case Recurrence.custom:
      return l10n.visitsRecurrenceCustom;
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

String recurrenceToDb(Recurrence recurrence) =>
    _recurrenceDbValues[recurrence]!;

Recurrence recurrenceFromString(String value) {
  return _recurrenceDbValues.entries
      .firstWhere(
        (e) => e.value == value,
        orElse: () => const MapEntry(Recurrence.daily, 'daily'),
      )
      .key;
}

/// Day keys as stored in `recurrence_days` / `schedule_blocks`, Monday first.
const weekdayKeys = ['mon', 'tue', 'wed', 'thu', 'fri', 'sat', 'sun'];

String weekdayShortLabel(AppLocalizations l10n, String day) => switch (day) {
  'mon' => l10n.visitsWeekdayMon,
  'tue' => l10n.visitsWeekdayTue,
  'wed' => l10n.visitsWeekdayWed,
  'thu' => l10n.visitsWeekdayThu,
  'fri' => l10n.visitsWeekdayFri,
  'sat' => l10n.visitsWeekdaySat,
  _ => l10n.visitsWeekdaySun,
};

/// One "Bloque de horario": a group of weekdays sharing the same access window.
class ScheduleBlock {
  const ScheduleBlock({
    required this.days,
    required this.start,
    required this.end,
  });

  final Set<String> days;
  final TimeOfDay start;
  final TimeOfDay end;

  Map<String, dynamic> toMap() => {
    'days': [
      for (final day in weekdayKeys)
        if (days.contains(day)) day,
    ],
    'start': timeToDb(start),
    'end': timeToDb(end),
  };

  factory ScheduleBlock.fromMap(Map<String, dynamic> map) => ScheduleBlock(
    days: {for (final day in (map['days'] as List)) day as String},
    start: timeFromDb(map['start'] as String),
    end: timeFromDb(map['end'] as String),
  );
}

/// `TimeOfDay` <-> Postgres `time` ("08:00:00").
String timeToDb(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';

TimeOfDay timeFromDb(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
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
    this.recurrenceDays,
    this.scheduleType,
    this.scheduleStart,
    this.scheduleEnd,
    this.scheduleBlocks,
    this.hasVehicle = false,
    this.notifyOnArrival = false,
    this.idPhotoPath,
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
  final List<String>? recurrenceDays;
  final ScheduleType? scheduleType;
  final TimeOfDay? scheduleStart;
  final TimeOfDay? scheduleEnd;
  final List<ScheduleBlock>? scheduleBlocks;
  final bool hasVehicle;
  final bool notifyOnArrival;
  final String? idPhotoPath;
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
          : VisitorRole.values.firstWhere(
              (r) => r.name == map['visitor_role'],
              orElse: () => VisitorRole.visitante,
            ),
      providerKind: (map['provider_kind'] as String?) == null
          ? null
          : ProviderKind.values.firstWhere(
              (k) => k.name == map['provider_kind'],
              orElse: () => ProviderKind.delivery,
            ),
      recurrence: (map['recurrence'] as String?) == null
          ? null
          : recurrenceFromString(map['recurrence'] as String),
      recurrenceDays: (map['recurrence_days'] as List?)?.cast<String>(),
      scheduleType: (map['schedule_type'] as String?) == 'custom'
          ? ScheduleType.custom
          : ScheduleType.allDay,
      scheduleStart: (map['schedule_start'] as String?) == null
          ? null
          : timeFromDb(map['schedule_start'] as String),
      scheduleEnd: (map['schedule_end'] as String?) == null
          ? null
          : timeFromDb(map['schedule_end'] as String),
      scheduleBlocks: (map['schedule_blocks'] as List?)
          ?.map((b) => ScheduleBlock.fromMap(b as Map<String, dynamic>))
          .toList(),
      hasVehicle: (map['has_vehicle'] as bool?) ?? false,
      notifyOnArrival: (map['notify_on_arrival'] as bool?) ?? false,
      idPhotoPath: map['id_photo_path'] as String?,
      notes: map['notes'] as String?,
      accessCode: map['access_code'] as String?,
      validFrom: DateTime.parse(map['valid_from'] as String).toLocal(),
      validUntil: DateTime.parse(map['valid_until'] as String).toLocal(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
    );
  }
}
