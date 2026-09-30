import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/amenity_thumbnail.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/amenity_card.dart';
import 'amenities_controller.dart';

class AmenitiesListScreen extends ConsumerWidget {
  const AmenitiesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final amenitiesAsync = ref.watch(
      amenitiesListProvider(membership.residentialId),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('Nueva reserva'),
      ),
      body: amenitiesAsync.when(
        loading: () => const LoadingView(),
        error: (e, _) => ErrorView(
          message: 'No se pudieron cargar las amenidades.',
          onRetry: () =>
              ref.invalidate(amenitiesListProvider(membership.residentialId)),
        ),
        data: (amenities) {
          if (amenities.isEmpty) {
            return const EmptyView(
              message: 'Tu residencial aún no tiene amenidades configuradas.',
              icon: Icons.pool_outlined,
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(amenitiesListProvider(membership.residentialId)),
            child: ListView(
              padding: const EdgeInsets.all(GatesSpacing.space16),
              children: [
                Text('Amenidades', style: GatesTypography.headingSmall),
                const SizedBox(height: GatesSpacing.space12),
                for (final card in amenities) ...[
                  _AmenityCardTile(card: card),
                  const SizedBox(height: GatesSpacing.space12),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AmenityCardTile extends StatelessWidget {
  const _AmenityCardTile({required this.card});

  final AmenityCard card;

  @override
  Widget build(BuildContext context) {
    final amenity = card.amenity;
    final content = Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(GatesSpacing.space16),
      decoration: BoxDecoration(
        color: GatesColors.bgSurface,
        border: Border.all(color: GatesColors.borderDefault),
        borderRadius: BorderRadius.circular(GatesRadius.radius16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  amenity.name,
                  style: GatesTypography.body.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (amenity.capacity != null) ...[
                  const SizedBox(height: GatesSpacing.space4),
                  Text(
                    '${amenity.capacity} personas',
                    style: GatesTypography.labelSecondary,
                  ),
                ],
                const SizedBox(height: GatesSpacing.space4),
                _BookingStatusBadge(requiresBooking: amenity.requiresBooking),
              ],
            ),
          ),
          const SizedBox(width: GatesSpacing.space16),
          AmenityThumbnail(imageUrl: card.imageUrl),
        ],
      ),
    );

    return InkWell(
      borderRadius: BorderRadius.circular(GatesRadius.radius16),
      onTap: () => context.push('/amenities/${amenity.id}'),
      child: content,
    );
  }
}

class _BookingStatusBadge extends StatelessWidget {
  const _BookingStatusBadge({required this.requiresBooking});

  final bool requiresBooking;

  @override
  Widget build(BuildContext context) {
    final background = requiresBooking
        ? GatesColors.bgBrand
        : GatesColors.bgAccent;
    final foreground = requiresBooking
        ? GatesColors.textInverse
        : GatesColors.textBrand;
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            requiresBooking ? Icons.calendar_today_outlined : Icons.check,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: GatesSpacing.space8),
          Text(
            requiresBooking ? 'Reserva obligatoria' : 'Sin reserva',
            style: GatesTypography.caption.copyWith(
              color: foreground,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
