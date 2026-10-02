import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_svg_icon.dart';
import '../../../core/widgets/state_views.dart';
import '../../amenities/presentation/amenities_controller.dart';
import '../../bulletins/presentation/bulletins_controller.dart';
import '../../incidents/domain/incident.dart';
import '../../incidents/presentation/incidents_controller.dart';
import '../../profile/presentation/profile_controller.dart';
import '../../session/domain/membership.dart';
import '../../session/presentation/session_controller.dart';
import '../../visits/domain/visit.dart';
import '../../visits/presentation/visits_controller.dart';
import '../../../core/widgets/gates_toast.dart';
import '../../../l10n/l10n.dart';

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
    showGatesToast(
      context,
      type: GatesToastType.info,
      title: context.l10n.homeComingSoon,
    );
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
            message: context.l10n.profileLoadFailed,
            onRetry: () => ref.invalidate(myProfileProvider),
          ),
          data: (profile) => RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(myProfileProvider);
              ref.invalidate(myBookingsProvider);
              ref.invalidate(incidentsListProvider(membership.residentialId));
              ref.invalidate(bulletinsListProvider(membership.residentialId));
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
                  _greeting(context, profile.firstName),
                  style: GatesTypography.headingMedium.copyWith(
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  context.l10n.homeTagline,
                  style: context.gatesText.labelSecondary,
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: _IncidentsSummaryCard(
                        residentialId: membership.residentialId,
                        onViewIncidents: () =>
                            onNavigateToTab(_incidentsTabIndex),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _BulletinsCard(residentialId: membership.residentialId),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _greeting(BuildContext context, String? firstName) {
    final name = firstName?.trim().split(' ').first;
    if (name == null || name.isEmpty) return context.l10n.homeGreeting;
    return context.l10n.homeGreetingNamed(name);
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
                style: context.gatesText.caption.copyWith(
                  color: context.palette.textBrand,
                ),
              ),
              Text(membership.unitName, style: GatesTypography.label),
            ],
          ),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          semanticLabel: context.l10n.homeNotifications,
          onTap: onBellTap,
          backgroundColor: context.palette.bgSurface,
          child: const GatesSvgIcon('assets/icons/home/bell.svg', size: 20),
        ),
        const SizedBox(width: 12),
        _CircleIconButton(
          semanticLabel: context.l10n.commonProfile,
          onTap: onAvatarTap,
          backgroundColor: context.palette.bgAccent,
          child: Text(
            avatarLetter,
            style: GatesTypography.label.copyWith(
              color: context.palette.textBrand,
            ),
          ),
        ),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.onTap,
    required this.semanticLabel,
    required this.backgroundColor,
    required this.child,
  });

  final VoidCallback onTap;
  final String semanticLabel;
  final Color backgroundColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: backgroundColor,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(width: 44, height: 44, child: Center(child: child)),
        ),
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  const _ReservationCard({required this.onBookAmenity});

  final VoidCallback onBookAmenity;

  String _dayLabel(BuildContext context, DateTime start) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final day = DateTime(start.year, start.month, start.day);
    if (day == today) return context.l10n.homeToday;
    if (day == tomorrow) return context.l10n.homeTomorrow;
    return HomeScreen._dayFormat.format(start);
  }

  /// "6:00" style clock, with the meridiem appended by [_range].
  static String _clock(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    return '$h:${t.minute.toString().padLeft(2, '0')}';
  }

  /// "6:00–10:00 p. m." as in Figma.
  static String _range(BuildContext context, DateTime start, DateTime end) {
    final meridiem = end.hour >= 12 ? context.l10n.homePm : context.l10n.homeAm;
    return '${_clock(start)}–${_clock(end)} $meridiem';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookingsAsync = ref.watch(myBookingsProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.palette.bgBrand,
        borderRadius: BorderRadius.circular(GatesRadius.radius24),
      ),
      child: bookingsAsync.when(
        loading: () => SizedBox(
          height: 148,
          child: Center(
            child: CircularProgressIndicator(
              color: context.palette.textOnBrand,
            ),
          ),
        ),
        error: (e, _) => _content(
          context,
          title: context.l10n.homeBookingsLoadFailed,
          detail: null,
          actionLabel: context.l10n.commonRetry,
          onAction: () => ref.invalidate(myBookingsProvider),
        ),
        data: (bookings) {
          final upcoming = bookings.where((b) => b.isUpcoming).toList()
            ..sort((a, b) => a.startTime.compareTo(b.startTime));

          if (upcoming.isEmpty) {
            return _content(
              context,
              title: context.l10n.homeNoBookingsTitle,
              detail: context.l10n.homeNoBookingsDetail,
              actionLabel: context.l10n.homeExploreAmenities,
              onAction: onBookAmenity,
            );
          }

          final next = upcoming.first;
          return _content(
            context,
            title:
                '${next.amenityName} · ${_dayLabel(context, next.startTime)}',
            detail: _range(context, next.startTime, next.endTime),
            actionLabel: context.l10n.homeExploreAmenities,
            onAction: onBookAmenity,
          );
        },
      ),
    );
  }

  Widget _content(
    BuildContext context, {
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
                    context.l10n.homeReservations,
                    style: context.gatesText.caption.copyWith(
                      color: context.palette.textOnBrand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GatesTypography.headingSmall.copyWith(
                      color: context.palette.textOnBrand,
                      letterSpacing: 0,
                    ),
                  ),
                  if (detail != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      detail,
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textOnBrand,
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
              decoration: BoxDecoration(
                color: context.palette.bgWarm,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: GatesSvgIcon(
                  'assets/icons/home/emblem_reservations.svg',
                  size: 28,
                  color: context.palette.iconBrand,
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
            color: context.palette.bgOnBrandAction,
            shape: const StadiumBorder(),
            child: InkWell(
              onTap: onAction,
              customBorder: const StadiumBorder(),
              child: Center(
                child: Text(
                  actionLabel,
                  style: GatesTypography.label.copyWith(
                    color: context.palette.textOnBrandAction,
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
              ? BorderSide(color: context.palette.borderDefault)
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
                      style: context.gatesText.caption.copyWith(
                        color: context.palette.textPrimary,
                      ),
                    ),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GatesTypography.label,
                    ),
                    Text(
                      action,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GatesTypography.label.copyWith(
                        color: context.palette.textBrand,
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
                      child: GatesSvgIcon(
                        iconAsset,
                        size: 20,
                        color: context.palette.iconBrand,
                      ),
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
      label: context.l10n.homeVisits,
      title: context.l10n.homeVisitsSummary(count),
      action: count == 0
          ? context.l10n.homeInvite
          : context.l10n.homeViewVisits,
      iconAsset: 'assets/icons/home/emblem_visits.svg',
      backgroundColor: context.palette.bgSurface,
      emblemColor: context.palette.bgAccent,
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
      label: context.l10n.homeIncidents,
      title: context.l10n.homeIncidentsSummary(count),
      action: count == 0
          ? context.l10n.homeReport
          : context.l10n.homeViewReport,
      iconAsset: 'assets/icons/home/emblem_incidents.svg',
      backgroundColor: context.palette.bgAccent,
      emblemColor: context.palette.bgSurface,
      onTap: count == 0
          ? () => context.push('/incidents/report')
          : onViewIncidents,
    );
  }
}

/// Full-width card under Visitas / Incidencias: summarises how many
/// bulletins are still unread. With none new it opens the history tab.
class _BulletinsCard extends ConsumerWidget {
  const _BulletinsCard({required this.residentialId});

  final String residentialId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bulletins = ref.watch(bulletinsListProvider(residentialId)).value;
    final readIds = ref.watch(bulletinReadIdsProvider(residentialId));
    final newCount =
        bulletins?.where((b) => !readIds.contains(b.id)).length ?? 0;
    final neverPublished = bulletins != null && bulletins.isEmpty;

    final title = neverPublished
        ? context.l10n.homeBulletinsEmpty
        : context.l10n.homeBulletinsSummary(newCount);
    final action = newCount == 0
        ? context.l10n.homeViewBulletinsHistory
        : newCount == 1
        ? context.l10n.homeViewBulletin
        : context.l10n.homeViewBulletins;
    final onTap = newCount == 0
        ? () => context.push('/bulletins?tab=history')
        : () => context.push('/bulletins');

    return Semantics(
      button: true,
      label: context.l10n.homeBulletins,
      value: title,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: context.palette.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GatesRadius.radius24),
          side: BorderSide(color: context.palette.borderDefault),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.homeBulletins,
                        style: context.gatesText.caption.copyWith(
                          color: context.palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GatesTypography.label,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        action,
                        style: GatesTypography.label.copyWith(
                          color: context.palette.textBrand,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: context.palette.bgAccent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    TablerIcons.news,
                    size: 20,
                    color: context.palette.iconBrand,
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
