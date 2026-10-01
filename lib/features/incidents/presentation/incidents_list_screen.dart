import 'package:flutter/material.dart';
import 'package:tabler_icons_plus/tabler_icons_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/gates_add_button.dart';
import '../../../core/widgets/gates_segmented_tabs.dart';
import '../../../core/widgets/nav_clearance.dart';
import '../../../core/widgets/state_views.dart';
import '../../session/presentation/session_controller.dart';
import '../domain/incident.dart';
import '../../../l10n/l10n.dart';
import 'incident_labels.dart';
import 'incidents_controller.dart';

enum _IncidentsTab { pending, inProgress, history }

bool _isPending(Incident i) => i.status == IncidentStatus.newIncident;
bool _isInProgress(Incident i) => i.status == IncidentStatus.inProgress;
bool _isHistory(Incident i) => !_isPending(i) && !_isInProgress(i);

String _emptyMessage(AppLocalizations l10n, _IncidentsTab tab) => switch (tab) {
  _IncidentsTab.pending => l10n.incidentsListEmptyPending,
  _IncidentsTab.inProgress => l10n.incidentsListEmptyInProgress,
  _IncidentsTab.history => l10n.incidentsListEmptyHistory,
};

final _dateFormat = DateFormat('d MMM y, HH:mm', 'es');

/// "Incidencias" tab — same shape as the Reservas and Visitas tabs: header
/// with a "+" that starts a new report, then Pendientes / En curso /
/// Historial. Lives inside [HomeShell]'s tab shell, so it has no app bar or
/// bottom navigation of its own.
class IncidentsListScreen extends ConsumerStatefulWidget {
  const IncidentsListScreen({super.key});

  @override
  ConsumerState<IncidentsListScreen> createState() =>
      _IncidentsListScreenState();
}

class _IncidentsListScreenState extends ConsumerState<IncidentsListScreen> {
  _IncidentsTab _tab = _IncidentsTab.pending;

  @override
  Widget build(BuildContext context) {
    final membership = ref.watch(selectedMembershipProvider).value;
    if (membership == null) return const LoadingView();

    final residentialId = membership.residentialId;
    final incidentsAsync = ref.watch(incidentsListProvider(residentialId));

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
                      context.l10n.incidentsListTitle,
                      style: GatesTypography.headingMedium,
                    ),
                  ),
                  GatesAddButton(
                    semanticLabel: context.l10n.incidentsReportAction,
                    onTap: () async {
                      await context.push('/incidents/report');
                      ref.invalidate(incidentsListProvider(residentialId));
                    },
                  ),
                ],
              ),
            ),
            incidentsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (e, _) => const SizedBox.shrink(),
              data: (_) => Padding(
                padding: const EdgeInsets.fromLTRB(
                  GatesSpacing.space24,
                  GatesSpacing.space16,
                  GatesSpacing.space24,
                  0,
                ),
                child: GatesSegmentedTabs<_IncidentsTab>(
                  options: [
                    GatesSegmentedTabOption(
                      value: _IncidentsTab.pending,
                      label: context.l10n.incidentsTabPending,
                    ),
                    GatesSegmentedTabOption(
                      value: _IncidentsTab.inProgress,
                      label: context.l10n.incidentsTabInProgress,
                    ),
                    GatesSegmentedTabOption(
                      value: _IncidentsTab.history,
                      label: context.l10n.incidentsTabHistory,
                    ),
                  ],
                  selected: _tab,
                  onSelect: (tab) => setState(() => _tab = tab),
                ),
              ),
            ),
            Expanded(
              child: incidentsAsync.when(
                loading: () => const LoadingView(),
                error: (e, _) => ErrorView(
                  message: context.l10n.incidentsListLoadError,
                  onRetry: () =>
                      ref.invalidate(incidentsListProvider(residentialId)),
                ),
                data: (incidents) {
                  final filtered = switch (_tab) {
                    _IncidentsTab.pending =>
                      incidents.where(_isPending).toList(),
                    _IncidentsTab.inProgress =>
                      incidents.where(_isInProgress).toList(),
                    _IncidentsTab.history =>
                      incidents.where(_isHistory).toList(),
                  }..sort((a, b) => b.createdAt.compareTo(a.createdAt));

                  if (filtered.isEmpty) {
                    return EmptyView(
                      message: _emptyMessage(context.l10n, _tab),
                      icon: TablerIcons.flagExclamation,
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(incidentsListProvider(residentialId)),
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        GatesSpacing.space24,
                        GatesSpacing.space16,
                        GatesSpacing.space24,
                        homeNavClearance(context),
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: GatesSpacing.space12),
                      itemBuilder: (context, index) => _IncidentCard(
                        incident: filtered[index],
                        onTap: () async {
                          await context.push(
                            '/incidents/${filtered[index].id}',
                          );
                          ref.invalidate(incidentsListProvider(residentialId));
                        },
                      ),
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

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});

  final Incident incident;
  final VoidCallback onTap;

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
            Text(
              incident.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GatesTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
            if (incident.incidentTypeName != null) ...[
              const SizedBox(height: GatesSpacing.space4),
              Text(
                incident.incidentTypeName!,
                style: context.gatesText.caption,
              ),
            ],
            const SizedBox(height: GatesSpacing.space4),
            Text(
              _dateFormat.format(incident.createdAt).replaceAll('.', ''),
              style: context.gatesText.labelSecondary,
            ),
            const SizedBox(height: GatesSpacing.space12),
            IncidentStatusBadge(status: incident.status),
          ],
        ),
      ),
    );
  }
}

class IncidentStatusBadge extends StatelessWidget {
  const IncidentStatusBadge({super.key, required this.status});

  final IncidentStatus status;

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (status) {
      IncidentStatus.newIncident => (
        context.palette.statusWarningBg,
        context.palette.statusWarning,
      ),
      IncidentStatus.inProgress => (
        context.palette.bgAccent,
        context.palette.textBrand,
      ),
      IncidentStatus.resolved => (
        context.palette.statusSuccessBg,
        context.palette.statusSuccess,
      ),
      IncidentStatus.closed || IncidentStatus.cancelled => (
        context.palette.bgSubtle,
        context.palette.textSecondary,
      ),
    };
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: GatesSpacing.space8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(GatesRadius.radius8),
      ),
      alignment: Alignment.center,
      child: Text(
        incidentStatusLabel(context.l10n, status),
        style: context.gatesText.caption.copyWith(color: foreground),
      ),
    );
  }
}
