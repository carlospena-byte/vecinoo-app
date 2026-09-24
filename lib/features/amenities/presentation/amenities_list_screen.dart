import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import 'amenities_controller.dart';

class AmenitiesListScreen extends ConsumerWidget {
  const AmenitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final amenitiesAsync = ref.watch(amenitiesListProvider(membership.residentialId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(
            tooltip: 'Mis reservas',
            icon: const Icon(Icons.event_note_outlined),
            onPressed: () => context.push('/amenities/my-bookings'),
          ),
        ],
      ),
      body: amenitiesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar las amenidades.',
          onRetry: () => ref.invalidate(amenitiesListProvider(membership.residentialId)),
        ),
        data: (amenities) {
          if (amenities.isEmpty) {
            return const EmptyView(
              message: 'Tu residencial aún no tiene amenidades configuradas.',
              icon: Icons.pool_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(amenitiesListProvider(membership.residentialId)),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: amenities.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final amenity = amenities[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.deck_outlined),
                    title: Text(amenity.name),
                    subtitle: Text(
                      [
                        if (amenity.location != null) amenity.location!,
                        if (amenity.capacity != null) 'Capacidad: ${amenity.capacity}',
                      ].join(' · '),
                    ),
                    trailing: amenity.requiresBooking ? const Icon(Icons.chevron_right) : null,
                    onTap: amenity.requiresBooking
                        ? () => context.push('/amenities/${amenity.id}', extra: amenity)
                        : null,
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
