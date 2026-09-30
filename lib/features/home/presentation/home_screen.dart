import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/state_views.dart';
import '../../amenities/presentation/amenities_controller.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/presentation/incidents_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../session/domain/membership.dart';
import '../../session/presentation/session_controller.dart';
import '../../visits/domain/visit.dart';
import '../../visits/presentation/visits_controller.dart';
import '../../../core/widgets/gates_toast.dart';

/// "05 / Home" screen from Figma (file `Bla1GPfXA7JkuZcYpVi2DS`, node `13:14`),
/// wired to the app's real providers.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, required this.onNavigateToTab});

  /// Switches the enclosing [HomeShell]'s selected tab.
  final ValueChanged<int> onNavigateToTab;

  static const _incidentsTabIndex = 1;
  static const _visitsTabIndex = 3;

  static final _dayFormat = DateFormat('d MMM', 'es');

  void _showComingSoon(BuildContext context) {
    showGatesToast(context, type: GatesToastType.info, title: 'Próximamente');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
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
                const SizedBox(height: 16),
                Text(
                  _greeting(profile.firstName),
                  style: GatesTypography.headingLarge.copyWith(
                    fontSize: 28,
                    height: 36 / 28,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tu comunidad, más cerca.',
                  style: GatesTypography.labelSecondary,
                ),
                const SizedBox(height: 16),
                _ReservationCard(
                  onBookAmenity: () => context.push('/amenities'),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _VisitsSummaryCard(
                        unitId: membership.unitId,
                        onViewVisits: () => onNavigateToTab(_visitsTabIndex),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _IncidentsSummaryCard(
                        residentialId: membership.residentialId,
                        onViewIncidents: () =>
                            onNavigateToTab(_incidentsTabIndex),
                      ),
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

  static String _greeting(String? firstName) {
    final name = firstName?.trim().split(' ').first;
    if (name == null || name.isEmpty) return 'Hola';
    return 'Hola, $name';
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
                style: GatesTypography.caption.copyWith(
                  color: GatesColors.textBrand,
                ),
              ),
              Text(membership.unitName, style: GatesTypography.label),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          onTap: onBellTap,
          backgroundColor: GatesColors.bgSurface,
          child: SvgPicture.asset(
            'assets/icons/home/bell.svg',
            width: 20,
            height: 20,
          ),
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
        child: SizedBox(width: 44, height: 44, child: Center(child: child)),
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({required this.onBookAmenity});

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

  /// "6:00" style clock, with the meridiem appended by [_range].
  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  /// "6:00–10:00 p. m." as in Figma.
  static String _range(DateTime start, DateTime end) {
    final meridiem = end.hour >= 12 ? 'p. m.' : 'a. m.';
    return '${_clock(start)}–${_clock(end)} $meridiem';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: GatesColors.bgBrand,
        borderRadius: BorderRadius.circular(GatesRadius.radius24),
      ),
      child: bookingsAsync.when(
        loading: () => const SizedBox(
          height: 148,
          child: Center(
            child: CircularProgressIndicator(color: GatesColors.textInverse),
          ),
        ),
        error: (e, _) => _content(
          title: 'No se pudieron cargar tus reservas.',
          detail: null,
          actionLabel: 'Reintentar',
          onAction: () => ref.invalidate(myBookingsProvider),
        ),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.isUpcoming).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (upcoming.isEmpty) {
            return _content(
              title: 'Un espacio para disfrutar',
              detail: 'Aún no tienes reservas próximas.',
              actionLabel: 'Explorar amenidades',
              onAction: onBookAmenity,
            );
          }

          final next = upcoming.first;
          return _content(
            title: '${next.amenityName} · ${_dayLabel(next.startTime)}',
            detail: _range(next.startTime, next.endTime),
            actionLabel: 'Explorar amenidades',
            onAction: onBookAmenity,
          );
        },
      ),
    );
  }

  Widget _content({
    required String title,
    required String? detail,
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservas',
                    style: GatesTypography.caption.copyWith(
                      color: GatesColors.textInverse,
                      height: 16 / 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GatesTypography.headingSmall.copyWith(
                      color: GatesColors.textInverse,
                      letterSpacing: 0,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: GatesTypography.label.copyWith(
                        color: GatesColors.textInverse,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: GatesColors.bgWarm,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/home/emblem_reservations.svg',
                  width: 28,
                  height: 28,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: Material(
            color: GatesColors.bgAccent,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: onAction,
              customBorder: const StadiumBorder(),
              child: Center(
                child: Text(
                  actionLabel,
                  style: GatesTypography.label.copyWith(
                    color: GatesColors.textBrand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Fixed-size graphic card from Figma ("Inicio / Tarjeta gráfica", 180 high).
/// Both cards in the row share this shell so they always match in size.
class _GraphicCard extends StatelessWidget {
  const _GraphicCard({
    required this.label,
    required this.title,
    required this.action,
    required this.iconAsset,
    required this.onTap,
    required this.backgroundColor,
    required this.emblemColor,
    this.bordered = false,
  });

  static const height = 180.0;

  final String label;
  final String title;
  final String action;
  final String iconAsset;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color emblemColor;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(GatesRadius.radius24);
    return SizedBox(
      height: height,
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: bordered
              ? const BorderSide(color: GatesColors.borderDefault)
              : BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: GatesTypography.caption.copyWith(
                        color: GatesColors.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GatesTypography.label.copyWith(fontSize: 16),
                    ),
                    Text(
                      action,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GatesTypography.label.copyWith(
                        color: GatesColors.textBrand,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: -4,
                  right: 0,
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: emblemColor,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: SvgPicture.asset(iconAsset, width: 20, height: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VisitsSummaryCard extends ConsumerWidget {
  const _VisitsSummaryCard({required this.unitId, required this.onViewVisits});

  final String unitId;
  final VoidCallback onViewVisits;

  bool _isPlanned(Visit v) =>
      v.status == VisitStatus.scheduled ||
      v.status == VisitStatus.active ||
      v.status == VisitStatus.inside ||
      v.status == VisitStatus.pendingRegistration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = DateTime(now.year, now.month, now.day + 1);
    final count =
        ref
            .watch(visitsListProvider(unitId))
            .value
            ?.where(
              (v) =>
                  _isPlanned(v) &&
                  v.validFrom.isBefore(endOfToday) &&
                  v.validUntil.isAfter(startOfToday),
            )
            .length ??
        0;

    return _GraphicCard(
      label: 'Visitas',
      title: count == 0
          ? 'Sin visitas\nprevistas'
          : count == 1
          ? '1 visita\npara hoy'
          : '$count visitas\npara hoy',
      action: count == 0 ? 'Invitar' : 'Ver visitas',
      iconAsset: 'assets/icons/home/emblem_visits.svg',
      backgroundColor: GatesColors.bgSurface,
      emblemColor: GatesColors.bgAccent,
      bordered: true,
      onTap: count == 0 ? () => context.push('/visits/new') : onViewVisits,
    );
  }
}

class _IncidentsSummaryCard extends ConsumerWidget {
  const _IncidentsSummaryCard({
    required this.residentialId,
    required this.onViewIncidents,
  });

  final String residentialId;
  final VoidCallback onViewIncidents;

  bool _isOpen(Incident incident) =>
      incident.status != IncidentStatus.resolved &&
      incident.status != IncidentStatus.closed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count =
        ref
            .watch(incidentsListProvider(residentialId))
            .value
            ?.where(_isOpen)
            .length ??
        0;

    return _GraphicCard(
      label: 'Incidencias',
      title: count == 0
          ? 'Sin incidencias\nreportadas'
          : count == 1
          ? '1 reporte\nen seguimiento'
          : '$count reportes\nen seguimiento',
      action: count == 0 ? 'Reportar' : 'Ver reporte',
      iconAsset: 'assets/icons/home/emblem_incidents.svg',
      backgroundColor: GatesColors.bgAccent,
      emblemColor: GatesColors.bgSurface,
      onTap: count == 0
          ? () => context.push('/incidents/report')
          : onViewIncidents,
    );
  }
}
