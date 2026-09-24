import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import 'incidents_controller.dart';

class IncidentsListScreen extends ConsumerWidget {
  const IncidentsListScreen({super.key});

  static final _dateFormat = DateFormat('d MMM, h:mm a', 'es');

  Color _priorityColor(BuildContext context, IncidentPriority priority) {
    final scheme = Theme.of(context).colorScheme;
    switch (priority) {
      case IncidentPriority.urgent:
      case IncidentPriority.high:
        return scheme.error;
      case IncidentPriority.medium:
        return scheme.tertiary;
      case IncidentPriority.low:
        return scheme.outline;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final incidentsAsync = ref.watch(incidentsListProvider(membership.residentialId));

    return Scaffold(
      appBar: AppBar(title: const Text('Incidencias')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/incidents/report'),
        icon: const Icon(Icons.add),
        label: const Text('Reportar'),
      ),
      body: incidentsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar las incidencias.',
          onRetry: () => ref.invalidate(incidentsListProvider(membership.residentialId)),
        ),
        data: (incidents) {
          if (incidents.isEmpty) {
            return const EmptyView(
              message: 'No hay incidencias reportadas.',
              icon: Icons.report_gmailerrorred_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(incidentsListProvider(membership.residentialId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: incidents.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final incident = incidents[index];
                return Card(
                  child: ListTile(
                    leading: Icon(Icons.circle, size: 12, color: _priorityColor(context, incident.priority)),
                    title: Text(incident.title),
                    subtitle: Text(
                      [
                        if (incident.incidentTypeName != null) incident.incidentTypeName!,
                        _dateFormat.format(incident.createdAt),
                      ].join(' · '),
                    ),
                    trailing: Chip(label: Text(statusLabel(incident.status))),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
