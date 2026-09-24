import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'visits_controller.dart';

class VisitsListScreen extends ConsumerWidget {
  const VisitsListScreen({super.key});

  static final _dateFormat = DateFormat('d MMM, h:mm a', 'es');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final visitsAsync = ref.watch(visitsListProvider(membership.unitId));

    return Scaffold(
      appBar: AppBar(title: const Text('Visitas')),
      floatingActionButton: PopupMenuButton<VisitType>(
        icon: const Icon(Icons.add),
        onSelected: (type) async {
          final route = switch (type) {
            VisitType.frequent => '/visits/new/frequent',
            VisitType.delivery => '/visits/new/delivery',
            VisitType.fastlane => '/visits/new/fastlane',
          };
          await context.push(route);
          ref.invalidate(visitsListProvider(membership.unitId));
        },
        itemBuilder: (context) => const [
          PopupMenuItem(value: VisitType.frequent, child: Text('Visita frecuente')),
          PopupMenuItem(value: VisitType.delivery, child: Text('Delivery o Proveedor')),
          PopupMenuItem(value: VisitType.fastlane, child: Text('FastLane')),
        ],
      ),
      body: visitsAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar tus visitas.',
          onRetry: () => ref.invalidate(visitsListProvider(membership.unitId)),
        ),
        data: (visits) {
          if (visits.isEmpty) {
            return const EmptyView(
              message: 'Aún no tienes visitas registradas.',
              icon: Icons.person_add_alt_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(visitsListProvider(membership.unitId)),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
              itemCount: visits.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final visit = visits[index];
                return Card(
                  child: ListTile(
                    title: Text(visit.name ?? 'Pendiente de registro'),
                    subtitle: Text(
                      [
                        visitTypeLabel(visit.visitType),
                        _dateFormat.format(visit.createdAt),
                      ].join(' · '),
                    ),
                    trailing: Chip(label: Text(visitStatusLabel(visit.status))),
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
