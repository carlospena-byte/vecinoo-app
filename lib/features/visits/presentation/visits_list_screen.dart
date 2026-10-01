import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_add_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/nav_clearance.dart';
import '../../../core/widgets/gates_switch_row.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/visit.dart';
import 'frequent_visit_formatters.dart';
import 'visit_detail_sheet.dart';
import 'visits_controller.dart';

enum _VisitsTab { pending, ongoing, history }

bool _isPending(Visit v) =>
    v.status == VisitStatus.pendingRegistration ||
    v.status == VisitStatus.scheduled;
bool _isOngoing(Visit v) =>
    v.status == VisitStatus.active || v.status == VisitStatus.inside;
bool _isHistory(Visit v) => !_isPending(v) && !_isOngoing(v);

String _emptyMessage(_VisitsTab tab) => switch (tab) {
  _VisitsTab.pending => 'No tienes visitas pendientes.',
  _VisitsTab.ongoing => 'No tienes visitas en curso.',
  _VisitsTab.history => 'Aún no tienes historial de visitas.',
};

final _dayMonthFormat = DateFormat('d MMM', 'es');
final _timeFormat = DateFormat('HH:mm', 'es');

/// "Hoy · 26 sep.", "Mañana · 27 sep." or, for any other day, just the date —
/// matches the Figma date-group headings ("V02A · Visitas / Pendientes").
String _dateGroupLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final day = DateTime(date.year, date.month, date.day);
  final dayMonth = '${_dayMonthFormat.format(date).replaceAll('.', '')}.';
  if (day == today) return 'Accesos para hoy · $dayMonth';
  if (day == tomorrow) return 'Mañana · $dayMonth';
  return dayMonth;
}

/// "Hoy", "Mañana" or "27 sep." — how the card's date line names a day.
String _relativeDay(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return 'Hoy';
  if (day == today.add(const Duration(days: 1))) return 'Mañana';
  return '${_dayMonthFormat.format(date).replaceAll('.', '')}.';
}

String _scheduleLabel(Visit v) {
  switch (v.visitType) {
    case VisitType.frequent:
      return frequentScheduleSummary(v);
    case VisitType.fastlane:
      return '${_relativeDay(v.validFrom)} · Llegada prevista ${_timeFormat.format(v.validFrom)}';
    case VisitType.delivery:
      return '${_relativeDay(v.validFrom)} · ${_timeFormat.format(v.validFrom)}–${_timeFormat.format(v.validUntil)}';
  }
}

String _visitSubtitle(Visit v) {
  switch (v.visitType) {
    case VisitType.delivery:
      final kind = v.providerKind != null
          ? ' · ${providerKindLabel(v.providerKind!)}'
          : '';
      return 'Delivery o proveedor$kind';
    case VisitType.fastlane:
      return 'Invitado · FastLane';
    case VisitType.frequent:
      return v.visitorRole != null
          ? visitorRoleLabel(v.visitorRole!)
          : 'Frecuente';
  }
}

/// "06 · Visitas / Inicio y detalle" — Figma node V02A (`118:225`), wired to
/// the app's real providers. Lives inside [HomeShell]'s tab shell, so it has
/// no app bar or bottom navigation of its own.
class VisitsListScreen extends ConsumerStatefulWidget {
  const VisitsListScreen({super.key});

  @override
  ConsumerState<VisitsListScreen> createState() => _VisitsListScreenState();
}

class _VisitsListScreenState extends ConsumerState<VisitsListScreen> {
  _VisitsTab _tab = _VisitsTab.pending;

  /// Frequent (standing) accesses are hidden by default so a handful of them
  /// don't bury the day's visits; the switch below the tabs reveals them.
  bool _showFrequent = false;

  Widget _card(BuildContext context, Visit visit, String unitName) =>
      _VisitCard(
        // Standing frequent access has no pending/scheduled state to report.
        showStatus:
            visit.visitType != VisitType.frequent || _tab != _VisitsTab.pending,
        visit: visit,
        // Frequent access and FastLane invitations still waiting for their data
        // have their own screens (last movement; share link / edit). Everything
        // else opens the "Detalle de visita" sheet.
        onTap: visit.visitType == VisitType.frequent
            ? () => context.push('/visits/${visit.id}/access')
            : visit.status == VisitStatus.pendingRegistration
            ? () => context.push('/visits/${visit.id}')
            : () => showVisitDetailSheet(
                context,
                visit: visit,
                unitName: unitName,
              ),
      );

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final visitsAsync = ref.watch(visitsListProvider(membership.unitId));

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space16,
                GatesSpacing.space24,
                0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Visitas',
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                  GatesAddButton(
                    semanticLabel: 'Nueva visita',
                    onTap: () async {
                      await context.push('/visits/new');
                      ref.invalidate(visitsListProvider(membership.unitId));
                    },
                  ),
                ],
              ),
            ),
            visitsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (visits) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  GatesSpacing.space24,
                  GatesSpacing.space16,
                  GatesSpacing.space24,
                  0,
                ),
                child: GatesSegmentedTabs<_VisitsTab>(
                  options: [
                    GatesSegmentedTabOption(
                      value: _VisitsTab.pending,
                      label: 'Pendientes',
                    ),
                    GatesSegmentedTabOption(
                      value: _VisitsTab.ongoing,
                      label: 'En curso',
                    ),
                    const GatesSegmentedTabOption(
                      value: _VisitsTab.history,
                      label: 'Historial',
                    ),
                  ],
                  selected: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                GatesSpacing.space24,
                GatesSpacing.space12,
                GatesSpacing.space24,
                0,
              ),
              child: GatesSwitchRow(
                compact: true,
                label: 'Mostrar visitas frecuentes',
                value: _showFrequent,
                onChanged: (v) => setState(() => _showFrequent = v),
              ),
            ),
            Expanded(
              child: visitsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: 'No se pudieron cargar tus visitas.',
                  onRetry: () =>
                      ref.invalidate(visitsListProvider(membership.unitId)),
                ),
                data: (visits) {
                  final filtered = switch (_tab) {
                    _VisitsTab.pending =>
                      visits.where(_isPending).toList()
                        ..sort((a, b) => a.validFrom.compareTo(b.validFrom)),
                    _VisitsTab.ongoing =>
                      visits.where(_isOngoing).toList()
                        ..sort((a, b) => a.validFrom.compareTo(b.validFrom)),
                    _VisitsTab.history =>
                      visits.where(_isHistory).toList()
                        ..sort((a, b) => b.validFrom.compareTo(a.validFrom)),
                  };

                  final regular = filtered
                      .where((v) => v.visitType != VisitType.frequent)
                      .toList();
                  final frequent = _showFrequent
                      ? filtered
                            .where((v) => v.visitType == VisitType.frequent)
                            .toList()
                      : <Visit>[];

                  if (regular.isEmpty && frequent.isEmpty) {
                    final hidden = filtered.length - regular.length;
                    return EmptyView(
                      message: hidden > 0 && !_showFrequent
                          ? '${_emptyMessage(_tab)}\nTienes $hidden ${hidden == 1 ? 'acceso frecuente oculto' : 'accesos frecuentes ocultos'}.'
                          : _emptyMessage(_tab),
                      icon: Icons.person_add_alt_outlined,
                    );
                  }

                  final groups = <DateTime, List<Visit>>{};
                  for (final visit in regular) {
                    final date = visit.validFrom;
                    final day = DateTime(date.year, date.month, date.day);
                    groups.putIfAbsent(day, () => []).add(visit);
                  }
                  final sortedDays = groups.keys.toList()
                    ..sort(
                      (a, b) => _tab == _VisitsTab.history
                          ? b.compareTo(a)
                          : a.compareTo(b),
                    );

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(visitsListProvider(membership.unitId)),
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        GatesSpacing.space24,
                        GatesSpacing.space16,
                        GatesSpacing.space24,
                        homeNavClearance(context),
                      ),
                      children: [
                        for (final day in sortedDays) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: GatesSpacing.space8,
                            ),
                            child: Text(
                              _dateGroupLabel(day),
                              style: context.gatesText.caption,
                            ),
                          ),
                          for (final visit in groups[day]!) ...[
                            _card(context, visit, membership.unitName),
                            const SizedBox(height: GatesSpacing.space16),
                          ],
                        ],
                        if (frequent.isNotEmpty) ...[
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: GatesSpacing.space8,
                            ),
                            child: Text(
                              'Accesos frecuentes',
                              style: context.gatesText.caption,
                            ),
                          ),
                          for (final visit in frequent) ...[
                            _card(context, visit, membership.unitName),
                            const SizedBox(height: GatesSpacing.space16),
                          ],
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Visit card" — Figma node `449:2030`.
class _VisitCard extends StatelessWidget {
  const _VisitCard({required this.visit, this.onTap, this.showStatus = true});

  final Visit visit;
  final VoidCallback? onTap;

  /// Whether to show the status pill. Frequent visits skip it on the
  /// Pendientes tab: standing access has no pending/scheduled state to report.
  final bool showStatus;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GatesSpacing.space16),
        decoration: BoxDecoration(
          color: context.palette.bgSurface,
          border: Border.all(color: context.palette.borderDefault),
          borderRadius: BorderRadius.circular(GatesRadius.radius16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    visit.name ?? 'Invitación por completar',
                    style: GatesTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: GatesSpacing.space8),
                _AccessChip(frequent: visit.visitType == VisitType.frequent),
              ],
            ),
            const SizedBox(height: GatesSpacing.space4),
            Text(_visitSubtitle(visit), style: context.gatesText.caption),
            const SizedBox(height: GatesSpacing.space4),
            Text(
              _scheduleLabel(visit),
              style: context.gatesText.labelSecondary,
            ),
            if (showStatus) ...[
              const SizedBox(height: GatesSpacing.space12),
              _VisitStatusBadge(status: visit.status),
            ],
          ],
        ),
      ),
    );
  }
}

/// "Access / Frecuente" and "Access / Visita del día" chips.
class _AccessChip extends StatelessWidget {
  const _AccessChip({required this.frequent});

  final bool frequent;

  @override
  Widget build(BuildContext context) {
    final background = frequent
        ? context.palette.bgSubtle
        : context.palette.toneInfo.background;
    final foreground = frequent
        ? context.palette.textBrand
        : context.palette.toneInfo.foreground;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GatesSpacing.space8,
        vertical: GatesSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            frequent ? Icons.repeat : Icons.calendar_today_outlined,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: GatesSpacing.space4),
          Text(
            frequent ? 'Frecuente' : 'Visita del día',
            style: context.gatesText.caption.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class _VisitStatusBadge extends StatelessWidget {
  const _VisitStatusBadge({required this.status});

  final VisitStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      VisitStatus.pendingRegistration => (
        context.palette.statusWarningBg,
        context.palette.statusWarning,
      ),
      VisitStatus.scheduled => (
        context.palette.bgSubtle,
        context.palette.textBrand,
      ),
      VisitStatus.active || VisitStatus.inside => (
        context.palette.bgAccent,
        context.palette.textBrand,
      ),
      VisitStatus.completed ||
      VisitStatus.cancelled ||
      VisitStatus.rejected ||
      VisitStatus.expired => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: GatesSpacing.space8,
        vertical: GatesSpacing.space4,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radiusFull),
      ),
      child: Text(
        visitStatusLabel(status),
        style: context.gatesText.caption.copyWith(color: foreground),
      ),
    );
  }
}
