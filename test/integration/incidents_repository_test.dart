@Tags(['integration'])
library;

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gates_app/core/error/failure.dart';
import 'package:gates_app/features/incidents/data/supabase_incidents_repository.dart';
import 'package:gates_app/features/incidents/domain/incident.dart';

import 'support/local_supabase.dart';

void main() {
  late TestResident resident;
  late SupabaseIncidentsRepository repository;

  setUp(() async {
    resident = await TestResident.create();
    repository = SupabaseIncidentsRepository(resident.client);
  });

  tearDown(() => resident.dispose());

  test(
    'a resident can report, read, edit and cancel an incident',
    () async {
      final id = await repository.createIncident(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        title: 'Test: luz del pasillo',
        description: '<p>No enciende</p>',
      );
      resident.track('incidents', id);

      final fetched = await repository.fetchIncident(id);
      expect(fetched.title, 'Test: luz del pasillo');
      expect(fetched.status, IncidentStatus.newIncident);

      final list = await repository.fetchIncidents(resident.residentialId);
      expect(list.map((i) => i.id), contains(id));

      await repository.updateIncident(incidentId: id, title: 'Test: editada');
      expect((await repository.fetchIncident(id)).title, 'Test: editada');

      await repository.cancelIncident(id);
      expect(
        (await repository.fetchIncident(id)).status,
        IncidentStatus.cancelled,
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'photos upload and come back as signed attachments',
    () async {
      final id = await repository.createIncident(
        residentialId: resident.residentialId,
        unitId: resident.unitId,
        title: 'Test: con foto',
      );
      resident.track('incidents', id);

      await repository.uploadPhoto(
        residentialId: resident.residentialId,
        incidentId: id,
        bytes: Uint8List.fromList(List.filled(32, 7)),
        extension: 'png',
      );

      final attachments = await repository.fetchAttachments(id);
      expect(attachments, hasLength(1));
      expect(attachments.single.url, startsWith('http'));

      await repository.deleteAttachment(attachments.single);
      expect(await repository.fetchAttachments(id), isEmpty);
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'incident types are the active ones of the residential, by name',
    () async {
      final types = await repository.fetchIncidentTypes(resident.residentialId);

      expect(types, isNotEmpty);
      final names = types.map((t) => t.name).toList();
      expect(names, [...names]..sort());
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );

  test(
    'unknown incidents and an unsigned client surface typed failures',
    () async {
      await expectLater(
        repository.fetchIncident('00000000-0000-0000-0000-000000000000'),
        throwsA(isA<Failure>()),
      );

      final anon = SupabaseIncidentsRepository(newAnonClient());
      await expectLater(
        anon.createIncident(
          residentialId: resident.residentialId,
          unitId: resident.unitId,
          title: 'Test: sin sesión',
        ),
        throwsA(isA<AuthFailure>()),
      );
      await expectLater(
        anon.uploadPhoto(
          residentialId: resident.residentialId,
          incidentId: 'x',
          bytes: Uint8List(1),
          extension: 'png',
        ),
        throwsA(isA<AuthFailure>()),
      );
    },
    skip: localSupabaseSkipReason,
    tags: 'integration',
  );
}
