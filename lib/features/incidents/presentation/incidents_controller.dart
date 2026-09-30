import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/incidents_repository.dart';
import '../domain/incident.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return IncidentsRepository(ref.watch(supabaseClientProvider));
});

final incidentsListProvider = FutureProvider.family<List<Incident>, String>(
  (ref, residentialId) =>
      ref.watch(incidentsRepositoryProvider).fetchIncidents(residentialId),
);

final incidentTypesProvider = FutureProvider.family<List<IncidentType>, String>(
  (ref, residentialId) =>
      ref.watch(incidentsRepositoryProvider).fetchIncidentTypes(residentialId),
);

final incidentDetailProvider = FutureProvider.family<Incident, String>(
  (ref, incidentId) =>
      ref.watch(incidentsRepositoryProvider).fetchIncident(incidentId),
);

final incidentAttachmentsProvider =
    FutureProvider.family<List<IncidentAttachment>, String>(
      (ref, incidentId) =>
          ref.watch(incidentsRepositoryProvider).fetchAttachments(incidentId),
    );
