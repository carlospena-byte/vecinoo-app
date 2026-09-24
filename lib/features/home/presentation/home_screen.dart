import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_button.dart';
import '../../../core/widgets/state_views.dart';
import '../../amenities/domain/amenity_booking.dart';
import '../../amenities/presentation/amenities_controller.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/presentation/incidents_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../session/domain/membership.dart';
import '../../session/presentation/session_controller.dart';

/// "05 / Home" screen from Figma (file `Bla1GPfXA7JkuZcYpVi2DS`, node `13:14`),
/// wired to the app's real providers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigateToTab});

  /// Switches the enclosing [HomeShell]'s selected tab.
  final ValueChanged<int> onNavigateToTab;

  static const _amenitiesTabIndex = 2;

  static final _dayFormat = DateFormat('d MMM', 'es');
  static final _timeFormat = DateFormat('h:mm a', 'es');

  static final _cardShadow = [
    const BoxShadow(color: Color(0x09243026), blurRadius: 24, offset: Offset(0, 4)),
  ];

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Próximamente')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: GatesColors.bgSubtle,
      body: SafeArea(
        bottom: false,
        child: profileAsync.when(
          loading: () => const LoadingView(),
          error: (e, _) => ErrorView(
            message: 'No se pudo cargar tu perfil.',
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
          data: (profile) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myProfileProvider);
              ref.invalidate(myBookingsProvider);
              ref.invalidate(incidentsListProvider(membership.residentialId));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 140),
              children: [
                _HeaderRow(
                  membership: membership,
                  avatarLetter: profile.displayName.isNotEmpty
                      ? profile.displayName[0].toUpperCase()
                      : '?',
                  onBellTap: () => _showComingSoon(context),
                  onAvatarTap: () => context.push('/profile'),
                ),
                const SizedBox(height: 20),
                Text(
                  'Hola, ${_firstName(profile.firstName, profile.displayName)}.\nTu comunidad hoy.',
                  style: GatesTypography.headingLarge,
                ),
                const SizedBox(height: 20),
                GatesButton(
                  label: '+  Invitar una visita',
                  onPressed: () => _showComingSoon(context),
                ),
                const SizedBox(height: 20),
                _ReservationCard(
                  onViewBooking: () => context.push('/amenities/my-bookings'),
                  onBookAmenity: () => onNavigateToTab(_amenitiesTabIndex),
                ),
                const SizedBox(height: 20),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: _MyReservationsSummaryCard()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IncidentsSummaryCard(residentialId: membership.residentialId),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _firstName(String? firstName, String displayName) {
    final trimmed = firstName?.trim();
    if (trimmed != null && trimmed.isNotEmpty) return trimmed;
    return displayName.split(' ').first;
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({
    required this.membership,
    required this.avatarLetter,
    required this.onBellTap,
    required this.onAvatarTap,
  });

  final Membership membership;
  final String avatarLetter;
  final VoidCallback onBellTap;
  final VoidCallback onAvatarTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                membership.residentialName.toUpperCase(),
                style: GatesTypography.caption.copyWith(color: GatesColors.textBrand),
              ),
              Text(membership.unitName, style: GatesTypography.label),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          onTap: onBellTap,
          backgroundColor: GatesColors.bgSurface,
          child: const Icon(Icons.notifications_outlined, size: 20, color: GatesColors.textPrimary),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          onTap: onAvatarTap,
          backgroundColor: GatesColors.bgAccent,
          child: Text(
            avatarLetter,
            style: GatesTypography.label.copyWith(color: GatesColors.textBrand),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.onTap,
    required this.backgroundColor,
    required this.child,
  });

  final VoidCallback onTap;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({required this.onViewBooking, required this.onBookAmenity});

  final VoidCallback onViewBooking;
  final VoidCallback onBookAmenity;

  String _dayLabel(DateTime start) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final day = DateTime(start.year, start.month, start.day);
    if (day == today) return 'Hoy';
    if (day == tomorrow) return 'Mañana';
    return HomeScreen._dayFormat.format(start);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GatesColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: HomeScreen._cardShadow,
      ),
      child: bookingsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 24),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (e, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TU PRÓXIMA RESERVA',
              style: GatesTypography.caption,
            ),
            const SizedBox(height: 8),
            Text(
              'No se pudieron cargar tus reservas.',
              style: GatesTypography.body,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => ref.invalidate(myBookingsProvider),
              child: const Text('Reintentar'),
            ),
          ],
        ),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.isUpcoming).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (upcoming.isEmpty) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TU PRÓXIMA RESERVA', style: GatesTypography.caption),
                const SizedBox(height: 8),
                Text(
                  'Aún no tienes reservas próximas.',
                  style: GatesTypography.headingSmall,
                ),
                const SizedBox(height: 12),
                _ActionRow(label: 'Reservar una amenidad', onTap: onBookAmenity),
              ],
            );
          }

          final next = upcoming.first;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TU PRÓXIMA RESERVA', style: GatesTypography.caption),
              const SizedBox(height: 12),
              Text('Un momento para ti.', style: GatesTypography.headingSmall),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${next.amenityName} · ${_dayLabel(next.startTime)}',
                          style: GatesTypography.label,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${HomeScreen._timeFormat.format(next.startTime)} – '
                          '${HomeScreen._timeFormat.format(next.endTime)}',
                          style: GatesTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: GatesColors.bgAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.pool_outlined, color: GatesColors.textBrand),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ActionRow(label: 'Ver mi reserva', onTap: onViewBooking),
            ],
          );
        },
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: GatesTypography.label.copyWith(color: GatesColors.textBrand),
              ),
            ),
            const Icon(Icons.arrow_forward, size: 20, color: GatesColors.textBrand),
          ],
        ),
      ),
    );
  }
}

class _SummaryCardShell extends StatelessWidget {
  const _SummaryCardShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 156),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GatesColors.bgSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: HomeScreen._cardShadow,
      ),
      child: child,
    );
  }
}

class _SummaryCardContent extends StatelessWidget {
  const _SummaryCardContent({
    required this.title,
    required this.value,
    required this.detail,
    this.status,
    this.statusColor,
  });

  final String title;
  final String value;
  final String detail;
  final String? status;
  final Color? statusColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: GatesTypography.label),
        const SizedBox(height: 8),
        Text(
          value,
          style: GatesTypography.headingMedium,
        ),
        const SizedBox(height: 8),
        Text(detail, style: GatesTypography.caption),
        if (status != null) ...[
          const SizedBox(height: 8),
          Text(
            status!,
            style: GatesTypography.caption.copyWith(color: statusColor ?? GatesColors.textBrand),
          ),
        ],
      ],
    );
  }
}

class _MyReservationsSummaryCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return _SummaryCardShell(
      child: bookingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          'No se pudieron cargar tus reservas.',
          style: GatesTypography.caption,
        ),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.isUpcoming).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));
          final AmenityBooking? next = upcoming.isNotEmpty ? upcoming.first : null;

          return _SummaryCardContent(
            title: 'Mis reservas',
            value: '${upcoming.length}',
            detail: next?.amenityName ?? 'Sin reservas próximas',
            status: next != null
                ? 'Próxima: ${HomeScreen._dayFormat.format(next.startTime)}'
                : null,
          );
        },
      ),
    );
  }
}

class _IncidentsSummaryCard extends ConsumerWidget {
  const _IncidentsSummaryCard({required this.residentialId});

  final String residentialId;

  bool _isOpen(Incident incident) =>
      incident.status != IncidentStatus.resolved && incident.status != IncidentStatus.closed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsListProvider(residentialId));

    return _SummaryCardShell(
      child: incidentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text(
          'No se pudieron cargar las incidencias.',
          style: GatesTypography.caption,
        ),
        data: (incidents) {
          final open = incidents.where(_isOpen).toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
          final Incident? mostRecent = open.isNotEmpty ? open.first : null;
          final count = open.length;

          return _SummaryCardContent(
            title: 'Incidencias',
            value: count == 1 ? '1 abierta' : '$count abiertas',
            detail: mostRecent?.title ?? 'Sin incidencias abiertas',
            status: mostRecent != null ? statusLabel(mostRecent.status) : null,
            statusColor: GatesColors.textBrand,
          );
        },
      ),
    );
  }
}
