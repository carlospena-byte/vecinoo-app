import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/paging/paged_notifier.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../data/supabase_incidents_repository.dart';
import '../domain/incident.dart';
import '../domain/incidents_repository.dart';

final incidentsRepositoryProvider = Provider<IncidentsRepository>((ref) {
  return SupabaseIncidentsRepository(ref.watch(supabaseClientProvider));
});

/// Key of one paged tab: a residential and the group shown.
typedef IncidentsPageKey = (String residentialId, IncidentGroup group);

/// Pages through one tab of the incidents list, 10 at a time.
class IncidentsPagingController extends PagedNotifier<Incident> {
  IncidentsPagingController(this.key);

  final IncidentsPageKey key;

  @override
  Future<List<Incident>> fetchPage({required int offset, required int limit}) =>
      ref
          .read(incidentsRepositoryProvider)
          .fetchIncidentsPage(
            key.$1,
            group: key.$2,
            limit: limit,
            offset: offset,
          );
}

final incidentsPagingProvider = NotifierProvider.autoDispose
    .family<IncidentsPagingController, PagedState<Incident>, IncidentsPageKey>(
      IncidentsPagingController.new,
    );

/// Every incident, for the Home summary card.
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
