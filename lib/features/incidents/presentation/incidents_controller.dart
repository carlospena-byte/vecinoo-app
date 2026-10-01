import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_incidents_repository.dart';
import '../domain/incident.dart';
import '../domain/incidents_repository.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return SupabaseIncidentsRepository(ref.watch(supabaseClientProvider));
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
