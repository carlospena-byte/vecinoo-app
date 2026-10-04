import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import 'visit_failure_text.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_add_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/nav_clearance.dart';
import '../../../core/widgets/gates_switch_row.dart';
import '../../../core/widgets/state_views.dart';
import '../../../l10n/l10n.dart';
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

String _emptyMessage(AppLocalizations l10n, _VisitsTab tab) => switch (tab) {
  _VisitsTab.pending => l10n.visitsListEmptyPending,
  _VisitsTab.ongoing => l10n.visitsListEmptyOngoing,
  _VisitsTab.history => l10n.visitsListEmptyHistory,
};

final _dayMonthFormat = DateFormat('d MMM', 'es');
final _timeFormat = DateFormat('HH:mm', 'es');

/// "Hoy · 26 sep.", "Mañana · 27 sep." or, for any other day, just the date —
/// matches the Figma date-group headings ("V02A · Visitas / Pendientes").
String _dateGroupLabel(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));
  final day = DateTime(date.year, date.month, date.day);
  final dayMonth = '${_dayMonthFormat.format(date).replaceAll('.', '')}.';
  if (day == today) return l10n.visitsListGroupToday(dayMonth);
  if (day == tomorrow) return l10n.visitsListGroupTomorrow(dayMonth);
  return dayMonth;
}

/// "Hoy", "Mañana" or "27 sep." — how the card's date line names a day.
String _relativeDay(AppLocalizations l10n, DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(date.year, date.month, date.day);
  if (day == today) return l10n.visitsToday;
  if (day == today.add(const Duration(days: 1))) return l10n.visitsTomorrow;
  return '${_dayMonthFormat.format(date).replaceAll('.', '')}.';
}

String _scheduleLabel(AppLocalizations l10n, Visit v) {
  switch (v.visitType) {
    case VisitType.frequent:
      return frequentScheduleSummary(l10n, v);
    case VisitType.fastlane:
      return l10n.visitsListFastlaneSchedule(
        _relativeDay(l10n, v.validFrom),
        _timeFormat.format(v.validFrom),
      );
    case VisitType.delivery:
      return '${_relativeDay(l10n, v.validFrom)} · ${_timeFormat.format(v.validFrom)}–${_timeFormat.format(v.validUntil)}';
  }
}

String _visitSubtitle(AppLocalizations l10n, Visit v) {
  switch (v.visitType) {
    case VisitType.delivery:
      return v.providerKind != null
          ? l10n.visitsListSubtitleDeliveryKind(
              providerKindLabel(l10n, v.providerKind!),
            )
          : l10n.visitsDeliveryOrProvider;
    case VisitType.fastlane:
      return l10n.visitsListSubtitleFastlane;
    case VisitType.frequent:
      return v.visitorRole != null
          ? visitorRoleLabel(l10n, v.visitorRole!)
          : l10n.visitsTypeFrequent;
  }
}

/// "06 · Visitas / Inicio y detalle" — Figma node V02A (`118:225`), wired to
/// the app's real providers. Lives inside [HomeShell]'s tab shell, so it has
/// no app bar or bottom navigation of its own.
class VisitsListScreen extends ConsumerStatefulWidget {
  const VisitsListScreen({super.key, this.active = true});

  /// Whether this is the selected tab; becoming active refetches the list.
  final bool active;

  @override
  ConsumerState<VisitsListScreen> createState() => _VisitsListScreenState();
}

class _VisitsListScreenState extends ConsumerState<VisitsListScreen> {
  _VisitsTab _tab = _VisitsTab.pending;

  /// Frequent (standing) accesses are hidden by default so a handful of them
  /// don't bury the day's visits; the switch below the tabs reveals them.
  bool _showFrequent = false;

  @override
  void didUpdateWidget(VisitsListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      // Providers can't be invalidated while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final membership = ref.read(selectedMembershipProvider).value;
        if (membership != null) {
          ref.invalidate(visitsListProvider(membership.unitId));
        }
      });
    }
  }

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
                      context.l10n.visitsListTitle,
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                  GatesAddButton(
                    semanticLabel: context.l10n.visitsListNewVisit,
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
                      label: context.l10n.visitsTabPending,
                    ),
                    GatesSegmentedTabOption(
                      value: _VisitsTab.ongoing,
                      label: context.l10n.visitsTabOngoing,
                    ),
                    GatesSegmentedTabOption(
                      value: _VisitsTab.history,
                      label: context.l10n.visitsTabHistory,
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
                label: context.l10n.visitsListShowFrequent,
                value: _showFrequent,
                onChanged: (v) => setState(() => _showFrequent = v),
              ),
            ),
            Expanded(
              child: visitsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: withErrorDetail(
                    context.l10n,
                    e,
                    context.l10n.visitsListLoadError,
                  ),
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
                          ? '${_emptyMessage(context.l10n, _tab)}\n${context.l10n.visitsListHiddenFrequent(hidden)}'
                          : _emptyMessage(context.l10n, _tab),
                      icon: TablerIcons.userPlus,
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
                              _dateGroupLabel(context.l10n, day),
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
                              context.l10n.visitsListFrequentHeading,
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
                    visit.name ?? context.l10n.visitsPendingInvitationName,
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
            Text(
              _visitSubtitle(context.l10n, visit),
              style: context.gatesText.caption,
            ),
            const SizedBox(height: GatesSpacing.space4),
            Text(
              _scheduleLabel(context.l10n, visit),
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
            frequent ? TablerIcons.repeat : TablerIcons.calendar,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: GatesSpacing.space4),
          Text(
            frequent
                ? context.l10n.visitsTypeFrequent
                : context.l10n.visitsListDailyVisit,
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
        visitStatusLabel(context.l10n, status),
        style: context.gatesText.caption.copyWith(color: foreground),
      ),
    );
  }
}
