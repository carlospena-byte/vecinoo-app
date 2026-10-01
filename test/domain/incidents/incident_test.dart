import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';
import 'package:gates_app/features/incidents/presentation/incident_edit_args.dart';
import 'package:gates_app/features/incidents/presentation/incident_labels.dart';
import 'package:gates_app/l10n/app_localizations_es.dart';

Map<String, dynamic> _map({
  String status = 'new',
  String priority = 'high',
  Map<String, dynamic>? extra,
}) => {
  'id': 'i1',
  'title': 'Fuga',
  'status': status,
  'priority': priority,
  'created_at': '2026-03-01T10:00:00Z',
  ...?extra,
};

void main() {
  group('statusFromString', () {
    test('maps every backend value', () {
      expect(statusFromString('new'), IncidentStatus.newIncident);
      expect(statusFromString('in_progress'), IncidentStatus.inProgress);
      expect(statusFromString('resolved'), IncidentStatus.resolved);
      expect(statusFromString('closed'), IncidentStatus.closed);
      expect(statusFromString('cancelled'), IncidentStatus.cancelled);
    });

    test('unknown values fall back to new', () {
      expect(statusFromString('weird'), IncidentStatus.newIncident);
      expect(statusFromString(''), IncidentStatus.newIncident);
    });
  });

  group('priorityFromString', () {
    test('maps names and falls back to medium', () {
      expect(priorityFromString('low'), IncidentPriority.low);
      expect(priorityFromString('high'), IncidentPriority.high);
      expect(priorityFromString('urgent'), IncidentPriority.urgent);
      expect(priorityFromString('nope'), IncidentPriority.medium);
    });
  });

  group('Incident.fromMap', () {
    test('parses all fields including the embedded type', () {
      final i = Incident.fromMap(
        _map(
          status: 'in_progress',
          extra: {
            'description': '<p>x</p>',
            'incident_type_id': 't1',
            'incident_types': {'name': 'Plomería'},
            'location': 'Lobby',
            'reported_by': 'u1',
          },
        ),
      );
      expect(i.id, 'i1');
      expect(i.title, 'Fuga');
      expect(i.description, '<p>x</p>');
      expect(i.incidentTypeId, 't1');
      expect(i.incidentTypeName, 'Plomería');
      expect(i.location, 'Lobby');
      expect(i.priority, IncidentPriority.high);
      expect(i.status, IncidentStatus.inProgress);
      expect(i.reportedBy, 'u1');
      expect(i.createdAt.toUtc(), DateTime.utc(2026, 3, 1, 10));
      expect(i.createdAt.isUtc, isFalse);
    });

    test('optional fields may be absent or null', () {
      final i = Incident.fromMap(_map(extra: {'incident_types': null}));
      expect(i.description, isNull);
      expect(i.incidentTypeId, isNull);
      expect(i.incidentTypeName, isNull);
      expect(i.location, isNull);
      expect(i.reportedBy, isNull);
    });

    test('missing required fields throw', () {
      expect(() => Incident.fromMap({'id': 'x'}), throwsA(isA<TypeError>()));
      expect(
        () => Incident.fromMap(_map(extra: {'created_at': 'garbage'})),
        throwsFormatException,
      );
    });

    test('only new incidents are editable', () {
      for (final s in IncidentStatus.values) {
        final raw = switch (s) {
          IncidentStatus.newIncident => 'new',
          IncidentStatus.inProgress => 'in_progress',
          _ => s.name,
        };
        expect(
          Incident.fromMap(_map(status: raw)).isEditable,
          s == IncidentStatus.newIncident,
        );
      }
    });
  });

  test('IncidentType.fromMap', () {
    final t = IncidentType.fromMap({'id': 't', 'name': 'Ruido'});
    expect(t.id, 't');
    expect(t.name, 'Ruido');
  });

  test('IncidentAttachment and edit args keep their data', () {
    const a = IncidentAttachment(id: 'a', storagePath: 'p/a.jpg', url: 'u');
    final i = Incident.fromMap(_map());
    final args = IncidentEditArgs(incident: i, attachments: const [a]);
    expect(args.incident, same(i));
    expect(args.attachments.single.storagePath, 'p/a.jpg');
    expect(args.attachments.single.url, 'u');
  });

  test('labels cover every status and priority', () {
    final l10n = AppLocalizationsEs();
    final statuses = {
      for (final s in IncidentStatus.values) incidentStatusLabel(l10n, s),
    };
    final priorities = {
      for (final p in IncidentPriority.values) incidentPriorityLabel(l10n, p),
    };
    expect(statuses, hasLength(IncidentStatus.values.length));
    expect(priorities, hasLength(IncidentPriority.values.length));
    expect(
      incidentStatusLabel(l10n, IncidentStatus.cancelled),
      l10n.incidentsStatusCancelled,
    );
    expect(
      incidentPriorityLabel(l10n, IncidentPriority.urgent),
      l10n.incidentsPriorityUrgent,
    );
  });
}
